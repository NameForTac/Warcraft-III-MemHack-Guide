# mini-mh：自己的最小 MH 教学项目

这是与上级教程配套的项目骨架。它只描述一个 API：`MiniMH_SetEffectAlpha(effect, 128)`。

项目默认处于“安全失败”状态：版本常量、内存桥和对象偏移都是占位值，因此不能直接修改游戏进程。只有在你完成 1.27a 离线测试、记录证据并替换占位实现后，才可以继续研究运行时行为。

## 文件

| 文件 | 作用 |
| --- | --- |
| `entry.j` | 初始化顺序、状态和对外入口 |
| `version_127a.j` | 只保存 1.27a 的版本常量和地址占位 |
| `memory.j` | 统一的读写接口；当前默认返回失败 |
| `handle_table.j` | `effect handle -> 对象地址` 的查找流程 |
| `effect_alpha.j` | 唯一的上层 API |
| `notes/evidence.md` | 每个地址、偏移和调用约定的证据表 |

## 接入阅读顺序

```text
entry.j
  -> version_127a.j
  -> memory.j
  -> handle_table.j
  -> effect_alpha.j
```

这里的 `.j` 文件是教学源码，不是已经完成的注入器，也不包含上游项目的内存访问技巧或机器码。
