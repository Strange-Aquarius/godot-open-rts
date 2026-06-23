# Open RTS — 代码结构文档

> Godot 4.6 RTS 游戏模板 | MIT License | Copyright 2023 Lampe Games | v0.9.0

---

## 一、顶层目录结构

```
godot-open-rts/
├── project.godot          # 项目配置 (6个Autoload, 22个输入映射, 4个翻译文件)
├── source/                # 🎯 全部源代码 (脚本+场景+着色器)
├── assets/                # 📦 静态资源 (3D模型/UI贴图/语音/翻译)
├── tests/manual/          # 🧪 手动测试场景
├── build/                 # 📤 导出输出目录
├── media/                 # 📸 宣传截图/Logo源文件
├── doc/                   # 📖 文档
└── makefile               # 构建/格式化自动化
```

---

## 二、六层架构 (从底层到顶层)

### Layer 0 — Autoload 全局单例 (6个)

| 文件 | 作用 |
|---|---|
| [source/Constants.gd](../source/Constants.gd) | 全局常量：玩家颜色(20色)、单位属性、导航参数、生产成本、语音映射 |
| [source/FeatureFlags.gd](../source/FeatureFlags.gd) | 功能开关：赤字消费、logo展示、小地图、帧步进、上帝模式 |
| [source/Globals.gd](../source/Globals.gd) | 运行时全局状态：选项(options)、上帝模式切换 |
| [source/Signals.gd](../source/Signals.gd) | 全局信号：`god_mode_enabled` / `god_mode_disabled` |
| [source/MatchSignals.gd](../source/match/MatchSignals.gd) | 对局信号总线 (26个信号) — **事件驱动架构核心** |
| [source/Utils.gd](../source/Utils.gd) | 工具类：`Set`, `Dict`, `Float`, `Colour`, `NodeEx`, `Arr`, `RouletteWheel` |

**信号总线是通信核心** — `MatchSignals` 提供完整的请求/通知机制：

- **请求信号**: `deselect_all_units`, `setup_and_spawn_unit`, `place_structure`, `schedule_navigation_rebake`, `navigate_unit_to_rally_point`
- **通知信号**: `match_started/aborted/finished_with_victory/defeat`, `terrain_targeted`, `unit_spawned/targeted/selected/deselected/damaged/died`, `unit_production_started/finished`, `unit_construction_finished`, `not_enough_resources_for_production/construction`

---

### Layer 1 — 入口与菜单

| 路径 | 说明 |
|---|---|
| [source/Main.gd](../source/Main.gd) | 根场景控制器 → Logo动画 → 主菜单 |
| [source/Logos.gd](../source/Logos.gd) | 启动Logo动画序列 |
| [source/main-menu/Main.gd](../source/main-menu/Main.gd) | 主菜单中枢 |
| [source/main-menu/Play.gd](../source/main-menu/Play.gd) | 对局设置：地图选择、玩家配置(类型/颜色) |
| [source/main-menu/Options.gd](../source/main-menu/Options.gd) | 选项：全屏/窗口、鼠标限制 |
| [source/main-menu/Credits.gd](../source/main-menu/Credits.gd) | 致谢页面 |
| [source/main-menu/Loading.gd](../source/main-menu/Loading.gd) | 对局加载过渡页面 |

**数据模型** (用于菜单→对局的参数传递):
- [source/data-model/MatchSettings.gd](../source/data-model/MatchSettings.gd) — 对局配置：玩家数组、可见模式、观察视角
- [source/data-model/PlayerSettings.gd](../source/data-model/PlayerSettings.gd) — 玩家配置：颜色、控制器类型、出生点偏移
- [source/data-model/Options.gd](../source/data-model/Options.gd) — 用户选项：屏幕模式、鼠标限制

---

### Layer 2 — 对局核心 (`source/match/`)

| 文件 | 说明 |
|---|---|
| [Match.gd](../source/match/Match.gd) | **对局主控**: 管理地图加载、玩家创建、迷雾、相机、导航、HUD |
| [Map.gd](../source/match/Map.gd) | 地图容器，加载 `maps/` 下的 tscn 场景 |
| [IsometricCamera3D.gd](../source/match/IsometricCamera3D.gd) | 等距相机：WASD移动、QE旋转、滚轮缩放、边缘滚动 |
| [FogOfWar.gd](../source/match/FogOfWar.gd) | 战争迷雾系统，3种可见模式 (PER_PLAYER/ALL_PLAYERS/FULL) |
| [Terrain.gd](../source/match/Terrain.gd) | 地形地面 (StaticBody3D) |
| [TerrainNavigation.gd](../source/match/TerrainNavigation.gd) | 地面导航系统 (NavigationAgent3D) |
| [AirNavigation.gd](../source/match/AirNavigation.gd) | 空中导航系统 (独立的导航层次 Y=1.5) |

**地图** (`source/match/maps/`):
- `PlainAndSimple.tscn` — 4玩家 50x50
- `BigArena.tscn` — 8玩家 100x100

**辅助模块**:
- [MatchConstants.gd](../source/match/MatchConstants.gd) — 导航域、资源、单位属性、生产、语音旁白常量
- [MatchUtils.gd](../source/match/MatchUtils.gd) — 树遍历工具、材质替换工具
- [source/match/utils/ResourceDecayAnimation.gd](../source/match/utils/ResourceDecayAnimation.gd) — 资源采集动画
- [source/match/utils/UnitMovementUtils.gd](../source/match/utils/UnitMovementUtils.gd) — 单位移动辅助
- [source/match/utils/UnitPlacementUtils.gd](../source/match/utils/UnitPlacementUtils.gd) — 单位放置辅助

**物理层** (4个):
| 层 | 名称 | 用途 |
|---|---|---|
| Layer 1 | Terrain | 地面碰撞 |
| Layer 2 | TerrainObjects | 地面单位/建筑 |
| Layer 3 | AirObjects | 空中单位 |
| Layer 4 | Air | 空中碰撞 |

---

### Layer 3 — 玩家系统 (`source/match/players/`)

```
Player.gd (基类 Node3D) ── 资源管理(resource_a/resource_b)、颜色材质
├── Human.gd ── 人类玩家控制
│   ├── AttackModeController.gd      # A键攻击模式切换
│   ├── UnitActionsController.gd     # 右键命令分发(移动/攻击/采集)
│   ├── StructurePlacementHandler.gd # 建筑蓝图放置+放置验证
│   ├── UnitVoicesController.gd      # 单位语音响应(sir/yes_sir/acknowledged)
│   └── VoiceNarratorController.gd   # 旁白语音播报(战斗/生产/警戒)
└── SimpleClairvoyantAI.gd ── AI (透视全图)
    ├── EconomyController.gd         # 经济策略：扩张+产兵
    ├── DefenseController.gd         # 防御策略：造塔+守家
    ├── OffenseController.gd         # 进攻策略：编队出击
    ├── IntelligenceController.gd    # 侦察/情报收集
    ├── ConstructionWorksController.gd # 建筑工管理
    └── AutoAttackingBattlegroup.gd  # 自动攻击编队
```

**Player.gd 核心API:**
- `add_resources(resources)` — 增加资源
- `subtract_resources(resources)` — 扣除资源
- `has_resources(resources)` — 检查资源是否足够 (受FeatureFlags.deficit_spending影响)
- `get_color_material()` — 获取玩家颜色的 StandardMaterial3D

---

### Layer 4 — 单位系统 (`source/match/units/`)

#### 类继承链

```
Area3D
├── Unit.gd (基类) — HP/伤害/阵营/动作系统
│   ├── Structure.gd (建筑基类，不可移动，生成时立即到位)
│   │   ├── CommandCenter.gd   # 主基地 → 生产 Worker
│   │   ├── VehicleFactory.gd  # 车厂 → 生产 Tank
│   │   ├── AircraftFactory.gd # 机场 → 生产 Drone/Helicopter
│   │   ├── AntiGroundTurret.gd # 对地炮塔
│   │   └── AntiAirTurret.gd   # 对空炮塔
│   ├── Worker.gd      # 资源采集 (采集 ResourceA/B)
│   ├── Tank.gd        # 地面主战坦克 (对地攻击)
│   ├── Drone.gd       # 空中侦察/轻攻击
│   └── Helicopter.gd  # 武装直升机 (对空+对地双域攻击)
└── ResourceUnit.gd (中立单位)
    ├── ResourceA.gd   # 蓝水晶 (采集时间 1s)
    └── ResourceB.gd   # 红水晶 (采集时间 2s)
```

#### 单位核心属性 (Unit.gd)

| 属性 | 说明 |
|---|---|
| `hp` / `hp_max` | 生命值（setter触发伤害事件和死亡处理） |
| `attack_damage` | 攻击伤害 |
| `attack_interval` | 攻击间隔 |
| `attack_range` | 攻击范围 |
| `attack_domains` | 可攻击域 (TERRAIN/AIR) |
| `sight_range` | 视野范围 (用于迷雾揭示) |
| `radius` | 碰撞半径 (从Movement或MovementObstacle子节点获取) |
| `movement_domain` | 移动域 (TERRAIN/AIR) |
| `movement_speed` | 移动速度 |
| `player` | 所属玩家 (parent节点) |
| `color` | 玩家颜色 (从player获取) |
| `action` | 当前行为 (Action子节点，setter处理切换) |
| `type` | 单位类型名 (自动从脚本文件名提取) |

关键机制：
- `_setup_default_properties_from_constants()` — 从 Constants 中按场景路径自动加载默认属性
- `_setup_color()` — 递归遍历Geometry节点替换材质颜色
- `_action_locked` — 防止行为切换竞态条件

#### 动作系统 (Action 组合模式)

单位通过 `unit.action = action_node` 在运行时切换行为。所有 Action 继承自 `Action.gd` (extends Node)：

| Action | 用途 |
|---|---|
| `Moving.gd` | 移动到指定位置 (通过 NavigationAgent3D) |
| `MovingToUnit.gd` | 追踪移动到目标单位 |
| `AttackingWhileInRange.gd` | 进入射程后持续攻击 |
| `AutoAttacking.gd` | 自动搜索范围内敌人并攻击 |
| `CollectingResourcesSequentially.gd` | 完整采集循环 (靠近→采集→返回→交付) |
| `CollectingResourcesWhileInRange.gd` | 在范围内持续采集 |
| `Constructing.gd` | 移动到建筑工地并建造 |
| `ConstructingWhileInRange.gd` | 在范围内持续建造 |
| `Following.gd` | 跟随单位 |
| `FollowingToReachDistance.gd` | 跟随直到达到指定距离 |
| `WaitingForTargets.gd` | 待机，自动索敌后转入攻击 |

#### 特性组件 (Trait 模式 — 附加到单位的子节点)

| Trait | 类型 | 用途 |
|---|---|---|
| `Movement.gd` | NavigationAgent3D | 寻路移动代理 (含domain, speed, radius) |
| `MovementObstacle.gd` | NavigationObstacle3D | 建筑占位阻挡 (静态) |
| `HealthBar.gd` | Node3D | 血条显示 (Sprite3D) |
| `Selection.gd` | Node3D | 选中圆环 (shader绘制) |
| `Highlight.gd` | Node3D | 鼠标悬停高亮 |
| `Targetability.gd` | Node3D | 可被瞄准属性配置 |
| `Sparkling.gd` | Node3D | 闪光特效 |
| `AirToTerrainMarker.gd` | Node3D | 空中单位的地面投影标记 |
| `ProductionQueue.gd` | Node | 建筑生产队列逻辑 |
| `RallyPoint.gd` | Node3D | 集结点标记+寻路 |
| `RotateRandomlyWhenLookingForTargetsIdle.gd` | Node | 待机索敌时随机旋转 |
| `ActionCaption.gd` (debug) | Label3D | 调试用，显示当前Action名称 |

#### 弹道系统

| 弹道 | 对应武器 |
|---|---|
| `CannonShell.gd` | 坦克/炮塔炮弹 (Node3D) |
| `Rocket.gd` | 直升机/防空导弹 (Node3D) |

---

### Layer 5 — HUD 与交互 (`source/match/hud/` + `handlers/`)

#### HUD 组件

| 组件 | 说明 |
|---|---|
| `Minimap.gd` | 小地图显示 |
| `Resources.gd` / `ResourcesBar.gd` | 资源计数器 + 可视化资源条 |
| `UnitMenus.gd` | 底部单位指令面板（根据选中单位类型切换菜单） |
| `ProductionQueue.gd` / `ProductionQueueElement.gd` | 生产队列显示 + 单项取消按钮 |
| `unit-menus/GenericMenu.gd` | 通用单位指令按钮（移动/停止/攻击） |
| `unit-menus/WorkerMenu.gd` | 工人专用（建造建筑按钮列表） |
| `unit-menus/VehicleFactoryMenu.gd` | 车厂生产菜单 |
| `unit-menus/AircraftFactoryMenu.gd` | 机场生产菜单 |
| `unit-menus/CommandCenterMenu.gd` | 主基地菜单 |

#### 交互处理器

| 组件 | 说明 |
|---|---|
| `ArealUnitSelectionHandler.gd` | 拖拽框选单位 |
| `DoubleClickUnitSelectionHandler.gd` | 双击选取同类型所有可见单位 |
| `UnitGroupSelectionHandler.gd` | Ctrl+数字编队 (9组) / 数字键快速选择编队 |
| `UnitVisibilityHandler.gd` | 战争迷雾可见性控制 (reveal/conceal) |
| `MouseClickAnimationsHandler.gd` | 鼠标点击涟漪动画 |
| `MatchEndHandler.gd` | 对局结束画面 (胜利/失败) |

---

### Layer 6 — Debug调试工具 (`source/match/debug/`)

| 工具 | 快捷键 | 功能 |
|---|---|---|
| `DiagnosticHud.gd` | F4 | FPS / 性能叠加层 |
| `GodModeHud.gd` | F2 | 上帝模式：自由视角、无限资源、所有玩家可见 |
| `FrameIncrementer.gd` | F8 | 逐帧步进 (空格键步进) |
| `TimeManager.gd` | — | 游戏速度控制 (暂停/1x/2x/4x) |
| `UnitsManager.gd` | — | 单位生成测试面板 |
| `FogOfWarManager.gd` | — | 迷雾调试面板 |
| `VisiblePlayerManager.gd` | — | 切换观察视角 |

---

## 三、输入系统 (22个动作映射)

| 输入动作 | 按键 | 用途 |
|---|---|---|
| `move_map_up/down/left/right` | W/S/A/D | 相机移动 |
| `rotate_map_clockwise/counterclockwise` | Q/E | 相机旋转 |
| `shift_selecting` | Shift | 追加选择 |
| `toggle_attack_mode` | A | 攻击模式切换 |
| `toggle_god_mode` | F2 | 上帝模式 |
| `toggle_diagnostic_mode` | F4 | 诊断模式 |
| `toggle_frame_incrementer` | F8 | 帧步进 |
| `frame_incrementer_step` | Space | 步进一帧 |
| `toggle_match_menu` | Escape | 暂停菜单 |
| `rotate_structure` | R | 建筑旋转 |
| `god_mode_delete_units` | Delete | 删除单位 (上帝模式) |
| `unit_groups_set_1~9` | Ctrl+1~9 | 设置编队 |
| `unit_groups_access_1~9` | 1~9 | 选择编队 |

---

## 四、资源体系

### 资产目录 (`assets/`)

| 目录 | 内容 |
|---|---|
| `models/kenney-spacekit/` | 100+ GLB 3D模型 (飞船/建筑/走廊/平台/管道/道具) |
| `ui/kenney-crosshairs/` | 70+ 十字准星PNG |
| `voice/alayna-us/` | 10个OGG — 旁白语音 (美式女声 TTS) |
| `voice/jackson-us/` | 3个OGG — 单位响应语音 (美式男声 TTS) |
| `translations/` | 4个翻译文件 (英文+波兰语 各2组: main_menu + match) |
| `logos/` | Godot logo (CC-BY-4.0) + Lampe Games logo |

### 材质 (`source/match/resources/materials/`)

| 材质 | 用途 |
|---|---|
| `terrain.material.tres` | 地形材质 |
| `resource_a.material.tres` | 蓝水晶材质 |
| `resource_b.material.tres` | 红水晶材质 |
| `blueprint_valid.material.tres` | 建筑放置有效 (绿色半透明) |
| `blueprint_invalid.material.tres` | 建筑放置无效 (红色半透明) |
| `structure_under_construction.material.tres` | 建筑建造中特效 |
| `controlled_unit_air_to_terrain_marker.material.tres` | 已方空中单位地面标记 |
| `adversary_unit_air_to_terrain_marker.material.tres` | 敌方空中单位地面标记 |

### 着色器 (`source/shaders/`)

| 着色器 | 域 | 用途 |
|---|---|---|
| `blurr.gdshader` | 2D | 模糊效果 |
| `white_transparent.gdshader` | 2D | 白色透明叠加 |
| `circle.gdshader` | 3D | 圆形绘制 (选中圈) |
| `faded_circle.gdshader` | 3D | 渐变圆形 |
| `fog.gdshader` / `simple_fog_of_war.gdshader` / `detailed_fog_of_war.gdshader` | 3D | 战争迷雾 |
| `air_to_terrain_marker.gdshader` | 3D | 空中单位地面投影 |

---

## 五、关键架构模式

### 1. 信号驱动通信
所有模块通过 `MatchSignals` 事件总线解耦。模块之间不持有直接引用，而是 emit/connect 信号。

### 2. Action 组合模式
单位行为由可替换的 Action 子节点实现。`_action_locked` 标志防止切换过程中出现竞态条件。旧 Action 在 `tree_exited` 信号中自动清理。

### 3. Trait 组合模式
功能组件（血条、选中圈、移动、高亮等）以独立子节点形式附加到单位。每个 Trait 是独立的可复用场景/脚本。

### 4. 双资源经济
Resource A (蓝水晶, 1s采集) 和 Resource B (红水晶, 2s采集)。每种生产/建造消耗不同的资源配比。

### 5. 双层导航
地面单位使用 `TerrainNavigation` (Y=0)，空中单位使用 `AirNavigation` (Y=1.5)。独立的 NavMesh 和 Agent 参数。

### 6. Autoload 全局状态
6 个单例：Constants(纯数据)、FeatureFlags(开关)、Globals(运行时状态)、Signals+MatchSignals(事件总线)、Utils(工具集)。

### 7. 场景驱动配置
单位属性不从代码硬编码，而是从 `Constants.Match.Units.DEFAULT_PROPERTIES` 字典按 `.tscn` 路径查找，实现配置与逻辑分离。

### 8. 颜色材质替换
单位模型使用标记色 `Color(0.99, 0.81, 0.48)` 作为"待替换像素"，运行时根据玩家颜色替换。通过 `MatchUtils.traverse_node_tree_and_replace_materials_matching_albedo()` 递归完成。

---

## 六、测试场景 (`tests/manual/`)

| 场景 | 用途 |
|---|---|
| `TestAllUnits.tscn` | 生成所有单位类型测试 |
| `TestOneUnit.tscn` | 单个单位测试 |
| `TestPlayerVsAI.tscn` | 人机对战测试 |
| `TestUnitsFightingEachOther.tscn` | 单位战斗测试 |
| `TestNonQuadraticMap.tscn` | 非正方形地图测试 |
| `maps/NonQuadratic.tscn` | 非方形地图资源 |

---

## 七、开发工作流

- **代码格式化**: `make format-check` (gdformat) + `make shaders-format-check` (.clang-format for shaders)
- **代码检查**: `make lint` (gdlint)
- **圈复杂度**: `make cc`
- **CI**: GitHub Actions 在 push/PR 到 main 时自动运行 format + lint
- **导出**: `make release-linux/macos/windows`
- **警告**: 项目关闭了部分 GDScript 警告 (unused_signal, standalone_expression, incompatible_ternary 等)
