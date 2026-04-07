# testRou

基于项目内多 Agent 约束生成并持续迭代的 Godot 4 俯视角 2D 肉鸽原型。

当前状态已经从 `v0.1` 闭环原型推进到 `v0.2`：

- 暗黑像素风背景与像素角色/敌人/投射物素材已接入
- 命中、受击、击杀、升级、精英与 Boss 均有反馈与音效
- 加入精英怪、Boss 与局外成长
- 刷怪节奏改成阶段式推进，敌人组合差异更明显
- 升级池权重与数值做了第二轮校正

## 当前内容

- 1 个可玩角色
- 3 类基础敌人 + 精英变体 + 1 个 Boss
- 自动攻击主武器
- 可解锁的脉冲副武器
- 10 个升级项
- 4 个局外成长项
- 经验掉落与升级三选一
- 10 分钟生存目标
- HUD、暂停、结算、局外成长购买与重开

## 操作

- `WASD` / 方向键：移动
- `Esc` / `P`：暂停
- `R`：结算后重开

## 素材说明

本项目中的暗黑像素风背景、角色贴图与音效均为本地脚本生成，不依赖外部手工导入素材。

- 背景与像素贴图生成脚本：[generate_pixel_assets.gd](D:\javaweb\godot\rouGeDemo\test-rou\scripts\tools\generate_pixel_assets.gd)
- 音效生成脚本：[generate_audio_assets.py](D:\javaweb\godot\rouGeDemo\test-rou\scripts\tools\generate_audio_assets.py)
- 背景资源目录：[art/backgrounds](D:\javaweb\godot\rouGeDemo\test-rou\art\backgrounds)
- 贴图资源目录：[art/sprites](D:\javaweb\godot\rouGeDemo\test-rou\art\sprites)
- 音效资源目录：[audio/sfx](D:\javaweb\godot\rouGeDemo\test-rou\audio\sfx)

## 核心循环

1. 玩家进入战斗并自动攻击最近敌人
2. 击败敌人后掉落经验
3. 升级时暂停，并从 3 个随机成长项中选择 1 个
4. 随时间进入不同战斗阶段，面对混编敌群、精英和 Boss
5. 结算时获得暗核碎片，可购买局外成长
6. 活满 10 分钟获胜，或死亡后结算重开

## 目录结构

```text
res://
  scenes/
  scripts/
  resources/
  art/
  audio/
  version-notes/
```

## 当前仍需继续优化

- 还没有加入专门的 Boss 技能表现和独立关卡目标
- UI 视觉已经从纯占位升级，但还没有做完整主题化排版
- 局外成长目前是轻量版，仍可继续扩展成更完整的长期养成
