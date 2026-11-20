# GreyDataGeneration（灰色数据生成 MATLAB 工具箱）

本项目将《灰色季节模型的构建及其应用研究》第二章涉及的数据生成方法整理为 MATLAB 程序包，供教学、复现实验和后续模型开发使用。

## 当前包含的算子

| 书稿术语 | MATLAB 函数 | 功能 |
|---|---|---|
| 一阶累加生成（1-AGO） | `gdag.ago` | 传统累加生成 |
| 一阶累减生成（1-IAGO） | `gdag.iago` | 传统累加的逆运算 |
| 新息优先累加（1-NIPAGO） | `gdag.nipago` | 通过参数 `lambda` 调整新旧信息权重 |
| 新息优先累减（1-NIPIAGO） | `gdag.nipiago` | 新息优先累加的逆运算 |
| r 阶分数阶累加 | `gdag.fractionalAGO` | 通过实数阶数 `r` 调节累加强度 |
| r 阶分数阶累减 | `gdag.fractionalIAGO` | 分数阶累加的逆运算 |
| 动态局部累加（DPAGO） | `gdag.dpago` | 采用长度为 `q` 的滚动局部窗口累加 |
| 动态局部累减（DPIAGO） | `gdag.dpiago` | 动态局部累加的逆运算 |
| 局部窗口候选评价 | `gdag.selectLocalWindow` | 以透明、可替换的评价准则辅助选择 `q` |

所有函数均接受行向量或列向量，返回列向量。输入须为有限实数向量；按照书稿定义，四类累加生成算子主要面向非负序列。

## 重要的公式核对说明

书稿第二章的公式（2.1.1）—（2.1.8）在当前 Word 文件中以嵌入公式对象呈现，普通文本提取无法完整读取公式本体。根据可读取的定义文字及章节说明，本程序包采用以下明确实现约定：

1. **NIPAGO**：`y(k) = lambda*y(k-1) + x(k)`，其中 `y(1)=x(1)`；因此 `lambda=1` 时退化为传统 AGO，`0<lambda<1` 时较新的观测相对权重较高。这与书稿关于“新信息优先”和 `lambda=1` 退化为传统累加的文字说明一致。
2. **分数阶 AGO**：采用标准广义二项式卷积系数 `w(j+1)=w(j)*(r+j-1)/j`。`r=1` 时退化为传统 AGO；逆算子使用阶数 `-r` 的对应卷积。
3. **DPAGO**：采用长度为 `q` 的滚动局部累加窗口，即 `y(k)=sum(x(i))`，求和范围为 `max(1,k-q+1):k`。逆算子据此递推还原原序列。
4. **局部窗口选择**：书稿说明 `q` 采用数据驱动思想确定，但当前可读取文本未呈现具体目标函数或完整选取算法。因此 `selectLocalWindow` 提供的是可解释的“单调性比例”候选评价示例，不应被误称为书稿中已经证明或采用的唯一最优选择准则。

**学术使用前请核对**：请将以上实现约定与 Word 书稿中公式（2.1.3）、（2.1.5）—（2.1.8）的可视化公式逐项比对。若公式本体与上述约定不同，应以书稿最终确认的数学定义为准，再修改相应 `.m` 文件。程序包不将无法从可读文本确认的细节伪装成已核实结论。

## 环境要求

- MATLAB R2016b 或更新版本（使用包文件夹 `+gdag`）。
- 本工具箱核心函数仅使用 MATLAB 基础语言，不依赖 Statistics and Machine Learning Toolbox 或 Optimization Toolbox。

## 快速开始

```matlab
% 1. 将本项目解压到本地
% 2. 在 MATLAB 当前文件夹中定位到 GreyDataGeneration 文件夹
% 3. 运行：
addpath(genpath(pwd));

x = [12 15 18 16 21 24];

% 传统 AGO 与还原
x1 = gdag.ago(x);
x0 = gdag.iago(x1);

% 新息优先 AGO（lambda 必须位于 (0,1]）
lambda = 0.85;
xn = gdag.nipago(x, lambda);
x_back = gdag.nipiago(xn, lambda);

% 分数阶 AGO（r=0.7）
r = 0.7;
xf = gdag.fractionalAGO(x, r);
x_back_f = gdag.fractionalIAGO(xf, r);

% 动态局部 AGO（窗口长度 q=3）
q = 3;
xd = gdag.dpago(x, q);
x_back_d = gdag.dpiago(xd, q);

% 检查误差
fprintf('AGO还原最大误差：%.3g\\n', max(abs(x(:)-x0)));
fprintf('NIPAGO还原最大误差：%.3g\\n', max(abs(x(:)-x_back)));
fprintf('分数阶还原最大误差：%.3g\\n', max(abs(x(:)-x_back_f)));
fprintf('DPAGO还原最大误差：%.3g\\n', max(abs(x(:)-x_back_d)));
```

## 目录结构

```text
GreyDataGeneration/
├── +gdag/
│   ├── ago.m
│   ├── iago.m
│   ├── nipago.m
│   ├── nipiago.m
│   ├── fractionalAGO.m
│   ├── fractionalIAGO.m
│   ├── dpago.m
│   ├── dpiago.m
│   ├── selectLocalWindow.m
│   └── validateInput.m
├── examples/
│   └── demo_all_operators.m
├── tests/
│   └── test_all_operators.m
├── LICENSE
├── CITATION.cff
└── README.md
```

## 运行测试

在 MATLAB 中进入项目根目录，运行：

```matlab
addpath(genpath(pwd));
results = runtests('tests');
table(results)
```

所有逆算子测试均采用“先生成、再还原”的数值检验。浮点数误差应处于数值计算容差范围内。

## 研究使用建议

- 复现实证时，记录原始序列、算子类型、阶数/权重/窗口长度、软件版本和数据来源。
- 对 `lambda`、`r`、`q` 等超参数进行训练集内选择，避免使用测试集信息造成数据泄漏。
- 将算子生成结果与原始序列同时保存，便于追溯和重复实验。
- 如将程序用于论文或书稿，请引用本项目并注明具体版本或 Git commit。
