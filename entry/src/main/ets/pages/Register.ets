import router from '@ohos.router';
import { NavBar } from '../common/NavBar';

/**
 * 页面 10：注册
 */
@Entry
@Component
struct Register {
  @State phone: string = '';
  @State code: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';

  private doRegister() { router.replaceUrl({ url: 'pages/VerifyAuth' }); }

  build() {
    Column() {
      NavBar({ title: '注册账号', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      Scroll() {
        Column() {
          Text('🚗').fontSize(48).margin({ top: 40 })
          Text('欢迎注册 Hello 租车').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 12 })
          Text('注册即享新用户专属优惠').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 6 })

          Column() {
            Text('手机号').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            Row() {
              TextInput({ placeholder: '请输入手机号', text: this.phone })
              .layoutWeight(1).onChange((v: string) => this.phone = v)
              Button() { Text('获取验证码').fontSize(12).fontColor($r('app.color.primary_orange')) }
                .backgroundColor(Color.Transparent).height(32)
            }
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 32 })

          Column() {
            Text('验证码').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            TextInput({ placeholder: '请输入6位验证码', text: this.code })
              .width('100%').type(InputType.Number).onChange((v: string) => this.code = v)
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          Column() {
            Text('设置密码').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            TextInput({ placeholder: '6-20位字母、数字', text: this.password })
              .width('100%').type(InputType.Password).onChange((v: string) => this.password = v)
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          Column() {
            Text('确认密码').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
              .width('100%').type(InputType.Password).onChange((v: string) => this.confirmPassword = v)
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          Button() {
            Text('注册').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).margin({ top: 32 })
          .onClick(() => this.doRegister())
        }
        .padding(24)
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
