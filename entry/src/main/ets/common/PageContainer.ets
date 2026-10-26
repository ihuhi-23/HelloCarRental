/**
 * PageContainer 通用页面骨架容器
 * 用途：组合 NavBar + 可滚动内容 + TabBar，页面只需传入自己的 content
 * props：showNavBar/navTitle、showTabBar/currentTab、rightText 及对应回调
 * 使用页面：当前无页面引用（预留；各页面目前自行拼装 NavBar/TabBar）
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
      // ===== 顶部导航栏（showNavBar 为 true 时显示）=====
      if (this.showNavBar) {
        NavBar({
          title: this.navTitle,
          showBack: !this.showTabBar,
          onBack: this.onBack,
          rightText: this.rightText,
          onRightClick: this.onRightClick
        })
      }

      // ===== 可滚动内容区（页面通过 @BuilderParam content 传入）=====
      Scroll() {
        this.content();
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      // ===== 底部标签栏（showTabBar 为 true 时显示）=====
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
