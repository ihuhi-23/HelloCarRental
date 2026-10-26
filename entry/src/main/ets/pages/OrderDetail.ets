import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { OrderInfo, OrderStatus, InfoRow } from '../common/Interfaces';
import { fetchOrderDetail } from '../common/HttpUtil';

/**
 * 页面：订单详情
 * 分工：成员四 · 简单页面
 * 入口：我的订单 → 订单详情
 * 功能：车辆信息、取还车信息、费用明细、支付/结算入口
 * 容器：Scroll（整页内容）、List（取还车信息）
 * 关键状态：order（订单数据）、isLoading（加载中）
 * 关键方法：loadOrder() 调用 HttpUtil.fetchOrderDetail()、goPay()/goFee() 路由跳转
 */
@Entry
@Component
struct OrderDetail {
  @State order: OrderInfo | null = null;
  @State isLoading: boolean = true;

  // 作用：页面加载时请求订单详情
  aboutToAppear() {
    this.loadOrder();
  }

  // 作用：读取路由参数 orderId，调用 HttpUtil.fetchOrderDetail() 获取订单
  private async loadOrder() {
    try {
      const params = router.getParams() as Record<string, string>;
      const orderId = params ? params['orderId'] : '';
      if (orderId) {
        const result = await fetchOrderDetail(orderId);
        if (result) this.order = result;
      }
    } catch (e) {
      console.error('Load order detail failed');
    } finally {
      this.isLoading = false;
    }
  }

  // 作用：跳转支付页 Payment，携带 orderId、orderNo、amount
  private goPay() {
    if (!this.order) return;
    router.pushUrl({
      url: 'pages/Payment',
      params: { orderId: this.order.id, orderNo: this.order.orderNo, amount: String(this.order.totalPrice) }
    });
  }

  // 作用：跳转费用结算页 FeeSettlement，携带 orderId
  private goFee() {
    if (!this.order) return;
    router.pushUrl({ url: 'pages/FeeSettlement', params: { orderId: this.order.id } });
  }

  // 作用：组装取还车信息行，供 List 渲染
  private getOrderInfoRows(): InfoRow[] {
    const info: OrderInfo | null = this.order;
    if (!info) return [];
    const rows: InfoRow[] = [
      { label: '取车门店', value: info.pickupStore },
      { label: '取车时间', value: info.pickupTime },
      { label: '还车门店', value: info.returnStore },
      { label: '还车时间', value: info.returnTime }
    ];
    return rows;
  }

  build() {
    Column() {
      NavBar({ title: '订单详情', onBack: (): void => { router.back(); }, rightText: '客服', onRightClick: (): void => { router.pushUrl({ url: "pages/AIChat" }); } })

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
            // ===== 订单状态卡片 =====
            Column() {
              Text('📦').fontSize(36)
              Text(this.order.status).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).margin({ top: 8 })
              Text('订单号：' + this.order.orderNo).fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            }
            .width('100%').padding(20).backgroundColor(Color.White).borderRadius(12).alignItems(HorizontalAlign.Center).margin({ top: 12 })

            // ===== 车辆信息 =====
            Column() {
              Text('车辆信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              Row() {
                Image(this.order.carImage).width(56).height(56).objectFit(ImageFit.Cover).borderRadius(10)
                Column() {
                  Text(this.order.carName).fontSize($r('app.float.font_size_subtitle')).fontColor($r('app.color.text_primary')).fontWeight(FontWeight.Medium)
                  Text('¥' + (this.order.totalPrice / this.order.days).toFixed(0) + '/天 · ' + this.order.days + '天').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 取还车信息 =====
            Column() {
              Text('取还车信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              // 取还车信息列表：List + ForEach 渲染 InfoRow
              List() {
                ForEach(this.getOrderInfoRows(), (row: InfoRow) => {
                  ListItem() {
                    Row() {
                      Text(row.label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(80)
                      Text(row.value).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
                    }
                    .width('100%').padding({ top: 6, bottom: 6 })
                  }
                }, (row: InfoRow): string => row.label)
              }
              .width('100%').scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.None)
              .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 费用明细 =====
            Column() {
              Text('费用明细').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              this.InfoLine('租车费用', '¥' + (this.order.totalPrice + (this.order.discount || 0)))
              if (this.order.discount) this.InfoLine('优惠券', '-¥' + this.order.discount)
              if (this.order.insurance) this.InfoLine('保险费用', '¥' + this.order.insurance)
              Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
              Row() {
                Text('合计').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                Blank()
                Text('¥' + this.order.totalPrice).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
          }
          .padding(16).padding({ bottom: 100 })
        }
        .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

        // ===== 底部操作按钮 =====
        Row() {
          Button() { Text('联系客服').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')) }
            .layoutWeight(1).height(44).backgroundColor(Color.White).border({ width: 1, color: $r('app.color.divider') }).borderRadius(22).margin({ right: 12 })
          Button() {
            Text(this.order.status === OrderStatus.PENDING ? '立即支付' : '还车结算').fontSize($r('app.float.font_size_body')).fontColor(Color.White)
          }
          .layoutWeight(1).height(44).backgroundColor($r('app.color.primary_orange')).borderRadius(22)
          .onClick(() => { if (this.order && this.order.status === OrderStatus.PENDING) this.goPay(); else this.goFee(); })
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor(Color.White)
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // 作用：费用明细单行（名称 + 金额）
  @Builder
  InfoLine(label: string, value: string) {
    Row() {
      Text(label).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(80)
      Text(value).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).layoutWeight(1)
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }
}
