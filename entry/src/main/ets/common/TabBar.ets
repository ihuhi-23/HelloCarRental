/**
 * TabBar 底部标签栏组件
 * 用途：4 个 tab（首页/订单/客服/我的），点击后通过父组件回调 onTabChange 切换页面
 * props：currentIndex 当前选中下标；onTabChange(index) 父页面的切换回调
 * 使用页面：Index、MyOrders、PersonalCenter、AIChat、InUse（各页面自行 switchTab）
 */
@Component
export struct TabBar {
  @Prop currentIndex: number = 0;
  onTabChange: (index: number) => void = () => {};

  build() {
    // ===== 四个 tab：点击回调 onTabChange(index)，由父页面决定跳转 =====
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
