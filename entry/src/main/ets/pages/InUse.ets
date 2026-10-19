import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';

/**
 * 页面 15：用车中
 */
@Entry
@Component
struct InUse {
  @State currentTab: number = 3;

  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 3) router.replaceUrl({ url: pages[index] });
  }

  private goReturn() { router.pushUrl({ url: 'pages/ReturnConfirm' }); }
  private goViolation() { router.pushUrl({ url: 'pages/Violation' }); }

  build() {
    Column() {
      NavBar({ title: '用车中', showBack: false, onBack: (): void => {}, rightText: '客服', onRightClick: (): void => { router.pushUrl({ url: "pages/AIChat" }); } })

      Scroll() {
        Column() {
          Column() {
            Text('🚗').fontSize(56)
            Text('宝马 3系 325Li').fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 12 })
            Text('已用车：2天 4小时').fontSize($r('app.float.font_size_body')).fontColor('#99FFFFFF').margin({ top: 8 })
            Row() {
              Column() {
                Text('取车时间').fontSize(10).fontColor('#99FFFFFF')
                Text('2026-10-20 10:00').fontSize($r('app.float.font_size_caption')).fontColor(Color.White).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Column() {
                Text('预计还车').fontSize(10).fontColor('#99FFFFFF')
                Text('2026-10-23 10:00').fontSize($r('app.float.font_size_caption')).fontColor(Color.White).margin({ top: 4 })
              }.alignItems(HorizontalAlign.End)
            }
            .width('100%').margin({ top: 16 })
          }
          .width('100%').padding(20)
          .linearGradient({ angle: 180, colors: [['#34C759', 0], ['#5ED87A', 1]] })
          .borderRadius(16).alignItems(HorizontalAlign.Center).margin({ top: 12 })

          Column() {
            Text('快捷功能').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
            Row() {
              Column() { this.FuncItem('📍', '车辆定位') }.layoutWeight(1).justifyContent(FlexAlign.Center)
              Column() { this.FuncItem('🔑', '远程锁车') }.layoutWeight(1).justifyContent(FlexAlign.Center)
              Column() { this.FuncItem('🚨', '紧急求助') }.layoutWeight(1).justifyContent(FlexAlign.Center)
              Column() { this.FuncItem('☎️', '联系门店') }.layoutWeight(1).justifyContent(FlexAlign.Center)
            }.width('100%')
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Column() {
            Text('用车服务').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 8 })
            this.ServiceRow('📋', '违章查询', (): void => this.goViolation())
            this.ServiceRow('🔧', '道路救援', (): void => {})
            this.ServiceRow('⛽', '加油记录', (): void => {})
            this.ServiceRow('📷', '拍照记录车况', (): void => {})
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
        }
        .padding(16).padding({ bottom: 120 })
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      Button() {
        Text('我要还车').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
      }
      .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24)
      .margin({ left: 16, right: 16, top: 8, bottom: 8 }).onClick(() => this.goReturn())

      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  FuncItem(icon: string, label: string) {
    Column() {
      Text(icon).fontSize(28).width(48).height(48).textAlign(TextAlign.Center).backgroundColor($r('app.color.bg_page')).borderRadius(24)
      Text(label).fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ServiceRow(icon: string, label: string, onClick: () => void) {
    Row() {
      Text(icon).fontSize(20).margin({ right: 12 })
      Text(label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
      Text('›').fontSize(16).fontColor($r('app.color.text_secondary'))
    }
    .width('100%').padding({ top: 10, bottom: 10 }).onClick(() => onClick())
  }
}
