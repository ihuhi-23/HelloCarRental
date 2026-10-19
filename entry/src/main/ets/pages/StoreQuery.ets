import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { mockStoreList } from '../common/MockData';
import { StoreInfo } from '../common/Interfaces';

/**
 * 页面 12：门店查询
 */
@Entry
@Component
struct StoreQuery {
  @State searchText: string = '';

  build() {
    Column() {
      NavBar({ title: '门店查询', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      Row() {
        Text('🔍').fontSize(16).margin({ right: 8 })
        TextInput({ placeholder: '搜索门店名称或地址', text: this.searchText })
          .layoutWeight(1).backgroundColor(Color.Transparent).fontSize($r('app.float.font_size_body'))
          .onChange((v: string) => this.searchText = v)
      }
      .width('100%').height(40).padding({ left: 12, right: 12 })
      .backgroundColor(Color.White).borderRadius(20).margin({ left: 16, right: 16, top: 12 })

      Scroll() {
        Column() {
          Column() {
            Text('🗺️').fontSize(60)
            Text('地图加载中...').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 8 })
          }
          .width('100%').height(200).backgroundColor(Color.White).borderRadius(12).justifyContent(FlexAlign.Center)
          .margin({ left: 16, right: 16, top: 12 })

          Text('附近门店').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
            .margin({ left: 16, top: 16, bottom: 8 })

          ForEach(mockStoreList, (store: StoreInfo) => {
            this.StoreCard(store)
          }, (store: StoreInfo) => store.id)
        }
      }
      .layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  StoreCard(store: StoreInfo) {
    Column() {
      Row() {
        Column() {
          Row() {
            Text('📍 ' + store.name).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
            Text(store.distance).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange')).margin({ left: 8 })
          }
          Text(store.address).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 4 }).maxLines(2)
          Row() {
            Text('🕐 ' + store.hours).fontSize(10).fontColor($r('app.color.text_secondary')).margin({ right: 12 })
            if (store.hasPickup) {
              Text('🚗 可接送').fontSize(10).fontColor($r('app.color.primary_orange')).backgroundColor($r('app.color.primary_orange_light')).padding({ left: 4, right: 4 }).borderRadius(3)
            }
          }.margin({ top: 6 })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Button() { Text('导航').fontSize(12).fontColor($r('app.color.text_primary')) }
          .height(32).backgroundColor(Color.White).border({ width: 1, color: $r('app.color.divider') }).borderRadius(16)
      }.width('100%')
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)
    .margin({ left: 16, right: 16, bottom: 12 })
  }
}
