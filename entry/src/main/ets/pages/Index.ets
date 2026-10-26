import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { CarInfo } from '../common/Interfaces';
import { fetchHomeCars } from '../common/HttpUtil';

/**
 * 页面：Index 车辆列表（首页）
 * 分工：成员一 · 复杂页面
 * 入口：应用启动首页 / 底部 TabBar「首页」
 * 功能：轮播、品牌宫格、门店行、搜索框、车辆列表
 * 容器：Grid（品牌宫格）、ForEach（车辆列表）、Swiper（SwiperBanner 组件内部）
 * 关键状态：carList（车辆数据）、searchText（搜索关键字）、currentTab（底部 Tab 索引）
 * 关键方法：loadRealCars() 调用 HttpUtil.fetchHomeCars() 拉取后端数据、goConfirm() 进入确认订单
 * 数据来源：后端 /api/cars
 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State searchText: string = '';
  @State storeName: string = '浦东机场 T2 · 1.2km';
  @State carList: CarInfo[] = [];
  @State isLoading: boolean = true;

  // Grid 品牌数据
  private brandIcons: string[] = ['奥迪', '宝马', '奔驰', '特斯拉', '丰田', '本田', '大众', '比亚迪'];

  // 作用：页面创建时加载首页车辆数据
  aboutToAppear() {
    this.loadRealCars();
  }

  // 作用：调用 HttpUtil.fetchHomeCars() 拉取车辆列表，失败时保留空列表
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

  // 作用：跳转到 CarFilter 车辆筛选页，无参数
  private goFilter() {
    router.pushUrl({ url: 'pages/CarFilter' });
  }

  // 作用：跳转到 OrderConfirm 确认订单页，传 carId 参数
  private goConfirm(carId: string) {
    router.pushUrl({ url: 'pages/OrderConfirm', params: { carId: carId } });
  }

  // 作用：底部 Tab 切换，非首页时用 replaceUrl 跳转到对应页面
  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 0) {
      router.replaceUrl({ url: pages[index] });
    }
  }

  build() {
    Column() {
      // ===== 顶部导航栏：右侧「筛选」按钮 =====
      NavBar({
        title: '选择车辆',
        showBack: false,
        rightText: '筛选',
        onBack: (): void => {},
        onRightClick: (): void => this.goFilter()
      })

      // ===== 外层 Scroll：NavBar 和 TabBar 固定，中间所有内容一起滚 =====
      Scroll() {
        Column() {
          // ===== 轮播 Banner：SwiperBanner 组件内部使用 Swiper =====
          SwiperBanner()

          // ===== 门店信息行 =====
          Row() {
            Text('📍 ' + this.storeName.substring(0, 12)).fontSize(13).fontColor($r('app.color.text_primary')).layoutWeight(1)
            Text('›').fontSize(16).fontColor($r('app.color.text_secondary')).margin({ left: 4 })
          }
          .width('100%').padding({ left: 16, right: 16, top: 6, bottom: 6 })

          // ===== 搜索框 =====
          Row() {
            Text('🔍').fontSize(14).margin({ right: 6 })
            TextInput({ placeholder: '搜索品牌或车型', text: this.searchText })
              .layoutWeight(1).backgroundColor(Color.Transparent).fontSize(13)
              .onChange((value: string) => { this.searchText = value; })
          }
          .width('100%').height(36).padding({ left: 12, right: 12 })
          .backgroundColor(Color.White).borderRadius(18)
          .margin({ left: 16, right: 16, bottom: 10 })

          // ===== 品牌宫格：Grid + GridItem + ForEach =====
          Grid() {
            ForEach(this.brandIcons, (brand: string) => {
              GridItem() {
                Column() {
                  Text(brand.substring(0, 1)).fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
                  Text(brand).fontSize(10).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
                }
                .width(44).height(44).backgroundColor(Color.White).borderRadius(22)
                .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              }
            }, (brand: string) => brand)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr').rowsGap(6).columnsGap(6)
          .width('100%').height(100)
          .padding({ left: 16, right: 16 }).backgroundColor($r('app.color.bg_page'))

          // ===== 热门车型标题与数量统计 =====
          Row() {
            Text('🔥 热门车型').fontSize(15).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
            Blank()
            Text(this.isLoading ? '加载中...' : ('共找到 ' + this.carList.length + ' 辆')).fontSize(12).fontColor($r('app.color.text_secondary'))
          }
          .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 8 })

          // ===== 车辆列表：ForEach 循环渲染 CarCard，数据来自 this.carList =====
          ForEach(this.carList, (car: CarInfo) => {
            this.CarCard(car)
          }, (car: CarInfo) => car.id)
        }
        .width('100%').padding({ bottom: 16 })
      }
      .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring).align(Alignment.Top)

      // ===== 底部 TabBar =====
      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // 作用：车辆卡片，展示车辆图片、品牌车型、配置、价格与「立即预订」按钮
  @Builder
  CarCard(car: CarInfo) {
    Column() {
      // ===== 大图 =====
      Image(car.imageUrl)
        .width('100%')
        .height(180)
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: 12, topRight: 12 })

      // ===== 车型与配置信息 =====
      Column() {
        Row() {
          Text(car.brand)
            .fontSize(11)
            .fontColor($r('app.color.primary_orange'))
            .backgroundColor($r('app.color.primary_orange_light'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
          Text(car.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .margin({ left: 8 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (car.inventory <= 2) {
            Text('仅剩 ' + car.inventory + ' 辆')
              .fontSize(10)
              .fontColor($r('app.color.primary_orange'))
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')

        Row() {
          Text(car.seats + '座')
            .fontSize(12).fontColor($r('app.color.text_secondary'))
          Text(' · ' + car.transmission + ' · ' + car.displacement)
            .fontSize(12).fontColor($r('app.color.text_secondary'))
          Text(' · ' + car.fuelType)
            .fontSize(12).fontColor($r('app.color.text_secondary'))
        }
        .margin({ top: 6 })

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
        .margin({ top: 8 })

        // ===== 价格与「立即预订」按钮 =====
        Row() {
          Row() {
            Text('¥')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary_orange'))
            Text(String(car.pricePerDay))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary_orange'))
            Text('/天')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 2 })
          }
          .alignItems(VerticalAlign.Bottom)

          Blank()

          Button() {
            Text('立即预订')
              .fontSize(13)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
          .height(34)
          .padding({ left: 20, right: 20 })
          .backgroundColor($r('app.color.primary_orange'))
          .borderRadius(17)
          .onClick(() => this.goConfirm(car.id))
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .width('100%')
      .padding(14)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .shadow({ radius: 2, color: '#0D000000', offsetY: 1 })
  }
}
