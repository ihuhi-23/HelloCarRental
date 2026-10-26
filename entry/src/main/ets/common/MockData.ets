import { CarInfo, StoreInfo, OrderInfo, OrderStatus, Coupon, UserInfo, PaymentMethod, ChatMessage, ViolationRecord } from './Interfaces';

/**
 * Mock 兜底数据（不是主数据源）
 * 仅在 HttpUtil 请求失败时回退使用；后端可用时页面展示的是真实接口数据
 */

// 车辆列表：fetchHomeCars 失败时兜底（首页展示）
export const mockCarList: CarInfo[] = [
  {
    id: 'car001',
    name: '宝马 3系 325Li',
    brand: '宝马',
    imageUrl: 'https://www.bmw.com.cn/content/dam/bmw/marketCN/common/all-models/sales_promotion/20241231/4series_coupe_inspire_kv.jpg/jcr:content/renditions/cq5dam.resized.img.1680.large.time1735526344048.jpg',
    pricePerDay: 298,
    originalPrice: 358,
    seats: 5,
    transmission: '自动',
    fuelType: '汽油',
    displacement: '2.0T',
    inventory: 2,
    features: ['真皮座椅', '倒车影像', '定速巡航'],
    rating: 4.9,
    orderCount: 1280
  },
  {
    id: 'car002',
    name: '丰田凯美瑞 2.5G',
    brand: '丰田',
    imageUrl: 'https://img1.xcarimg.com/b166/s15792/2000_1500_20230420164232892327304977859.jpg',
    pricePerDay: 198,
    originalPrice: 238,
    seats: 5,
    transmission: '自动',
    fuelType: '汽油',
    displacement: '2.5L',
    inventory: 5,
    features: ['省油耐造', '空间宽敞', '舒适静音'],
    rating: 4.8,
    orderCount: 2150
  },
  {
    id: 'car003',
    name: '大众帕萨特 380TSI',
    brand: '大众',
    imageUrl: 'https://img3.bitautoimg.com/autoalbum/files/20210916/683/202109161202.JPG',
    pricePerDay: 228,
    seats: 5,
    transmission: '自动',
    fuelType: '汽油',
    displacement: '2.0T',
    inventory: 3,
    features: ['商务首选', '动力充沛'],
    rating: 4.7,
    orderCount: 960
  },
  {
    id: 'car004',
    name: '别克GL8 ES 豪华型',
    brand: '别克',
    imageUrl: 'https://img.pcauto.com.cn/images/upload/upc/tx/auto5/2211/07/c0/340656290_1667785907238_1024.jpg',
    pricePerDay: 388,
    seats: 7,
    transmission: '自动',
    fuelType: '汽油',
    displacement: '2.0T',
    inventory: 1,
    features: ['7座MPV', '商务出行', '电动滑门'],
    rating: 4.9,
    orderCount: 580
  },
  {
    id: 'car005',
    name: '特斯拉 Model 3',
    brand: '特斯拉',
    imageUrl: 'https://img.pcauto.com.cn/images/upload/upc/tx/auto5/2108/26/c10/275773173_1629967518523.jpg',
    pricePerDay: 328,
    originalPrice: 398,
    seats: 5,
    transmission: '自动',
    fuelType: '纯电动',
    displacement: '-',
    inventory: 4,
    features: ['自动驾驶', '大屏中控', '零排放'],
    rating: 4.8,
    orderCount: 1420
  },
  {
    id: 'car006',
    name: '奔驰C级 C260L',
    brand: '奔驰',
    imageUrl: 'https://ts1.tc.mm.bing.net/th/id/R-C.e60e2ca018be3dd57b32e7dfea8b87a4?rik=9biMuEUEnMviCg&riu=http%3a%2f%2fn.sinaimg.cn%2fsinacn20115%2f600%2fw1920h1080%2f20190103%2fe1d0-hqzxptp1135831.jpg&ehk=wXTsR19pzZsh8cg47A9x7c1iHNpjVxStZh%2be2zg179A%3d&risl=&pid=ImgRaw&r=0',
    pricePerDay: 458,
    seats: 5,
    transmission: '自动',
    fuelType: '汽油',
    displacement: '1.5T',
    inventory: 2,
    features: ['豪华品牌', '内饰精致'],
    rating: 4.9,
    orderCount: 720
  }
];

// 门店列表：fetchStores 失败时兜底（门店查询、确认订单、还车确认）
export const mockStoreList: StoreInfo[] = [
  {
    id: 'store001',
    name: '浦东机场 T2 航站楼店',
    address: '上海市浦东新区浦东机场T2航站楼出发层',
    distance: '1.2km',
    phone: '021-12345678',
    hours: '24小时营业',
    hasPickup: true
  },
  {
    id: 'store002',
    name: '虹桥机场 T2 航站楼店',
    address: '上海市长宁区虹桥机场T2航站楼一层',
    distance: '8.5km',
    phone: '021-23456789',
    hours: '06:00-24:00',
    hasPickup: true
  },
  {
    id: 'store003',
    name: '人民广场步行街店',
    address: '上海市黄浦区南京东路100号',
    distance: '3.2km',
    phone: '021-34567890',
    hours: '08:00-22:00',
    hasPickup: false
  },
  {
    id: 'store004',
    name: '陆家嘴金融中心店',
    address: '上海市浦东新区陆家嘴环路200号',
    distance: '5.1km',
    phone: '021-45678901',
    hours: '08:00-22:00',
    hasPickup: true
  }
];

// 订单列表：fetchOrders / fetchOrderDetail 失败时兜底
export const mockOrderList: OrderInfo[] = [
  {
    id: 'order000',
    orderNo: 'HC2026101900000',
    carName: '宝马 3系 325Li',
    carImage: 'https://www.bmw.com.cn/content/dam/bmw/marketCN/common/all-models/sales_promotion/20241231/4series_coupe_inspire_kv.jpg/jcr:content/renditions/cq5dam.resized.img.1680.large.time1735526344048.jpg',
    pickupStore: '浦东机场 T2 航站楼店',
    returnStore: '浦东机场 T2 航站楼店',
    pickupTime: '2026-10-19 10:00',
    returnTime: '2026-10-22 10:00',
    days: 3,
    totalPrice: 894,
    status: OrderStatus.IN_USE,
    createTime: '2026-10-18 14:30',
    discount: 50,
    insurance: 30
  },
  {
    id: 'order001',
    orderNo: 'HC2026101500001',
    carName: '宝马 3系 325Li',
    carImage: 'https://www.bmw.com.cn/content/dam/bmw/marketCN/common/all-models/sales_promotion/20241231/4series_coupe_inspire_kv.jpg/jcr:content/renditions/cq5dam.resized.img.1680.large.time1735526344048.jpg',
    pickupStore: '浦东机场 T2 航站楼店',
    returnStore: '浦东机场 T2 航站楼店',
    pickupTime: '2026-10-20 10:00',
    returnTime: '2026-10-23 10:00',
    days: 3,
    totalPrice: 894,
    status: OrderStatus.CONFIRMED,
    createTime: '2026-10-15 14:30',
    discount: 50,
    insurance: 30
  },
  {
    id: 'order002',
    orderNo: 'HC2026101000002',
    carName: '丰田凯美瑞 2.5G',
    carImage: 'https://img1.xcarimg.com/b166/s15792/2000_1500_20230420164232892327304977859.jpg',
    pickupStore: '人民广场步行街店',
    returnStore: '虹桥机场 T2 航站楼店',
    pickupTime: '2026-10-12 09:00',
    returnTime: '2026-10-14 18:00',
    days: 2,
    totalPrice: 436,
    status: OrderStatus.COMPLETED,
    createTime: '2026-10-10 16:20',
    discount: 30
  },
  {
    id: 'order003',
    orderNo: 'HC2026100500003',
    carName: '特斯拉 Model 3',
    carImage: 'https://img.pcauto.com.cn/images/upload/upc/tx/auto5/2108/26/c10/275773173_1629967518523.jpg',
    pickupStore: '陆家嘴金融中心店',
    returnStore: '陆家嘴金融中心店',
    pickupTime: '2026-10-06 14:00',
    returnTime: '2026-10-09 14:00',
    days: 3,
    totalPrice: 984,
    status: OrderStatus.COMPLETED,
    createTime: '2026-10-05 10:15'
  }
];

// 优惠券列表：fetchCoupons 失败时兜底（确认订单）
export const mockCouponList: Coupon[] = [
  { id: 'cp001', name: '新用户立减券', discount: 50, threshold: 300, expireDate: '2026-12-31', used: false },
  { id: 'cp002', name: '周末出行优惠', discount: 100, threshold: 500, expireDate: '2026-11-30', used: false },
  { id: 'cp003', name: '长租专享券', discount: 200, threshold: 1000, expireDate: '2026-12-15', used: false }
];

// 用户信息：fetchUser 失败时兜底（个人中心）
export const mockUserInfo: UserInfo = {
  id: 'user001',
  name: '张三',
  phone: '138****8888',
  avatar: '👤',
  memberLevel: '黄金会员',
  memberExpire: '2027-12-31',
  points: 2680,
  verified: true
};

// 支付方式：收银台页直接使用的静态列表
export const mockPaymentMethods: PaymentMethod[] = [
  { id: 'pay001', name: '招商银行', type: 'bankcard', cardNo: '尾号 6688', isDefault: true },
  { id: 'pay002', name: '微信支付', type: 'wechat', isDefault: false },
  { id: 'pay003', name: '支付宝', type: 'alipay', isDefault: false }
];

// AI 客服示例对话：当前无页面引用（AIChat 页使用自建 ChatMsg）
export const mockChatMessages: ChatMessage[] = [
  { id: 'msg001', content: '您好！我是 Hello 租车智能小助手，很高兴为您服务😊', isUser: false, time: '09:00' },
  { id: 'msg002', content: '我想了解一下取车流程', isUser: true, time: '09:01' },
  { id: 'msg003', content: '好的！取车流程如下：\n1. 到达门店后出示身份证和驾驶证\n2. 工作人员会为您核验信息并签署合同\n3. 确认车辆外观无损伤后即可提车\n4. 押金将在还车后原路退还', isUser: false, time: '09:01' },
  { id: 'msg004', content: '我可以提前取车吗？', isUser: true, time: '09:02' },
  { id: 'msg005', content: '提前取车需要联系门店工作人员确认哦，不同门店政策可能不同。建议您提前拨打门店电话咨询～', isUser: false, time: '09:02' }
];

// 违章记录：违章查询页直接使用的静态列表（后端暂无该接口）
export const mockViolationList: ViolationRecord[] = [
  { id: 'v001', time: '2026-08-15 14:30', location: '浦东新区世纪大道', reason: '违反禁止标线指示', points: 3, fine: 200, status: '待处理' },
  { id: 'v002', time: '2026-07-20 09:15', location: '徐汇区沪闵高架', reason: '超速10%-20%', points: 3, fine: 150, status: '已处理' },
  { id: 'v003', time: '2026-06-10 18:45', location: '黄浦区延安高架', reason: '不系安全带', points: 1, fine: 50, status: '已处理' }
];
