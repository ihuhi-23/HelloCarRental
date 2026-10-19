import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';
import { mockCarList } from '../common/MockData';
import { CarInfo } from '../common/Interfaces';
import { fetchHomeCars } from '../common/HttpUtil';

/**
 * 页面 1：车辆列表 - 首页
 * 【复杂页面】包含搜索、筛选、车辆卡片列表、门店选择
 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State searchText: string = '';
  @State storeName: string = '浦东机场 T2 · 1.2km';
  @State carList: CarInfo[] = mockCarList;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadRealCars();
  }

  private async loadRealCars() {
    try {
      let realCars = await fetchHomeCars();
      if (realCars && realCars.length > 0) {
        this.carList = realCars;
      }
    } catch (e) {
      console.error('Load cars failed');
    } finally {
      this.isLoading = false;
    }
  }

  private goFilter() {
    router.pushUrl({ url: 'pages/CarFilter' });
  }

  private goConfirm(carId: string) {
    router.pushUrl({ url: 'pages/OrderConfirm?carId=' + carId });
  }

  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 0) {
      router.replaceUrl({ url: pages[index] });
    }
  }

  build() {
    Column() {
      NavBar({
        title: '选择车辆',
        showBack: false,
        rightText: '筛选',
        onBack: (): void => {},
        onRightClick: (): void => this.goFilter()
      })

      Column() {
        Row() {
          Column() {
            Text(this.storeName)
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Medium)
            Text('2026-10-20 ~ 2026-10-23 · 3天')
              .fontSize($r('app.float.font_size_small'))
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('›')
            .fontSize(18)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 2, color: '#0D000000', offsetY: 1 })

        Row() {
          Text('🔍').fontSize(16).margin({ right: 8 })
          TextInput({ placeholder: '搜索品牌或车型', text: this.searchText })
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .fontSize($r('app.float.font_size_body'))
            .onChange((value: string) => { this.searchText = value; })
        }
        .width('100%')
        .height(40)
        .padding({ left: 12, right: 12 })
        .backgroundColor($r('app.color.bg_page'))
        .borderRadius(20)
        .margin({ top: 12 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      Row() {
        Text('🔥 热门车型')
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(this.isLoading ? '加载中...' : ('共找到 ' + this.carList.length + ' 辆'))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column() {
          ForEach(this.carList, (car: CarInfo) => {
            this.CarCard(car)
          }, (car: CarInfo) => car.id)
        }
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  CarCard(car: CarInfo) {
    Column() {
      Row() {
        Image(car.imageUrl)
          .width(130)
          .height(100)
          .objectFit(ImageFit.Cover)
          .borderRadius(10)
          .backgroundColor($r('app.color.bg_page'))

        Column() {
          Row() {
            Text(car.name)
              .fontSize($r('app.float.font_size_subtitle'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Blank()
            if (car.inventory <= 2) {
              Text('仅剩 ' + car.inventory + ' 辆')
                .fontSize(10)
                .fontColor($r('app.color.primary_orange'))
                .backgroundColor($r('app.color.primary_orange_light'))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(4)
            }
          }
          .width('100%')

          Row() {
            ForEach(car.features.slice(0, 3), (tag: string) => {
              Text(tag)
                .fontSize(10)
                .fontColor($r('app.color.text_secondary'))
                .backgroundColor($r('app.color.bg_page'))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(4)
                .margin({ right: 6 })
            }, (tag: string) => tag)
          }
          .margin({ top: 6 })

          Text(car.seats + '座 · ' + car.transmission + ' · ' + car.displacement)
            .fontSize($r('app.float.font_size_small'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }

      Divider().color($r('app.color.divider')).margin({ top: 12 })

      Row() {
        Column() {
          Row() {
            Text('¥' + car.pricePerDay)
              .fontSize($r('app.float.font_size_price'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary_orange'))
            Text('/天')
              .fontSize($r('app.float.font_size_small'))
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 2 })
          }
          if (car.originalPrice) {
            Text('原价 ¥' + car.originalPrice + '/天')
              .fontSize($r('app.float.font_size_small'))
              .fontColor($r('app.color.text_hint'))
              .decoration({ type: TextDecorationType.LineThrough })
          }
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Button() {
          Text('立即预订')
            .fontSize($r('app.float.font_size_caption'))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .height(36)
        .backgroundColor($r('app.color.primary_orange'))
        .borderRadius(18)
        .onClick(() => this.goConfirm(car.id))
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
}
