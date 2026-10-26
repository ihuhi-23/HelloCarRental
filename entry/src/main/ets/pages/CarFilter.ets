import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { SwiperBanner } from '../common/SwiperBanner';
import { FilterCondition } from '../common/Interfaces';

/**
 * 页面：CarFilter 车辆筛选
 * 分工：成员二 · 复杂页面
 * 入口：Index 首页右上角「筛选」
 * 功能：车型/品牌/燃油多选、价格滑块、排序方式、重置与确认
 * 容器：Scroll（筛选内容）、Flex（选项自动换行）、ForEach（选项与排序列表）
 * 关键状态：selectedTypes/selectedBrands/fuelTypes（多选条件）、priceMax（价格上限）、sortBy（排序索引）
 * 关键方法：toggleItem() 切换选中项、reset() 重置条件、FilterSection() 复用的筛选区块
 */
@Entry
@Component
struct CarFilter {
  @State selectedTypes: string[] = [];
  @State selectedBrands: string[] = [];
  @State priceMax: number = 500;
  @State fuelTypes: string[] = [];
  @State sortBy: number = 0;
  @State condition: FilterCondition = { brand: '', priceRange: '100-500', carType: '', sortBy: '综合排序' };

  private carTypes: string[] = ['轿车', 'SUV', 'MPV', '跑车', '皮卡'];
  private brands: string[] = ['宝马', '奔驰', '奥迪', '丰田', '大众', '别克', '特斯拉', '比亚迪'];
  private fuelOptions: string[] = ['汽油', '纯电动', '混合动力'];
  private sortOptions: string[] = ['综合排序', '价格从低到高', '评分从高到低'];

  // 作用：清空所有筛选条件，恢复默认价格与排序
  private reset() {
    this.selectedTypes = [];
    this.selectedBrands = [];
    this.priceMax = 500;
    this.fuelTypes = [];
    this.sortBy = 0;
    this.condition = { brand: '', priceRange: '100-500', carType: '', sortBy: '综合排序' };
  }

  // 作用：选中或取消选中一个选项，返回新的数组
  private toggleItem(list: string[], item: string): string[] {
    const result = list.slice();
    const idx = result.indexOf(item);
    if (idx >= 0) {
      result.splice(idx, 1);
    } else {
      result.push(item);
    }
    return result;
  }

  // 作用：判断选项是否已选中，用于按钮高亮
  private contains(list: string[], item: string): boolean {
    return list.indexOf(item) >= 0;
  }

  build() {
    Column() {
      // ===== 顶部导航栏，右侧「重置」 =====
      NavBar({
        title: '筛选条件',
        rightText: '重置',
        onBack: (): void => { router.back(); },
        onRightClick: (): void => {
          this.selectedTypes = [];
          this.selectedBrands = [];
        }
      })

      // ===== 轮播 Banner：SwiperBanner 组件内部使用 Swiper =====
      SwiperBanner()

      // ===== 筛选内容滚动区 =====
      Scroll() {
        Column() {
          // ===== 车型 / 品牌 / 燃油类型多选（复用 FilterSection） =====
          this.FilterSection('车型', this.carTypes, this.selectedTypes, false)
          this.FilterSection('品牌', this.brands, this.selectedBrands, false)
          this.FilterSection('燃油类型', this.fuelOptions, this.fuelTypes, false)

          // ===== 价格区间：Slider 滑块 =====
          Column() {
            Text('价格区间').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
            Text('¥100 - ¥' + this.priceMax + '/天').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.primary_orange')).margin({ top: 4 })

            Slider({ value: this.priceMax, min: 100, max: 800, step: 50, style: SliderStyle.OutSet })
              .width('100%')
              .trackThickness(4)
              .selectedColor($r('app.color.primary_orange'))
              .blockColor($r('app.color.primary_orange'))
              .onChange((value: number) => { this.priceMax = Math.floor(value); })
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })

          // ===== 排序方式：ForEach 渲染选项 =====
          Column() {
            Text('排序方式').fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
            ForEach(this.sortOptions, (opt: string, idx: number) => {
              Row() {
                Text(opt).fontSize($r('app.float.font_size_body')).fontColor(this.sortBy === idx ? $r('app.color.primary_orange') : $r('app.color.text_primary'))
                Blank()
                if (this.sortBy === idx) {
                  Text('✓').fontSize(16).fontColor($r('app.color.primary_orange'))
                }
              }
              .width('100%').padding({ top: 10, bottom: 10 })
              .onClick(() => { this.sortBy = idx; })
            }, (opt: string, idx: number) => `${idx}`)
          }
          .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
        }
        .padding(16)
      }
      .layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)

      // ===== 底部「确认筛选」按钮 =====
      Button() {
        Text('确认筛选').fontSize($r('app.float.font_size_body')).fontColor(Color.White).fontWeight(FontWeight.Medium)
      }
      .width('100%').height(48).backgroundColor($r('app.color.primary_orange')).borderRadius(24)
      .margin({ left: 16, right: 16, top: 12, bottom: 12 })
      .onClick(() => router.back())
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // 作用：可复用的筛选分组区块，按标题区分车型/品牌/燃油并写入对应选中状态
  @Builder
  FilterSection(title: string, options: string[], selected: string[], _isPrice: boolean) {
    Column() {
      Text(title).fontSize($r('app.float.font_size_body')).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).margin({ bottom: 12 })
      // ===== 选项宫格：Flex 自动换行 + ForEach =====
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(options, (opt: string) => {
          Text(opt)
            .fontSize($r('app.float.font_size_caption'))
            .fontColor(this.contains(selected, opt) ? Color.White : $r('app.color.text_primary'))
            .backgroundColor(this.contains(selected, opt) ? $r('app.color.primary_orange') : $r('app.color.bg_page'))
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(16).margin({ right: 8, bottom: 8 })
            .onClick(() => {
              if (title === '车型') this.selectedTypes = this.toggleItem(this.selectedTypes, opt);
              else if (title === '品牌') this.selectedBrands = this.toggleItem(this.selectedBrands, opt);
              else if (title === '燃油类型') this.fuelTypes = this.toggleItem(this.fuelTypes, opt);
            })
        }, (opt: string) => opt)
      }
      .width('100%')
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ top: 12 })
  }
}
