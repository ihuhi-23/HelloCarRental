import router from '@ohos.router';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';
import { mockChatMessages } from '../common/MockData';
import { ChatMessage } from '../common/Interfaces';

/**
 * 页面 13：AI 智能客服
 * 【复杂页面】
 */
@Entry
@Component
struct AIChat {
  @State currentTab: number = 2;
  @State messages: ChatMessage[] = mockChatMessages;
  @State inputText: string = '';
  private quickQuestions: string[] = ['取车流程是怎样的？', '可以提前还车吗？', '违章怎么处理？', '如何添加驾驶员？'];

  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 2) router.replaceUrl({ url: pages[index] });
  }

  private sendMessage(text: string) {
    if (!text || text.trim().length === 0) return;
    const now = new Date();
    const h = now.getHours();
    const m = now.getMinutes();
    const timeStr = (h < 10 ? '0' + h : '' + h) + ':' + (m < 10 ? '0' + m : '' + m);

    this.messages.push({
      id: 'msg' + Date.now().toString(),
      content: text,
      isUser: true,
      time: timeStr
    });
    this.inputText = '';

    setTimeout(() => {
      const replies: string[] = [
        '好的，我已经收到您的问题，稍等一下哦～',
        '根据您的描述，建议您提前联系门店工作人员确认具体情况。',
        '这个问题我帮您查询一下，请稍候...',
        '感谢您的咨询！还有什么可以帮您的吗？😊'
      ];
      const reply = replies[Math.floor(Math.random() * replies.length)];
      this.messages.push({
        id: 'reply' + Date.now().toString(),
        content: reply,
        isUser: false,
        time: timeStr
      });
    }, 800);
  }

  build() {
    Column() {
      NavBar({ title: '智能客服', showBack: false, onBack: (): void => {}, rightText: '', onRightClick: (): void => {} })

      Scroll() {
        Column() {
          Column() {
            Text('🤖').fontSize(40)
            Text('您好，我是 Hello 租车的智能小助手').fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).margin({ top: 8 })
            Text('有什么可以帮您的吗？').fontSize($r('app.float.font_size_caption')).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
          }
          .width('100%').padding(16).alignItems(HorizontalAlign.Center)

          ForEach(this.messages, (msg: ChatMessage) => {
            this.MessageBubble(msg)
          }, (msg: ChatMessage) => msg.id)
        }
        .padding(12)
      }
      .layoutWeight(1).scrollBar(BarState.Off)

      Row() {
        Scroll() {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.quickQuestions, (q: string) => {
              Text(q)
                .fontSize(12)
                .fontColor($r('app.color.text_primary'))
                .backgroundColor(Color.White)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(14).margin({ right: 8, bottom: 8 })
                .onClick(() => this.sendMessage(q))
            }, (q: string) => q)
          }
        }
        .scrollBar(BarState.Off).layoutWeight(1)
      }
      .width('100%').padding({ left: 12, right: 12, top: 8 })

      Row() {
        TextInput({ placeholder: '请输入您的问题', text: this.inputText })
          .layoutWeight(1).height(40).backgroundColor(Color.White).borderRadius(20)
          .padding({ left: 16, right: 16 }).fontSize($r('app.float.font_size_body'))
          .onChange((v: string) => { this.inputText = v; })
          .onSubmit(() => { this.sendMessage(this.inputText); })
        Button() {
          Text('发送').fontSize($r('app.float.font_size_body')).fontColor(Color.White)
        }
        .height(40).padding({ left: 16, right: 16 }).backgroundColor($r('app.color.primary_orange')).borderRadius(20).margin({ left: 8 })
        .onClick(() => this.sendMessage(this.inputText))
      }
      .width('100%').padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor(Color.White)

      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.isUser) {
        Blank()
        Column() {
          Text(msg.content).fontSize($r('app.float.font_size_body')).fontColor(Color.White).padding(12)
            .backgroundColor($r('app.color.primary_orange')).borderRadius(12).maxLines(10).textAlign(TextAlign.Start)
          Text(msg.time).fontSize(10).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
        }.alignItems(HorizontalAlign.End)
      } else {
        Column() { Text('🤖').fontSize(20) }.width(36).height(36).backgroundColor(Color.White).borderRadius(18).justifyContent(FlexAlign.Center).margin({ right: 8 })
        Column() {
          Text(msg.content).fontSize($r('app.float.font_size_body')).fontColor($r('app.color.text_primary')).padding(12)
            .backgroundColor(Color.White).borderRadius(12).maxLines(10).textAlign(TextAlign.Start)
          Text(msg.time).fontSize(10).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%').padding({ top: 4, bottom: 4 })
  }
}
