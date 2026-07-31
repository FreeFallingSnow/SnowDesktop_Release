# SnowDesktop Lua 组件包 v1

SnowDesktop 将 Lua 组件作为渠道无关的文件夹包运行。布局只保存不可变的
`packageId` 和实例 `id`，不会保存或执行 Lua 文件路径。自有社区、静态目录和
Steam Workshop 只能提供包制品，安装和更新必须进入统一的暂存校验流程。

## 目录与制品

```text
<package>/
  widget.json
  main.lua
  assets/
  modules/
  locales/
  preview.png
  LICENSE
```

发布制品扩展名为 `.snowwidget`，内容是 ZIP32。当前导出器使用标准 ZIP
store method，导入器拒绝加密、data descriptor、ZIP64 和其他压缩 method，
以便在引入经过审计的解压库前保持攻击面可控。

内置包位于 `<exe>\widgets`，逻辑上只读；用户包位于
`<data>\widgets\installed\<id>\<version>`；开发包位于
`<data>\widgets\dev\<id>`。暂存、隔离和迁移备份分别位于 `staging`、
`quarantine` 和 `migrations`。

## 旧散文件迁移

升级时，SnowDesktop 会按旧清单中的官方本地化键识别自带组件，将布局中的旧
文件名映射为新版不可变 UUID，保留原实例 `id` 和以该实例为前缀的存储数据，
并在一次性存储快照成功提交后直接删除旧 `.lua + .widget.json`。临时存储
快照在 Lua 引擎完成合并和原子写回后立即消费，不进入 `migrations`。这个过程
在包管理器初始化时自动完成，不显示迁移向导。

无法确认为官方自带内容的旧散文件一律视为用户组件：保持禁用、不自动改动，
只在组件管理页中由用户明确选择迁移，并将原文件备份到 `migrations`。这样
同名的自制组件也不会仅凭文件名被静默覆盖。

## `widget.json`

必备身份与兼容字段：

- `schemaVersion: 1`
- `id`: 不可变 UUID，在所有发布渠道保持一致
- `slug`: 小写字母、数字和连字符
- `version`: SemVer
- `apiVersion: 1`
- `dataVersion`: 正整数
- `entry`: 包内相对 `.lua` 路径，通常为 `main.lua`
- `minHostVersion`
- `name`、`description`: 英文回退
- `author`、`license`
- `permissions`、`networkDomains`

还可声明尺寸、刷新间隔、BCP-47 本地化目录、预览和设置元数据。v1 不允许
跨包依赖、DLL、可执行文件、包外资源、符号链接、junction 或重解析点。

## 校验限制

- 制品最大 20 MiB，解压后最大 64 MiB
- 最多 512 个文件
- Lua 入口最大 1 MiB
- 预览最大 2 MiB
- 所有路径 canonicalize 后必须仍位于包根目录
- 网络权限只能列出明确 DNS 主机，不能使用 `*`

## 生命周期与来源

`WidgetPackageManager` 负责安装、启停、更新、回滚、卸载、隔离和原子注册表。
同一个包只有一个活动来源。跨 Provider 切换、增加权限或扩大网络域名必须由
调用方传入明确确认，不能静默更新。旧版本保留为 last-known-good 回滚候选。

Provider 通过 `IWidgetPackageSource` 和 `IWidgetPackagePublisher` 接入。
当前包含内置目录、本地开发目录、静态目录与本地静态目录发布器；它们和未来
HTTP/Steam Provider 使用同一 `PackageArtifact`、来源引用和暂存校验。

## 作者工具

```bat
snowwidget validate widgets\my-widget
snowwidget pack widgets\my-widget my-widget.snowwidget
snowwidget publish-local widgets\my-widget D:\widget-catalog
```

校验报告是机器可读 JSON。本地发布命令生成 `catalog.json` 和制品目录，可在
没有服务器或 Steam SDK 的情况下测试发布、消费、升级和回滚。

## 运行时边界

每个实例拥有独立 `lua_State` 和 16 MiB Lua 内存额度。宿主 API 表只读，
实例身份绑定在 Lua registry 中；回调受指令与时间额度限制，并生成 traceback。
定时器、HTTP、通知、宿主控件、图片与字体缓存、实例存储均有数量或容量上限。
存储使用可转义 JSON 和原子替换；损坏文件会隔离而不是被部分解析。
