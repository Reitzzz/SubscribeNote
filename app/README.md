# 订小阅 Android Demo

安装、构建、实现范围与验证边界见 [项目 README](../README.md#android-demo)。

- `lib/domain.dart`：整数金额、月末账期、计费事件与预测。
- `lib/store.dart`：Drift/SQLite 表、事务、历史账单和首次样例。
- `lib/ui.dart`：来自 HTML 的共享视觉组件。
- `lib/pages.dart`、`lib/editor.dart`：各页面及操作表单。
- `lib/main.dart`：Riverpod 与 go_router 入口。

SQL 使用参数绑定；订阅、事件和账单分别存储，载荷是版本化 Dart 模型的 JSON。为本地 Demo 保留 UUID、修改时间、版本、软删除和设备标识；暂未实现同步 outbox 或服务端协议。样例不等于真实账单或实时服务价格。
