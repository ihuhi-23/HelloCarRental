import { BannerInfo } from './Interfaces';
import { fetchBanners } from './HttpUtil';

/**
 * SwiperBanner 通用 Banner 轮播组件
 * 数据：HttpUtil.fetchBanners() → GET /api/banners，进入组件时加载一次
 * 行为：无数据或请求失败时渲染 0 尺寸占位，自动隐藏不占空间
 * props：无，组件内部自行取数据
 * 使用页面：Index、CarFilter、OrderConfirm、FeeSettlement、VerifyAuth、Violation
 */

@Component
export struct SwiperBanner {
  @State banners: BannerInfo[] = [];

  aboutToAppear() {
    fetchBanners().then((list: BannerInfo[]) => {
      this.banners = list;
    });
  }

  build() {
    if (this.banners.length === 0) {
      // 没数据就不渲染，不占空间
      Column().width(0).height(0);
    } else {
      // ===== 轮播主体：图片 + 底部渐变标题，自动播放 =====
      Swiper() {
        ForEach(this.banners, (banner: BannerInfo) => {
          Stack() {
            Image(banner.imageUrl)
              .width('100%')
              .height(140)
              .objectFit(ImageFit.Cover)
              .backgroundColor('#E0E0E0');

            // 底部渐变遮罩 + 标题
            Column() {
              Blank();
              Row() {
                if (banner.title) {
                  Text(banner.title)
                    .fontSize(13)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis });
                }
              }
              .width('100%')
              .padding({ left: 14, right: 14, bottom: 10 });
            }
            .width('100%')
            .height('100%')
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['rgba(0,0,0,0)', 0.4], ['rgba(0,0,0,0.55)', 1.0]]
            });
          }
          .width('100%')
          .height(140);
        }, (banner: BannerInfo) => banner.id);
      }
      .width('100%')
      .height(140)
      .autoPlay(true)
      .interval(3500)
      .indicator(true)
      .borderRadius(8)
      .margin({ left: 12, right: 12, top: 8 });
    }
  }
}
