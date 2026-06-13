# MATLAB 全量测试稳定化任务

## 背景

架构重排后，MATLAB 注册链路已经恢复并加强：

- `AlgorithmRegistryMetadataTest.m` 通过；
- `registerAllAlgorithms()` 可注册 34 个算法；
- `apiGetMetadata('algorithms')` 可从注册表返回完整算法目录；
- GA 的 package 路径解析和算子父类构造函数加载问题已修复。

但 MATLAB 全量测试仍未绿色，当前迁移后结果为：

```text
Total: 227
Passed: 85
Failed: 142
Incomplete: 140
```

该任务独立于架构重排 PR 处理，避免在目录迁移中混入大规模算法数学逻辑修复。

## 失败族群

### 1. 公共接口与测试契约不一致

大量测试直接读取 `algorithm.config`，但 `BaseAlgorithm.config` 当前为 protected 属性。

处理方向：

- 评估是否增加只读 public accessor，例如 `getConfig()`；
- 或调整测试只依赖公开 metadata/config API；
- 统一单目标与多目标算法的配置可观测契约。

### 2. MATLAB 数值类型不兼容

典型错误包括：

- `int64` 与非标量 double 混合计算；
- `int64` 传入 `exp`；
- `int64` 参与非正整数幂运算。

处理方向：

- 将迭代计数、归一化比例、指数/幂运算输入显式转为 double；
- 保留计数语义，但避免 MATLAB 数值 API 类型冲突；
- 每类算法用一个最小测试验证运行链路。

### 3. 问题维度与边界定义不一致

部分测试构造的 `dim` 与 `lb`/`ub` 向量长度不一致，触发 `BaseAlgorithm:InvalidProblem`。

处理方向：

- 明确 scalar bounds 是否应按 `dim` 自动扩展；
- 如果不扩展，则测试必须提供长度匹配的向量边界；
- 将该规则写入架构或代码风格文档。

### 4. 多目标算法接口期望未统一

`MOAlgorithmTest` 失败集中在：

- default/custom config 可观测性；
- dominance/archive helper 的访问方式；
- Pareto result shape；
- boundary handling。

处理方向：

- 先稳定 `MOBaseAlgorithm` 的公共契约；
- 再逐个修复 `MOALO`、`MODA`、`MOGOA`、`MOGWO`、`MSSA`、`NSGAIII`。

### 5. 遗留占位测试与当前注册目录不一致

`NewAlgorithmsTest` 涉及 PSO、DE、HHO、ABC、CS、FA、DBO、SMA、BWO、ASO、NRBO、CPO、HO 等算法族。

处理方向：

- 明确这些算法是否进入当前 34 算法正式注册目录；
- 若是占位测试，应临时 quarantine 或标注跳过原因；
- 若要纳入正式目录，应补齐 `PARAM_SCHEMA`、`metadata()`、`register()` 与后端 catalog 映射。

## 验收标准

- `matlab/tests/unit/AlgorithmRegistryMetadataTest.m` 保持通过；
- `matlab/tests/run_all_tests.m` 全绿，或遗留占位测试被显式跳过并附理由；
- 单目标与多目标算法的 public config/metadata 契约写入文档；
- 不在无针对性测试的情况下改写算法数学逻辑。

## 建议执行顺序

1. 先修 `BaseAlgorithm` / `MOBaseAlgorithm` 公共契约与测试访问方式。
2. 再修 int64/double 数值类型族群。
3. 再修问题维度与边界扩展规则。
4. 最后处理多目标算法和遗留占位测试。

## 复现命令

```powershell
& "D:\software\MATLAB 2024b\bin\matlab.exe" -batch "cd('D:/代码整理/metaheuristic-optimization-algorithm'); addpath(genpath('matlab')); run('matlab/tests/run_all_tests.m');"
```

```powershell
& "D:\software\MATLAB 2024b\bin\matlab.exe" -batch "cd('D:/代码整理/metaheuristic-optimization-algorithm'); addpath(genpath('matlab')); results = runtests('matlab/tests/unit/AlgorithmRegistryMetadataTest.m'); assertSuccess(results);"
```
