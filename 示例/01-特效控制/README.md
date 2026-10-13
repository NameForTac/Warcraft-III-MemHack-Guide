# 极小案例：创建并控制一个特效

这个练习以 **Warcraft III 1.27a** 为目标环境，让地图在可玩区域中心创建一个 Holy Bolt 特效，把透明度设为半透明、缩放设为 1.5 倍，并在三秒后销毁。它用一段短脚本串起普通 JASS、MemHackAPI 扩展 API、handle 转内部对象以及清理流程。

源码文件：[EffectDemo.j](EffectDemo.j)

## 运行前提

- 需要一个已接入 MemHackAPI 的 Warcraft III 1.27a 地图。上游 README 推荐 1.26a，并说明不支持 Reforged；上游源码虽有 1.27a 分支，但地址、对象布局和调用方式仍要按你的实际构建验证。
- `AddSpecialEffect`、`CreateTimer`、`TimerStart`、`DestroyEffect`、`DestroyTimer`、`GetRectCenterX/Y` 是 Warcraft III/常见地图脚本环境提供的函数。
- `SetEffectAlpha` 和 `SetEffectScale` 是 MemHackAPI 扩展函数。单独把 `EffectDemo.j` 放进普通地图，不会自动获得这两个函数。
- MemHackAPI 必须在 `Demo_Start` 执行前完成初始化。上游 `85-InitMemoryHack.j` 的 `Your Stuff` 区域位于模块初始化之后，可在整合到上游教学副本时从那里调用 `Demo_Start`。不要把调用放在 MemHack 初始化之前。
- 本例有意只支持一个同时存在的特效。它用于学习生命周期，不是多实例系统，也没有在本机 Warcraft III 环境中实测。

## 完整源码

```jass
globals
    effect Demo_Effect = null
    timer Demo_Timer = null
endglobals

function Demo_DestroyEffect takes nothing returns nothing
    if Demo_Effect != null then
        call DestroyEffect(Demo_Effect)
        set Demo_Effect = null
    endif

    if Demo_Timer != null then
        call DestroyTimer(Demo_Timer)
        set Demo_Timer = null
    endif
endfunction

function Demo_Start takes nothing returns nothing
    local real x = GetRectCenterX(bj_mapInitialPlayableArea)
    local real y = GetRectCenterY(bj_mapInitialPlayableArea)

    call Demo_DestroyEffect()

    set Demo_Effect = AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", x, y)
    if Demo_Effect == null then
        return
    endif

    call SetEffectAlpha(Demo_Effect, 128)
    call SetEffectScale(Demo_Effect, 1.50)

    set Demo_Timer = CreateTimer()
    call TimerStart(Demo_Timer, 3.00, false, function Demo_DestroyEffect)
endfunction
```

## 怎么把它接进地图

1. 将 `EffectDemo.j` 的函数和全局变量放入地图脚本；如果地图通过 JassHelper 管理源码，就按该地图的导入方式加入文件。
2. 确认地图已经包含并按顺序初始化 MemHackAPI，且目标游戏版本受该份地址表支持。
3. 在 MemHackAPI 完成初始化之后调用一次 `Demo_Start()`。在上游示例的 `Init_MemoryHack` 中，这意味着放在全部 `Init_...` 调用之后。
4. 进入地图后观察可玩区域中心：特效应以半透明、放大后的样子出现，三秒后被销毁。

这里只说明接入位置，不包含上游项目的编译器、完整地图资源或初始化技巧的复制品。请按原项目的工具链和授权条件自行准备测试地图。

## 逐段读源码

### 1. 保存两个 handle

```jass
globals
    effect Demo_Effect = null
    timer Demo_Timer = null
endglobals
```

- `globals` 到 `endglobals` 声明全局变量。函数结束后，变量仍可被计时器回调读取。
- `Demo_Effect` 保存 `AddSpecialEffect` 返回的 JASS effect handle。这个 handle 是脚本层引用，不是内部 C++ 对象地址。
- `Demo_Timer` 保存计时器 handle，让清理函数可以销毁它。
- `null` 表示当前没有关联对象。销毁后把变量设回 `null`，避免后续代码误把旧 handle 当作仍有效对象。

为什么用全局变量？`TimerStart` 的回调签名是 `takes nothing`，它不会自动接收 `Demo_Start` 中的局部变量。全局变量是这个单实例示例最短的状态传递办法。真实多实例系统通常会用 hashtable、结构库或其他方式按计时器保存各自状态。

### 2. 集中负责销毁

```jass
function Demo_DestroyEffect takes nothing returns nothing
    if Demo_Effect != null then
        call DestroyEffect(Demo_Effect)
        set Demo_Effect = null
    endif
```

1. `Demo_DestroyEffect` 是计时器回调，因此没有参数，也不返回值。
2. 先检查 effect handle，避免对空引用执行销毁。
3. `DestroyEffect` 是游戏提供的生命周期函数，结束这个特效。
4. 置空全局变量，表达“当前没有存活的示例特效”。

```jass
    if Demo_Timer != null then
        call DestroyTimer(Demo_Timer)
        set Demo_Timer = null
    endif
endfunction
```

计时器触发后也要释放计时器并清空变量。把两种资源的清理放在同一处，重跑示例时也可以调用同一个函数，不必维护两套不同的清理逻辑。

### 3. 选择坐标并先清理旧状态

```jass
function Demo_Start takes nothing returns nothing
    local real x = GetRectCenterX(bj_mapInitialPlayableArea)
    local real y = GetRectCenterY(bj_mapInitialPlayableArea)

    call Demo_DestroyEffect()
```

- `local real` 声明本次函数调用临时使用的实数坐标。
- `bj_mapInitialPlayableArea` 是常见地图脚本环境中的初始可玩区域；取其中心，避免把特效固定在地图坐标原点。
- 开始新一轮前先清理旧状态，所以多次调用 `Demo_Start` 仍只保留一个本例特效。

### 4. 创建 effect handle

```jass
    set Demo_Effect = AddSpecialEffect(
        "Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl",
        x,
        y
    )
```

真实 `.j` 文件中这是一行；此处换行只是为了讲解参数。`AddSpecialEffect` 根据模型路径和坐标创建特效，并返回一个 effect handle。`set` 将返回值存进全局变量，供后面的 API 与销毁函数继续使用。模型资源路径要以地图中可用的资源为准。

```jass
    if Demo_Effect == null then
        return
    endif
```

创建失败就提前结束，不再把空 handle 交给 MemHackAPI，也不创建一个没有用途的计时器。

### 5. 调整透明度和大小

```jass
    call SetEffectAlpha(Demo_Effect, 128)
    call SetEffectScale(Demo_Effect, 1.50)
```

- Alpha 参数范围在上游实现中检查为 `0` 到 `255`；`128` 大约是中间透明度。具体模型的视觉效果也受材质影响。
- 缩放 `1.50` 表示使用该对象缩放值的 1.5 倍。
- 两个函数都不是普通地图原生函数，而是 MemHackAPI 提供的扩展。
- 代码来源：[70-MemHackEffectAPI.j](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/70-MemHackEffectAPI.j)。其中 `SetEffectAlpha` 和 `SetEffectScale` 都先调用 `ConvertHandle(e)`，再把内部对象地址交给通用的 `SetObject...` 函数。

### 6. 延时清理

```jass
    set Demo_Timer = CreateTimer()
    call TimerStart(Demo_Timer, 3.00, false, function Demo_DestroyEffect)
endfunction
```

创建一个计时器，设置三秒后单次触发。`false` 表示不是周期计时；回调运行 `Demo_DestroyEffect`，因此 effect 和 timer 都会被回收。

## 从地图函数追到上游实现

```text
Demo_Start
  -> AddSpecialEffect 创建原生 effect handle
  -> SetEffectAlpha / SetEffectScale（MemHackAPI 易用层）
  -> ConvertHandle(effect)（JASS handle 转内部对象地址）
  -> SetObjectAlpha / SetObjectScale（CObject 通用层）
  -> 获取对象的 sprite 并调用游戏内部方法或写入其属性
  -> 三秒后 TimerStart 回调 Demo_DestroyEffect
  -> DestroyEffect / DestroyTimer 释放两个 handle
```

可以直接对照这些上游文件：

- [`70-MemHackEffectAPI.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/70-MemHackEffectAPI.j)：`SetEffectAlpha` 与 `SetEffectScale` 将 effect handle 转换后转发。
- [`13-APIMemoryGameData.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/13-APIMemoryGameData.j)：`ConvertHandle` / `ConvertHandleId` 的句柄到内部对象查找过程。
- [`52-MemHackCObjectAPI.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/52-MemHackCObjectAPI.j)：通用对象层。源码注释说明 `SetObjectAlpha` 针对 Effect；缩放实现通过对象 sprite 的实数字段进行访问。
- [`85-InitMemoryHack.j`](https://github.com/UnryzeC/MemHackAPI/blob/main/MapFiles/trigger/1-MemoryHack%20API/85-InitMemoryHack.j)：初始化列表中先初始化 `CSpriteUber`，后初始化 Effect API；注释也说明 Effect API 依赖前者。

`ConvertHandle` 的具体查表公式和字段语义有版本依赖。源码能说明它执行了哪些读取和偏移运算，但单凭源码不能证明这些内部位置在所有游戏版本都具有同一含义。完整讨论见[《源码结构与调用链》](../../源码结构与调用链.md)的结构解析部分。

## 练习

1. 把 alpha 改为 `64`，记录透明度的变化；再试 `255`。
2. 把 scale 改为 `0.75`，比较模型大小。
3. 把延迟改成 `1.00`，确认资源清理时间变化。
4. 暂时删掉 `Demo_DestroyEffect()` 中的 `set Demo_Effect = null`。思考为什么销毁后仍应清空脚本变量。
5. 沿上游源码继续追：`SetEffectScale` 调了谁？哪个函数读取 sprite 地址？初始化列表为何先初始化 CSpriteUber 再初始化 Effect API？

## 来源

本案例代码由本仓库独立编写。MemHackAPI 的 API 名称、行为描述和调用链分析参考 [UnryzeC/MemHackAPI](https://github.com/UnryzeC/MemHackAPI)。上游仓库未声明开源许可证；此处提供源码位置和解释，不复制上游函数实现。案例仅用于旧版 Warcraft III 地图开发历史学习。
