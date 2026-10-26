import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { OrderInfo, InfoRow } from '../common/Interfaces';
import { fetchOrderDetail } from '../common/HttpUtil';

/**
 * 页面：PaymentSuccess 支付成功
 * 分工：成员三 · 简单页面
 * 入口：Payment 支付完成后跳转；还车结算时 from='return'
 * 功能：成功图标、金额、订单信息、查看订单 / 取车凭证
 * 容器：List（订单信息列表）
 * 关键状态：from（booking/return 场景）、order（订单详情）
 * 关键方法：loadOrder() 调用 HttpUtil.fetchOrderDetail()、goVoucher() 进入 PickupVoucher、goOrders() 进入 MyOrders
 */
@Entry
@Component
struct PaymentSuccess {
  @State orderId: string = '';
  @State orderNo: string = '';
  @State amount: number = 0;
  @State from: string = 'booking';
  @State order: OrderInfo | null = null;
  @State isLoading: boolean = true;

  // 作用：读取路由参数（orderId/orderNo/amount/from）并加载订单
  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.orderId = params['orderId'] || '';
      this.orderNo = params['orderNo'] || '';
      this.amount = Number(params['amount'] || 0);
      this.from = params['from'] || 'booking';
    }
    this.loadOrder();
  }

  // 作用：调用 HttpUtil.fetchOrderDetail() 获取订单号等展示信息
  private async loadOrder() {
    try {
      if (this.orderId) {
        this.order = await fetchOrderDetail(this.orderId);
        if (this.order) {
          this.orderNo = this.order.orderNo;
        }
      }
    } catch (e) {
      console.error('Load paid order failed');
    } finally {
      this.isLoading = false;
    }
  }

  // 作用：判断是否还车结算流程（from === 'return'）
  private isReturnFlow(): boolean { return this.from === 'return'; }

  // 作用：组装订单号、取车门店、取车时间三行展示信息
  private getInfoRows(): InfoRow[] {
    const rows: InfoRow[] = [
      { label: '订单号', value: this.isLoading ? '加载中…' : (this.orderNo || '—') },
      { label: '取车门店', value: this.order ? this.order.pickupStore : '—' },
      { label: '取车时间', value: this.order ? this.order.pickupTime : '—' }
    ];
    return rows;
  }

  // 作用：跳转到 PickupVoucher 取车凭证页，传 orderId 参数
  private goVoucher() {
    router.replaceUrl({ url: 'pages/PickupVoucher', params: { orderId: this.orderId } });
  }
  // 作用：跳转到 Index 首页
  private goHome() { router.replaceUrl({ url: 'pages/Index' }); }
  // 作用：跳转到 MyOrders 我的订单页
  private goOrders() { router.replaceUrl({ url: 'pages/MyOrders' }); }

  build() {
    Column() {
      // ===== 顶部导航栏（无返回键） =====
      NavBar({ title: this.isReturnFlow() ? '结算成功' : '支付成功', showBack: false, onBack: (): void => {}, rightText: '', onRightClick: (): void => {} })

      // ===== 支付结果内容区 =====
      Column() {
        // ===== 成功图标与金额 =====
        Column() { Text('✓').fontSize(40).fontWeight(FontWeight.Bold).fontColor($r('app.color.success_green')) }
          .width(80).height(80).backgroundColor($r('app.color.success_bg')).borderRadius(40).justifyContent(FlexAlign.Center).margin({ top: 40 })

        Text(this.isReturnFlow() ? '还车费用已结清' : '支付成功')
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 20 })
        Text('¥' + this.amount).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 8 })
        Text(this.isReturnFlow() ? '感谢使用，本次租车服务已完成' : '订单已确认，请按时前往门店取车')
          .fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).margin({ top: 16 })

        Column() {
          // ===== 订单信息列表：List + ListItem + ForEach =====
          List() {
            ForEach(this.getInfoRows(), (row: InfoRow) => {
              ListItem() {
                Row() {
                  Text(row.label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary'))
                  Text(row.value).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1).textAlign(TextAlign.End)
                }
                .width('100%').padding({ top: 10, bottom: 10 })
              }
            }, (row: InfoRow): string => row.label)
          }
          .width('100%').scrollBar(BarState.Off)
        }
        .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 24 })

        Blank()

        // ===== 底部操作按钮：查看订单 / 查看取车凭证 =====
        Row() {
          Button() { Text('查看订单').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')) }
            .layoutWeight(1).height(44).backgroundColor(Color.White).border({ width: 1, color: $r('app.color.divider') }).borderRadius(22).margin({ right: 12 })
            .onClick(() => { this.goOrders(); })
          Button() { Text(this.isReturnFlow() ? '返回首页' : '查看取车凭证').fontSize($r('app.float.font_size_body')).fontColor(Color.White) }
            .layoutWeight(1).height(44).backgroundColor($r('app.color.primary_orange')).borderRadius(22)
            .onClick(() => { if (this.isReturnFlow()) { this.goHome(); } else { this.goVoucher(); } })
        }
        .width('100%').margin({ bottom: 24 })
      }
      .layoutWeight(1).padding(24).width('100%')
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
