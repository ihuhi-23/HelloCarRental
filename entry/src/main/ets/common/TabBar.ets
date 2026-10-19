/**
 * 底部标签栏组件
 */
@Component
export struct TabBar {
  @Prop currentIndex: number = 0;
  onTabChange: (index: number) => void = () => {};

  build() {
    Row() {
      Column() {
        Text('🏠').fontSize(24).opacity(this.currentIndex === 0 ? 1 : 0.6)
        Text('首页').fontSize(10).fontColor(this.currentIndex === 0 ? $r('app.color.tab_selected') : $r('app.color.tab_unselected')).margin({ top: 2 })
      }
      .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
      .onClick(() => { this.onTabChange(0); })

      Column() {
        Text('📋').fontSize(24).opacity(this.currentIndex === 1 ? 1 : 0.6)
        Text('订单').fontSize(10).fontColor(this.currentIndex === 1 ? $r('app.color.tab_selected') : $r('app.color.tab_unselected')).margin({ top: 2 })
      }
      .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
      .onClick(() => { this.onTabChange(1); })

      Column() {
        Text('💬').fontSize(24).opacity(this.currentIndex === 2 ? 1 : 0.6)
        Text('客服').fontSize(10).fontColor(this.currentIndex === 2 ? $r('app.color.tab_selected') : $r('app.color.tab_unselected')).margin({ top: 2 })
      }
      .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
      .onClick(() => { this.onTabChange(2); })

      Column() {
        Text('👤').fontSize(24).opacity(this.currentIndex === 3 ? 1 : 0.6)
        Text('我的').fontSize(10).fontColor(this.currentIndex === 3 ? $r('app.color.tab_selected') : $r('app.color.tab_unselected')).margin({ top: 2 })
      }
      .layoutWeight(1).height('100%').justifyContent(FlexAlign.Center)
      .onClick(() => { this.onTabChange(3); })
    }
    .width('100%')
    .height($r('app.float.tab_bar_height'))
    .backgroundColor($r('app.color.bg_card'))
    .shadow({ radius: 1, color: '#1a000000', offsetY: -1 })
  }
}
