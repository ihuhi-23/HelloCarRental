import router from '@ohos.router';
import { NavBar } from '../common/NavBar';

/**
 * 页面 16：还车确认
 */
@Entry
@Component
struct ReturnConfirm {
  @State selectedStore: string = '浦东机场 T2 航站楼店';
  @State selectedTime: string = '2026-10-23 10:00';
  @State hasDamage: boolean = false;
  @State agree: boolean = false;

  private stores: string[] = ['浦东机场 T2 航站楼店', '虹桥机场 T2 航站楼店', '人民广场步行街店'];
  private times: string[] = ['2026-10-23 10:00', '2026-10-23 14:00', '2026-10-23 18:00', '2026-10-24 10:00'];

  private goFee() { router.pushUrl({ url: 'pages/FeeSettlement' }); }

  build() {
    Column() {
      NavBar({ title: '还车确认', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('🚗').fontSize(40).width(64).height(64).textAlign(TextAlign.Center).backgroundColor($r('app.color.bg_page')).borderRadius(10)
              Column() {
                Text('宝马 3系 325Li').fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                Text('取车：浦东机场 T2 · 2026-10-20 10:00').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                Text('已用车：2天').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.primary_orange')).margin({ top: 2 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
            }.width('100%')
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Column() {
            Text('选择还车门店').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
            ForEach(this.stores, (s: string) => {
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
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
