/**
 * 全局数据模型定义
 * 所有 interface 与后端接口返回字段一一对应，供各页面和 HttpUtil 共用
 */

// 车辆信息：首页、确认订单页；HttpUtil 车辆接口返回
export interface CarInfo {
  id: string;
  name: string;           // 车型名称
  brand: string;          // 品牌
  imageUrl: string;       // 车辆图片
  pricePerDay: number;    // 日租金
  originalPrice?: number; // 原价
  seats: number;          // 座位数
  transmission: string;   // 变速箱
  fuelType: string;       // 燃油类型
  displacement: string;   // 排量
  inventory: number;      // 库存
  features: string[];     // 特色标签
  rating?: number;        // 评分
  orderCount?: number;    // 预订次数
}

// 门店信息：门店查询、确认订单、还车确认页
export interface StoreInfo {
  id: string;
  name: string;
  address: string;
  lng?: number;
  lat?: number;
  city?: string;
  distance: string;
  phone: string;
  hours: string;
  hasPickup: boolean;     // 是否支持接送
}

// 订单状态枚举：订单列表/详情/用车中页按状态展示；枚举值即中文文案
export enum OrderStatus {
  PENDING = '待支付',
  CONFIRMED = '已确认',
  PICKED_UP = '已取车',
  IN_USE = '用车中',
  RETURNED = '已还车',
  COMPLETED = '已完成',
  CANCELLED = '已取消'
}

// 订单信息：我的订单、订单详情、支付、取车凭证、还车确认、费用结算页
export interface OrderInfo {
  id: string;
  orderNo: string;
  carName: string;
  carImage: string;
  pickupStore: string;
  returnStore: string;
  pickupTime: string;
  returnTime: string;
  days: number;
  totalPrice: number;
  status: OrderStatus;
  createTime: string;
  discount?: number;
  insurance?: number;
}

// 优惠券：确认订单页选择优惠券
export interface Coupon {
  id: string;
  name: string;
  discount: number;       // 优惠金额
  threshold: number;      // 使用门槛
  expireDate: string;
  used: boolean;
}

// 用户信息：个人中心页；HttpUtil 登录与用户接口
export interface UserInfo {
  id: string;
  name: string;
  phone: string;
  avatar: string;
  memberLevel: string;
  memberExpire?: string;
  points: number;
  verified: boolean;      // 是否实名认证
}

// 支付方式：收银台页（Payment.ets），MockData 提供静态列表
export interface PaymentMethod {
  id: string;
  name: string;
  type: 'bankcard' | 'wechat' | 'alipay';
  cardNo?: string;
  isDefault: boolean;
}

// 消息气泡（AI客服）：当前仅 MockData.mockChatMessages 使用，AIChat 页用自建 ChatMsg
export interface ChatMessage {
  id: string;
  content: string;
  isUser: boolean;
  time: string;
}

// 违章记录：违章查询页（Violation.ets），数据来自 MockData
export interface ViolationRecord {
  id: string;
  time: string;
  location: string;
  reason: string;
  points: number;
  fine: number;
  status: string;
}

// Banner 轮播图：SwiperBanner 组件；HttpUtil.fetchBanners 返回
export interface BannerInfo {
  id: string;
  imageUrl: string;
  title: string;
  link: string;
  sort: number;
  enabled: boolean;
}

// 详情类页面的信息行：订单详情、用车中、取车凭证、还车确认、支付成功页 List 渲染
export interface InfoRow {
  label: string;
  value: string;
}

// 车辆筛选条件：筛选页（CarFilter.ets）
export interface FilterCondition {
  brand: string;
  priceRange: string;
  carType: string;
  sortBy: string;
}

// 登录表单：登录页（Login.ets）
export interface LoginForm {
  phone: string;
  code: string;
  password: string;
}

// 注册表单：注册页（Register.ets）
export interface RegisterForm {
  phone: string;
  code: string;
  password: string;
  confirmPassword: string;
}

// 实名认证表单：实名认证页（VerifyAuth.ets）
export interface VerifyAuthForm {
  realName: string;
  idCard: string;
}
