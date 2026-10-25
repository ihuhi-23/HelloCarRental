# 哈喽租车 HelloCarRental

鸿蒙（HarmonyOS）租车 App 示例项目，前端使用 ArkTS / ArkUI，后端为 Node.js + Express。
团队期末作业项目。

> **接口已部署在云端**，直接编译运行即可，**无需在本地启动后端**。

---

## 功能概览

- 登录 / 注册、个人中心
- 首页车型推荐、车辆筛选（车型、座位数、价格区间）
- 车辆详情、下单、支付、支付成功
- 我的订单、订单详情、取车凭证
- 用车中、费用结算
- 门店查询（高德地图）
- AI 客服「小哈」（DeepSeek）
- 移动端 Web 管理后台（车辆、订单、门店、AI 配置）

## 技术栈

| 层 | 技术 |
|----|------|
| 客户端 | HarmonyOS ArkTS / ArkUI，DevEco Studio 工程 |
| 后端 | Node.js + Express 3.x（`express` / `cors` / `multer`） |
| 数据存储 | JSON 文件（`backend/data.json`），图片存 `backend/uploads/` |
| 部署 | Ubuntu + Nginx + systemd，HTTPS（Let's Encrypt） |

## 目录结构

```
HelloCarRental/
├── AppScope/                  # 应用级配置与资源
├── entry/                     # 主模块（页面、组件、工具类）
│   └── src/main/ets/
│       ├── common/HttpUtil.ets    # 统一请求封装 + BASE_URL
│       └── pages/                 # 各业务页面
├── backend/                   # Node.js 后端
│   ├── server.js              # 所有接口 + 静态托管
│   ├── admin/index.html       # Web 管理后台（Vue3 + Element Plus，适配移动端）
│   ├── data.json              # 演示数据
│   ├── uploads/               # 车辆图片、头像
│   ├── ai_config.example.json # AI 配置模板（需复制为 ai_config.json）
│   └── map_config.example.json# 高德配置模板（需复制为 map_config.json）
├── build-profile.json5        # 工程构建配置（SDK 版本、签名）
├── oh-package.json5           # 工程依赖与 modelVersion
└── hvigor/hvigor-config.json5 # hvigor 构建工具配置
```

## 快速开始（只跑 App）

1. 安装 **DevEco Studio 6.1.1 Release**（对应 HarmonyOS SDK API 24）。
2. 打开本工程根目录，等待 `hvigor` 同步完成。
3. 菜单 **File → Project Structure → Signing Configs**，勾选 **Automatically generate signature**（需登录华为开发者账号）。
   - 本工程 `signingConfigs` 为空，不签名无法安装到模拟器。
4. 启动 HarmonyOS 模拟器（或真机），点击运行。

客户端接口地址在 [entry/src/main/ets/common/HttpUtil.ets](entry/src/main/ets/common/HttpUtil.ets)：

```ts
export const BASE_URL = 'https://car.ihuhi.xyz';
```

已指向线上服务器，编译后即可直接获取真实数据（车辆、门店、订单等）。

- **App 地址**：https://car.ihuhi.xyz
- **管理后台**：https://car.ihuhi.xyz/admin/

> 演示账号见后台或 `backend/data.json`，也可在 App 内直接注册。

## 可选：本地运行后端

仅在需要改后端逻辑时才需要。步骤：

```bash
cd backend
npm install
cp ai_config.example.json ai_config.json     # 填入自己的 DeepSeek API Key
cp map_config.example.json map_config.json   # 填入自己的高德 Web 服务 Key
npm start                                    # 默认 http://localhost:3000
```

然后把 `HttpUtil.ets` 的 `BASE_URL` 改回本地地址：

| 运行环境 | BASE_URL |
|----------|----------|
| 模拟器访问宿主机 | `http://10.232.0.1:3000` |
| 真机（同一局域网） | `http://<电脑局域网IP>:3000` |

不填 Key 时后端仍可启动：AI 客服会返回缺少 Key 的提示，门店地图为空，其余功能正常。

## 环境版本说明（机房版本过低怎么办）

本工程由 **DevEco Studio 6.1.1** 创建，关键版本配置：

| 配置项 | 位置 | 当前值 |
|--------|------|--------|
| `modelVersion` | `oh-package.json5`、`hvigor/hvigor-config.json5` | `26.0.0` |
| `compatibleSdkVersion` | `build-profile.json5` | `6.1.1(24)` |
| `targetSdkVersion` | `build-profile.json5` | `26.0.0` |

机房常见的是 **DevEco Studio 6.1.0（HarmonyOS 6.1.0(23)）**，直接打开会提示「版本不匹配 / SDK 版本过低」。两种解决办法：

**方案 A（推荐）：安装匹配版本**
在机房电脑安装 DevEco Studio 6.1.1 Release 及 API 24 SDK。只影响本机环境，不修改工程。

**方案 B：把工程降到 6.1.0**
逐个文件改成：

```json5
// oh-package.json5
"modelVersion": "6.1.0"

// hvigor/hvigor-config.json5
"modelVersion": "6.1.0"

// build-profile.json5 -> app.products[0]
"compatibleSdkVersion": "6.1.0(23)",
"targetSdkVersion": "6.1.0(23)",
```

改完后需 **Build → Clean Project** 再同步。若编译报错提示某个 API 在当前 SDK 不存在，说明用到了 6.1.1 才有的接口，此时只能走方案 A。

## 常见问题

| 现象 | 原因 / 解决 |
|------|-------------|
| 打开工程提示版本不匹配 | 见上文「环境版本说明」 |
| 运行报签名错误 | 未配置自动签名，见快速开始第 3 步 |
| 列表空白 / 请求失败 | 服务器不可达。浏览器访问 https://car.ihuhi.xyz/api/cars 确认；模拟器需能上外网 |
| 车辆图片不显示 | 图片地址由后端返回 `/uploads/xxx.png`，客户端用 `resolveImageUrl` 拼成完整 HTTPS 地址，检查是否能直接打开该图片链接 |
| AI 客服无回复 | 线上服务器已配置 Key；若本地跑后端，需自行填写 `ai_config.json` |
| 门店地图空白 | 同上，需配置高德 Key |
| 后台页面样式旧 | 后台已禁止缓存，强制刷新（Ctrl+F5）即可 |

## 接口速查

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/login` | 登录 |
| POST | `/api/register` | 注册 |
| GET | `/api/cars` | 车辆列表 |
| GET | `/api/cars/:id` | 车辆详情 |
| GET | `/api/stores` | 门店列表 |
| POST | `/api/orders` | 创建订单 |
| GET | `/api/orders` | 我的订单 |
| POST | `/api/ai/chat` | AI 客服 |
| POST | `/api/admin/upload` | 后台图片上传 |
| GET | `/api/admin/cars` | 后台车辆管理 |
| GET | `/api/admin/stats` | 后台统计 |

## 说明

- 本项目为课程作业演示用途，后台管理页面未做登录鉴权，请勿用于生产环境。
- 仓库不包含 `backend/node_modules`、`backend/.env` 及含真实密钥的 `ai_config.json`、`map_config.json`，请使用对应的 `.example.json` 模板。
