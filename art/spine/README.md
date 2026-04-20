# Spine资源目录

本目录用于存放正式战斗动画使用的 `Spine` 源资产或 `Spine` 导出帧。

当前接入方式：

- 运行时未直接接入 Spine 插件
- 主攻击动画改为读取 `Spine` 导出帧目录
- `scripts/data/branch_catalog.gd` 会读取各分支 `manifest.json`
- `scripts/actors/player.gd` 会按阶段播放 `weapon / trail / impact` 三层序列帧

目录约定：

```text
art/spine/
  branch_attacks/
	tank/
	  manifest.json
	  weapon/
	  trail/
	  impact/
	debuff/
	  manifest.json
	  weapon/
	  trail/
	  impact/
	building/
	  manifest.json
	  weapon/
	  trail/
	  impact/
```

替换规则：

- 后续美术提供真实 Spine 导出帧时，保持 `manifest.json` 和目录结构不变，直接替换对应 png 即可
- `hit_frame_progress` 用于同步命中时机
- `spine_event_track` 用于标记命中事件语义，便于后续接真正的 Spine runtime
