# 🎮 Open RTS 代码结构入门指南

> 这是一个用 **Godot 4** 引擎制作的开源实时策略（RTS）游戏框架，适合想学习 RTS 开发的初学者。

---

## 一、项目概览

```
godot-open-rts/
├── assets/       ← 游戏资源（3D模型、图片、音效、翻译文件）
├── source/       ← 🔥 核心代码（我们主要看这里）
├── tests/        ← 测试文件
├── project.godot ← Godot 项目配置文件
└── README.md     ← 项目说明书
```

---

## 二、source/ 目录：核心代码总览

```
source/
├── Main.tscn / Main.gd           ← 🚪 游戏入口（启动画面）
├── Constants.gd                  ← 📋 全局常量
├── Globals.gd                    ← 🌍 全局变量
├── Signals.gd                    ← 📢 全局信号
├── FeatureFlags.gd               ← 🚩 功能开关
├── Utils.gd                      ← 🧰 工具函数
│
├── main-menu/                    ← 🏠 主菜单
├── match/                        ← ⚔️ 对局系统（最核心！）
├── data-model/                   ← 📦 数据模型
├── generic-scenes-and-nodes/     ← 🔧 通用组件
├── resources/                    ← 🎨 样式资源
├── shaders/                      ← ✨ 着色器特效
└── utils/                        ← 🛠 更多工具
```

---

## 三、从启动入口开始理解

### 1. 程序启动流程

```
Main.tscn（Logo画面）→ main-menu/Main.tscn（主菜单）→ match/Match.tscn（游戏对局）
```

**`Main.gd`** — 入口脚本：
- 显示 Logo 后自动跳转到主菜单

**`project.godot`** 中设置了「自动加载」（Autoload），这些脚本在游戏启动时就会被加载，全局都可访问：

| 自动加载名 | 用途 |
|-----------|------|
| `Constants` | 所有常量定义（如单位属性、资源成本等）|
| `Globals` | 全局变量（如游戏选项、上帝模式开关）|
| `Signals` | 全局信号（如上帝模式开启/关闭）|
| `MatchSignals` | 对局信号（选择单位、开始战斗等）|
| `Utils` | 工具函数库 |
| `FeatureFlags` | 功能开关（显示小地图、允许调试等）|

> 🧠 **初学者笔记**：Autoload 是 Godot 的"全局变量"机制，就像游戏的"工具箱"，任何代码都可以直接使用它们，不需要手动引用。

### 2. 最重要的自动加载文件

**`Constants.gd`** — 游戏的「字典」：
- 定义了玩家类型（人类 / AI）
- 定义了玩家的颜色列表
- 指向各种场景文件的路径

**`MatchConstants.gd`** — 对局的「百科全书」（在 Constants.gd 中被引用）：
- 地图信息（大小、玩家人数）
- 导航层级参数（空中/地面）
- **单位属性**：每个单位的 HP、攻击力、视野、造价、建造时间
- **资源定义**：两种资源（A 和 B）的颜色和采集时间
- 弹射物映射（哪种单位发射哪种炮弹）

---

## 四、⚔️ match/ 目录：游戏对局核心（最大、最重要的目录）

```
match/
├── Match.tscn / Match.gd      ← 🎮 对局主控
├── MatchSignals.gd             ← 📢 对局信号
├── MatchConstants.gd           ← 📋 对局常量
├── MatchUtils.gd               ← 🧰 对局工具
│
├── Menu.gd                     ← ⏸️ 暂停菜单
├── Map.gd                      ← 🗺️ 地图
├── Terrain.gd                  ← 🌄 地形
├── IsometricCamera3D.gd        ← 📷 等距摄像机
├── Navigation.gd               ← 🧭 导航系统
├── FogOfWar.gd                 ← 🌫️ 战争迷雾
├── AirNavigation.gd            ← ✈️ 空中导航
├── TerrainNavigation.gd        ← 🚗 地面导航
│
├── players/                    ← 👤 玩家系统
├── units/                      ← 🚁 单位系统（最大子目录）
├── handlers/                   ← 🖱️ 交互处理器
├── hud/                        ← 📊 界面
├── debug/                      ← 🐛 调试工具
├── utils/                      ← 🛠 对局工具
├── decorations/                ← 🎄 装饰物
└── maps/                       ← 🗺️ 地图文件
```

### 1. Match.gd — 对局的总指挥

这是**整个对局的大脑**，负责：
1. 加载地图
2. 创建玩家（人类和AI）
3. 给每个玩家生成初始单位（指挥中心 + 无人机 + 工人）
4. 设置摄像机位置
5. 初始化战争迷雾和导航系统
6. 处理点击空白处取消选择

### 2. match/players/ — 玩家系统

```
players/
├── Player.gd               ← 👤 玩家基类（拥有资源、颜色）
├── Player.tscn
├── human/
│   ├── Human.gd            ← 🧑 人类玩家（处理鼠标点击攻击）
│   ├── AttackModeController
│   └── UnitActionsController
└── simple-clairvoyant-ai/
    ├── SimpleClairvoyantAI.gd  ← 🤖 AI玩家
    ├── EconomyController       ← 经济管理
    ├── DefenseController       ← 防御管理
    ├── OffenseController       ← 进攻管理
    ├── IntelligenceController  ← 情报管理
    ├── ConstructionWorksController ← 建造管理
    └── AutoAttackingBattlegroup   ← 自动攻击编队
```

**`Player.gd`** — 玩家基类：
- 拥有两种资源：`resource_a` 和 `resource_b`
- 有 `add_resources()`、`has_resources()`、`subtract_resources()` 等方法
- 每个玩家有自己的颜色

**Human.gd** — 人类玩家：
- 继承自 Player
- 处理鼠标攻击指令
- 控制单位执行操作

**AI 玩家** — 由多个"控制器"组成，各司其职：
- `EconomyController`：管理资源采集和生产
- `DefenseController`：建造防御塔
- `OffenseController`：组织进攻部队
- `IntelligenceController`：侦察敌情
- `ConstructionWorksController`：安排工人建造建筑

> 🧠 **初学者笔记**：AI 被拆分成多个小控制器，每个只负责一件事，这样代码更容易理解和维护。

### 3. match/units/ — 单位系统（最大的子目录）

#### 3.1 单位的类型

每种单位用一个 `.tscn` 场景 + `.gd` 脚本表示：

| 单位 | 类型 | 说明 |
|------|------|------|
| `CommandCenter` | 建筑 | 指挥中心，生产工人 |
| `VehicleFactory` | 建筑 | 车辆工厂，生产坦克 |
| `AircraftFactory` | 建筑 | 飞行器工厂，生产直升机/无人机 |
| `AntiGroundTurret` | 建筑 | 对地炮塔 |
| `AntiAirTurret` | 建筑 | 对空炮塔 |
| `Worker` | 地面单位 | 工人，采集资源、建造建筑 |
| `Tank` | 地面单位 | 坦克，对地攻击 |
| `Drone` | 空中单位 | 无人机，侦察 |
| `Helicopter` | 空中单位 | 直升机，对地/对空攻击 |

#### 3.2 Unit.gd — 所有单位的基类

所有单位都继承自 `Unit.gd`，它定义了单位的共同属性：

- **属性**：`hp`（血量）、`hp_max`（最大血量）、`attack_damage`（攻击力）、`attack_range`（攻击范围）、`sight_range`（视野范围）
- **引用父节点为玩家**：`player` 属性通过 `get_parent()` 获取
- **自动颜色**：根据所属玩家的颜色自动着色
- **死亡处理**：`hp` 降到 0 时自动销毁并发出信号
- **动作系统**：通过 `action` 属性控制单位当前在做什么

#### 3.3 match/units/actions/ — 单位动作系统

单位能做的各种"动作"，每个动作是一个独立的脚本：

| 动作 | 说明 |
|------|------|
| `Moving.gd` | 移动到指定位置 |
| `MovingToUnit.gd` | 移动到某个单位附近 |
| `Following.gd` | 跟随目标 |
| `FollowingToReachDistance.gd` | 跟随到一定距离 |
| `AttackingWhileInRange.gd` | 进入射程后攻击 |
| `AutoAttacking.gd` | 自动攻击附近敌人 |
| `CollectingResourcesWhileInRange.gd` | 进入资源点后采集 |
| `CollectingResourcesSequentially.gd` | 按顺序采集多个资源 |
| `Constructing.gd` | 建造建筑 |
| `ConstructingWhileInRange.gd` | 靠近后建造 |
| `WaitingForTargets.gd` | 等待敌人出现 |

> 🧠 **初学者笔记**：每个动作是一个独立的脚本节点，附加到单位上。这就像给单位下达"命令"，单位收到后就会自动执行。这种设计让代码很干净，想添加新行为只需创建新的动作脚本。

#### 3.4 match/units/traits/ — 单位的"特性"（组件）

特性是附加在单位上的小功能模块：

| 特性 | 说明 |
|------|------|
| `Movement` | 移动能力（地面/空中）|
| `MovementObstacle` | 作为障碍物阻挡其他单位 |
| `HealthBar` | 显示血条 |
| `Highlight` | 选中时高亮 |
| `Selection` | 可被选中 |
| `Targetability` | 可被攻击 |
| `ProductionQueue` | 生产队列（建筑用）|
| `RallyPoint` | 集结点（建筑用）|
| `Sparkling` | 闪烁效果（资源用）|
| `RotateRandomlyWhenLookingForTargetsIdle` | 空闲时随机旋转（搜索目标）|
| `AirToTerrainMarker` | 空中单位在地上的投影标记 |

> 🧠 **初学者笔记**：特性类似于"插件"或"组件"。单位想要什么功能就添加什么特性，比如移动的单位加 Movement，能生产的建筑加 ProductionQueue。这种设计非常灵活！

#### 3.5 非玩家单位（资源）

```
units/non-player/
├── ResourceUnit.gd   ← 资源基类
├── ResourceA.tscn     ← A 类资源
└── ResourceB.tscn     ← B 类资源
```

#### 3.6 弹射物

```
units/projectiles/
├── CannonShell.tscn   ← 炮弹（坦克、对地炮塔使用）
└── Rocket.tscn        ← 火箭弹（直升机、对空炮塔使用）
```

### 4. match/handlers/ — 交互处理器

处理各种玩家交互逻辑：

| 处理器 | 说明 |
|--------|------|
| `ArealUnitSelectionHandler` | 框选单位（拖拽矩形选择）|
| `DoubleClickUnitSelectionHandler` | 双击选择同类单位 |
| `UnitGroupSelectionHandler` | 数字键编组选择（Ctrl+1~9 编组，1~9 选择）|
| `MatchEndHandler` | 对局结束判定 |
| `MouseClickAnimationsHandler` | 鼠标点击动画效果 |
| `UnitVisibilityHandler` | 单位可见性控制 |

### 5. match/hud/ — 游戏界面

| 文件 | 说明 |
|------|------|
| `Minimap.gd` | 小地图 |
| `ResourcesBar.gd` | 资源显示条（两种资源的数量）|
| `Resources.gd` | 资源管理 |
| `ProductionQueue.gd` | 生产队列显示 |
| `UnitMenus.gd` | 单位操作菜单 |
| `unit-menus/` | 各单位的具体操作面板 |

### 6. match/utils/ — 对局工具

| 文件 | 说明 |
|------|------|
| `UnitMovementUtils.gd` | 单位移动工具 |
| `UnitPlacementUtils.gd` | 单位放置工具 |
| `ResourceUtils.gd` | 资源工具 |
| `ResourceDecayAnimation.gd` | 资源衰减动画 |
| `SparklingAnimation.gd` | 闪烁动画 |
| `MouseClickAnimation.tscn` | 鼠标点击动画 |

---

## 五、其他目录

### main-menu/ — 主菜单

```
main-menu/
├── Main.tscn / Main.gd     ← 主菜单界面
├── Play.gd                  ← 开始游戏设置（选择地图、玩家等）
├── Options.gd               ← 游戏设置选项
├── Credits.gd               ← 制作人员
├── Loading.gd               ← 加载画面
└── Background.tscn          ← 背景
```

### data-model/ — 数据模型

```
data-model/
├── MatchSettings.gd         ← 对局设置（地图、玩家列表等）
├── PlayerSettings.gd        ← 玩家设置（控制器类型、颜色等）
└── Options.gd               ← 选项数据
```

### generic-scenes-and-nodes/ — 通用组件

```
generic-scenes-and-nodes/
├── 2d/                      ← 2D 通用组件
├── 3d/                      ← 3D 通用组件
└── control/                 ← UI 通用组件
```

---

## 六、核心数据流向（一句话搞懂游戏怎么跑）

```
1️⃣ 主菜单 → 玩家选择设置（地图、对手等）
       ↓
2️⃣ Match.gd 根据设置创建对局
       ↓
3️⃣ 自动生成玩家和初始单位
       ↓
4️⃣ 玩家（Human/AI）通过信号控制单位
       ↓
5️⃣ 单位接收动作指令（移动/攻击/采集/建造）
       ↓
6️⃣ 动作驱动单位执行具体行为
       ↓
7️⃣ 战争迷雾、导航系统、界面持续更新
       ↓
8️⃣ 某方单位全灭 → 对局结束 → 返回主菜单
```

---

## 七、信号系统（Sinal）—— 组件之间的"对讲机"

Godot 的信号机制是这个框架各个部分**通信**的关键。例如：

**全局信号** `Signals.gd`：
- `god_mode_enabled` / `god_mode_disabled` — 上帝模式开关

**对局信号** `MatchSignals.gd`：
- `match_started` — 对局开始
- `unit_selected` / `unit_deselected` — 单位选中/取消
- `unit_spawned` — 单位生成
- `unit_damaged` / `unit_died` — 单位受伤/死亡
- `unit_production_started` / `unit_production_finished` — 单位生产开始/完成
- `terrain_targeted` / `unit_targeted` — 点击地面/点击单位

> 🧠 **初学者笔记**：可以想象信号是"广播"——A 处喊一声"unit_died!"，所有关心这个事件的代码都会收到通知并做出反应。这样各个模块之间就不需要互相"认识"，降低了耦合度。

---

## 八、初学者开发指南

### 从哪里开始修改？

| 你想做什么 | 找哪个文件 |
|-----------|-----------|
| 修改坦克的攻击力 | `MatchConstants.gd` → `Units.DEFAULT_PROPERTIES` |
| 新增一种单位 | 复制一个单位文件夹 + 在 `MatchConstants.gd` 注册属性 |
| 修改 AI 策略 | `players/simple-clairvoyant-ai/` 下的控制器 |
| 新增单位动作 | `units/actions/` 下新建动作脚本 |
| 修改单位外观 | `assets/` 下的 .glb 3D 模型文件 |
| 添加新地图 | `match/maps/` 下新建场景 |
| 修改 UI 界面 | `match/hud/` 下的脚本和场景 |

### 常见问题

**Q: 游戏入口在哪里？**
A: `Main.tscn` 是入口，显示 Logo 后跳转到 `main-menu/Main.tscn`。

**Q: 我想加一个新单位，需要改哪些文件？**
A: 至少需要：① 新建单位场景和脚本（参考 Tank 或 Drone）② 在 `MatchConstants.gd` 的 `DEFAULT_PROPERTIES` 添加属性 ③ 如果是可生产的单位，在 `PRODUCTION_COSTS` 和 `PRODUCTION_TIMES` 添加。

**Q: 代码里经常出现 `@onready` 是什么？**
A: Godot 的语法，表示"在节点准备好后获取子节点"，等价于在 `_ready()` 中写 `find_child("名字")`。

**Q: `preload` 和 `load` 有什么区别？**
A: `preload` 在编译时加载（更快），`load` 在运行时加载。框架里大量使用 `preload` 来提高性能。

---

## 九、推荐的阅读顺序

如果你是初学者，建议按这个顺序阅读核心代码：

1. **`Constants.gd`** → 了解游戏有哪些常量和类型
2. **`MatchConstants.gd`** → 了解单位属性、资源、地图配置
3. **`Match.gd`** → 了解对局如何启动和初始化
4. **`Unit.gd`** → 了解单位的基础
5. **`Player.gd`** → 了解玩家如何管理资源
6. **`units/actions/Moving.gd`** → 了解动作系统的工作方式
7. **`units/traits/Movement.gd`** → 了解特性系统
8. **`FogOfWar.gd`** → 了解战争迷雾
9. **`Human.gd`** → 了解人类玩家的交互
10. **`SimpleClairvoyantAI.gd`** → 了解AI的工作方式

---

这个框架虽然看起来文件很多，但**结构非常清晰**，每个文件都有明确的职责。作为初学者，理解了这个结构后，就可以有针对性地去修改和扩展你想要的功能了！

祝你开发愉快 🎉
