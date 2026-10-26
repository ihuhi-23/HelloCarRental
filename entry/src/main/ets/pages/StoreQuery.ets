import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { StoreInfo } from '../common/Interfaces';
import { fetchStores } from '../common/HttpUtil';
import webview from '@ohos.web.webview';

/**
 * 页面：门店查询
 * 分工：成员二 · 简单页面
 * 入口：个人中心「门店查询」
 * 功能：门店搜索、热门城市筛选、地图/列表模式切换
 * 容器：List（门店列表）、Stack（地图与列表切换）、Web（高德地图 H5）
 * 关键状态：stores、filteredStores、isMapMode、searchText、searchByCity、mapUrl
 * 关键方法：loadStores() 调用 HttpUtil.fetchStores()、filterStores()、searchCity()、toggleMode()
 */
// 地图页地址：IP 直连，避免部分网络（校园网）DNS 拦截域名导致地图空白
const BASE = 'http://47.107.80.195:8081';
// 备用：HTTPS 域名 const BASE = 'https://car.ihuhi.xyz';

@Entry
@Component
struct StoreQuery {
  @State searchText: string = '';
  @State stores: StoreInfo[] = [];
  @State filteredStores: StoreInfo[] = [];
  @State isMapMode: boolean = true;
  @State searchByCity: string = '';
  @State mapUrl: string = BASE + '/api/map/stores?city=';
  // Web 控制器只创建一次，不能放在 build() 里，否则每次重渲染都会新建实例导致 Web 内核重建
  private controller: webview.WebviewController = new webview.WebviewController();

  // 作用：页面加载时获取门店列表
  aboutToAppear() {
    this.loadStores();
  }

  // 作用：返回前停止 Web 加载，避免销毁时卡住主线程
  // 页面返回前先停止 Web 加载，缩短 Web 内核销毁耗时，避免主线程被卡住
  onBackPress(): boolean {
    this.stopWeb();
    return false;
  }

  // 作用：调用 Web 控制器停止加载
  private stopWeb() {
    try {
      this.controller.stop();
    } catch (e) {
      // Web 还未初始化完成时 controller 会抛异常，忽略即可
      console.error('webview stop failed: ' + JSON.stringify(e));
    }
  }

  // 作用：调用 HttpUtil.fetchStores() 获取门店并刷新筛选结果
  private async loadStores() {
    try {
      this.stores = await fetchStores();
      this.filterStores();
    } catch (e) {
      console.error('Load stores failed');
    }
  }

  // 作用：按城市和搜索关键词过滤门店
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
  }

  // 作用：切换城市筛选，并更新地图 URL
  private searchCity(city: string) {
    if (this.searchByCity === city) {
      this.searchByCity = '';
    } else {
      this.searchByCity = city;
    }
    this.filterStores();
    // 只有切换城市时才更新地图 URL，避免搜索输入每敲一个字都触发 Web 重新加载
    this.mapUrl = BASE + '/api/map/stores?city=' + encodeURIComponent(this.searchByCity);
  }

  // 作用：在地图模式和列表模式之间切换
  private toggleMode() {
    this.isMapMode = !this.isMapMode;
  }

  build() {
    Column() {
      NavBar({
        title: '门店查询',
        onBack: (): void => { this.stopWeb(); router.back(); },
        rightText: this.isMapMode ? '📋 列表' : '🗺️ 地图',
        onRightClick: (): void => { this.toggleMode(); }
      })

      // ===== 搜索栏 =====
      // 搜索栏
      Row() {
        Text('🔍').fontSize(16).margin({ right: 8 });
        TextInput({ placeholder: '搜索门店名称、地址或城市', text: this.searchText })
          .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
          .onChange((v: string) => { this.searchText = v; this.filterStores(); });
      }
      .width('100%').height(40).padding({ left: 12, right: 12 })
      .backgroundColor(Color.White).borderRadius(20).margin({ left: 16, right: 16, top: 12 });

      // ===== 热门城市快捷按钮 =====
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

      // ===== 地图/列表面板：Stack 切换 =====
      // 地图/列表共用一个 Stack，Web 实例常驻，只切换可见性；
      // 避免用 if 分支销毁并重建 Web 内核（销毁 Web 时会同步等待内核退出，主线程可能被卡死）
      Stack() {
        if (!this.isMapMode) {
          // ============ 列表模式 ============
          // 门店列表：List + ForEach 渲染 StoreCard
          List() {
            ForEach(this.filteredStores, (store: StoreInfo) => {
              ListItem() {
                this.StoreCard(store);
              }
            }, (store: StoreInfo): string => store.id);
            if (this.filteredStores.length === 0) {
              ListItem() {
                Column() {
                  Text('🏪').fontSize(48);
                  Text('暂无门店').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ top: 8 });
                }
                .width('100%').padding(40).justifyContent(FlexAlign.Center);
              }
              .width('100%')
            }
          }
          .width('100%').height('100%').scrollBar(BarState.Off);
        }

        // ============ 地图模式：Web 加载高德 H5 ============
        // 地图：Web 组件加载后端生成的高德地图页面
        Web({ src: this.mapUrl, controller: this.controller })
          .width('100%')
          .height('100%')
          .margin({ top: 8 })
          .backgroundColor('#F5F5F5')
          .visibility(this.isMapMode ? Visibility.Visible : Visibility.None);
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'));
  }

  // 作用：门店卡片（名称、地址、营业时间、电话、导航按钮）
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
        Text('导航').fontSize(12).fontColor($r('app.color.text_primary'))
          .height(32).padding({ left: 16, right: 16 })
          .backgroundColor(Color.White).border({ width: 1, color: $r('app.color.divider') }).borderRadius(16);
      }.width('100%');
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 });
  }
}
