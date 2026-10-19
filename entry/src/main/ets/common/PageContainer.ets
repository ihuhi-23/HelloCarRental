/**
 * 通用页面骨架容器
 */

@Component
export struct PageContainer {
  @BuilderParam content: CustomBuilder;
  @Prop showNavBar: boolean = false;
  @Prop navTitle: string = '';
  @Prop showTabBar: boolean = false;
  @Prop currentTab: number = 0;
  onTabChange: (index: number) => void = () => {};
  onBack: () => void = () => {};
  @Prop rightText: string = '';
  onRightClick: () => void = () => {};

  build() {
    Column() {
      if (this.showNavBar) {
        NavBar({
          title: this.navTitle,
          showBack: !this.showTabBar,
          onBack: this.onBack,
          rightText: this.rightText,
          onRightClick: this.onRightClick
        })
      }

      Scroll() {
        this.content();
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      if (this.showTabBar) {
        TabBar({
          currentIndex: this.currentTab,
          onTabChange: this.onTabChange
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
