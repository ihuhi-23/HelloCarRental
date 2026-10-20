const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

const DATA_FILE = path.join(__dirname, 'data.json');
const UPLOAD_DIR = path.join(__dirname, 'uploads');

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

// 新增门店
app.post('/api/admin/stores', (req, res) => {
  const data = loadData();
  const body = req.body || {};
  const newStore = {
    id: 'store' + String(data.stores.length + 1).padStart(3, '0'),
    name: body.name || '',
    address: body.address || '',
    distance: body.distance || '',
    phone: body.phone || '',
    hours: body.hours || '',
    hasPickup: Boolean(body.hasPickup)
  };
  data.stores.push(newStore);
  saveData(data);
  res.json({ code: 1, data: newStore, message: '新增成功' });
});

// 更新门店
app.put('/api/admin/stores/:id', (req, res) => {
  const data = loadData();
  const idx = data.stores.findIndex(s => s.id === req.params.id);
  if (idx === -1) return res.json({ code: 0, message: '门店不存在' });
  const body = req.body || {};
  data.stores[idx] = { ...data.stores[idx], ...body, hasPickup: Boolean(body.hasPickup) };
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
