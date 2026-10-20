import { BannerInfo } from './Interfaces';
import { fetchBanners } from './HttpUtil';

/**
 * 通用 Banner 轮播组件
 * 用法：直接 <SwiperBanner /> 插入页面顶部 NavBar 下方即可
 * 后端无 Banner 数据时组件自动隐藏（不占空间）
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
