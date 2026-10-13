# 从零设计自己的最小 MH

前一个案例调用了 MemHackAPI；本篇讨论更基础的问题：**如果完全不使用 MemHackAPI，自己从头设计一个只支持 Warcraft III 1.27a、只提供一个功能的最小 MH，应该怎样拆？**

这里的“最小”指学习架构最小，不是一个可以直接复制到游戏里的现成外挂。它只作为旧版 Warcraft III 离线研究的教学骨架。真正运行需要你对自己拥有的 1.27a 安装、地图和测试进程做版本验证；不要在联网对战或他人进程上使用。

## 先限定目标

我们只实现一个假想功能：

```text
地图层请求：把一个 effect 的 alpha 设置为 128
```

为了完成这件事，最小 MH 仍然需要五块能力：

```text
JASS 入口
  -> 能把请求传进 MH 的桥
  -> 1.27a 版本检查
  -> handle 转对象地址
  -> 读取对象的 sprite 并修改 alpha
```

如果目标换成“改单位模型”“创建 Frame”或“拦截伤害”，后面的对象定位、调用约定和恢复逻辑都会不同。不要从一个功能的偏移推导出整个游戏的结构。

## 和 MemHackAPI 的关系

本篇的模块名称和调用链参考 **UnryzeC 编写的 [MemHackAPI](https://github.com/UnryzeC/MemHackAPI)**，但示例代码由本仓库独立编写，不复制其实现。上游仓库未声明开源许可证，因此这里只讲设计和验证方法，并链接到对应源码供阅读。

## 最小项目目录

```text
mini-mh/
  README.md                 # 目标、版本、已验证能力
  version_127a.j            # 只登记 1.27a 的常量和地址
  memory.j                  # 受控的读写抽象
  handle_table.j            # handle -> 对象地址
  effect_alpha.j            # 唯一一个上层 API
  entry.j                    # 初始化顺序和失败处理
  notes/
    evidence.md              # 每个偏移、函数、调用约定的证据
```

这个目录比 MemHackAPI 小很多，但依赖关系不能省略。最小项目不是把所有代码写进一个函数，而是只保留完成一个功能所需的边界。

## 第一步：先写“不能猜”的版本门控

```jass
globals
    boolean MiniMH_Ready = false
    string MiniMH_Version = ""
endglobals

function MiniMH_CheckVersion takes nothing returns boolean
    // 教学占位：这里必须使用你在 1.27a 测试环境中确认的版本特征。
    set MiniMH_Version = "1.27a"
    return MiniMH_Version == "1.27a"
endfunction
```

这段代码本身没有识别真实进程版本，只表达接口。真实实现必须回答：

1. 读取哪一个稳定特征？
2. 如何区分 1.27a 与相近版本？
3. 识别失败时是否完全拒绝初始化？
4. 版本识别证据保存在哪里？

MemHackAPI 的版本分支可以在 [`04-APIMemory.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/04-APIMemory.j) 和初始化文件中阅读。不要把 `PatchVersion = "1.27a"` 这种字符串赋值当成真正的检测。

## 第二步：把内存访问藏在最小接口后面

```jass
function MiniMH_ReadDword takes integer address returns integer
    // 教学接口：真实版本需要由你验证 JASS 到进程内存的访问桥。
    return 0
endfunction

function MiniMH_WriteDword takes integer address, integer value returns boolean
    // 教学接口：真实版本还要记录旧值，以便失败或退出时恢复。
    return false
endfunction

function MiniMH_ReadFloat takes integer address returns real
    return 0.0
endfunction

function MiniMH_WriteFloat takes integer address, real value returns boolean
    return false
endfunction
```

这里故意返回占位值。因为 `ReadRealMemory`、`WriteRealMemory` 的实现不是普通 JASS 能力，而是整个 MH 最特殊、最依赖运行环境的部分。你在自己的研究中要单独验证：

```text
JASS 参数
  -> 特殊执行桥
  -> 目标地址
  -> 读取/写入结果
```

不要一开始就写 `SetEffectAlpha`。先用一个已知测试地址验证读、写、恢复三个动作，再允许上层对象代码调用它。MemHackAPI 对应的阅读入口是 [`04-APIMemory.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/04-APIMemory.j)。

## 第三步：只做一个 handle 查找器

上层拿到的是 JASS `effect`，底层需要对象地址。最小版本只需要一条明确的转换路径：

```jass
function MiniMH_ConvertEffect takes effect e returns integer
    local integer handleId = GetHandleId(e)
    local integer gameState = 0
    local integer tableRoot = 0
    local integer entryAddress = 0

    if e == null or handleId == 0 then
        return 0
    endif

    // 以下地址和偏移只是教学变量，不能直接用于游戏。
    set gameState = MiniMH_ReadDword(MiniMH_GameStateAddress)
    set tableRoot = MiniMH_ReadDword(gameState + MiniMH_HandleTableOffset)
    set entryAddress = tableRoot + handleId * MiniMH_HandleEntryStride
    return MiniMH_ReadDword(entryAddress)
endfunction
```

这个函数要验证的不是变量名，而是每一次解引用：

```text
GetHandleId(e)
  -> GameState 基址
  -> handle 表根节点
  -> handleId * 条目步长
  -> 对象地址
```

MemHackAPI 的对应源码是 [`13-APIMemoryGameData.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/13-APIMemoryGameData.j)。源码能证明它执行了哪些读取和偏移运算，但不能单凭变量名证明中间节点的 C++ 类名。你的 `notes/evidence.md` 应记录每个值来自哪次 1.27a 观察。

## 第四步：只实现一个 alpha API

```jass
function MiniMH_SetEffectAlpha takes effect e, integer alpha returns boolean
    local integer pObject = MiniMH_ConvertEffect(e)
    local integer pSprite = 0

    if pObject == 0 then
        return false
    endif

    if alpha < 0 or alpha > 255 then
        return false
    endif

    set pSprite = MiniMH_ReadDword(pObject + MiniMH_ObjectSpriteOffset)
    if pSprite == 0 then
        return false
    endif

    // 教学占位：你必须先确认 1.27a 的 alpha 写入路径。
    return MiniMH_WriteDword(pSprite + MiniMH_AlphaOffset, alpha)
endfunction
```

这个 API 的职责只有四件事：

1. 检查 handle 是否有效。
2. 检查 alpha 范围。
3. 找到对象对应的 sprite。
4. 写入已验证的 alpha 位置，返回成功或失败。

不要在这个函数里混入版本检测、计时器、日志、模型替换和 hook。职责越小，越容易判断失败发生在哪一层。

MemHackAPI 的同类上层函数是 `SetEffectAlpha`，位于 [`70-MemHackEffectAPI.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/70-MemHackEffectAPI.j)；通用对象层可阅读 [`52-MemHackCObjectAPI.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/52-MemHackCObjectAPI.j)。本篇把它们拆成了可验证的教学接口，没有填入上游偏移。

## 第五步：规定初始化顺序

```jass
function MiniMH_Init takes nothing returns boolean
    if not MiniMH_CheckVersion() then
        return false
    endif

    if not MiniMH_InitMemoryBridge() then
        return false
    endif

    if not MiniMH_InitHandleTable() then
        return false
    endif

    set MiniMH_Ready = true
    return true
endfunction
```

依赖顺序是：

```text
版本检查
  -> 内存访问桥
  -> handle 表定位
  -> Effect 转换
  -> SetEffectAlpha
```

任何一步失败，都不能继续把 `MiniMH_Ready` 设为 `true`。MemHackAPI 的完整初始化入口 [`85-InitMemoryHack.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/85-InitMemoryHack.j) 采用的也是先基础设施、再对象 API、最后上层 API 的思路。

## 第六步：地图层只看到一个稳定 API

```jass
function Demo_SetAlpha takes effect e returns nothing
    if not MiniMH_Ready then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "MiniMH is not ready")
        return
    endif

    if not MiniMH_SetEffectAlpha(e, 128) then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "MiniMH_SetEffectAlpha failed")
    endif
endfunction
```

地图作者不应该知道 `pSprite + MiniMH_AlphaOffset`。这正是“扩展 API”和“内部实现”之间的边界。未来换成 1.27b 时，理论上只需替换版本表和底层实现；如果地图脚本也依赖偏移，维护会变得非常困难。

## 你真正需要从零验证的清单

```text
[ ] 1.27a 的版本特征
[ ] JASS 到内存读写桥确实可用
[ ] 目标地址在读写前后属于同一进程和同一对象
[ ] GetHandleId 到对象地址的每一级解引用
[ ] effect 对象的 sprite 指针位置
[ ] alpha 字段或内部 SetAlpha 函数的调用约定
[ ] 写入前的旧值记录
[ ] 写入失败时的恢复路径
[ ] 地图退出时的清理
[ ] 未识别版本时完全拒绝调用上层 API
```

其中“alpha 字段”与“SetAlpha 内部函数”是两条不同路线：直接写字段可能需要额外刷新；调用内部函数需要确认 `this` 指针、参数顺序和返回约定。应先观察现有 API 的实现，再决定哪条路线可验证，不能因为字段偏移看起来简单就默认它安全。

## 推荐的实现顺序

1. 写版本检查，只允许 1.27a。
2. 写只读内存测试，并记录结果，不做修改。
3. 写单地址的可恢复读写测试。
4. 验证一个 effect handle 的对象地址转换。
5. 只读出 sprite 指针和目标值。
6. 增加 alpha 写入和立即恢复。
7. 最后才把它包装成 `MiniMH_SetEffectAlpha`。
8. 通过地图脚本调用，并在每一步失败时显示明确错误。

这个顺序比“先复制完整 MemHackAPI，再删到能跑”为好理解，因为每一层的输入、输出和证据都能单独检查。完成 alpha 后，再考虑 scale、position 或 model；每新增一个 API，都重复同一条链路。

## 新增 API 时的模板

```text
1. 明确地图层签名：SetEffectScale(effect e, real scale)
2. 找到现有对象转换：复用 ConvertEffect
3. 找到底层操作：字段写入还是内部函数调用
4. 为 1.27a 单独记录地址、偏移和调用约定
5. 加范围检查和零地址检查
6. 加失败返回值
7. 加恢复/清理说明
8. 写一个只验证该 API 的小地图测试
```

如果新 API 需要新的内部函数地址，才新增版本表条目；如果只是复用已验证的 `ConvertEffect` 和对象层函数，就不要重复登记同一地址。每一项都应在 `notes/evidence.md` 中写出来源和未解决的问题。

## 这篇教程没有替你填什么

- 没有提供可直接用于第三方进程的注入器或补丁器。
- 没有把未经独立验证的 1.27a 地址、偏移或机器码写成“正确答案”。
- 没有把上游 MemHackAPI 的实现复制进本仓库。
- 没有声称只靠源码就能恢复完整 Warcraft III C++ 类布局。

这些限制是为了让学习过程保持可验证：你应先证明一条读取或调用链，再把它纳入自己的 API，而不是从一个能运行的黑盒开始猜。

## 下一步练习

完成 alpha 的证据记录后，可以按难度扩展：

1. `SetEffectScale`：复用对象转换，新增一个浮点写入。
2. `SetEffectPosition`：检查多个坐标字段和位置刷新逻辑。
3. `SetEffectModel`：研究字符串在游戏内存中的表示和生命周期。
4. `SetEffectAlpha` 的失败恢复：保存旧值，测试地图退出路径。

每个练习都应该新增自己的小测试和证据记录，不要一次实现整个对象系统。
