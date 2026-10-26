import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';
import { OrderInfo, OrderStatus, InfoRow } from '../common/Interfaces';
import { fetchOrders, fetchOrderDetail } from '../common/HttpUtil';

/**
 * 页面：用车中
 * 分工：成员六 · 简单页面
 * 入口：我的订单「用车中」/ 个人中心「用车中」
 * 功能：进行中订单信息、快捷功能、用车服务、还车入口
 * 容器：Scroll（整页内容）、List（用车信息）
 * 关键状态：order（当前订单）、isLoading（加载中）
 * 关键方法：loadInUseOrder() 调用 HttpUtil.fetchOrderDetail()/fetchOrders()、goReturn() 跳转 ReturnConfirm
 */
@Entry
@Component
struct InUse {
  @State currentTab: number = 3;
  @State order: OrderInfo | null = null;
  @State isLoading: boolean = true;

  // 作用：页面加载时获取进行中的订单
  aboutToAppear() {
    this.loadInUseOrder();
  }

  // 作用：优先按路由 orderId 调用 HttpUtil.fetchOrderDetail()，否则调用 HttpUtil.fetchOrders() 找 IN_USE 订单
  private async loadInUseOrder() {
    try {
      // 优先从路由参数取 orderId
      const params = router.getParams() as Record<string, string>;
      const orderId = params ? params['orderId'] : '';
      if (orderId) {
        this.order = await fetchOrderDetail(orderId);
      }
      // 没有 orderId 或加载失败，fallback 找 IN_USE 订单
      if (!this.order) {
        let all = await fetchOrders();
        this.order = all.find((o: OrderInfo) => o.status === OrderStatus.IN_USE) || all[0] || null;
      }
    } catch (e) {
      console.error('Load in-use order failed');
    } finally {
      this.isLoading = false;
    }
  }

  // 作用：底部 Tab 切换，非本页时 replaceUrl 到目标页
  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 3) router.replaceUrl({ url: pages[index] });
  }

  // 作用：跳转还车确认页 ReturnConfirm，携带 orderId
  private goReturn() {
    promptAction.showToast({ message: '跳转还车确认', duration: 800 });
    if (this.order) {
      router.pushUrl({ url: 'pages/ReturnConfirm', params: { orderId: this.order.id } });
    } else {
      router.pushUrl({ url: 'pages/ReturnConfirm' });
    }
  }
  // 作用：跳转违章查询页 Violation
  private goViolation() { router.pushUrl({ url: 'pages/Violation' }); }

  // 作用：组装用车信息行，供 List 渲染
  private getInfoRows(): InfoRow[] {
    const info: OrderInfo | null = this.order;
    if (!info) return [];
    const rows: InfoRow[] = [
      { label: '取车门店', value: info.pickupStore },
      { label: '还车门店', value: info.returnStore },
      { label: '取车时间', value: info.pickupTime },
      { label: '预计还车', value: info.returnTime },
      { label: '租车天数', value: info.days + '天' },
      { label: '订单金额', value: '¥' + info.totalPrice }
    ];
    return rows;
  }

  build() {
    Column() {
      NavBar({ title: '用车中', showBack: false, onBack: (): void => {}, rightText: '客服', onRightClick: (): void => { router.pushUrl({ url: "pages/AIChat" }); } })

      // ===== 加载中占位 =====
      if (this.isLoading || !this.order) {
        Column() {
          Text('⏳').fontSize(48)
          Text('加载中...').fontSize(14).fontColor('#909399').margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          // ===== 主内容区：Scroll 纵向滚动 =====
          Column() {
            // ===== 车辆卡片 =====
            Column() {
              Image(this.order.carImage).width(80).height(80).objectFit(ImageFit.Cover).borderRadius(12)
              Text(this.order.carName).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 12 })
              Text('订单号：' + this.order.orderNo).fontSize($r('app.float.font_size_small')).fontColor('#99FFFFFF').margin({ top: 4 })
              Row() {
                Column() {
                  Text('取车时间').fontSize(10).fontColor('#99FFFFFF')
                  Text(this.order.pickupTime).fontSize($r('app.float.font_size_caption')).fontColor(Color.White).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Column() {
                  Text('预计还车').fontSize(10).fontColor('#99FFFFFF')
                  Text(this.order.returnTime).fontSize($r('app.float.font_size_caption')).fontColor(Color.White).margin({ top: 4 })
                }.alignItems(HorizontalAlign.End)
              }
              .width('100%').margin({ top: 16 })
            }
            .width('100%').padding(20)
            .linearGradient({ angle: 180, colors: [['#34C759', 0], ['#5ED87A', 1]] })
            .borderRadius(16).alignItems(HorizontalAlign.Center).margin({ top: 12 })

            // ===== 用车信息 =====
            Column() {
              Text('用车信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 8 })
              // 用车信息列表：List + ForEach 渲染 InfoRow
              List() {
                ForEach(this.getInfoRows(), (row: InfoRow) => {
                  ListItem() {
                    Row() {
                      Text(row.label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(80)
                      Text(row.value).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
                    }
                    .width('100%').padding({ top: 8, bottom: 8 })
                  }
                }, (row: InfoRow): string => row.label)
              }
              .width('100%').scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.None)
              .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 快捷功能 =====
            Column() {
              Text('快捷功能').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              Row() {
                Column() { this.FuncItem('📍', '车辆定位') }.layoutWeight(1).justifyContent(FlexAlign.Center)
                Column() { this.FuncItem('🔑', '远程锁车') }.layoutWeight(1).justifyContent(FlexAlign.Center)
                Column() { this.FuncItem('🚨', '紧急求助') }.layoutWeight(1).justifyContent(FlexAlign.Center)
                Column() { this.FuncItem('☎️', '联系门店') }.layoutWeight(1).justifyContent(FlexAlign.Center)
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 用车服务 =====
            Column() {
              Text('用车服务').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 8 })
              this.ServiceRow('📋', '违章查询', (): void => this.goViolation())
              this.ServiceRow('🔧', '道路救援', (): void => {})
              this.ServiceRow('⛽', '加油记录', (): void => {})
              this.ServiceRow('📷', '拍照记录车况', (): void => {})
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
          }
          .padding(16).padding({ bottom: 120 })
        }
        .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

        // ===== 底部还车按钮 =====
        Button() {
          Text('我要还车').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
        }
        .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24)
        .margin({ left: 16, right: 16, top: 8, bottom: 8 }).onClick(() => this.goReturn())
      }

      // 底部 TabBar
      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // 作用：快捷功能图标项（图标 + 文字）
  @Builder
  FuncItem(icon: string, label: string) {
    Column() {
      Text(icon).fontSize(28).width(48).height(48).textAlign(TextAlign.Center).backgroundColor($r('app.color.bg_page')).borderRadius(24)
      Text(label).fontSize(11).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  // 作用：用车服务列表行（图标 + 名称 + 箭头）
  @Builder
  ServiceRow(icon: string, label: string, onClick: () => void) {
    Row() {
      Text(icon).fontSize(20).margin({ right: 12 })
      Text(label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
      Text('›').fontSize(16).fontColor($r('app.color.text_secondary'))
    }
    .width('100%').padding({ top: 10, bottom: 10 }).onClick(() => onClick())
  }
}
