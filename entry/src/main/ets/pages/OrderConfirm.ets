import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import webview from '@ohos.web.webview';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { CarInfo, Coupon, OrderInfo, StoreInfo } from '../common/Interfaces';
import { fetchCarDetail, fetchCoupons, fetchStores, createOrder, CreateOrderParams, BASE_URL } from '../common/HttpUtil';

// 地图 H5 与原生页面的桥接对象：H5 内调用 window.ohosBridge.onStoreSelect(storeId)
class StoreBridge {
  onSelect: (id: string) => void = (id: string): void => {};
  // 作用：H5 地图调用此方法回传门店 id，转调 onSelect 回调
  onStoreSelect(id: string): void {
    this.onSelect(id);
  }
}

/**
 * 页面：OrderConfirm 预订确认
 * 分工：成员三 · 复杂页面
 * 入口：Index 车辆卡片「立即预订」
 * 功能：车辆信息、取还车门店选择（列表/地图）、优惠券、保险、费用明细、提交订单
 * 容器：Scroll（订单内容）、ForEach（门店列表）、Web（高德地图 H5）
 * 关键状态：car（车辆详情）、pickupStore/returnStore（取还车门店）、selectedCoupon（优惠券索引）、useInsurance（保险开关）、showStorePicker（门店浮层）
 * 关键方法：loadData() 调用 HttpUtil.fetchCarDetail()/fetchCoupons()/fetchStores()、goPayment() 调用 HttpUtil.createOrder() 后进入 Payment
 */
@Entry
@Component
struct OrderConfirm {
  @State car: CarInfo | null = null;
  @State days: number = 3;
  @State useInsurance: boolean = true;
  @State selectedCoupon: number = -1;
  @State coupons: Coupon[] = [];
  @State pickupStore: string = '浦东机场 T2 航站楼店';
  @State returnStore: string = '浦东机场 T2 航站楼店';
  @State pickupStoreId: string = '';
  @State returnStoreId: string = '';
  @State stores: StoreInfo[] = [];
  @State showStorePicker: boolean = false;
  // 'pickup' = 正在选还车/取车门店
  @State pickingField: string = 'pickup';
  @State pickerTab: string = 'list';
  @State mapActivated: boolean = false;
  @State isSubmitting: boolean = false;

  // Web 控制器只创建一次；浮层常驻挂载，避免反复销毁 Web 内核
  private mapController: webview.WebviewController = new webview.WebviewController();
  private storeBridge: StoreBridge = new StoreBridge();

  // 作用：注册地图桥接回调，并加载确认页所需数据
  aboutToAppear() {
    this.storeBridge.onSelect = (id: string): void => { this.selectStoreById(id); };
    this.loadData();
  }

  // 作用：取路由 carId，调用 HttpUtil.fetchCarDetail()/fetchCoupons()/fetchStores() 加载数据
  private async loadData() {
    try {
      const params = router.getParams() as Record<string, string>;
      const carId = params ? params['carId'] : '';
      if (carId) {
        this.car = await fetchCarDetail(carId);
      }
      this.coupons = await fetchCoupons();
      const stores = await fetchStores();
      this.stores = stores;
      if (stores.length > 0) {
        const pickup = stores.find((s: StoreInfo): boolean => s.name === this.pickupStore);
        if (pickup) {
          this.pickupStoreId = pickup.id;
        } else {
          this.pickupStore = stores[0].name;
          this.pickupStoreId = stores[0].id;
        }
        const ret = stores.find((s: StoreInfo): boolean => s.name === this.returnStore);
        if (ret) {
          this.returnStoreId = ret.id;
        } else {
          this.returnStore = stores[0].name;
          this.returnStoreId = stores[0].id;
        }
      }
    } catch (e) {
      console.error('Load confirm data failed');
    }
  }

  // 作用：打开门店选择浮层，field 区分取车（pickup）与还车（return）
  private openStorePicker(field: string) {
    if (this.stores.length === 0) {
      promptAction.showToast({ message: '门店数据加载中，请稍后重试' });
      return;
    }
    this.pickingField = field;
    this.pickerTab = 'list';
    this.showStorePicker = true;
  }

  // 作用：关闭门店选择浮层
  private closeStorePicker() {
    this.showStorePicker = false;
  }

  // 作用：切换门店浮层的「列表 / 地图」模式，首次进地图才创建 Web
  private switchPickerTab(tab: string) {
    this.pickerTab = tab;
    if (tab === 'map') {
      this.mapActivated = true; // 首次打开地图才创建 Web，避免页面进入时就加载高德脚本
    }
  }

  // 作用：把选中的门店写入取车或还车字段，并关闭浮层
  private applyStore(store: StoreInfo) {
    if (this.pickingField === 'pickup') {
      this.pickupStore = store.name;
      this.pickupStoreId = store.id;
    } else {
      this.returnStore = store.name;
      this.returnStoreId = store.id;
    }
    this.showStorePicker = false;
  }

  // 作用：地图 H5 回传门店 id 后，按 id 找到门店并应用
  private selectStoreById(id: string) {
    const store = this.stores.find((s: StoreInfo): boolean => s.id === id);
    if (store) this.applyStore(store);
  }

  // 作用：返回当前正在选择（取车/还车）的门店 id，用于列表高亮
  private currentStoreId(): string {
    return this.pickingField === 'pickup' ? this.pickupStoreId : this.returnStoreId;
  }

  // 作用：车辆租金小计 = 日价 × 天数
  private getSubtotal(): number { return (this.car?.pricePerDay || 0) * this.days; }

  // 作用：计算优惠券减免金额，未达门槛时为 0
  private getDiscount(): number {
    if (this.selectedCoupon >= 0 && this.selectedCoupon < this.coupons.length) {
      const coupon = this.coupons[this.selectedCoupon];
      if (this.getSubtotal() >= coupon.threshold) return coupon.discount;
    }
    return 0;
  }

  // 作用：保险费用，开启无忧保险时固定 30 元
  private getInsuranceFee(): number { return this.useInsurance ? 30 : 0; }
  // 作用：合计金额 = 租金 - 优惠 + 保险
  private getTotal(): number { return this.getSubtotal() - this.getDiscount() + this.getInsuranceFee(); }

  // 作用：调用 HttpUtil.createOrder() 创建待支付订单，成功后跳转 Payment 并传 orderId/orderNo/amount
  private async goPayment() {
    if (this.isSubmitting || !this.car) return;
    this.isSubmitting = true;
    let params: CreateOrderParams = {
      carId: this.car.id,
      days: this.days,
      pickupStore: this.pickupStore,
      returnStore: this.returnStore,
      pickupTime: '2026-10-20 10:00',
      returnTime: '2026-10-23 10:00',
      discount: this.getDiscount(),
      insurance: this.getInsuranceFee()
    };
    const order: OrderInfo | null = await createOrder(params);
    this.isSubmitting = false;
    if (!order) {
      promptAction.showToast({ message: '提交订单失败，请检查后端服务' });
      return;
    }
    router.pushUrl({
      url: 'pages/Payment',
      params: { orderId: order.id, orderNo: order.orderNo, amount: String(this.getTotal()) }
    });
  }

  build() {
    // ===== 页面主体 + 底部门店选择浮层 =====
    Stack({ alignContent: Alignment.Bottom }) {
    Column() {
      // ===== 顶部导航栏 =====
      NavBar({ title: '确认订单', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      // ===== 轮播 Banner：SwiperBanner 组件内部使用 Swiper =====
      SwiperBanner()

      // ===== 车辆数据加载中占位 =====
      if (!this.car) {
        Column() {
          Text('⏳').fontSize(48)
          Text('加载中...').fontSize(14).fontColor('#909399').margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        // ===== 订单内容滚动区 =====
        Scroll() {
          Column() {
            // ===== 车辆信息与取还车门店 =====
            Column() {
              Row() {
                Image(this.car.imageUrl).width(72).height(72).objectFit(ImageFit.Cover).borderRadius(12)
                Column() {
                  Text(this.car.name).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                  Text(this.car.seats + '座 · ' + this.car.transmission + ' · ' + this.car.displacement)
                    .fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }
              Divider().color($r('app.color.divider')).margin({ top: 14, bottom: 14 })
              Row() {
                Text('取车门店').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(70)
                Column() {
                  Text(this.pickupStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_primary'))
                  Text('2026-10-20 10:00').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Text('›').fontSize(18).fontColor($r('app.color.text_secondary')).margin({ left: 8 })
              }
              .width('100%')
              .onClick(() => { this.openStorePicker('pickup'); })
              Row() {
                Text('还车门店').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(70)
                Column() {
                  Text(this.returnStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_primary'))
                  Text('2026-10-23 10:00').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Text('›').fontSize(18).fontColor($r('app.color.text_secondary')).margin({ left: 8 })
              }
              .width('100%').margin({ top: 12 })
              .onClick(() => { this.openStorePicker('return'); })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 优惠券选择（点击轮换可用优惠券） =====
            Row() {
              Text('优惠券').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
              Blank()
              if (this.getDiscount() > 0) {
                Text('-¥' + this.getDiscount()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.primary_orange')).margin({ right: 8 })
              } else {
                Text(this.coupons.length + '张可用').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ right: 8 })
              }
              Text('›').fontSize(16).fontColor($r('app.color.text_secondary'))
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
            .onClick(() => {
              if (this.coupons.length > 0) {
                this.selectedCoupon = (this.selectedCoupon + 1) % this.coupons.length;
              }
            })

            // ===== 无忧保险开关 =====
            Row() {
              Column() {
                Text('无忧保险').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                Text('覆盖车损险、第三者责任险等').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.useInsurance }).onChange((isOn: boolean) => { this.useInsurance = isOn; })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 费用明细：租金、优惠、保险、合计 =====
            Column() {
              Text('费用明细').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              Row() {
                Text('车辆租金 (' + this.days + '天)').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                Blank()
                Text('¥' + this.getSubtotal()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
              }.width('100%')
              if (this.getDiscount() > 0) {
                Row() {
                  Text('优惠券减免').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                  Blank()
                  Text('-¥' + this.getDiscount()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.primary_orange'))
                }.width('100%').margin({ top: 8 })
              }
              if (this.useInsurance) {
                Row() {
                  Text('无忧保险').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                  Blank()
                  Text('¥' + this.getInsuranceFee()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                }.width('100%').margin({ top: 8 })
              }
              Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
              Row() {
                Text('合计').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                Blank()
                Text('¥' + this.getTotal()).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
          }
          .padding(16).padding({ bottom: 100 })
        }
        .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

        // ===== 底部合计与「提交订单」按钮 =====
        Row() {
          Column() {
            Text('合计').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
            Text('¥' + this.getTotal()).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 2 })
          }.alignItems(HorizontalAlign.Start).margin({ right: 16 })
          Button() {
            Text(this.isSubmitting ? '提交中…' : '提交订单').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1).height(48).backgroundColor(this.isSubmitting ? '#FFBD9B' : $r('app.color.primary_orange')).borderRadius(24)
          .enabled(!this.isSubmitting)
          .onClick(() => { this.goPayment(); })
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor(Color.White)
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))

      // ===== 门店选择浮层（常驻挂载，只切换可见性，避免 Web 内核反复重建）=====
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%').height('100%').backgroundColor('#66000000')
          .onClick(() => { this.closeStorePicker(); })

        this.StorePickerSheet()
      }
      .width('100%').height('100%')
      .visibility(this.showStorePicker ? Visibility.Visible : Visibility.None)
    }
    .width('100%').height('100%')
  }

  // 作用：底部弹出的门店选择面板，支持列表与地图两种方式
  @Builder
  StorePickerSheet() {
    Column() {
      Row() {
        Text(this.pickingField === 'pickup' ? '选择取车门店' : '选择还车门店')
          .fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
        Blank()
        Text('✕').fontSize(16).fontColor($r('app.color.text_secondary'))
          .onClick(() => { this.closeStorePicker(); })
      }
      .width('100%').padding({ left: 20, right: 20, top: 18, bottom: 14 })

      Row() {
        Text('门店列表').fontSize(13)
          .fontColor(this.pickerTab === 'list' ? Color.White : $r('app.color.text_secondary'))
          .backgroundColor(this.pickerTab === 'list' ? $r('app.color.primary_orange') : Color.Transparent)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 }).borderRadius(14)
          .onClick(() => { this.switchPickerTab('list'); })
        Text('地图选择').fontSize(13)
          .fontColor(this.pickerTab === 'map' ? Color.White : $r('app.color.text_secondary'))
          .backgroundColor(this.pickerTab === 'map' ? $r('app.color.primary_orange') : Color.Transparent)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 }).borderRadius(14)
          .margin({ left: 8 })
          .onClick(() => { this.switchPickerTab('map'); })
      }
      .width('100%').padding({ left: 20, right: 20, bottom: 12 })
      .justifyContent(FlexAlign.Start)

      Divider().color($r('app.color.divider'))

      // ===== 门店面板内容：列表（ForEach） / 地图两种模式 =====
      Stack() {
        // 列表模式
        Scroll() {
          Column() {
            ForEach(this.stores, (store: StoreInfo) => {
              this.StoreOption(store);
            }, (store: StoreInfo) => store.id)
          }.padding({ top: 4, bottom: 16 })
        }
        .width('100%').height('100%').scrollBar(BarState.Off).align(Alignment.Top)
        .visibility(this.pickerTab === 'list' ? Visibility.Visible : Visibility.None)

        // 地图模式：Web 加载后端生成的高德 H5，点击标签通过 javaScriptProxy 回传门店 id
        if (this.mapActivated) {
          Web({ src: BASE_URL + '/api/map/stores?select=1', controller: this.mapController })
            .javaScriptProxy({
              object: this.storeBridge,
              name: 'ohosBridge',
              methodList: ['onStoreSelect'],
              controller: this.mapController
            })
            .width('100%').height('100%')
            .visibility(this.pickerTab === 'map' ? Visibility.Visible : Visibility.None)
        }
      }
      .width('100%').layoutWeight(1)
    }
    .width('100%').height(520)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
    .onClick(() => {})
  }

  // 作用：单个门店选项，显示名称、距离、地址、营业时间与选中状态
  @Builder
  StoreOption(store: StoreInfo) {
    Row() {
      Column() {
        Row() {
          Text(store.name).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
          if (store.distance) {
            Text(store.distance).fontSize(11).fontColor($r('app.color.primary_orange')).margin({ left: 8 })
          }
        }
        Text(store.address).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 })
        Text('营业时间 ' + store.hours).fontSize(10).fontColor($r('app.color.text_hint')).margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      if (store.id === this.currentStoreId()) {
        Text('✓').fontSize(16).fontColor($r('app.color.primary_orange')).fontWeight(FontWeight.Bold)
      }
    }
    .width('100%').padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .backgroundColor(store.id === this.currentStoreId() ? $r('app.color.primary_orange_light') : Color.White)
    .onClick(() => { this.applyStore(store); })
  }
}
