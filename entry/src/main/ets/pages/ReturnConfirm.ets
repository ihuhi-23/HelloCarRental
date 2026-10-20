import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { OrderInfo } from '../common/Interfaces';
import { fetchOrderDetail, fetchOrders, fetchStores } from '../common/HttpUtil';

/**
 * 页面 16：还车确认
 * 数据来源：后端 /api/orders/:id + /api/stores
 */
@Entry
@Component
struct ReturnConfirm {
  @State order: OrderInfo | null = null;
  @State selectedStore: string = '';
  @State selectedTime: string = '';
  @State hasDamage: boolean = false;
  @State agree: boolean = false;
  @State storeNames: string[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadData();
  }

  private async loadData() {
    try {
      const params = router.getParams() as Record<string, string>;
      const orderId = params ? params['orderId'] : '';
      if (orderId) {
        this.order = await fetchOrderDetail(orderId);
      }
      if (!this.order) {
        // fallback: 找第一个订单
        const all = await fetchOrders();
        this.order = all[0] || null;
      }

      // 加载门店列表
      const stores = await fetchStores();
      this.storeNames = stores.map((s) => s.name);
      if (this.storeNames.length > 0) this.selectedStore = this.storeNames[0];

      if (this.order) {
        this.selectedTime = this.order.returnTime;
      }
    } catch (e) {
      console.error('Load return confirm data failed');
    } finally {
      this.isLoading = false;
    }
  }

  private times: string[] = ['2026-10-23 10:00', '2026-10-23 14:00', '2026-10-23 18:00', '2026-10-24 10:00'];

  private goFee() {
    if (this.order) {
      router.pushUrl({ url: 'pages/FeeSettlement', params: { orderId: this.order.id } });
    } else {
      router.pushUrl({ url: 'pages/FeeSettlement' });
    }
  }

  build() {
    Column() {
      NavBar({ title: '还车确认', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      if (this.isLoading || !this.order) {
        Column() {
          Text('⏳').fontSize(48)
          Text('加载中...').fontSize(14).fontColor('#909399').margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Image(this.order.carImage).width(64).height(64).objectFit(ImageFit.Cover).borderRadius(10)
                Column() {
                  Text(this.order.carName).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                  Text('取车：' + this.order.pickupStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                  Text(this.order.pickupTime + ' ~ ' + this.order.returnTime).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.primary_orange')).margin({ top: 2 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Column() {
              Text('选择还车门店').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              ForEach(this.storeNames, (s: string) => {
                Row() {
                  Text('📍 ' + s).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                  Blank()
                  if (this.selectedStore === s) Text('✓').fontSize(16).fontColor($r('app.color.primary_orange'))
                }
                .width('100%').padding({ top: 10, bottom: 10 })
                .onClick(() => this.selectedStore = s)
              }, (s: string) => s)
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Column() {
              Text('选择还车时间').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.times, (t: string) => {
                  Text(t)
                    .fontSize(12)
                    .fontColor(this.selectedTime === t ? Color.White : $r('app.color.text_primary'))
                    .backgroundColor(this.selectedTime === t ? $r('app.color.primary_orange') : $r('app.color.bg_page'))
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(14).margin({ right: 8, bottom: 8 })
                    .onClick(() => this.selectedTime = t)
                }, (t: string) => t)
              }
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Row() {
              Column() {
                Text('车辆是否有损伤？').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                Text('如无损伤将直接进入结算流程').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.hasDamage }).onChange((v: boolean) => this.hasDamage = v)
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Row() {
              Checkbox().width(16).height(16).onChange((v: boolean) => this.agree = v)
              Text('我已阅读并同意').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ left: 6 })
              Text('《还车协议》').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange'))
            }
            .margin({ top: 16 })
          }
          .padding(16).padding({ bottom: 100 })
        }
        .layoutWeight(1).scrollBar(BarState.Off)

        Button() {
          Text('确认还车').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
        }
        .width('100%').height(48).backgroundColor(this.agree ? $r('app.color.primary_orange') : '#FFBD9B').borderRadius(24)
        .margin({ left: 16, right: 16, top: 12, bottom: 12 }).enabled(this.agree)
        .onClick(() => this.goFee())
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
