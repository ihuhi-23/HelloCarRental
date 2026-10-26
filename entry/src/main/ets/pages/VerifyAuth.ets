import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { VerifyAuthForm } from '../common/Interfaces';

/**
 * 页面：实名认证
 * 分工：成员五 · 简单页面
 * 入口：个人中心「我的驾照」/ 注册后跳转
 * 功能：填写姓名、身份证号、上传证件照、人脸识别、提交审核
 * 容器：SwiperBanner（内部 Swiper 轮播）、Scroll（表单）
 * 关键状态：form（姓名与身份证）、faceVerified（人脸识别完成）
 * 关键方法：submit() 提交后 replaceUrl 返回 Index
 */
@Entry
@Component
struct VerifyAuth {
  @State form: VerifyAuthForm = { realName: '', idCard: '' };
  @State faceVerified: boolean = false;

  // 作用：提交认证，replaceUrl 回到首页 Index
  private submit() { router.replaceUrl({ url: 'pages/Index' }); }

  build() {
    Column() {
      NavBar({ title: '实名认证', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      // 轮播横幅：SwiperBanner（内部为 Swiper）
      SwiperBanner()

      // ===== 认证表单：Scroll 纵向滚动 =====
      Scroll() {
        Column() {
          // ===== 安全提示 =====
          Row() {
            Text('🛡️').fontSize(20)
            Text('为了保障您的用车安全，请完成实名认证').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ left: 8 }).layoutWeight(1)
          }
          .width('100%').padding(12).backgroundColor($r('app.color.primary_orange_light')).borderRadius(8).margin({ top: 12 })

          // ===== 真实姓名输入 =====
          Column() {
            TextInput({ placeholder: '请输入真实姓名', text: this.form.realName })
              .width('100%').fontSize($r('app.float.font_size_body')).onChange((v: string) => { this.form.realName = v; })
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(10).margin({ top: 16 })

          // ===== 身份证号输入 =====
          Column() {
            TextInput({ placeholder: '请输入身份证号码', text: this.form.idCard })
              .width('100%').fontSize($r('app.float.font_size_body')).type(InputType.Number).onChange((v: string) => { this.form.idCard = v; })
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 身份证照片上传 =====
          Column() {
            Text('上传身份证照片').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
            Row() {
              Column() {
                Column() { Text('📷').fontSize(36) }.width(100).height(70).backgroundColor($r('app.color.bg_page')).borderRadius(8).justifyContent(FlexAlign.Center)
                Text('人像面').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Center).margin({ right: 24 })
              Column() {
                Column() { Text('📷').fontSize(36) }.width(100).height(70).backgroundColor($r('app.color.bg_page')).borderRadius(8).justifyContent(FlexAlign.Center)
                Text('国徽面').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Center)
            }
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 人脸识别 =====
          Row() {
            Column() {
              Text('人脸识别').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
              Text('完成后可享受免押租车等服务').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Button() {
              Text(this.faceVerified ? '已完成' : '去识别').fontSize($r('app.float.font_size_caption')).fontColor(Color.White)
            }
            .backgroundColor(this.faceVerified ? $r('app.color.success_green') : $r('app.color.primary_orange')).borderRadius(14)
            .onClick(() => this.faceVerified = true)
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

          // ===== 提交按钮 =====
          Button() {
            Text('提交审核').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).margin({ top: 32 })
          .onClick(() => this.submit())
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
