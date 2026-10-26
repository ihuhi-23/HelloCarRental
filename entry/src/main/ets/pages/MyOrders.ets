import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';
import { OrderInfo, OrderStatus } from '../common/Interfaces';
import { fetchOrders } from '../common/HttpUtil';

/**
 * 页面：MyOrders 我的订单
 * 分工：成员四 · 复杂页面
 * 入口：底部 TabBar「订单」/ PaymentSuccess、PickupVoucher 跳转
 * 功能：订单状态分类筛选、订单卡片列表、跳转订单详情 / 用车页
 * 容器：List（订单列表）、ForEach（状态 Tab、订单卡片）
 * 关键状态：orders（订单列表）、currentStatusIndex（状态筛选）、currentTab（底部 Tab 索引）
 * 关键方法：loadOrders() 调用 HttpUtil.fetchOrders()、goDetail() 按状态跳转 InUse 或 OrderDetail
 */
@Entry
@Component
struct MyOrders {
  @State currentTab: number = 1;
  @State currentStatusIndex: number = 0;
  @State orders: OrderInfo[] = [];

  private statusTabs: string[] = ['全部', '待支付', '已确认', '用车中', '已完成'];

  // 作用：页面创建时拉取订单列表
  aboutToAppear() {
    this.loadOrders();
  }

  // 作用：每次页面显示都重新拉取，保证下单/支付后返回能立刻看到新订单
  onPageShow() {
    this.loadOrders();
  }

  // 作用：调用 HttpUtil.fetchOrders() 拉取订单列表
  private async loadOrders() {
    try {
      this.orders = await fetchOrders();
    } catch (e) {
      console.error('Load orders failed');
    }
  }

  // 作用：按当前状态 Tab 过滤订单，「全部」时直接返回原列表
  private getFilteredOrders(): OrderInfo[] {
    if (this.currentStatusIndex === 0) return this.orders;
    const statusMap: Record<number, OrderStatus[]> = {
      1: [OrderStatus.PENDING],
      2: [OrderStatus.CONFIRMED],
      3: [OrderStatus.PICKED_UP, OrderStatus.IN_USE, OrderStatus.RETURNED],
      4: [OrderStatus.COMPLETED]
    };
    const target = statusMap[this.currentStatusIndex] || [];
    return this.orders.filter((o: OrderInfo) => target.indexOf(o.status) >= 0);
  }

  // 作用：用车中/已取车跳转 InUse，其他状态跳转 OrderDetail，均传 orderId
  private goDetail(order: OrderInfo) {
    if (order.status === OrderStatus.IN_USE || order.status === OrderStatus.PICKED_UP) {
      router.pushUrl({ url: 'pages/InUse', params: { orderId: order.id } })
        .catch((err: Error) => { promptAction.showToast({ message: '跳转失败: ' + err.message, duration: 2000 }); });
    } else {
      router.pushUrl({ url: 'pages/OrderDetail', params: { orderId: order.id } })
        .catch((err: Error) => { promptAction.showToast({ message: '跳转失败: ' + err.message, duration: 2000 }); });
    }
  }

  // 作用：底部 Tab 切换，非订单页时用 replaceUrl 跳转到对应页面
  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 1) router.replaceUrl({ url: pages[index] });
  }

  // 作用：按订单状态返回对应的文字颜色
  private statusColor(status: OrderStatus): string {
    if (status === OrderStatus.PENDING) return '#FF3B30';
    if (status === OrderStatus.CONFIRMED) return '#FF6B00';
    if (status === OrderStatus.IN_USE || status === OrderStatus.PICKED_UP) return '#34C759';
    return '#8E8E93';
  }

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      NavBar({ title: '我的订单', showBack: false, onBack: (): void => {}, rightText: '', onRightClick: (): void => {} })

      // ===== 状态筛选 Tab：ForEach 渲染 =====
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

      // ===== 订单列表：List + ListItem + ForEach，无订单时显示占位 =====
      List() {
        if (this.getFilteredOrders().length === 0) {
          ListItem() {
            Column() {
              Text('📋').fontSize(60)
              Text('暂无订单').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 12 })
            }
            .width('100%').height(300).justifyContent(FlexAlign.Center)
          }
          .width('100%')
        } else {
          ForEach(this.getFilteredOrders(), (order: OrderInfo) => {
            ListItem() {
              this.OrderCard(order)
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .onClick(() => { this.goDetail(order); })
          }, (order: OrderInfo): string => order.id)
        }
      }
      .width('100%').layoutWeight(1).scrollBar(BarState.Off)

      // ===== 底部 TabBar =====
      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // 作用：订单卡片，展示订单号、状态、车辆、门店、时间和金额
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
        Image(order.carImage).width(64).height(64).objectFit(ImageFit.Cover).borderRadius(10)
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
        Row() {
          Text(order.status === OrderStatus.IN_USE || order.status === OrderStatus.PICKED_UP ? '进入用车' : '查看详情')
            .fontSize(12).fontColor(Color.White)
        }
        .height(32).padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.primary_orange')).borderRadius(16)
      }.width('100%').margin({ top: 12 })
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ bottom: 12 })
  }
}
