import router from '@ohos.router';
import { NavBar } from '../common/NavBar';

/**
 * 页面 5：支付成功
 */
@Entry
@Component
struct PaymentSuccess {
  private goVoucher() { router.replaceUrl({ url: 'pages/PickupVoucher' }); }
  private goHome() { router.replaceUrl({ url: 'pages/Index' }); }

  build() {
    Column() {
      NavBar({ title: '支付成功', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      Column() {
        Column() { Text('✓').fontSize(40).fontWeight(FontWeight.Bold).fontColor($r('app.color.success_green')) }
          .width(80).height(80).backgroundColor($r('app.color.success_bg')).borderRadius(40).justifyContent(FlexAlign.Center).margin({ top: 40 })

        Text('支付成功').fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 20 })
        Text('¥1,084.00').fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 8 })
        Text('订单已确认，请按时前往门店取车').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 16 })

        Column() {
          Row() { Text('订单号').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')); Blank(); Text('HC2026101500001').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')) }.width('100%')
          Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
          Row() { Text('取车门店').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')); Blank(); Text('浦东机场 T2 航站楼店').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')) }.width('100%')
          Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
          Row() { Text('取车时间').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')); Blank(); Text('2026-10-20 10:00').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')) }.width('100%')
        }
        .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 24 })

        Blank()

        Row() {
          Button() { Text('返回首页').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')) }
            .layoutWeight(1).height(44).backgroundColor(Color.White).border({ width: 1, color: $r('app.color.divider') }).borderRadius(22).margin({ right: 12 })
            .onClick(() => this.goHome())
          Button() { Text('查看取车凭证').fontSize($r('app.float.font_size_body')).fontColor(Color.White) }
            .layoutWeight(1).height(44).backgroundColor($r('app.color.primary_orange')).borderRadius(22).onClick(() => this.goVoucher())
        }
        .width('100%').margin({ bottom: 24 })
      }
      .layoutWeight(1).padding(24).width('100%')
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
