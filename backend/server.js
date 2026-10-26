const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const https = require('https');
const crypto = require('crypto');

// ===== 环境变量（读取 backend/.env，不引入额外依赖）=====
const ENV_FILE = path.join(__dirname, '.env');

function loadEnvFile() {
  if (!fs.existsSync(ENV_FILE)) return;
  fs.readFileSync(ENV_FILE, 'utf-8').split(/\r?\n/).forEach((line) => {
    const text = line.trim();
    if (!text || text.startsWith('#')) return;
    const idx = text.indexOf('=');
    if (idx === -1) return;
    const key = text.slice(0, idx).trim();
    let value = text.slice(idx + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = value;
  });
}

loadEnvFile();

const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.use(cors());
// 头像以 base64 上传，默认 100kb 限制不够，这里放宽到 8MB（后端会再校验解码后 ≤2MB）
app.use(express.json({ limit: '8mb' }));

// 包装 async 路由：Express 4 不会自动捕获 async 里抛出的异常，
// 包一层后统一交给下方错误中间件，避免请求悬挂或进程崩溃
function wrapAsync(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

const DATA_FILE = path.join(__dirname, 'data.json');
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const MAP_CONFIG_FILE = path.join(__dirname, 'map_config.json');

// ===== 原子写文件 =====
// 先写临时文件并 fsync 落盘，再 rename 覆盖目标文件。
// 进程在写入途中被杀也不会留下半个 JSON，避免后端下次启动直接解析失败。
function writeJsonAtomic(file, data) {
  const tmp = file + '.tmp';
  const fd = fs.openSync(tmp, 'w');
  try {
    fs.writeSync(fd, JSON.stringify(data, null, 2), null, 'utf-8');
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, file);
}

// ===== 高德地图 Key 管理 =====
// Key 默认值来自环境变量，不再硬编码在源码里；实际以 map_config.json 为准
const DEFAULT_MAP_CONFIG = { amapWebKey: process.env.AMAP_WEB_KEY || '', amapHmsKey: '' };

function loadMapConfig() {
  try {
    if (fs.existsSync(MAP_CONFIG_FILE)) {
      return { ...DEFAULT_MAP_CONFIG, ...JSON.parse(fs.readFileSync(MAP_CONFIG_FILE, 'utf-8')) };
    }
  } catch (e) {}
  const cfg = { ...DEFAULT_MAP_CONFIG };
  writeJsonAtomic(MAP_CONFIG_FILE, cfg);
  return cfg;
}

function saveMapConfig(cfg) {
  writeJsonAtomic(MAP_CONFIG_FILE, { ...DEFAULT_MAP_CONFIG, ...cfg });
}

// 高德地理编码代理（后端调高德 API，隐藏 Key）
function amapGeocode(address, city = '') {
  return new Promise((resolve, reject) => {
    const cfg = loadMapConfig();
    if (!cfg.amapWebKey) { reject(new Error('高德 Key 未配置')); return; }
    let url = `https://restapi.amap.com/v3/geocode/geo?key=${cfg.amapWebKey}&address=${encodeURIComponent(address)}`;
    if (city) url += `&city=${encodeURIComponent(city)}`;
    https.get(url, (res) => {
      let body = '';
      res.on('data', (c) => body += c);
      res.on('end', () => {
        try { resolve(JSON.parse(body)); } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

// 高德关键词搜索（城市中心点 / POI 搜索）
function amapKeywordSearch(keywords, city = '') {
  return new Promise((resolve, reject) => {
    const cfg = loadMapConfig();
    if (!cfg.amapWebKey) { reject(new Error('高德 Key 未配置')); return; }
    let url = `https://restapi.amap.com/v3/place/text?key=${cfg.amapWebKey}&keywords=${encodeURIComponent(keywords)}&offset=20`;
    if (city) url += `&city=${encodeURIComponent(city)}`;
    https.get(url, (res) => {
      let body = '';
      res.on('data', (c) => body += c);
      res.on('end', () => {
        try { resolve(JSON.parse(body)); } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

// 确保 uploads 目录存在
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// multer 存储配置
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    const name = 'car_' + Date.now() + '_' + Math.round(Math.random() * 10000) + ext;
    cb(null, name);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 最大 5MB
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|webp|bmp/;
    if (allowed.test(path.extname(file.originalname).toLowerCase())) cb(null, true);
    else cb(new Error('只支持图片格式 (jpg/png/gif/webp)'));
  }
});

// 读取数据
// 进程内只保留一份数据对象，所有请求读写同一份：
// 1) 避免每个请求都重复解析整个 JSON 文件；
// 2) Node 单线程同步修改 + 原子写盘，写操作天然串行，不会出现两个请求互相覆盖。
// 若外部手工改了 data.json（mtime 变化），会自动重新加载，保留原有调试习惯。
let dbCache = null;
let dbMtime = 0;

function loadData() {
  const mtime = fs.statSync(DATA_FILE).mtimeMs;
  if (!dbCache || mtime !== dbMtime) {
    dbCache = JSON.parse(fs.readFileSync(DATA_FILE, 'utf-8'));
    dbMtime = mtime;
  }
  return dbCache;
}

// 写入数据（持久化）
function saveData(data) {
  if (data) dbCache = data;
  if (!dbCache) return;
  writeJsonAtomic(DATA_FILE, dbCache);
  dbMtime = fs.statSync(DATA_FILE).mtimeMs;
}

// ===== ID 生成 =====
// 生成不会重复的编码：同一毫秒内并发创建时追加序号，避免 Date.now() 撞车
function uniqueCode(items, field, prefix) {
  const base = prefix + Date.now();
  let code = base;
  let seq = 1;
  while (items.some((item) => item[field] === code)) {
    seq += 1;
    code = base + '-' + seq;
  }
  return code;
}

// 取现有最大编号 +1，避免删除中间项后新建又复用已存在的 id
function nextSeqCode(items, prefix, idPattern) {
  let max = 0;
  (items || []).forEach((item) => {
    const m = idPattern.exec(item.id);
    if (m) max = Math.max(max, Number(m[1]));
  });
  return prefix + String(max + 1).padStart(3, '0');
}

// ===== 用户账号与登录态 =====
// 演示用短信验证码：项目未接入真实短信服务，服务端固定校验 1234
const SMS_CODE = '1234';
const TOKEN_TTL = 30 * 24 * 60 * 60 * 1000; // 30 天

function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return salt + ':' + hash;
}

function verifyPassword(password, stored) {
  if (!stored || stored.indexOf(':') === -1) return false;
  const parts = stored.split(':');
  const calc = crypto.scryptSync(password, parts[0], 64);
  const expected = Buffer.from(parts[1], 'hex');
  return expected.length === calc.length && crypto.timingSafeEqual(expected, calc);
}

// 手机号脱敏，返回给客户端时不暴露完整号码
function maskPhone(phone) {
  if (!phone || phone.length < 11) return phone || '';
  return phone.slice(0, 3) + '****' + phone.slice(-4);
}

// 对外输出的用户对象：永远不带密码
function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    phone: maskPhone(user.phone),
    avatar: user.avatar || '',
    memberLevel: user.memberLevel || '普通会员',
    memberExpire: user.memberExpire || '',
    points: user.points || 0,
    verified: !!user.verified
  };
}

function issueToken(data, userId) {
  const now = Date.now();
  // 顺手清理过期会话
  data.sessions = (data.sessions || []).filter((s) => s.expiresAt > now);
  const token = crypto.randomBytes(24).toString('hex');
  data.sessions.push({ token, userId, createdAt: now, expiresAt: now + TOKEN_TTL });
  return token;
}

// 从 Authorization: Bearer xxx 解析当前登录用户
function authUser(req) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
  if (!token) return null;
  const data = loadData();
  const now = Date.now();
  const session = (data.sessions || []).find((s) => s.token === token && s.expiresAt > now);
  if (!session) return null;
  const user = (data.users || []).find((u) => u.id === session.userId);
  return user ? { data, user } : null;
}

function createUser(data, phone, password, name) {
  const user = {
    id: nextSeqCode(data.users, 'user', /^user(\d+)$/),
    name: name || ('用户' + phone.slice(-4)),
    phone,
    password: hashPassword(password),
    avatar: '',
    memberLevel: '普通会员',
    memberExpire: '',
    points: 0,
    verified: false,
    createdAt: new Date().toISOString()
  };
  data.users.push(user);
  return user;
}

// ===== 首次启动的数据迁移 =====
// 老版本只有一个 data.user 对象，这里迁移成 users 数组，并写入演示账号
function migrateUsers() {
  const data = loadData();
  let changed = false;
  if (!Array.isArray(data.users) || data.users.length === 0) {
    data.users = [
      { id: 'user001', name: '张三', phone: '13800138000', password: hashPassword('123456'), avatar: '', memberLevel: '黄金会员', memberExpire: '2027-12-31', points: 2680, verified: true, createdAt: new Date().toISOString() },
      { id: 'user002', name: '李四', phone: '13900139001', password: hashPassword('123456'), avatar: '', memberLevel: '白银会员', memberExpire: '2026-12-31', points: 580, verified: true, createdAt: new Date().toISOString() },
      { id: 'user003', name: '王五', phone: '13700137002', password: hashPassword('123456'), avatar: '', memberLevel: '钻石会员', memberExpire: '2027-06-30', points: 5200, verified: true, createdAt: new Date().toISOString() },
      { id: 'user004', name: '赵六', phone: '13600136003', password: hashPassword('123456'), avatar: '', memberLevel: '普通会员', memberExpire: '', points: 120, verified: false, createdAt: new Date().toISOString() },
      { id: 'user005', name: '孙七', phone: '13500135004', password: hashPassword('123456'), avatar: '', memberLevel: '黄金会员', memberExpire: '2026-11-30', points: 1580, verified: true, createdAt: new Date().toISOString() }
    ];
    changed = true;
  }
  if (!Array.isArray(data.sessions)) {
    data.sessions = [];
    changed = true;
  }
  if (data.user) {
    delete data.user; // 旧的单用户对象已由 users 取代
    changed = true;
  }
  if (changed) saveData(data);
}

// ===== Banner 轮播图 =====
// C 端：获取已启用的 Banner
app.get('/api/banners', (req, res) => {
  const data = loadData();
  if (!data.banners) data.banners = [];
  const list = data.banners
    .filter(b => b.enabled !== false)
    .sort((a, b) => (a.sort || 99) - (b.sort || 99));
  res.json({ code: 1, data: list });
});

// 后台：获取全部 Banner
app.get('/api/admin/banners', (req, res) => {
  const data = loadData();
  if (!data.banners) data.banners = [];
  const list = [...data.banners].sort((a, b) => (a.sort || 99) - (b.sort || 99));
  res.json({ code: 1, data: list });
});

// 后台：新增 Banner
app.post('/api/admin/banners', (req, res) => {
  const data = loadData();
  if (!data.banners) data.banners = [];
  const body = req.body || {};
  if (!body.imageUrl) return res.json({ code: 0, message: '图片地址不能为空' });
  const id = 'banner' + String(Date.now()).slice(-6);
  const banner = {
    id: id,
    imageUrl: body.imageUrl,
    title: body.title || '',
    link: body.link || '',
    sort: Number(body.sort) || 99,
    enabled: body.enabled !== false
  };
  data.banners.push(banner);
  saveData(data);
  res.json({ code: 1, data: banner });
});

// 后台：更新 Banner
app.put('/api/admin/banners/:id', (req, res) => {
  const data = loadData();
  if (!data.banners) data.banners = [];
  const idx = data.banners.findIndex(b => b.id === req.params.id);
  if (idx < 0) return res.json({ code: 0, message: 'Banner 不存在' });
  const body = req.body || {};
  data.banners[idx] = { ...data.banners[idx], ...body };
  saveData(data);
  res.json({ code: 1, data: data.banners[idx] });
});

// 后台：删除 Banner
app.delete('/api/admin/banners/:id', (req, res) => {
  const data = loadData();
  if (!data.banners) data.banners = [];
  const idx = data.banners.findIndex(b => b.id === req.params.id);
  if (idx < 0) return res.json({ code: 0, message: 'Banner 不存在' });
  data.banners.splice(idx, 1);
  saveData(data);
  res.json({ code: 1 });
});

// ===== 高德地图 Key 管理 =====
app.get('/api/admin/map-config', (req, res) => {
  const cfg = loadMapConfig();
  // Web Key 脱敏显示
  let maskedKey = '';
  if (cfg.amapWebKey && cfg.amapWebKey.length >= 12) {
    maskedKey = cfg.amapWebKey.slice(0, 6) + '****' + cfg.amapWebKey.slice(-4);
  }
  res.json({ code: 1, data: { ...cfg, amapWebKey: maskedKey } });
});

app.post('/api/admin/map-config', (req, res) => {
  const body = req.body || {};
  const current = loadMapConfig();
  // 如果新 key 包含 ****，说明是脱敏值，保持原值
  const newWebKey = (body.amapWebKey && !body.amapWebKey.includes('****'))
    ? body.amapWebKey : current.amapWebKey;
  saveMapConfig({ amapWebKey: newWebKey, amapHmsKey: body.amapHmsKey || current.amapHmsKey });
  res.json({ code: 1, message: '高德 Key 已保存' });
});

// ===== 高德代理接口（C 端调用，后端隐藏 Web Key）=====
// 地理编码：地址→经纬度
app.get('/api/geo/encode', async (req, res) => {
  const address = req.query.address || '';
  const city = req.query.city || '';
  if (!address) return res.json({ code: 0, message: '请传入 address' });
  try {
    const r = await amapGeocode(address, city);
    if (r.geocodes && r.geocodes.length > 0) {
      const loc = r.geocodes[0].location.split(',');
      res.json({
        code: 1,
        data: {
          lng: parseFloat(loc[0]),
          lat: parseFloat(loc[1]),
          city: r.geocodes[0].province || '',
          district: r.geocodes[0].district || '',
          formatted: r.geocodes[0].formatted_address || address
        }
      });
    } else {
      res.json({ code: 0, message: '未找到该地址' });
    }
  } catch (e) {
    res.json({ code: 0, message: '地理编码失败：' + e.message });
  }
});

// 城市搜索：根据关键词找城市中心点（用于地图定位）
app.get('/api/geo/search', async (req, res) => {
  const q = req.query.q || req.query.keywords || '';
  if (!q) return res.json({ code: 0, message: '请传入 q' });
  try {
    const r = await amapKeywordSearch(q);
    res.json({ code: 1, data: r.pois || [] });
  } catch (e) {
    res.json({ code: 0, message: '搜索失败：' + e.message });
  }
});

// C 端：门店列表（支持 ?city= 按城市过滤）
app.get('/api/stores', (req, res) => {
  const data = loadData();
  const city = (req.query.city || '').toString();
  let list = data.stores || [];
  if (city) {
    list = list.filter(s => (s.city || '').includes(city));
  }
  res.json({ code: 1, data: list });
});

// ===== 高德地图 H5 页面（内嵌到 HarmonyOS Web 组件）=====
app.get('/api/map/stores', (req, res) => {
  const data = loadData();
  const cfg = loadMapConfig();
  const city = (req.query.city || '').toString();
  let list = (data.stores || []).filter(s => (s.lng || 0) > 0 && (s.lat || 0) > 0);
  if (city) {
    list = list.filter(s => (s.city || '').includes(city));
  }

  // 计算中心点（所有门店经纬度平均值）
  let avgLng = 121.4737, avgLat = 31.2304;
  if (list.length > 0) {
    avgLng = list.reduce((s, x) => s + x.lng, 0) / list.length;
    avgLat = list.reduce((s, x) => s + x.lat, 0) / list.length;
  }

  const selectMode = (req.query.select || '') === '1';

  const markers = list.map(s => `
    { id: ${JSON.stringify(s.id)}, name: ${JSON.stringify(s.name)}, position: [${s.lng}, ${s.lat}], content: '<div style="padding:4px 8px;background:#FF6B35;color:white;border-radius:12px;font-size:12px;white-space:nowrap;box-shadow:0 2px 6px rgba(0,0,0,.2);">📍 ${s.name}</div>' }
  `).join(',');

  const html = `<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>哈喽租车门店地图</title>
<style>html,body,#m{margin:0;padding:0;height:100%;width:100%;font-family:-apple-system,sans-serif;}</style>
<script src="https://webapi.amap.com/maps?v=2.0&key=${cfg.amapWebKey}"></script>
</head><body><div id="m"></div>
<script>
var map = new AMap.Map('m', { zoom: 11, center: [${avgLng}, ${avgLat}], viewMode: '3D', pitch: 30 });
var selectMode = ${selectMode ? 'true' : 'false'};
var markers = [${markers}];
markers.forEach(function(m){
  var mk = new AMap.Marker({ position: m.position, content: m.content, offset: new AMap.Pixel(-40, -15), cursor: 'pointer' });
  // 点击门店标签：通知 HarmonyOS 端（选择模式用于下单时选址）
  mk.on('click', function(){
    if (window.ohosBridge && window.ohosBridge.onStoreSelect) {
      window.ohosBridge.onStoreSelect(m.id);
    }
    if (selectMode) {
      mk.setContent('<div style="padding:4px 10px;background:#1A1A1A;color:white;border-radius:12px;font-size:12px;white-space:nowrap;box-shadow:0 4px 10px rgba(0,0,0,.3);">✓ ' + m.name + '</div>');
      mk.setOffset(new AMap.Pixel(-40, -15));
    }
  });
  map.add(mk);
});
${selectMode ? `var tip = document.createElement('div');
tip.style.cssText = 'position:absolute;top:12px;left:50%;transform:translateX(-50%);background:rgba(0,0,0,.68);color:#fff;padding:7px 14px;border-radius:16px;font-size:12px;z-index:99;white-space:nowrap;';
tip.textContent = '点击地图上的门店标签即可选中';
document.body.appendChild(tip);` : ''}
if (markers.length > 0) {
  map.setFitView();
}
map.addControl(new AMap.ToolBar({ position: 'RB' }));
</script></body></html>`;
  res.type('html').send(html);
});

// ===== C 端路由 =====

// 健康检查
app.get('/', (req, res) => {
  res.json({ code: 1, message: 'Hello 租车后端运行中 ✅', time: new Date().toLocaleString() });
});

// 获取车辆列表
app.get('/api/cars', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.cars });
});

// 搜索车辆（必须注册在 /api/cars/:id 之前，否则 search 会被当成 id 匹配）
app.get('/api/cars/search', (req, res) => {
  const data = loadData();
  const keyword = (req.query.q || '').toLowerCase();
  const results = data.cars.filter(c =>
    c.name.toLowerCase().includes(keyword) || c.brand.toLowerCase().includes(keyword)
  );
  res.json({ code: 1, data: results });
});

// 获取单个车辆
app.get('/api/cars/:id', (req, res) => {
  const data = loadData();
  const car = data.cars.find(c => c.id === req.params.id);
  if (car) res.json({ code: 1, data: car });
  else res.json({ code: 0, message: '车辆不存在' });
});

// 获取订单列表
app.get('/api/orders', (req, res) => {
  const data = loadData();
  const status = req.query.status;
  let list = data.orders;
  if (status) {
    list = list.filter(o => o.status === status.toUpperCase());
  }
  res.json({ code: 1, data: list });
});

// 获取订单详情
app.get('/api/orders/:id', (req, res) => {
  const data = loadData();
  const order = data.orders.find(o => o.id === req.params.id);
  if (order) res.json({ code: 1, data: order });
  else res.json({ code: 0, message: '订单不存在' });
});

// ===== 注册 / 登录 / 当前用户 =====

// 注册：手机号 + 验证码 + 密码，账号信息落库到 data.json 的 users
app.post('/api/register', (req, res) => {
  const { phone, code, password, name } = req.body || {};
  if (!/^1[3-9]\d{9}$/.test(phone || '')) return res.json({ code: 0, message: '请输入正确的 11 位手机号' });
  if (code !== SMS_CODE) return res.json({ code: 0, message: '验证码错误（演示验证码 ' + SMS_CODE + '）' });
  if (!password || password.length < 6 || password.length > 20) return res.json({ code: 0, message: '密码需为 6-20 位' });
  const data = loadData();
  if (data.users.some((u) => u.phone === phone)) {
    return res.json({ code: 0, message: '该手机号已注册，请直接登录' });
  }
  const user = createUser(data, phone, password, name);
  const token = issueToken(data, user.id);
  saveData(data);
  res.json({ code: 1, data: { token, user: publicUser(user) }, message: '注册成功' });
});

// 登录：传 password 走密码登录；传 code 走验证码登录（未注册手机号自动创建账号）
app.post('/api/login', (req, res) => {
  const { phone, code, password } = req.body || {};
  if (!/^1[3-9]\d{9}$/.test(phone || '')) return res.json({ code: 0, message: '请输入正确的 11 位手机号' });
  const data = loadData();
  let user = data.users.find((u) => u.phone === phone);

  if (password) {
    if (!user) return res.json({ code: 0, message: '该手机号未注册，请先注册' });
    if (!verifyPassword(password, user.password)) return res.json({ code: 0, message: '手机号或密码错误' });
  } else {
    if (code !== SMS_CODE) return res.json({ code: 0, message: '验证码错误（演示验证码 ' + SMS_CODE + '）' });
    if (!user) {
      user = createUser(data, phone, '123456', '');
    }
  }

  user.lastLoginAt = new Date().toISOString();
  const token = issueToken(data, user.id);
  saveData(data);
  res.json({ code: 1, data: { token, user: publicUser(user) }, message: '登录成功' });
});

// 退出登录：销毁当前 token
app.post('/api/logout', (req, res) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
  const data = loadData();
  const before = (data.sessions || []).length;
  data.sessions = (data.sessions || []).filter((s) => s.token !== token);
  if (data.sessions.length !== before) saveData(data);
  res.json({ code: 1, message: '已退出登录' });
});

// 获取当前登录用户信息
app.get('/api/user', (req, res) => {
  const auth = authUser(req);
  if (!auth) return res.status(401).json({ code: 0, message: '未登录或登录已失效' });
  res.json({ code: 1, data: publicUser(auth.user) });
});

// 上传头像：客户端把图片转成 base64 后提交，服务端解码落盘并更新用户
app.post('/api/user/avatar', (req, res) => {
  const auth = authUser(req);
  if (!auth) return res.status(401).json({ code: 0, message: '未登录或登录已失效' });
  const { base64, ext } = req.body || {};
  if (!base64) return res.json({ code: 0, message: '请选择图片' });
  const suffix = String(ext || 'jpg').toLowerCase().replace('.', '');
  if (['jpg', 'jpeg', 'png', 'webp'].indexOf(suffix) === -1) {
    return res.json({ code: 0, message: '只支持 jpg/png/webp 格式' });
  }
  const buf = Buffer.from(base64, 'base64');
  if (!buf.length) return res.json({ code: 0, message: '图片解析失败' });
  if (buf.length > 2 * 1024 * 1024) return res.json({ code: 0, message: '头像不能超过 2MB' });

  const filename = 'avatar_' + auth.user.id + '_' + Date.now() + '.' + suffix;
  fs.writeFileSync(path.join(UPLOAD_DIR, filename), buf);

  // 删除该用户上一张头像文件，避免 uploads 目录越堆越多
  const oldAvatar = auth.user.avatar || '';
  if (oldAvatar.startsWith('/uploads/avatar_')) {
    try {
      fs.unlinkSync(path.join(UPLOAD_DIR, path.basename(oldAvatar)));
    } catch (e) {
      // 旧文件不存在时忽略
    }
  }

  auth.user.avatar = '/uploads/' + filename;
  saveData(auth.data);
  res.json({ code: 1, data: publicUser(auth.user), message: '头像已更新' });
});

// 获取优惠券
app.get('/api/coupons', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.coupons });
});

// 创建订单（下单成功即落库，状态为待支付）
app.post('/api/orders', (req, res) => {
  const data = loadData();
  const { carId, days, pickupStore, returnStore, pickupTime, returnTime, discount, insurance } = req.body || {};
  const car = data.cars.find(c => c.id === carId);
  if (!car) return res.json({ code: 0, message: '车辆不存在' });
  const rentDays = Number(days) || 3;
  const order = {
    id: uniqueCode(data.orders, 'id', 'order'),
    orderNo: uniqueCode(data.orders, 'orderNo', 'HC'),
    carName: car.name,
    carImage: car.imageUrl,
    pickupStore: pickupStore || '浦东机场 T2 航站楼店',
    returnStore: returnStore || pickupStore || '浦东机场 T2 航站楼店',
    pickupTime: pickupTime || new Date().toLocaleString(),
    returnTime: returnTime || new Date(Date.now() + rentDays * 86400000).toLocaleString(),
    days: rentDays,
    totalPrice: car.pricePerDay * rentDays,
    discount: Number(discount) || 0,
    insurance: Number(insurance) || 0,
    status: 'PENDING',
    createTime: new Date().toLocaleString()
  };
  data.orders.unshift(order);
  saveData(data);
  res.json({ code: 1, data: order });
});

// 更新订单状态（支付、取车、还车、结算等环节调用）
app.post('/api/orders/:id/status', (req, res) => {
  const data = loadData();
  const order = data.orders.find(o => o.id === req.params.id);
  if (!order) return res.json({ code: 0, message: '订单不存在' });
  const status = String((req.body || {}).status || '').toUpperCase();
  const allowed = ['PENDING', 'CONFIRMED', 'PICKED_UP', 'IN_USE', 'RETURNED', 'COMPLETED', 'CANCELLED'];
  if (allowed.indexOf(status) === -1) return res.json({ code: 0, message: '订单状态不合法' });
  order.status = status;
  order.updateTime = new Date().toLocaleString();
  saveData(data);
  res.json({ code: 1, data: order });
});

// ===== 管理端 API =====

// 仪表盘统计
app.get('/api/admin/stats', (req, res) => {
  const data = loadData();
  const totalOrders = data.orders.length;
  const completedOrders = data.orders.filter(o => o.status === 'COMPLETED').length;
  const inUseOrders = data.orders.filter(o => o.status === 'IN_USE').length;
  const confirmedOrders = data.orders.filter(o => o.status === 'CONFIRMED').length;
  const cancelledOrders = data.orders.filter(o => o.status === 'CANCELLED').length;
  const totalRevenue = data.orders.reduce((sum, o) => sum + (o.totalPrice || 0), 0);
  const availableCars = data.cars.filter(c => c.inventory > 0).length;
  const totalInventory = data.cars.reduce((sum, c) => sum + (c.inventory || 0), 0);

  res.json({
    code: 1,
    data: {
      totalCars: data.cars.length,
      availableCars,
      totalInventory,
      totalStores: data.stores.length,
      totalOrders,
      completedOrders,
      inUseOrders,
      confirmedOrders,
      cancelledOrders,
      totalRevenue,
      totalCoupons: data.coupons ? data.coupons.length : 0,
      carBrands: [...new Set(data.cars.map(c => c.brand))],
      recentOrders: data.orders.slice(0, 5),
      topCars: [...data.cars].sort((a, b) => (b.orderCount || 0) - (a.orderCount || 0)).slice(0, 5)
    }
  });
});

// ===== 车辆管理 =====

// 获取所有车辆
app.get('/api/admin/cars', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.cars });
});

// 新增车辆
app.post('/api/admin/cars', (req, res) => {
  const data = loadData();
  const body = req.body || {};
  const newCar = {
    id: nextSeqCode(data.cars, 'car', /^car(\d+)$/),
    name: body.name || '',
    brand: body.brand || '',
    imageUrl: body.imageUrl || '🚗',
    pricePerDay: Number(body.pricePerDay) || 0,
    originalPrice: Number(body.originalPrice) || 0,
    seats: Number(body.seats) || 5,
    transmission: body.transmission || '自动',
    fuelType: body.fuelType || '汽油',
    displacement: body.displacement || '',
    inventory: Number(body.inventory) || 0,
    features: Array.isArray(body.features) ? body.features : [],
    rating: Number(body.rating) || 4.5,
    orderCount: 0
  };
  data.cars.push(newCar);
  saveData(data);
  res.json({ code: 1, data: newCar, message: '新增成功' });
});

// 更新车辆
app.put('/api/admin/cars/:id', (req, res) => {
  const data = loadData();
  const idx = data.cars.findIndex(c => c.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '车辆不存在' });
  const body = req.body || {};
  const car = data.cars[idx];
  data.cars[idx] = {
    ...car,
    ...body,
    pricePerDay: Number(body.pricePerDay ?? car.pricePerDay),
    originalPrice: Number(body.originalPrice ?? car.originalPrice),
    seats: Number(body.seats ?? car.seats),
    inventory: Number(body.inventory ?? car.inventory),
    rating: Number(body.rating ?? car.rating),
    features: Array.isArray(body.features) ? body.features : car.features
  };
  saveData(data);
  res.json({ code: 1, data: data.cars[idx], message: '更新成功' });
});

// 删除车辆
app.delete('/api/admin/cars/:id', (req, res) => {
  const data = loadData();
  const idx = data.cars.findIndex(c => c.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '车辆不存在' });
  data.cars.splice(idx, 1);
  saveData(data);
  res.json({ code: 1, message: '删除成功' });
});

// ===== 门店管理 =====

// 获取所有门店
app.get('/api/admin/stores', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.stores });
});

// 自动解析地址经纬度的辅助函数
async function enrichStoreGeo(store) {
  try {
    // 如果没传 lng/lat，自动解析
    if ((!store.lng || !store.lat) && store.address) {
      const city = store.city || '';
      const r = await amapGeocode(store.address, city);
      if (r.geocodes && r.geocodes.length > 0) {
        const loc = r.geocodes[0].location.split(',');
        store.lng = parseFloat(loc[0]);
        store.lat = parseFloat(loc[1]);
        if (!store.city) store.city = r.geocodes[0].province || '';
      }
    }
  } catch (e) {
    console.error('geo encode error:', e.message);
  }
  return store;
}

// 新增门店（自动解析经纬度）
app.post('/api/admin/stores', wrapAsync(async (req, res) => {
  const data = loadData();
  const body = req.body || {};
  let newStore = {
    id: 'store' + String(Date.now()).slice(-6),
    name: body.name || '',
    address: body.address || '',
    lng: body.lng || 0,
    lat: body.lat || 0,
    city: body.city || '',
    distance: body.distance || '',
    phone: body.phone || '',
    hours: body.hours || '',
    hasPickup: Boolean(body.hasPickup)
  };
  newStore = await enrichStoreGeo(newStore);
  data.stores.push(newStore);
  saveData(data);
  res.json({ code: 1, data: newStore, message: '新增成功' });
}));

// 更新门店（自动解析经纬度）
app.put('/api/admin/stores/:id', wrapAsync(async (req, res) => {
  const data = loadData();
  const idx = data.stores.findIndex(s => s.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '门店不存在' });
  const body = req.body || {};
  let merged = { ...data.stores[idx], ...body, hasPickup: Boolean(body.hasPickup) };
  // 如果地址变了但没传经纬度，重新解析
  if (body.address && body.address !== data.stores[idx].address && !body.lng) {
    merged.lng = 0; merged.lat = 0;
    merged = await enrichStoreGeo(merged);
  } else if (!merged.lng || !merged.lat) {
    merged = await enrichStoreGeo(merged);
  }
  data.stores[idx] = merged;
  saveData(data);
  res.json({ code: 1, data: data.stores[idx], message: '更新成功' });
}));

// 删除门店
app.delete('/api/admin/stores/:id', (req, res) => {
  const data = loadData();
  const idx = data.stores.findIndex(s => s.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '门店不存在' });
  data.stores.splice(idx, 1);
  saveData(data);
  res.json({ code: 1, message: '删除成功' });
});

// ===== 订单管理 =====

// 获取所有订单（管理端）
app.get('/api/admin/orders', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.orders });
});

// 更新订单状态
app.put('/api/admin/orders/:id/status', (req, res) => {
  const data = loadData();
  const idx = data.orders.findIndex(o => o.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '订单不存在' });
  const { status } = req.body || {};
  const validStatuses = ['PENDING', 'CONFIRMED', 'IN_USE', 'COMPLETED', 'CANCELLED'];
  if (!validStatuses.includes(status)) return res.json({ code: 0, message: '无效状态' });
  data.orders[idx].status = status;
  saveData(data);
  res.json({ code: 1, data: data.orders[idx], message: '状态更新成功' });
});

// 删除订单
app.delete('/api/admin/orders/:id', (req, res) => {
  const data = loadData();
  const idx = data.orders.findIndex(o => o.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '订单不存在' });
  data.orders.splice(idx, 1);
  saveData(data);
  res.json({ code: 1, message: '删除成功' });
});

// ===== 用户管理 =====

// 获取用户列表（真实注册用户，不返回密码）
app.get('/api/admin/users', (req, res) => {
  const data = loadData();
  const users = (data.users || []).map((u) => ({
    id: u.id,
    name: u.name,
    phone: u.phone,
    avatar: u.avatar || '',
    memberLevel: u.memberLevel || '普通会员',
    memberExpire: u.memberExpire || '',
    points: u.points || 0,
    verified: !!u.verified,
    createdAt: u.createdAt || '',
    lastLoginAt: u.lastLoginAt || ''
  }));
  res.json({ code: 1, data: users });
});

// ===== 优惠券管理 =====

// 获取优惠券列表
app.get('/api/admin/coupons', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.coupons });
});

// 新增优惠券
app.post('/api/admin/coupons', (req, res) => {
  const data = loadData();
  const body = req.body || {};
  const newCoupon = {
    id: nextSeqCode(data.coupons, 'cp', /^cp(\d+)$/),
    name: body.name || '',
    discount: Number(body.discount) || 0,
    threshold: Number(body.threshold) || 0,
    expireDate: body.expireDate || '',
    used: false
  };
  if (!data.coupons) data.coupons = [];
  data.coupons.push(newCoupon);
  saveData(data);
  res.json({ code: 1, data: newCoupon, message: '新增成功' });
});

// 删除优惠券
app.delete('/api/admin/coupons/:id', (req, res) => {
  const data = loadData();
  if (!data.coupons) return res.json({ code: 0, message: '优惠券不存在' });
  const idx = data.coupons.findIndex(c => c.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '优惠券不存在' });
  data.coupons.splice(idx, 1);
  saveData(data);
  res.json({ code: 1, message: '删除成功' });
});

// ===== 图片上传 API =====

// 上传车辆图片
app.post('/api/admin/upload', upload.single('file'), (req, res) => {
  if (!req.file) return res.json({ code: 0, message: '请选择文件' });
  const url = '/uploads/' + req.file.filename;
  res.json({
    code: 1,
    data: {
      url,
      filename: req.file.filename,
      size: req.file.size
    },
    message: '上传成功'
  });
});

// ===== AI 配置存储 =====
const AI_CONFIG_FILE = path.join(__dirname, 'ai_config.json');

function loadAIConfig() {
  try { return JSON.parse(fs.readFileSync(AI_CONFIG_FILE, 'utf-8')); }
  catch (e) { return { apiKey: '', model: 'deepseek-chat', baseUrl: 'https://api.deepseek.com/v1', systemPrompt: '你是哈喽租车客服小哈。', temperature: 0.7, maxTokens: 1024 }; }
}

function saveAIConfig(cfg) {
  writeJsonAtomic(AI_CONFIG_FILE, cfg);
}

// ===== 后台：读写 AI 配置 =====
app.get('/api/admin/ai-config', (req, res) => {
  const cfg = loadAIConfig();
  // 返回时隐藏完整 key，只显示最后 4 位
  const maskedKey = cfg.apiKey ? cfg.apiKey.slice(0, 8) + '****' + cfg.apiKey.slice(-4) : '';
  res.json({
    code: 1,
    data: {
      hasKey: !!cfg.apiKey,
      maskedKey: maskedKey,
      model: cfg.model,
      baseUrl: cfg.baseUrl,
      systemPrompt: cfg.systemPrompt,
      temperature: cfg.temperature,
      maxTokens: cfg.maxTokens
    }
  });
});

app.post('/api/admin/ai-config', (req, res) => {
  const cfg = loadAIConfig();
  const body = req.body || {};
  // 如果前端传了 apiKey 且不为空，则更新；否则保留原值
  if (body.apiKey && body.apiKey.trim()) cfg.apiKey = body.apiKey.trim();
  if (body.model) cfg.model = body.model;
  if (body.baseUrl) cfg.baseUrl = body.baseUrl;
  if (body.systemPrompt) cfg.systemPrompt = body.systemPrompt;
  if (typeof body.temperature === 'number') cfg.temperature = body.temperature;
  if (typeof body.maxTokens === 'number') cfg.maxTokens = body.maxTokens;
  saveAIConfig(cfg);
  res.json({ code: 1, message: 'AI 配置已保存' });
});

// ===== C 端：AI 聊天接口 =====
// 请求体: { messages: [{role: 'user', content: '你好'}, ...] }
app.post('/api/ai/chat', async (req, res) => {
  try {
    const cfg = loadAIConfig();
    if (!cfg.apiKey) {
      return res.json({ code: 0, message: 'AI Key 未配置，请联系管理员在后台设置' });
    }
    const messages = req.body.messages || [];
    if (!messages.length) {
      return res.json({ code: 0, message: '消息不能为空' });
    }
    // 组装请求：system prompt + 历史消息
    const apiMessages = [
      { role: 'system', content: cfg.systemPrompt },
      ...messages
    ];
    const response = await fetch(cfg.baseUrl + '/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + cfg.apiKey
      },
      body: JSON.stringify({
        model: cfg.model,
        messages: apiMessages,
        temperature: cfg.temperature,
        max_tokens: cfg.maxTokens
      })
    });
    if (!response.ok) {
      const errText = await response.text();
      console.error('DeepSeek API error:', response.status, errText);
      return res.json({ code: 0, message: 'AI 服务异常 (' + response.status + ')' });
    }
    const data = await response.json();
    const reply = data.choices && data.choices[0] && data.choices[0].message
      ? data.choices[0].message.content
      : '抱歉，我没理解你的意思 🤔';
    res.json({ code: 1, data: { reply: reply } });
  } catch (e) {
    console.error('AI chat error:', e);
    res.json({ code: 0, message: '服务器内部错误' });
  }
});

// ===== 静态文件托管 =====
app.use('/uploads', express.static(UPLOAD_DIR));
app.use('/admin', express.static(path.join(__dirname, 'admin')));

// ===== 统一错误处理 =====
// 兜住未匹配的路由与所有路由抛出的异常，统一返回 JSON，不再把堆栈直接吐给前端
app.use((req, res) => {
  res.status(404).json({ code: 0, message: '接口不存在: ' + req.method + ' ' + req.originalUrl });
});

app.use((err, req, res, next) => {
  console.error('[api error]', req.method, req.originalUrl, err && err.stack ? err.stack : err);
  if (res.headersSent) return next(err);
  const isUploadError = err && (err.code === 'LIMIT_FILE_SIZE' || err.message === '只支持图片格式 (jpg/png/gif/webp)');
  res.status(isUploadError ? 400 : 500).json({
    code: 0,
    message: isUploadError ? (err.message || '图片超过 5MB 限制') : '服务器内部错误'
  });
});

// 进程级兜底：记录但不退出，保证演示时单个异常不会让整个后端挂掉
process.on('uncaughtException', (err) => {
  console.error('[uncaughtException]', err && err.stack ? err.stack : err);
});
process.on('unhandledRejection', (err) => {
  console.error('[unhandledRejection]', err && err.stack ? err.stack : err);
});

// ===== 启动 =====
// 启动前先加载一次数据，data.json 损坏时立刻报错，而不是拖到第一个请求
loadData();
migrateUsers();

app.listen(PORT, '0.0.0.0', () => {
  const net = require('os').networkInterfaces();
  console.log('=================================');
  console.log('🚗 Hello 租车后端已启动');
  console.log('   本机API:    http://localhost:' + PORT);
  console.log('   管理后台:   http://localhost:' + PORT + '/admin');
  console.log('=================================');
  Object.values(net).forEach(nets => {
    nets.forEach(n => {
      if (n.family === 'IPv4' && !n.internal) {
        console.log('   局域网API:  http://' + n.address + ':' + PORT);
        console.log('   局域网后台: http://' + n.address + ':' + PORT + '/admin');
      }
    });
  });
  console.log('=================================');
});
