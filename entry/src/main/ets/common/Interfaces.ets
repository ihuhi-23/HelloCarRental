/**
 * 数据模型接口定义
 */

// 车辆信息
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

// 门店信息
export interface StoreInfo {
  id: string;
  name: string;
  address: string;
  distance: string;
  phone: string;
  hours: string;
  hasPickup: boolean;     // 是否支持接送
}

// 订单状态枚举
export enum OrderStatus {
  PENDING = '待支付',
  CONFIRMED = '已确认',
  PICKED_UP = '已取车',
  IN_USE = '用车中',
  RETURNED = '已还车',
  COMPLETED = '已完成',
  CANCELLED = '已取消'
}

// 订单信息
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

// 优惠券
export interface Coupon {
  id: string;
  name: string;
  discount: number;       // 优惠金额
  threshold: number;      // 使用门槛
  expireDate: string;
  used: boolean;
}

// 用户信息
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

// 支付方式
export interface PaymentMethod {
  id: string;
  name: string;
  type: 'bankcard' | 'wechat' | 'alipay';
  cardNo?: string;
  isDefault: boolean;
}

// 消息气泡（AI客服）
export interface ChatMessage {
  id: string;
  content: string;
  isUser: boolean;
  time: string;
}

// 违章记录
export interface ViolationRecord {
  id: string;
  time: string;
  location: string;
  reason: string;
  points: number;
  fine: number;
  status: string;
}
