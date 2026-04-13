# manyoyo-app

MANYOYO 原生 UI 客户端，基于 Flutter 构建，支持 macOS、Windows、iOS、Android。

客户端直接调用 [MANYOYO](https://github.com/xcanwin/manyoyo) 后端 API，使用纯 Flutter 原生 UI 实现登录、会话列表、Agent 对话、终端、文件浏览与配置编辑，不依赖 WebView。

## 依赖

- Flutter SDK ^3.x
- 运行中的 MANYOYO 后端（`manyoyo serve` 或手动启动）

## 构建与运行

```bash
flutter pub get
flutter analyze
flutter test

# 指定后端地址运行
flutter run -d macos --dart-define=MANYOYO_SERVER_URL=http://127.0.0.1:3000
flutter run -d windows --dart-define=MANYOYO_SERVER_URL=http://127.0.0.1:3000
```

## 平台说明

- **macOS / Windows**：直接 `flutter run`，需本机运行 MANYOYO 后端
- **iOS**：需 Xcode 签名配置，真机调试先执行 `flutter devices` 获取设备 ID
- **Android**：局域网访问需在 AndroidManifest 允许 cleartext traffic

## 功能概览

- 登录与服务地址配置
- 会话列表与容器管理
- Agent 流式对话
- WebSocket 终端
- 工作区文件浏览与文本编辑
- MANYOYO 配置文件编辑

## License

Apache 2.0
