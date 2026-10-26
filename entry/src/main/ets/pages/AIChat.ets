import router from '@ohos.router';
import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { NavBar } from '../common/NavBar';
import { TabBar } from '../common/TabBar';

/**
 * 页面：AIChat AI 智能客服
 * 分工：成员五 · 复杂页面
 * 入口：底部 TabBar「客服」
 * 功能：消息列表、Markdown 渲染、快捷提问、发送消息
 * 容器：Grid（快捷提问两列）、Scroll（消息列表）
 * 关键状态：messages（对话记录）、isSending（发送中）
 * 关键方法：sendMessage() 调用后端 AI 接口、loadHistory() 恢复历史记录
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

const BASE_URL = 'http://47.107.80.195:8081';
const STORE_NAME = 'ai_chat_store';
const KEY_HISTORY = 'ai_history';

// ============ 轻量 Markdown 解析器 ============
// 只处理 AI 客服回复里常见的格式，够用就行
// 作用：解析 AI 回复中的标题、列表、加粗、分隔线
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

// 作用：把对话记录写入 Preferences
async function saveHistory(prefs: preferences.Preferences, list: ChatMsg[]): Promise<void> {
  try {
    await prefs.put(KEY_HISTORY, JSON.stringify(list));
    await prefs.flush();
  } catch (e) {
    console.error('saveHistory error', e);
  }
}

// 作用：从 Preferences 读取历史对话
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

  // 作用：初始化 Preferences，恢复历史消息并滚到底部
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

  // 作用：保存当前消息列表并自动滚动到底部
  private persistMessages() {
    if (this.prefs) {
      saveHistory(this.prefs, this.messages);
    }
    // 自动滚到底
    setTimeout(() => {
      this.scrollController.scrollTo({ xOffset: 0, yOffset: 99999, animation: { duration: 200 } });
    }, 30);
  }

  // 作用：底部 Tab 切换，非本页时 replaceUrl 到目标页
  private switchTab(index: number) {
    this.currentTab = index;
    const pages: string[] = ['pages/Index', 'pages/MyOrders', 'pages/AIChat', 'pages/PersonalCenter'];
    if (index !== 2) router.replaceUrl({ url: pages[index] });
  }

  // 清空对话
  // 作用：重置消息列表并写入 Preferences
  private clearChat() {
    this.messages = [
      { role: 'assistant', content: '对话已清空 ✅\n您好！我是哈喽租车 AI 客服小哈 🚗，有什么可以帮您的？' }
    ];
    this.persistMessages();
  }

  // 作用：发送用户消息，调用后端 /api/ai/chat（http.request），追加 AI 回复
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

  // 作用：点击快捷问题，填入输入框并立即发送
  private quickAsk(q: string) {
    this.inputText = q;
    this.sendMessage();
  }

  // 作用：判断消息是否为用户发送
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
      // 消息列表：Scroll + Column + ForEach 渲染对话
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
        .padding({ left: 16, right: 16, top: 8, bottom: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)

      // ===== 快捷提问区（首屏空对话时显示） =====
      // 快捷问题（首屏空对话时显示）
      if (this.messages.length <= 1 && !this.isSending) {
        Column() {
          Text('猜你想问')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 8 })
          // 快捷提问两列：Grid + GridItem
          Grid() {
            ForEach(this.quickQuestions, (q: string) => {
              GridItem() {
                Text(q)
                  .width('100%')
                  .fontSize(12)
                  .fontColor($r('app.color.primary_orange'))
                  .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                  .backgroundColor($r('app.color.primary_orange_light'))
                  .borderRadius(16)
                  .border({ width: 1, color: '#FFDCC4' })
                  .onClick(() => this.quickAsk(q))
              }
            }, (q: string): string => q)
          }
          .width('100%')
          .columnsTemplate('1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16, bottom: 4 })
      }

      // ===== 输入栏（白色胶囊卡片） =====
      // 输入栏（白色胶囊卡片）
      Row() {
        TextInput({ placeholder: '有问题尽管问我…', text: this.inputText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.Transparent)
          .padding({ left: 14, right: 8 })
          .fontSize($r('app.float.font_size_body'))
          .placeholderColor($r('app.color.text_hint'))
          .onChange((v: string) => this.inputText = v)
          .enabled(!this.isSending)

        Button() {
          Text('↑')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(36)
        .height(36)
        .backgroundColor(this.inputText.trim() && !this.isSending ? $r('app.color.primary_orange') : '#FFC9A8')
        .borderRadius(18)
        .margin({ right: 4 })
        .enabled(!!this.inputText.trim() && !this.isSending)
        .onClick(() => this.sendMessage())
      }
      .width('100%')
      .padding({ left: 6, right: 6, top: 6, bottom: 6 })
      .backgroundColor(Color.White)
      .borderRadius(24)
      .margin({ left: 16, right: 16, top: 4, bottom: 10 })
      .shadow({ radius: 10, color: '#0A000000', offsetX: 0, offsetY: 2 })

      // 底部 TabBar
      TabBar({ currentIndex: this.currentTab, onTabChange: (i: number): void => this.switchTab(i) })
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }

  // ============ 气泡 Builder ============

  // AI 头像（橙底白字，统一标识，不随消息重复文字标签）
  // 作用：AI 头像展示
  @Builder
  AIAvatar() {
    Column() {
      Text('哈').fontSize(14).fontColor(Color.White).fontWeight(FontWeight.Bold)
    }
    .width(32).height(32)
    .borderRadius(16)
    .linearGradient({ angle: 180, colors: [['#FF9A55', 0], ['#FF6B00', 1]] })
    .justifyContent(FlexAlign.Center)
    .margin({ right: 10 })
    .alignSelf(ItemAlign.Start)
  }

  // 作用：用户消息气泡（右侧橙色）
  @Builder
  UserBubble(msg: ChatMsg) {
    Row() {
      Blank();
      Text(msg.content)
        .fontSize($r('app.float.font_size_body'))
        .fontColor(Color.White)
        .lineHeight(21)
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .linearGradient({ angle: 180, colors: [['#FF9A55', 0], ['#FF6B00', 1]] })
        .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
        .constraintSize({ maxWidth: '76%' })
        .shadow({ radius: 10, color: '#1AFF6B00', offsetX: 0, offsetY: 3 });
    }
    .width('100%')
    .margin({ top: 12 });
  }

  // 作用：AI 消息气泡，按 Markdown 片段渲染
  @Builder
  AIBubble(msg: ChatMsg) {
    Row() {
      this.AIAvatar();

      Column() {
        // Markdown 片段渲染：ForEach(parseMarkdown(...))
        ForEach(parseMarkdown(msg.content), (seg: MdSeg, idx: number) => {
          if (seg.isDivider) {
            Column()
              .width('100%')
              .height(1)
              .backgroundColor($r('app.color.divider'))
              .margin({ top: 8, bottom: 8 });
          } else if (seg.text === '') {
            Column().width('100%').height(6);
          } else if (seg.isHeader) {
            Text(seg.text)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .lineHeight(22)
              .margin({ top: 6, bottom: 2 });
          } else {
            Text(seg.text)
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.text_primary'))
              .lineHeight(21)
              .fontWeight(seg.bold ? FontWeight.Bold : FontWeight.Normal)
              .margin({ top: 2 });
          }
        }, (seg: MdSeg, idx: number) => idx + '_' + seg.text);
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
      .constraintSize({ maxWidth: '78%' })
      .shadow({ radius: 10, color: '#0A000000', offsetX: 0, offsetY: 2 });
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ top: 12 });
  }

  // 作用：AI 正在输入提示气泡
  @Builder
  LoadingBubble() {
    Row() {
      this.AIAvatar();

      Row() {
        LoadingProgress()
          .width(18).height(18)
          .color($r('app.color.primary_orange'))
        Text('小哈正在输入…')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ left: 8 })
      }
      .padding({ left: 12, right: 14, top: 10, bottom: 10 })
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
      .shadow({ radius: 10, color: '#0A000000', offsetX: 0, offsetY: 2 });
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ top: 12 });
  }
}
