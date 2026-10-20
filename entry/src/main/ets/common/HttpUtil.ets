import http from '@ohos.net.http';
import { CarInfo } from './Interfaces';
import { mockCarList } from './MockData';

// ===== 本地后端地址（Node.js Express）=====
// 鸿蒙模拟器和真机通用：直接用宿主机真实 IP
const BASE_URL = 'http://10.232.0.1:3000';

interface HeaderObj { 'Content-Type': string; }
interface RequestOpt {
  method: http.RequestMethod;
  connectTimeout: number;
  readTimeout: number;
  header: HeaderObj;
  extraData?: string;
}

let memoryCars: CarInfo[] | null = null;

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

// ============ 对外 API ============

// 获取车辆列表
export async function fetchHomeCars(): Promise<CarInfo[]> {
  if (memoryCars && memoryCars.length > 0) return memoryCars;
  try {
    let text = await httpGet('/api/cars');
    if (!text) return mockCarList;
    let parsed = JSON.parse(text) as Record<string, Object>;
    let code = parsed['code'] as number;
    let data = parsed['data'] as CarInfo[];
    if (code === 1 && data && data.length > 0) {
      memoryCars = data;
      return data;
    }
    return mockCarList;
  } catch (e) {
    return mockCarList;
  }
}

// 强制刷新（重新请求后端）
export async function refreshHomeCars(): Promise<CarInfo[]> {
  memoryCars = null;
  return fetchHomeCars();
}

// 登录（调用后端 /api/login）
export async function login(phone: string, code: string): Promise<boolean> {
  try {
    let text = await httpPost('/api/login', JSON.stringify({ phone: phone, code: code }));
    if (!text) return false;
    let parsed = JSON.parse(text) as Record<string, Object>;
    return (parsed['code'] as number) === 1;
  } catch (e) {
    return false;
  }
}
