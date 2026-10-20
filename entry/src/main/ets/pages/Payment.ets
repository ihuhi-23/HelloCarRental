import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { mockPaymentMethods } from '../common/MockData';
import { PaymentMethod } from '../common/Interfaces';

/**
 * 页面 4：支付方式（收银台）
 * 注意：后端暂无支付方式 API，当前使用 Mock 数据（mockPaymentMethods）
 */
@Entry
@Component
struct Payment {
  @State selectedIndex: number = 0;
  @State amount: number = 1084;

  private pay() { router.pushUrl({ url: 'pages/PaymentSuccess' }); }

  build() {
    Column() {
      NavBar({ title: '收银台', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      Scroll() {
        Column() {
          Column() {
            Text('应付金额（元）').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary'))
            Text('¥' + this.amount).fontSize(32).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 8 })
            Text('订单号：HC2026101500001').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_hint')).margin({ top: 8 })
          }
          .width('100%').padding(20).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 }).alignItems(HorizontalAlign.Center)

          Column() {
            Text('选择支付方式').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
            ForEach(mockPaymentMethods, (pm: PaymentMethod, idx: number) => {
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
                Radio({ value: pm.id, group: 'pay' }).checked(idx === this.selectedIndex)
              }
              .width('100%').padding(12).onClick(() => { this.selectedIndex = idx; })
              .margin({ bottom: 8 })
            }, (pm: PaymentMethod) => pm.id)
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      Button() {
        Text('确认支付 ¥' + this.amount).fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
      }
      .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24)
      .margin({ left: 16, right: 16, top: 12, bottom: 12 }).onClick(() => this.pay())
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
