import http from '@ohos.net.http';
import { CarInfo, StoreInfo, OrderInfo, OrderStatus, Coupon, UserInfo, BannerInfo } from './Interfaces';
import { mockCarList, mockStoreList, mockOrderList, mockCouponList, mockUserInfo } from './MockData';

// ===== 本地后端地址（Node.js Express）=====
// 模拟器访问宿主机：10.232.0.1
// 真机访问：改成你电脑的局域网 IP，如 http://192.168.x.x:3000
const BASE_URL = 'http://10.232.0.1:3000';

// ===== 图片 URL 工具 =====

// 把后端图片路径转成可在 ArkUI Image() 中使用的完整 URL
// 后端可能返回：/uploads/xxx.png | https://xxx.com/xxx.jpg
// 只接受这两种，不再支持 emoji
export function resolveImageUrl(url: string): string {
  if (!url) return '';
  if (url.startsWith('/uploads/')) {
    return BASE_URL + url;
  }
  return url;
}

// 从车辆缓存中，根据订单的 carName 找对应的图片 URL
export function getCarImageByName(carName: string): string {
  let list = memoryCars || mockCarList;
  let car = list.find((c: CarInfo) => c.name === carName);
  if (car && car.imageUrl) return resolveImageUrl(car.imageUrl);
  return '';
}

interface HeaderObj { 'Content-Type': string; }
interface RequestOpt {
  method: http.RequestMethod;
  connectTimeout: number;
  readTimeout: number;
  header: HeaderObj;
  extraData?: string;
}

// ===== HTTP 底层方法 =====

async function httpGet(path: string): Promise<string> {
  let url = BASE_URL + path;
  let httpRequest = http.createHttp();
  try {
    let opt: RequestOpt = {
      method: http.RequestMethod.GET,
      connectTimeout: 5000,
      readTimeout: 5000,
      header: { 'Content-Type': 'application/json' }
    };
    let response = await httpRequest.request(url, opt);
    return response.result as string;
  } catch (e) {
    return '';
  } finally {
    httpRequest.destroy();
  }
}

async function httpPost(path: string, body: string): Promise<string> {
  let url = BASE_URL + path;
  let httpRequest = http.createHttp();
  try {
    let opt: RequestOpt = {
      method: http.RequestMethod.POST,
      connectTimeout: 5000,
      readTimeout: 5000,
      header: { 'Content-Type': 'application/json' },
      extraData: body
    };
    let response = await httpRequest.request(url, opt);
    return response.result as string;
  } catch (e) {
    return '';
  } finally {
    httpRequest.destroy();
  }
}

// ===== 数据转换工具 =====

// 后端订单状态（英文） → 前端 OrderStatus 枚举（中文）
function mapOrderStatus(status: string): OrderStatus {
  let s = status.toUpperCase();
  if (s === 'PENDING') return OrderStatus.PENDING;
  if (s === 'CONFIRMED') return OrderStatus.CONFIRMED;
  if (s === 'IN_USE') return OrderStatus.IN_USE;
  if (s === 'COMPLETED') return OrderStatus.COMPLETED;
  if (s === 'CANCELLED') return OrderStatus.CANCELLED;
  return OrderStatus.PENDING;
}

function parseResponse<T>(text: string): T | null {
  try {
    if (!text) return null;
    let parsed = JSON.parse(text) as Record<string, Object>;
    if ((parsed['code'] as number) === 1) {
      return parsed['data'] as T;
    }
    return null;
  } catch (e) {
    return null;
  }
}

// ===== 内存缓存 =====
let memoryCars: CarInfo[] | null = null;
let memoryStores: StoreInfo[] | null = null;
let memoryOrders: OrderInfo[] | null = null;
let memoryCoupons: Coupon[] | null = null;
let memoryUser: UserInfo | null = null;
let memoryBanners: BannerInfo[] | null = null;

// ============ 对外 API ============

// ===== 车辆 =====

export async function fetchHomeCars(): Promise<CarInfo[]> {
  if (memoryCars && memoryCars.length > 0) return memoryCars;
  let text = await httpGet('/api/cars');
  let data = parseResponse<CarInfo[]>(text);
  if (data && data.length > 0) {
    // 统一转成完整图片 URL
    data.forEach((c: CarInfo) => {
      c.imageUrl = resolveImageUrl(c.imageUrl);
    });
    memoryCars = data;
    return data;
  }
  return mockCarList;
}

export async function refreshHomeCars(): Promise<CarInfo[]> {
  memoryCars = null;
  return fetchHomeCars();
}

export async function fetchCarDetail(id: string): Promise<CarInfo | null> {
  let text = await httpGet('/api/cars/' + id);
  let data = parseResponse<CarInfo>(text);
  if (data) {
    data.imageUrl = resolveImageUrl(data.imageUrl);
    return data;
  }
  let list = memoryCars || mockCarList;
  return list.find((c: CarInfo) => c.id === id) || null;
}

// ===== 门店 =====

export async function fetchStores(): Promise<StoreInfo[]> {
  if (memoryStores && memoryStores.length > 0) return memoryStores;
  let text = await httpGet('/api/stores');
  let data = parseResponse<StoreInfo[]>(text);
  if (data && data.length > 0) {
    memoryStores = data;
    return data;
  }
  return mockStoreList;
}

// ===== 订单 =====

export async function fetchOrders(status?: string): Promise<OrderInfo[]> {
  // 确保车辆缓存里有数据（用于匹配图片）
  if (!memoryCars || memoryCars.length === 0) {
    await fetchHomeCars();
  }
  let text = status ? await httpGet('/api/orders?status=' + status) : await httpGet('/api/orders');
  let rawList = parseResponse<OrderInfo[]>(text);
  if (rawList && rawList.length > 0) {
    let list = rawList.map((o: OrderInfo): OrderInfo => {
      // 关键：从车辆缓存找对应的图片 URL，替换订单里的 emoji
      let realImage = getCarImageByName(o.carName);
      let mapped: OrderInfo = {
        id: o.id,
        orderNo: o.orderNo,
        carName: o.carName,
        carImage: realImage || o.carImage, // 优先用车辆真实图片
        pickupStore: o.pickupStore,
        returnStore: o.returnStore,
        pickupTime: o.pickupTime,
        returnTime: o.returnTime,
        days: o.days,
        totalPrice: o.totalPrice,
        status: mapOrderStatus(o.status as string),
        createTime: o.createTime,
        discount: o.discount,
        insurance: o.insurance
      };
      return mapped;
    });
    memoryOrders = list;
    return list;
  }
  return mockOrderList;
}

export async function fetchOrderDetail(id: string): Promise<OrderInfo | null> {
  if (!memoryCars || memoryCars.length === 0) {
    await fetchHomeCars();
  }
  let text = await httpGet('/api/orders/' + id);
  let data = parseResponse<OrderInfo>(text);
  if (data) {
    data.status = mapOrderStatus(data.status as string);
    let realImage = getCarImageByName(data.carName);
    if (realImage) data.carImage = realImage;
    return data;
  }
  let list = memoryOrders || mockOrderList;
  return list.find((o: OrderInfo) => o.id === id) || null;
}

export async function createOrder(carId: string, days: number, pickupStore: string): Promise<OrderInfo | null> {
  let body = JSON.stringify({ carId: carId, days: days, pickupStore: pickupStore });
  let text = await httpPost('/api/orders', body);
  let data = parseResponse<OrderInfo>(text);
  if (data) {
    data.status = mapOrderStatus(data.status as string);
    memoryOrders = null;
    return data;
  }
  return null;
}

// ===== 优惠券 =====

export async function fetchCoupons(): Promise<Coupon[]> {
  if (memoryCoupons && memoryCoupons.length > 0) return memoryCoupons;
  let text = await httpGet('/api/coupons');
  let data = parseResponse<Coupon[]>(text);
  if (data && data.length > 0) {
    memoryCoupons = data;
    return data;
  }
  return mockCouponList;
}

// ===== 用户 =====

export async function fetchUser(): Promise<UserInfo> {
  if (memoryUser) return memoryUser;
  let text = await httpGet('/api/user');
  let data = parseResponse<UserInfo>(text);
  if (data) {
    memoryUser = data;
    return data;
  }
  return mockUserInfo;
}

// ===== 登录 =====

export async function login(phone: string, code: string): Promise<boolean> {
  let body = JSON.stringify({ phone: phone, code: code });
  let text = await httpPost('/api/login', body);
  let parsed = parseResponse<Record<string, Object>>(text);
  if (parsed) {
    memoryUser = null;
    return true;
  }
  return false;
}

// ===== Banner =====

export async function fetchBanners(): Promise<BannerInfo[]> {
  if (memoryBanners && memoryBanners.length > 0) return memoryBanners;
  try {
    let text = await httpGet('/api/banners');
    let data = parseResponse<BannerInfo[]>(text);
    if (data && data.length > 0) {
      data.forEach((b: BannerInfo) => {
        b.imageUrl = resolveImageUrl(b.imageUrl);
      });
      memoryBanners = data;
      return data;
    }
  } catch (e) {
    console.error('fetchBanners error', e);
  }
  // 后端没配或网络不通时的 fallback（空数组让组件隐藏）
  return [];
}
