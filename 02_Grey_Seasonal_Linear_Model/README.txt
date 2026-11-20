第三章九个灰色季节模型 MATLAB 独立调用程序包
================================================

一、程序结构
------------
本版本每个模型均为完整独立的 .m 文件，模型内部包含其所需的参数估计、
响应递推、逆变换、拟合和预测计算，不调用 gseason.fit，也不依赖 +gseason
文件夹或其他模型文件。

九个独立模型：
dgsm.m       DGSM(1,1)
cdgsm.m      CDGSM(1,1)
dgstm.m      DGSTM(1,1)
dpdgsm.m     DPDGSM(1,1)
dpdgstm.m    DPDGSTM(1,1)
sdgm.m       SDGM(1,1)
ddvgsm.m     DDVGSM(1,1)
nipdgstm.m   NIPDGSTM(1,1)
nipddgsm.m   NIPDDGSM(1,1)

误差分析工具：
error_metrics.m   MAE、MSE、RMSE、SSE、MAPE、MPE、sMAPE、R²
error_analysis.m  残差、相对误差、统计量和诊断图
compare_models.m  九个模型批量运行及误差比较
plot_results.m    拟合值、实际值和残差图

二、安装与调用
--------------
解压后，在 MATLAB 命令窗口进入该文件夹，或添加路径：
addpath('D:\Chapter3_Models_Standalone');

x = [120 135 150 145 130 148 166 160 ...
     142 158 178 170 150 168 190 182]';
h = 4;  % 预测步数
s = 4;  % 季节周期

% 直接调用单个模型，不需要 gseason.fit：
r1 = dgsm(x,h,s);
r2 = cdgsm(x,h,s);
r3 = dgstm(x,h,s);

% DPD 模型可指定局部窗口；NIP 模型可指定新息权重：
opts = struct('q',3,'lambda',0.9);
r4 = dpdgsm(x,h,s,opts);
r5 = nipdgstm(x,h,s,opts);

每个模型结果字段：
result.fitted       样本内拟合值
result.forecast     未来预测值
result.theta        估计参数
result.metrics      样本内误差指标
result.residual     生成序列回归残差

三、误差检测
------------
r = dgsm(x,4,4);
M = error_metrics(x,r.fitted);
disp(M);
A = error_analysis(x,r.fitted,true); % 输出逐期误差表并绘图
disp(A.detail);

四、九模型比较
--------------
opts = struct('q',3,'lambda',0.9);
[comparison,results] = compare_models(x,4,4,opts);
disp(comparison);

五、重要说明
------------
(1) 本版解决的是程序调用结构：九个模型文件均可直接调用，且不依赖
    gseason.fit。误差分析工具是独立文件。
(2) 当前程序的模型结构沿用前一版本已说明的离散回归约定。书稿中部分
    公式为嵌入式 OLE/WMF 对象，尚需对照公式原图逐项核验，特别是 CDGSM
    周期累加/逆变换、双季节项及各模型回归项。不能把本版本视为已完成
    全部论文公式验证的最终学术复现。
(3) opts.optimize 不在本独立版本中实现；DPD 模型可直接设置 opts.q，
    NIP 模型可直接设置 opts.lambda。
(4) MAPE/MPE 对实际值为零的观测自动跳过。
(5) 当前构建环境未安装 MATLAB/Octave，已做文件结构和依赖检查，未能
    实际执行 MATLAB 运行测试。请在本地 MATLAB 中运行单模型和比较程序。
