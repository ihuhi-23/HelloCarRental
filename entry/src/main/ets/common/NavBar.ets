/**
 * 导航栏组件
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

      Text(this.title)
        .fontSize($r('app.float.font_size_title'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

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
