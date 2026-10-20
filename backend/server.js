const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const https = require('https');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

const DATA_FILE = path.join(__dirname, 'data.json');
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const MAP_CONFIG_FILE = path.join(__dirname, 'map_config.json');

// ===== 高德地图 Key 管理 =====
const DEFAULT_MAP_CONFIG = { amapWebKey: '8c7cd33d18989b043109fa5b31a3cd7b', amapHmsKey: '' };

function loadMapConfig() {
  try {
    if (fs.existsSync(MAP_CONFIG_FILE)) {
      return { ...DEFAULT_MAP_CONFIG, ...JSON.parse(fs.readFileSync(MAP_CONFIG_FILE, 'utf-8')) };
    }
  } catch (e) {}
  const cfg = { ...DEFAULT_MAP_CONFIG };
  fs.writeFileSync(MAP_CONFIG_FILE, JSON.stringify(cfg, null, 2));
  return cfg;
}

function saveMapConfig(cfg) {
  fs.writeFileSync(MAP_CONFIG_FILE, JSON.stringify({ ...DEFAULT_MAP_CONFIG, ...cfg }, null, 2));
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
function loadData() {
  return JSON.parse(fs.readFileSync(DATA_FILE, 'utf-8'));
}

// 写入数据（持久化）
function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2), 'utf-8');
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

// C 端：按城市过滤门店
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

  const markers = list.map(s => `
    { position: [${s.lng}, ${s.lat}], content: '<div style="padding:4px 8px;background:#FF6B35;color:white;border-radius:12px;font-size:12px;white-space:nowrap;box-shadow:0 2px 6px rgba(0,0,0,.2);">📍 ${s.name}</div>' }
  `).join(',');

  const html = `<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>哈喽租车门店地图</title>
<style>html,body,#m{margin:0;padding:0;height:100%;width:100%;font-family:-apple-system,sans-serif;}</style>
<script src="https://webapi.amap.com/maps?v=2.0&key=${cfg.amapWebKey}"></script>
</head><body><div id="m"></div>
<script>
var map = new AMap.Map('m', { zoom: 11, center: [${avgLng}, ${avgLat}], viewMode: '3D', pitch: 30 });
var markers = [${markers}];
markers.forEach(function(m){
  var mk = new AMap.Marker({ position: m.position, content: m.content, offset: new AMap.Pixel(-40, -15) });
  map.add(mk);
});
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

// 获取单个车辆
app.get('/api/cars/:id', (req, res) => {
  const data = loadData();
  const car = data.cars.find(c => c.id === req.params.id);
  if (car) res.json({ code: 1, data: car });
  else res.json({ code: 0, message: '车辆不存在' });
});

// 搜索车辆
app.get('/api/cars/search', (req, res) => {
  const data = loadData();
  const keyword = (req.query.q || '').toLowerCase();
  const results = data.cars.filter(c =>
    c.name.toLowerCase().includes(keyword) || c.brand.toLowerCase().includes(keyword)
  );
  res.json({ code: 1, data: results });
});

// 获取门店列表
app.get('/api/stores', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.stores });
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

// 获取用户信息
app.get('/api/user', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.user });
});

// 登录（简单模拟）
app.post('/api/login', (req, res) => {
  const { phone, code } = req.body || {};
  if (!phone) return res.json({ code: 0, message: '请输入手机号' });
  if (code !== '1234') return res.json({ code: 0, message: '验证码错误' });
  const data = loadData();
  res.json({ code: 1, data: { token: 'mock_token_' + Date.now(), user: data.user } });
});

// 获取优惠券
app.get('/api/coupons', (req, res) => {
  const data = loadData();
  res.json({ code: 1, data: data.coupons });
});

// 创建订单
app.post('/api/orders', (req, res) => {
  const data = loadData();
  const { carId, days, pickupStore } = req.body || {};
  const car = data.cars.find(c => c.id === carId);
  if (!car) return res.json({ code: 0, message: '车辆不存在' });
  const order = {
    id: 'order' + Date.now(),
    orderNo: 'HC' + Date.now(),
    carName: car.name,
    carImage: car.imageUrl,
    pickupStore: pickupStore || '浦东机场 T2 航站楼店',
    returnStore: pickupStore || '浦东机场 T2 航站楼店',
    pickupTime: new Date().toLocaleString(),
    returnTime: new Date(Date.now() + (days || 3) * 86400000).toLocaleString(),
    days: days || 3,
    totalPrice: car.pricePerDay * (days || 3),
    status: 'CONFIRMED',
    createTime: new Date().toLocaleString()
  };
  data.orders.unshift(order);
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
    id: 'car' + String(data.cars.length + 1).padStart(3, '0'),
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
app.post('/api/admin/stores', async (req, res) => {
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
});

// 更新门店（自动解析经纬度）
app.put('/api/admin/stores/:id', async (req, res) => {
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
});

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

// 获取用户列表（mock，暂时返回现有用户）
app.get('/api/admin/users', (req, res) => {
  const data = loadData();
  // mock 用户列表
  const users = [
    data.user,
    { id: 'user002', name: '李四', phone: '139****6666', avatar: '👤', memberLevel: '白银会员', memberExpire: '2026-12-31', points: 580, verified: true },
    { id: 'user003', name: '王五', phone: '137****9999', avatar: '👤', memberLevel: '钻石会员', memberExpire: '2027-06-30', points: 5200, verified: true },
    { id: 'user004', name: '赵六', phone: '136****7777', avatar: '👤', memberLevel: '普通会员', memberExpire: '-', points: 120, verified: false },
    { id: 'user005', name: '孙七', phone: '135****5555', avatar: '👤', memberLevel: '黄金会员', memberExpire: '2026-11-30', points: 1580, verified: true }
  ];
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
    id: 'cp' + String((data.coupons?.length || 0) + 1).padStart(3, '0'),
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
  fs.writeFileSync(AI_CONFIG_FILE, JSON.stringify(cfg, null, 2), 'utf-8');
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

// ===== 启动 =====
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
