# mini-mh：Warcraft III 1.27a 最小 MH 案例

本项目在地图 JASS 中实现内存桥、特效句柄转换和内部透明度函数调用。地图只需加载本目录的 8 个源码文件，无需加载 MemHackAPI 的 `03-APITypecast.j` 或其他上游源码。虚拟机转换与启动方式参考 [MemHackAPI](https://github.com/UnryzeC/MemHackAPI)。

## 当前验证结果

用户在本机 1.27a 游戏中反馈的运行日志确认：

- 可以编译并进入地图。
- 内存桥初始化、版本特征检查和 Game.dll 头检查通过。
- 句柄表检查和调用缓冲区分配通过。
- 透明度调用使用的 36 字节机器码逐项写入并回读一致。
- 原生入口重定向、调用返回和原始指针恢复通过，恢复值回读一致。

这些结果证明本次测试中的内存写入及调用流程正常。尚未回读精灵的透明度字段，也未完成可见效果对比，因此不能把“调用返回成功”解释成“透明度视觉效果已验证”。以上是特定环境的用户实测结果，不是所有 1.27a 安装的兼容性保证。

## 地图主脚本如何导入

把下面 8 行放入地图工具链支持 `#include` 的自定义脚本区域。路径为本案例所在机器的完整路径；项目搬动后需对应修改。

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

使用支持 vJASS 的 JassHelper。关闭编译优化，保留 `//! nocjass`、`//! endnocjass` 和 `//# +nosemanticerror` 指令。不要同时导入原版 MH 或旧探针中的同名声明。

仅 include 不会执行初始化。编译通过也不代表虚拟机内存桥可以运行；必须查看游戏中的阶段输出。编译后的脚本是排查依据，尤其要检查同名变量、声明顺序和启动函数布局。

## 完整地图调用示例

在地图初始化完成后的触发器动作中调用。下面函数名只是示例；替换现有触发器内容时保留编辑器生成的函数名。局部变量必须位于执行语句之前。

```jass
function Demo_MiniMH takes nothing returns nothing
    local effect e = null
    if not MiniMH_Init() then
        return
    endif
    set e = AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", 0, 0)
    call MiniMH_DemoSetAlpha(e)
    call TriggerSleepAction(5.0)
    call DestroyEffect(e)
    set e = null
endfunction
```

`e` 必须先声明并创建。特效创建在地图坐标 `(0, 0)`，需要把镜头移到该位置。此模型用于演示调用，动画可能在 5 秒前结束；观察透明度时建议用持续显示的模型，在相同镜头、光照和模型下对比 `255` 与 `128`。

也可以在初始化成功后直接调用 `MiniMH_SetEffectAlpha(e, alpha)`；参数范围为 `0..255`，`MiniMH_DemoSetAlpha(e)` 固定使用 `128`。布尔返回值表示检查、机器码写入、调用及入口恢复是否报告成功，不包含透明度字段的独立回读。

## 输出与排查

`MiniMH_Debug` 默认是 `true`。设置 `set MiniMH_Debug = false` 可以关闭库的诊断输出；失败原因仍保存在 `MiniMH_LastError`。

| 输出 | 含义 |
| --- | --- |
| 开始初始化内存桥 | 地图已进入公开初始化入口 |
| 启动锚点、启动后数组地址 | 诊断代码转换和启动步骤；非零本身不能证明内存桥正确 |
| 内存桥检查通过 | 版本特征和模块头检查通过 |
| 4 字节写入回读一致 | 指定地址写入后读取值与期望值相同；日志数值是十进制有符号整数 |
| 透明度机器码共 36 字节已逐项写入并回读一致 | 缓冲区中 9 个四字节值写入验证通过 |
| 透明度机器码调用已返回 | 控制流从重定向调用返回 |
| 原生入口已恢复并回读一致 | 原始原生函数指针恢复并验证通过 |

虚函数表为 `0` 时应先查启动桥和生成脚本，不能修改版本常量绕过。版本特征不匹配时记录实际值，停止使用版本偏移。当前 1.27a 预期特征值为 `0x277890`（十进制 `2586768`）。

## 文件职责

| 文件 | 职责 |
| --- | --- |
| `core.j` | 就绪状态、错误信息和中文输出开关 |
| `version_127a.j` | 1.27a 特征值、模块偏移及对象偏移 |
| `typecast.j` | 代码、整数、布尔和数组表示转换，以及字节码填充 |
| `memory.j` | 特殊启动入口、版本/模块头检查、四字节读写与回读 |
| `handle_table.j` | 从特效句柄定位内部对象 |
| `calls.j` | 可执行缓冲区、机器码调用、原生指针保存与恢复 |
| `effect_alpha.j` | 参数检查、对象与精灵定位、透明度调用 |
| `entry.j` | 按顺序初始化并提供固定透明度示例 |

`tests/smoke.j` 是额外的手动测试入口，不属于必须 include 的 8 个文件。`tests/compile_smoke.ps1` 是可选编译脚本，不会随地图自动执行，路径配置需要匹配本机环境。

## 必须保留的布局

- 类型转换的写入函数位于同名局部声明之前，转换读取函数位于声明之后。不要改动 `Code/l__Code`、`Array/l__Array`、`bytecode/l__bytecode` 等名称和顺序。
- `MiniMH_InitBytecode` 必须位于 `MiniMH_BytecodeCastDeclaration` 之前；之前在 `memory.j` 直接写字节码数组的布局曾导致仅加载脚本就无法进图。
- 公开内存初始化通过非空 force 从 `MiniMH_BootstrapMemory + 0x8` 进入，跳过局部数组声明。正常直接调用启动函数曾读出虚函数表 `0`。
- `MiniMH_NewGlobal` 的第二条 `return 0x2700` 及启动常量属于字节码构造，不能按普通死代码删除。
- `MiniMH_RawRead` 的生成代码 `+0x34` 用于提取变量标识，因此不要随意在函数体中插入日志或改变其结构。

## 当前限制

公开读写接口检查就绪状态、低地址和四字节对齐，但不检查完整页映射或对象生命周期。调用缓冲区当前没有释放接口，透明度调用没有重入保护；不要在调用过程中嵌套调用本案例 API。尚未覆盖多版本、失败注入、地图退出清理及透明度视觉对比。

## 技术原理

整个流程是：`JASS 表示转换 → 建立内存桥 → 识别 Game.dll → 句柄转内部对象 → 调用透明度函数 → 恢复原生入口`。

### 1. 从 JASS 值取得地址

`typecast.j` 利用 JASS 虚拟机的变量表示和同名声明布局，将 `code`、整数、布尔及数组的内部表示按另一种类型读取。例如，`MiniMH_CodeAddress` 取得函数的字节码地址，`MiniMH_AddressCode` 将整数地址重新解释为可交给 `ForForce` 执行的代码值。这些操作依赖编译后布局，因此名称、声明顺序及关闭优化都是实现的一部分。

### 2. 将数组访问变成进程内存访问

初始化包装函数通过 `ForForce` 从 `MiniMH_BootstrapMemory + 0x8` 进入，跳过局部数组声明，再利用启动锚点和伪数组头构造 JASS 字节码。该字节码把 `l__Memory` 的数组表示改为所需的内存映射，使 `l__Memory[address / 4]` 可以访问指定地址的四字节内容；数组索引除以 4，是因为一个整数占四字节。

启动过程中读取数组虚函数表，用它与首项地址的差值检查版本特征，再减去 1.27a 的固定 RVA 得到 Game.dll 基址。随后回读模块的 DOS 头，检查映射结果。这里的启动字节码与后续执行透明度调用的 x86 机器码是两种不同的代码。

### 3. 从特效句柄找到精灵

JASS 的 `effect` 是句柄，不能直接当作内部对象指针。`handle_table.j` 从 Game.dll 的游戏状态沿指针找到句柄表，再根据 `GetHandleId(e)`、表项步长和编号基准定位内部对象。`effect_alpha.j` 从对象的固定偏移读取精灵指针，作为透明度函数的目标。

### 4. 借原生函数入口执行 x86 调用

`calls.j` 在 JASS 原生函数表中找到 `MergeUnits` 和 `IgnoredUnits` 的函数指针槽。初始化时暂时把 `MergeUnits` 指向 Game.dll 导入表中的 `VirtualAlloc`，借其四个参数分配 64 字节可执行内存，并恢复原始入口；返回值通过布尔位模式转换取得分配地址。

设置透明度时，在缓冲区写入 36 字节 x86 机器码：保存 ESI，将精灵指针放入 ECX、透明度放入 EDX、附加参数 0 压栈，再调用 `Game.dll 基址 + MINIMH_SET_ALPHA_RVA`，恢复 ESI 并返回。随后暂时把 `IgnoredUnits` 的入口指向缓冲区，通过 JASS 原生调用进入机器码，返回后恢复原指针。

机器码写入和入口恢复都通过回读检查。它们能确认相应内存值与期望一致，但不能独立证明精灵透明度字段已经变化；这一点仍需字段回读或游戏中的可见效果对比确认。
