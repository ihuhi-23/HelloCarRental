import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NavBar } from '../common/NavBar';
import { register, AuthResult } from '../common/HttpUtil';
import { RegisterForm } from '../common/Interfaces';

/**
 * 页面：Register 注册
 * 分工：成员一 · 简单页面
 * 入口：Login 页右上角「注册」
 * 功能：提示轮播、手机号验证码、设置密码与确认密码、提交注册
 * 容器：Swiper（注册提示轮播）、Scroll（注册表单）
 * 关键状态：countdown（验证码倒计时）、isSubmitting（防重复提交）
 * 关键方法：doRegister() 调用 HttpUtil.register()，成功后进入 VerifyAuth 实名认证
 * 数据来源：后端注册接口
 */
@Entry
@Component
struct Register {
  @State form: RegisterForm = { phone: '', code: '', password: '', confirmPassword: '' };
  @State registerTips: string[] = ['注册即送 100 元优惠券', '上传证件 30 秒完成实名认证', '支持异地还车'];
  @State countdown: number = 0;
  @State isSubmitting: boolean = false;

  // 作用：用正则校验 11 位手机号
  private isPhoneValid(): boolean {
    return /^1[3-9]\d{9}$/.test(this.form.phone);
  }

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

  // 作用：校验表单后调用 HttpUtil.register()，成功后跳转 VerifyAuth 实名认证页
  private async doRegister() {
    if (this.isSubmitting) return;
    if (!this.isPhoneValid()) {
      promptAction.showToast({ message: '请输入正确的 11 位手机号' });
      return;
    }
    if (!this.form.code) {
      promptAction.showToast({ message: '请输入验证码' });
      return;
    }
    if (this.form.password.length < 6 || this.form.password.length > 20) {
      promptAction.showToast({ message: '密码需为 6-20 位' });
      return;
    }
    if (this.form.password !== this.form.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }
    this.isSubmitting = true;
    let res: AuthResult = await register(this.form.phone, this.form.code, this.form.password, '');
    this.isSubmitting = false;
    if (res.success) {
      promptAction.showToast({ message: '注册成功' });
      router.replaceUrl({ url: 'pages/VerifyAuth' });
    } else {
      promptAction.showToast({ message: res.message });
    }
  }

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      NavBar({ title: '注册账号', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      // ===== 注册提示轮播：Swiper + ForEach =====
      Swiper() {
        ForEach(this.registerTips, (tip: string) => {
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

      // ===== 注册表单滚动区 =====
      Scroll() {
        Column() {
          Text('🚗').fontSize(48).margin({ top: 40 })
          Text('欢迎注册 Hello 租车').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 12 })
          Text('注册即享新用户专属优惠').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 6 })

          // ===== 手机号与验证码 =====
          Column() {
            Text('手机号').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            Row() {
              TextInput({ placeholder: '请输入手机号', text: this.form.phone })
              .layoutWeight(1).type(InputType.PhoneNumber).maxLength(11).onChange((v: string) => { this.form.phone = v; })
              Button() { Text(this.countdown > 0 ? this.countdown + 's' : '获取验证码').fontSize(12).fontColor(this.countdown > 0 ? $r('app.color.text_secondary') : $r('app.color.primary_orange')) }
                .backgroundColor(Color.Transparent).height(32).enabled(this.countdown <= 0)
                .onClick(() => this.sendCode())
            }
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 32 })

          // ===== 验证码输入 =====
          Column() {
            Text('验证码').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            TextInput({ placeholder: '请输入6位验证码', text: this.form.code })
              .width('100%').type(InputType.Number).onChange((v: string) => { this.form.code = v; })
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 设置密码 =====
          Column() {
            Text('设置密码').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            TextInput({ placeholder: '6-20位字母、数字', text: this.form.password })
              .width('100%').type(InputType.Password).onChange((v: string) => { this.form.password = v; })
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 确认密码 =====
          Column() {
            Text('确认密码').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ bottom: 8 })
            TextInput({ placeholder: '请再次输入密码', text: this.form.confirmPassword })
              .width('100%').type(InputType.Password).onChange((v: string) => { this.form.confirmPassword = v; })
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding({ top: 16, bottom: 16 }).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 注册按钮 =====
          Button() {
            Text('注册').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).margin({ top: 32 })
          .onClick(() => this.doRegister())
        }
        .padding(24)
      }
      .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
