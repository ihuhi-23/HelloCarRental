import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { OrderInfo, OrderStatus } from '../common/Interfaces';
import { fetchOrderDetail } from '../common/HttpUtil';

/**
 * 页面 8：订单详情
 * 数据来源：后端 /api/orders/:id
 */
@Entry
@Component
struct OrderDetail {
  @State order: OrderInfo | null = null;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadOrder();
  }

  private async loadOrder() {
    try {
      const params = router.getParams() as Record<string, string>;
      const orderId = params ? params['orderId'] : '';
      if (orderId) {
        const result = await fetchOrderDetail(orderId);
        if (result) this.order = result;
      }
    } catch (e) {
      console.error('Load order detail failed');
    } finally {
      this.isLoading = false;
    }
  }

  private goPay() { router.pushUrl({ url: 'pages/Payment' }); }
  private goFee() { router.pushUrl({ url: 'pages/FeeSettlement' }); }

  build() {
    Column() {
      NavBar({ title: '订单详情', onBack: (): void => { router.back(); }, rightText: '客服', onRightClick: (): void => { router.pushUrl({ url: "pages/AIChat" }); } })

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
              Text('📦').fontSize(36)
              Text(this.order.status).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 8 })
              Text('订单号：' + this.order.orderNo).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            }
            .width('100%').padding(20).backgroundColor(Color.White).borderRadius(12).alignItems(HorizontalAlign.Center).margin({ top: 12 })

            Column() {
              Text('车辆信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              Row() {
                Image(this.order.carImage).width(56).height(56).objectFit(ImageFit.Cover).borderRadius(10)
                Column() {
                  Text(this.order.carName).fontSize($r('app.float.font_size_subtitle')).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
                  Text('¥' + (this.order.totalPrice / this.order.days).toFixed(0) + '/天 · ' + this.order.days + '天').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Column() {
              Text('取还车信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              this.InfoLine('取车门店', this.order.pickupStore)
              this.InfoLine('取车时间', this.order.pickupTime)
              this.InfoLine('还车门店', this.order.returnStore)
              this.InfoLine('还车时间', this.order.returnTime)
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Column() {
              Text('费用明细').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              this.InfoLine('租车费用', '¥' + (this.order.totalPrice + (this.order.discount || 0)))
              if (this.order.discount) this.InfoLine('优惠券', '-¥' + this.order.discount)
              if (this.order.insurance) this.InfoLine('保险费用', '¥' + this.order.insurance)
              Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
              Row() {
                Text('合计').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                Blank()
                Text('¥' + this.order.totalPrice).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
          }
          .padding(16).padding({ bottom: 100 })
        }
        .layoutWeight(1).scrollBar(BarState.Off)

        Row() {
          Button() { Text('联系客服').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')) }
            .layoutWeight(1).height(44).backgroundColor(Color.White).border({ width: 1, color: $r('app.color.divider') }).borderRadius(22).margin({ right: 12 })
          Button() {
            Text(this.order.status === OrderStatus.PENDING ? '立即支付' : '还车结算').fontSize($r('app.float.font_size_body')).fontColor(Color.White)
          }
          .layoutWeight(1).height(44).backgroundColor($r('app.color.primary_orange')).borderRadius(22)
          .onClick(() => { if (this.order && this.order.status === OrderStatus.PENDING) this.goPay(); else this.goFee(); })
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor(Color.White)
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  InfoLine(label: string, value: string) {
    Row() {
      Text(label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(80)
      Text(value).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }
}
