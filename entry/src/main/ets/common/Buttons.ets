/**
 * PrimaryButton 主按钮组件
 * 用途：统一样式的橙色主操作按钮（如"立即预订"）
 * props：text 按钮文字；btnEnabled 是否可用；btnHeight 高度；onTap 点击回调
 * 使用页面：当前无页面引用（预留通用按钮）
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
