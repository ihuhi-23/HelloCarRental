import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { StoreInfo } from '../common/Interfaces';
import { fetchStores } from '../common/HttpUtil';
import webview from '@ohos.web.webview';

/**
 * 页面 12：门店查询
 * 地图模式：用 Web 组件加载高德地图 H5（后端 /api/map/stores 生成）
 * 列表模式：原生 UI 组件
 */
const BASE = 'http://10.232.0.1:3000';

@Entry
@Component
struct StoreQuery {
  @State searchText: string = '';
  @State stores: StoreInfo[] = [];
  @State filteredStores: StoreInfo[] = [];
  @State isMapMode: boolean = true;
  @State searchByCity: string = '';
  @State mapUrl: string = BASE + '/api/map/stores?city=';

  aboutToAppear() {
    this.loadStores();
  }

  private async loadStores() {
    try {
      this.stores = await fetchStores();
      this.filterStores();
    } catch (e) {
      console.error('Load stores failed');
    }
  }

  private filterStores() {
    let result = this.stores;
    if (this.searchByCity) {
      result = result.filter((s: StoreInfo): boolean => (s.city || '').includes(this.searchByCity));
    }
    if (this.searchText) {
      const kw = this.searchText.toLowerCase();
      result = result.filter((s: StoreInfo): boolean =>
        (s.name || '').toLowerCase().includes(kw) || (s.address || '').toLowerCase().includes(kw)
      );
    }
    this.filteredStores = result;
    // 更新地图 URL（让后端过滤城市）
    this.mapUrl = BASE + '/api/map/stores?city=' + encodeURIComponent(this.searchByCity);
  }

  private searchCity(city: string) {
    if (this.searchByCity === city) {
      this.searchByCity = '';
    } else {
      this.searchByCity = city;
    }
    this.filterStores();
  }

  private toggleMode() {
    this.isMapMode = !this.isMapMode;
  }

  build() {
    Column() {
      NavBar({
        title: '门店查询',
        onBack: (): void => { router.back(); },
        rightText: this.isMapMode ? '📋 列表' : '🗺️ 地图',
        onRightClick: (): void => { this.toggleMode(); }
      })

      // 搜索栏
      Row() {
        Text('🔍').fontSize(16).margin({ right: 8 });
        TextInput({ placeholder: '搜索门店名称、地址或城市', text: this.searchText })
          .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
          .onChange((v: string) => { this.searchText = v; this.filterStores(); });
      }
      .width('100%').height(40).padding({ left: 12, right: 12 })
      .backgroundColor(Color.White).borderRadius(20).margin({ left: 16, right: 16, top: 12 });

      // 热门城市快捷按钮
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(['上海', '北京', '广州', '深圳', '南宁'], (city: string) => {
          Text(city)
            .fontSize(12)
            .fontColor(this.searchByCity === city ? Color.White : $r('app.color.primary_orange'))
            .backgroundColor(this.searchByCity === city ? $r('app.color.primary_orange') : Color.White)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .margin({ right: 6, top: 8 })
            .onClick(() => { this.searchCity(city); });
        }, (c: string) => c);
      }
      .width('100%').padding({ left: 16, right: 16 });

      if (this.isMapMode) {
        // ============ 地图模式：Web 加载高德 H5 ============
        Web({ src: this.mapUrl, controller: new webview.WebviewController() })
          .width('100%')
          .layoutWeight(1)
          .margin({ top: 8 })
          .backgroundColor('#F5F5F5');
      } else {
        // ============ 列表模式 ============
        Scroll() {
          Column() {
            ForEach(this.filteredStores, (store: StoreInfo) => {
              this.StoreCard(store);
            }, (store: StoreInfo) => store.id);
            if (this.filteredStores.length === 0) {
              Column() {
                Text('🏪').fontSize(48);
                Text('暂无门店').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ top: 8 });
              }
              .width('100%').padding(40).justifyContent(FlexAlign.Center);
            }
          }
        }
        .layoutWeight(1).scrollBar(BarState.Off);
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'));
  }

  @Builder
  StoreCard(store: StoreInfo) {
    Column() {
      Row() {
        Column() {
          Row() {
            Text('📍 ' + store.name).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'));
            if (store.distance) {
              Text(store.distance).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange')).margin({ left: 8 });
            }
          }
          Text(store.address).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 4 }).maxLines(2);
          Row() {
            Text('🕐 ' + store.hours).fontSize(10).fontColor($r('app.color.text_secondary')).margin({ right: 12 });
            if (store.hasPickup) {
              Text('🚗 可接送').fontSize(10).fontColor($r('app.color.primary_orange')).backgroundColor($r('app.color.primary_orange_light')).padding({ left: 4, right: 4 }).borderRadius(3);
            }
          }.margin({ top: 6 });
          if (store.phone) {
            Text('📞 ' + store.phone).fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 4 });
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
        Button() { Text('导航').fontSize(12).fontColor($r('app.color.text_primary')); }
          .height(32).backgroundColor(Color.White).border({ width: 1, color: $r('app.color.divider') }).borderRadius(16);
      }.width('100%');
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 });
  }
}
