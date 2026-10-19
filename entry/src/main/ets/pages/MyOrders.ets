import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';
import { mockOrderList } from '../common/MockData';
import { OrderInfo, OrderStatus } from '../common/Interfaces';

/**
 * 页面 7：我的订单
 * 【复杂页面】
 */
@Entry
@Component
struct MyOrders {
  @State currentTab: number = 1;
  @State currentStatusIndex: number = 0;

  private statusTabs: string[] = ['全部', '待支付', '已确认', '用车中', '已完成'];

  private getFilteredOrders(): OrderInfo[] {
    if (this.currentStatusIndex === 0) return mockOrderList;
    const statusMap: Record<number, OrderStatus[]> = {
      1: [OrderStatus.PENDING],
      2: [OrderStatus.CONFIRMED],
      3: [OrderStatus.PICKED_UP, OrderStatus.IN_USE, OrderStatus.RETURNED],
      4: [OrderStatus.COMPLETED]
    };
    const target = statusMap[this.currentStatusIndex] || [];
    return mockOrderList.filter((o: OrderInfo) => target.indexOf(o.status) >= 0);
  }

  private goDetail(order: OrderInfo) {
    if (order.status === OrderStatus.IN_USE || order.status === OrderStatus.PICKED_UP) {
      router.pushUrl({ url: 'pages/InUse' });
    } else {
      router.pushUrl({ url: 'pages/OrderDetail?orderId=' + order.id });
    }
  }

  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 1) router.replaceUrl({ url: pages[index] });
  }

  private statusColor(status: OrderStatus): string {
    if (status === OrderStatus.PENDING) return '#FF3B30';
    if (status === OrderStatus.CONFIRMED) return '#FF6B00';
    if (status === OrderStatus.IN_USE || status === OrderStatus.PICKED_UP) return '#34C759';
    return '#8E8E93';
  }

  build() {
    Column() {
      NavBar({ title: '我的订单', showBack: false, onBack: (): void => {}, rightText: '', onRightClick: (): void => {} })

      Row() {
        ForEach(this.statusTabs, (tab: string, idx: number) => {
          Column() {
            Text(tab)
              .fontSize($r('app.float.font_size_body'))
              .fontColor(this.currentStatusIndex === idx ? $r('app.color.primary_orange') : $r('app.color.text_secondary'))
              .fontWeight(this.currentStatusIndex === idx ? FontWeight.Medium : FontWeight.Normal)
            Column().width(24).height(3).backgroundColor(this.currentStatusIndex === idx ? $r('app.color.primary_orange') : Color.Transparent).borderRadius(2).margin({ top: 4 })
          }
          .layoutWeight(1).padding({ top: 12, bottom: 12 })
          .onClick(() => { this.currentStatusIndex = idx; })
        }, (tab: string, idx: number) => `${idx}`)
      }
      .width('100%').backgroundColor(Color.White)

      Scroll() {
        Column() {
          if (this.getFilteredOrders().length === 0) {
            Column() {
              Text('📋').fontSize(60)
              Text('暂无订单').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 12 })
            }
            .width('100%').height(300).justifyContent(FlexAlign.Center)
          } else {
            ForEach(this.getFilteredOrders(), (order: OrderInfo) => {
              this.OrderCard(order)
            }, (order: OrderInfo) => order.id)
          }
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  OrderCard(order: OrderInfo) {
    Column() {
      Row() {
        Text('订单号：' + order.orderNo).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
        Blank()
        Text(order.status).fontSize($r('app.float.font_size_caption')).fontColor(this.statusColor(order.status)).fontWeight(FontWeight.Medium)
      }.width('100%')
      Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
      Row() {
        Text(order.carImage).fontSize(40).width(64).height(64).textAlign(TextAlign.Center).backgroundColor($r('app.color.bg_page')).borderRadius(10)
        Column() {
          Text(order.carName).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
          Text(order.pickupStore + ' → ' + order.returnStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 })
          Text(order.pickupTime + ' ~ ' + order.returnTime).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_hint')).margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
      }.width('100%')
      Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
      Row() {
        Text('共' + order.days + '天').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary'))
        Blank()
        Text('合计 ').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
        Text('¥' + order.totalPrice).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
      }.width('100%')
      Row() {
        Blank()
        Button() {
          if (order.status === OrderStatus.IN_USE || order.status === OrderStatus.PICKED_UP) {
            Text('进入用车').fontSize(12).fontColor(Color.White)
          } else {
            Text('查看详情').fontSize(12).fontColor(Color.White)
          }
        }
          .height(32).backgroundColor($r('app.color.primary_orange')).borderRadius(16)
          .onClick(() => this.goDetail(order))
      }.width('100%').margin({ top: 12 })
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ bottom: 12 })
  }
}
