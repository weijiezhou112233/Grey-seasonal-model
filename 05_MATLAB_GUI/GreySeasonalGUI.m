function GreySeasonalGUI
% GREYSEASONALGUI
% Graphical interface for the standalone grey seasonal models in this repo.
%
% Compatible with MATLAB R2018b and later.
% Start from the repository root:
%   addpath(genpath(pwd));
%   GreySeasonalGUI
%
% Model interfaces used here (verified from the repository source files):
%   Chapter 3 linear:     f(x, horizon, period, opts)
%   Chapter 4 nonlinear:  f(x, period, horizon)
%   Chapter 5 coupled:    f(x, horizon, period, opts)
%
% Each model remains an independent .m file. This GUI is only the front end.

guiFile = mfilename('fullpath');
guiDir = fileparts(guiFile);
repoRoot = fileparts(guiDir);
addModelPaths(repoRoot);

% category, display name, function name, chapter/interface
catalog = {
 '灰色季节线性模型','DGSM(1,1) - 离散灰色季节模型','dgsm',3
 '灰色季节线性模型','CDGSM(1,1) - 耦合离散灰色季节模型','cdgsm',3
 '灰色季节线性模型','DGSTM(1,1) - 灰色季节趋势模型','dgstm',3
 '灰色季节线性模型','DPDGSM(1,1)','dpdgsm',3
 '灰色季节线性模型','DPDGSTM(1,1)','dpdgstm',3
 '灰色季节线性模型','SDGM(1,1)','sdgm',3
 '灰色季节线性模型','DDVGSM(1,1)','ddvgsm',3
 '灰色季节线性模型','NIPDGSTM(1,1)','nipdgstm',3
 '灰色季节线性模型','NIPDDGSM(1,1)','nipddgsm',3
 '灰色季节非线性模型','SNGBM(1,1)','sngbm',4
 '灰色季节非线性模型','SWBGM(1,1)','swbgm',4
 '灰色季节非线性模型','DGSTPM(1,1)','dgstpm',4
 '灰色季节非线性模型','NIPSGMP(1,1)','nipsgmp',4
 '灰色季节非线性模型','NIPSWBGM(1,1)','nipswbgm',4
 '灰色季节非线性模型','DDVGSTM(1,1)','ddvgstm',4
 '灰色季节耦合模型','GSLSSVR','gslssvr',5
 '灰色季节耦合模型','GSTLSSVR','gstlssvr',5
 '灰色季节耦合模型','NOFGHW','nofghw',5
 '灰色季节耦合模型','NCGHW','ncghw',5
};

% Only show model entries whose .m files are actually present.
present = false(size(catalog,1),1);
for k=1:size(catalog,1)
    present(k) = exist(catalog{k,3},'file')==2;
end
missingModels = catalog(~present,3);
catalog = catalog(present,:);
if isempty(catalog)
    error('未找到灰色季节模型文件。请从仓库根目录运行，并执行 addpath(genpath(pwd))。');
end

fig = uifigure('Name','Grey Seasonal Forecasting System | 灰色季节模型预测系统',...
    'Position',[60 45 1450 880]);
fig.Color = [0.96 0.97 0.98];

rootGrid = uigridlayout(fig,[3 2]);
rootGrid.RowHeight = {48,'1.05x','1.35x'};
rootGrid.ColumnWidth = {'1.05x','0.95x'};
rootGrid.Padding = [12 12 12 12];
rootGrid.RowSpacing = 9;
rootGrid.ColumnSpacing = 9;

header = uilabel(rootGrid,'Text','灰色季节模型预测与分析平台',...
    'FontSize',21,'FontWeight','bold','HorizontalAlignment','center');
header.Layout.Row=1; header.Layout.Column=[1 2];

% ----------------------- Data input panel -----------------------
dataPanel = uipanel(rootGrid,'Title','数据导入与编辑');
dataPanel.Layout.Row=2; dataPanel.Layout.Column=1;
dataGrid = uigridlayout(dataPanel,[3 1]);
dataGrid.RowHeight = {34,'1x',30};
dataGrid.Padding = [8 8 8 8];

dataButtons = uigridlayout(dataGrid,[1 4]);
dataButtons.ColumnWidth = {'1x','1x','1x','1x'};
uibutton(dataButtons,'Text','导入 Excel/CSV','ButtonPushedFcn',@importData);
uibutton(dataButtons,'Text','示例数据','ButtonPushedFcn',@loadDemo);
uibutton(dataButtons,'Text','增加数据行','ButtonPushedFcn',@appendRows);
uibutton(dataButtons,'Text','清空数据','ButtonPushedFcn',@clearData);

initialData = cell(30,5);
dataTable = uitable(dataGrid,'Data',initialData,...
    'ColumnName',{'时间','序列1','序列2','序列3','序列4'},...
    'ColumnEditable',true(1,5),...
    'ColumnWidth',{105,95,95,95,95});
uilabel(dataGrid,'Text','第一列为时间标签，其余列为数值序列。可直接粘贴 Excel 区域。',...
    'FontColor',[0.25 0.25 0.25]);

% ----------------------- Model/settings panel -------------------
settingPanel = uipanel(rootGrid,'Title','序列特征识别与模型设置');
settingPanel.Layout.Row=2; settingPanel.Layout.Column=2;
settingGrid = uigridlayout(settingPanel,[10 2]);
settingGrid.RowHeight = {28,28,28,28,28,28,28,'1x',34,34};
settingGrid.ColumnWidth = {118,'1x'};
settingGrid.Padding = [10 8 10 8];

uilabel(settingGrid,'Text','数值序列');
seriesDrop = uidropdown(settingGrid,'Items',{'序列1'},'Value','序列1');
uilabel(settingGrid,'Text','模型类别');
categoryDrop = uidropdown(settingGrid,...
    'Items',{'灰色季节线性模型','灰色季节非线性模型','灰色季节耦合模型'},...
    'Value','灰色季节线性模型','ValueChangedFcn',@categoryChanged);
uilabel(settingGrid,'Text','具体模型');
modelDrop = uidropdown(settingGrid,'Items',{},'ValueChangedFcn',@modelChanged);
uilabel(settingGrid,'Text','季节周期');
periodField = uieditfield(settingGrid,'numeric','Value',4,'Limits',[1 Inf],...
    'RoundFractionalValues','on');
uilabel(settingGrid,'Text','预测步长');
horizonField = uieditfield(settingGrid,'numeric','Value',4,'Limits',[1 Inf],...
    'RoundFractionalValues','on');
uilabel(settingGrid,'Text','验证样本数');
holdoutField = uieditfield(settingGrid,'numeric','Value',4,'Limits',[0 Inf],...
    'RoundFractionalValues','on');
uilabel(settingGrid,'Text','模型参数');
parameterLabel = uilabel(settingGrid,'Text','默认参数；可在高级设置中调整');
uilabel(settingGrid,'Text','特征分析');
featureLabel = uilabel(settingGrid,'Text','导入数据后点击“分析序列特征”。');
uibutton(settingGrid,'Text','分析序列特征','ButtonPushedFcn',@analyzeSeries);
uibutton(settingGrid,'Text','推荐基准模型','ButtonPushedFcn',@recommendModel);

% ----------------------- Result panel ----------------------------
resultPanel = uipanel(rootGrid,'Title','预测结果与误差分析');
resultPanel.Layout.Row=3; resultPanel.Layout.Column=[1 2];
resultGrid = uigridlayout(resultPanel,[3 2]);
resultGrid.RowHeight = {'1.15x',38,'1x'};
resultGrid.ColumnWidth = {'1.2x','0.8x'};
resultGrid.Padding = [8 8 8 8];

plotAxes = uiaxes(resultGrid);
plotAxes.Layout.Row=1; plotAxes.Layout.Column=1;
plotAxes.XGrid='on'; plotAxes.YGrid='on';
title(plotAxes,'原始序列、拟合值与预测值');
xlabel(plotAxes,'时间'); ylabel(plotAxes,'数值');

metricTable = uitable(resultGrid,'Data',cell(8,2),...
    'ColumnName',{'评价指标','结果'},'ColumnWidth',{150,130});
metricTable.Layout.Row=1; metricTable.Layout.Column=2;

actionGrid = uigridlayout(resultGrid,[1 5]);
actionGrid.Layout.Row=2; actionGrid.Layout.Column=[1 2];
actionGrid.ColumnWidth = {'1.2x','1x','1x','1x','1x'};
uibutton(actionGrid,'Text','运行预测','FontWeight','bold',...
    'BackgroundColor',[0.15 0.43 0.72],'FontColor',[1 1 1],...
    'ButtonPushedFcn',@runForecast);
uibutton(actionGrid,'Text','高级参数','ButtonPushedFcn',@advancedOptions);
uibutton(actionGrid,'Text','保存 Excel','ButtonPushedFcn',@exportExcel);
uibutton(actionGrid,'Text','保存预测图','ButtonPushedFcn',@exportPlot);
uibutton(actionGrid,'Text','清除结果','ButtonPushedFcn',@clearResults);

resultTable = uitable(resultGrid,'Data',cell(0,5),...
    'ColumnName',{'时间','实际值','拟合/预测值','APE(%)','数据类型'});
resultTable.Layout.Row=3; resultTable.Layout.Column=[1 2];

% ----------------------- Runtime state ---------------------------
lastResult = [];
modelOpts = struct('q',3,'lambda',0.9,'optimize',true);
refreshModelList();

% ======================= Nested callbacks ========================

    function importData(~,~)
        [file,path] = uigetfile({'*.xlsx;*.xls;*.csv','Excel / CSV 文件'},...
            '选择时间序列数据');
        if isequal(file,0), return; end
        try
            T = readtable(fullfile(path,file));
            if width(T)<2
                error('数据文件至少应包含一列时间和一列数值序列。');
            end
            names = cellstr(string(T.Properties.VariableNames));
            C = cell(height(T),width(T));
            for rr=1:height(T)
                C{rr,1} = char(string(T{rr,1}));
                for cc=2:width(T)
                    value = T{rr,cc};
                    if iscell(value), value=value{1}; end
                    if isnumeric(value) && isscalar(value)
                        C{rr,cc}=value;
                    else
                        C{rr,cc}=str2double(string(value));
                    end
                end
            end
            dataTable.Data=C;
            dataTable.ColumnName=names;
            dataTable.ColumnEditable=true(1,width(T));
            seriesDrop.Items=names(2:end);
            seriesDrop.Value=names{2};
            clearResults();
        catch ME
            uialert(fig,ME.message,'导入失败','Icon','error');
        end
    end

    function loadDemo(~,~)
        values = [120 135 150 145;130 148 166 160;142 158 178 170;...
            150 168 190 182;160 177 198 190;170 188 210 202;...
            180 198 220 214;190 210 232 224]';
        C=cell(size(values,2),size(values,1)+1);
        for rr=1:size(values,2)
            C{rr,1}=sprintf('t%d',rr);
            for cc=1:size(values,1), C{rr,cc+1}=values(cc,rr); end
        end
        dataTable.Data=C;
        dataTable.ColumnName={'时间','序列1','序列2','序列3','序列4'};
        dataTable.ColumnEditable=true(1,5);
        seriesDrop.Items=dataTable.ColumnName(2:end);
        seriesDrop.Value='序列1';
        clearResults();
    end

    function appendRows(~,~)
        C=dataTable.Data;
        dataTable.Data=[C;cell(10,size(C,2))];
    end

    function clearData(~,~)
        dataTable.Data=cell(30,max(2,size(dataTable.Data,2)));
        clearResults();
        featureLabel.Text='导入数据后点击“分析序列特征”。';
    end

    function clearResults(varargin)
        lastResult=[];
        resultTable.Data=cell(0,5);
        metricTable.Data=cell(0,2);
        cla(plotAxes);
        title(plotAxes,'原始序列、拟合值与预测值');
    end

    function [x,times] = selectedSeries()
        C=dataTable.Data;
        col=find(strcmp(dataTable.ColumnName,seriesDrop.Value),1);
        if isempty(col) || col==1
            error('请先选择一个数值序列。');
        end
        x=nan(size(C,1),1);
        times=cell(size(C,1),1);
        for rr=1:size(C,1)
            value=C{rr,col};
            if isnumeric(value) && isscalar(value)
                x(rr)=value;
            elseif ischar(value) || isstring(value)
                x(rr)=str2double(string(value));
            end
            times{rr}=C{rr,1};
        end
        keep=isfinite(x);
        x=x(keep); times=times(keep);
        if isempty(x), error('所选列没有有效数值。'); end
        if any(~isfinite(x)), error('数据包含 NaN 或 Inf。'); end
    end

    function categoryChanged(~,~)
        refreshModelList();
        clearResults();
    end

    function refreshModelList()
        category=categoryDrop.Value;
        rows=find(strcmp(catalog(:,1),category));
        if isempty(rows)
            modelDrop.Items={'无可用模型'};
            modelDrop.Value='无可用模型';
            return;
        end
        items=catalog(rows,2);
        modelDrop.Items=items;
        modelDrop.Value=items{1};
    end

    function modelChanged(~,~)
        idx=selectedModelIndex();
        if isempty(idx), return; end
        if catalog{idx,4}==4
            parameterLabel.Text='非线性模型：参数由模型内部估计';
        elseif catalog{idx,4}==5
            parameterLabel.Text='耦合模型：默认自动优化；可设置 optimize';
        else
            parameterLabel.Text='线性模型：DPD/NIP参数使用 q、lambda';
        end
        clearResults();
    end

    function idx=selectedModelIndex()
        idx=find(strcmp(catalog(:,2),modelDrop.Value),1);
    end

    function analyzeSeries(~,~)
        try
            [x,~]=selectedSeries();
            n=numel(x); t=(1:n)';
            if n<3, error('至少需要3个有效观测值。'); end
            if std(x)==0
                trendCorr=0; seasonalCorr=NaN;
            else
                cc=corrcoef(t,x); trendCorr=cc(1,2);
                s=round(periodField.Value);
                if s>=1 && n>s
                    cc=corrcoef(x(1:end-s),x(1+s:end)); seasonalCorr=cc(1,2);
                else
                    seasonalCorr=NaN;
                end
            end
            cv=std(x)/max(abs(mean(x)),eps);
            if abs(trendCorr)>=0.65, trendText='趋势相关较强';
            else, trendText='趋势相关不强'; end
            if isfinite(seasonalCorr) && abs(seasonalCorr)>=0.45
                seasonText='指定滞后存在周期相关';
            else
                seasonText='指定滞后周期相关较弱';
            end
            if any(x<=0), valueText='含零值或负值，请注意所选模型的数据约束';
            else, valueText='数据为正值'; end
            featureLabel.Text=sprintf('%s；%s；CV=%.3f；%s',trendText,seasonText,cv,valueText);
        catch ME
            uialert(fig,ME.message,'特征分析失败','Icon','error');
        end
    end

    function recommendModel(~,~)
        try
            [x,~]=selectedSeries();
            if numel(x)<max(6,round(periodField.Value)+2)
                error('样本量不足以进行灰色季节模型推荐。');
            end
            % DGSM is explicitly presented as a baseline, not an automatic optimum.
            idx=find(strcmp(catalog(:,3),'dgsm'),1);
            if isempty(idx), error('仓库中没有检测到 dgsm.m。'); end
            categoryDrop.Value=catalog{idx,1};
            refreshModelList();
            modelDrop.Value=catalog{idx,2};
            uialert(fig,['建议先以 DGSM(1,1) 作为基准模型，再使用相同留出样本' ...
                '比较线性、非线性和耦合模型的预测误差。此推荐不是自动最优判定。'],...
                '基准模型建议');
        catch ME
            uialert(fig,ME.message,'模型推荐失败','Icon','error');
        end
    end

    function advancedOptions(~,~)
        dlg=uifigure('Name','高级模型参数','Position',[500 350 390 250],...
            'WindowStyle','modal');
        g=uigridlayout(dlg,[4 2]);
        g.RowHeight={36,36,36,'1x'};
        g.ColumnWidth={145,'1x'};
        uilabel(g,'Text','DPD局部窗口 q');
        qField=uieditfield(g,'numeric','Value',modelOpts.q,'Limits',[1 Inf],...
            'RoundFractionalValues','on');
        uilabel(g,'Text','NIP新息权重 lambda');
        lambdaField=uieditfield(g,'numeric','Value',modelOpts.lambda,...
            'Limits',[0 Inf]);
        uilabel(g,'Text','耦合模型自动优化');
        optimizeCheck=uicheckbox(g,'Value',logical(modelOpts.optimize));
        uibutton(g,'Text','应用参数','ButtonPushedFcn',@applyAdvanced);
        function applyAdvanced(~,~)
            modelOpts.q=round(qField.Value);
            modelOpts.lambda=lambdaField.Value;
            modelOpts.optimize=optimizeCheck.Value;
            delete(dlg);
        end
    end

    function runForecast(~,~)
        try
            [x,times]=selectedSeries();
            s=round(periodField.Value);
            h=round(horizonField.Value);
            v=round(holdoutField.Value);
            if s<1 || h<1, error('季节周期和预测步长必须为正整数。'); end
            if numel(x)<max(6,s+2)
                error('样本量不足。当前建议至少 max(6,周期+2) 个观测值。');
            end
            idx=selectedModelIndex();
            if isempty(idx), error('请选择有效模型。'); end
            fun=catalog{idx,3};
            chapter=catalog{idx,4};
            if exist(fun,'file')~=2
                error('模型文件 %s 不在 MATLAB 路径中。请检查仓库文件夹。',fun);
            end
            if v<0 || v>=numel(x)-max(3,s)
                if v~=0, error('验证样本数过大；请减少验证长度。'); end
            end

            validation=struct('MAPE',NaN,'MAE',NaN,'RMSE',NaN,'MSE',NaN);
            if v>0
                trainX=x(1:end-v);
                actual=x(end-v+1:end);
                valOut=callModel(fun,chapter,trainX,v,s);
                valPred=valOut.forecast(:);
                if numel(valPred)~=v
                    error('%s 返回的验证预测长度不是验证样本数。',fun);
                end
                validation=calcMetrics(actual,valPred);
            end

            fullOut=callModel(fun,chapter,x,h,s);
            fitted=fullOut.fitted(:);
            forecast=fullOut.forecast(:);
            if numel(fitted)~=numel(x)
                error('%s 返回的拟合值长度与输入数据长度不一致。',fun);
            end
            if numel(forecast)~=h
                error('%s 返回的预测值长度与预测步长不一致。',fun);
            end
            trainMetrics=calcMetrics(x(isfinite(fitted)),fitted(isfinite(fitted)));
            lastResult=struct('x',x,'times',{times},'fitted',fitted,...
                'forecast',forecast,'validation',validation,...
                'training',trainMetrics,'model',fun,'modelDisplay',catalog{idx,2},...
                'category',catalog{idx,1},'period',s,'horizon',h,'holdout',v,...
                'modelOutput',fullOut);
            updateMetrics(lastResult);
            drawForecast(lastResult);
            updateResultTable(lastResult);
        catch ME
            uialert(fig,ME.message,'模型运行失败','Icon','error');
        end
    end

    function out=callModel(fun,chapter,x,h,s)
        switch chapter
            case 3
                out=feval(fun,x,h,s,modelOpts);
            case 4
                out=feval(fun,x,s,h);
            case 5
                out=feval(fun,x,h,s,modelOpts);
            otherwise
                error('未定义的模型接口类型。');
        end
        if ~isstruct(out) || ~isfield(out,'fitted') || ~isfield(out,'forecast')
            error('模型 %s 未返回包含 fitted 和 forecast 字段的结构体。',fun);
        end
    end

    function M=calcMetrics(actual,predicted)
        actual=actual(:); predicted=predicted(:);
        valid=isfinite(actual)&isfinite(predicted);
        actual=actual(valid); predicted=predicted(valid);
        if isempty(actual), error('没有可用于误差评价的有效观测值。'); end
        e=actual-predicted;
        M.MAE=mean(abs(e));
        M.MSE=mean(e.^2);
        M.RMSE=sqrt(M.MSE);
        nz=abs(actual)>eps;
        if any(nz)
            M.MAPE=mean(abs(e(nz)./actual(nz)))*100;
        else
            M.MAPE=NaN;
        end
        M.SSE=sum(e.^2);
    end

    function updateMetrics(R)
        V=R.validation; T=R.training;
        metricTable.Data={
            '验证集 MAPE (%)',V.MAPE
            '验证集 MAE',V.MAE
            '验证集 RMSE',V.RMSE
            '验证集 MSE',V.MSE
            '样本内 MAPE (%)',T.MAPE
            '样本内 MAE',T.MAE
            '样本内 RMSE',T.RMSE
            '样本内 MSE',T.MSE
            '模型',R.model
            '周期 / 预测步长',sprintf('%d / %d',R.period,R.horizon)};
    end

    function drawForecast(R)
        cla(plotAxes); hold(plotAxes,'on');
        n=numel(R.x);
        plot(plotAxes,1:n,R.x,'ko-','LineWidth',1.1,...
            'MarkerSize',4,'DisplayName','原始数据');
        plot(plotAxes,1:n,R.fitted,'b--','LineWidth',1.4,...
            'DisplayName','样本内拟合');
        plot(plotAxes,n+(1:numel(R.forecast)),R.forecast,'r*-',...
            'LineWidth',1.5,'DisplayName','未来预测');
        xline(plotAxes,n,'k:','预测起点','HandleVisibility','off');
        xlabel(plotAxes,'时间序号'); ylabel(plotAxes,'观测值');
        title(plotAxes,sprintf('%s | 周期=%d | 预测步长=%d',...
            R.modelDisplay,R.period,R.horizon),'Interpreter','none');
        legend(plotAxes,'Location','best'); grid(plotAxes,'on');
        hold(plotAxes,'off');
    end

    function updateResultTable(R)
        n=numel(R.x); h=numel(R.forecast);
        D=cell(n+h,5);
        for ii=1:n
            ape=NaN;
            if isfinite(R.fitted(ii)) && abs(R.x(ii))>eps
                ape=abs(R.x(ii)-R.fitted(ii))/abs(R.x(ii))*100;
            end
            D(ii,:)={R.times{ii},R.x(ii),R.fitted(ii),ape,'样本内拟合'};
        end
        for ii=1:h
            D(n+ii,:)={sprintf('预测期 %d',ii),NaN,R.forecast(ii),NaN,'未来预测'};
        end
        resultTable.Data=D;
    end

    function exportExcel(~,~)
        if isempty(lastResult)
            uialert(fig,'请先运行模型预测。','提示'); return;
        end
        [file,path]=uiputfile('GreySeasonal_Forecast.xlsx','导出预测结果');
        if isequal(file,0), return; end
        R=lastResult; n=numel(R.x); h=numel(R.forecast);
        timeCol=[string(R.times(:));"Forecast_"+string((1:h)')];
        actual=[R.x;nan(h,1)];
        fitForecast=[R.fitted;R.forecast];
        ape=nan(n+h,1);
        nz=abs(R.x)>eps & isfinite(R.fitted);
        ape(find(nz))=abs(R.x(nz)-R.fitted(nz))./abs(R.x(nz))*100;
        kind=[repmat("Fitted",n,1);repmat("Forecast",h,1)];
        T=table(timeCol,actual,fitForecast,ape,kind,...
            'VariableNames',{'Time','Actual','FittedOrForecast','APE_percent','Type'});
        writetable(T,fullfile(path,file));
        uialert(fig,'预测结果和逐期APE已保存为Excel文件。','导出完成');
    end

    function exportPlot(~,~)
        if isempty(lastResult)
            uialert(fig,'请先运行模型预测。','提示'); return;
        end
        [file,path]=uiputfile('GreySeasonal_Forecast.png','保存预测图');
        if isequal(file,0), return; end
        R=lastResult;
        tempFig = figure('Visible','off','Color','w');
        tempAx = axes('Parent',tempFig);
        hold(tempAx,'on');
        n=numel(R.x);
        plot(tempAx,1:n,R.x,'ko-','LineWidth',1.1,'DisplayName','原始数据');
        plot(tempAx,1:n,R.fitted,'b--','LineWidth',1.4,'DisplayName','样本内拟合');
        plot(tempAx,n+(1:numel(R.forecast)),R.forecast,'r*-',...
            'LineWidth',1.5,'DisplayName','未来预测');
        line(tempAx,[n n],ylim(tempAx),'Color','k','LineStyle',':',...
            'HandleVisibility','off');
        xlabel(tempAx,'时间序号'); ylabel(tempAx,'观测值');
        title(tempAx,R.modelDisplay,'Interpreter','none');
        legend(tempAx,'Location','best'); grid(tempAx,'on');
        print(tempFig,fullfile(path,file),'-dpng','-r180');
        close(tempFig);
    end
end

function addModelPaths(repoRoot)
folders={
 '02_Grey_Seasonal_Linear_Model'
 '03_Grey_Seasonal_Nonlinear_Model'
 '04_Grey_Seasonal_Coupled_Model'};
for k=1:numel(folders)
    folder=fullfile(repoRoot,folders{k});
    if isfolder(folder), addpath(folder); end
end
end
