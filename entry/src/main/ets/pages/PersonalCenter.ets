import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';
import { mockUserInfo } from '../common/MockData';
import { UserInfo } from '../common/Interfaces';

/**
 * 页面 14：个人中心
 */
@Entry
@Component
struct PersonalCenter {
  @State currentTab: number = 3;
  @State userInfo: UserInfo = mockUserInfo;

  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 3) router.replaceUrl({ url: pages[index] });
  }

  private goPage(url: string) { router.pushUrl({ url: url }); }

  build() {
    Column() {
      Column() {
        Row() {
          Text(this.userInfo.avatar).fontSize(48).width(64).height(64).textAlign(TextAlign.Center).backgroundColor(Color.White).borderRadius(32)
          Column() {
            Row() {
              Text(this.userInfo.name).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)
              Text(this.userInfo.memberLevel).fontSize(10).fontColor($r('app.color.primary_orange')).backgroundColor(Color.White).padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4).margin({ left: 8 })
            }
            Text(this.userInfo.phone).fontSize($r('app.float.font_size_caption')).fontColor('#CCFFFFFF').margin({ top: 4 })
            Row() {
              if (this.userInfo.verified) {
                Text('✓ 已实名').fontSize(10).fontColor($r('app.color.success_green')).backgroundColor('#33FFFFFF').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
              }
              Text('积分 ' + this.userInfo.points).fontSize(10).fontColor('#CCFFFFFF').margin({ left: 12 })
            }.margin({ top: 6 })
          }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 16 })
          Text('›').fontSize(20).fontColor('#99FFFFFF')
        }.width('100%')
      }
      .width('100%').padding(20)
      .linearGradient({ angle: 180, colors: [['#FF6B00', 0], ['#FF8F3D', 1]] })

      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('我的订单').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
              Blank()
              Text('查看全部').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary'))
              Text('›').fontSize(14).fontColor($r('app.color.text_secondary')).margin({ left: 4 })
            }.width('100%').onClick(() => { router.pushUrl({ url: 'pages/MyOrders' }); })
            Row() {
              this.OrderEntry('💳', '待支付', (): void => { router.pushUrl({ url: 'pages/MyOrders' }); })
              this.OrderEntry('📝', '已确认', (): void => { router.pushUrl({ url: 'pages/MyOrders' }); })
              this.OrderEntry('🚗', '用车中', (): void => { router.pushUrl({ url: 'pages/InUse' }); })
              this.OrderEntry('✅', '已完成', (): void => { router.pushUrl({ url: 'pages/MyOrders' }); })
            }.width('100%').margin({ top: 12 })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Column() {
            this.MenuRow('🎟️', '优惠券', '3张可用', (): void => {})
            this.MenuRow('🪪', '我的驾照', '', (): void => this.goPage('pages/VerifyAuth'))
            this.MenuRow('📍', '门店查询', '', (): void => this.goPage('pages/StoreQuery'))
            this.MenuRow('🚨', '违章查询', '', (): void => this.goPage('pages/Violation'))
            this.MenuRow('💳', '支付方式', '', (): void => {})
            this.MenuRow('🎁', '邀请有礼', '得¥100券', (): void => {})
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Column() {
            this.MenuRow('⚙️', '设置', '', (): void => {})
            this.MenuRow('❓', '帮助中心', '', (): void => {})
            this.MenuRow('ℹ️', '关于我们', 'v1.0.0', (): void => {})
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          Column() {
            Row() {
              Text('退出登录').fontSize($r('app.float.font_size_body')).fontColor('#FF3B30').layoutWeight(1).textAlign(TextAlign.Center)
            }.width('100%').padding({ top: 12, bottom: 12 }).onClick(() => { router.replaceUrl({ url: 'pages/Login' }); })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
        }
        .padding(16).padding({ bottom: 120 })
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  OrderEntry(icon: string, label: string, onClick: () => void) {
    Column() {
      Text(icon).fontSize(28).margin({ bottom: 4 })
      Text(label).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center).onClick(() => onClick())
  }

  @Builder
  MenuRow(icon: string, label: string, extra: string, onClick: () => void) {
    Row() {
      Text(icon).fontSize(20).margin({ right: 12 })
      Text(label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
      if (extra) Text(extra).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ right: 8 })
      Text('›').fontSize(16).fontColor($r('app.color.text_secondary'))
    }
    .width('100%').padding({ top: 10, bottom: 10 }).onClick(() => onClick())
  }
}
