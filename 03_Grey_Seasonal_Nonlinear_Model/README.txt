第四章灰色季节模型 MATLAB 独立程序包
======================================

模型文件（每个模型均可独立调用）：
1. sngbm.m      SNGBM(1,1)
2. swbgm.m      SWBGM(1,1)
3. dgstpm.m     DGSTPM(1,1)
4. nipsgmp.m    NIPSGMP(1,1)
5. nipswbgm.m   NIPSWBGM(1,1)
6. ddvgstm.m    DDVGSTM(1,1)

调用示例：
  x = [82 91 106 98 88 97 114 104 95 103 121 110 101 111 129 118]';
  r = sngbm(x,4,4);
  r.fitted       % 样本内拟合值
  r.forecast     % 未来4期预测值
  r.parameters   % 参数估计值

统一输入：模型名(原始正数序列, 季节周期, 预测步长)
统一输出：结构体，含 fitted、forecast、allPred、parameters、seasonalIndex 等字段。
要求：基础 MATLAB（使用 fminsearch、fzero、table、xline 等函数；旧版本 MATLAB 可能需替换 string/xline）。

辅助文件：
- error_metrics.m：MAE、RMSE、MAPE、sMAPE
- compare_models.m：六模型样本内误差与预测均值比较
- plot_results.m：观测、拟合和预测图
- examples/demo_chapter4.m：运行示例
- tests/test_chapter4.m：基础冒烟测试

公式依据与实现说明：
- 按用户最新书稿第四章六个模型构建。
- SNGBM：季节指数调整 + NGBM/Bernoulli 方程；lambda 用 fminsearch 优化，a、b 用 OLS。
- SWBGM：季节指数调整 + Weibull-Bernoulli 离散关系；u、v 用 fminsearch 优化，a、b 用 OLS，递推预测采用隐式数值求解。
- DGSTPM：按书稿离散关系 s1(t+1)=eta*s1(t)+xi*t^gamma+sigma_season；gamma 数值优化，其余参数 OLS。
- NIPSGMP：季节调整 + 新息优先累加 y(k)=lambda*y(k-1)+x(k)，并按幂模型离散关系估计；lambda、gamma 数值优化。
- NIPSWBGM：季节调整 + 新息优先累加，并按书稿中含 u*k^(u-1)、双形状参数 u/v 的离散方程拟合。
- DDVGSTM：按书稿双季节虚拟变量及时间幂项的离散关系建模；gamma 数值优化，其余参数 OLS。

重要限制：
1. 本包是可运行的研究实现版本，不等同于对书稿全部公式逐符号复现。书稿部分时间响应函数/公式以 WMF 数学图片嵌入；代码对非线性递推部分采用数值求解，参数优化采用 fminsearch，并非逐字复刻书稿中的文化算法（CA）或角蜥优化算法（HLOA）。
2. SWBGM/NIPSWBGM 中的非线性隐式响应通过数值根求解；应使用书稿原始数据对参数、边界与预测结果进一步校准。
3. 目前未在 MATLAB/Octave 中执行测试。本包提供 tests/test_chapter4.m 冒烟测试脚本；请在 MATLAB 中运行后确认数值稳定性。
4. 输入序列需为有限正数，长度至少 max(6, s+2)。s 为季节周期（季度=4、月度=12），h 为预测步长。
