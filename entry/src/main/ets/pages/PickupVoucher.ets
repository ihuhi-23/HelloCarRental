import router from '@ohos.router';
import { NavBar } from '../common/NavBar';

/**
 * 页面 6：取车凭证
 */
@Entry
@Component
struct PickupVoucher {
  private goOrders() { router.replaceUrl({ url: 'pages/MyOrders' }); }

  build() {
    Column() {
      NavBar({ title: '取车凭证', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('🚗').fontSize(40).width(64).height(64).textAlign(TextAlign.Center)
              Column() {
                Text('宝马 3系 325Li').fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor(Color.White)
                Text('订单号 HC2026101500001').fontSize($r('app.float.font_size_small')).fontColor('#99FFFFFF').margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
            }.width('100%')
            Divider().color('#33FFFFFF').margin({ top: 16, bottom: 16 })
            Column() {
              Text('📱').fontSize(80)
              Text('出示此二维码即可取车').fontSize($r('app.float.font_size_caption')).fontColor('#99FFFFFF').margin({ top: 12 })
            }.margin({ top: 12 })
          }
          .width('100%').padding(20)
          .linearGradient({ angle: 180, colors: [['#FF6B00', 0], ['#FF8F3D', 1]] })
          .borderRadius(16).margin({ top: 12 })

          Column() {
            Text('取车信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 16 })
            this.InfoRow('取车门店', '浦东机场 T2 航站楼店')
            this.InfoRow('门店地址', '上海市浦东新区浦东机场T2航站楼出发层')
            this.InfoRow('联系电话', '021-12345678')
            this.InfoRow('取车时间', '2026-10-20 10:00')
            this.InfoRow('预计还车', '2026-10-23 10:00')
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Column() {
            Text('温馨提示').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 8 })
            Text('• 请携带本人身份证和驾驶证原件').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
            Text('• 如代取车需提前告知门店').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            Text('• 建议提前10分钟到达门店').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      Button() {
        Text('我的订单').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
      }
      .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24)
      .margin({ left: 16, right: 16, top: 12, bottom: 12 }).onClick(() => this.goOrders())
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(80)
      Text(value).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
    }
    .width('100%').padding({ top: 8, bottom: 8 })
  }
}
