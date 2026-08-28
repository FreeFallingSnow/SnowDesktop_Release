# 飘雪桌面（SnowDesktop）

[简体中文](./README.md) | [English](./README.en.md)

一款 Windows 桌面整理美化工具：用 Direct2D 渲染的自定义桌面，替代 Explorer 原生图标，支持多显示器网格布局、可嵌入组件和 Lua 脚本扩展。
## 📦 安装

[![从 Microsoft 获取](https://get.microsoft.com/images/zh-cn%20dark.svg)](https://apps.microsoft.com/detail/9PLLGJVL4LC3)

[Steam 商店（即将推出，可加入愿望单）](https://store.steampowered.com/app/5080330/SnowDesktop/)

[源码仓库](https://github.com/FreeFallingSnow/SnowDesktop)

[发行版仓库](https://github.com/FreeFallingSnow/SnowDesktop_Release)

## ✨ 功能亮点

- 🖥️ **自由桌面布局**：使用可调行列与图标间距的网格整理桌面项目和组件；每台显示器可拥有独立页面和布局，并支持屏幕热插拔及离线页面浏览。
- 🗂️ **桌面整理组件**：
  - **集合**：用可调整大小的容器收纳应用和桌面快捷方式，支持拖入、拖出、排序和重命名，让常用项目按用途各归其位。
  - **集合组**：将多个集合组合成一个带标签页的组件，可搜索集合内容、拖放调整标签顺序，在有限的桌面空间中切换多组工作区。
  - **桌面文件分类**：按文件类型自动归类桌面内容，可切换列表或图标视图，并提供分类标签、搜索、排序、日期分组、框选和拖放操作。
  - **文件夹映射**：将任意文件夹直接映射到桌面，无需移动原文件，即可像使用桌面组件一样浏览、搜索和管理其中内容。
  - **文件组**：把桌面文件分类和多个映射文件夹汇集到同一组件，通过来源与分类两级标签快速切换，减少窗口往返和桌面占用。
- 🚀 **Dock 与悬浮 Dock**：
  - **灵活布局**：Dock 可停靠在屏幕上、下、左、右四边，支持岛式或贴边外观，并可指定在单个或全部显示器上显示。
  - **常用内容集中访问**：可添加应用快捷方式、文件夹栈和集合，显示常用项目，并提供 Windows 入口和快捷搜索；项目可直接拖放添加和排序。
  - **窗口快速切换**：集中展示正在运行的应用，悬停即可查看窗口预览，并可快速激活、最小化或关闭窗口。
  - **自然交互**：支持图标放大、过渡动画和文件夹弹出视图；悬浮 Dock 还可通过快捷键或屏幕边缘手势临时唤起。
- 🔎 **快捷导航**：通过快捷键搜索桌面项目、应用和 Everything 文件结果，并按桌面、映射及 Dock 等来源快速浏览和启动。
- 🧩 **Lua 组件平台**：
  - **组件管理**：支持组件包的安装、启停、更新、回滚和离线目录。
  - **内置组件**：提供模拟与数字时钟、月历、日程、提醒、系统监控、媒体控制、便签、番茄钟、RSS 阅读器和快速启动等实用组件。
- 🎨 **外观个性化**：提供深浅色主题、毛玻璃与亚克力背景、组件样式、Dock 外观以及动态任务栏等设置。
- 💾 **备份与数据迁移**：可完整备份和恢复布局、设置、组件包及组件数据，并在不同发布渠道或数据目录之间迁移。

## 🛠️ 构建

依赖：CMake 3.24+、Visual Studio 2022（“使用 C++ 的桌面开发”工作负载）、
Windows 10/11 SDK 10.0.19041.0 或更高版本。NuGet 会按项目固定版本还原
Microsoft Windows App SDK 2.4.0 和 Microsoft.Windows.CppWinRT 3.0.260818.1，
无需在开发机或目标机器预装 Windows App SDK Runtime。

```bat
.\scripts\build.bat
```

默认构建不会终止 SnowDesktop 或重启 Explorer。如果任务栏 Hook DLL 正被占用，
预检会在编译前停止并提示。请先正常退出 SnowDesktop；需要自动解除占用时可使用
`.\scripts\build.bat --reload-shell`，该参数会终止 SnowDesktop 并短暂重启 Explorer。

## 🧱 技术栈

- C++20 / MSVC
- WinUI 3 / Windows App SDK 2.4.0（设置中心，Win32 XAML Island）
- Direct2D + Direct3D 11 + DirectComposition
- Dear ImGui（仅创意工坊管理器）
- Lua 5.4（脚本引擎）
- Fluent System Icons Regular（现代右键菜单与组件菜单图标）
- Font Awesome 6 Free（组件兼容图标）
- WinHTTP（Lua HTTP 运行时）

## 📄 许可证

SnowDesktop 核心代码采用 GNU General Public License v3.0，详见 [LICENSE](./LICENSE)。
仓库中包含的第三方组件及其版权和许可信息，统一记录在
[THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)。
发行包会在 `licenses/` 目录中随附所分发第三方组件的完整许可证与声明文件。

独立的 `steam_bridge/` 创意工坊桥接程序采用 MIT 许可证，详见
[steam_bridge/LICENSE](./steam_bridge/LICENSE)。Steamworks SDK 本身不包含在本仓库内，
也不适用上述 GPL 或 MIT 许可证。
