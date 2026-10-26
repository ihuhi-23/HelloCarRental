import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { mockViolationList } from '../common/MockData';
import { ViolationRecord } from '../common/Interfaces';

/**
 * 页面：违章查询
 * 分工：成员四 · 简单页面
 * 入口：用车中「违章查询」/ 个人中心「违章查询」
 * 功能：车辆号牌与查询时间、违章统计、违章明细
 * 容器：SwiperBanner（内部 Swiper 轮播）、Scroll（页面内容）
 * 说明：数据来自 MockData.mockViolationList，暂无后端接口
 */
@Entry
@Component
struct Violation {
  build() {
    Column() {
      NavBar({ title: '违章查询', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      // 轮播横幅：SwiperBanner（内部为 Swiper）
      SwiperBanner()

      // ===== 页面内容：Scroll 纵向滚动 =====
      Scroll() {
        Column() {
          // ===== 车辆与查询时间 =====
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

          // ===== 违章统计汇总 =====
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

          // ===== 违章详情 =====
          Text('违章详情').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
            .margin({ left: 4, top: 16, bottom: 8 })

          // 违章列表：ForEach 渲染 mockViolationList（本页未使用 List）
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
      .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
