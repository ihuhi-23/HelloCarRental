import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { OrderInfo } from '../common/Interfaces';
import { fetchOrderDetail, fetchOrders } from '../common/HttpUtil';

/**
 * 页面 17：费用结算
 * 【复杂页面】
 * 数据来源：后端 /api/orders/:id
 */
@Entry
@Component
struct FeeSettlement {
  @State order: OrderInfo | null = null;
  @State baseFee: number = 0;
  @State extraFee: number = 80;
  @State insuranceFee: number = 30;
  @State discount: number = 100;
  @State penalty: number = 0;
  @State damageFee: number = 0;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadOrder();
  }

  private async loadOrder() {
    try {
      const params = router.getParams() as Record<string, string>;
      const orderId = params ? params['orderId'] : '';
      if (orderId) {
        this.order = await fetchOrderDetail(orderId);
      }
      if (!this.order) {
        const all = await fetchOrders();
        this.order = all[0] || null;
      }
      if (this.order) {
        this.baseFee = this.order.totalPrice - (this.order.discount || 0);
      }
    } catch (e) {
      console.error('Load fee order failed');
    } finally {
      this.isLoading = false;
    }
  }

  private getTotal(): number {
    return this.baseFee + this.extraFee + this.insuranceFee + this.penalty + this.damageFee - this.discount;
  }

  private confirmPay() { router.pushUrl({ url: 'pages/PaymentSuccess' }); }

  build() {
    Column() {
      NavBar({ title: '费用结算', onBack: (): void => { router.back(); }, rightText: '开发票', onRightClick: (): void => {} })

      SwiperBanner()

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
                Image(this.order.carImage).width(72).height(72).objectFit(ImageFit.Cover).borderRadius(12)
                Column() {
                  Text(this.order.carName).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                  Text(this.order.pickupStore + ' → ' + this.order.returnStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                  Text(this.order.pickupTime + ' ~ ' + this.order.returnTime + ' · ' + this.order.days + '天').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_hint')).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Column() {
              Text('费用明细').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              this.FeeRow('基础租车费', this.order.days + '天 × ¥' + Math.round(this.baseFee / this.order.days) + '/天', this.baseFee)
              this.FeeRow('无忧保险', '车损+第三者', this.insuranceFee)
              this.FeeRow('超时服务费', '超出30分钟', this.extraFee)
              Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
              this.FeeRow('违章罚款', '2条违章记录', this.penalty, true)
              this.FeeRow('车辆损伤', '轻微划痕', this.damageFee, true)
              if (this.order.discount) {
                Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
                this.FeeRow('优惠券抵扣', '已使用', this.order.discount, false, true)
              }
              Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
              Row() {
                Text('应付合计').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                Blank()
                Text('¥' + this.getTotal()).fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Column() {
              Text('💡 结算说明').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
              Text('• 基础租车费按实际租期计算').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
              Text('• 超时30分钟内免费，超过按小时计费').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
              Text('• 如有违章或损伤将另行扣费').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
          }
          .padding(16).padding({ bottom: 100 })
        }
        .layoutWeight(1).scrollBar(BarState.Off)

        Row() {
          Column() {
            Text('应付合计').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
            Text('¥' + this.getTotal()).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 2 })
          }.alignItems(HorizontalAlign.Start).margin({ right: 16 })
          Button() {
            Text('立即支付').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1).height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).onClick(() => this.confirmPay())
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor(Color.White)
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  FeeRow(title: string, sub: string, amount: number, isExtra: boolean = false, isDiscount: boolean = false) {
    Row() {
      Column() {
        Text(title).fontSize($r('app.float.font_size_body')).fontColor(isExtra && amount === 0 ? $r('app.color.text_hint') : $r('app.color.text_primary'))
        Text(sub).fontSize($r('app.float.font_size_small')).fontColor(isExtra && amount === 0 ? $r('app.color.text_hint') : $r('app.color.text_secondary')).margin({ top: 2 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text((isDiscount ? '-' : '') + '¥' + amount)
        .fontSize($r('app.float.font_size_body'))
        .fontColor(isDiscount ? $r('app.color.primary_orange') : (isExtra && amount === 0 ? $r('app.color.text_hint') : $r('app.color.text_primary')))
    }
    .width('100%').margin({ top: 8, bottom: 8 })
  }
}
