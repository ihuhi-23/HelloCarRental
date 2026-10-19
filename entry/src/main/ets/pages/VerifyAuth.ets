import router from '@ohos.router';
import { NavBar } from '../common/NavBar';

/**
 * 页面 11：实名认证
 */
@Entry
@Component
struct VerifyAuth {
  @State name: string = '';
  @State idCard: string = '';
  @State faceVerified: boolean = false;

  private submit() { router.replaceUrl({ url: 'pages/Index' }); }

  build() {
    Column() {
      NavBar({ title: '实名认证', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      Scroll() {
        Column() {
          Row() {
            Text('🛡️').fontSize(20)
            Text('为了保障您的用车安全，请完成实名认证').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ left: 8 }).layoutWeight(1)
          }
          .width('100%').padding(12).backgroundColor($r('app.color.primary_orange_light')).borderRadius(8).margin({ top: 12 })

          Column() {
            TextInput({ placeholder: '请输入真实姓名', text: this.name })
              .width('100%').fontSize($r('app.float.font_size_body')).onChange((v: string) => this.name = v)
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(10).margin({ top: 16 })

          Column() {
            TextInput({ placeholder: '请输入身份证号码', text: this.idCard })
              .width('100%').fontSize($r('app.float.font_size_body')).type(InputType.Number).onChange((v: string) => this.idCard = v)
            Divider().color($r('app.color.divider')).margin({ top: 8 })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(10).margin({ top: 12 })

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

          Button() {
            Text('提交审核').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).margin({ top: 32 })
          .onClick(() => this.submit())
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
