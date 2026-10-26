import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NavBar } from '../common/NavBar';
import { OrderInfo, InfoRow } from '../common/Interfaces';
import { fetchOrderDetail, fetchOrders, fetchStores, updateOrderStatus } from '../common/HttpUtil';

/**
 * 页面：还车确认
 * 分工：成员三 · 简单页面
 * 入口：用车中「我要还车」
 * 功能：确认还车门店、还车时间、车辆损伤、协议勾选
 * 容器：Scroll（整页内容）、List（还车信息）
 * 关键状态：selectedStore、selectedTime、hasDamage、agree（协议勾选）
 * 关键方法：loadData() 调用 HttpUtil.fetchOrderDetail()/fetchOrders()/fetchStores()、goFee() 调用 HttpUtil.updateOrderStatus() 后跳转 FeeSettlement
 */
@Entry
@Component
struct ReturnConfirm {
  @State order: OrderInfo | null = null;
  @State selectedStore: string = '';
  @State selectedTime: string = '';
  @State hasDamage: boolean = false;
  @State agree: boolean = false;
  @State storeNames: string[] = [];
  @State isLoading: boolean = true;

  // 作用：页面加载时获取订单和门店列表
  aboutToAppear() {
    this.loadData();
  }

  // 作用：读取订单与门店，初始化还车门店和还车时间
  private async loadData() {
    try {
      const params = router.getParams() as Record<string, string>;
      const orderId = params ? params['orderId'] : '';
      if (orderId) {
        this.order = await fetchOrderDetail(orderId);
      }
      if (!this.order) {
        // fallback: 找第一个订单
        const all = await fetchOrders();
        this.order = all[0] || null;
      }

      // 加载门店列表
      const stores = await fetchStores();
      this.storeNames = stores.map((s) => s.name);
      if (this.storeNames.length > 0) this.selectedStore = this.storeNames[0];

      if (this.order) {
        this.selectedTime = this.order.returnTime;
      }
    } catch (e) {
      console.error('Load return confirm data failed');
    } finally {
      this.isLoading = false;
    }
  }

  private times: string[] = ['2026-10-23 10:00', '2026-10-23 14:00', '2026-10-23 18:00', '2026-10-24 10:00'];

  // 作用：组装还车信息行，供 List 渲染
  private getInfoRows(): InfoRow[] {
    const info: OrderInfo | null = this.order;
    if (!info) return [];
    const rows: InfoRow[] = [
      { label: '取车门店', value: info.pickupStore },
      { label: '还车门店', value: this.selectedStore || info.returnStore },
      { label: '取车时间', value: info.pickupTime },
      { label: '还车时间', value: this.selectedTime || info.returnTime },
      { label: '租车天数', value: info.days + '天' },
      { label: '订单金额', value: '¥' + info.totalPrice }
    ];
    return rows;
  }

  // 作用：调用 HttpUtil.updateOrderStatus() 标记已还车，再跳转 FeeSettlement
  private goFee() {
    if (!this.order) {
      promptAction.showToast({ message: '订单信息加载失败，请稍后重试' });
      return;
    }
    // 确认还车后先把订单状态改为已还车，再进入费用结算
    updateOrderStatus(this.order.id, 'RETURNED').then((ok: boolean) => {
      if (!ok) {
        promptAction.showToast({ message: '还车状态更新失败，请检查后端服务' });
        return;
      }
      router.pushUrl({ url: 'pages/FeeSettlement', params: { orderId: this.order?.id || '' } });
    });
  }

  build() {
    Column() {
      NavBar({ title: '还车确认', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

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
              Row() {
                Image(this.order.carImage).width(64).height(64).objectFit(ImageFit.Cover).borderRadius(10)
                Column() {
                  Text(this.order.carName).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                  Text('取车：' + this.order.pickupStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                  Text(this.order.pickupTime + ' ~ ' + this.order.returnTime).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.primary_orange')).margin({ top: 2 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 还车信息 =====
            Column() {
              Text('还车信息').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 8 })
              // 还车信息列表：List + ForEach 渲染 InfoRow
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

            // ===== 选择还车门店 =====
            Column() {
              Text('选择还车门店').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              ForEach(this.storeNames, (s: string) => {
                Row() {
                  Text('📍 ' + s).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                  Blank()
                  if (this.selectedStore === s) Text('✓').fontSize(16).fontColor($r('app.color.primary_orange'))
                }
                .width('100%').padding({ top: 10, bottom: 10 })
                .onClick(() => this.selectedStore = s)
              }, (s: string) => s)
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 选择还车时间 =====
            Column() {
              Text('选择还车时间').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.times, (t: string) => {
                  Text(t)
                    .fontSize(12)
                    .fontColor(this.selectedTime === t ? Color.White : $r('app.color.text_primary'))
                    .backgroundColor(this.selectedTime === t ? $r('app.color.primary_orange') : $r('app.color.bg_page'))
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(14).margin({ right: 8, bottom: 8 })
                    .onClick(() => this.selectedTime = t)
                }, (t: string) => t)
              }
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 车辆损伤选项 =====
            Row() {
              Column() {
                Text('车辆是否有损伤？').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                Text('如无损伤将直接进入结算流程').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.hasDamage }).onChange((v: boolean) => this.hasDamage = v)
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            // ===== 还车协议勾选 =====
            Row() {
              Checkbox().width(16).height(16).onChange((v: boolean) => this.agree = v)
              Text('我已阅读并同意').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ left: 6 })
              Text('《还车协议》').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.primary_orange'))
            }
            .margin({ top: 16 })
          }
          .padding(16).padding({ bottom: 100 })
        }
        .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

        // ===== 底部确认还车按钮 =====
        Button() {
          Text('确认还车').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
        }
        .width('100%').height(48).backgroundColor(this.agree ? $r('app.color.primary_orange') : '#FFBD9B').borderRadius(24)
        .margin({ left: 16, right: 16, top: 12, bottom: 12 }).enabled(this.agree)
        .onClick(() => this.goFee())
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
