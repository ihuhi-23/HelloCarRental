import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { CarInfo, Coupon } from '../common/Interfaces';
import { fetchCarDetail, fetchCoupons } from '../common/HttpUtil';

/**
 * 页面 3：预订确认
 * 【复杂页面】
 * 数据来源：后端 /api/cars/:id + /api/coupons
 */
@Entry
@Component
struct OrderConfirm {
  @State car: CarInfo | null = null;
  @State days: number = 3;
  @State useInsurance: boolean = true;
  @State selectedCoupon: number = -1;
  @State coupons: Coupon[] = [];
  @State pickupStore: string = '浦东机场 T2 航站楼店';
  @State returnStore: string = '浦东机场 T2 航站楼店';

  aboutToAppear() {
    this.loadData();
  }

  private async loadData() {
    try {
      const params = router.getParams() as Record<string, string>;
      const carId = params ? params['carId'] : '';
      if (carId) {
        this.car = await fetchCarDetail(carId);
      }
      this.coupons = await fetchCoupons();
    } catch (e) {
      console.error('Load confirm data failed');
    }
  }

  private getSubtotal(): number { return (this.car?.pricePerDay || 0) * this.days; }

  private getDiscount(): number {
    if (this.selectedCoupon >= 0 && this.selectedCoupon < this.coupons.length) {
      const coupon = this.coupons[this.selectedCoupon];
      if (this.getSubtotal() >= coupon.threshold) return coupon.discount;
    }
    return 0;
  }

  private getInsuranceFee(): number { return this.useInsurance ? 30 : 0; }
  private getTotal(): number { return this.getSubtotal() - this.getDiscount() + this.getInsuranceFee(); }

  private goPayment() { router.pushUrl({ url: 'pages/Payment' }); }

  build() {
    Column() {
      NavBar({ title: '确认订单', onBack: (): void => { router.back(); }, rightText: '', onRightClick: (): void => {} })

      SwiperBanner()

      if (!this.car) {
        Column() {
          Text('⏳').fontSize(48)
          Text('加载中...').fontSize(14).fontColor('#909399').margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Image(this.car.imageUrl).width(72).height(72).objectFit(ImageFit.Cover).borderRadius(12)
                Column() {
                  Text(this.car.name).fontSize($r('app.float.font_size_subtitle')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                  Text(this.car.seats + '座 · ' + this.car.transmission + ' · ' + this.car.displacement)
                    .fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
              }
              Divider().color($r('app.color.divider')).margin({ top: 14, bottom: 14 })
              Row() {
                Text('取车门店').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(70)
                Column() {
                  Text(this.pickupStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_primary'))
                  Text('2026-10-20 10:00').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              Row() {
                Text('还车门店').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_secondary')).width(70)
                Column() {
                  Text(this.returnStore).fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_primary'))
                  Text('2026-10-23 10:00').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 2 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }.margin({ top: 12 })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Row() {
              Text('优惠券').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
              Blank()
              if (this.getDiscount() > 0) {
                Text('-¥' + this.getDiscount()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.primary_orange')).margin({ right: 8 })
              } else {
                Text(this.coupons.length + '张可用').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ right: 8 })
              }
              Text('›').fontSize(16).fontColor($r('app.color.text_secondary'))
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
            .onClick(() => {
              if (this.coupons.length > 0) {
                this.selectedCoupon = (this.selectedCoupon + 1) % this.coupons.length;
              }
            })

            Row() {
              Column() {
                Text('无忧保险').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                Text('覆盖车损险、第三者责任险等').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.useInsurance }).onChange((isOn: boolean) => { this.useInsurance = isOn; })
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

            Column() {
              Text('费用明细').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
              Row() {
                Text('车辆租金 (' + this.days + '天)').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                Blank()
                Text('¥' + this.getSubtotal()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
              }.width('100%')
              if (this.getDiscount() > 0) {
                Row() {
                  Text('优惠券减免').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                  Blank()
                  Text('-¥' + this.getDiscount()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.primary_orange'))
                }.width('100%').margin({ top: 8 })
              }
              if (this.useInsurance) {
                Row() {
                  Text('无忧保险').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                  Blank()
                  Text('¥' + this.getInsuranceFee()).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary'))
                }.width('100%').margin({ top: 8 })
              }
              Divider().color($r('app.color.divider')).margin({ top: 12, bottom: 12 })
              Row() {
                Text('合计').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                Blank()
                Text('¥' + this.getTotal()).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange'))
              }.width('100%')
            }
            .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
          }
          .padding(16).padding({ bottom: 100 })
        }
        .layoutWeight(1).scrollBar(BarState.Off)

        Row() {
          Column() {
            Text('合计').fontSize($r('app.float.font_size_small')).fontColor($r('app.color.text_secondary'))
            Text('¥' + this.getTotal()).fontSize($r('app.float.font_size_price')).fontWeight(FontWeight.Bold).fontColor($r('app.color.primary_orange')).margin({ top: 2 })
          }.alignItems(HorizontalAlign.Start).margin({ right: 16 })
          Button() {
            Text('提交订单').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1).height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24).onClick(() => this.goPayment())
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).backgroundColor(Color.White)
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
