import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NavBar } from '../common/NavBar';
import { mockPaymentMethods } from '../common/MockData';
import { PaymentMethod } from '../common/Interfaces';
import { updateOrderStatus } from '../common/HttpUtil';

/**
 * 页面：Payment 支付方式（收银台）
 * 分工：成员二 · 简单页面
 * 入口：OrderConfirm 提交订单后跳转
 * 功能：应付金额、支付方式选择、确认支付
 * 容器：List（支付方式列表）、Scroll（页面滚动）
 * 关键状态：selectedIndex（选中支付方式）、amount（应付金额）、isPaying（支付中）
 * 关键方法：pay() 调用 HttpUtil.updateOrderStatus() 后进入 PaymentSuccess
 * 数据来源：订单参数来自 OrderConfirm，支付方式为 Mock 数据
 */
@Entry
@Component
struct Payment {
  @State selectedIndex: number = 0;
  @State amount: number = 0;
  @State orderId: string = '';
  @State orderNo: string = '';
  @State isPaying: boolean = false;

  // 作用：从路由参数读取 orderId、orderNo、amount
  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.orderId = params['orderId'] || '';
      this.orderNo = params['orderNo'] || '';
      this.amount = Number(params['amount'] || 0);
    }
  }

  // 作用：调用 HttpUtil.updateOrderStatus() 把订单改为已确认，再跳转 PaymentSuccess
  private async pay() {
    if (this.isPaying) return;
    this.isPaying = true;
    if (this.orderId) {
      const ok = await updateOrderStatus(this.orderId, 'CONFIRMED');
      if (!ok) {
        this.isPaying = false;
        promptAction.showToast({ message: '支付失败，请检查后端服务' });
        return;
      }
    }
    this.isPaying = false;
    router.replaceUrl({
      url: 'pages/PaymentSuccess',
      params: { orderId: this.orderId, orderNo: this.orderNo, amount: String(this.amount), from: 'booking' }
    });
  }

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      NavBar({ title: '收银台', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      // ===== 页面滚动区 =====
      Scroll() {
        Column() {
          // ===== 应付金额卡片 =====
          Column() {
            Text('应付金额（元）').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary'))
            Text('¥' + this.amount).fontSize(32).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 8 })
            Text('订单号：' + (this.orderNo || '—')).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_hint')).margin({ top: 8 })
          }
          .width('100%').padding(20).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 }).alignItems(HorizontalAlign.Center)

          // ===== 支付方式选择 =====
          Column() {
            Text('选择支付方式').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
            // ===== 支付方式列表：List + ListItem + ForEach =====
            List() {
              ForEach(mockPaymentMethods, (pm: PaymentMethod, idx: number) => {
                ListItem() {
                  Row() {
                    Text(pm.type === 'bankcard' ? '💳' : (pm.type === 'wechat' ? '💬' : '💰')).fontSize(24)
                      .width(40).height(40).textAlign(TextAlign.Center)
                      .backgroundColor(pm.isDefault ? $r('app.color.primary_orange_light') : $r('app.color.bg_page'))
                      .borderRadius(10)
                    Column() {
                      Text(pm.name).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                      if (pm.cardNo) {
                        Text(pm.cardNo).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
                      }
                    }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
                    if (idx === this.selectedIndex) {
                      Text('●').fontSize(20).fontColor($r('app.color.primary_orange'))
                    } else {
                      Text('○').fontSize(20).fontColor($r('app.color.text_hint'))
                    }
                  }
                  .width('100%').padding(12).onClick(() => { this.selectedIndex = idx; })
                  .margin({ bottom: 8 })
                }
              }, (pm: PaymentMethod): string => pm.id)
            }
            .width('100%').scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.None)
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

      // ===== 底部确认支付按钮 =====
      Button() {
        Text(this.isPaying ? '支付中…' : '确认支付 ¥' + this.amount).fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
      }
      .width('100%').height(48).backgroundColor(this.isPaying ? '#FFBD9B' : $r('app.color.primary_orange')).borderRadius(24)
      .margin({ left: 16, right: 16, top: 12, bottom: 12 })
      .enabled(!this.isPaying)
      .onClick(() => { this.pay(); })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
