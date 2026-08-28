# SnowDesktop Lua 组件 API v2

本文档描述当前宿主已经实现并放入 API v2 沙箱的接口。清单中保留的权限名或
路线图能力不代表组件已经可以调用它们。可在运行时使用
`widget.apiInfo()`、`widget.hasFeature(id)` 和 `system.capabilities()` 探测能力。
作者工具的 `snowwidget capabilities` 协议 v2 将可执行契约明确列为
`executableSchemaVersions:[2]` / `executableApiVersions:[2]`。宿主、校验、预览和打包
只接受 schema/API v2。

编辑器类型定义位于 `library/snowdesktop-v2.lua`，其函数签名是本文档的配套
机器可读契约。

运行 `snowwidget api-contract` 可获得当前沙箱完整的宿主 Lua 函数目录。导出按库列出
`qualifiedName`、`sinceApi`、`untilApi` 和函数级 `requiredPermission`，同时给出沙箱中
允许使用的 Lua 标准库与宿主库集合。桌面运行时和该命令由同一个注册清单生成；作者工具应先
用它确定函数及版本是否存在，再使用 `library/snowdesktop-v2.lua` 获取参数与返回值类型。

运行 `snowwidget lint <组件目录>` 可在启动组件前先调用 Lua 编译器检查语法，再静态检查源码。
它从同一宿主 API、系统
能力和视图节点目录识别不存在或版本不匹配的调用，核对字面量 `data.subscribe`/`task.start`
能力所需权限是否已经由 manifest 必选或可选声明，并拒绝 API v2 沙箱没有的 `require/os/io/debug/
package/coroutine`。对于使用字面量属性表的声明式节点，它还检查缺失、空或重复的字面量 `key`，
并警告明显的硬编码 `text/label/title/placeholder/alt` 等界面文案。结果是带文件、行号、稳定
问题码和错误/警告计数的 JSON；语法失败使用 `lua.syntax` 并保留编译器行号，动态拼装的调用、
能力名或属性表仍由运行时最终校验。

运行 `snowwidget test <组件目录>` 可执行包内 `tests/` 下的 Lua 测试文件。每个文件必须返回
`{ ["测试名"] = function() ... end }`，函数无返回值/返回 true 即通过，返回 false 或抛错即失败。
每个文件使用独立的 16 MiB Lua 状态和宿主相同的指令/时间上限，只开放基础纯函数、string、
table、math、utf8 以及仅能读取包内 `modules/*.lua` 的 `module.require`；不注册网络、文件、
Shell、系统数据、存储或其他副作用 API。命令输出文件数、用例数、通过/失败数、稳定问题码和
有界错误文本 JSON。它适合纯逻辑与模块测试；完整 view/宿主 mock 场景继续由 preview 工具负责。

运行 `snowwidget preview <组件目录> <输出.png>` 会先复用包校验器，再启动真实 SnowDesktop
预览宿主，以 `WidgetEngine::InitPreview` 注册完整 API v2 沙箱，执行入口、生命周期和 render/view，
通过离屏 D2D/WIC 输出 PNG。它使用隔离的 manifest `previewData.storage` 覆盖层，不写实例持久化
存储；`--storage key=value` 可重复覆盖预览值，`--columns/--rows` 必须落在清单尺寸范围内，
`--dpi` 支持 96–480，`--locale` 选择宿主已安装语言。`--appearance` 可为
`dark/light/glass-dark/glass-light/acrylic-dark/acrylic-light`；旧参数 `--theme dark/light`
继续作为普通深/浅外观的简写，但不能和 `--appearance` 同时使用。生成最终打包预览时应通过
`--background <图片文件>` 显式选择背景；该图片只参与合成，不会被 `pack` 自动加入组件包。
未指定时使用中性的兼容背景。输出 PNG 始终包含背景、解析后的普通/毛玻璃/亚克力材质层和组件
内容，像素完全不透明；组件自定义材质
优先，`followPersonalization` 则回到所选宿主外观。应先用 `preview` 生成清单声明的最终预览图，
再运行 `pack`；`pack` 只校验和归档现有预览文件，不会启动宿主或改写源码目录。
`--data-state` 可为 `ready/empty/loading/error/stale/permission-denied`，用于让全部预览数据订阅
返回对应的确定性包络；`empty` 保留 `available=true` 但使用空/零值，`error` 返回
`providerUnavailable`，拒权返回 `permissionDenied`；包络时间戳与 `time.now()` 共用固定预览
时钟，stale 时间固定落在两个请求采样周期之前。以上环境在 Lua `setup()` 前注入，预览
显示器摘要固定标记为 unavailable；accent、无障碍默认值、region、UTC 时区和输入语言也由
所选 locale 的确定性预览环境提供，不读取开发机对应设置。命令返回包含稳定 `stage`、最终像素
尺寸、栅格尺寸、DPI、locale、基础 theme、appearance、dataState 和 background 的 JSON。复制到
SnowDesktop 安装目录外的 CLI 可用 `--host <SnowDesktop.exe>` 或 `SNOWDESKTOP_HOST` 指定宿主。

运行 `snowwidget permissions <组件目录>` 可从宿主同一权限 descriptor、公共函数目录和 system
topic/task 目录生成机器可读报告。每个必选/可选声明包含风险类别、是否需要用户同意以及受该权限
保护的函数、数据或任务；网络段单独列出精确域名、Internet 与 local 范围，并给出与运行时授权
状态使用同一算法的 scope fingerprint。该命令只分析包声明，不读取或修改用户授权。

运行 `snowwidget view-contract` 可获得宿主当前公开的声明式视图 JSON 契约。顶层
`schemaVersion=3` 版本化该导出格式，`apiVersion` 表示组件 API；`nodes`、`properties` 和
`events` 分别登记节点适用属性与逐节点默认值、属性类型/枚举/范围/影响域，以及事件 payload
类别。属性策略为 `closed-world`，每个节点的 `properties` 与 `prohibitedProperties` 明确划分
全部公共属性；未知字段和节点禁止字段都不会被静默忽略。`limits` 直接导出宿主当前使用的
全树、文本、资源、集合与虚拟化额度；`transitions`
登记更新/入退场动画允许字段、时长、easing 及 preview/reducedMotion 的静态终点策略；
每个属性的 `transitionEffects` 进一步标出该字段变化可驱动 visual、transform 或 layout
过渡。`directionality` 固定 auto/ltr/rtl 的解析、start/end 对齐以及声明顺序不随视觉方向反转；
`validation` 则说明未知/禁止/错误值会原子拒绝整棵候选树并保留上一棵成功树。
视图链路错误统一写成 `[code] message`；`diagnosticCodes` 导出稳定的阶段码，例如
`view.parse`、`view.layout` 和 `view.hostControls`。工具可以依赖阶段码分类，但不应依赖后面的
人类可读说明逐字不变。
`preview` 表明预览复用宿主校验和渲染、使用隔离存储覆盖层。作者工具应调用该命令，不要复制
维护另一份节点、属性、动画或额度白名单。

运行 `snowwidget system-contract` 可离线获得与 `system.capabilities()` 同源的系统能力目录。
其中 `functions`、`dataTopics`、`tasks` 分别公开 feature 与权限；同步函数公开有序
`parameters[{name,type,optional}]` 和 `resultType`。数据主题还公开可见/隐藏采样
间隔、空闲释放、风险属性以及对应的 LuaLS `optionsType/valueType`，任务公开可信手势要求、
每实例并发上限和 `argumentsType/resultType`。无参数任务的 `argumentsType` 为 null；类型名均指向
随工具分发的 `library/snowdesktop-v2.lua`，作者工具不应再靠任务名猜测结构。该导出只描述系统能力，
不会读取当前组件的授权状态；实例是否已授权仍应在运行时查询 `system.capabilities(id)`。

## 入口契约

`main.lua` 必须返回 `widget.define({...})` 的结果，并且必须且只能提供
`render` 或 `view`。宿主会把当前上下文和实例 model 传给所选回调：

```lua
local function setup(context)
    schedule.every("refresh", 60000)
    return { createdOn = context.surface }
end

local function render(context, model)
    draw.text(layout.cu(12), layout.cu(12),
        "Hello from " .. model.createdOn)
end

local function dispose(context, model, reason)
    -- Optional. Host resources are released automatically after this returns.
end

local function event(context, model, value)
    if value.kind == "schedule" and value.id == "refresh" then
        state.set("lastRefresh", time.monotonic())
    end
end

return widget.define({
    name = l10n.tr("lua_widget.example.name"),
    setup = setup,
    render = render,
    event = event,
    dispose = dispose,
})
```

`setup(context)` 最多执行一次，返回值作为实例 model 传给每次 `render(context,
model)`、`panel(context, model)`、`event(context, model, event)` 和最终的 `dispose(context, model,
reason)`。没有 `setup` 时 model 为
`nil`；没有 `dispose` 时宿主仍会自动回收实例资源。`reason` 当前可能是
`unload`、`hotReload` 或 `shutdown`。setup 失败时新 VM 不会替换热重载前的可用
VM。

event 覆盖宿主 surface 级事件：`visibility`、`resize`、`timer`、
`schedule`、`action`、`selection`、`environment`、`panel`、`dialog`、`popover`、
`data.change` 和
`task.complete`。
使用 `render`/即时绘制的 surface 还会收到原始 `pointer` 生命周期事件，其中包含
`action`、`surface`、`x/y`、`button`、`delta`，命中 region 时还包含 `targetKey`。
声明式 `view` surface 不投递这条通用高频事件；作者应在节点 `events.pointer*` 中显式
绑定所需动作，未绑定动作的 hover/pressed 纯视觉状态由宿主直接重绘已提交 scene，
不会同步进入 Lua。schedule 事件包含 `id`、UTC epoch 毫秒 `now`、
`missed` 和 `coalesced`。
region 绑定的 hover、pressed、click、doubleClick、wheel 和菜单选择统一以
`event.kind == "action"` 投递。
探测 `view.pointer.events` 后，声明式节点还可显式观察高频 `pointerMove` 和 `wheel`；
宿主滚动消费 wheel 时仍先更新滚动偏移并投递对应节点动作，动作不能取消滚动。
事件驱动的数据 topic 发生变更时，持有对应订阅的组件收到 `data.change`，其中包含
`topic/revision`；组件可在该事件中重建依赖日期范围等参数的订阅。

`menu(context, model, request)` 同时用于即时绘制 region 和声明式节点的独立右键菜单。
不要定义已移除的全局回调；入口必须返回 v2 描述符。

## 已实现能力

### 基础 feature 探测索引

以下基础能力也有稳定 feature ID，组件需要按版本降级时应使用
`widget.hasFeature(id)` 或 `system.capabilities(id)`，不要通过函数是否为 `nil` 猜测宿主版本：

- `system.environment`：`system.info/capabilities`；`time.basic`：`time.now/monotonic`；
  `time.calendar`：`time.parts/format/add/compare`；
- `layout.relativeUnits`：与声明式 View Tree 根内容框同坐标系的
  `layout.contentWidth/contentHeight/vw/vh/vmin/vmax`，以及
  `widget.context().layoutSize`；
- `module.package`：安全包内模块；`resource.package`：包内图片、字体和资源状态；
- `state.transient`：仅存活于当前实例 VM 的瞬态状态；`schedule.visibility`：计划的
  `whenHidden=pause|throttle|continue` 生命周期；
- `slots.mutation.userGesture`：binding/collection 的选择、清除、移除、撤销与重做仍要求
  当前可信用户动作；
- `widget.panel`、`widget.dialog`、`widget.popover`：对应宿主 surface 的打开和关闭能力；
  surface 内返回声明式树时还应分别探测 `view.surface.panel/dialog/popover`。

### `widget`

- `widget.define(definition)`：校验并返回 v2 描述符。`render` 与 `view` 必须二选一，可选
  `setup`、`panel`、`dialog`、`popover`、`event`、`menu` 和 `dispose`。`panel` 只在
  `widget.openPanel` 打开的宿主辅助面板中执行，收到的 `context.surface` 为
  `panel`。探测 `view.surface.panel` 后，回调可返回一棵声明式视图；返回 `nil`
  则保留即时绘制。面板中的声明式输入与 `control.textInput/textArea` 均复用宿主
  输入代理和 storage-bound 契约。
  `dialog` 由 `widget.openDialog` 打开并收到 `context.surface="dialog"`；它复用同一套
  声明式/即时渲染、滚动、输入和 action 管线，但由宿主居中显示、绘制遮罩并隔离桌面输入。
  `popover` 由可信桌面手势调用 `widget.openPopover`，并锚定上一棵成功桌面 scene 中的
  稳定 `anchorKey`；回调收到 `context.surface="popover"`。
  `showTitle=true` 会启用宿主移动底栏并显示组件标题；默认值 `false` 表示无底栏，悬停时
  由宿主在左下角显示紧凑移动手柄、右下角显示缩放手柄，其余桌面 surface 均由组件内容和
  指针交互使用。
  `bottomBarHover` 只控制已启用底栏是否仅悬停显示。
- `widget.apiInfo()`：返回当前 API 版本、支持版本和 feature ID。
- `widget.hasFeature(id)`：探测 feature。
- `widget.context()`：返回逻辑/像素尺寸、DPI、网格跨度、显示器范围、主题、
  辅助功能、语言区域、时区、可见/预览/选择状态和 surface。
- `widget.info()`、`widget.theme()`：兼容的实例与外观快照。
- `widget.hasPermission(name)`：查询当前实例已授予权限。
- `widget.setTitle(text)`、`widget.invalidate()`、`widget.log(level, text)`。
- v2 不暴露旧 `widget.setTimer/cancelTimer`；周期、延迟和绝对时间调度统一使用
  `schedule.every/after/at/timeline`。
- `widget.openSettings()`、`widget.openPanel(options)`、`widget.closePanel()`、
  `widget.openDialog(options)`、`widget.closeDialog()`。dialog 默认允许 Escape 关闭、
  不允许点击遮罩关闭；可用 `dismissOnEscape` 与 `dismissOnOutside` 显式调整。它不使用
  阻塞式系统模态循环。
- `widget.openPopover(options)`、`widget.closePopover()`：`anchorKey` 必填且必须属于当前
  desktop surface 中已启用、可见命中的元素。调用只在直接可信桌面手势中成功并返回 true；
  支持 `auto/top/bottom/left/right/topStart/topEnd/bottomStart/bottomEnd`，auto 会按当前
  工作区空间选择并最终钳制。标题省略时使用无标题栏紧凑 chrome；默认点击外部或 Escape 关闭。

### `view.tree.core` 声明式视图

当前过渡 feature `view.tree.core` 提供 `view.box/row/column/stack/text/image/button/icon/
iconButton/shape/progressBar/progressRing/spacer`；额外的 `view.dataSeries` feature 提供
`sparkline/lineChart/barChart/waveform/spectrum`，`view.statusVisuals` 提供
`badge/divider/meter`，`view.selectionControls` 提供 `toggle/checkbox`，
`view.actionControls` 提供 `link/radioGroup/slider`，
`view.inputControls` 一次提供 `textInput/textArea/searchBox/numberInput/select`，
`view.keyboardNavigation.basic` 提供桌面与活动 panel surface 的通用宿主键盘焦点与激活，
`view.keyboard.events` 提供聚焦元素不可取消的按下/释放观察事件，
`view.keyboard.accessKey` 提供宿主管理的组件内 Alt 访问键和快捷键语义文本，
`view.pointer.events` 提供显式的声明式 pointerMove/wheel 观察，
`view.focus.request` 将可信手势焦点请求扩展到任意可聚焦声明式元素，
`view.flex.layout` 提供 row/column 主轴切换、换行与多行交叉轴对齐，
`view.flex.sizing` 提供线性布局的 basis/grow/shrink 尺寸分配，
`view.text.flow` 提供文本块的换行、行数、溢出和垂直对齐，
`view.text.typography` 提供字体粗细、字形、行高和字距，
`view.text.locale` 提供 BCP 47 locale 与双向文本基准方向，
`view.theme.tokens` 提供宿主解析的声明式语义颜色，
`view.tooltip` 提供宿主管理的字符串元素提示，`view.tooltip.rich` 提供有界标题+正文描述，
`view.layout.overflow` 提供容器后代裁剪，`view.shadow` 提供有界宿主阴影，
`view.image.tint` 提供保留图片 alpha 的 RGB 着色，
`view.transform.basic` 提供布局后的平移、统一缩放和变换原点，
`view.transform.affine` 提供非统一缩放、旋转、斜切和精确逆矩阵命中，
`view.transition.visual` 提供宿主驱动的有限视觉样式过渡，
`view.transition.transform` 将该过渡扩展到声明式 transform，
`view.state.selected` 提供通用受控选中样式，`view.checkbox.indeterminate` 提供复选框混合态，
`view.progress.indeterminate` 提供宿主驱动的不确定进度条与进度环，
`view.state.visibility` 明确区分参与布局的隐藏状态与完全折叠状态，
`view.input.selection` 提供文本输入的受控选区，`view.input.required` 提供表单必填语义，
`view.keyboardNavigation.order` 提供显式焦点参与和顺序，
`view.grid.uniform` 提供基础 `grid`，`view.grid.placement` 提供显式格位与跨度，
`view.grid.tracks` 提供受限 fixed/auto/fr/minmax 列轨和行轨，
`view.flow.wrap` 提供横向换行 `flow`，`view.identity.diagnostics` 提供开发者场景标识。
`view.scroll` 提供宿主滚动视口，`view.scroll.initialTarget` 提供首次声明式定位，
`view.collection.basic` 提供基础集合，
`view.collection.orientation` 提供普通 list 横纵方向，
`view.collection.virtual.orientation` 提供 fixed/variable virtualList 横向主轴，
`view.collection.selection` 提供受控单选/多选，`view.collection.stickyHeaders` 提供 eager 纵向分组标题，
`view.collection.contentStates` 提供空态/加载态，
`view.collection.virtual` 提供固定行高虚拟集合与可见范围查询，
`view.collection.virtual.stickyHeaders` 提供 virtualList 的全局分组索引与窗口外活动标题，
`view.collection.virtual.variableExtent` 为 virtualList 增加宿主测量的可变主轴尺寸；
`view.styledText.basic` 提供有界样式 span，`view.styledText.inlineIcons` 提供宿主图标字体 span，
`view.styledText.actions` 提供精确行内交互目标，
`view.monthCalendar` 提供受控月历日期网格，
`view.logicalSlots` 提供与 manifest 宿主管理槽位严格对应的 `slotSurface/slotItem`，
`view.logicalSlots.dropStyle` 提供主题感知、宿主有界的合法拖放目标样式，
`view.logicalSlots.emptyContent` 提供与宿主空快照绑定的单节点槽位空态，
`view.referenceIcon` 提供只接收实例自有 opaque ref 的宿主图标节点。

探测 `view.identity.diagnostics` 后，任意声明式节点可增加可选 `debugName` 和 `testId`。
`debugName` 是 1–256 UTF-8 字节且不含控制字符的开发者可读名称；`testId` 是 1–128 字节、只接受 ASCII
字母数字及 `._:-/` 的稳定测试选择器。两者只进入设置页“复制诊断”导出的 desktop 与辅助
surface 场景快照，快照同时包含节点类型、全局 key、树深度和最终布局 frame。它们不参与
diff、布局、绘制、命中、焦点、action target 或 UIA AutomationId；行为身份仍必须使用全局唯一
`key`。省略字段不产生额外输出，显式空字符串会拒绝本次树提交。

`view.layout.constraints` 为所有节点提供 `minWidth/maxWidth/minHeight/maxHeight` 数值约束、
`aspectRatio` 和统一 `margin`。尺寸约束与外边距是 0–4096 的有限逻辑单位，同一轴的最小值不得大于最大值；
宽高比表示 `width / height`，范围 0.01–100。约束会参与固有尺寸、fill/flex 分配以及
grid/flow/scroll 子项布局，而不是只在绘制时裁切；与宽高比不可能同时满足的最小/最大约束，
或不符合宽高比的双固定尺寸会拒绝整棵新树并保留上一棵有效树。
`margin` 由父布局保留在节点 frame 之外，参与线性分配、grid cell、flow 换行、stack inset、
scroll content extent 和虚拟 item extent；同级间的公共间隔仍优先使用父容器 `gap`。
`view.layout.edgeInsets` 将 `margin/padding` 扩展为数值或边距表。数值表示四边相同；
`{ horizontal = 12, vertical = 6 }` 分别设置左右和上下，`{ top, right, bottom, left }`
可按边设置。轴值会先展开，显式边值随后覆盖对应轴；每个已声明值仍须位于 0–4096。
不接受 CSS shorthand 字符串、数组或未知字段。方向值会实际参与固有尺寸、布局、滚动范围、
文本/图片内容区和宿主输入控件命中，而不是只影响背景绘制。
`view.positioning.basic` 为 stack 的直接子节点提供
`offset = { x?, y? }`（每轴 -4096–4096）和 `zIndex`（-1024–1024）。offset 只移动
视觉 frame，不占用或重新分配布局空间；zIndex 只决定稳定绘制顺序和重叠区域命中顺序，
相同值仍保持声明顺序。其他父容器不得使用非零 offset/zIndex，语义与键盘顺序仍保持原声明顺序。
容器可用 `clip = true` 将后代绘制、指针命中、宿主输入和语义可见范围裁剪到自身 content rect；
叶节点使用 clip 会拒绝整棵新树。当前不支持任意裁剪路径或通过 offset 脱离 stack 建立绝对布局。
新组件应在探测 `view.layout.overflow` 后使用 `overflow="visible"|"clip"`；`clip=true`
仅作为兼容写法保留，同时声明两者时必须表达相同结果。`shadow={color,blur,offsetX,offsetY,alpha}`
由宿主最多 16 层受控衰减绘制，blur 限制为 0 到 64，不参与布局或扩大命中区；对应 feature
为 `view.shadow`。图片在探测 `view.image.tint` 后可声明 `tint=0xRRGGBB`，宿主替换 RGB、
保留源 alpha，并继续遵循 fit、alignment、interpolation 和节点 opacity。

探测 `view.theme.tokens` 后，所有声明式 RGB 颜色槽都可用下列字符串代替
`0xRRGGBB`：

```lua
style = {
    background = "surface",
    foreground = "textPrimary",
    borderColor = "border",
}
hoverStyle = { background = "surfaceVariant" }
```

稳定 Token 为 `widgetBackground/surface/surfaceVariant`、
`textPrimary/textSecondary/textDisabled`、`border/borderStrong`、
`systemAccent/accentText` 和 `info/success/warning/error`。它们适用于
`style` 及全部状态样式的 `background/foreground/borderColor`、styledText span 的
`foreground/hoverForeground/pressedForeground`、`shadow.color` 和图片 `tint`。
宿主在状态样式合并之后、transition 之前按当前组件主题和系统强调色解析，因此 Token
之间的状态变化仍可由 `view.transition.visual` 插值。高对比度模式改用 Windows 系统窗口、
文本、选中和禁用色；Token 不会把系统颜色数值暴露为可持久化品牌色，也不适用于即时绘制 API。
该能力无需权限。未知字符串会拒绝整棵新树并保留上一棵成功树。

探测 `view.transform.basic` 后，任意节点可声明
`transform={translateX?,translateY?,scale?,originX?,originY?}`。平移每轴限制在
-4096–4096，统一正数 scale 限制为 0.05–8，归一化原点限制为 0–1；嵌套累计缩放必须保持
在 1/64–64。变换在布局后应用并由后代继承，绘制、命中、宿主输入、裁剪和 UIA 边界使用
同一结果。探测 `view.transform.affine` 后还可加入 `scaleX/scaleY` 正数乘数、
`rotate`（-360–360 度）以及 `skewX/skewY`（各 -80–80 度）。局部顺序固定为
scale → skew → rotate → translate；每个最终局部缩放轴仍须保持 0.05–8，嵌套仿射矩阵的最小/最大伸缩轴
仍限制为 1/64–64。旋转命中使用逆矩阵恢复原始 rect/roundedRect/circle 或文本片段，而 UIA
继续暴露变换后的轴对齐包围框；slider 值按旋转后的真实轨道投影。宿主管理的输入代理、
scroll viewport 和逻辑槽位只接受正向轴对齐变换，带裁剪的节点也不接受非轴对齐矩阵，
避免用不精确 AABB 冒充可操作或裁剪区域。透视变换不属于二维组件 scene API。

探测 `view.transition.visual` 后，任意节点可声明：

```lua
transition = {
    durationMs = 120,
    easing = "easeOut",
    properties = { "background", "opacity", "transform" },
}
```

`properties` 必须包含 1–4 个不重复的白名单名称；`durationMs` 默认为 120、范围为
1–2000，`easing` 默认为 `easeOut`，也可使用 `linear/easeIn/easeInOut`。稳定 key 节点的
解析后样式目标变化时，宿主插值 background/foreground/borderColor/opacity；颜色只有旧值和
新值都显式存在时才插值，颜色出现或消失会直接切换，未声明 opacity 按 1 参与插值。
探测 `view.transition.transform` 后，`properties` 还可包含 `transform`：宿主逐项插值平移、
缩放、原点和斜切，并沿最短角度路径插值旋转；未声明 transform 按单位变换参与过渡。
transform 插值只改变呈现矩阵，命中、宿主控件和 UIA 几何会在新 scene 提交时原子切换到
目标矩阵，不会暴露逐帧中间几何。

探测 `view.transition.layout` 后，`properties` 还可包含 `layout`。同一稳定 key 节点在父布局内的
相对位置或尺寸变化时，宿主用呈现矩阵从上一帧布局插值到新布局；父子都声明时按层级组合，
而滚动偏移与虚拟窗口平移不会被误判为布局变化。插值帧不重新求值布局，命中、裁剪、宿主输入
和 UIA 几何仍在 scene 提交时原子使用目标布局，因此动画中的视觉位置不扩大可点击区域。

探测 `view.transition.enter` 后，任意节点还可单独声明：

```lua
enterTransition = {
    durationMs = 160,
    easing = "easeOut",
    opacity = 0,
    transform = { scale = 0.92, translateY = 6 },
}
```

`opacity` 与 `transform` 至少提供一个；它们表示入场起点，终点仍是节点正常解析出的目标样式和
transform。transform 是完整起始变换，省略字段使用单位变换默认值，不从目标 transform 逐字段
继承。首次整棵 scene 提交不会让全部节点集体入场；只有宿主已经成功提交过该 surface 后首次
出现的新稳定 key 才执行。预览、计时器不可用或 `reducedMotion` 开启时直接显示终点。入场只影响
呈现，节点的命中、宿主控件和 UIA 从 scene 提交起即使用目标几何。

探测 `view.transition.exit` 后，同一描述结构也可用于 `exitTransition`，其中 opacity/transform
表示退场终点。新 scene 不再包含稳定 key 时，宿主从上一呈现状态创建不可交互的旧子树快照，
保留旧父变换和裁剪并插值到终点；新 scene 的命中、焦点、宿主控件和 UIA 会立即提交，快照不会
继续接收动作、右键菜单或可信手势。移除的父节点声明退场时由它承载仍被移除的后代，已经在新
scene 中复用的后代 key 会从快照剔除；没有退场的祖先不会阻止更深层节点使用自己的声明。
同一 surface 最多保留 512 个快照节点，快速连续更新超过额度时最早的退场直接结束；key 在后续
scene 重新出现会取消同 key 的旧快照。预览、无计时器或 `reducedMotion` 下不保留快照。

阴影参数、圆角和边框宽度仍不能作为 transition 插值属性；出现/移除期间只开放 opacity 与
完整 transform 端点。

桌面与 panel/dialog/popover 各自维护过渡状态，插值帧只重绘上一棵成功提交的 scene tree，
不会每帧重新调用 Lua `view()`。未绑定节点 pointer action 的 hover/pressed 状态变化也走
同一条已提交 scene 快速重绘路径；绑定动作时先向 `event.kind="action"` 投递精确节点事件，
再由组件提交下一棵树。目标样式来自新 scene 或宿主 hover/pressed/focus 等状态；
预览、宿主计时器不可用或系统开启“减少动态效果”时直接显示最终样式。隐藏、关闭 surface、
热重载和卸载会清理待执行过渡。该能力不要求权限，也不能用于绕过 reducedMotion。
探测 `view.state.visibility` 后，节点可声明 `visibility="visible"|"hidden"|"collapsed"`。
`hidden` 仍参与父布局，但整棵子树不绘制、不可命中、不创建宿主输入，也不进入 UI Automation；
`collapsed` 则不占用布局空间。旧 `visible=false` 固定等价于 collapsed，`visible=true` 等价于 visible。
同时声明两种写法时必须一致，且 `hidden` 不得与旧布尔写法混用。`opacity=0` 只改变绘制透明度，
节点仍可交互，不能用作隐藏状态。
每次 `view(context, model)` 返回一棵完整树；所有节点必须提供全树唯一、1–128 字节的
稳定 `key`。宿主先完整解析、校验和布局，再原子替换上一棵成功树；回调或校验失败时
继续显示上一棵树，不留下半棵树或空白交互区。

```lua
local function buildView(context, model)
    return view.column({
        key = "root",
        width = "fill",
        height = "fill",
        padding = 12,
        gap = 8,
        alignItems = "stretch",
        justifyContent = "center",
        children = {
            view.text({
                key = "status",
                text = model.status,
                width = "fill",
                textAlign = "center",
                fontSize = 18,
                style = { foreground = 0xFFFFFF },
            }),
            view.button({
                key = "refresh",
                label = l10n.tr("lua_widget.example.refresh"),
                height = 36,
                action = { id = "refresh" },
                events = {
                    contextMenu = { id = "refresh.menu" },
                },
                style = { background = 0x365F86, cornerRadius = 8 },
                hoverStyle = { background = 0x477FB5 },
                pressedStyle = { background = 0x315F8F },
            }),
        },
    })
end
```

尺寸接受有限非负数字、`auto` 或 `fill`；线性布局支持数值或四边结构的 `padding`、`gap`、
`flexBasis/flexGrow/flexShrink`、`alignItems/alignSelf` 和 `justifyContent`。`row/column`
还可在探测 `view.flex.layout` 后使用
`flexDirection="row"|"rowReverse"|"column"|"columnReverse"` 覆盖构造器默认主轴，
以 `flexWrap="wrap"|"wrapReverse"` 按可用主轴空间分行，并用
`alignContent="start"|"center"|"end"|"stretch"|"spaceBetween"|"spaceAround"|"spaceEvenly"`
分配多行交叉轴空间。`justifyContent` 同样支持三种 space 分布。每行独立执行 grow/shrink
和 justify；reverse 只反转布局主轴或交叉轴起点，声明、绘制、命中、键盘和 UIA 顺序仍保持
组件给出的逻辑顺序。`flexBasis`
接受 0–4096 数值或 `auto`，先确定主轴基础外尺寸；正剩余空间按非负 `flexGrow` 分配，
空间不足时按 `flexShrink × basis` 收缩并重新分配触及 `minWidth/minHeight` 后的溢出。
`flexShrink` 默认 1，设为 0 可保持基础尺寸；`fill` 在未写 grow 时继续隐含 grow=1。
上述完整行为需探测 `view.flex.sizing`。文本支持 `fontSize`、`bold`、
`textAlign`；基础样式支持 RGB 前景/背景/边框、边框宽度、圆角、0–1 opacity 及
hover/pressed 覆盖。按钮 `action` 是 click 简写；events 还支持 pointer enter/leave/
down/up、doubleClick 和 contextMenu，动作通过 `event.kind == "action"` 投递。
`contextMenu` 动作默认 `scope="element"`：命中后菜单只显示该元素返回的操作，不混入组件
设置、悬浮和移除等总菜单，但宿主会固定追加“打开组件面板”入口，确保组件总菜单始终可达。
覆盖整张组件表面的菜单应显式写
`{ id="component.menu", scope="component" }`，其返回项会附加到组件总菜单。

事件名称和节点适用性由宿主公共契约固定，未知名称会拒绝整棵 scene，而不是被静默忽略：

| 事件 | 可声明节点 | 主要负载 |
|---|---|---|
| `pointerEnter/Leave/Down/Move/Up` | 任意节点 | `targetKey`、局部 `x/y`、指针按钮与修饰键；move 需 `view.pointer.events` |
| `click/doubleClick/contextMenu` | 任意节点 | `targetKey`、`source`、点击次数或菜单目标 |
| `wheel` | 任意节点 | `targetKey`、`delta`、修饰键；需 `view.pointer.events` |
| `keyDown/keyUp` | 运行时实际可聚焦的节点 | `key`、`virtualKey`、`repeat`、修饰键；需 `view.keyboard.events` |
| `change` | 输入、选择、滑块、日历和声明了 selection 的集合 | 原值及宿主建议的新值/选择；组件仍负责写回 model |
| `selectionChange` | `textInput/textArea/searchBox` | UTF-8 字节边界的 `previousSelection/selection` |
| `focus/blur/submit` | `textInput/textArea/searchBox/numberInput` | `targetKey`、`source`；submit 同时携带当前文本或数值 |
| `scrollEnd` | `scroll/virtualList/virtualGrid` | `targetKey`、`source` 与已提交的滚动状态；需 `view.scroll.events` |

表中“任意节点”只表示类型级适用性；事件仍受可见、命中、enabled、焦点、feature probe 和
可信手势规则约束。例如没有实际焦点的节点不会收到 key 事件，selectionMode 为 none 的集合也
不会产生 change。所有事件动作继续使用 `SnowInteractionAction`，不能保存 Lua 闭包或取消宿主默认行为。

探测 `view.text.flow` 后，普通 `text`、按钮/链接等 label 节点和 `styledText` 可使用
`textWrap="noWrap|wrap"`、`maxLines=0..64`、`overflowText="clip|ellipsis"` 和
`verticalAlign="start|center|end"`。普通文本/label 默认 noWrap+ellipsis，styledText 为保持
多段正文语义默认 wrap+clip；两者默认垂直居中。宿主在同一个 DirectWrite layout 中应用
换行、行数高度门限、字符级省略和文本块偏移，最终绘制仍受节点 frame 裁剪。

探测 `view.text.typography` 后，上述文本与 label 节点还可使用 100–900、步长 100 的
`fontWeight`、`fontStyle="normal|italic"`、1–1024 的统一 `lineHeight` 和 -64–256 的
`letterSpacing`。显式 fontWeight 优先于兼容属性 `bold`；lineHeight 同时参与固有高度和
DirectWrite 行距，letterSpacing 同时参与近似固有宽度与 TextLayout1 字符间距。该 feature
不改变宿主文本编辑器的输入、选择或 IME 度量，输入控件排版将在对应控件契约中单独开放。

探测 `view.text.locale` 后，text/styledText、输入、select 和带文字标签的节点可使用
`locale` 与 `textDirection="auto|ltr|rtl"`。locale 必须是最长 85 字节、以连字符分隔的
BCP 47 标签；空值继承宿主语言。auto 先按首个强方向字符确定段落方向，没有强字符时再按
locale 决定。LTR/RTL 会同时影响 DirectWrite shaping、start/end 对齐、select 指示器、
radio/checkbox/toggle 的标签与控件相对位置；方向不会反转声明、Tab 或 UIA 子节点顺序。

探测 `view.tooltip` 后，任意声明式节点可设置最多 4096 UTF-8 字节的字符串 `tooltip`；探测
`view.tooltip.rich` 后可改用 `{title?, text}`，标题最多 256 字节，正文必填、非空且最多 4096 字节。
宿主会为只有提示而没有 action 的节点创建裁剪命中区，在元素 hover 时将提示限制在组件 surface
内并绘制于 select 与输入覆盖层之上；标题使用宿主强调字重。两种形式都不创建 HWND、不执行
markup，也不调用 Lua 回调。标题与正文同时作为 UI Automation HelpText 的后备值，输入节点存在
`validationMessage` 时以后者优先。
提示不得承载秘密、命令或必须常驻可见的说明；这些内容应使用正常文本节点或宿主 panel。

`toggle` 和 `checkbox` 是受控选择控件：必须提供非空 `label`、显式 `checked`，以及
`action` 简写或 `events.change`；不得绑定 `events.click`。指针完成一次有效点击时，宿主
投递 `event.action == "change"`，并附带当前 `previousChecked` 与建议的新值 `checked`。
宿主不会替组件修改或持久化状态；组件应在 `event` 中更新自己的 model/storage 并调用
`widget.invalidate()`，下一棵树仍以组件提供的 `checked` 为准。`checkedStyle` 先于
`hoverStyle/pressedStyle/focusStyle` 合并，`disabledStyle` 最后覆盖其他状态样式；未声明
`focusStyle` 时宿主仍提供可见焦点轮廓。轨道、勾选标记、hover、pressed、focus 和元素命中
均由宿主实时绘制；两类控件也支持各自的 `contextMenu`。探测
`view.keyboardNavigation.basic` 后，Enter/空格会生成同样的受控 change 建议。基础
UI Automation 输出已开放，深层虚拟化与全部 Pattern/事件仍按升级计划继续补齐。

探测 `view.checkbox.indeterminate` 后，checkbox 可在 `checked=false` 时声明受控
`indeterminate=true`。宿主绘制横线混合态，指针、键盘或 UI Automation 激活都会建议
`checked=true, indeterminate=false`，事件同时带 `previousIndeterminate/indeterminate`；
宿主仍不写回状态。`checked=true` 与 `indeterminate=true` 同时出现会拒绝整棵树。

探测 `view.state.selected` 后，任意节点可声明受控 `selected` 和 `selectedStyle`；样式在
checked、hover、pressed、validation、focus、disabled 之前合并。带 SelectionItem 契约的
`listItem/slotItem` 还会向 UI Automation 暴露选中值，其他普通节点只获得视觉状态。
月历日期格继续复用 `selectedStyle`，但其日期选择仍由 `selectedDate` 控制。

`widget.context().focused` 在宿主管理的文本输入或任一可聚焦声明式元素取得键盘/UIA
焦点时为 `true`，不再只表示文本编辑状态。

```lua
view.toggle({
    key = "notifications",
    label = "Notifications",
    checked = model.notifications,
    action = { id = "notifications.change" },
    checkedStyle = { background = 0x4C9AFF },
})
```

`link` 要求非空 `label` 和 click action，宿主使用链接语义、手型光标、强调色与下划线
实时绘制，并支持 hover/pressed 样式和元素级 `contextMenu`。`radioGroup` 与 `slider` 同样是
受控控件，必须使用 `action` 简写或 `events.change`，不得绑定 `events.click`。单选组要求
显式 `selectedValue`（空字符串表示未选择）以及 1–64 个 `{ key, value, label, enabled? }`
选项，key/value 在组内唯一；每个选项都有独立的 `<group-key>/<option-key>` 命中区、
radio 语义、hover/pressed/checked 绘制和右键菜单目标。选中选项时 action 事件附带
`previousSelection/selection`，宿主不写回选中值。

`slider` 要求显式 `value` 和 `accessibility.label`，支持 `min/max/step`（默认
0/1/0.01）及水平/垂直方向。鼠标左键按下后由宿主捕获拖动，持续投递 step 对齐且限制在
范围内的 `previousControlValue/controlValue`；右键只用于菜单，不改变数值。组件收到建议值
后仍需更新自己的 model/storage 并调用 `widget.invalidate()`。这三个节点对应
`view.actionControls`；探测 `view.keyboardNavigation.basic` 后，单选项可用 Enter/空格选择，
滑块可用左/下减一档、右/上加一档。UI Automation 已输出单选项的 SelectionItem、父组的
Selection，以及滑块的 RangeValue Pattern；辅助技术动作仍要求组件处理建议值并回写受控状态。

```lua
view.radioGroup({
    key = "density",
    selectedValue = model.density,
    options = {
        { key = "comfortable", value = "comfortable", label = "Comfortable" },
        { key = "compact", value = "compact", label = "Compact" },
    },
    action = { id = "density.change" },
})

view.slider({
    key = "volume",
    value = model.volume,
    min = 0,
    max = 100,
    step = 5,
    action = { id = "volume.change" },
    accessibility = { label = "Volume" },
})
```

`view.inputControls` 的五类节点都是声明式受控控件。`textInput/textArea/searchBox`
必须提供字符串 `value`，`numberInput` 必须提供有限数值 `value/min/max/step`，四类输入
都要求 `action` 简写或 `events.change` 和 `accessibility.label`，不得绑定 `events.click`。
宿主复用同一套键盘、选择、剪贴板代理和 IME 编辑器：聚焦期间宿主持有编辑缓冲，
`change` 通过 `previousText/text` 只报告建议值；组件更新 model 后下一棵树才成为权威值，
Lua 不会获得剪贴板内容或原生句柄。`liveUpdate=false` 将 change 延迟到提交，Escape 在
实时模式下用 `cancelled=true` 建议恢复初始值。`focus/blur/submit` 为可选动作；单行 Enter
提交，`textArea` Enter 换行而 Ctrl+Enter 提交。`numberInput` 的上下方向键按 step 调整，
文本是完整且位于范围内的数字时，change 还带 `numberValid=true` 和 `controlValue`。
探测 `view.keyboardNavigation.basic` 后，Tab/Shift+Tab 可在这些输入与同树其他可操作元素
之间循环；进入输入后仍由上述宿主编辑器处理文本键、选择、IME 和提交。

探测 `view.input.selection` 后，`textInput/textArea/searchBox` 可声明
`selection = { start = 0, finish = 0 }`。`start/finish` 是从 0 开始、左闭右开的 UTF-8
字节偏移，必须位于当前 `value` 的码点边界且满足 `start <= finish`；不能把 Lua 字符串的
字节偏移与 Windows 编辑器内部 UTF-16 单元混用。声明 selection 时必须同时声明
`events.selectionChange`，并且不能再使用一次性的 `selectAll`。键盘或指针只改变选区时，
动作事件携带 `previousSelection/selection`；发生文本 change 时，change 事件也携带编辑后的
`selection`。组件应把建议范围写回自身 model 并 invalidate，宿主只在聚焦编辑期间保存草稿，
不会替组件持久化选区。

```lua
view.textInput({
    key = "title",
    value = model.title,
    selection = model.titleSelection,
    events = {
        change = { id = "title.change" },
        selectionChange = { id = "title.selection" },
    },
    accessibility = { label = "Title" },
})
```

探测 `view.input.required` 后，textInput/textArea/searchBox/numberInput/select 可声明
`required=true`。它会映射为 UI Automation 的 IsRequiredForForm，方便辅助技术理解表单，
但不会自行校验、阻止提交或生成错误文案；组件仍应显式维护 `validationState`、
`validationMessage` 与可见提示。

```lua
view.searchBox({
    key = "query",
    value = model.query,
    placeholder = "Search",
    maxBytes = 256,
    action = { id = "query.change" },
    events = { submit = { id = "query.submit" } },
    accessibility = { label = "Search" },
})
```

`select` 需要 `selectedValue`、1–64 个稳定选项、`events.change`（可用 `action` 简写）、
`events.click` 和 `accessibility.label`。展开状态同样由组件通过 `expanded` 控制：触发区 click
报告 `previousExpanded/expanded`，展开后每个 `<select-key>/<option-key>` 选项 change 报告
`previousSelection/selection`。宿主在组件内表面顶层绘制选项并优先命中，不调用阻塞式系统
菜单；组件收到 click/change 后应更新 model 并 invalidate。当前弹层仍受组件及父滚动视口
裁剪，跨组件表面的通用 popover 属于后续宿主 surface API。

`textInput/textArea/searchBox/numberInput` 可设置 `readOnly=true`。只读输入仍可获得焦点、
移动光标、选择并复制文字，也可触发 focus/blur/submit；宿主会拒绝键入、IME 提交、粘贴、
剪切删除、退格/Delete、数字方向键步进以及 UI Automation SetValue。只读输入不要求
`action/events.change`，即使作者提供也不会因用户编辑触发。`enabled=false` 仍表示完全禁用，
与只读语义不同。对应能力包含在 `view.inputControls`。

上述五类输入/选择节点还支持 `validationState="none|info|success|warning|error"`、
`validationMessage` 和 `validationStyle`。非 `none` 状态会在 pressed 之后、focus/disabled 之前
叠加校验样式；未提供校验边框时，宿主按状态提供蓝/绿/黄/红边框和至少 1.5 逻辑像素宽度。
`validationMessage` 受单节点及整树文本配额限制，并通过 UI Automation HelpText 暴露；如果信息
需要持续可见，组件仍应显式渲染相邻 `text`，不能只依靠颜色或辅助技术。校验状态是受控显示
属性，不会替组件阻止 change、修改 model 或写入存储。

`view.keyboardNavigation.basic` 作用于桌面 surface 中当前唯一选中的 Lua 组件，以及当前活动的
panel surface。宿主按照对应 surface 最后一棵成功提交的交互树顺序收集启用的可点击节点、
受控控件和文本输入：Tab/Shift+Tab 循环焦点，
方向键按元素几何位置移动焦点，Enter/空格激活按钮、链接、选择控件等，Escape 清除焦点；滑块
用左/下减一档、右/上加一档。键盘激活仍投递普通 action/change 事件，但带
`source="keyboard"` 和可信手势标记。鼠标点击可操作元素也会同步宿主
焦点，但不会叠加键盘式蓝色焦点框；指针反馈应使用 hover/pressed/selected 样式。文本
输入仍显示编辑焦点，键盘、访问键、程序化聚焦和辅助技术焦点也继续显示宿主焦点轮廓。
桌面逻辑槽位继续在这一焦点序列中使用 `Alt+方向键` 重排和 Delete 移除；panel
不开放这组宿主槽位操作。该基础 feature 不承诺任意键绑定。

探测 `view.keyboard.accessKey` 后，拥有单一直接交互目标的可聚焦节点可声明
`accessKey="A"`（一个 ASCII 字母或数字）和可选 `acceleratorText="Ctrl+R"`。
访问键在同一棵提交树内大小写不敏感且必须唯一；活动 panel/dialog/popover 优先于桌面，
桌面仍要求该 Lua 组件是唯一选中组件。`Alt+访问键` 会把焦点移到目标：文本/数字输入和 slider
只聚焦，按钮、链接、toggle/checkbox、select、listItem/slotItem 等则复用既有 click/change
受控语义激活，并以 `source="accessKey"` 作为可信键盘手势。按住按键的重复消息不会再次激活。
radioGroup、monthCalendar 等一个节点生成多个交互子项的控件不接受父级访问键，避免一个键对应
多个目标。宿主通过 UI Automation `AccessKey` 暴露 `Alt+A`；`acceleratorText` 只进入
`AcceleratorKey`，用于描述组件已经通过其他机制实现的快捷键，不注册系统或全局热键。
两个字段都不要求权限，辅助 surface 关闭、组件取消选择或节点 disabled 后不会响应。

探测 `view.keyboard.events` 后，可聚焦节点可声明 `events.keyDown/keyUp`。事件仅投递给桌面
surface 中当前唯一选中 Lua 组件或活动 panel surface 的当前聚焦元素，包含稳定符号名 `key`、Windows
`virtualKey`、`repeat`、`ctrlKey/shiftKey/altKey`、`targetKey`、`source="keyboard"` 和
可信手势。宿主在按下时记录目标，因此普通重渲染或 Escape 清焦后仍会把对应 keyUp 配对到
原元素；窗口失焦时清空未完成配对。该观察事件不能返回 handled、取消 Enter/空格默认激活，
也不能阻止 SnowDesktop 管理快捷键。它不是字符输入接口：文本、输入法组合和剪贴板结果仍只
通过宿主输入控件及其 change/selectionChange 契约处理。

探测 `view.pointer.events` 后，任意可命中的声明式节点可声明 `events.pointerMove/wheel`。
`pointerMove` 只在指针位于该元素或其捕获仍有效时高频投递；没有绑定时 hover/pressed 继续由
宿主重绘，不执行 Lua。`wheel` 带原始 `delta` 和可信手势；scroll/virtual collection 即使先由
宿主移动内容，也会向自身显式 wheel action 投递，事件不能阻止、回滚或替代宿主滚动。

探测 `interaction.pointerCapture` 后，非宿主输入/select 节点可设置 `capturePointer=true`，并且必须
绑定 `pointerMove` 或 `pointerUp`。主指针在该稳定 key 上按下后，即使移出元素或组件边界，move/up
仍投递给原目标；移出后不会合成 click。释放按键、目标从成功 scene 消失、surface 关闭、窗口失焦、
系统取消捕获、组件卸载或授权导致实例停用都会终止捕获。该能力不允许 Lua 捕获全局输入，也不改变
hover 命中；连续按压 30 秒后宿主也会停止捕获路由。宿主 slider 原有拖动语义不要求作者重复声明。

探测 `view.keyboardNavigation.order` 后，任意有语义的节点可声明 `focusable`，并在实际可聚焦时
声明 `tabIndex=-1..32767`。`focusable=false` 同时退出鼠标、键盘和 UI Automation 焦点；
`tabIndex=-1` 仍允许鼠标/UIA 聚焦，但不进入 Tab 和方向键遍历；正数按升序排在默认 0 的文档
顺序之前，同值保持声明顺序。把原本不可聚焦的节点设为 true 时必须有可访问名称，spacer 等
无语义节点不能被提升。该属性只改变焦点参与和遍历；只有单独探测
`view.keyboard.events` 并声明动作时才观察按键，且不会改变绘制/UIA 阅读顺序。

`grid` 是行优先的均匀网格容器，必须提供 1–64 的整数 `columns`；每列等宽，
`columnGap/rowGap` 分别控制水平和垂直间距，未提供时回退到 `gap`。隐藏子节点不占格，
其余子节点保持原顺序，现有 `alignItems/alignSelf` 控制格内拉伸或对齐，
`justifyContent` 控制整组行在纵向剩余空间中的位置。对应 feature 为
`view.grid.uniform`。探测 `view.grid.tracks` 后，`grid/gridList.columns` 也可改为 1–64 项数组：
数字是固定逻辑尺寸，`"auto"` 取已声明子项的固有尺寸，`{fr=n}` 按正权重分配剩余空间，
`{min=n,max=...}` 的 max 可为不小于 min 的固定值、`"auto"` 或 `{fr=n}`。可选 `rows`
接受同一数组，也可用整数创建对应数量的 auto 行；内容需要的后续隐式行仍为 auto。
固定轨和内容下限可以溢出容器，是否裁剪由 `overflow` 决定。`virtualGrid` 为保证固定行高的
范围计算，仍只接受整数等宽 columns，也不接受 rows。
`view.grid.placement` 另允许 `grid` 和 `gridList` 的直接子节点使用
1-based `gridColumn/gridRow`，以及 1 到 64 的 `columnSpan/rowSpan`；只指定一个坐标时，
另一轴以及完全未指定的子项按声明顺序在首个可用位置行优先放置。显式格位重叠、跨度越过
列边界或第 64 行会拒绝整棵树，不会覆盖已有子项。该 feature 仍不包含 fixed/auto/fr/minmax
任意嵌套 track 函数、瀑布流或自动虚拟化；需要这些能力时不得假设基础 `grid` 会静默模拟。

`flow` 按子节点原顺序从左到右放置，当前行剩余宽度不足时整体换到下一行；隐藏子节点
不占位置，单个超宽子节点钳制到内容区宽度。`columnGap/rowGap` 独立控制项间距与行间距，
未提供时回退到 `gap`；`justifyContent` 分别作用于每一行的横向剩余空间，
`alignItems/alignSelf` 控制行内纵向对齐。自动高度采用“每项单独一行”的保守固有高度，
避免测量阶段因未知最终宽度截断换行内容；在固定或 fill 高度中，超出的行高会按可用高度
收缩。对应 feature 为 `view.flow.wrap`，不包含纵向 flow、masonry、滚动或虚拟化。

`scroll` 是宿主管理的有界滚动视口，只允许一个子节点且该节点必须可见（额外隐藏节点也会
拒绝）；默认纵向，也可使用
`orientation="horizontal"`。宿主测量完整内容、按实例和稳定 key 保存偏移、处理滚轮/
触控板 wheel、钳制到内容边界、移动子树并同时裁剪绘制和元素命中。滚出视口的按钮或
列表项不能 hover、点击或打开右键菜单。`showScrollbar=false` 可隐藏宿主滚动条，但不会
关闭滚动。每棵树最多 32 个 scroll，单轴内容 extent 最大 1,000,000 逻辑单位；该能力
对应 feature `view.scroll`，当前不提供 Lua 自绘滚动条、惯性动画或滚动链；
Windows UI Automation Scroll Pattern 可以通过同一宿主滚动状态移动视口，但不会获得可信手势。
探测 `view.scroll.initialTarget` 后，普通 `scroll` 可用 `initialScrollKey` 在该 surface
第一次成功接收此容器稳定 key 时，以 nearest 语义显示一个可见后代；`virtualList/virtualGrid`
则用 1-based `initialScrollIndex` 定位固定或估算高度项目。初始定位只在宿主尚无该 key 的偏移时计算，
即使结果为 0 也会建立状态；后续重渲染、属性变化和组件主动滚动都不会覆盖用户位置。
目标后代不存在、被 hidden/collapsed，或虚拟索引越界时，首次候选 scene 会按事务语义拒绝。
虚拟集合首帧还必须把同一个 `initialScrollIndex` 传给 `view.virtualRange()`，使 Lua 实体化目标
附近的连续窗口；如果 loadingContent 正在显示，宿主会把定位延后到项目内容首次成功提交。
探测 `view.scroll.events` 后，`scroll/virtualList/virtualGrid` 可声明 `events.scrollEnd`；滚轮或
UIA 滚动从末端之前首次到达最大偏移时投递一次 action，离开末端后可再次触发。没有可滚动范围、
已位于末端的重复输入和渲染时偏移钳制不会重复投递；UIA 来源为 `accessibility` 且不携带可信手势。
探测 `view.scroll.programmatic` 后，action/event/schedule 等非渲染回调可调用
`view.scrollTo(key, offset)` 或 `view.scrollBy(key, delta)`；宿主按当前已提交 scroll/virtual
节点范围钳制并返回 `{offset,maximum,changed}`。`view.scrollToIndex(key,index,alignment?)`
接受已提交的固定主轴尺寸 `virtualList/virtualGrid` 以及可变行高 `virtualList`，使用 1-based 全局索引和
`nearest/start/center/end` 对齐。三个函数都禁止在 `view()`/`render()` 中改变偏移，未知 key
返回 `scrollTargetNotFound`，索引越界返回 `indexOutOfRange`，且不会产生可信用户手势。

`list` 是默认纵向的有界集合；探测 `view.collection.orientation` 后可声明
`orientation="horizontal"|"vertical"`，横向会同时改变固有尺寸、basis/grow/shrink 分配和条目
位置，但声明、键盘与语义顺序保持不变。`gridList` 是要求 `columns=1..64` 的行优先等宽集合；两者的直接
子节点必须全部是 `listItem`。每个 `listItem` 要求全树唯一稳定 key、只含一个可见内容子节点
（额外隐藏节点也会拒绝）和 `accessibility.label`，可以使用 `action`/`events.click`、doubleClick、pointer 状态与
独立 contextMenu；宿主默认赋予 `listitem` 语义。一个树最多 256 个 listItem，仍受 512
总节点和 256 交互区域上限约束。对应 feature 为 `view.collection.basic`。这是非虚拟化
基础集合；大量或远程分页数据应使用下述 `virtualList/virtualGrid`，不能通过超配额树模拟。
`gridList/virtualGrid` 不接受 orientation；`virtualList` 只有探测
`view.collection.virtual.orientation` 后才能使用下述横向模型，横向 estimatedItemSize 还必须同时
探测 `view.collection.virtual.variableExtent`。

探测 `view.collection.stickyHeaders` 后，纵向 eager `list` 的直接 `listItem` 可声明
`sticky=true`。当该 list 位于纵向 `scroll` 内时，宿主把已经越过视口顶部的最近标题固定在
scroll content 顶部；下一个 sticky 项会把前一个标题向上推出，最后一个标题也不会越过所属
list 的底部。固定后的绘制、裁剪、元素命中、右键菜单和 UIA 几何共用同一个 scene frame，
标题会排在普通条目之上，但声明与语义顺序不改变。横向 list、gridList 和 virtual collection
会原子拒绝 sticky；virtualList 的分组标题使用独立的
`view.collection.virtual.stickyHeaders` 契约，不能直接给虚拟 listItem 设置 sticky。

探测 `view.collection.selection` 后，四种集合容器都可声明
`selectionMode="none"|"single"|"multiple"` 和受控 `selectedKeys`。非虚拟集合的键必须
对应直接 `listItem`，虚拟集合则允许保留当前窗口外的逻辑项键；键必须唯一，single 最多一个，
none 不接受任何键。single/multiple 要求在集合容器声明 `events.change`。宿主把选择状态统一
应用到条目的 `selectedStyle`、键盘/指针命中和 UIA Selection/SelectionItem，并在 action 事件
中返回 `previousSelectedKeys/selectedKeys`；Lua 必须更新 model 并重新提交，宿主不自行持久化。
选择集合的条目不能再声明 click/change，单击和 Enter/Space 留给选择；需要打开条目时使用
`doubleClick` 或条目内独立按钮，contextMenu 仍保持元素级目标。多选的辅助技术 Add/Remove
操作也只产生同一种受控建议。

```lua
view.list({
    key = "messages",
    selectionMode = "multiple",
    selectedKeys = model.selectedKeys,
    events = { change = { id = "messages.select" } },
    children = items,
})
```

探测 `view.collection.contentStates` 后，集合可声明单个 `emptyContent` 和
`loadingContent` 节点。非忙且 eager children 为空、或 virtual `itemCount=0` 时，宿主用
emptyContent 替代项目；`busy=true` 且提供 loadingContent 时，无论已有项目与否都原子切到
loadingContent。替代节点按集合 content box 布局并经过同一绘制、命中、键盘和语义树，不再
出现视觉空白但旧项目仍可点击的状态。virtual 替代态的滚动范围归零；loading 可保留受控
selectedKeys，empty 必须清空选择。没有提供对应替代节点时宿主保留作者提交的普通 children，
不会擅自生成或本地化状态文字。通用 `busy` 可通过 `view.state.busy` 探测，并以
UI Automation `busy=true` 语义暴露；它本身不会禁用控件或启动隐式逐帧动画。

```lua
view.virtualList({
    key = "results",
    height = "fill",
    itemCount = model.total,
    itemExtent = 44,
    firstIndex = range.firstIndex,
    busy = model.loading,
    loadingContent = view.text({ key = "loading", text = l10n.t("loading") }),
    emptyContent = view.text({ key = "empty", text = l10n.t("noResults") }),
    children = items,
})
```

```lua
view.scroll({
    key = "feed-scroll",
    height = "fill",
    children = {
        view.list({
            key = "feed",
            gap = 6,
            children = {
                view.listItem({
                    key = "article:" .. article.id,
                    action = { id = "article.open",
                        value = { articleId = article.id } },
                    events = { contextMenu = { id = "article.menu",
                        value = { articleId = article.id } } },
                    accessibility = { label = article.title },
                    children = {
                        view.text({ key = "title:" .. article.id,
                            text = article.title }),
                    },
                }),
            },
        }),
    },
})
```

`virtualList` 和 `virtualGrid` 默认是固定行高的纵向虚拟集合，对应 feature
`view.collection.virtual`。Lua 先用 `view.virtualRange()` 查询当前宿主滚动位置需要实体化的
1-based 闭区间，只为该区间创建连续 `listItem`；再把同一 `key/itemCount/itemExtent/
rowGap/columns/overscan`、返回的 `firstIndex` 和窗口 children 提交给虚拟节点。宿主按全局
索引布局这些项、使用完整逻辑 itemCount 计算滚动范围，并验证提交窗口覆盖真实可见行；
窗口缺项会拒绝整棵树，不能显示错误但可点击的空洞。

```lua
local itemExtent = 44
local rowGap = 4
local viewportExtent = math.max(1, context.logicalHeight - 8)
local range = view.virtualRange({
    key = "feed-virtual",
    itemCount = #articles,
    itemExtent = itemExtent,
    viewportExtent = viewportExtent,
    rowGap = rowGap,
    overscan = 2,
    initialScrollIndex = model.initialArticleIndex,
})
local children = {}
for index = range.firstIndex, range.lastIndex do
    local article = articles[index]
    children[#children + 1] = view.listItem({
        key = "article:" .. article.id,
        action = { id = "article.open", value = { index = index } },
        accessibility = { label = article.title },
        children = {
            view.text({ key = "title:" .. article.id,
                text = article.title }),
        },
    })
end
return view.virtualList({
    key = "feed-virtual",
    height = "fill",
    itemCount = #articles,
    itemExtent = itemExtent,
    firstIndex = range.firstIndex,
    rowGap = rowGap,
    overscan = 2,
    initialScrollIndex = model.initialArticleIndex,
    children = children,
})
```

`virtualGrid` 另要求 `columns=1..64`，`view.virtualRange` 必须收到同一 columns；
`itemExtent` 表示行高而不是单格宽度。虚拟集合最多表示 1,000,000 项，但总逻辑 extent
仍不得超过 1,000,000；每帧最多实体化 128 项，overscan 为 0–16 行，空集合使用
`firstIndex=0` 和空 children。虚拟节点必须有固定或 fill 高度，`viewportExtent` 是扣除
节点 padding 后的实际内容高度。

探测 `view.collection.virtual.orientation` 后，`virtualList` 可声明
`orientation="horizontal"`。固定尺寸时 `itemExtent` 表示单项宽度；探测
`view.collection.virtual.variableExtent` 后也可用 `estimatedItemSize` 估算并测量单项宽度。主轴间隔
使用 `columnGap`，节点必须有 fixed/fill 宽度；`view.virtualRange` 必须收到相同 orientation、
尺寸参数和 columnGap，
且 `viewportExtent` 改为扣除 padding 后的内容宽度。宿主在 x 轴完成窗口布局、裁剪、滚轮、
滚动条和 `scrollToIndex`。横向虚拟列表只允许 `columns=1`，不接受 `rowGap` 或
section/sticky header；`virtualGrid` 仍固定纵向。

探测 `view.collection.virtual.variableExtent` 后，`virtualList` 可用正数
`estimatedItemSize` 替代 `itemExtent`。`view.virtualRange` 必须传入同一个 estimate、
`layoutRevision`、主轴 gap 和 overscan；宿主先以 estimate 计算首帧范围，成功 scene 布局后测量
当前连续 `listItem` 窗口的高度（纵向）或宽度（横向），最多为每个容器缓存 4096 个 1-based
索引尺寸，并触发下一次合并重绘。缓存修正内容主轴总长度和后续范围，且以修正前第一个可见项为
锚点同步调整偏移，避免测得前方项目后
让当前内容跳动。测量缓存只在整棵候选 scene 成功后提交；失败 scene 不污染后续范围。
当项目顺序、字体、尺寸策略或其他会改变主轴尺寸的 model 内容变化时，作者必须递增非负
`layoutRevision`，宿主会原子丢弃旧代测量；itemCount、estimate、主轴 gap 或 orientation 变化也会
自动换代。
固定和估算尺寸不可同时声明，`virtualGrid` 仍只接受固定 `itemExtent`。

```lua
local estimate = 48
local revision = model.feedLayoutRevision
local range = view.virtualRange({
    key = "variable-feed",
    itemCount = #articles,
    estimatedItemSize = estimate,
    layoutRevision = revision,
    viewportExtent = viewportExtent,
    rowGap = 4,
    overscan = 3,
})
-- 只创建 range.firstIndex..range.lastIndex 的连续 listItem。
return view.virtualList({
    key = "variable-feed",
    height = "fill",
    itemCount = #articles,
    estimatedItemSize = estimate,
    layoutRevision = revision,
    firstIndex = range.firstIndex,
    rowGap = 4,
    overscan = 3,
    children = items,
})
```

探测 `view.collection.virtual.stickyHeaders` 后，`virtualList` 可把最多 4096 个已排序、唯一且
位于 `1..itemCount` 的全局索引同时作为 `sectionHeaderIndices` 传给 `view.virtualRange()` 和
virtualList 节点。范围结果的可选 `stickyHeaderIndex` 是当前首个可见项所属的最近分组标题。
当它小于 `range.firstIndex` 时，Lua 必须先创建这个标题的一个额外 `listItem`，再按原顺序创建
`range.firstIndex..range.lastIndex` 的连续窗口；标题已经位于窗口内时不得重复创建。节点的
`children`、`firstIndex`、`sectionHeaderIndices` 和 `stickyHeaderIndex` 会被宿主联合校验，额外标题
不占 128 项连续窗口配额。固定和可变行高 virtualList 共用这一契约；下一个已实体化分组标题会
推出当前标题，呈现后的绘制、命中、右键菜单与 UIA 几何保持一致。

```lua
local sectionHeaders = { 1, 8, 19 }
local range = view.virtualRange({
    key = "grouped-feed",
    itemCount = #articles,
    itemExtent = 44,
    viewportExtent = viewportExtent,
    overscan = 2,
    sectionHeaderIndices = sectionHeaders,
})
local children = {}
if range.stickyHeaderIndex and
        range.stickyHeaderIndex < range.firstIndex then
    children[#children + 1] = makeItem(range.stickyHeaderIndex)
end
for index = range.firstIndex, range.lastIndex do
    children[#children + 1] = makeItem(index)
end
return view.virtualList({
    key = "grouped-feed",
    height = "fill",
    itemCount = #articles,
    itemExtent = 44,
    firstIndex = range.firstIndex,
    sectionHeaderIndices = sectionHeaders,
    stickyHeaderIndex = range.stickyHeaderIndex,
    children = children,
})
```

当前仍不支持横向 virtualGrid、可变行高 virtualGrid、横向 sticky header、未实体化项目的
UIA VirtualizedItem，
或保留已回收项的 Lua 局部状态；固定与可变列表的程序化定位由 `view.scroll.programmatic` 提供，
稳定状态应放在 model/state 并以 item key 索引。

`shape` 支持 rectangle、roundedRectangle、circle 和 ellipse；填充与描边来自 style。
`image` 的 `source` 只接受入口加载期间创建的 `resource.image()` 句柄，必须显式提供
`alt`（装饰图片使用空字符串），支持 `fill/contain/cover/none` fit、
`start/center/end` alignment 和 `nearest/linear` interpolation；对应 feature 为
`view.image`。`referenceIcon` 使用相同的 `alt/fit/alignment/interpolation`，但以当前
组件实例从宿主搜索、文件引用任务或逻辑槽位获得的 1–128 字节 opaque `reference`
代替图片资源句柄；宿主在异步 Shell 图标缓存就绪后重绘，不在渲染热路径同步解码，
也不会把目标路径交给 Lua。该节点本身不授予启动、打开、定位或文件内容权限，对应
feature 为 `view.referenceIcon`。

```lua
view.referenceIcon({
    key = item.id .. ".icon",
    reference = item.reference,
    alt = item.title,
    width = 64,
    height = 64,
})
```

`text`、`badge`、`button`、`link`、`toggle`、`checkbox` 和
`radioGroup` 可通过 `font` 使用
`resource.font()` 返回的包私有字体
句柄，对应 feature 为 `view.font`。这些属性不接受文件路径或跨包句柄。
`icon`/`iconButton` 的 `glyph` 使用宿主 Font Awesome 或 Fluent 字体，`iconButton` 必须
提供 `accessibility.label`。`progressBar`/`progressRing` 接受 0–1 的 `value`、正数
`thickness`、track/fill opacity，并分别使用 style.background/foreground 作为轨道和
进度色。探测 `view.progress.indeterminate` 后，两者还可声明 `indeterminate=true`；此时
`value` 仍须处于 0–1 但不参与绘制，`meter` 不接受该状态。宿主只在对应 desktop/panel
surface 可见时推进动画，不向 Lua 投递逐帧回调；组件隐藏、面板关闭后停止请求帧，预览和
系统“减少动态效果”状态使用静态片段。这些节点均由宿主直接绘制，不开放路径、字体文件或
原生绘图对象。

`styledText` 要求 1–64 个非空 `spans`，每个 span 可独立指定
`foreground/fontSize/bold/italic/underline/strikethrough`。宿主把全部 span 合并为一个 DirectWrite layout，统一
执行换行、裁剪、对齐和包私有字体解析，而不是为每段创建布局子节点。基础样式通过
`view.styledText.basic` 探测。

探测 `view.styledText.actions` 后，span 可增加稳定 `key`、`action`、受限 pointer/key
`events`、`contextMenu`、`cursor`、`tooltip`、`accessibility.label` 以及
`hoverForeground/pressedForeground`。生成的独立目标为
`<styledText-key>/<span-key>`；宿主从同一 DirectWrite layout 提取最多 64 个换行片段进行精确
命中，不会把两行之间或行尾之外的包围盒空白当作链接。click、双击、hover、pressed、键盘、
提示和元素级右键菜单都复用普通 action surface 路由，事件的 `targetKey` 是上述生成键。
存在任何交互字段的 span 必须提供 key；重复键、超长生成键或片段超配额会拒绝整棵新树并
保留上一成功树。

探测 `view.styledText.inlineIcons` 后，一个 span 可用恰好一个有效 Unicode scalar 的 `glyph`
替代 `text`，并通过
`iconFont="fa"|"fluent"` 选择宿主内嵌 Font Awesome 或 Fluent 字体。图标与普通文本仍进入
同一个 DirectWrite layout，因此共享换行、基线、对齐、裁剪和精确 span 命中；`fontSize`、颜色、
hover/pressed、action、tooltip 与右键菜单继续有效。图标字体是固定字形，不接受 bold/italic；
带 key 的图标 span 必须提供 `accessibility.label`，避免把私用区字符暴露成无意义名称。
该 feature 不提供包内任意 inline 图片、HTML 或 Markdown。

```lua
view.styledText({
    key = "status",
    spans = {
        { text = "Build ", foreground = 0x94A3B8 },
        { glyph = "\u{f058}", iconFont = "fa",
          foreground = 0x4ADE80 },
        { text = " " },
        { key = "result", text = "passed", foreground = 0x4ADE80,
          hoverForeground = 0x86EFAC, bold = true,
          action = { id = "build.open" },
          events = { contextMenu = { id = "build.menu" } },
          accessibility = { label = "Build result" } },
    },
    accessibility = { label = "Build passed" },
})
```

`monthCalendar` 是受控的六周 Gregorian 日期网格。它要求 `year/month/selectedDate`、
按周日至周六排列的七个本地化 `weekdayLabels`、change `action` 和
`accessibility.label`；`firstDayOfWeek=1..7` 决定显示顺序。`todayDate`、最多 366 个唯一
`eventDates`、`showAdjacentDates` 以及 `selectedStyle/todayStyle/adjacentStyle/eventStyle`
用于有限状态绘制。每个可见日期拥有稳定的 `<calendar-key>/<YYYY-MM-DD>` 命中目标和
独立 hover/pressed/contextMenu；点击投递 `previousSelection/selection`，组件必须写回
自己的 model，宿主不会修改持久状态。

```lua
view.monthCalendar({
    key = "month",
    year = 2026, month = 8, firstDayOfWeek = 2,
    selectedDate = model.selectedDate,
    todayDate = model.todayDate,
    weekdayLabels = { "日", "一", "二", "三", "四", "五", "六" },
    action = { id = "calendar.select" },
    accessibility = { label = "2026 年 8 月" },
})
```

`badge` 要求非空 `text`，默认使用 4 单位 padding 和胶囊圆角，适合紧凑状态标记；
`divider` 通过 `orientation="horizontal"|"vertical"` 表示分隔方向，以 `thickness` 和
`style.foreground` 控制线宽与颜色，垂直分隔线未显式指定尺寸时使用 intrinsic width 并
填满父级高度；`meter` 接受 0–1 `value`，绘制方式与确定进度条相同，但语义是当前读数
而不是任务完成进度，因此必须提供 `accessibility.label`。三者对应
`view.statusVisuals`，不创建原生窗口或逐帧 Lua 回调。

五个数据图形节点只接受 `values` 连续数值数组，每节点 1–512 个有限样本、全树最多
4096 个样本，并要求 `accessibility.label`。`sparkline` 和 `lineChart` 默认按当前数列
自动取值域；`barChart` 自动包含零基线；`waveform` 默认范围为 -1–1，`spectrum` 默认
范围为 0–1。需要固定尺度时必须同时提供有限且满足 `min < max` 的 `min/max`；超出范围
的样本只在绘制时钳制，不修改 Lua 数据。`lineChart` 绘制有界参考线，`waveform` 和跨零
柱图绘制零线；`style.foreground` 和 `fillOpacity` 控制全部图形前景，`thickness` 只用于
`sparkline/lineChart/waveform` 的折线宽度，`trackOpacity` 只用于
`lineChart/barChart/waveform` 的参考线或零线。
节点由宿主在已提交树内直接绘制，不创建逐样本子节点或逐样本事件区域：

```lua
view.waveform({
    key = "waveform",
    values = audio.waveform,
    height = 64,
    style = { foreground = 0x72C7FF },
    trackOpacity = 0.5,
    accessibility = { label = "Output audio waveform" },
})
```

树限制为 512 节点、32 层、单节点 4 KiB 文本、全树 64 KiB 文本和最多 256 个交互
区域；数据图形另有上述逐节点和全树样本额度。未知字段、错误枚举、非连续 children、
重复 key、NaN/Infinity 和越界值会拒绝整次提交。桌面树只布局在底部标题栏之上的内容区。

宿主现在从同一份可枚举节点契约表读取 44 个已公开节点的名称、所属 feature、默认
accessibility role、允许属性、直接必需属性和子节点策略。Lua 解析器会在布局前按该表拒绝拼错字段或
用在错误节点上的字段；例如 `columns` 不能用于 `row`，`source` 不能用于
`referenceIcon`，叶节点也不接受 `children`。子节点策略固定为：

| 策略 | 节点 | 约束 |
|---|---|---|
| 任意组合 | `box/row/column/grid/flow/stack` | 0 个或多个普通节点，仍受全树深度和数量额度限制 |
| 单一内容 | `scroll/listItem/slotItem` | 必须恰好一个可见内容节点 |
| 集合窗口 | `list/gridList/virtualList/virtualGrid` | 正常态只接受直接 `listItem`；empty/loading 替代态恰好一个可见节点 |
| 宿主槽位 | `slotSurface` | binding 最多一个 `slotItem`，collection 只接受 `slotItem`；空态可有一个非槽位节点 |
| 叶节点 | 文本、图片、控件、状态、图表、日历和 `spacer` | 不接受 `children` |

属性矩阵同样拒绝“接收后无效果”的通用字段：字体、排版和文本流字段只允许用于文本/标签、
输入/选择、图标和月历等实际消费它们的节点；`gap` 只用于线性、网格、flow、虚拟集合和
radioGroup；`alignItems/justifyContent` 只用于会执行对应对齐算法的布局；`clip/overflow` 只用于
拥有后代的容器。需要给图片裁圆角或背景时应使用 `style`，不要把后代裁剪属性放在叶节点上。
其中输入和 select 只消费 `fontSize/textAlign/locale/textDirection`，radioGroup 与月历额外消费
`bold`，其余高级字重、字形、行高、字距和文本流字段只开放给真正使用 DirectWrite 通用文本
管线的文本、标签和图标节点。divider 只使用 `thickness`，不接受进度/图表的
`trackOpacity/fillOpacity`；select 的选中项当前使用宿主固定状态色，也不接受仅供
toggle/checkbox/radioGroup 使用的 `checkedStyle`。图表属性也按实际绘制路径区分：柱图和频谱
不接受未消费的 `thickness`，sparkline 和频谱不接受未消费的 `trackOpacity`。
全部 146 个属性还具有可枚举的语义值类型；跨节点一致的标量范围（例如 opacity 0–1、
fontSize 1–512、grid span 1–64）由同一契约登记。节点相关的组合约束仍会在场景校验阶段执行，
例如 slider/numberInput 必须满足 `min < max`、`value` 位于范围内且 `step` 不大于跨度。
Lua 解析器会在构造节点前按该契约拒绝通用标量越界值，不会把它们延迟为布局时空白。
基础 string/enum/boolean/number/integer 类型同样严格按目录检查；数字不会隐式成为文本，
数字字符串也不会隐式成为 number。`value` 是明确登记的 string-or-number 联合类型，随后再由
text input 或数值控件的节点契约收窄。
enum 属性的允许值也可从同一契约枚举并由 Lua 入口统一校验，包括节点 type、布局方向、图片
fit/interpolation、文本流、可见性、校验状态和集合选择模式；拼错值会拒绝本次 tree commit。
length、edge-insets、resource、color、array/node、style、transition、tooltip、accessibility、events
和 action 等结构值先按目录检查 Lua 外形，再由对应解析器校验内部字段与额度。
每项属性同时登记可能影响的 layout、paint、hit-test、input、accessibility、resource 和 tree
宿主域；这套信息用于工具审计及后续增量失效，不改变组件声明式提交模型。
工具还可逐节点查询属性默认：`required`、不适用、固定 Lua 表达式和条件默认是不同状态。
例如 badge padding 为 4、输入 padding 为 8、radioGroup gap 为 8、scroll/list 默认为纵向；
divider 尺寸和数据图自动范围保留为条件默认，不会生成错误的固定值提示。

该表也登记 17 个公开事件的负载类别和逐节点适用性，以及 UIA ControlType、基础 Pattern 和宿主键盘可聚焦性，宿主能从
布局结果生成语义快照，并已通过 Windows UIA Fragment Provider 暴露组件/元素树、基础属性、
边界、父子/兄弟导航、点命中与宿主焦点。Invoke、Toggle、RangeValue、Value、
ExpandCollapse、SelectionItem 和 Scroll Pattern 已连接到同一套 Lua action/受控输入或宿主滚动
通道，Selection 容器、Grid 与 GridItem 也会输出当前受控状态和零基行列坐标。事件中的
`source` 为 `accessibility` 且 `trustedGesture=false`，不会借辅助技术操作扩大权限。UIA
Provider 会在成功桌面帧后按稳定语义 ID 差分并发送结构、焦点、边界、名称、启用、离屏、开关、
选择、RangeValue、Value、展开和滚动状态变化，不会每帧广播未变化属性。其中 `radioGroup` 的选项、展开 `select` 的选项和
`monthCalendar` 的日期已经作为稳定的 SelectionItem 子元素输出，父控件提供 Selection Pattern，
可由辅助技术单独聚焦和选择；受控集合的单选/多选、添加和移除选择也复用
`previousSelectedKeys/selectedKeys` 建议。滚动容器提供 Scroll，网格及当前已实体化的单元提供
Grid/GridItem；任意未实体化集合项仍未形成完整 UIA VirtualizedItem/ScrollItem 协议，真实 Narrator
验收也尚未完成；默认值/范围、视觉状态、动画额度和错误码也未全部迁入，
作者仍应以本节各 feature 的细化说明为准。

探测 `view.accessibility.metadata` 后，声明式节点的 `accessibility` 表除 `role/label` 外还支持：

- `value` 覆盖面向辅助技术的值文本，不修改组件受控值；`hint` 进入 UIA HelpText；
- `labelledBy/describedBy` 引用同一棵树中另一个稳定节点 key。前者提供 Name 与 LabeledBy，
  后者追加 HelpText 并提供 DescribedBy；未知、自引用或没有可读文本的目标会拒绝整棵树；
- `headingLevel=1..9`、`live="off|polite|assertive"`、一基的
  `positionInSet/setSize`；live 节点的名称、值或帮助变化会发送 LiveRegionChanged；
- `rowIndex/columnIndex` 必须成对用于 grid/gridList/virtualGrid 的直接子节点，公共值从 1 开始，
  UIA GridItem 输出转换为从 0 开始；
- `hidden=true` 从语义树移除整棵子树但保留视觉布局。宿主拒绝用它隐藏可聚焦、带动作或带
  交互控件的子树，避免产生只能用鼠标操作的目标。

语义字符串受单节点 4 KiB 与全树 64 KiB 文本额度约束。`role` 同时输出 UIA AriaRole，
`value/hint/heading/live/positionInSet/setSize` 分别映射到 ItemStatus、HelpText、HeadingLevel、
LiveSetting、PositionInSet 和 SizeOfSet；关系目标仍在语义树中时还会输出原生 UIA provider 关系。

即时模式的 `interaction.region` 也进入同一种宿主语义快照，因此使用 `render()` 的组件应为
每个有意义的元素填写稳定 `key`、`accessibility.role` 与 `accessibility.label`；纯命中区域若不
声明语义不会出现在无障碍树中。探测 `interaction.accessibility.metadata` 后还可声明
`value/hint/headingLevel/live/positionInSet/setSize/hidden`；即时 region 是扁平语义集合，不接受
跨 region 的 labelledBy/describedBy 或 grid 行列关系。快照只收集当前可见、有效且非预览的 v2 实例。

探测 `view.surface.panel` 后，`panel(context, model)` 可返回同一份受限声明式树。宿主为 panel
单独维护上一成功树、交互区域、滚动偏移、输入控件与焦点，桌面重渲染不会清空这些状态；
指针、滚轮、元素级菜单、键盘与 action/change 事件均路由到 panel，并在上下文或事件中标识
`surface="panel"`。panel 返回 `nil` 时仍可使用即时绘制与即时控件。panel 的声明式语义树尚未
导出到当前桌面 UIA Fragment Provider，`view.logicalSlots` 的原生重排/移除也仍以桌面 surface
为边界；作者不得据此宣称 panel 已有完整辅助技术或宿主槽位支持。

探测 `view.surface.dialog` 后，`dialog(context, model)` 使用同一份辅助 surface 场景管线，
但宿主将其居中并加非阻塞模态遮罩。dialog 活动时，遮罩外的左/右/中键、滚轮、移动与双击
不会穿透桌面；焦点和键盘事件留在 dialog，关闭按钮始终可用。`dismissOnOutside` 默认 false，
`dismissOnEscape` 默认 true。一个实例同时只拥有一个 panel 或 dialog；打开新辅助 surface 会
关闭旧 surface。dialog 同样尚未导出到桌面 UIA Fragment Provider。

panel、dialog 或 popover 打开后，宿主在其首棵成功场景中自动聚焦 Tab 顺序里的第一个
可聚焦元素，使方向键、Enter 和空格立即作用于辅助界面；同一打开回调中通过
`control.focus()` 提交的显式目标优先。该自动聚焦每次打开只执行一次，后续重绘不会在用户按
Escape 清除焦点后再次抢回；首帧尚无可聚焦元素时会等到首次成功提交此类元素。

探测 `view.surface.popover` 后，`popover(context, model)` 复用辅助 surface 场景管线，但位置
来自 `widget.openPopover({ anchorKey=... })` 指向的当前成功 desktop scene 元素，而不是鼠标
坐标或 Lua 提供的任意屏幕坐标。宿主将元素局部命中范围转换为桌面范围，应用 placement、翻转
与工作区钳制；滚动出裁剪区、禁用、未知或陈旧 key 会使打开返回 false。popover 默认非模态、
外部点击与 Escape 均关闭，与 panel/dialog 互斥；嵌套辅助 surface 打开被拒绝。popover 语义树
同样尚未导出到桌面 UIA Fragment Provider。

`view.tree.core` 仍不是完整 `view.tree`：业务状态失效时仍提交完整树；只有
`view.transition.visual/view.transition.transform` 的插值帧会复用上一棵成功树。当前尚无可变高度虚拟集合、
完整 UIA 虚拟集合/ScrollItem Pattern 或差量资源复用。
需要这些能力的组件应继续使用已经公开的细粒度 feature 或等待对应能力；不得把
`view.tree.core` 当作稳定完整控件集声明。

### `slots.model` 与 `view.logicalSlots`

API v2 包可在 `widget.json` 中静态声明单项绑定或有界集合。当前只支持
`operation="reference"`，引用原对象而不移动、复制或删除它：

```json
"slots": {
  "primaryApp": {
    "kind": "binding",
    "accepts": ["app.reference"],
    "operation": "reference",
    "replacePolicy": "allow",
    "allowClear": true
  },
  "favorites": {
    "kind": "collection",
    "accepts": ["desktop.item", "app.reference", "filesystem.reference"],
    "operation": "reference",
    "capacity": 32
  }
}
```

每包最多声明 16 个槽位，集合容量为 1–64。`slots.binding(id)` 与
`slots.collection(id)` 只接受 manifest 中同 kind 的 ID。读取方法 `id/revision/state/
capacity/item/items` 可在 view 中调用；`bind/add/clear/remove/move` 会持久化宿主管理模型，
只能由当前可信用户 action 调用，预览和普通 render/data/timer 回调会以
`userGestureRequired` 或 `previewReadOnly` 拒绝。`bind/add` 接受 `app.search`、
`desktop.search`、`everything.search` 或文件引用任务返回的当前实例 opaque ref，成功后
返回 `SnowLogicalSlotChange`；槽位会发出新的持久 opaque `item.reference`，可继续交给
`view.referenceIcon` 显示宿主图标，或交给对应的 `app.launch`、
`shell.openItem/revealItem` 任务执行受权限和可信手势约束的操作。
当宿主应用目录核对改变持久应用引用的可用性时，revision 同样递增并发送 operation 为
`availability`、source 为 `host.catalog` 的 `slot.changed`；这类宿主状态更新不进入用户撤销历史。
文件系统引用的路径或文件/文件夹类型发生变化时使用同一 operation，source 为
`host.filesystem`。

声明式树必须准确反映同一宿主快照。binding 的 surface 可有一个 placeholder 或一个
`slotItem`；有绑定时必须提交该 item。collection 的直接 children 必须按宿主顺序完整提交
为 `slotItem`。伪造、漏掉、重复或交换 reference，以及可选 `revision` 不匹配，都会拒绝
整棵新树并保留上一棵成功树：

```lua
local favorites = slots.collection("favorites")
local children = {}
for _, item in ipairs(favorites:items()) do
    children[#children + 1] = view.slotItem({
        key = item.id,
        reference = item.reference,
        accessibility = { label = item.title },
        child = view.text({ key = item.id .. ".title", text = item.title }),
    })
end

return view.slotSurface({
    key = "favorites",
    collection = "favorites",
    revision = favorites:revision(),
    dropStyle = {
        background = "surfaceVariant",
        borderColor = "borderStrong",
        foreground = "systemAccent",
        borderWidth = 2,
        cornerRadius = 10,
        opacity = 0.8,
    },
    emptyContent = view.text({
        key = "favorites.empty",
        text = "Drop a favorite here",
        textAlign = "center",
    }),
    children = children,
})
```

探测 `view.logicalSlots.emptyContent` 后，binding 和 collection 的 `slotSurface` 都可携带一个
可见 `emptyContent` 节点。宿主快照为空且本次没有 `slotItem` children 时，该节点成为唯一直接
child 并填满 surface；快照非空时它不会替换真实条目，Lua 漏报条目或伪造空态仍会拒绝整棵新树。
旧 binding 用单个 `child` 表示空态的写法继续兼容，但新组件应使用 `emptyContent`，以便与已绑定
条目的 `child` 明确分离。`loadingContent` 仍只属于普通/虚拟集合，逻辑槽位没有 Lua 自定的加载态。

探测 `view.logicalSlots.dropStyle` 后，`slotSurface` 可声明 `dropStyle`。只有宿主已经按
manifest `accepts`、容量和替换策略确认当前对象可以放置时才显示该样式；它不能放宽接收规则，
也不能改变命中范围。`background`、`borderColor`、`borderWidth`、`cornerRadius` 和 `opacity`
作用于整个经过裁剪的合法 surface，`foreground` 只设置宿主插入线或空槽轮廓颜色。语义颜色
token 会按组件主题和系统高对比度解析；省略某个颜色时保留对应的宿主默认反馈。桌面/Explorer
原生拖入、`slots.pointerReorder` 的同槽重排和 `slots.pointerTransfer` 的跨槽转移使用同一目标样式，但插入位置、线宽和拖放对象仍
完全由宿主管理，Lua 不会收到逐帧坐标或原生对象。

探测 `slots.pointerReorder` 后，collection 中有至少两个项目时，用户可从任一已提交
`slotItem` 内直接按住拖动。未越过系统拖动阈值时仍按普通声明式 click 处理；越过后由宿主
接管捕获，实时绘制源项目轮廓和插入线，释放时按 item ID 原子调用同槽 move，并写入同一
undo/redo 历史。成功变化通过 `slot.changed` 以 `source="host.pointer"` 投递；Lua 不接收
高频拖动坐标，也不能伪造插入位置。binding 和槽位外拖出不属于该 feature。

探测 `slots.pointerTransfer` 后，即使来源 collection 只有一个项目，也可继续拖到同一组件内
另一个已提交、类型兼容且未满的 collection。目标已有同一 kind/target 时拒绝重复；释放后
宿主保留原 opaque item ID/reference，同时更新两个 revision，并把转移记为一个历史事务。

探测 `slots.keyboardNavigation` 后，选中单个 Lua 组件时按 `Tab` / `Shift+Tab` 可进入并循环
当前已提交且可见的 `slotItem`，方向键按屏幕空间位置移动宿主焦点，`Escape` 退出。若焦点项
自己声明了 `events.click`，`Enter` 或空格会以可信 `source="keyboard"` action 激活它；宿主
不会猜测或代替触发其任意子控件。collection 焦点项可用 `Alt+方向键` 在同槽内原子移动，
`Delete` 可移除 collection 项或 `allowClear=true` 的 binding，二者都进入同一 undo/redo
历史，并以 `slot.changed source="host.keyboard"` 通知 Lua。宿主直接绘制焦点轮廓，不向 Lua
投递高频按键；普通声明式控件使用 `view.keyboardNavigation.basic`，UI Automation 仍未完成。

提交成功的 `slotSurface` 现在也是宿主原生拖放面。桌面项目、应用快捷方式或 Explorer
文件拖到该区域时，宿主先按 manifest 的 `accepts`、binding 替换策略及 collection 容量
进行命中判断，再显示插入预览并原子保存引用；不会移动、复制或删除真实对象。当前原生
入口一次只接收一个对象，多选拖入会在命中前拒绝。组件或组件分组标签不会进入逻辑槽位。

探测 `slots.hostPicker` 后，可在当前可信 action 中调用 binding 或 collection 句柄的
`pick()`。宿主会打开复用快速导航索引的选择界面，只显示 manifest `accepts` 允许的应用、
桌面项目或文件候选；选择结果直接成为持久化 opaque reference，collection 默认追加一项。
选择器不会授予文件内容权限，取消也不会产生事务；collection 满容量时不会打开。

宿主拖放、选择器或槽位项菜单提交后会派发 `event.kind == "slot.changed"`，字段为 `slotId`、
`slotKind`、`revision`、`operation`、opaque `itemIds`，以及 `source == "host.drop"`、
`"host.picker"`、`"host.menu"`、`"host.pointer"` 或 `"host.keyboard"`。Lua 应重新读取对应句柄并重算 view，不能把事件内容
当作可写模型。可分别探测 `slots.nativeDrop`、`slots.nativeContextMenu`、
`slots.pointerReorder`、`slots.keyboardNavigation` 与 `slots.event.changed`。原生槽位项菜单只显示该项的向前/向后移动和移除操作，不会附加
组件总菜单；binding 是否能移除遵守 manifest 的 `allowClear`。同一组件内从一个 collection
拖到另一个兼容 collection 时，`operation="transferred"`，主 `slotId/revision` 表示目标，
`relatedSlotId/relatedRevision` 表示来源；opaque item ID/reference 保持不变，两个槽位作为
一个事务持久化和撤销。目标类型不接受、已有同一引用或容量已满时不提交。原生槽位项拖出及
跨组件/跨实例转移仍未接入。

探测 `slots.history` 后，可在当前可信用户 action 中调用 `slots.undo()` / `slots.redo()`；
它们按组件实例维护最近 32 次宿主槽位事务，返回 operation 为 `undone` / `redone` 的
`SnowLogicalSlotChange`。`slots.canUndo()` / `slots.canRedo()` 可在 view 中读取。新事务会清空
redo 栈，热重载或重启不会恢复历史。探测 `slots.hostHistory` 后，选中单个 Lua 组件时
宿主还会将 Ctrl+Z、Ctrl+Shift+Z 和 Ctrl+Y 路由到同一历史；没有可用槽位历史时不会
吞掉原桌面快捷键。键盘槽位操作与 Lua 主动调用的历史操作共享相同的最近 32 次边界。

### `interaction` 与元素级菜单

即时绘制没有宿主可识别的元素。`interaction.region(spec)` 在 `render` 内为当前
桌面 surface 提交语义命中区域；一次成功 render 会原子替换上一成功帧的完整集合，
render 抛错时继续使用上一集合。首版最多 256 个 region，稳定 `key` 为 1 到 128
个 UTF-8 字节，后提交的重叠区域位于上层。

```lua
local function render(context, model)
    local key = "primary-action"
    local hovered = interaction.isHovered(key)
    local pressed = interaction.isPressed(key)
    draw.rect(12, 12, 120, 36,
        pressed and 0x315F8F or (hovered and 0x477FB5 or 0x365F86), 8)
    draw.text(28, 20, "Open", 15, 0xFFFFFF)
    interaction.region({
        key = key,
        shape = { type = "roundedRect", x = 12, y = 12,
            width = 120, height = 36, radius = 8 },
        cursor = "hand",
        events = {
            click = { id = "item.open", value = { itemId = "primary" } },
            contextMenu = { id = "item.menu",
                value = { itemId = "primary" } },
        },
        accessibility = { role = "button", label = "Open" },
    })
end
```

shape 首版支持 `rect`、`roundedRect` 和 `circle`；cursor 支持 `default`、`hand`、
`text`、`crosshair`。events 支持 `pointerEnter`、`pointerLeave`、`pointerDown`、
`pointerUp`、`pointerMove`、`click`、`doubleClick`、`wheel` 和 `contextMenu`。
动作 `value` 会被深拷贝，只允许 nil、布尔、有限数字、字符串、连续数组和字符串键
对象，限制 8 层、256 个节点和合计 16 KiB 字符串。普通 hover/click 不需要权限。

探测 `interaction.pointerCapture` 后，即时 region 也可声明 `capturePointer=true`，并同时绑定
`pointerMove` 或 `pointerUp`。其主指针捕获、终止条件和不合成越界 click 的规则与声明式节点一致。

探测 `interaction.tooltip` 后，region 可声明最多 4096 UTF-8 字节的字符串 `tooltip`；探测
`interaction.tooltip.rich` 后也可使用与声明式节点相同的 `{title?, text}`。两者都由宿主在命中区域内
显示，不是任意 markup 或窗口。探测 `interaction.keyboard` 后，region 可声明
`focusable`、`tabIndex=-1..32767` 及 `events.keyDown/keyUp`。默认仍从受控类型、click 或文本输入
role 推导焦点；显式 `focusable=false` 会退出焦点，key 观察目标必须可聚焦。按键事件与声明式
版本使用相同负载和按下/释放配对，`interaction.isFocused(key)` 可用于绘制焦点状态；这些事件
不能取消宿主激活、组件槽位快捷键或字符/IME 输入。

即时绘制滚动区域使用 `interaction.scroll(spec)`，不要调用 v1
`ui.scrollArea`：

```lua
local scroll = interaction.scroll({
    key = "items",
    shape = { type = "rect", x = 0, y = 0,
        width = layout.width(), height = layout.height() },
    contentHeight = 1200,
})
draw.pushClip(0, 0, layout.width(), layout.height())
-- 使用 scroll.offset 把内容坐标换算为视口坐标后绘制。
draw.popClip()
```

scroll key 同样是实例内稳定的 1–128 字节 UTF-8 字符串；只接受正尺寸 rect。默认纵向并要求
`contentHeight`；探测 `interaction.scroll.orientation` 后可声明 `orientation="horizontal"` 并改用
`contentWidth`，两个 content 字段互斥且上限均为 1,000,000 逻辑单位。返回值始终包含主轴
`offset/maximum/orientation/viewportExtent/contentExtent`，并按轴额外返回
`viewportHeight/contentHeight` 或 `viewportWidth/contentWidth`。宿主处理滚轮和触控板 wheel
增量、钳制偏移、重绘及对应方向滚动条；组件必须用成对的 `draw.pushClip/popClip` 裁剪内容。
`interaction.setScrollOffset(key, offset)` 只在当前 render 已注册同 key 区域后设置并
返回实际偏移。滚动不需要 `ui.input` 权限，基础 feature 为 `interaction.scroll`，横向扩展为
`interaction.scroll.orientation`。

右键命中带 `contextMenu` 绑定的 region 后，宿主同步调用 descriptor 的 `menu`：

```lua
local menuOpenImage = resource.image("menuOpen")

local function menu(_context, _model, request)
    if request.id ~= "item.menu" then return nil end
    return ui.menu({
        { id = "item.open", label = "Open", image = menuOpenImage },
        { id = "item.pin", label = "Pin", checked = false },
        { label = "Open with", children = {
            { id = "item.open.editor", label = "Editor" },
            { id = "item.open.browser", label = "Browser" },
        } },
        { type = "separator" },
        { id = "item.remove", label = "Remove" },
    })
end
```

基础菜单项支持唯一字符串 `id`、`label`、`enabled`、`checked`、separator 和宿主
字体 glyph。探测 `interaction.contextMenu.submenu` 后，无 `id` 的普通项可通过 `children`
形成子菜单；动作 `id` 在整棵树中唯一，最多嵌套 3 层，整棵树（含父项和分隔线）最多 64 项。
探测 `interaction.contextMenu.resourceImage` 后，普通项或子菜单父项可用 `image=resource.image(...)`
显示已声明的包内图片；它与宿主字形 `icon` 互斥，不接受媒体封面、剪贴板图片等临时运行时句柄。
宿主从已解码的包资源缓存生成按菜单 DPI 限制尺寸的预乘 alpha 位图，菜单关闭后释放副本；禁用项
降低整体图像不透明度。图片解码失败时 `resource.image(...)` 已在组件入口加载阶段报错，不在打开
菜单时同步读取文件。
回调必须同步、快速且不执行 I/O。用户选择叶子项后收到
`event.kind == "action"`，其中 `id` 为菜单项 ID，`source == "contextMenu"`，并带
原 region 的 `targetKey` 与 `value`。菜单打开后只要 region 集合产生新一代提交，
旧菜单动作就会失效，避免重排或复用 key 后误操作。`request.scope` 为 `element` 或
`component`；元素级菜单独立显示，组件级菜单才与 SnowDesktop 的设置、授权、诊断和
移除入口合并。该 API 不要求 `ui.contextMenu` 权限；对应 feature 为
`interaction.region`、`interaction.pointerActions` 和 `interaction.contextMenu`；嵌套菜单另需
`interaction.contextMenu.submenu`，包内图片另需 `interaction.contextMenu.resourceImage`。
- v2 不暴露旧 `widget.editText(...)`；文本编辑统一使用声明式输入节点或
  `control.textInput/textArea`。

### `control` 文本编辑

`control.textInput(spec)` 和 `control.textArea(spec)` 是即时绘制 surface 的兼容入口；新声明式
组件应优先使用 `view.inputControls`。这两个函数仍是
宿主管理文本编辑器。组件在每次 `render` 中提交稳定描述符，宿主继续使用 Direct2D
绘制透明背景、光标、选择、占位文本和 IME 组合下划线；输入值绑定到实例
`storageKey`，函数返回当前字符串。它们不属于声明式节点，也不向
Lua 暴露剪贴板内容或原生窗口句柄。

```lua
local value = control.textArea({
    key = "note",
    storageKey = "text",
    shape = {
        type = "rect",
        x = layout.cu(12),
        y = layout.cu(12),
        width = layout.width() - layout.cu(24),
        height = layout.height() - layout.cu(48),
    },
    placeholder = l10n.tr("lua_widget.note.placeholder"),
    fontSize = layout.fontCu(15),
    maxBytes = 65536,
    liveUpdate = true,
})
```

共同字段为 `key/storageKey/shape`，以及 `placeholder/fontSize/textColor/
placeholderColor/backgroundColor/borderColor/focusedBorderColor/backgroundAlpha/
focusedBackgroundAlpha/borderAlpha/focusedBorderAlpha/radius/padding/
borderThickness/selectAll/liveUpdate/maxBytes`。shape 只接受正尺寸 `rect`；key 和
storageKey 是 1–128 字节有效 UTF-8。颜色是 `0xRRGGBB`，alpha 是 0–1，字号范围
9–96。单行 `maxBytes` 默认 4096，多行默认 65536，允许范围 1–65536；粘贴、普通
输入和 IME 提交按编辑后的最终 UTF-8 大小原子接受或拒绝，不会先删除选择再留下
半次修改。旧存储若已经超限仍可删除内容，宿主不会静默截断。

`textArea` 额外支持 `placeholderWhenWhitespace`。两个控件都支持点击定位、拖选、
Shift 选择、Ctrl+A/C/X/V、Escape 恢复焦点前内容；多行 Enter 插入换行、
Ctrl+Enter 提交，滚轮与光标跟随会调整实例内滚动位置。普通文本输入不要求权限，
剪贴板只由宿主在聚焦控件内处理，并没有开放通用剪贴板 API。探测
`view.keyboardNavigation.basic` 后，这两个即时兼容控件也进入所属 desktop/panel
surface 的 Tab 顺序。

`control.focus(key)` 只能在直接 click/doubleClick/pointerDown/pointerUp/wheel、菜单命令
或宿主明确标记的打开回调同步栈中接受；render、panel render、schedule、data.change 和
task.complete 不能抢走键盘焦点。探测 `view.focus.request` 后，key 除文本输入外还可
指向最后一棵成功视图中的任意启用、可聚焦元素，包括普通按钮、列表项和逻辑槽位项；槽位焦点
状态会同步更新。若该操作同时把目标加入界面树，宿主会把
最新一次聚焦请求保留到同一 surface 的下一次成功渲染，并在提交控件后聚焦；若届时
仍未提交目标控件，则清除请求并记录诊断，不会在更晚的无关界面中意外聚焦。返回
`(accepted, error)`，稳定失败码为 `trustedGestureRequired`、`controlNotFound` 或
`hostUnavailable`。对应 feature 为 `control.textInput`、`control.textArea` 和
`control.focus`；通用声明式目标另要求 `view.focus.request`。

`control.blur(key)` 同样只接受上述可信手势同步栈。它只在 key 与当前 surface 中已聚焦的
文本控件完全匹配时提交当前值并失焦，从而清除光标、选择和焦点框；不会误清除其他控件的
焦点。返回 `(blurred, error)`，稳定失败码为 `trustedGestureRequired`、
`controlNotFocused` 或 `hostUnavailable`，对应 feature 为 `control.blur`。

### `schedule`

- `schedule.every(id, milliseconds, options?)`：创建或替换一个重复计划。
- `schedule.after(id, milliseconds, options?)`：创建或替换一个单次计划。
- `schedule.at(id, epochMilliseconds, options?)`：按 UTC epoch 毫秒创建或替换一个
  单次绝对时间计划，最远可设置 366 天；过去时间在下一次宿主唤醒时合并触发。
- `schedule.timeline(id, entries, options?)`：创建或替换一组按绝对时间排列的状态条目；
  `entries` 为 1–64 个 `{ at=UTC毫秒, value=JSON-like值 }`，`at` 必须严格递增且
  最远不超过 366 天。
- `schedule.cancel(id)`：取消计划，存在并取消时返回 `true`。

ID 为 1–128 字节，每个实例最多 32 个计划；周期请求范围是 1 ms–24 小时，
宿主最小实际周期为 100 ms。跨过多个重复截止时间时只分发一个
`event.kind == "schedule"` 事件，并通过 `now`、`missed` 和 `coalesced` 报告实际分发
时间与合并结果。
timeline 跨过多个条目时也只分发最新到期值，并额外返回 `value`、一基
`timelineIndex`、`timelineCount` 和 `timelineEnded`；`missed` 是本次省略的较早
条目数。所有条目的 value 合计最多 256 个节点、8 层和 16 KiB 字符串，语义与
`SnowStateValue` 一致。
`options.whenHidden` 支持 `pause`、`throttle`（默认）和 `continue`。pause 隐藏时不
保留宿主唤醒，恢复后只发送一个合并事件并报告 `missed`；throttle 隐藏时使用
5000 ms 最小周期；对绝对时间 timeline，throttle 与 continue 都保留绝对截止时间。
卸载、热重载和关闭会自动取消实例计划。

`schedule.timeline` 的 `options.reload` 可为 `none`（默认）或 `atEnd`。`atEnd` 不会
直接重跑 Lua；最终事件会设置 `reload=true`，组件应在事件回调中发布下一组 timeline。
它对应 feature `schedule.timeline`。`schedule.at` 对应 feature `schedule.absolute`；
系统时钟在宿主重新计算截止时间时会重新投影到单调时钟，避免用可回拨的 wall clock
计算经过时长。预览执行使用固定虚拟 wall/monotonic 时钟；schedule 会完成参数校验并
登记到预览实例，但不创建系统计时器或自行推进时间，对应 feature
`time.previewClock`。已移除的 `onTimer` 不进入正式 VM；组件不得依赖清单
`refreshIntervalMs` 过渡事件。

### `animation`

- `animation.requestFrame(id)` 请求一次宿主合并的下一帧事件，成功返回 `(true, nil)`。
- `animation.cancelFrame(id)` 取消尚未分发的同名请求；确有请求被取消时返回 `true`。

ID 必须是 1–128 字节有效 UTF-8；同名请求在同一帧内合并，每实例最多同时保留 16 个
不同 ID。宿主约 16 ms 后分发 `event.kind == "frame"`，并提供 `id`、单调时钟
`now` 和相对同一 ID 上一帧的 `deltaMs`；首帧和隐藏后恢复的首帧为 0，过长间隔
封顶为 1000 ms。一次请求只产生一次事件，组件必须在 frame 事件中再次调用
`requestFrame` 才会继续，因而不会创建永久隐式 60 FPS 循环。

隐藏、卸载、热重载和宿主关闭会立即取消请求且不补帧；预览不启动真实计时器，系统启用
“减少动态效果”时也拒绝逐帧回调。稳定失败码为 `hidden`、`reducedMotion`、
`previewUnavailable`、`quotaExceeded`、`hostUnavailable` 或 `apiVersion`。此 API 不要求
权限，对应 feature `animation.frame`；它只适合短时即时视觉更新，低频刷新仍应使用
`schedule`，系统状态、媒体和音频数据仍应使用按需 `data.subscribe`。

### `data`

当前公开二十五个按需数据源：`system.cpu`、`system.memory`、`process.summary`、`system.gpu`、`system.power`、
`system.network.status`、`system.network.traffic`、`system.storage.volumes`、
`system.storage.io`、`system.display.topology`、`system.display.current`、
`audio.output.default`、`audio.output.volume`、`audio.output.analysis`、
`media.sessions`、`media.current`、`media.timeline`、`media.artwork`、`desktop.items`、
`desktop.selection`、`desktop.changes`、`calendar.events` 和
`calendar.selectedDate`、`app.indexStatus`，以及 `filesystem.watch`。在 `setup` 或模块
入口创建订阅，不要在每次 `render` 中重复订阅：

```lua
local cpu

local function setup()
    cpu = data.subscribe("system.cpu", {
        maxAgeMs = 1000,
        whenHidden = "throttle",
    })
end

local function render()
    local snapshot = cpu:value()
    if snapshot.available then
        draw.text(12, 12, string.format("CPU %.1f%%",
            snapshot.value.usagePercent))
    elseif snapshot.warmingUp then
        draw.text(12, 12, "CPU …")
    end
end
```

`data.subscribe(topic, options?)` 返回句柄。`options.maxAgeMs` 为 1–86400000，
表达请求采样周期；快照在连续错过下一次完整采样机会后才标记 `stale=true`，
不会因为线程调度比请求周期晚几毫秒而短暂过期。CPU 最快 500 ms，内存和进程摘要最快 1000 ms，
电源、存储卷和显示拓扑最快 2000 ms；存储 I/O、默认音频端点和主音量最快
1000 ms，媒体三个 topic 最快 500 ms，桌面和日历事件 topic 最快 100 ms，
音频分析最快 16 ms。`whenHidden` 可为
`pause`、`throttle`（默认）或 `continue`；
当前系统 provider 不承诺后台 continue，因此会收敛为隐藏 throttle。
`handle:value()` 返回
`available/value/timestamp/stale/warmingUp/error` 包络，CPU value 包含
`usagePercent/logicalProcessors/name`，内存 value 包含
`totalBytes/usedBytes/freeBytes/commitLimitBytes/commitUsedBytes/commitAvailableBytes/usagePercent`，电源 value 包含
`acPower/charging/saver/batteryPercent/estimatedRemainingSeconds?`。CPU 首次
差分采样可能暂时 `warmingUp=true`；无电池设备返回
`available=false,error="notPresent"`。`handle:unsubscribe()` 主动释放；卸载、
热重载和关闭也会自动释放。

所有轮询采样 provider 都在 API 层统一稳定包络语义：数值、速率和仍处于可用态的
value 会逐样本更新；从可用态进入 `warmingUp`、不可用或错误态时，必须连续两次采样
得到相同包络后才发布，单次异常采样继续返回上一份稳定 value 并刷新时间戳；恢复到
可用态立即发布。桌面、日历、应用索引和文件监听等事件驱动 topic 直接发布权威事件，不人为延迟；
权限撤销同样立即生效，不参与采样稳定。

`process.summary` 受独立的 `process.summary.read` 保护。value 的 `processes` 固定最多
12 项，按总机器 CPU 占比、private bytes 和 working set 排序；每项只含进程生命周期内
稳定的 opaque `id`、用于显示的可执行文件基本名、0–100 的 `cpuPercent`、
`workingSetBytes` 和 `privateBytes`。`observedCount/truncated` 明确报告宿主实际可查询的
候选是否被截断。首轮尚无 CPU 差分基线时返回内存排序并标记 `warmingUp=true`；该高风险
topic 隐藏时强制暂停，最后一个可见订阅释放后立即停止枚举并清除快照。它不返回 PID、路径、命令行、窗口标题、用户名、token、
进程内存内容或任何控制句柄，受保护/不可查询的进程也不会伪造成零值条目；预览只返回固定
模拟进程。

GPU value 的 `adapters` 是数组；每项包含不透明 `id`、显示 `name`、
`usagePercent`、`dedicatedMemoryBytes/dedicatedUsedBytes` 和
`sharedMemoryBytes/sharedUsedBytes`。两个容量来自 DXGI adapter 描述；两个 used 字段
分别来自 Windows `GPU Adapter Memory` 的 Dedicated Usage 和 Shared Usage，并按
adapter LUID 归属，不能把核显 LOCAL segment 当作专用显存。宿主不会只返回第一块
GPU；首次 PDH 差分样本为 `warmingUp=true`。最后一个 GPU 订阅释放后会关闭 PDH
query，不会因 CPU、内存或网络仍有订阅而继续采样 GPU。

网络 status value 包含 `connectivity`（`none/local/internet`）、`transport`
（`none/ethernet/wifi/cellular/other`）、`costKnown/metered/roaming/overLimit`。
宿主会对 status 的语义变化做两次连续采样确认：首次状态立即发布，后续只有连续两次
采样得到相同的新语义才切换；单次相反或异常采样继续返回上一稳定语义，但使用本次
采样时间戳保持快照新鲜。权限撤销仍由授权层立即生效，不经过此稳定处理。
traffic value 包含 `connected/receivedBytes/sentBytes/downloadBytesPerSecond/
uploadBytesPerSecond`，首次差分样本为 `warmingUp=true`。状态和流量是两个独立
topic；只订阅状态不会启动流量差分采样。两者都不会返回 IP、MAC、SSID、BSSID
或主机名。

存储卷 value 的 `volumes` 是当前可访问挂载卷数组。每项包含不透明 `id`、
`displayName/mountPoint/kind/capacityBytes/freeBytes/capacityAvailable/removable/readOnly`；
`mountPoint` 只用于显示，不能作为文件 API 的路径或授权句柄。空光驱等无法读取
容量的设备以 `capacityAvailable=false` 表示；宿主不会为了刷新快照同步访问远程卷，
避免断开的网络映射拖住其他共享 provider。预览使用固定模拟卷，不枚举开发机。

存储 I/O value 是所有物理磁盘的有界聚合，包含 `readBytesPerSecond`、
`writeBytesPerSecond` 和钳制到 0–100 的 `busyPercent`，不包含磁盘序列号或文件路径。
首次 PDH 差分样本为 `warmingUp=true`；最后一个 I/O 订阅释放后立即关闭该 PDH query，
不会因卷列表或其他系统 topic 仍有订阅而继续采样。

显示拓扑 value 的 `displays` 是所有活动显示器数组；每项包含不透明 `id`、显示
`name`、`primary`、逻辑 `bounds/workArea`、像素 `pixelBounds/pixelWorkArea`、
`dpiX/dpiY/scale/refreshHz/orientation`，以及 `hdrKnown/hdrSupported/hdrEnabled`。
Windows 无法报告高级颜色状态时 `hdrKnown=false`，不能把两个 false 当成设备明确
不支持 HDR。预览返回单个固定显示器，不读取开发机拓扑。

`system.display.current` 使用同一份共享显示元数据，但按订阅所属实例的 surface
边界选择当前显示器，value 通过 `display` 返回单项 `SnowDisplayDataValue`。组件跨屏
移动后宿主会在下一次拓扑快照匹配新显示器；匹配前返回
`available=false,error="currentDisplayUnavailable"`，不会错误回退到主显示器。

`audio.output.default` value 包含默认 multimedia render endpoint 的不透明 `id`、
Windows 友好 `name` 和 `state`；`audio.output.volume` 包含匹配的 `endpointId`、
0–1 主音量 `volume`、`muted` 和 `minimum/maximum`。没有输出设备时返回
`available=false,error="notPresent"`。这两个 topic 只读取 endpoint 元数据与主音量，
不会启动 loopback、取得 PCM 或暴露原生 endpoint ID；预览使用固定模拟设备。

`audio.output.analysis` 使用独立 WASAPI loopback 线程。默认 value 返回 128 点
`waveform`、64 个 `spectrum` bin、`rms/peak/silent/deviceChanged`、不透明
`endpointId` 及源 `sampleRate/channels`。waveform 已下混为 mono 且限制在 -1–1，
频谱使用 20 Hz 至 8 kHz（受分析窗分辨率和源 Nyquist 频率限制）的对数频带，使低频占据
更多可视宽度并减少高频柱数；低频、中频和高频仍按听感展开。频谱和电平限制在 0–1。
Lua 不取得 PCM、无限历史或每进程音频。

订阅可通过 `features` 选择 1–4 个不重复的 `waveform/rms/peak/spectrum`；未选择的
派生字段不会出现在 value 中。`waveformPoints` 为 16–256，`spectrumBins` 为 16–128，
并且只能在相应 feature 启用时提供。`updateHz` 为 1–60 的整数，与 `maxAgeMs` 互斥；
两者都是投递频率上限请求，而非硬实时保证。该高风险 topic 强制
`whenHidden="pause"`。宿主在所有已授权可见订阅间取特征并集、最大点数和最高刷新率，
只运行一条捕获/分析管线，再按每个订阅的配置裁剪字段和降采样。

四个媒体 topic 受 `media.read` 保护，并在同一 provider 采样周期内合并读取：
`media.sessions` value 返回最多 32 个会话和当前会话的不透明 ID，`media.current`
value 通过 `session` 返回当前会话，`media.timeline` value 通过 `timeline` 返回当前
时间线。每个会话包含受限到 4096 字节的 `sourceName/title/artist/album`、播放状态、
逐动作 `can*`、相对 `positionMs/durationMs` 和 seek 范围；没有当前会话时 current
和 timeline 返回 `available=false,error="notPresent"`，会话列表则是可用的空数组。
`media.artwork` 只返回当前会话的 `sessionId`、临时 `image` resource handle 和不超过
512×512 的 `width/height`。宿主在工作线程读取最多 4 MiB 的编码数据，拒绝边长超过
16384 的源图，并解码为有界 PBGRA 像素；Lua 不取得编码原图、缓存路径或像素字节。
该句柄可直接传给 `draw.image` 或 `view.image.source`，最后一个订阅取消后对应 CPU/GPU
缓存立即清除，因此不应持久化句柄。无封面使用 `notPresent`；读取、查询、解码、尺寸等
失败分别使用稳定错误码。预览返回固定 64×64 模拟封面，不读取开发机媒体状态。

三个桌面 topic 受 `desktop.read` 保护且由宿主变更事件驱动，不启动轮询线程。
`desktop.items` 返回最多 2048 项，`desktop.selection` 返回最多 512 项；每项只有
稳定宿主引用 `id` 和 `title/source/type/selected` 展示字段，不向 v2 返回绝对路径。
`desktop.changes` 返回单调 `revision` 与最长 64 字节的宿主 `reason`，用于判断何时
重新读取列表。预览使用固定项目；取消最后订阅时没有后台 worker 或系统句柄残留。

`calendar.events` 和 `calendar.selectedDate` 受 `calendar.read` 保护，同样不启动
轮询线程。events 可在订阅选项中同时传入 `fromDate/toDate`（ISO `YYYY-MM-DD`、
闭区间、最长 366 天）；未传时使用当前选中日期前后各 62 天。value 返回实际
`fromDate/toDate`、最多 512 个本地事件、`revision` 和 `truncated`，事件包含
`id/revision/title/date/allDay/startMinutes/endMinutes/notes/reminderMinutes`。
selectedDate value 返回 `date/revision`。创建、修改和删除日程仍不由这些只读 topic
执行；`calendar.selectDate(date)` 只改变 SnowDesktop 内部共享选中日期，不修改事件，
因此不要求 `calendar.write`。纯 `calendar.dateInfo/addDays` 也不读取用户数据、不要求
权限。对应 feature 为 `calendar.selection` 和 `calendar.dateMath`；预览返回固定日期
和事件。

`app.indexStatus` 受 `app.discovery` 保护，value 返回 `state/revision`。当前宿主
应用索引真实返回 `indexing`、`ready` 或 `unavailable`；缺失时以
`available=false,state="unavailable",error="providerUnavailable"` 明确报告，
应用索引变更推进 revision。该 topic 不携带完整应用目录，搜索结果由有界
`app.search` 任务获取。

CPU、内存和 GPU 受 `system.performance.read` 保护，电源受 `system.power.read` 保护，
进程摘要单独受 `process.summary.read` 保护，
两个网络 topic 受 `system.network.read` 保护，两个存储 topic 受
`system.storage.read` 保护，显示拓扑受 `system.display.read` 保护。
基础两个音频输出 topic 受 `audio.output.read` 保护；分析 topic 单独受
`audio.output.analyze` 保护。分析是高风险 provider：只有已授权且可见的实例持有
订阅时运行，隐藏、撤销、卸载或取消最后一个订阅会立即停止并清空，忽略
`whenHidden="continue"`；预览只返回确定性模拟波形。
需要无权限降级的组件应把对应权限声明在 `optionalPermissions`，并处理
`available=false,error="permissionDenied"`；预览返回稳定模拟值且不会读取本机
状态。对应 feature ID 是 `data.subscribe`、`data.system.cpu`、
`data.system.memory`、`data.process.summary`、`data.system.gpu`、`data.system.power`、
`data.system.network.status` 和
`data.system.network.traffic`、`data.system.storage.volumes` 和
`data.system.storage.io`、`data.system.display.topology` 和
`data.system.display.current`，以及 `data.audio.output.default`、
`data.audio.output.volume` 和 `data.audio.output.analysis`，以及
`data.media.sessions`、`data.media.current`、`data.media.timeline` 和
`data.media.artwork`。
桌面 topic 对应 `data.desktop.items`、`data.desktop.selection` 和
`data.desktop.changes`。
日历 topic 对应 `data.calendar.events` 和 `data.calendar.selectedDate`。
应用索引状态对应 `data.app.indexStatus`。

### `task`

当前公开异步媒体动作 `media.play`、`media.pause`、`media.toggle`、`media.stop`、
`media.next`、`media.previous`、`media.seek`、`media.setRate`、`media.setShuffle`、
`media.setRepeat`，
默认音频输出动作 `audio.output.setVolume/setMute`，应用任务
`app.search`、`app.launch`，桌面项目任务 `desktop.search`、`everything.search`、
`shell.openItem`、`shell.revealItem`、`desktop.refresh`，通知任务
`notification.show/update/dismiss/schedule/cancel`，以及本地日历写入任务
`calendar.create`、`calendar.update`、`calendar.remove`、公网读取
任务 `network.request`、外部链接动作 `shell.openUri`、受控设置动作
`system.openSettings`、有界剪贴板任务 `clipboard.read/write/clear`，以及用户选择文件
范围的 `filesystem.pickOpen/pickSave/pickFolder`。它们对应
feature ID `task.start`、`task.media.control`、`task.audio.output.control`、`task.app.search`、`task.app.launch`
、`task.notification.show`、`task.notification.lifecycle`、`task.notification.schedule`、
`task.notification.structured`、`task.notification.actions`、
`task.calendar.write`、`task.network.request` 和
`task.shell.openUri`、`task.system.openSettings`、`task.clipboard.text`、
`task.clipboard.image`、`task.clipboard.fileReference`、
`task.filesystem.picker`、`task.filesystem.access`、`task.filesystem.binary`，以及 `task.desktop.search`、`task.everything.search`、
`task.shell.item`、`task.desktop.refresh`。媒体动作要求 `media.action` 权限，而且只能在
`click/doubleClick/pointerDown/pointerUp/wheel`、宿主按钮、菜单命令或由宿主明确
标记来源的打开回调同步调用栈内启动：

```lua
local taskId, err = task.start("media.toggle", {
    sessionId = session.id,
})
if not taskId then
    widget.log("warn", "media task rejected: " .. tostring(err))
end
```

默认音频输出动作要求 `audio.output.control` 和同样的可信用户手势，只作用于调用时
Windows 当前默认的 multimedia render endpoint：

```lua
local volumeTask = task.start("audio.output.setVolume", { volume = 0.65 })
local muteTask = task.start("audio.output.setMute", { muted = true })
```

`volume` 必须是有限数值，宿主在 Core Audio 调用前钳制到 0–1；`muted` 必须是布尔值。
宿主用自己的事件来源 GUID 标记修改，并对同一组件实例的音频修改设置 100 ms 最小
间隔。任务成功值为 `{ accepted = true }`；稳定错误包括 `rateLimited`、`notPresent`、
`audioEnumeratorUnavailable`、`audioEndpointUnavailable`、`audioVolumeUnavailable`、
`audioControlRejected`、`permissionRevoked` 和 `canceled`。该权限不授予非默认设备、
逐进程音频会话、默认设备切换或系统音频策略控制。

`system.openSettings` 要求 `shell.launch` 和当前可信用户手势，只接受宿主固定枚举的
`page`：`notifications/audio/display/network/bluetooth/power/storage/apps/personalization`。
宿主把枚举映射到微软公开的固定 `ms-settings:` 页面；Lua 不能传 URI、查询参数或
任意设置页名称：

```lua
local settingsTask = task.start("system.openSettings", {
    page = "audio",
})
```

成功值为 `{ accepted = true }`，表示 Windows 接受打开请求；稳定错误包括
`openRejected`、`permissionDenied`、`userGestureRequired` 和 `canceled`。预览只返回
确定性成功结果，不启动 Windows 设置。

剪贴板任务都要求当前可信用户手势，并按读取与修改分别检查 `clipboard.read` 和
`clipboard.write`。读取必须显式请求 `text`、`image` 或 `file-reference` format；写入
仍只接受 `text`，且最多 262144 字节、无 NUL、有效 UTF-8；清空不接受参数：

```lua
local readTask = task.start("clipboard.read", { format = "text" })
local imageTask = task.start("clipboard.read", { format = "image" })
local filesTask = task.start("clipboard.read", {
    format = "file-reference",
})
local writeTask = task.start("clipboard.write", {
    format = "text",
    text = "SnowDesktop",
})
local clearTask = task.start("clipboard.clear")

-- readTask 成功：event.value = { format = "text", text = "..." }
-- imageTask 成功：event.value = {
--     format = "image", image = imageHandle, width = 256, height = 256,
-- }
-- filesTask 成功：event.value = {
--     format = "file-reference",
--     items = { { ref = itemRef, name = "photo.png", type = "file" } },
-- }
-- write/clear 成功：event.value = { accepted = true }
```

任务在独立 worker 访问 Win32 剪贴板，同一实例最短间隔 100 ms；稳定错误包括
`rateLimited`、`clipboardBusy`、`formatUnavailable`、`clipboardTooLarge`、
`clipboardReadFailed`、`clipboardWriteFailed`、`clipboardImageDecodeFailed`、
`clipboardImageDimensionsInvalid`、`clipboardReferenceUnavailable`、
`permissionRevoked` 和 `canceled`。预览按所请求 format 返回确定性 mock，不访问真实
剪贴板。

图片输入块上限为 64 MiB，源尺寸每边上限 16384；宿主解码并等比缩放到每边不超过
512 像素，返回的临时 `SnowImageResource` 可直接用于 `draw.image` 或
`view.image.source`。句柄绑定当前组件实例，在热重载、实例卸载或运行时资源限额回收
后失效，不得持久化。文件引用一次最多返回 32 项，每项仅有 `{ref,name,type}`；`ref`
可用于 `draw.icon`、`shell.openItem` 和 `shell.revealItem`，但不暴露路径、不允许读取
文件内容，也不等同于 `filesystem` 授权。剪贴板历史仍未开放，组件不得用文本路径
冒充文件引用。

文件选择器只在当前可信用户手势中启动，并且只把用户实际选择的范围授予当前组件
包与当前实例。`filesystem.pickOpen` 要求 `filesystem.userSelected.read`；
`filesystem.pickSave` 要求 `filesystem.userSelected.write`；`filesystem.pickFolder`
的 `access=read/write/readWrite` 分别要求对应的一项或两项权限：

```lua
local openTask = task.start("filesystem.pickOpen", {
    extensions = { "txt", "md" },
})
local saveTask = task.start("filesystem.pickSave", {
    extensions = { "json" },
    suggestedName = "export.json",
})
local folderTask = task.start("filesystem.pickFolder", {
    access = "readWrite",
})

-- 成功：event.value = {
--   handle = "filesystem:...", kind = "file"|"folder",
--   access = "read"|"write"|"readWrite", name = "仅用于显示的名称"
-- }
```

`extensions` 最多 16 项，只接受无通配符的安全扩展名；`suggestedName` 只能是文件名，
不能传路径。句柄使用系统随机 token，保存于 Lua 普通存储之外的宿主注册表，并同时
绑定 package ID 与实例 ID；组件删除或软件包卸载时撤销。Lua 永远得不到绝对路径，
其他实例也不能解析或撤销该句柄。稳定错误包括 `permissionDenied`、
`userGestureRequired`、`userCanceled`、`pickerUnavailable`、`pickerFailed`、
`invalidSelection`、`handleQuotaExceeded`、`handlePersistenceFailed` 和 `canceled`。
预览返回固定虚拟句柄且不打开系统对话框。

`task.filesystem.access` 在同一句柄边界上公开 `stat/list/read/write/release`：

```lua
local statTask = task.start("filesystem.stat", { handle = selectedHandle })
local listTask = task.start("filesystem.list", {
    handle = selectedFolder,
    offset = 0,
    limit = 50,
})
local readTask = task.start("filesystem.read", {
    handle = selectedFile,
    encoding = "utf8",
    maxBytes = 512 * 1024,
})
local writeTask = task.start("filesystem.write", {
    handle = selectedFile,
    encoding = "utf8",
    text = nextText,
    expectedRevision = previouslyReadRevision,
})
local binaryReadTask = task.start("filesystem.read", {
    handle = selectedFile,
    encoding = "binary",
    maxBytes = 1024 * 1024,
})
local binaryWriteTask = task.start("filesystem.write", {
    handle = selectedFile,
    encoding = "binary",
    data = byteString,
    expectedRevision = previouslyReadRevision,
})
local releaseTask = task.start("filesystem.release", {
    handle = selectedHandle,
})
```

`stat`、`list`、`read` 要求 `filesystem.userSelected.read` 和可读句柄；`write` 要求
`filesystem.userSelected.write` 和可写句柄。`release` 只撤销当前实例自己的句柄，不要求
额外权限或手势；句柄仍有任务执行时返回 `handleBusy`。`stat` 返回
`{ handle,kind,name,size?,modifiedMs,readOnly,revision }`；`list` 只枚举一层，分页范围
0–10000、每页 1–100，并把非 reparse 子项转换为同一实例的新 opaque handle；超过
10000 个可枚举子项返回 `directoryTooLarge`。`read`/`write` 默认使用 `encoding=utf8`；
UTF-8 读取返回 `text`，NUL 或非法编码返回 `invalidEncoding`。探测到
`task.filesystem.binary` 后可显式使用 `encoding=binary`，读取结果改为 `data`，写入也必须
传 `data`；Lua 字符串中的 NUL 和非 UTF-8 字节会被原样保留。两种模式的调用方上限与宿主
硬上限都不超过 1 MiB，整文件读写不会因此开放路径或扩展句柄范围。

`write` 是 1 MiB 内的原子整文件替换，同一实例最短间隔 100 ms；传入
`expectedRevision` 时，文件不存在或 revision 已变化均返回 `conflict`。成功返回新的
`{ accepted,size,modifiedMs,revision }`。其他稳定错误包括 `invalidReference`、
`handleAccessDenied`、`notFile`、`notFolder`、`notFound`、`accessDenied`、
`reparsePointDenied`、`fileTooLarge`、`fileChanged`、`readFailed`、`writeFailed`、
`rateLimited`、`permissionRevoked` 和 `canceled`。这些任务不接受路径，也不递归遍历；
目录监听使用独立权限 `filesystem.userSelected.watch`，只接受
`filesystem.pickFolder` 返回且仍属于当前包、当前实例的 folder handle：

```lua
local changes = data.subscribe("filesystem.watch", {
    handle = selectedFolder,
    whenHidden = "pause",
})

local snapshot = changes:value()
if snapshot.available then
    for _, change in ipairs(snapshot.value.events) do
        -- kind: added / removed / modified / renamed
        -- name/oldName 仅用于显示；仍存在的子项可能带 opaque handle
    end
    if snapshot.value.overflow then
        task.start("filesystem.list", { handle = selectedFolder })
    end
end
```

监听只覆盖所选目录的一层，不递归、不跟随 reparse point，也不返回绝对路径。宿主通过
`ReadDirectoryChangesW` 按 subscription 隔离监听，并把连续通知合并到最多 256 个事件；
内核缓冲溢出时返回 `overflow=true`，调用方必须重新 `filesystem.list`，不能把事件列表
当作完整目录状态。隐藏策略固定收敛为 pause；隐藏、退订、卸载、撤权与关闭都会立即取消
监听并清空待发事件。`data.change` 会带 `topic="filesystem.watch"`、`subscriptionId`、
`revision` 和 `overflow`，同一组件监听多个目录时应按 subscription ID 区分。

`filesystem.release` 在对应目录仍被订阅时返回 `handleBusy`。稳定监听错误包括
`invalidReference`、`notFolder`、`permissionDenied`、`invalidDirectory`、
`watchOpenFailed`、`watchStartFailed`、`watchReadFailed` 和 `watchRestartFailed`。
feature 为 `data.filesystem.watch`。

`app.search` 要求 `app.discovery`，不要求用户手势；参数是严格的普通表：`query`
为 1–256 字节有效 UTF-8，`limit` 默认为 50、范围 1–100，`offset` 默认为 0、范围
0–10000。结果按宿主名称/拼音匹配排序并分页，只返回展示字段和实例作用域的不透明
`ref`：

```lua
local searchId, err = task.start("app.search", {
    query = "music",
    limit = 20,
    offset = 0,
})

-- 对应 task.complete 成功值：
-- event.value.items[i] = { ref, title, source, type }
-- event.value.nextOffset / hasMore / catalogRevision
```

如果应用索引仍在构建，完成事件返回 `appIndexNotReady`；可订阅
`app.indexStatus`，在 revision/state 变化后重试。目录在 UI 线程复制成不可变快照，
实际匹配在独立任务线程完成，因此不会让 Lua 或 worker 直接读取桌面应用容器。

`app.launch` 要求独立的 `app.launch` 权限和当前可信用户手势，只接受同一组件实例
先前搜索得到的 `ref`：

```lua
-- 必须位于直接 click/action 回调的同步调用栈：
local launchId, err = task.start("app.launch", { ref = item.ref })
```

Lua 不会取得可执行文件路径、参数、Shell verb 或工作目录，也不能伪造其他实例的
引用。应用目录 revision 改变后旧引用返回 `staleReference`；未知、被回收或跨实例
引用返回 `invalidReference`。成功值与媒体动作一样为 `accepted=true`，只表示宿主的
Shell 启动队列已接受请求，不代表目标进程最终成功启动。

`desktop.search` 与 `everything.search` 提供有界、可取消的项目搜索。两者都接受
`query/limit/offset` 严格参数；query 为 1–256 字节有效 UTF-8，limit 范围 1–100，
offset 范围 0–100。`desktop.search` 要求 `desktop.read`：宿主最多复制 2048 个当前
桌面项目为不可变快照，实际名称/拼音匹配在任务线程完成。`everything.search` 要求
`everything.search` 权限，每实例最多一个并发任务，在后台调用本机 Everything
索引；宿主把进程级 Everything SDK 调用串行化，避免与 SnowDesktop 自身搜索互相覆盖。

```lua
local desktopTask = task.start("desktop.search", {
    query = "report", limit = 50, offset = 0,
})
local everythingTask = task.start("everything.search", {
    query = "report", limit = 50, offset = 0,
})

-- 两者的 task.complete 成功值结构相同：
-- event.value.items[i] = { ref, title, source, type }
-- event.value.nextOffset / hasMore / revision
```

结果只含展示字段和当前组件实例可用的不透明 `ref`，不含文件系统路径。组件可将该
ref 直接传给 `draw.icon(ref, ...)`；不得持久化、解析或自行构造。桌面 revision 变化
后旧桌面引用返回 `staleReference`；未知、已回收或跨实例引用返回
`invalidReference`。取消 Everything 搜索会抑制结果投递，但不能保证中断已经进入
Everything IPC 的一次查询。

项目打开、定位和桌面刷新要求 `desktop.action`，并且只能在直接指针动作或菜单命令
的可信手势调用栈中启动。`shell.openItem/revealItem` 只接受同一实例先前由
`desktop.search/everything.search` 返回的 ref；`desktop.refresh` 不接受参数：

```lua
local openTask = task.start("shell.openItem", { ref = item.ref })
local revealTask = task.start("shell.revealItem", { ref = item.ref })
local refreshTask = task.start("desktop.refresh")
```

成功值为 `{ accepted = true }`。稳定错误包括 `invalidReference`、`staleReference`、
`openRejected`、`revealRejected`、`permissionDenied`、`userGestureRequired` 和
`canceled`。应用 ref 仍只能交给 `app.launch`，项目 ref 不能交给 `app.launch`。

通知任务要求 `notification.post` 权限，但不要求用户手势。`notification.show` 接受
`title/message`，并可选接受包内 `resource.image` 句柄、0–1 的 `progress` 和最多两个
`{ id, label }` 操作按钮；标题为 1–256 字节、正文为 1–2048 字节的有效 UTF-8，均不得包含
NUL。其 `task.complete.value.notificationId` 是宿主生成、仅当前组件实例可用的不透明
ID：

```lua
local taskId, err = task.start("notification.show", {
    title = l10n.tr("widget.name"),
    message = l10n.tr("widget.completed"),
    image = resource.image("completed"),
    progress = 1,
    actions = {
        { id = "open", label = l10n.tr("widget.open") },
    },
})
```

拿到 ID 后可用 `notification.update` 替换任一内容字段；`image=false`、
`progress=false` 和空 `actions` 数组分别清除图片、进度和按钮。用
`notification.dismiss` 关闭已投递通知。`notification.schedule` 在 `atMs` 指定的未来
Unix 毫秒时间由宿主按需唤醒投递，无需 Lua 轮询；时间最多可提前 366 天，成功同样返回
`notificationId`。尚未投递的 ID 可更新或用 `notification.cancel` 取消；已投递 ID 应使用
`dismiss`。预约投递后会收到 `event.kind == "notification.delivered"`，其中包含
`notificationId/ok/error`。按钮激活会向创建通知且仍存活的实例投递
`event.kind == "notification.action"`，携带 `notificationId/actionId`，该回调处于可信用户
手势作用域；实例已经卸载或热重载时安全丢弃：

```lua
local scheduledTask = task.start("notification.schedule", {
    title = "休息时间",
    message = "起来活动一下",
    atMs = time.now() + 5 * 60 * 1000,
})

task.start("notification.update", {
    notificationId = savedNotificationId,
    message = "延长两分钟",
})
task.start("notification.cancel", {
    notificationId = savedNotificationId,
})
```

宿主限制每实例每分钟实际投递最多 5 次、每实例最多保留 64 个 ID（其中预约最多
32 个）；已投递 ID 保留 24 小时。预约以原子文件绑定组件实例 ID、包 ID 和不透明通知
ID，应用重启后会绑定新的 Lua VM generation，错过不超过 24 小时的到期时间会在组件
恢复后补投；组件卸载、禁用、热重载或权限撤销会删除其预约，不让旧包代码继续后台
通知。预约文件保存资源名而不是绝对路径，并持久化进度和按钮；恢复时重新在当前包根解析
图片。预览异步返回确定性 ID，但不会写入预约文件或产生系统通知。
除通用的 `permissionRevoked` 和 `canceled` 外，稳定错误包括 `invalidArguments`、
`notFound`、`invalidState`、`quotaExceeded`、`providerUnavailable`、
`persistenceFailed` 和
`notificationFailed`。组件应把权限放在 `optionalPermissions`，拒绝通知时仍完成自身
主功能。纯文本通知使用系统托盘；带图片、进度或按钮的通知使用不抢占桌面焦点的宿主通知
窗。运行时图片句柄不能作为通知图片，操作按钮最多两个且 ID 在单条通知内必须唯一。
不得使用已移除的 `system.notify` 绕过任务与权限模型。

`calendar.create`、`calendar.update`、`calendar.remove` 要求 `calendar.write`，参数只接受严格字段。
create/update 共用 `title/date/allDay/startMinutes/endMinutes/notes/reminderMinutes`；
update 另需宿主事件 `id` 和正整数 `expectedRevision`，remove 只接受 `id`。提醒值
限定为 `-1/0/5/15/30/60/1440`，日期必须是有效 `YYYY-MM-DD`，文本和时间范围在
进入日历服务前完成边界检查。新增和更新不要求手势；删除必须从直接指针动作或菜单
命令的可信调用栈启动：

```lua
local updateId, err = task.start("calendar.update", {
    id = item.id,
    expectedRevision = item.revision,
    title = item.title,
    date = item.date,
    allDay = item.allDay,
    startMinutes = item.startMinutes,
    endMinutes = item.endMinutes,
    notes = item.notes or "",
    reminderMinutes = item.reminderMinutes,
})
```

成功结果为 `{ id, revision }`；删除的 revision 为 0。更新冲突返回
`error="conflict"`，并在完成事件的 `currentRevision` 给出宿主当前 revision。
其他稳定错误包括 `not_found`、`title_required`、`text_too_long`、`invalid_date`、
`invalid_time`、`invalid_reminder`、`event_limit`、`save_failed`、
`permissionDenied`、`userGestureRequired` 和 `previewReadOnly`。

`network.request` 要求 `network.internet`，支持公网 HTTPS 的 `GET/HEAD/POST/PUT/PATCH/DELETE`、
有界自定义请求头和请求体，但仍不启用 WinHTTP Cookie 或系统认证。默认可访问任意公网 HTTPS 主机；如果组件功能固定依赖少数服务，
可以在 `networkDomains` 中逐项声明精确主机名，主动把自身网络范围收窄。域名限制不支持
通配符或子域继承；无论是否收窄，localhost、局域网地址和指向非公网地址的解析或重定向
都被拒绝。每实例该任务最多并发 2 个，参数只接受：

- `url`：1–2048 字节有效 UTF-8 公网 HTTPS URL；清单声明了 `networkDomains` 时主机必须精确命中；
- `method`：上述六个大写方法，默认 `GET`；
- `headers`：最多 32 个 RFC token 名称；普通值必须是单行 UTF-8，也可以使用下述 secret descriptor；注入后合计不超过 32 KiB；
- `body`：普通字符串字节或一个 secret descriptor，注入后不超过 64 KiB；
- `timeoutMs`：1000–30000，默认 15000；
- `cacheSeconds`：0–86400，默认 0，缓存按实例、请求与响应上限隔离；
- `maxBytes`：4096–1048576，默认 524288。

```lua
local requestId, err = task.start("network.request", {
    url = "https://www.example.com/feed.xml",
    timeoutMs = 15000,
    cacheSeconds = 120,
    maxBytes = 512 * 1024,
})

-- 成功：event.value = { status, body, fromCache }
-- HTTP 响应失败时：event.error == "httpStatus"，event.status 可用
```

声明式 `password` 设置取得的引用只能作为 `{ secretRef=ref, prefix=?, suffix=? }` descriptor
交给请求头值或整个 body。任务代理队列只保存引用和公开前后缀；宿主在真正发送前按包和实例
解析并注入正文，完成事件、日志和诊断不会回传正文。例如：

```lua
local tokenRef = storage.get("apiToken")
local requestId, err = task.start("network.request", {
    url = "https://api.example.com/items",
    method = "POST",
    headers = {
        Authorization = { secretRef = tokenRef, prefix = "Bearer " },
        ["Content-Type"] = "application/json",
    },
    body = "{\"limit\":20}",
    maxBytes = 256 * 1024,
})
```

descriptor 的 prefix/suffix 只是原始拼接，不执行 JSON 或 URL 转义；需要结构化编码时应把秘密
放在专用请求头，或确保服务端约定的秘密字符集可直接嵌入。含 secret、非 GET 或非空 body 的
请求强制关闭响应缓存。引用缺失、已清除、来自其他实例或无法由当前 Windows 用户解密时返回
`secretUnavailable`。对应 feature 为 `task.network.headers`、`task.network.requestBody` 和
`task.network.secretReference`。

重定向的每一跳都重新检查 HTTPS、可选的精确域名范围、DNS 解析地址和实际连接地址。响应在
worker 中读取，超限立即失败，不会把慢网络 I/O 放进 UI/render 线程。稳定完成错误包括
`requestRejected`、`networkError`、`redirectRejected`、`responseTooLarge`、
`httpStatus`、`permissionRevoked` 和 `canceled`。预览返回确定性的最小 RSS mock，不发起
网络连接。声明了 `networkDomains` 的组件如果请求范围外主机，会得到 `requestRejected`；
RSS、Webhook 阅读器等允许用户填写地址的组件不应声明固定域名范围。

`shell.openUri` 要求 `shell.launch` 和当前可信用户手势，只接受不含用户名/密码的公网
HTTPS URL；`http:`、`file:`、自定义 scheme、localhost、局域网和 IP 内网地址均被拒绝。
成功值为 `{ accepted = true }`，仅表示宿主 Shell 队列接受请求。稳定错误包括
`invalidUrl`、`openRejected`、`permissionDenied`、`userGestureRequired` 和 `canceled`。
阅读器等非核心打开场景应把 `shell.launch` 放入 `optionalPermissions`，无授权时仍显示内容。

六个直接动作 `play/pause/toggle/stop/next/previous` 的参数表可省略，也可只传
`sessionId`。`seek` 需要非负整数 `positionMs`，其含义是相对媒体时间线起点的位置；
`setRate` 需要有限正数 `rate`；`setShuffle` 需要布尔 `shuffle`；`setRepeat` 需要
`mode="none"|"track"|"list"`。所有动作都可选传入 `media.sessions/current` 返回的
不透明 `sessionId`，不传时控制 Windows 当前会话。目标会话已经消失时返回
`notAvailable`；宿主在执行前检查该会话对应的 `can*` 能力，时间线越界返回
`seekOutOfRange`，不支持的控制返回 `actionUnsupported`。会话 ID 仅用于当前快照和
后续短时交互，不应解析或持久化。

启动成功只表示任务进入宿主队列。WinRT 媒体调用在独立工作线程执行；完成后由
`event.kind == "task.complete"` 串行投递，事件包含 `taskId/task/ok`。成功时
`event.value.accepted == true`；失败时 `event.error` 为稳定错误码，例如
`notAvailable`、`actionUnsupported`、`actionRejected`、`mediaActionFailed`、
`permissionRevoked` 或 `canceled`。完成事件不继承原始用户手势，不能借完成回调
连续启动更多高风险动作。

`task.cancel(taskId)` 只接受当前 Lua VM 自己持有的任务。卸载、热重载、撤权和
宿主关闭会自动取消；热重载使用 VM owner token，旧任务结果不会投递给新 VM。
预览不会访问系统媒体会话、音频端点、Windows 设置、真实剪贴板或系统通知，而是异步返回确定性 mock。
媒体参数表只接受上述动作对应字段；其他任务同样拒绝未知字段、错误类型和越界数值。已移除的
`media.playPause/next/previous` 不会注册进 VM，不能绕过任务的手势门禁。

### `draw`

即时绘制坐标以组件左上角为 `(0, 0)`：

- `draw.text(x, y, text, size?, color?, maxWidth?, bold?, singleLine?,
  maxHeight?, alpha?, font?)`
- `draw.marqueeText({key, x, y, width, height, text, size?, color?, bold?,
  speed?, gap?, alpha?, font?}) -> scrolling`
- `draw.measureText(text, size?, maxWidth?, bold?, font?)`
- `draw.rect(...)`、`draw.strokeRect(...)`、`draw.line(...)`、`draw.circle(...)`
- `draw.arc(cx, cy, radius, startDegrees, sweepDegrees, thickness?, color?, alpha?)`
- `draw.path(commands, options?)`
- `draw.gradientRect(x, y, width, height, startColor?, endColor?, direction?, radius?, alpha?)`
- `draw.shadow(x, y, width, height, color?, blur?, radius?, offsetX?, offsetY?, alpha?)`
- `draw.sparkline(values, x, y, width, height, color?, thickness?, min?, max?, alpha?)`
- `draw.pushClip(x, y, width, height)`、`draw.popClip()`
- `draw.fa(...)`、`draw.fluent(...)`
- `draw.image(imageHandle, x, y, width, height, alpha?)`
- `draw.imageFit(imageHandle, x, y, width, height, fit?, alignment?, alpha?, interpolation?)`
- `draw.icon(ref, x, y, size?, alpha?)`：要求 `desktop.read`，只接受当前实例由
  `app.search`、`desktop.search` 或 `everything.search` 返回且仍有效的不透明 ref；
  不接受路径、v1 项目表或其他实例的引用。

颜色是 `0xRRGGBB`，透明度单独传入。`draw.image` 在 v2 中只接受
`resource.image()` 返回的不透明句柄；字体句柄可传给 `draw.text` 和
`draw.measureText`。

`draw.marqueeText` 用于持续横向滚动的单行溢出文字，对应 feature
`draw.marqueeText`。组件必须在 `requiredFeatures` 或 `optionalFeatures` 中声明该
feature，并且只能在桌面 surface 的 `render()` 中调用。`key` 必须在一次 render 中
唯一且稳定；同一 key 在数据刷新或重新布局后会尽量保留滚动相位。`width/height` 定义
裁剪视口，文字在视口内纵向居中；文字宽度不超过视口时返回 `false` 并静态绘制，否则
返回 `true`。`speed` 默认每秒 24 个逻辑像素，`gap` 默认 24；一次 render 最多提交
32 项，文字最多 4096 个 UTF-8 字节。

宿主会把同一次即时 render 中的其他绘制录制为静态命令，后续滚动帧只重放这份缓存、
绘制文字并局部刷新 marquee 视口，不重新进入 Lua，也不产生 `frame` 或 `schedule`
事件。因此持续溢出文字应优先使用此 API，而不是用
`animation.requestFrame`/`schedule.every` 修改偏移。marquee 作为宿主原生覆盖层绘制在
该次即时绘制缓存之上；不要依赖在它之后用其他即时绘制内容遮盖文字。数据、交互、主题
或组件主动失效仍会正常重新执行 render 并更新缓存。组件隐藏时动画暂停；预览、
reduced-motion 或宿主没有动画调度器时从起点静态显示，但返回值仍只表示是否发生溢出。

上述 `arc/path/gradientRect/shadow/sparkline/imageFit` 属于可探测 feature
`draw.advanced`，仅注册到 API v2。它们遵守以下确定性边界：

- `arc` 的 `0°` 指向右侧，正角度顺时针；非零 sweep 最多一圈，宿主会拆成至多
  3 段安全圆弧。
- `path` 接受 1–256 个严格命令，首项必须是
  `{op="move", x, y}`。后续可用 `line`、`cubic`、`quadratic`、`close`；命令表
  拒绝未知字段、元表和稀疏数组。`options` 只接受 `fillColor/strokeColor/thickness/
  alpha/fillRule`，其中 `fillRule` 为 `alternate` 或 `winding`。没有指定填充或描边时
  默认使用白色描边。
- `gradientRect` 是两色线性渐变，方向为 `horizontal`、`vertical`、
  `diagonalDown` 或 `diagonalUp`；圆角不能超过短边一半。
- `imageFit` 仍只接受当前实例的图片句柄。`fit` 为 `fill/contain/cover/none`，
  `alignment` 为 `start/center/end` 并同时作用于两轴，采样为 `linear/nearest`；
  `cover` 由宿主计算源图裁切，不向 Lua 暴露资源路径或像素。
- `shadow` 的 blur 为 `0–64`，最多产生 16 层宿主受控的柔和衰减；它不是任意
  shader 或无界高斯效果。圆角不能超过短边一半，偏移和扩散后的区域仍受坐标预算约束。
- `sparkline` 接受 1–512 个有限数值。`min/max` 必须成对提供且严格递增；省略时宿主
  自动计算范围，越界样本裁到绘图区。所有宽高、坐标、线宽、颜色和透明度都经过有限值
  与上限检查，不会因一次调用创建无界工作量。

### `layout`

`layout.width/height` 保留现有的完整 surface 渲染尺寸，适合需要覆盖整个即时绘制
surface 的兼容代码。探测 `layout.relativeUnits` 后，响应式布局应改用
`layout.contentWidth/contentHeight`；它们与声明式 View Tree 根节点实际收到的内容框
处于同一坐标系，并与 `widget.context().layoutSize` 一致。桌面底栏需要固定占位时，
content height 已扣除该保留区；panel/dialog/popover 则使用各自完整内容框。

`layout.vw(percent)`、`layout.vh(percent)`、`layout.vmin(percent)` 和
`layout.vmax(percent)` 接受 0–100 的有限百分比，分别返回根内容宽、高、短边和长边的
对应比例。圆形、方形和跨宽高比保持一致的控件优先使用 `vmin`；横向或纵向结构分别
使用 `vw`、`vh`。这些函数直接返回可用于声明式数值尺寸和即时绘制坐标的布局值，
不要再与 DPI 归一化的 `context.logicalSize` 混用。

`columns/rows/sizeClass` 返回跨度与尺寸档位。
`cellWidth/cellHeight/cellScale/cellGap/barHeight` 提供宿主网格指标。
`layout.cu(value)` 和 `layout.fontCu(value)` 用于保持最小点击尺寸、描边、局部间距和
字体在不同网格密度下的视觉尺度；它们不会随组件跨度同比增长，不能代替总宽高比例单位。

### `storage`

- `storage.get(key) -> SnowStateValue?`
- `storage.set(key, value)`：`value` 可以是 nil、boolean、有限 number、string、连续数组
  或字符串键对象，并立即原子持久化。
- `storage.remove(key)`、`storage.keys()`。
- `storage.transaction(function(tx) ... end) -> changed`：一次原子提交多个类型化
  写入；事务对象提供 `tx:get/set/remove`。

```lua
storage.transaction(function(tx)
    tx:set("item.42", { title = "Book tickets", done = false })
    tx:set("order", { 17, 42 })
    tx:remove("draft")
end)
```

事务内必须通过 `tx` 访问存储，不能嵌套事务，也不能混用全局
`storage.get/set/remove/keys`。回调抛错、最终快照超过配额或写盘失败时不会暴露部分
修改；配额在最终快照上检查，因此允许先暂存新键再在同一事务删除旧键。事务最多
1024 次操作；每实例最多 256 个键、每键 128 个有效 UTF-8 字节、每值 64 KiB、
总量 1 MiB。顶层字符串仍可使用完整的 64 KiB 单值配额；非字符串结构化值最多 256 个
节点、8 层和合计 16 KiB 的字符串内容。循环表、metatable、混合数组/对象、非有限数和
无效 UTF-8 会被拒绝。既有未标记值始终按原字符串读取；新字符串也保持原始字符串编码，
非字符串值使用宿主保留的实例元数据标记，避免把用户历史字符串误判成序列化对象。
对应 feature 为 `storage.transaction`、`storage.typed` 和
`storage.writeBudget`。

API v2 的 `storage.set/remove/transaction` 不能在 `render` 内调用；持久化只允许在
setup、事件、菜单动作或迁移回调等副作用阶段执行。预览和迁移使用隔离覆盖层，成功
后再由宿主决定是否持久化。存储 null 与缺失键都会由 `get` 返回 nil，需要区分时使用
`storage.keys()`。声明式 `password` 键是宿主管理的只读 secret reference：可以通过
`storage.get/keys` 读取引用，但 `storage.set/remove` 和事务写入会拒绝覆盖；秘密正文不属于
storage 值，预览中该键始终未设置。

每个真实实例可突发提交 32 次持久变化，之后每秒恢复 1 次；一次事务只计一次，未改变
的提交、预览和迁移覆盖层不计。超过预算时调用抛出包含建议等待毫秒数的稳定错误。
宿主 storage-bound 文本控件不占用 Lua 写入预算，用户输入不会因正常键速被拒绝。只在
值变化时写入；新组件不必再手工 `tostring/tonumber` 编解码结构化状态。

### `state`

`state` 是仅随当前组件 VM 存活的实例内存状态：

- `state.get(key, default?)` 返回深拷贝，未设置时返回默认值。
- `state.set(key, value)` 保存深拷贝；值没有变化时返回 `false` 且不重复失效。
- `state.remove(key)`、`state.has(key)`、`state.keys()`、`state.clear()`。

值支持 nil、boolean、有限 number、string、连续数组和字符串键对象。循环表、
metatable、混合数组/对象以及超出深度、节点、字符串或 256-key 实例配额的值会
被拒绝。真实变化会合并成宿主失效信号；它不会写盘，热重载或卸载后丢失。

### `system` 与 `time`

- `system.info()`：Windows、架构、宿主版本和部署模式。
- `system.capabilities(featureOrApi?)`：不传参数时同时返回宿主 feature 列表和完整的
  v2 系统函数、数据主题、任务契约；传 feature ID 或公开 API 名时返回单项状态。
- `system.uptime()`：毫秒与是否包含睡眠时间。
- `time.now()`、`time.monotonic()`。
- `time.parts(epochMilliseconds?, timeZone?)`。
- `time.format(epochMilliseconds?, options?)`。
- `time.add(epochMilliseconds, delta, options?)`、`time.compare(a, b)`。

时区参数接受 `local`、`utc` 或 Windows 时区键（例如
`Pacific Standard Time`、`China Standard Time`）。`widget.context().timeZone`
返回的键可直接传给上述接口；显式时区的拆分、格式化和日历加减会应用对应日期的
DST 规则。未知时区会被拒绝，不会静默回退到本地时区。

这些基础环境与时间接口不要求高风险权限。`system.capabilities("system.cpu")`
这类 API 名查询会同时返回 `feature`、`kind`、`hostAvailable`、`authorized`、
`permission`、`available/reason` 和刷新率或并发上限。`hostAvailable` 只表示宿主包含
该能力；硬件是否存在、provider 是否 warming/stale 仍由对应数据快照表达。
CPU、内存、网络、媒体和音频波形等状态应通过 `data.subscribe` 按需订阅，不能使用
已移除的同步 `sys` 代替。
在组件预览中，`time.now()`、无参数的 `time.parts/format`、`time.monotonic()` 和
`system.uptime()` 使用固定虚拟值，保证重复预览不会随等待时间变化；正式实例仍读取
宿主当前时间。可通过 `time.previewClock` feature 查询该保证。

### `calendar` 日期计算与选择

- `calendar.dateInfo("YYYY-MM-DD")` 返回年、月、日、星期和当月天数。
- `calendar.addDays(date, offset)` 返回偏移后的 ISO 日期，offset 范围为
  -366000 到 366000。
- `calendar.selectDate(date)` 改变 SnowDesktop 本地共享选中日期。

前两项是纯 Gregorian 日期计算；第三项只用于月历、日程等组件协同，不创建、修改或
删除日程。三者都不要求 `calendar.read/write`；读取选中日期和事件仍必须通过受
`calendar.read` 保护的 `data.subscribe`。

声明式 `select` 设置可用稳定的 `options` 值，并用等长的 `optionLabels` 提供当前语言
显示文本；宿主保存值而不是翻译，切换语言不会使现有设置失效。对应 feature 为
`settings.select.localizedOptions`。

API v2 还提供以下普通值设置控件：

- `url`：空值或不超过 2048 字节、带 authority 且不含空白和反斜杠的 `http://` / `https://` URL；
- `date`：空值或严格 Gregorian `YYYY-MM-DD`；
- `time`：空值或 24 小时制 `HH:MM`；
- `range`：声明有限的 `min <= max` 和正 `step`，宿主对值钳制并吸附到步长；
- `multiSelect`：声明 1-64 个唯一稳定 `options`，可配等长本地化 `optionLabels`，`default`
  与 preset 值均为这些选项组成的无重复数组。

`url/date/time` 通过 `storage.get` 返回 string，`range` 返回 number，`multiSelect` 返回
string[]；后两项使用 `storage.typed` 持久化，首次读取默认值、应用 preset、恢复默认以及用户修改
保持相同 Lua 类型。无效清单或 preset 会使组件加载失败；设置页不会提交输入过程中的无效
URL、日期或时间。对应 feature 分别为 `settings.url`、`settings.date`、`settings.time`、
`settings.range`、`settings.multiSelect`。

设置字段可提供不超过 2048 字节的本地化 `description`，宿主在控件下方以辅助文本显示。
`settings.groups` 按声明顺序定义最多 32 个分组，每组包含稳定 ASCII `id`、本地化 `label`、
可选 `description`，以及 `collapsible/defaultExpanded`；字段用 `group=id` 加入分组。未分组字段
保持声明顺序并显示在分组前，同一分组内也保持字段声明顺序。重复 group/field ID、未知 group 或
超长文本会使组件加载失败。对应 feature 为 `settings.description`、
`settings.groups`。

```lua
settings = {
    groups = {
        {
            id = "content",
            label = l10n.tr("widget.settings.content"),
            description = l10n.tr("widget.settings.content_help"),
            collapsible = true,
            defaultExpanded = true,
        },
    },
    fields = {
        {
            key = "feedUrl",
            type = "url",
            label = l10n.tr("widget.settings.feed"),
            description = l10n.tr("widget.settings.feed_help"),
            group = "content",
        },
    },
}
```

字段校验由宿主执行。`text/url/date/time` 可声明 `minLength/maxLength`（0-2048，按 Unicode
code point 而不是 UTF-8 字节计数），任意字段可声明 `required=true`；`bool` 的 required 表示
必须为 true，password、filesystem handle 和实体 reference 表示必须已有宿主管理值。只要声明
`required/minLength/maxLength`，就必须同时提供组件自行本地化的 `validationMessage`。文本输入在
满足约束前只保留为设置页草稿，不写入组件 storage；其他控件或宿主管理值不满足 required 时，
宿主在字段下显示同一错误文本。对应 feature 为 `settings.validation`。

字段可通过另一个已声明字段控制可用性或可见性：

```lua
settings = {
    fields = {
        {
            key = "advanced",
            type = "bool",
            label = l10n.tr("widget.settings.advanced"),
            default = false,
        },
        {
            key = "endpoint",
            type = "url",
            label = l10n.tr("widget.settings.endpoint"),
            required = true,
            validationMessage = l10n.tr("widget.settings.endpoint_invalid"),
            dependsOn = "advanced",
            showWhen = {
                key = "advanced",
                operator = "truthy",
            },
        },
    },
}
```

- `dependsOn="key"` 是 `enabledWhen={key="key", operator="truthy"}` 的简写，两者不能并用；
- `showWhen` 为 false 时不渲染字段，`enabledWhen` 为 false 时保留但禁止编辑；两者都保留已有值；
- `equals/notEquals/contains/notContains` 接收一个 `value`，`oneOf/notOneOf` 接收 1-64 个值；
- `set/unset/truthy/falsy` 不接收 `value`；`contains/notContains` 只用于 multiSelect，select 与
  multiSelect 的比较值必须来自其稳定 `options`；
- password、file/folder handle 与实体 reference 只能参与 `set/unset/truthy/falsy`，条件不会
  取得它们的 secret、handle 或 reference；
- 条件只能引用其他已声明字段。未知键、自引用、类型不兼容或跨多字段形成的循环都会使组件
  加载失败。

使用前分别探测 `settings.dependencies`（`dependsOn/enabledWhen`）和 `settings.showWhen`。

`appSearch` 设置使用 `key` 保存用户选中的应用显示名，使用 `searchKey` 保存搜索文字；
宿主复用应用索引并在后台完成匹配，在设置页直接显示候选项。`emptyLabel` 和
`noResultsLabel` 必须使用组件清单中的本地化文本。该控件只负责设置交互；组件运行时仍应
通过 `app.search` 获取当前实例的 opaque `ref`，并在可信用户动作中用 `app.launch` 启动。
对应 feature 为 `settings.appSearch`。

`appReference` 是持久应用引用选择器，不保存显示名、路径或 AUMID。字段必须提供稳定的
`key` 和 `binding`；`binding` 必须指向 manifest 中接受 `app.reference` 且
`replacePolicy="allow"`、且只接受 `app.reference` 的单项槽位；一个 binding 不能被多个实体设置字段复用：

```lua
settings = {
    fields = {
        {
            key = "primaryAppPicker",
            label = l10n.tr("widget.primary_app"),
            type = "appReference",
            binding = "primaryApp",
            emptyLabel = l10n.tr("widget.primary_app_empty"),
            noResultsLabel = l10n.tr("widget.no_apps"),
        },
    },
}
```

宿主在设置页搜索自己的应用索引；选择、替换和清除直接提交到逻辑槽位事务并进入同一
撤销历史，搜索文字只保存在临时 UI 状态。`default`、preset、普通 storage 和组件预览都不
接触引用内容；`storage.get/transaction:get` 对字段 `key` 返回 nil，写入或移除该键会被拒绝。
组件用 `slots.binding("primaryApp"):item()` 读取宿主持久 opaque
`reference`；项目的 `availability` 为 `available` 或 `unavailable`，应用索引变化时宿主会重新核对，
不可用引用不能交给 `app.launch`。选择器本身不要求 `app.discovery`，但启动仍要求
`app.launch` 权限和当前可信用户手势。对应 feature 为 `settings.appReference`，并同时依赖
`slots.model`。

其余单实体选择器使用相同的 host-owned binding 契约：

| 设置类型 | binding 必须接受 | 宿主选择范围 | feature |
| --- | --- | --- | --- |
| `desktopItemReference` | `desktop.item` | SnowDesktop 当前桌面、集合和 Dock 中的项目 | `settings.desktopItemReference` |
| `fileReference` | `filesystem.reference` | 快速导航与 Everything 结果中的文件 | `settings.fileReference` |
| `folderReference` | `filesystem.reference` | 快速导航与 Everything 结果中的文件夹 | `settings.folderReference` |

三个字段都要求 binding 只接受表中对应 kind、使用 `replacePolicy="allow"`，并提供
`binding`、`emptyLabel`，不接收 default 或
preset。设置页的 `...` 打开宿主选择器，`×` 按 manifest 的 `allowClear` 清除；文件和文件夹
即使共享 `filesystem.reference` kind 也会在候选生成和结果列表两层严格过滤。宿主在实例加载及
桌面内容变化时重新检查路径存在性和文件/文件夹类型；失效引用变为 `unavailable`，不能交给
`shell.openItem/revealItem`。这些选择器只授予所选引用，不授予目录枚举或文件内容读取权限。
运行时仍统一通过 `slots.binding(bindingId):item()` 读取，不通过设置字段的 storage key。

`password` 设置由宿主显示遮罩输入框并使用 Windows DPAPI 写入独立私有状态文件；不要提供
`default`，也不要把该键写进 preset。输入框失去焦点时提交新值，右侧 `×` 清除已有值。
Lua 的 `storage.get(key)` 只能得到形如 `secret:v1:…` 的实例作用域 opaque reference，未设置时
返回 nil；没有 `secrets.reveal()`，引用不能跨包或跨组件实例解析，也不会进入组件预览、普通
storage、日志或 `.snowbackup` 数据目录。对应 feature 为 `settings.secretReference`。

`fileHandle` 与 `folderHandle` 把系统文件选择器直接放进设置页。字段声明 `key`、本地化
`label/emptyLabel` 和 `access="read"|"write"|"readWrite"`（默认 `read`）；`fileHandle`
还可声明最多 16 个安全 `extensions`，开头的点可省略，`folderHandle` 不接收扩展名。
`fileHandle` 的 `write` 使用保存选择器，`read` 与 `readWrite` 选择现有文件；`folderHandle`
始终选择目录。

用户选择后，`storage.get(key)` 与 `storage.transaction(function(tx) tx:get(key) end)` 返回绑定
当前包和实例的 opaque filesystem handle，未选择或授权失效时返回 nil；`storage.keys()` 仅在
已选择时列出该字段。字段不接收 default/preset，不能由 Lua 写入或移除，也不进入组件预览。
每个字段取得独立 handle，替换或点击 `×` 会取消仍使用旧 handle 的任务与目录监听并撤销旧授权；
Lua 调用 `filesystem.release` 释放这种宿主管理 handle 会得到 `hostManagedReference`，只能由用户在
设置页撤销。宿主持久化的字段映射和句柄仓库不向 Lua 暴露路径。

选择器本身只授予用户选中的对象；后续 `filesystem.stat/list/read/write` 仍分别受
`filesystem.userSelected.read/write` 权限、handle kind/access 和任务配额约束。对应 feature 为
`settings.fileHandle`、`settings.folderHandle`。

### `l10n`

- `l10n.tr(literalKey, ...)`、`l10n.language()`。
- `l10n.formatNumber`、`l10n.formatBytes`、`l10n.formatDuration`、
  `l10n.formatRelativeTime`、`l10n.formatList`。

所有用户可见文本都应使用清单 `locales` 中存在的字面量 key。宿主语言文件不是
组件翻译目录。

### `module` 与 `resource`

`module.require("modules/example.lua")` 只能在入口脚本求值期间加载包内 `.lua`
模块；结果按实例缓存。禁止循环依赖、包外路径以及 `require/package/io/os/load`。

资源必须在 `widget.json` 中声明，例如：

```json
"resources": {
  "logo": { "type": "image", "path": "assets/logo.png" },
  "display": {
    "type": "font",
    "path": "assets/Display.ttf",
    "license": "OFL-1.1"
  }
}
```

入口加载时创建句柄：

```lua
local logo = resource.image("logo")
local display = resource.font("display")

-- 同一句柄可进入声明式视图；Lua 不会获得资源路径。
view.image({ key = "logo", source = logo, alt = "SnowDesktop" })
view.text({ key = "title", text = "SnowDesktop", font = display })
```

可用 `resource.exists(name)` 和 `resource.status(handle)` 查询。句柄在入口求值期间同步创建，
所以状态只会是 `ready` 或带 `error = "unavailable"` 的 `error`，不会留下需要轮询的
`pending`。创建失败会拒绝本次 VM 加载，并以 `resource.image: code` 或
`resource.font: code` 抛出稳定错误：`loadPhaseRequired`、`invalidName`、
`notDeclared`、`typeMismatch`、`hostUnavailable`、`unavailable`、
`quotaExceeded`、`decodeFailed`、`deviceUnavailable`、`fontLoadFailed`；
`resource.status` 对错误参数使用 `invalidHandle`。资源路径、数量、
文件大小、图片像素、字体格式与许可字段受包校验器限制；不允许绝对路径、父级
跳转、符号链接、junction 或其他重解析点。

资源名在 VM 建立时一次性解析为宿主私有路径；`resource.exists` 只查询已验证的清单，
不会在 `view/render` 回调中访问文件系统。`resource.image` 在入口加载期计算内容 SHA-256，
再把图片解码到有界、同宿主共享的像素缓存；成功 VM 保存资源名对应的内容键，因此同一路径
热重载不会误用旧像素，失败的新 VM 也不会改变仍在运行的旧实例。绘制和 D2D 设备重建只从
对应内容键的内存像素创建设备位图；失败加载、热重载、卸载和关机会释放当前 VM 创建的句柄，
最后一个同内容句柄释放后宿主回收其 CPU 像素和 D2D 位图；
`resource.font` 同样必须在入口加载期完成私有字体集合创建。解码、字体加载或总缓存额度
失败会直接拒绝句柄和本次 VM，而不是把同步磁盘 I/O 推迟到首帧。

## 清单 v2 最小要求

```json
{
  "schemaVersion": 2,
  "id": "f527797f-a986-4ad1-a58d-250ef91f53d3",
  "slug": "my-widget",
  "name": "My Widget",
  "nameKey": "lua_widget.my_widget.name",
  "version": "1.0.0",
  "apiVersion": 2,
  "dataVersion": 1,
  "entry": "main.lua",
  "minHostVersion": "1.0.4.0",
  "author": "Your Name",
  "license": "MIT",
  "description": "A short English fallback.",
  "descriptionKey": "lua_widget.my_widget.description",
  "requiredFeatures": ["draw.immediate", "lifecycle.event", "lifecycle.model",
    "l10n.basic", "schedule.basic"],
  "optionalFeatures": [],
  "resources": {},
  "slots": {},
  "permissions": [],
  "optionalPermissions": []
}
```

`schemaVersion` 与 `apiVersion` 必须同时为 2。`requiredFeatures` 不受支持时包
无法激活；`optionalFeatures` 用于可降级能力。基础时钟、绘制、上下文和包资源
不应声明高风险权限。

## 当前明确未开放

当前沙箱不提供已移除的同步 `desktop`、`media`、`http` 和 `sys` 库，也不提供任意
原始键盘事件、原生 UI Automation 对象、系统路径、Shell verb、进程、WMI、注册表或
原生句柄。声明式 `view.tree.core`、宿主生成的 UI Automation 语义、元素级交互和独立
右键菜单已经开放；组件只能声明语义，不能直接操作 UIA Provider。

剪贴板、文件选择/句柄访问、应用/桌面搜索与启动、媒体控制、通知、HTTP 请求和系统状态
均已通过 `task.start` / `data.subscribe` 的窄能力开放，并继续受清单权限、可信手势、额度、
取消和预览无副作用策略约束。尚未出现在 `system.capabilities()`、feature 目录和 LuaLS 中的
能力仍视为未开放；不要根据权限词汇自行推测函数名。
