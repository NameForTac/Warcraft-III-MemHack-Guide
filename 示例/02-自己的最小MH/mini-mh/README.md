# mini-mh：自己的最小 MH 教学项目

这是与上级教程配套的项目骨架。它只描述一个 API：`MiniMH_SetEffectAlpha(effect, 128)`。

项目默认处于“安全失败”状态：版本常量、内存桥和对象偏移都是占位值，因此不能直接修改游戏进程。只有在你完成 1.27a 离线测试、记录证据并替换占位实现后，才可以继续研究运行时行为。

## 文件

| 文件 | 作用 |
| --- | --- |
| `core.j` | 跨模块共享的初始化状态 |
| `entry.j` | 初始化顺序和对外入口 |
| `version_127a.j` | 只保存 1.27a 的版本常量和地址占位 |
| `memory.j` | 统一的读写接口；当前默认返回失败 |
| `handle_table.j` | `effect handle -> 对象地址` 的查找流程 |
| `effect_alpha.j` | 唯一的上层 API |
| `notes/evidence.md` | 每个地址、偏移和调用约定的证据表 |

## 接入阅读顺序

```text
entry.j
  -> core.j
  -> version_127a.j
  -> memory.j
  -> handle_table.j
  -> effect_alpha.j
```

这里的 `.j` 文件是教学源码，不是已经完成的注入器，也不包含上游项目的内存访问技巧或机器码。

## 地图主脚本如何导入

本项目使用 JassHelper 的 vJASS `library` 声明，因此要在**编译阶段**导入源码。`#include` 是 C/C++ 预处理器语法，不是这里使用的 JASS 指令。JassHelper 常用的导入指令是 `//! import`。

假设地图源码文件和 `mini-mh` 目录的相对位置如下：

```text
地图工程/
├─ war3map.j
└─ src/
   └─ mini-mh/
      ├─ core.j
      ├─ version_127a.j
      ├─ memory.j
      ├─ handle_table.j
      ├─ effect_alpha.j
      └─ entry.j
```

在地图主脚本 `war3map.j` 的顶部加入这些指令：

```jass
//! import "src/mini-mh/core.j"
//! import "src/mini-mh/version_127a.j"
//! import "src/mini-mh/memory.j"
//! import "src/mini-mh/handle_table.j"
//! import "src/mini-mh/effect_alpha.j"
//! import "src/mini-mh/entry.j"
```

JassHelper 手册把 `//! import "文件.j"` 定义为外部脚本导入：编译时把该文件内容放进地图脚本，作用近似于在此处粘贴源码。相对路径从地图所在目录或 JassHelper 配置的查找目录解析，因此要让编译器能找到 `src/mini-mh/`；路径按你的实际目录调整。这个指令不是把模型、图标等普通地图资源加入导入列表。各文件中的 `library ... requires ...` 声明负责表达库依赖，JassHelper 会据此处理库顺序，不需要靠上面几行 `//! import` 的先后顺序表达依赖。

参考：[JassHelper 手册：Import external script files](https://warraft.github.io/JassHelper-manual/import-external-script-files.html)。

### 在地图初始化时调用

把下面的代码放进地图的初始化触发器，确保所有依赖的库都已编译进地图：

```jass
function Trig_MiniMH_Init_Actions takes nothing returns nothing
    if not MiniMH_Init() then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "MiniMH initialization failed")
    endif
endfunction
```

在 GUI 触发器编辑器中，可以新建一个“地图初始化”事件的触发器，并添加“自定义脚本”动作 `call MiniMH_Init()`。需要显示初始化失败原因时，使用上面的 JASS 函数形式。确保初始化动作先于任何调用 `MiniMH_SetEffectAlpha` 的地图逻辑；最简单的做法是在同一个地图初始化触发器中先调用 `MiniMH_Init`，成功后再启动依赖它的逻辑。当前骨架中的版本检查和内存桥返回失败，所以这里会按设计报告初始化失败。

## 编译与放入地图

1. 保留 `mini-mh` 目录结构，把它放在地图目录下，或放进 JassHelper 配置的查找目录。
2. 在地图主 `.j` 脚本顶部添加导入指令，并按地图正在使用的 JassHelper 版本编译。
3. 若编译器报告找不到文件，核对相对导入路径能否从地图目录或已配置的查找目录解析；若报告找不到库或函数，检查 `library requires` 声明和导入文件是否都参与本次编译。
4. 编译成功后，将生成的脚本产物按当前地图工具链写入地图；不要把 `.j` 源码当作模型等普通资源导入后就期待游戏自动编译。
5. 在离线测试地图的初始化阶段调用 `MiniMH_Init()`，确认未完成的骨架失败关闭。

纯 GUI 触发器编辑器不会自动理解这些 vJASS `library` 声明。需要能运行 JassHelper 的地图工具链，或把源文件合并/编译为该工具链接受的 JASS 输出。不同编辑器对源码目录和构建命令的配置不同；本项目不假定某个特定编辑器安装路径。
