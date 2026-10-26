import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { OrderInfo } from '../common/Interfaces';
import { fetchOrderDetail, fetchOrders, updateOrderStatus } from '../common/HttpUtil';

/**
 * 页面：费用结算
 * 分工：成员六 · 复杂页面
 * 入口：订单详情「还车结算」/ 还车确认「确认还车」
 * 功能：费用明细、优惠抵扣、合计金额、立即支付
 * 容器：SwiperBanner（内部 Swiper 轮播）、Scroll（结算内容）
 * 关键状态：baseFee、extraFee、insuranceFee、discount、penalty、damageFee、isPaying
 * 关键方法：loadOrder() 调用 HttpUtil.fetchOrderDetail()/fetchOrders()、getTotal() 计算合计、confirmPay() 调用 HttpUtil.updateOrderStatus()
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
  @State isPaying: boolean = false;

  // 作用：页面加载时获取订单数据
  aboutToAppear() {
    this.loadOrder();
  }

  // 作用：读取订单并计算基础租车费
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

  // 作用：汇总基础费、保险、超时、违章、损伤并扣除优惠
  private getTotal(): number {
    return this.baseFee + this.extraFee + this.insuranceFee + this.penalty + this.damageFee - this.discount;
  }

  // 作用：调用 HttpUtil.updateOrderStatus() 标记订单已完成，再跳转 PaymentSuccess
  // 还车费用结清：把订单标记为已完成，再进入结算成功页（不展示取车凭证）
  private async confirmPay() {
    if (this.isPaying || !this.order) return;
    this.isPaying = true;
    const ok = await updateOrderStatus(this.order.id, 'COMPLETED');
    this.isPaying = false;
    if (!ok) {
      promptAction.showToast({ message: '结算失败，请检查后端服务' });
      return;
    }
    router.replaceUrl({
      url: 'pages/PaymentSuccess',
      params: { orderId: this.order.id, orderNo: this.order.orderNo, amount: String(this.getTotal()), from: 'return' }
    });
  }

  build() {
    Column() {
      NavBar({ title: '费用结算', onBack: (): void => { router.back(); }, rightText: '开发票', onRightClick: (): void => {} })

      // 轮播横幅：SwiperBanner（内部为 Swiper）
      SwiperBanner()

      // ===== 加载中占位 =====
      if (this.isLoading || !this.order) {
        Column() {
          Text('⏳').fontSize(48)
          Text('加载中...').fontSize(14).fontColor('#909399').margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          // ===== 主内容区：Scroll 纵向滚动 =====
          Column() {
            // ===== 车辆信息 =====
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

            // ===== 费用明细 =====
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

            // ===== 结算说明 =====
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
        .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

        // ===== 底部支付栏 =====
        Row() {
          Column() {
            Text('应付合计').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
            Text('¥' + this.getTotal()).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 2 })
          }.alignItems(HorizontalAlign.Start).margin({ right: 16 })
          Button() {
            Text(this.isPaying ? '支付中…' : '立即支付').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1).height(48).backgroundColor(this.isPaying ? '#FFBD9B' : $r('app.color.primary_orange')).borderRadius(24)
          .enabled(!this.isPaying)
          .onClick(() => { this.confirmPay(); })
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor(Color.White)
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // 作用：费用明细单行（标题 + 说明 + 金额，支持优惠/额外费用样式）
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
