import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { mockViolationList } from '../common/MockData';
import { ViolationRecord } from '../common/Interfaces';

/**
 * 页面 18：违章查询
 * 注意：后端暂无违章查询 API，当前使用 Mock 数据（mockViolationList）
 */
@Entry
@Component
struct Violation {
  build() {
    Column() {
      NavBar({ title: '违章查询', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      SwiperBanner()

      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('车辆号牌').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary'))
              Blank()
              Text('沪A·12345').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.primary_orange'))
            }.width('100%')
            Row() {
              Text('查询时间').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary'))
              Blank()
              Text('2026-06-01 至 2026-10-18').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_primary'))
            }.width('100%').margin({ top: 8 })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Row() {
            Column() {
              Text(mockViolationList.length.toString()).fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
              Text('违章总数').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column() {
              Text((mockViolationList.reduce((s: number, v: ViolationRecord) => s + v.fine, 0)).toString())
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.warning_red'))
              Text('罚款金额').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column() {
              Text((mockViolationList.reduce((s: number, v: ViolationRecord) => s + v.points, 0)).toString())
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
              Text('扣分合计').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Text('违章详情').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
            .margin({ left: 4, top: 16, bottom: 8 })

          ForEach(mockViolationList, (v: ViolationRecord) => {
            Column() {
              Row() {
                Text(v.time).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).layoutWeight(1)
                Text(v.status).fontSize($r('app.float.font_size_small'))
                  .fontColor(v.status === '待处理' ? $r('app.color.warning_red') : $r('app.color.text_secondary'))
              }.width('100%')
              Row() {
                Text(v.reason).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
              }.width('100%').margin({ top: 6 })
              Row() {
                Text('📍 ' + v.location).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).layoutWeight(1)
                Text('扣' + v.points + '分').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.primary_orange')).margin({ right: 12 })
                Text('¥' + v.fine).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
              }.width('100%').margin({ top: 6 })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ bottom: 8 })
          }, (v: ViolationRecord) => v.id)
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
