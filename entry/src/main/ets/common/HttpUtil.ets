/**
 * 网络请求统一封装
 * 包含 BASE_URL、token 管理与自动携带、接口失败回退 MockData 的兜底策略
 * 所有页面都通过本文件的函数访问后端，不直接使用 @ohos.net.http
 */
import http from '@ohos.net.http';
import { CarInfo, StoreInfo, OrderInfo, OrderStatus, Coupon, UserInfo, BannerInfo } from './Interfaces';
import { mockCarList, mockStoreList, mockOrderList, mockCouponList, mockUserInfo } from './MockData';

// ===== 线上后端地址（Node.js Express，部署在阿里云 ECS）=====
// 本地开发时改回：http://10.232.0.1:3000
export const BASE_URL = 'https://car.ihuhi.xyz';

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

interface HeaderObj { 'Content-Type': string; Authorization?: string; }
interface RequestOpt {
  method: http.RequestMethod;
  connectTimeout: number;
  readTimeout: number;
  header: HeaderObj;
  extraData?: string;
}

// ===== 登录态 =====
// 登录成功后保存服务端返回的 token，后续请求自动带 Authorization 头
let sessionToken: string = '';
// 演示账号：未手动登录时，首次请求用户信息会自动用它完成一次真实登录，
// 避免每次启动都要手动登录（数据仍来自后端 users）
const DEMO_PHONE = '13800138000';
const DEMO_CODE = '1234';

export interface AuthResult {
  success: boolean;
  message: string;
}

function buildHeader(): HeaderObj {
  let header: HeaderObj = { 'Content-Type': 'application/json' };
  if (sessionToken) {
    header.Authorization = 'Bearer ' + sessionToken;
  }
  return header;
}

// 从后端返回的 { code, message } 里取错误提示
function parseMessage(text: string, fallback: string): string {
  try {
    if (!text) return fallback;
    let parsed = JSON.parse(text) as Record<string, Object>;
    let msg = parsed['message'];
    if (typeof msg === 'string' && msg.length > 0) return msg as string;
  } catch (e) {
    // 解析失败按网络异常处理
  }
  return fallback;
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
      header: buildHeader()
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
      connectTimeout: 15000,
      readTimeout: 15000,
      header: buildHeader(),
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
  if (s === 'PICKED_UP') return OrderStatus.PICKED_UP;
  if (s === 'IN_USE') return OrderStatus.IN_USE;
  if (s === 'RETURNED') return OrderStatus.RETURNED;
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
// memoryOrders：订单全量列表缓存，列表页与详情页复用，减少重复请求；
// 下单、改状态、退出登录后置空，下次读取会重新拉取
let memoryOrders: OrderInfo[] | null = null;
let memoryCoupons: Coupon[] | null = null;
let memoryUser: UserInfo | null = null;
let memoryBanners: BannerInfo[] | null = null;

// ============ 对外 API ============

// ===== 车辆 =====

// 接口：GET /api/cars
// 用途：首页获取车辆列表，成功后写入 memoryCars；请求失败才回退 MockData.mockCarList
// 使用位置：Index.ets
export async function fetchHomeCars(): Promise<CarInfo[]> {
  if (memoryCars && memoryCars.length > 0) return memoryCars;
  let text = await httpGet('/api/cars');
  let data = parseResponse<CarInfo[]>(text);
  // 接口成功就信后端：空数组也是有效结果，只有请求失败（null）才回退 Mock
  if (data) {
    data.forEach((c: CarInfo) => {
      c.imageUrl = resolveImageUrl(c.imageUrl);
    });
    memoryCars = data;
    return data;
  }
  return mockCarList;
}

// 接口：GET /api/cars（先清空缓存再请求）
// 用途：强制刷新车辆列表，供重试/下拉刷新场景使用
// 使用位置：当前无页面调用（预留）
export async function refreshHomeCars(): Promise<CarInfo[]> {
  memoryCars = null;
  return fetchHomeCars();
}

// 接口：GET /api/cars/{id}
// 用途：确认订单页读取所选车辆详情；请求失败时从 memoryCars/Mock 中按 id 查找
// 使用位置：OrderConfirm.ets
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

// 接口：GET /api/stores
// 用途：获取门店列表；请求失败时回退 MockData.mockStoreList
// 使用位置：StoreQuery.ets、OrderConfirm.ets、ReturnConfirm.ets
export async function fetchStores(): Promise<StoreInfo[]> {
  if (memoryStores && memoryStores.length > 0) return memoryStores;
  let text = await httpGet('/api/stores');
  let data = parseResponse<StoreInfo[]>(text);
  if (data) {
    memoryStores = data;
    return data;
  }
  return mockStoreList;
}

// ===== 订单 =====

// 接口：GET /api/orders（可选 ?status= 过滤）
// 用途：读取订单列表并补全车辆真实图片；请求失败时回退 MockData.mockOrderList
// 使用位置：MyOrders.ets、InUse.ets、FeeSettlement.ets、PickupVoucher.ets、ReturnConfirm.ets
export async function fetchOrders(status?: string): Promise<OrderInfo[]> {
  // 确保车辆缓存里有数据（用于匹配图片）
  if (!memoryCars || memoryCars.length === 0) {
    await fetchHomeCars();
  }
  let text = status ? await httpGet('/api/orders?status=' + status) : await httpGet('/api/orders');
  let rawList = parseResponse<OrderInfo[]>(text);
  if (rawList) {
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
    // 只缓存未过滤的全量列表，避免带 status 的请求污染订单缓存
    if (!status) memoryOrders = list;
    return list;
  }
  return mockOrderList;
}

// 接口：GET /api/orders/{id}
// 用途：读取单个订单详情；请求失败时从 memoryOrders/Mock 中按 id 查找
// 使用位置：OrderDetail.ets、InUse.ets、PaymentSuccess.ets、PickupVoucher.ets、ReturnConfirm.ets、FeeSettlement.ets
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

// 下单参数
export interface CreateOrderParams {
  carId: string;
  days: number;
  pickupStore: string;
  returnStore?: string;
  pickupTime?: string;
  returnTime?: string;
  discount?: number;
  insurance?: number;
}

// 接口：POST /api/orders
// 用途：提交下单，成功后清空 memoryOrders 避免读到旧列表
// 使用位置：OrderConfirm.ets
export async function createOrder(params: CreateOrderParams): Promise<OrderInfo | null> {
  let body = JSON.stringify(params);
  let text = await httpPost('/api/orders', body);
  let data = parseResponse<OrderInfo>(text);
  if (data) {
    data.status = mapOrderStatus(data.status as string);
    memoryOrders = null;
    return data;
  }
  return null;
}

// 接口：POST /api/orders/{id}/status
// 用途：支付成功(CONFIRMED)、确认还车(RETURNED)、费用结清(COMPLETED)时更新状态
// 使用位置：Payment.ets、ReturnConfirm.ets、FeeSettlement.ets
// 更新订单状态：支付成功、确认还车、费用结清等环节调用
export async function updateOrderStatus(id: string, status: string): Promise<boolean> {
  let body = JSON.stringify({ status: status });
  let text = await httpPost('/api/orders/' + id + '/status', body);
  let data = parseResponse<OrderInfo>(text);
  if (data) {
    memoryOrders = null;
    return true;
  }
  return false;
}

// ===== 优惠券 =====

// 接口：GET /api/coupons
// 用途：确认订单页可选优惠券；请求失败时回退 MockData.mockCouponList
// 使用位置：OrderConfirm.ets
export async function fetchCoupons(): Promise<Coupon[]> {
  if (memoryCoupons && memoryCoupons.length > 0) return memoryCoupons;
  let text = await httpGet('/api/coupons');
  let data = parseResponse<Coupon[]>(text);
  if (data) {
    memoryCoupons = data;
    return data;
  }
  return mockCouponList;
}

// ===== 用户 / 登录态 =====

// 登录/注册接口统一返回 { token, user }，这里解析并保存 token
function parseAuth(text: string): UserInfo | null {
  try {
    if (!text) return null;
    let parsed = JSON.parse(text) as Record<string, Object>;
    if ((parsed['code'] as number) !== 1) return null;
    let data = parsed['data'] as Record<string, Object>;
    let token = data['token'] as string;
    let user = data['user'] as UserInfo;
    if (!token || !user) return null;
    sessionToken = token;
    if (user.avatar) user.avatar = resolveImageUrl(user.avatar);
    memoryUser = user;
    return user;
  } catch (e) {
    return null;
  }
}

async function authRequest(path: string, body: string, fallback: string): Promise<AuthResult> {
  let text = await httpPost(path, body);
  if (!text) return { success: false, message: '网络异常，请检查后端服务是否已启动' };
  let user = parseAuth(text);
  if (user) return { success: true, message: '' };
  return { success: false, message: parseMessage(text, fallback) };
}

// 接口：POST /api/register
// 用途：注册账号，成功后自动保存 token 并进入登录态
// 使用位置：Register.ets
// 注册：成功后自动登录
export async function register(phone: string, code: string, password: string, name: string): Promise<AuthResult> {
  let body = JSON.stringify({ phone: phone, code: code, password: password, name: name });
  return authRequest('/api/register', body, '注册失败，请稍后重试');
}

// 接口：POST /api/login（验证码）
// 用途：验证码登录，未注册手机号由后端自动建号；也被 ensureSession 内部调用
// 使用位置：Login.ets
// 验证码登录（未注册的手机号后端会自动创建账号）
export async function loginWithCode(phone: string, code: string): Promise<AuthResult> {
  let body = JSON.stringify({ phone: phone, code: code });
  return authRequest('/api/login', body, '登录失败，请稍后重试');
}

// 接口：POST /api/login（密码）
// 用途：密码登录
// 使用位置：Login.ets
// 密码登录
export async function loginWithPassword(phone: string, password: string): Promise<AuthResult> {
  let body = JSON.stringify({ phone: phone, password: password });
  return authRequest('/api/login', body, '登录失败，请稍后重试');
}

// 未登录时用演示账号静默登录，保证首页/个人中心可直接进入
async function ensureSession(): Promise<void> {
  if (sessionToken) return;
  await loginWithCode(DEMO_PHONE, DEMO_CODE);
}

// 接口：GET /api/user
// 用途：读取当前用户信息；未登录先静默登录，请求失败时回退 MockData.mockUserInfo
// 使用位置：PersonalCenter.ets
export async function fetchUser(): Promise<UserInfo> {
  if (memoryUser) return memoryUser;
  await ensureSession();
  let text = await httpGet('/api/user');
  let data = parseResponse<UserInfo>(text);
  if (data) {
    if (data.avatar) data.avatar = resolveImageUrl(data.avatar);
    memoryUser = data;
    return data;
  }
  return mockUserInfo;
}

// 接口：POST /api/user/avatar
// 用途：头像以 base64 提交，成功后更新 memoryUser
// 使用位置：PersonalCenter.ets
// 上传头像（图片以 base64 提交，服务端落盘到 /uploads）
export async function uploadAvatar(base64: string, ext: string): Promise<AuthResult> {
  await ensureSession();
  let body = JSON.stringify({ base64: base64, ext: ext });
  let text = await httpPost('/api/user/avatar', body);
  if (!text) return { success: false, message: '网络异常，头像上传失败' };
  let data = parseResponse<UserInfo>(text);
  if (data) {
    if (data.avatar) data.avatar = resolveImageUrl(data.avatar);
    memoryUser = data;
    return { success: true, message: '头像已更新' };
  }
  return { success: false, message: parseMessage(text, '头像上传失败') };
}

// 接口：POST /api/logout
// 用途：退出登录，清空 token 与用户/订单缓存
// 使用位置：PersonalCenter.ets
// 退出登录：通知后端销毁 token，并清空本地缓存
export async function logout(): Promise<void> {
  await httpPost('/api/logout', '{}');
  sessionToken = '';
  memoryUser = null;
  memoryOrders = null;
}

// ===== Banner =====

// 接口：GET /api/banners
// 用途：轮播图数据；后端无数据或请求失败时返回空数组，由组件自行隐藏
// 使用位置：SwiperBanner.ets（组件被 Index/CarFilter/OrderConfirm/FeeSettlement/VerifyAuth/Violation 引用）
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
