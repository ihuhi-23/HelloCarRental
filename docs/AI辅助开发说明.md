# AI 辅助开发说明

## 一、使用的 AI 工具与方式

- 工具：Trae IDE 内置 AI 编程助手（DeepSeek-V4.1-Flash 模型）
- 使用环节：页面骨架生成、ArkTS 组件与状态管理编写、服务端接口编写、后台管理页面开发、编译报错定位、课程硬指标自查
- 协作方式：由组员用自然语言描述需求与验收标准 → AI 生成或修改代码 → 组员在 DevEco Studio 编译、真机运行验收 → 不通过则带着报错信息继续对话修正
- 边界：需求定义、数据准备、界面审美判断、真机测试结论、最终提交内容均由人工决定，AI 不参与决策

## 二、典型提示词记录

| 序号 | 场景 | 提示词要点 | 产出位置 |
| --- | --- | --- | --- |
| 1 | 首页改版 | 首页要求整页滚动，只有 NavBar 和 TabBar 固定；车辆图片要大；轮播、品牌宫格、门店行、搜索框、车辆列表放在同一个滚动容器里 | `pages/Index.ets` |
| 2 | 轮播组件复用 | 把筛选页顶部的轮播抽成公共组件，数据从后端 Banner 接口取，注入到筛选、确认订单、实名认证、违章、费用结算页面 | `common/SwiperBanner.ets` |
| 3 | 门店地图 | 后端代理高德 Web 服务隐藏 Key，门店数据补经纬度；用 Web 组件加载后端生成的地图 H5，支持地图/列表切换与城市过滤 | `backend/server.js`、`pages/StoreQuery.ets` |
| 4 | 地图选店 | 确认订单页的取车/还车门店改成可选，列表来源于后端门店接口，并支持在地图上点击门店标签回填 | `pages/OrderConfirm.ets` |
| 5 | 订单全链路 | 提交订单时先在后端创建订单（待支付），支付后置为已确认，还车置为已还车，结算支付后置为已完成；订单列表返回时立即刷新 | `server.js`、`OrderConfirm/Payment/PaymentSuccess/FeeSettlement/ReturnConfirm` |
| 6 | 账号体系 | 用户真实注册登录，密码加盐哈希，登录签发 token；头像从相册选取后上传后端并落盘，个人中心立即刷新 | `server.js`、`Login/Register/PersonalCenter` |
| 7 | AI 客服 UI | 消息气泡按角色区分样式，左侧统一头像，加载态改为旋转指示，快捷提问改为胶囊按钮，输入栏做白色胶囊卡片 | `pages/AIChat.ets` |
| 8 | 页面滚动对齐 | 内容不足一屏时卡片被垂直居中，要求一律贴顶显示 | 18 个页面的 `Scroll` |
| 9 | 后台管理系统移动端适配 | 768px 以下侧边栏改抽屉，统计卡片自适应两列，表格横向滑动，弹窗接近全宽，表单标签置顶 | `backend/admin/index.html` |
| 10 | 课程硬指标核对 | 对照课程考核表逐条检查 18 个页面，指出缺失项并补齐 List/Grid/Swiper 容器与数据模型 | `pages/*.ets`、`common/Interfaces.ets` |

> 以上为提示词要点归纳，原始对话记录按会话保留，可在答辩时按需展示。

## 三、更新记录

| 日期 | 更新内容 |
| --- | --- |
| 2026-10-19 | 项目初始化，18 个页面骨架、公共组件与 Mock 数据 |
| 2026-10-20 | 订单页点击跳转修复；五个页面接入轮播 Banner；高德地图代理与门店经纬度补全 |
| 2026-10-21 | 服务端原子写盘、并发下单防覆盖、统一错误处理、配置外置 |
| 2026-10-22 | 接口缺陷修复：搜索路由匹配顺序、门店城市过滤、订单号唯一性、空数组误判回退 Mock |
| 2026-10-23 | 首页轮播统一为公共组件 |
| 2026-10-24 | 注册/登录改为真实账号体系，新增头像上传 |
| 2026-10-25 | AI 客服页面 UI 重构；订单创建与状态流转修复；还车结算不再出现取车凭证；页面滚动贴顶修复；确认订单页支持门店列表/地图选店 |
| 2026-10-26 | 后台管理系统移动端适配；订单管理车辆列改为图片缩略图；按课程硬指标补齐容器组件与数据模型 |

## 四、AI 生成代码的定位方式

答辩时若需定位实现，可按「功能 → 文件 → 关键位置」直接跳转：

| 功能 | 文件 | 关键实现 |
| --- | --- | --- |
| 页面列表与路由表 | `entry/src/main/ets/pages/*.ets` | 各页 `aboutToAppear` 与 `router.pushUrl` 调用 |
| 底部标签切换 | `common/TabBar.ets` | `onTabChange` 回调 + 各页 `pages` 数组 |
| 公共导航栏 | `common/NavBar.ets` | `@Component NavBar`，`showBack` / `rightText` 控制形态 |
| 轮播组件 | `common/SwiperBanner.ets` | 拉取 `/api/banners`，`Swiper + ForEach` 渲染 |
| 数据模型 | `common/Interfaces.ets` | 车辆、门店、订单、优惠券、用户、Banner 等 interface |
| 网络请求 | `common/HttpUtil.ets` | `fetchHomeCars` / `fetchOrders` / `createOrder` / `updateOrderStatus`，失败回退 Mock |
| 服务端入口 | `backend/server.js` | `POST /api/orders` 创建订单、`POST /api/orders/:id/status` 状态流转、`/api/register`、`/api/login`、`POST /api/user/avatar` |
| 地图 H5 | `backend/server.js` | `GET /api/map/stores` 动态生成高德页面，`?select=1` 为选店模式 |
| 后台管理 | `backend/admin/index.html` | Vue3 + Element Plus，模块按 `activeMenu` 切换 |

## 五、使用声明

1. 所有 AI 生成代码均经过人工阅读、编译与真机运行验证后才保留。
2. AI 未参与需求定义、页面取舍、数据真实性判断与最终验收。
3. 若后续继续使用 AI 修改代码，同步更新本文件的更新记录表。
