/**
 * NavBar 顶部导航栏组件
 * 用途：统一标题栏，支持返回按钮与右侧操作文字
 * props：title 标题；showBack 是否显示返回；rightText 右侧文字；onBack / onRightClick 回调
 * 使用页面：Index、CarFilter、StoreQuery、OrderConfirm、OrderDetail、Payment、PaymentSuccess、
 *           InUse、MyOrders、PickupVoucher、ReturnConfirm、FeeSettlement、AIChat、
 *           Register、VerifyAuth、Violation；也被 PageContainer 内部复用
 */
@Component
export struct NavBar {
  @Prop title: string = '';
  @Prop showBack: boolean = true;
  @Prop rightText: string = '';
  onBack: () => void = () => {};
  onRightClick: () => void = () => {};

  build() {
    Row() {
      // ===== 左侧返回按钮 =====
      if (this.showBack) {
        Text('‹')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 12 })
          .onClick(() => {
            this.onBack();
          })
      } else {
        Blank().width(40)
      }

      // ===== 中间标题 =====
      Text(this.title)
        .fontSize($r('app.float.font_size_title'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // ===== 右侧操作文字（可选）=====
      if (this.rightText.length > 0) {
        Text(this.rightText)
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ right: 16 })
          .onClick(() => {
            this.onRightClick();
          })
      } else {
        Blank().width(40)
      }
    }
    .width('100%')
    .height($r('app.float.nav_bar_height'))
    .backgroundColor($r('app.color.bg_card'))
  }
}
