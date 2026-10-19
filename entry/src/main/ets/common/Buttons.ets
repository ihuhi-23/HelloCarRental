/**
 * 按钮组件
 */

@Component
export struct PrimaryButton {
  @Prop text: string = '立即预订';
  onTap: () => void = () => {};
  @Prop btnEnabled: boolean = true;
  @Prop btnHeight: number = 48;

  build() {
    Button() {
      Text(this.text)
        .fontSize($r('app.float.font_size_body'))
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
    }
    .width('100%')
    .height(this.btnHeight)
    .backgroundColor(this.btnEnabled ? $r('app.color.primary_orange') : '#FFBD9B')
    .borderRadius($r('app.float.btn_radius'))
    .enabled(this.btnEnabled)
    .onClick(() => {
      if (this.btnEnabled && this.onTap) this.onTap();
    })
  }
}
