# mini-mh：1.27a 最小 MH 源码

地图源码仅依赖本目录文件。`typecast.j` 在本地实现 code/integer、boolean/integer、数组地址转换；参考 MemHackAPI 的 VM 技巧，不需要 include 外部 APITypecast 文件。不要同时加载旧探针或原版 MH 库。

## include 清单

```jass
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/core.j"
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/version_127a.j"
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/typecast.j"
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/memory.j"
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/handle_table.j"
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/calls.j"
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/effect_alpha.j"
#include "D:/MemHack研究/Warcraft-III-MemHack-Guide/示例/02-自己的最小MH/mini-mh/entry.j"
```

`#include` 使用用户地图工具链的预处理器。关闭 JassHelper 优化。`typecast.j` 的 setter 位于类型碰撞声明之前，转换读取函数位于声明之后；保留该顺序以及 `Code/l__Code` 等全局和局部名称。类型转换指令 `//# +nosemanticerror` 也需要保留。

## 文件职责

- `typecast.j`：本地转换实现，无 PatchVersion 或 APIAllTypecast 依赖。
- `memory.j`：引导字节码、版本检查、内存读写。
- `calls.j`：调用缓冲区和 native 指针保存/恢复，boolean 转换复用本地 typecast。
- `handle_table.j`：effect handle 查找。
- `effect_alpha.j`：alpha API。
- `entry.j`：MiniMH_Init、MiniMH_DemoSetAlpha。

## 验证状态

本次完成的是自包含源码接入。完整初始化与 SetEffectAlpha 尚未在游戏中验证。由用户负责地图编译、进图和运行测试，反馈实际错误后继续修正。之前只加载转换探针并进图成功，不代表转换执行、内存桥或 alpha 功能已成功。
