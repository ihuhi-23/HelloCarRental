import router from '@ohos.router';
import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';

/**
 * 页面 13：AI 智能客服
 * 数据来源：后端 /api/ai/chat（DeepSeek API）
 * 特性：对话持久化（Preferences）、自动滚到底部、Markdown 轻量渲染
 */

// 单条消息
interface ChatMsg {
  role: string;   // 'user' | 'assistant'
  content: string;
}

// Markdown 渲染片段（一个消息可以拆成多个片段分别渲染）
interface MdSeg {
  text: string;
  bold: boolean;
  isList: boolean;      // 是否是列表项（带 - 或数字前缀）
  isHeader: boolean;    // 是否是标题（## 开头）
  isDivider: boolean;    // --- 分隔线
}

const BASE_URL = 'http://10.232.0.1:3000';
const STORE_NAME = 'ai_chat_store';
const KEY_HISTORY = 'ai_history';

// ============ 轻量 Markdown 解析器 ============
// 只处理 AI 客服回复里常见的格式，够用就行
function parseMarkdown(text: string): MdSeg[] {
  if (!text) return [];
  const segs: MdSeg[] = [];
  const lines = text.split('\n');

  for (let rawLine of lines) {
    let line = rawLine.trimEnd();
    if (!line.trim()) {
      // 空行也加进去（空文本渲染成换行间隔）
      segs.push({ text: '', bold: false, isList: false, isHeader: false, isDivider: false });
      continue;
    }
    // 分隔线
    if (/^[-*]{3,}$/.test(line.trim())) {
      segs.push({ text: '', bold: false, isList: false, isHeader: false, isDivider: true });
      continue;
    }
    // 标题 ##
    let isHeader = false;
    if (/^#{1,3}\s/.test(line)) {
      line = line.replace(/^#{1,3}\s/, '');
      isHeader = true;
    }
    // 列表项 - 或 1.
    let isList = false;
    if (/^\s*[-*]\s+/.test(line)) {
      line = line.replace(/^\s*[-*]\s+/, '• ');
      isList = true;
    } else if (/^\s*\d+\.\s+/.test(line)) {
      line = line.replace(/^\s*(\d+)\.\s+/, '$1. ');
      isList = true;
    }

    // 提取 **加粗** 片段
    // 简单处理：一行里可能有多段 **text**
    let remaining = line;
    let pendingBold = false;
    // 先替换 **内容** 为特殊标记，然后分割
    const parts = line.split(/(\*\*[^*]+\*\*)/);
    for (let part of parts) {
      if (part.startsWith('**') && part.endsWith('**') && part.length > 4) {
        let boldText = part.slice(2, -2);
        segs.push({ text: boldText, bold: true, isList: isList, isHeader: isHeader, isDivider: false });
      } else if (part) {
        segs.push({ text: part, bold: false, isList: isList, isHeader: isHeader, isDivider: false });
      }
    }
    // 如果这一行没产生任何 seg（比如整行就是 **bold**），确保至少有一个
    if (parts.length === 1 && !parts[0].includes('**')) {
      // 已经 push 过了，跳过
    }
  }
  return segs;
}

// ============ Preferences 持久化（在组件内部调用 getContext）============

async function saveHistory(prefs: preferences.Preferences, list: ChatMsg[]): Promise<void> {
  try {
    await prefs.put(KEY_HISTORY, JSON.stringify(list));
    await prefs.flush();
  } catch (e) {
    console.error('saveHistory error', e);
  }
}

async function loadHistory(prefs: preferences.Preferences): Promise<ChatMsg[]> {
  try {
    let raw = await prefs.get(KEY_HISTORY, '') as string;
    if (!raw) return [];
    return JSON.parse(raw) as ChatMsg[];
  } catch (e) {
    console.error('loadHistory error', e);
    return [];
  }
}

// ============ 主页面 ============
@Entry
@Component
struct AIChat {
  @State currentTab: number = 2;
  @State messages: ChatMsg[] = [];
  @State inputText: string = '';
  @State isSending: boolean = false;

  private quickQuestions: string[] = [
    '推荐几款性价比高的车',
    '租车需要什么证件？',
    '超时还车怎么收费？',
    '可以送车上门吗？'
  ];

  private scrollController: Scroller = new Scroller();
  private prefs: preferences.Preferences | null = null;

  aboutToAppear() {
    // 在组件内部初始化 Preferences（ArkTS 要求 getContext 在 UIAbilityContext 中调用）
    let context = getContext(this) as common.UIAbilityContext;
    preferences.getPreferences(context, STORE_NAME).then((store: preferences.Preferences) => {
      this.prefs = store;
      // 恢复历史
      loadHistory(store).then((saved: ChatMsg[]) => {
        if (saved && saved.length > 0) {
          this.messages = saved;
        } else {
          this.messages = [
            { role: 'assistant', content: '您好！我是哈喽租车 AI 客服小哈 🚗\n\n我可以帮您推荐车辆、查询价格、解答租车流程等问题，有什么需要帮忙的？' }
          ];
        }
        // 滚到底
        setTimeout(() => {
          this.scrollController.scrollTo({ xOffset: 0, yOffset: 99999, animation: { duration: 200 } });
        }, 80);
      });
    });
  }

  private persistMessages() {
    if (this.prefs) {
      saveHistory(this.prefs, this.messages);
    }
    // 自动滚到底
    setTimeout(() => {
      this.scrollController.scrollTo({ xOffset: 0, yOffset: 99999, animation: { duration: 200 } });
    }, 30);
  }

  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 2) router.replaceUrl({ url: pages[index] });
  }

  // 清空对话
  private clearChat() {
    this.messages = [
      { role: 'assistant', content: '对话已清空 ✅\n您好！我是哈喽租车 AI 客服小哈 🚗，有什么可以帮您的？' }
    ];
    this.persistMessages();
  }

  private async sendMessage() {
    let text = this.inputText.trim();
    if (!text || this.isSending) return;

    let userMsg: ChatMsg = { role: 'user', content: text };
    this.messages.push(userMsg);
    this.inputText = '';
    this.isSending = true;
    this.persistMessages();

    try {
      // 只发最近 10 条，避免上下文过长
      const history: ChatMsg[] = this.messages.slice(-10).map((m: ChatMsg): ChatMsg => {
        let item: ChatMsg = { role: m.role, content: m.content };
        return item;
      });

      let httpRequest = http.createHttp();
      let response = await httpRequest.request(BASE_URL + '/api/ai/chat', {
        method: http.RequestMethod.POST,
        connectTimeout: 10000,
        readTimeout: 15000,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ messages: history })
      });
      httpRequest.destroy();

      let body = JSON.parse(response.result as string) as Record<string, Object>;
      let reply: ChatMsg;
      if ((body['code'] as number) === 1 && body['data']) {
        let data = body['data'] as Record<string, string>;
        reply = { role: 'assistant', content: data['reply'] };
      } else {
        let msg = (body['message'] as string) || 'AI 服务暂时不可用';
        reply = { role: 'assistant', content: '😅 ' + msg };
      }
      this.messages.push(reply);
      this.persistMessages();
    } catch (e) {
      console.error('AI chat error:', e);
      let netErr: ChatMsg = { role: 'assistant', content: '😅 网络请求失败，请检查后端是否启动' };
      this.messages.push(netErr);
      this.persistMessages();
    } finally {
      this.isSending = false;
    }
  }

  private quickAsk(q: string) {
    this.inputText = q;
    this.sendMessage();
  }

  private isUser(m: ChatMsg): boolean { return m.role === 'user'; }

  build() {
    Column() {
      NavBar({
        title: 'AI 客服小哈',
        showBack: false,
        onBack: (): void => {},
        rightText: '清空',
        onRightClick: (): void => this.clearChat()
      })

      // 消息列表（带自动滚到底）
      Scroll(this.scrollController) {
        Column() {
          ForEach(this.messages, (msg: ChatMsg) => {
            if (this.isUser(msg)) {
              this.UserBubble(msg);
            } else {
              this.AIBubble(msg);
            }
          }, (msg: ChatMsg, idx: number) => idx + '_' + msg.role);

          // 加载中
          if (this.isSending) {
            this.LoadingBubble();
          }

          // 底部占位（确保最后一条消息能滚到顶部）
          Column().width('100%').height(4);
        }
        .padding(12)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 快捷问题（首屏空对话时显示）
      if (this.messages.length <= 1) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.quickQuestions, (q: string) => {
            Text(q)
              .fontSize(12)
              .fontColor($r('app.color.primary_orange'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(Color.White)
              .borderRadius(14)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => this.quickAsk(q))
          }, (q: string) => q)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      }

      // 输入栏
      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .padding({ left: 12, right: 12 })
          .fontSize($r('app.float.font_size_body'))
          .onChange((v: string) => this.inputText = v)
          .enabled(!this.isSending)

        Button() {
          Text(this.isSending ? '发送中...' : '发送').fontSize(14).fontColor(Color.White)
        }
        .height(40)
        .backgroundColor(this.inputText.trim() ? $r('app.color.primary_orange') : '#FFBD9B')
        .borderRadius(20)
        .margin({ left: 8 })
        .enabled(!!this.inputText.trim() && !this.isSending)
        .onClick(() => this.sendMessage())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.bg_page'))

      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // ============ 气泡 Builder ============

  @Builder
  UserBubble(msg: ChatMsg) {
    Row() {
      Blank();
      Text(msg.content)
        .fontSize($r('app.float.font_size_body'))
        .fontColor(Color.White)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.primary_orange'))
        .borderRadius({ topLeft: 14, topRight: 14, bottomLeft: 14, bottomRight: 4 })
        .maxLines(50)
        .width('75%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ top: 8 });
  }

  @Builder
  AIBubble(msg: ChatMsg) {
    Row() {
      Column() {
        // 头像标识
        Row() {
          Text('🤖').fontSize(14).margin({ right: 6 });
          Text('小哈').fontSize(11).fontColor($r('app.color.text_secondary'));
        }
        .margin({ bottom: 6 });

        // Markdown 渲染
        Column() {
          ForEach(parseMarkdown(msg.content), (seg: MdSeg, idx: number) => {
            if (seg.isDivider) {
              Column()
                .width('100%')
                .height(1)
                .backgroundColor($r('app.color.divider'))
                .margin({ top: 6, bottom: 6 });
            } else if (seg.text === '') {
              Column().width('100%').height(8);
            } else if (seg.isHeader) {
              Text(seg.text)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .margin({ top: 4 });
            } else {
              Text(seg.text)
                .fontSize($r('app.float.font_size_body'))
                .fontColor($r('app.color.text_primary'))
                .fontWeight(seg.bold ? FontWeight.Bold : FontWeight.Normal)
                .margin({ top: 2 })
                .width('100%');
            }
          }, (seg: MdSeg, idx: number) => idx + '_' + seg.text);
        }
        .width('100%');
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 14, topRight: 14, bottomLeft: 4, bottomRight: 14 })
      .width('85%');
    }
    .width('100%')
    .margin({ top: 8 });
  }

  @Builder
  LoadingBubble() {
    Row() {
      Column() {
        Row() {
          Column().width(6).height(6).backgroundColor($r('app.color.text_secondary')).borderRadius(3).margin({ right: 3 });
          Column().width(6).height(6).backgroundColor($r('app.color.text_secondary')).borderRadius(3).margin({ right: 3 });
          Column().width(6).height(6).backgroundColor($r('app.color.text_secondary')).borderRadius(3);
        }
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 14, topRight: 14, bottomLeft: 4, bottomRight: 14 });
      }
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .margin({ top: 8 });
  }
}
