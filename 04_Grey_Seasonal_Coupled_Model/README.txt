第五章灰色季节耦合预测模型 MATLAB 独立程序包
================================================

一、程序文件
------------
gslssvr.m   灰色季节最小二乘支持向量回归模型
gstlssvr.m  灰色季节趋势最小二乘支持向量回归模型
nofghw.m    灰色分数阶 Holt-Winters 模型
ncghw.m     新息优先灰色 Holt-Winters 模型

每个模型文件均可直接调用，模型内部包含其自身的参数估计、
递推预测、还原和局部计算函数。不依赖 gseason.fit，也不依赖
统一模型入口。

辅助文件：
error_metrics.m  误差指标（MAE、MSE、RMSE、SSE、MAPE、MPE、R²）
compare_models.m 四个模型的直接调用与比较
plot_results.m   拟合、预测和残差绘图
examples/        调用示例
tests/           基本接口测试

二、调用方式
------------
addpath(genpath('D:\Chapter5_Models_Standalone'));

x = [120 135 150 145 130 148 166 160 ...
     142 158 178 170 150 168 190 182 ...
     160 177 198 190 170 188 210 202]';

h = 4;      % 预测步数
s = 4;      % 季节周期

r1 = gslssvr(x,h,s);
r2 = gstlssvr(x,h,s);
r3 = nofghw(x,h,s);
r4 = ncghw(x,h,s);

查看预测：
r1.forecast
查看拟合：
r1.fitted
查看误差：
error_metrics(x,r1.fitted)

比较四个模型：
[comparison,results] = compare_models(x,h,s);
disp(comparison);

绘图：
plot_results(x,r3);

三、统一输出字段
----------------
result.model       模型名称
result.fitted      样本内拟合值（初始化区间可能为 NaN）
result.forecast    样本外预测值
result.residuals   残差
result.parameters  模型参数
result.metrics     误差指标
其他字段保存模型系数、状态变量和参数寻优信息。

四、与书稿模型的对应关系及实现说明
----------------------------------
1. GSLSSVR：按书稿式(5.1.1)采用一阶 AGO、前一期累加值作为
   LSSVR输入、季节虚拟变量作为季节项；采用线性核或高斯/RBF核。
   参数通过带季节虚拟变量的 LS-SVR 线性方程组估计。
2. GSTLSSVR：按书稿式(5.2.1)在 GSLSSVR 结构中加入时间趋势项。
3. NOFGHW：按书稿式(5.3.1)-(5.3.6)实现分数阶周期 AGO、逆算子、
   Holt-Winters 水平/趋势/季节递推和多步预测。
4. NCGHW：按书稿定义6及式(5.4.1)-(5.4.4)实现新息优先周期 AGO、
   逆算子、Holt-Winters递推及多步预测。

五、参数优化说明
----------------
GSLSSVR/GSTLSSVR 默认使用最后块验证选择核函数、惩罚参数和 RBF
核宽度；可通过 opts.optimize=false 关闭，并手动设置 opts.kernel、
opts.penalty、opts.sigma。

NOFGHW/NCGHW 的四个参数默认自动优化。代码内置不依赖工具箱的
有限差分 L-BFGS 两循环递推和 Armijo 回溯线搜索，以便 MATLAB
基础环境可以运行。书稿说明采用 LBFGS/strong-Wolfe；当前代码
采用 Armijo 回溯作为可运行实现，若需逐项复现 strong-Wolfe，
可进一步替换线搜索部分。

六、重要核验说明
----------------
代码按书稿可识别的模型结构和公式图像编写。书稿中的部分公式
以 WMF/OLE 嵌入对象保存，个别符号或公式编号在文字抽取时不完整。
特别是 NCGHW 式(5.4.1)的水平更新项在公式图像中为
(S_{t-1}-b_{t-1})，而预测式(5.4.3)为(S_t+j*b_t)；本程序保留
公式图像中的符号。请在最终论文数值实验前再与原始公式核对。

本程序包已进行文件与代码结构检查；当前执行环境未提供 MATLAB
或 Octave，因此未声称 MATLAB 运行测试已经通过。请在本地 MATLAB
运行 tests/test_chapter5.m 进行实际测试。
