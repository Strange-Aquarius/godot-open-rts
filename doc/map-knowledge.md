# 地图系统知识文档

> 涵盖：现有地图清单、地图原理、Plain & Simple 玩法与代码逐行解析、如何新建地图

---

## 一、现有地图清单

### 正式地图（可通过主菜单选择游玩）

| 地图 | 文件 | 玩家数 | 尺寸 | 说明 |
|---|---|---|---|---|
| **Plain & Simple** | `source/match/maps/PlainAndSimple.tscn` | 4 | 50×50 | 54×54 平面，4 个出生点分布于四角 |
| **Big Arena** | `source/match/maps/BigArena.tscn` | 8 | 100×100 | 104×104 平面，8 个出生点 + RockLargeA 装饰物 |

地图注册在 [source/match/MatchConstants.gd](../source/match/MatchConstants.gd) 的 `MAPS` 字典中：

```gdscript
const MAPS = {
    "res://source/match/maps/PlainAndSimple.tscn":
    {
        "name": "Plain & Simple",
        "players": 4,
        "size": Vector2i(50, 50),
    },
    "res://source/match/maps/BigArena.tscn":
    {
        "name": "Big Arena",
        "players": 8,
        "size": Vector2i(100, 100),
    },
}
```

### 测试地图（不显示在菜单中）

| 地图 | 文件 | 尺寸 | 用途 |
|---|---|---|---|
| **NonQuadratic** | `tests/manual/maps/NonQuadratic.tscn` | 100×50 | 测试非正方形地形 |

---

## 二、地图场景架构原理

### 模板继承关系

每张地图都继承自一个公共的父模板 `Map.tscn`：

```
Map.tscn (父模板)
├── Geometry
│   ├── BlackBackgroundFixingAntiAliasingBug  # 黑色背景面（修复抗锯齿 bug）
│   └── Terrain (默认 1000×1000 占位 PlaneMesh)
├── SpawnPoints (空容器，等子地图填充 Marker3D)
├── Resources (空容器，等子地图填充资源水晶)
└── Decorations (空容器，等子地图填充装饰物)
```

每张子地图通过 `instance=ExtResource("Map.tscn")` 实例化父模板，然后**覆写**关键节点：
- 替换 `Terrain` 的 `mesh` 为实际尺寸的 PlaneMesh
- 填充 `SpawnPoints` 下的 `Marker3D`
- 填充 `Resources` 下的 `ResourceA` / `ResourceB`
- （可选）填充 `Decorations` 下的装饰物

### Map.gd 脚本核心逻辑

[Map.gd](../source/match/Map.gd) 提供了一个 `@tool` 脚本（在编辑器中和运行时都生效）：

```gdscript
@tool
extends Node3D

const EXTRA_MARGIN = 2

@export var size = Vector2(50, 50):
    set(a_size):
        size = a_size
        find_child("Terrain").mesh.size = size + Vector2(EXTRA_MARGIN, EXTRA_MARGIN) * 2
        find_child("Terrain").mesh.center_offset = Vector3(size.x, 0.0, size.y) / 2.0

func get_topdown_polygon_2d():
    return [Vector2(0, 0), Vector2(size.x, 0), size, Vector2(0, size.y)]
```

- `EXTRA_MARGIN = 2`：地形 mesh 比逻辑尺寸每边多 2 米，避免地图边缘出现空白
- `get_topdown_polygon_2d()`：返回地图的 2D 俯视多边形，用于判断建筑蓝图是否越界
- `@tool`：编辑器内修改 `size` 时自动实时更新 terrain mesh

### 地图加载流程（Match.gd）

1. 菜单 `Play.gd` 选择地图路径 → 传给 `Loading.gd` → 传给 `Match.gd`
2. `Match._set_map()` 把地图场景添加为子节点
3. `_ready()` 中依次：
   - `_terrain.update_shape(map.Terrain.mesh)` — 更新物理地形
   - `fog_of_war.resize(map.size)` — 调整迷雾纹理
   - `_recalculate_camera_bounding_planes(map.size)` — 限制相机边界
   - `navigation.setup(map)` — 烘焙导航网格

---

## 三、Plain & Simple 玩法全解析

### 对局流程

#### 🏁 开始

1. 主菜单 → `Play` → 选 `Plain & Simple`
2. 配置 8 个玩家槽位（NONE / HUMAN / AI），人类玩家限 1 人
3. Start → Loading → 进入对局

#### 开局初始单位（每个玩家在出生点自动生成）

| 单位 | 数量 | 状态 |
|---|---|---|
| CommandCenter | 1 | **建设中**（工人需要先去建好它） |
| Drone | 1 | 飞行侦察（视野 10） |
| Worker | 2 | 资源采集 |

游戏开始语音：`"Battle Control Online"`

#### ❌ 结束条件

`MatchEndHandler.gd` 在每次单位死亡时检查：

| 条件 | 结果 |
|---|---|
| 人类玩家的所有单位被消灭 | ❌ **Defeat** — `"You Have Lost"` |
| 人类玩家存活 + 只剩 1 个玩家有单位 | ✅ **Victory** — `"You Are Victorious"` |
| 纯 AI 对战，只剩 1 个玩家 | Finish（显示结束画面，不区胜负） |

结束后游戏暂停，显示面板，点击 Exit 返回主菜单。

---

### 核心操作

#### 🖱️ 鼠标

| 操作 | 效果 |
|---|---|
| **左键点单位** | 选中单位，Shift+点击追加选择 |
| **左键拖拽** | 矩形框选 |
| **双击单位** | 选中屏幕上所有同类型己方单位 |
| **右键地面** | 移动选中单位到目标点（地面/空中自动分流） |
| **右键敌方** | 自动判断：可攻击→攻击、可采集→采集、可建造→建造 |
| **右键己方建筑** | 设置集结点（Rally Point） |
| **滚轮** | 缩放相机 |
| **屏幕边缘** | 相机滚动 |

#### ⌨️ 键盘

| 快捷键 | 功能 |
|---|---|
| **W/A/S/D** | 相机移动 |
| **Q/E** | 相机旋转 |
| **A** | 进入攻击模式（左键点地面→自动索敌攻击） |
| **R** | 蓝图旋转 45°（放置建筑时） |
| **Ctrl+1~9** | 编组 |
| **1~9** | 选择编组 |
| **Escape** | 暂停菜单 |
| **F2** | 上帝模式（无限资源、全图可见） |

---

### 单位与数值

#### 战斗单位

| 单位 | HP | 伤害 | 间隔 | 射程 | 攻击域 | 视野 | 移动域 |
|---|---|---|---|---|---|---|---|
| Tank | 10 | 2 | 0.75s | 5.0 | 地面 | 8 | 地面 |
| Helicopter | 10 | 1 | 1.0s | 5.0 | 地面+空中 | 8 | 空中 |
| Drone | 6 | 无 | — | — | — | 10 | 空中 |
| AntiGroundTurret | 8 | 2 | 1.0s | 8.0 | 地面 | 8 | 无（固定） |
| AntiAirTurret | 8 | 2 | 0.75s | 8.0 | 空中 | 8 | 无（固定） |

#### 生产建筑

| 建筑 | HP | 可生产 | 成本 | 耗时 |
|---|---|---|---|---|
| CommandCenter | 20 | Worker | 2A | 3s |
| VehicleFactory | 16 | Tank | 3A+1B | 6s |
| AircraftFactory | 16 | Drone | 2A | 3s |
| AircraftFactory | 16 | Helicopter | 1A+3B | 6s |

#### 建造建筑

| 建筑 | 成本 | HP |
|---|---|---|
| CommandCenter | 8A+8B | 20 |
| VehicleFactory | 6A | 16 |
| AircraftFactory | 4A+4B | 16 |
| AntiGroundTurret | 2A+2B | 8 |
| AntiAirTurret | 2A+2B | 8 |

#### 采集

| 资源 | 采集时间 | 初始分布（Plain & Simple） |
|---|---|---|
| ResourceA（蓝水晶） | 1 秒 | 12 个（4 区域各 3 个） |
| ResourceB（红水晶） | 2 秒 | 4 个（4 区域各 1 个） |

---

### 一条典型开局流程

```
1. 开局：1 CommandCenter(建设中) + 1 Drone + 2 Workers
                          ↓
2. 选 2 Workers → 右键建设中 CommandCenter → 完成建造
                          ↓
3. Drone 探路（飞行，视野 10）
                          ↓
4. Workers → 右键水晶采集资源
                          ↓
5. 积累资源 → Worker → 建造 VehicleFactory / AircraftFactory
                          ↓
6. Workers → 右键新建造的建筑 → 施工完成
                          ↓
7. 在建成建筑中下单生产战斗单位
                          ↓
8. 设集结点（右键位置或资源点）
                          ↓
9. 编队战斗单位 → A 键攻击模式 → 推平敌方基地
```

---

## 四、PlainAndSimple.tscn 逐行解析

### 先备：Godot 核心概念

| 概念 | 通俗理解 |
|---|---|
| **场景 `.tscn`** | 纯文本文件，描述节点树和属性。类似 Unity Prefab |
| **节点 `Node`** | 一切皆节点。`Node3D`=3D物体，`Area3D`=碰撞检测，`Control`=UI |
| **资源 `Resource`** | 可复用资产：材质、贴图、脚本、子场景等 |
| **`res://`** | 项目根目录的虚拟路径前缀 |
| **UID** | Godot 4.x 全局唯一 ID，文件移动/改名后引用不中断 |
| **PackedScene** | 打包的场景模板，调用 `.instantiate()` 克隆实例 |
| **Transform3D** | 4×3 矩阵 = 3×3 Basis(旋转) + origin(位移) |
| **Vector2** | 2D 向量 `(x, y)` |
| **Vector3** | 3D 向量 `(x, y, z)` — Y 轴朝上（在 Godot 中） |

### 第 1 行：文件头

```gdscript
[gd_scene load_steps=6 format=3 uid="uid://cbe63rdjw7y4p"]
```

| 字段 | 含义 |
|---|---|
| `gd_scene` | 这是一个 Godot 场景文件 |
| `load_steps=6` | 加载步骤总数：4 个 ext_resource + 1 个 sub_resource + 1 个根节点实例。引擎用来算进度条 |
| `format=3` | Godot 4.x 使用场景格式版本 3 |
| `uid="uid://cbe63rdjw7y4p"` | 此场景全局唯一标识符。其他文件通过 UID 引用，改名/移动后不丢引用 |

### 第 3-6 行：外部资源引用

```gdscript
[ext_resource type="PackedScene" uid="..." path="res://source/match/Map.tscn" id="1_sqrvi"]
[ext_resource type="Material"    uid="..." path="res://.../terrain.material.tres" id="2_sguro"]
[ext_resource type="PackedScene" uid="..." path="res://.../ResourceA.tscn"       id="3_3gxbc"]
[ext_resource type="PackedScene" uid="..." path="res://.../ResourceB.tscn"       id="4_4hhxt"]
```

| id | 文件 | 类型 | 作用 |
|---|---|---|---|
| `1_sqrvi` | `Map.tscn` | PackedScene | 父场景模板，本场景继承它 |
| `2_sguro` | `terrain.material.tres` | Material | 地形外观材质 |
| `3_3gxbc` | `ResourceA.tscn` | PackedScene | 蓝水晶模板 |
| `4_4hhxt` | `ResourceB.tscn` | PackedScene | 红水晶模板 |

- **ext_resource** = 外部资源：告诉引擎去硬盘加载文件
- **uid** 是首选查找方式（文件未移动时用 path 做 fallback）
- **id** 是此场景内的本地别名（后续通过 `ExtResource("id")` 引用）

### 第 8-12 行：地形网格子资源

```gdscript
[sub_resource type="PlaneMesh" id="PlaneMesh_frqq2"]
resource_local_to_scene = true
material = ExtResource("2_sguro")
size = Vector2(54, 54)
center_offset = Vector3(25, 0, 25)
```

| 行 | 含义 |
|---|---|
| `sub_resource type="PlaneMesh"` | 内嵌资源（不存单独文件）：一个长方形平面网格 |
| `resource_local_to_scene = true` | 设 true 后此 mesh 是本场景独立副本。不设的话多个场景引用同一 mesh，一改全改 |
| `material = ExtResource("2_sguro")` | 应用地形材质来渲染 |
| `size = Vector2(54, 54)` | 平面尺寸 54×54 米（比地图逻辑 50×50 每边多 2 米） |
| `center_offset = Vector3(25, 0, 25)` | 网格中心偏移到逻辑地图中心。不加偏移的话 mesh 从 (-27,-27) 开始，加了从 (-2,-2) 附近开始，匹配 4 个出生点位置 |

### 第 14 行：实例化父模板

```gdscript
[node name="Map" instance=ExtResource("1_sqrvi")]
```

1. 创建节点 `name="Map"`
2. `instance=ExtResource("1_sqrvi")` — 以 `Map.tscn` 为模板实例化。Map.tscn 内的所有子节点（Geometry→Terrain、SpawnPoints、Resources、Decorations）全部自动创建

### 第 16-17 行：覆写地形

```gdscript
[node name="Terrain" parent="Geometry" index="1"]
mesh = SubResource("PlaneMesh_frqq2")
```

| 字段 | 含义 |
|---|---|
| `parent="Geometry"` | 指明 Terrain 在 Geometry 节点下，用于精确匹配（父模板可能有多个叫 Terrain 的节点） |
| `index="1"` | 在父节点 Geometry 子列表中排第 1 位 |
| `mesh = SubResource(...)` | 把 Terrain 的 mesh 替换为我们第 8 行的 54×54 PlaneMesh |

### 第 19-29 行：4 个出生点

以 Player 1 为例：

```gdscript
[node name="Marker3D" type="Marker3D" parent="SpawnPoints" index="0"]
transform = Transform3D(-1, 0, -8.74228e-08, 0, 1, 0, 8.74228e-08, 0, -1, 10, 0, 7)
```

- `type="Marker3D"`：Godot 内置标记节点，无视觉，仅编辑器显示图标。用作出生点锚点
- `parent="SpawnPoints"`：挂在父模板的 SpawnPoints 容器下
- `index="0"`：第 0 个玩家（Match.gd 按子节点 index 分配出生点给 player_index）

#### Transform3D 矩阵拆解

`Transform3D` 存储为 12 个浮点数，分成 4 列：

```
Basis X:  (-1,          0, -8.74228e-08)  ← 局部X轴
Basis Y:  ( 0,          1,          0   )  ← 局部Y轴（朝上）
Basis Z:  ( 8.74228e-08, 0,         -1   )  ← 局部Z轴
Origin:   (10,          0,          7   )  ← 世界坐标位置
```

> `-8.74228e-08` ≈ `-0.000000087`，浮点精度的"零"。实际矩阵为：
> ```
> [-1  0   0]     [10]
> [ 0  1   0]  +  [ 0]
> [ 0  0  -1]     [ 7]
> ```
> 这是**绕 Y 轴旋转 180°** 的矩阵（X 和 Z 同时取反），目的：让生成的单位面朝地图中心。

4 个出生点一览：

| 节点 | 坐标 | 地图位置 |
|---|---|---|
| Marker3D [0] | (10, 0, 7) | 左下 |
| Marker3D2 [1] | (40, 0, 7) | 右下 |
| Marker3D3 [2] | (40, 0, 43) | 右上 |
| Marker3D4 [3] | (10, 0, 43) | 左上 |

地图 50×50，四角各内缩 7~10 米，形成对称十字分布。

### 第 31-81 行：资源点

以第 31 行为例：

```gdscript
[node name="ResourceA" parent="Resources" index="0" instance=ExtResource("3_3gxbc")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 7.53, -0.000007, 15.57)
```

- `instance=ExtResource("3_3gxbc")` — 实例化蓝水晶模板
- `parent="Resources"` — 挂在 Resources 容器下
- `transform` — 单位矩阵（无旋转），仅位移

有些资源点覆写了额外属性：

```gdscript
resource_a = 5
```

这直接覆写 `ResourceA.gd` 脚本的导出变量 `resource_a`，表示该水晶矿量为 5 个单位（而非默认值）。

#### 完整资源分布

| 资源类型 | 数量 | 分布 |
|---|---|---|
| ResourceA（蓝水晶） | 12 个 | 每片区域 3 个（4 区域 × 3 = 12），其中每区 1 个大矿（矿量 5） |
| ResourceB（红水晶） | 4 个 | 每片区域 1 个（4 区域 × 1 = 4） |

每片区域 = 1 个玩家的出生区域，对称分布。

### 最终节点树结构

```
Map (Node3D)  ← 来自 Map.tscn
├── Geometry
│   ├── BlackBackgroundFixingAntiAliasingBug  ← 超大黑色平面，防止边缘抗锯齿闪线
│   └── Terrain  ← 54×54 平面 + terrain.material
├── SpawnPoints
│   ├── Marker3D  [0] → (10, 0, 7)
│   ├── Marker3D2 [1] → (40, 0, 7)
│   ├── Marker3D3 [2] → (40, 0, 43)
│   └── Marker3D4 [3] → (10, 0, 43)
├── Resources
│   ├── ResourceA  [0-11]  → 12 个蓝水晶
│   └── ResourceB  [12-15] → 4 个红水晶
└── Decorations  ← 空（本图无装饰物）
```

---

## 五、Big Arena 地图对比

| 属性 | Plain & Simple | Big Arena |
|---|---|---|
| 文件 | `PlainAndSimple.tscn` | `BigArena.tscn` |
| 玩家数 | 4 | 8 |
| 逻辑尺寸 | 50×50 | 100×100 |
| Mesh 尺寸 | 54×54 | 104×104 |
| Mesh 中心偏移 | (25, 0, 25) | (50, 0, 50) |
| 出生点数 | 4 | 8 |
| 装饰物 | 无 | RockLargeA |
| 资源分布 | 4 区对称 | 8 区对称 |

---

## 六、如何新建一张地图

### 步骤 1：创建 `.tscn` 场景文件

在 `source/match/maps/` 下新建 `.tscn`，写入：

```gdscript
[gd_scene load_steps=N format=3 uid="uid://<auto>"]
```

### 步骤 2：引用依赖

```
[ext_resource ... path="res://source/match/Map.tscn" id="1_map"]
[ext_resource ... path="res://.../terrain.material.tres" id="2_mat"]
[ext_resource ... path="res://.../ResourceA.tscn" id="3_resA"]
[ext_resource ... path="res://.../ResourceB.tscn" id="4_resB"]
```

### 步骤 3：定义地形 PlaneMesh

```gdscript
[sub_resource type="PlaneMesh" id="PlaneMesh_xxx"]
resource_local_to_scene = true
material = ExtResource("2_mat")
size = Vector2(实际尺寸+4, 实际尺寸+4)  # +4 = EXTRA_MARGIN*2
center_offset = Vector3(尺寸.x/2, 0, 尺寸.y/2)
```

### 步骤 4：实例化 Map 并覆写

```gdscript
[node name="Map" instance=ExtResource("1_map")]
size = Vector2(尺寸.x, 尺寸.y)  # Map.gd 的 @export var

[node name="Terrain" parent="Geometry" index="1"]
mesh = SubResource("PlaneMesh_xxx")
```

### 步骤 5：放置出生点和资源

每个 `Marker3D` 一个出生点（数量=玩家数），每个资源点实例化 `ResourceA` 或 `ResourceB`：

```gdscript
[node name="Marker3D" type="Marker3D" parent="SpawnPoints" index="0"]
transform = Transform3D(...)  # 设置位置

[node name="ResourceA" parent="Resources" index="0" instance=ExtResource("3_resA")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, x, 0, z)
```

### 步骤 6：注册到 Constants

在 [MatchConstants.gd](../source/match/MatchConstants.gd) 的 `MAPS` 字典中添加：

```gdscript
const MAPS = {
    # ... 已有地图 ...
    "res://source/match/maps/你的地图.tscn":
    {
        "name": "地图显示名称",
        "players": 玩家数,
        "size": Vector2i(宽, 高),
    },
}
```

注册后地图自动出现在 Play 菜单中（按玩家数排序）。

---

## 七、相关文件索引

| 文件 | 职责 |
|---|---|
| [source/match/Map.tscn](../source/match/Map.tscn) | 所有地图的父模板（Geometry / SpawnPoints / Resources / Decorations 容器） |
| [source/match/Map.gd](../source/match/Map.gd) | 地图脚本（size 属性 + 出界检测） |
| [source/match/maps/PlainAndSimple.tscn](../source/match/maps/PlainAndSimple.tscn) | 4 人 50×50 地图 |
| [source/match/maps/BigArena.tscn](../source/match/maps/BigArena.tscn) | 8 人 100×100 地图 |
| [source/match/MatchConstants.gd](../source/match/MatchConstants.gd) | `MAPS` 字典（地图注册）+ 导航/单位/资源常量 |
| [source/match/Match.gd](../source/match/Match.gd) | 对局主控：加载地图、创建玩家、初始化迷雾/导航/相机 |
| [source/main-menu/Play.gd](../source/main-menu/Play.gd) | 菜单中的地图选择和玩家配置 |
| [source/match/handlers/MatchEndHandler.gd](../source/match/handlers/MatchEndHandler.gd) | 胜利/失败判定 |
| [source/match/players/human/UnitActionsController.gd](../source/match/players/human/UnitActionsController.gd) | 右键命令分发（移动/攻击/采集/建造/跟随） |
| [source/match/players/human/AttackModeController.gd](../source/match/players/human/AttackModeController.gd) | A 键攻击模式 |
| [source/match/players/human/StructurePlacementHandler.gd](../source/match/players/human/StructurePlacementHandler.gd) | 建筑蓝图放置 + 验证 |
| [source/match/FogOfWar.gd](../source/match/FogOfWar.gd) | 战争迷雾 |
| [source/match/hud/UnitMenus.gd](../source/match/hud/UnitMenus.gd) | 底部单位菜单切换 |
