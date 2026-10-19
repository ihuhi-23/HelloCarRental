import http from '@ohos.net.http';
import { CarInfo } from './Interfaces';

const API_KEY = 'ff81cdc727875d2e52deae99f575a1e0';
const BASE_URL = 'https://api.tanshuapi.com/api/car/v1';
const HOT_BRANDS: string[] = ['奥迪', '宝马', '奔驰', '特斯拉', '丰田', '本田', '大众', '比亚迪', '日产', '别克'];

interface BrandSub {
  brand_id: number;
  brand_name: string;
}
interface BrandItem {
  main_brand_id: number;
  main_brand_name: string;
  brand_list: BrandSub[];
}
interface SeriesItem {
  series_id: number;
  series_name: string;
  img: string;
  sale_state: string;
  scale: string;
}

interface HeaderObj {
  'Content-Type': string;
}
interface RequestOpt {
  method: http.RequestMethod;
  connectTimeout: number;
  readTimeout: number;
  header: HeaderObj;
}

let brandCache: BrandItem[] | null = null;
let seriesCache: Map<string, SeriesItem[]> = new Map();

async function requestBrands(): Promise<BrandItem[]> {
  let url = BASE_URL + '/carBrand?key=' + API_KEY;
  let httpRequest = http.createHttp();
  try {
    let opt: RequestOpt = {
      method: http.RequestMethod.GET,
      connectTimeout: 10000,
      readTimeout: 10000,
      header: { 'Content-Type': 'application/json' }
    };
    let response = await httpRequest.request(url, opt);
    let text = response.result as string;
    let parsed = JSON.parse(text) as Record<string, Object>;
    let code = parsed['code'] as number;
    let data = parsed['data'] as BrandItem[];
    if (code === 1 && data) {
      return data;
    }
    return [];
  } catch (e) {
    return [];
  } finally {
    httpRequest.destroy();
  }
}

async function requestSeries(brandId: number): Promise<SeriesItem[]> {
  let url = BASE_URL + '/carSeries?key=' + API_KEY + '&brand_id=' + brandId;
  let httpRequest = http.createHttp();
  try {
    let opt: RequestOpt = {
      method: http.RequestMethod.GET,
      connectTimeout: 10000,
      readTimeout: 10000,
      header: { 'Content-Type': 'application/json' }
    };
    let response = await httpRequest.request(url, opt);
    let text = response.result as string;
    let parsed = JSON.parse(text) as Record<string, Object>;
    let code = parsed['code'] as number;
    let data = parsed['data'] as SeriesItem[];
    if (code === 1 && data) {
      return data;
    }
    return [];
  } catch (e) {
    return [];
  } finally {
    httpRequest.destroy();
  }
}

async function loadBrands(): Promise<BrandItem[]> {
  if (brandCache) return brandCache;
  brandCache = await requestBrands();
  return brandCache;
}

async function loadSeries(brandId: number): Promise<SeriesItem[]> {
  let key = String(brandId);
  if (seriesCache.has(key)) return seriesCache.get(key) as SeriesItem[];
  let arr = await requestSeries(brandId);
  seriesCache.set(key, arr);
  return arr;
}

function pickFeatures(scale: string, name: string): string[] {
  let features: string[] = [];
  if (scale.indexOf('SUV') >= 0) features.push('SUV');
  if (scale.indexOf('MPV') >= 0) features.push('MPV');
  if (name.indexOf('新能源') >= 0 || name.indexOf('e-tron') >= 0 || name.indexOf('Model') >= 0) features.push('纯电');
  if (name.indexOf('混动') >= 0) features.push('混动');
  features.push('自动挡', '蓝牙');
  if (name.indexOf('四驱') >= 0) features.push('四驱');
  if (features.length === 0) features = ['自动挡', '蓝牙', '倒车雷达'];
  return features.slice(0, 4);
}

export async function fetchHomeCars(): Promise<CarInfo[]> {
  let cars: CarInfo[] = [];
  let brands = await loadBrands();
  if (brands.length === 0) return cars;

  let hotBrands: BrandItem[] = [];
  for (let i = 0; i < brands.length; i++) {
    if (HOT_BRANDS.indexOf(brands[i].main_brand_name) >= 0) {
      hotBrands.push(brands[i]);
    }
  }

  for (let bi = 0; bi < hotBrands.length; bi++) {
    let brand = hotBrands[bi];
    let sub: BrandSub | null = null;
    if (brand.brand_list && brand.brand_list.length > 0) {
      sub = brand.brand_list[0];
    }
    if (!sub) continue;

    let seriesList = await loadSeries(sub.brand_id);
    if (seriesList.length === 0) continue;

    let count = 0;
    for (let si = 0; si < seriesList.length; si++) {
      let series = seriesList[si];
      if (series.sale_state && series.sale_state.indexOf('停售') >= 0) continue;
      if (!series.img || series.img.length < 10) continue;

      let pricePerDay = 199 + Math.floor(Math.random() * 600);
      let inventory = 1 + Math.floor(Math.random() * 5);
      let scale = series.scale || '';
      let seats = 5;
      if (scale.indexOf('7') >= 0 || scale.indexOf('MPV') >= 0) seats = 7;
      let fuelType = '汽油';
      if (series.series_name && (series.series_name.indexOf('新能源') >= 0 || series.series_name.indexOf('e-tron') >= 0 || series.series_name.indexOf('Model') >= 0)) {
        fuelType = '纯电';
      }

      let car: CarInfo = {
        id: String(series.series_id),
        name: series.series_name,
        brand: brand.main_brand_name,
        imageUrl: series.img,
        pricePerDay: pricePerDay,
        seats: seats,
        transmission: '自动',
        fuelType: fuelType,
        displacement: '2.0T',
        inventory: inventory,
        features: pickFeatures(scale, series.series_name),
        rating: 4.5 + Math.random() * 0.5,
        orderCount: 500 + Math.floor(Math.random() * 2000)
      };
      cars.push(car);
      count++;
      if (count >= 3) break;
    }
    if (cars.length >= 24) break;
  }
  return cars;
}
