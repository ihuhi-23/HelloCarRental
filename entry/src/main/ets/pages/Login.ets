import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { loginWithCode, loginWithPassword, AuthResult } from '../common/HttpUtil';
import { LoginForm } from '../common/Interfaces';

/**
 * 页面：Login 登录
 * 分工：成员五 · 简单页面
 * 入口：个人中心退出登录后进入
 * 功能：登录提示轮播、验证码登录、密码登录、注册入口
 * 容器：Swiper（登录提示轮播）、Scroll（登录表单）
 * 关键状态：isCodeLogin（登录方式切换）、countdown（验证码倒计时）、isSubmitting（防重复提交）
 * 关键方法：doLogin() 调用 HttpUtil.loginWithCode()/loginWithPassword()、sendCode() 获取验证码
 */
@Entry
@Component
struct Login {
  @State form: LoginForm = { phone: '', code: '', password: '' };
  @State loginTips: string[] = ['新用户注册立享首单立减 100 元', '全国 5 大门店 24 小时取还车', '芝麻信用免押 最快 3 分钟取车'];
  @State isCodeLogin: boolean = true;
  @State countdown: number = 0;
  @State isSubmitting: boolean = false;

  // 作用：校验手机号后发送验证码（演示验证码 1234），并启动 60 秒倒计时
  private sendCode() {
    if (!this.isPhoneValid()) {
      promptAction.showToast({ message: '请输入正确的 11 位手机号' });
      return;
    }
    this.countdown = 60;
    const timer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) clearInterval(timer);
    }, 1000);
    promptAction.showToast({ message: '验证码已发送（演示验证码 1234）' });
  }

  // 作用：用正则校验 11 位手机号
  private isPhoneValid(): boolean {
    return /^1[3-9]\d{9}$/.test(this.form.phone);
  }

  // 作用：调用 HttpUtil.loginWithCode() 或 loginWithPassword() 登录，成功后跳转 Index
  private async doLogin() {
    if (this.isSubmitting) return;
    if (!this.isPhoneValid()) {
      promptAction.showToast({ message: '请输入正确的 11 位手机号' });
      return;
    }
    let res: AuthResult = { success: false, message: '' };
    this.isSubmitting = true;
    if (this.isCodeLogin) {
      if (!this.form.code) {
        this.isSubmitting = false;
        promptAction.showToast({ message: '请输入验证码' });
        return;
      }
      res = await loginWithCode(this.form.phone, this.form.code);
    } else {
      if (this.form.password.length < 6) {
        this.isSubmitting = false;
        promptAction.showToast({ message: '请输入至少 6 位密码' });
        return;
      }
      res = await loginWithPassword(this.form.phone, this.form.password);
    }
    this.isSubmitting = false;
    if (res.success) {
      promptAction.showToast({ message: '登录成功' });
      router.replaceUrl({ url: 'pages/Index' });
    } else {
      promptAction.showToast({ message: res.message });
    }
  }
  // 作用：跳转到 Register 注册页，无参数
  private goRegister() { router.pushUrl({ url: 'pages/Register' }); }

  build() {
    Column() {
      // ===== 顶部关闭与注册入口 =====
      Row() {
        Text('✕').fontSize(20).fontColor($r('app.color.text_primary')).onClick(() => router.back())
        Blank()
        Text('注册').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.primary_orange')).onClick(() => this.goRegister())
      }
      .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

      // ===== 登录提示轮播：Swiper + ForEach =====
      Swiper() {
        ForEach(this.loginTips, (tip: string) => {
          Text(tip)
            .width('100%').height(72)
            .fontSize($r('app.float.font_size_body'))
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .backgroundColor($r('app.color.primary_orange'))
            .borderRadius(10)
        }, (tip: string): string => tip)
      }
      .width('100%').height(72)
      .autoPlay(true).interval(3500).indicator(true)
      .margin({ left: 16, right: 16, top: 8 })

      // ===== 登录表单滚动区 =====
      Scroll() {
        Column() {
          Text('🚗').fontSize(72).margin({ top: 40 })
          Text('Hello 租车').fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 16 })
          Text('便捷出行 · 值得信赖').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 8 })

          // ===== 验证码登录 / 密码登录切换 =====
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

          // ===== 手机号输入 =====
          Row() {
            Text('+86').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
            Column().width(1).height(20).backgroundColor($r('app.color.divider')).margin({ left: 12, right: 12 })
            TextInput({ placeholder: '请输入手机号', text: this.form.phone })
              .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
              .onChange((v: string) => { this.form.phone = v; })
          }
          .width('100%').height(48).padding({ left: 12, right: 12 })
          .backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 验证码 / 密码输入（随登录方式切换） =====
          Row() {
            if (this.isCodeLogin) {
              TextInput({ placeholder: '请输入验证码', text: this.form.code })
                .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
                .type(InputType.Number).onChange((v: string) => { this.form.code = v; })
              Button() {
                Text(this.countdown > 0 ? this.countdown + 's' : '获取验证码')
                  .fontSize($r('app.float.font_size_caption'))
                  .fontColor(this.countdown > 0 ? $r('app.color.text_secondary') : $r('app.color.primary_orange'))
              }
              .backgroundColor(Color.Transparent).height(32).enabled(this.countdown <= 0)
              .onClick(() => this.sendCode())
            } else {
              TextInput({ placeholder: '请输入密码', text: this.form.password })
                .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
                .type(InputType.Password).onChange((v: string) => { this.form.password = v; })
            }
          }
          .width('100%').height(48).padding({ left: 12, right: 12 })
          .backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 登录按钮 =====
          Button() {
            Text('登录').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).margin({ top: 32 })
          .onClick(() => this.doLogin())

          // ===== 用户协议勾选 =====
          Row() {
            Checkbox().width(16).height(16)
            Text('已阅读并同意').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ left: 8 })
            Text('《用户协议》').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange'))
            Text('和').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
            Text('《隐私政策》').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange'))
          }
          .margin({ top: 16 })

          Blank()

          // ===== 第三方登录图标（仅展示） =====
          Row() {
            Column() { Text('💬').fontSize(28) }.width(44).height(44).backgroundColor(Color.White).borderRadius(22).justifyContent(FlexAlign.Center).margin({ right: 24 })
            Column() { Text('🅰️').fontSize(28) }.width(44).height(44).backgroundColor(Color.White).borderRadius(22).justifyContent(FlexAlign.Center).margin({ right: 24 })
            Column() { Text('🍎').fontSize(28) }.width(44).height(44).backgroundColor(Color.White).borderRadius(22).justifyContent(FlexAlign.Center)
          }
          .margin({ top: 24 })
        }
        .padding(24).alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
