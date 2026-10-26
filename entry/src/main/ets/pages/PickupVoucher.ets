import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { OrderInfo, InfoRow } from '../common/Interfaces';
import { fetchOrderDetail, fetchOrders } from '../common/HttpUtil';

/**
 * 页面：PickupVoucher 取车凭证
 * 分工：成员一 · 简单页面
 * 入口：PaymentSuccess 支付成功后「查看取车凭证」
 * 功能：二维码凭证、车辆与订单信息、取车提示、我的订单入口
 * 容器：List（取车信息列表）、Scroll（页面滚动）
 * 关键状态：order（当前订单）、isLoading（加载中）
 * 关键方法：loadData() 调用 HttpUtil.fetchOrderDetail()/fetchOrders()、goOrders() 进入 MyOrders
 */
@Entry
@Component
struct PickupVoucher {
  @State order: OrderInfo | null = null;
  @State isLoading: boolean = true;

  // 作用：页面创建时加载取车凭证所需订单数据
  aboutToAppear() {
    this.loadData();
  }

  // 作用：按 orderId 调用 HttpUtil.fetchOrderDetail()，取不到时回退到 fetchOrders() 的已确认订单
  private async loadData() {
    try {
      const params = router.getParams() as Record<string, string>;
      const orderId = params ? params['orderId'] : '';
      if (orderId) {
        this.order = await fetchOrderDetail(orderId);
      }
      if (!this.order) {
        const all = await fetchOrders();
        this.order = all.find((o) => o.status === '已确认') || all[0] || null;
      }
    } catch (e) {
      console.error('Load voucher failed');
    } finally {
      this.isLoading = false;
    }
  }

  // 作用：跳转到 MyOrders 我的订单页
  private goOrders() { router.replaceUrl({ url: 'pages/MyOrders' }); }

  // 作用：把订单的门店、时间、天数、金额组装成展示行
  private getInfoRows(): InfoRow[] {
    const info: OrderInfo | null = this.order;
    if (!info) return [];
    const rows: InfoRow[] = [
      { label: '取车门店', value: info.pickupStore },
      { label: '还车门店', value: info.returnStore },
      { label: '取车时间', value: info.pickupTime },
      { label: '还车时间', value: info.returnTime },
      { label: '租车天数', value: info.days + '天' },
      { label: '订单金额', value: '¥' + info.totalPrice }
    ];
    return rows;
  }

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      NavBar({ title: '取车凭证', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      // ===== 加载中 / 凭证内容两种状态 =====
      if (this.isLoading || !this.order) {
        Column() {
          Text('⏳').fontSize(48)
          Text('加载中...').fontSize(14).fontColor('#909399').margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        // ===== 凭证内容滚动区 =====
        Scroll() {
          Column() {
            // ===== 凭证卡：车辆、订单号与二维码 =====
            Column() {
              Row() {
                Image(this.order.carImage).width(64).height(64).objectFit(ImageFit.Cover).borderRadius(12)
                Column() {
                  Text(this.order.carName).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor(Color.White)
                  Text('订单号 ' + this.order.orderNo).fontSize($r('app.float.font_size_small')).fontColor('#99FFFFFF').margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }.width('100%')
              Divider().color('#33FFFFFF').margin({ top: 16, bottom: 16 })
              Column() {
                Text('📱').fontSize(80)
                Text('出示此二维码即可取车').fontSize($r('app.float.font_size_caption')).fontColor('#99FFFFFF').margin({ top: 12 })
              }.margin({ top: 12 })
            }
            .width('100%').padding(20)
            .linearGradient({ angle: 180, colors: [['#FF6B00', 0], ['#FF8F3D', 1]] })
            .borderRadius(16).margin({ top: 12 })

            Column() {
              Text('取车信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 16 })
              // ===== 取车信息列表：List + ListItem + ForEach =====
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

            // ===== 温馨提示 =====
            Column() {
              Text('温馨提示').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 8 })
              Text('• 请携带本人身份证和驾驶证原件').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
              Text('• 如代取车需提前告知门店').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
              Text('• 建议提前10分钟到达门店').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
          }
          .padding(16)
        }
        .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

        // ===== 底部「我的订单」按钮 =====
        Button() {
          Text('我的订单').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
        }
        .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24)
        .margin({ left: 16, right: 16, top: 12, bottom: 12 }).onClick(() => this.goOrders())
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
