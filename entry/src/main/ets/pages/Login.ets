import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

/**
 * 页面 9：登录
 */
@Entry
@Component
struct Login {
  @State phone: string = '';
  @State code: string = '';
  @State password: string = '';
  @State isCodeLogin: boolean = true;
  @State countdown: number = 0;

  private sendCode() {
    this.countdown = 60;
    const timer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) clearInterval(timer);
    }, 1000);
  }

  private doLogin() {
    if (this.phone.length < 6) {
      promptAction.showToast({ message: '请输入手机号' });
      return;
    }
    if (this.isCodeLogin) {
      if (this.code !== '1234') {
        promptAction.showToast({ message: '验证码错误（请输入 1234）' });
        return;
      }
    } else {
      if (this.password.length < 4) {
        promptAction.showToast({ message: '请输入密码' });
        return;
      }
    }
    router.replaceUrl({ url: 'pages/Index' });
  }
  private goRegister() { router.pushUrl({ url: 'pages/Register' }); }

  build() {
    Column() {
      Row() {
        Text('✕').fontSize(20).fontColor($r('app.color.text_primary')).onClick(() => router.back())
        Blank()
        Text('注册').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.primary_orange')).onClick(() => this.goRegister())
      }
      .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

      Scroll() {
        Column() {
          Text('🚗').fontSize(72).margin({ top: 40 })
          Text('Hello 租车').fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 16 })
          Text('便捷出行 · 值得信赖').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 8 })

          Row() {
            Text('验证码登录').fontSize($r('app.float.font_size_body'))
              .fontColor(this.isCodeLogin ? $r('app.color.primary_orange') : $r('app.color.text_secondary'))
              .fontWeight(this.isCodeLogin ? FontWeight.Medium : FontWeight.Normal)
              .onClick(() => this.isCodeLogin = true)
            Text('密码登录').fontSize($r('app.float.font_size_body'))
              .fontColor(!this.isCodeLogin ? $r('app.color.primary_orange') : $r('app.color.text_secondary'))
              .fontWeight(!this.isCodeLogin ? FontWeight.Medium : FontWeight.Normal)
              .margin({ left: 24 }).onClick(() => this.isCodeLogin = false)
          }
          .margin({ top: 40 })

          Row() {
            Text('+86').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
            Column().width(1).height(20).backgroundColor($r('app.color.divider')).margin({ left: 12, right: 12 })
            TextInput({ placeholder: '请输入手机号', text: this.phone })
              .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
              .onChange((v: string) => this.phone = v)
          }
          .width('100%').height(48).padding({ left: 12, right: 12 })
          .backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          Row() {
            if (this.isCodeLogin) {
              TextInput({ placeholder: '请输入验证码', text: this.code })
                .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
                .type(InputType.Number).onChange((v: string) => this.code = v)
              Button() {
                Text(this.countdown > 0 ? this.countdown + 's' : '获取验证码')
                  .fontSize($r('app.float.font_size_caption'))
                  .fontColor(this.countdown > 0 ? $r('app.color.text_secondary') : $r('app.color.primary_orange'))
              }
              .backgroundColor(Color.Transparent).height(32).enabled(this.countdown <= 0)
              .onClick(() => this.sendCode())
            } else {
              TextInput({ placeholder: '请输入密码', text: this.password })
                .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
                .type(InputType.Password).onChange((v: string) => this.password = v)
            }
          }
          .width('100%').height(48).padding({ left: 12, right: 12 })
          .backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          Button() {
            Text('登录').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).margin({ top: 32 })
          .onClick(() => this.doLogin())

          Row() {
            Checkbox().width(16).height(16)
            Text('已阅读并同意').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ left: 8 })
            Text('《用户协议》').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange'))
            Text('和').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
            Text('《隐私政策》').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange'))
          }
          .margin({ top: 16 })

          Blank()

          Row() {
            Column() { Text('💬').fontSize(28) }.width(44).height(44).backgroundColor(Color.White).borderRadius(22).justifyContent(FlexAlign.Center).margin({ right: 24 })
            Column() { Text('🅰️').fontSize(28) }.width(44).height(44).backgroundColor(Color.White).borderRadius(22).justifyContent(FlexAlign.Center).margin({ right: 24 })
            Column() { Text('🍎').fontSize(28) }.width(44).height(44).backgroundColor(Color.White).borderRadius(22).justifyContent(FlexAlign.Center)
          }
          .margin({ top: 24 })
        }
        .padding(24).alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
