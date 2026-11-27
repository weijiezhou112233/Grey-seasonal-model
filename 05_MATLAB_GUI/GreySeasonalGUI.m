function GreySeasonalGUI
% GREYSEASONALGUI  Grey seasonal forecasting desktop application.
% MATLAB R2019b or later. Run: GreySeasonalGUI
% Models are called as independent functions from the repository folders.
% Chapter 3/5 signatures: model(x,h,s[,opts]); Chapter 4: model(x,s,h).

root = fileparts(mfilename('fullpath'));
repoRoot = fileparts(root);
addRepoPaths(repoRoot);

models = {
    'DGSM(1,1) - 灰色季节模型', 'dgsm', 3;
    'CDGSM(1,1) - 耦合灰色季节模型', 'cdgsm', 3;
    'DGSTM(1,1) - 趋势灰色季节模型', 'dgstm', 3;
    'DPDGSM(1,1)', 'dpdgsm', 3;
    'DPDGSTM(1,1)', 'dpdgstm', 3;
    'SDGM(1,1)', 'sdgm', 3;
    'DDVGSM(1,1)', 'ddvgsm', 3;
    'NIPDGSTM(1,1)', 'nipdgstm', 3;
    'NIPDDGSM(1,1)', 'nipddgsm', 3;
    'SNGBM(1,1)', 'sngbm', 4;
    'SWBGM(1,1)', 'swbgm', 4;
    'DGSTPM(1,1)', 'dgstpm', 4;
    'NIPSGMP(1,1)', 'nipsgmp', 4;
    'NIPSWBGM(1,1)', 'nipswbgm', 4;
    'DDVGSTM(1,1)', 'ddvgstm', 4;
    'GSLSSVR', 'gslssvr', 5;
    'GSTLSSVR', 'gstlssvr', 5;
    'NOFGHW', 'nofghw', 5;
    'NCGHW', 'ncghw', 5
};
available = false(size(models,1),1);
for k=1:size(models,1), available(k)=exist(models{k,2},'file')==2; end
models = models(available,:);
if isempty(models), error('未找到模型文件。请确认仓库目录结构完整。'); end

fig = uifigure('Name','Grey Seasonal Forecasting System | 灰色季节预测系统',...
    'Position',[80 60 1380 820]);
main = uigridlayout(fig,[3 2]);
main.RowHeight={42,'1.1x','1.2x'};
main.ColumnWidth={'1.05x','1x'};
main.Padding=[10 10 10 10]; main.RowSpacing=8; main.ColumnSpacing=8;

head = uilabel(main,'Text','灰色季节模型预测与分析平台',...
    'FontSize',20,'FontWeight','bold','HorizontalAlignment','center');
head.Layout.Row=1; head.Layout.Column=[1 2];

% Data input
pData=uipanel(main,'Title','数据导入与编辑');
pData.Layout.Row=2; pData.Layout.Column=1;
gd=uigridlayout(pData,[3 1]); gd.RowHeight={34,'1x',28};
tools=uigridlayout(gd,[1 4]); tools.ColumnWidth={'1x','1x','1x','1x'};
uibutton(tools,'Text','导入 Excel/CSV','ButtonPushedFcn',@importData);
uibutton(tools,'Text','示例数据','ButtonPushedFcn',@loadDemo);
uibutton(tools,'Text','添加行','ButtonPushedFcn',@addRows);
uibutton(tools,'Text','清空','ButtonPushedFcn',@clearData);
dataTable=uitable(gd,'Data',cell(24,3),...
    'ColumnName',{'时间','序列1','序列2'},...
    'ColumnEditable',[true true true],...
    'ColumnWidth',{100,100,100});
uilabel(gd,'Text','第一列为时间标签，其余列为数值序列；可直接粘贴 Excel 数据。',...
    'FontColor',[0.25 0.25 0.25]);

% Settings and feature analysis
pSet=uipanel(main,'Title','序列特征识别与模型匹配');
pSet.Layout.Row=2; pSet.Layout.Column=2;
gs=uigridlayout(pSet,[9 2]);
gs.RowHeight={30,30,30,30,30,30,'1x',34,34};
gs.ColumnWidth={115,'1x'};
uilabel(gs,'Text','数值序列');
seriesDrop=uidropdown(gs,'Items',{'序列1'},'Value','序列1');
uilabel(gs,'Text','预测模型');
modelDrop=uidropdown(gs,'Items',models(:,1),'Value',models{1,1});
uilabel(gs,'Text','季节周期');
periodField=uieditfield(gs,'numeric','Value',4,'Limits',[1 Inf],...
    'RoundFractionalValues','on');
uilabel(gs,'Text','预测步长');
horizonField=uieditfield(gs,'numeric','Value',4,'Limits',[1 Inf],...
    'RoundFractionalValues','on');
uilabel(gs,'Text','验证长度');
holdoutField=uieditfield(gs,'numeric','Value',4,'Limits',[0 Inf],...
    'RoundFractionalValues','on');
uilabel(gs,'Text','模型类别');
categoryLabel=uilabel(gs,'Text','线性 / 非线性 / 耦合模型','WordWrap','on');
uilabel(gs,'Text','特征分析');
featureLabel=uilabel(gs,'Text','请导入数据后点击“特征分析”。','WordWrap','on');
uibutton(gs,'Text','自动识别序列特征','ButtonPushedFcn',@analyze);
uibutton(gs,'Text','推荐模型','ButtonPushedFcn',@recommend);

% Results
pRes=uipanel(main,'Title','预测结果、误差分析与可视化');
pRes.Layout.Row=3; pRes.Layout.Column=[1 2];
gr=uigridlayout(pRes,[3 2]);
gr.RowHeight={'1.2x',34,'1x'}; gr.ColumnWidth={'1.25x','1x'};
ax=uiaxes(gr); ax.Layout.Row=1; ax.Layout.Column=1;
ax.XGrid='on'; ax.YGrid='on'; title(ax,'原始序列、拟合值与预测值');
metricTable=uitable(gr,'Data',cell(8,2),...
    'ColumnName',{'误差指标','数值'});
metricTable.Layout.Row=1; metricTable.Layout.Column=2;
buttons=uigridlayout(gr,[1 4]); buttons.Layout.Row=2; buttons.Layout.Column=[1 2];
buttons.ColumnWidth={'1x','1x','1x','1x'};
uibutton(buttons,'Text','运行预测','ButtonPushedFcn',@runForecast,...
    'BackgroundColor',[0.20 0.48 0.78],'FontColor',[1 1 1]);
uibutton(buttons,'Text','保存结果','ButtonPushedFcn',@saveResults);
uibutton(buttons,'Text','导出预测图','ButtonPushedFcn',@savePlot);
uibutton(buttons,'Text','结果表格','ButtonPushedFcn',@showResults);
resultTable=uitable(gr,'Data',cell(0,5),...
    'ColumnName',{'时间','实际值','拟合/预测值','APE(%)','类型'});
resultTable.Layout.Row=3; resultTable.Layout.Column=[1 2];

lastResult=[];
timeLabels={};

    function addRepoPaths(base)
        folders={'01_Data_Generation_Model','02_Grey_Seasonal_Linear_Model',...
            '03_Grey_Seasonal_Nonlinear_Model','04_Grey_Seasonal_Coupled_Model'};
        for ii=1:numel(folders)
            d=fullfile(base,folders{ii});
            if isfolder(d), addpath(d); end
        end
    end

    function importData(~,~)
        [fn,fp]=uigetfile({'*.xlsx;*.xls;*.csv','Excel / CSV files'},'选择数据文件');
        if isequal(fn,0), return; end
        try
            T=readtable(fullfile(fp,fn),'VariableNamingRule','preserve');
            if width(T)<2, error('文件至少需要一列时间和一列数值数据。'); end
            C=table2cell(T); out=cell(height(T),width(T));
            for rr=1:height(T)
                out{rr,1}=char(string(C{rr,1}));
                for cc=2:width(T)
                    v=C{rr,cc};
                    if isnumeric(v), out{rr,cc}=v;
                    else, out{rr,cc}=str2double(string(v)); end
                end
            end
            dataTable.Data=out;
            dataTable.ColumnName=T.Properties.VariableNames;
            seriesDrop.Items=T.Properties.VariableNames(2:end);
            seriesDrop.Value=seriesDrop.Items{1};
            timeLabels=out(:,1);
        catch ME
            uialert(fig,ME.message,'数据导入失败','Icon','error');
        end
    end

    function loadDemo(~,~)
        xx=[120 135 150 145 130 148 166 160 142 158 178 170 ...
            150 168 190 182 160 177 198 190 170 188 210 202]';
        C=cell(numel(xx),2);
        for ii=1:numel(xx), C{ii,1}=sprintf('t%d',ii); C{ii,2}=xx(ii); end
        dataTable.Data=C; dataTable.ColumnName={'时间','序列1'};
        seriesDrop.Items={'序列1'}; seriesDrop.Value='序列1';
        timeLabels=C(:,1);
    end

    function addRows(~,~)
        C=dataTable.Data; C=[C;cell(10,size(C,2))]; dataTable.Data=C;
    end

    function clearData(~,~)
        dataTable.Data=cell(24,3); lastResult=[]; timeLabels={};
        resultTable.Data=cell(0,5); metricTable.Data=cell(0,2); cla(ax);
    end

    function [x,times]=getSeries()
        C=dataTable.Data; col=find(strcmp(dataTable.ColumnName,seriesDrop.Value),1);
        if isempty(col), error('请先导入或粘贴数值序列。'); end
        x=nan(size(C,1),1); times=cell(size(C,1),1);
        for ii=1:size(C,1)
            v=C{ii,col};
            if isnumeric(v)&&isscalar(v), x(ii)=v;
            elseif ischar(v)||isstring(v), x(ii)=str2double(string(v)); end
            if size(C,2)>=1, times{ii}=C{ii,1}; end
        end
        keep=isfinite(x); x=x(keep); times=times(keep);
        if isempty(x), error('所选列没有有效数值。'); end
        if any(~isfinite(x)), error('数据包含非有限值。'); end
    end

    function analyze(~,~)
        try
            [x,~]=getSeries(); n=numel(x); tt=(1:n)';
            if n<3, error('至少需要3个有效观测值。'); end
            trendCorr=corr(tt,x);
            cv=std(x)/max(abs(mean(x)),eps);
            s=round(periodField.Value);
            if n>s
                seasonalCorr=corr(x(1:end-s),x(1+s:end));
            else
                seasonalCorr=NaN;
            end
            featureLabel.Text=sprintf('趋势相关=%.3f；变异系数=%.3f；周期滞后相关=%.3f',...
                trendCorr,cv,seasonalCorr);
            categoryLabel.Text=classifyModel(x,trendCorr,seasonalCorr);
        catch ME
            uialert(fig,ME.message,'特征分析失败','Icon','error');
        end
    end

    function txt=classifyModel(x,rhoTrend,rhoSeason)
        if abs(rhoSeason)>0.45
            seasonalTxt='具有明显周期相关';
        else
            seasonalTxt='周期性证据较弱';
        end
        if abs(rhoTrend)>0.65, trendTxt='趋势性较强';
        else, trendTxt='趋势性不明显'; end
        if std(diff(x))>1.5*max(std(x),eps), shapeTxt='波动/非线性特征需进一步检验';
        else, shapeTxt='变化相对平稳'; end
        txt=[trendTxt,'；',seasonalTxt,'；',shapeTxt];
    end

    function recommend(~,~)
        try
            [x,~]=getSeries(); s=round(periodField.Value);
            if numel(x)<max(6,s+2), error('样本量不足以推荐当前灰色季节模型。'); end
            idx=find(strcmp(models(:,2),'dgsm'),1);
            if ~isempty(idx), modelDrop.Value=models{idx,1}; end
            hint='推荐 DGSM 作为基准模型；建议再用留出样本与其他模型比较。';
            uialert(fig,hint,'模型推荐');
        catch ME
            uialert(fig,ME.message,'推荐失败','Icon','error');
        end
    end

    function runForecast(~,~)
        try
            [x,times]=getSeries(); s=round(periodField.Value);
            h=round(horizonField.Value); v=round(holdoutField.Value);
            if s<1||h<1, error('周期和预测步长必须为正整数。'); end
            if numel(x)<max(6,s+2), error('样本长度不足；建议至少 max(6,周期+2) 个观测值。'); end
            mi=find(strcmp(models(:,1),modelDrop.Value),1);
            if isempty(mi), error('未找到所选模型。'); end
            fun=models{mi,2}; chapter=models{mi,3};
            if exist(fun,'file')~=2, error('模型文件 %s 不在 MATLAB 路径中。',fun); end

            valMetrics=struct('MAPE',NaN,'MAE',NaN,'RMSE',NaN,'MSE',NaN);
            if v>0
                if v>=numel(x)-max(3,s), error('验证长度过大，需保留足够训练样本。'); end
                rv=callSelectedModel(fun,chapter,x(1:end-v),v,s);
                actual=x(end-v+1:end); pred=rv.forecast(:);
                valMetrics=calcMetrics(actual,pred);
            end
            r=callSelectedModel(fun,chapter,x,h,s);
            fit=r.fitted(:); fc=r.forecast(:);
            if numel(fit)~=numel(x), error('模型返回的拟合值长度与输入数据不一致。'); end
            lastResult=struct('x',x,'times',{times},'fit',fit,'forecast',fc,...
                'metrics',valMetrics,'model',fun,'period',s,'horizon',h);
            metricTable.Data={'验证 MAPE (%)',valMetrics.MAPE;...
                '验证 MAE',valMetrics.MAE;'验证 RMSE',valMetrics.RMSE;...
                '验证 MSE',valMetrics.MSE;'SSE（样本内）',sum((x(isfinite(fit))-fit(isfinite(fit))).^2);...
                '预测步长',h;'季节周期',s;'模型',fun};
            drawResults(lastResult);
            fillResultTable(lastResult);
        catch ME
            uialert(fig,ME.message,'预测失败','Icon','error');
        end
    end

    function r=callSelectedModel(fun,chapter,x,h,s)
        switch chapter
            case 3
                r=feval(fun,x,h,s);
            case 4
                r=feval(fun,x,s,h);
            case 5
                r=feval(fun,x,h,s);
            otherwise
                error('未知模型版本。');
        end
        if ~isstruct(r)||~isfield(r,'fitted')||~isfield(r,'forecast')
            error('模型 %s 未返回标准 fitted/forecast 字段。',fun);
        end
    end

    function M=calcMetrics(a,p)
        a=a(:); p=p(:); e=a-p;
        M.MAE=mean(abs(e)); M.MSE=mean(e.^2); M.RMSE=sqrt(M.MSE);
        nz=abs(a)>eps;
        if any(nz), M.MAPE=mean(abs(e(nz)./a(nz)))*100; else, M.MAPE=NaN; end
    end

    function drawResults(R)
        cla(ax); hold(ax,'on'); n=numel(R.x);
        plot(ax,1:n,R.x,'ko-','LineWidth',1.1,'DisplayName','原始值');
        plot(ax,1:n,R.fit,'b--','LineWidth',1.4,'DisplayName','拟合值');
        plot(ax,n+(1:numel(R.forecast)),R.forecast,'r*-','LineWidth',1.4,'DisplayName','预测值');
        xline(ax,n,'k:','预测起点'); legend(ax,'Location','best');
        xlabel(ax,'时间'); ylabel(ax,'观测值');
        title(ax,sprintf('%s | 周期=%d | 预测步长=%d',R.model,R.period,R.horizon));
        grid(ax,'on'); hold(ax,'off');
    end

    function fillResultTable(R)
        n=numel(R.x); h=numel(R.forecast); D=cell(n+h,5);
        for ii=1:n
            ape=NaN;
            if abs(R.x(ii))>eps, ape=abs(R.x(ii)-R.fit(ii))/abs(R.x(ii))*100; end
            D(ii,:)={R.times{ii},R.x(ii),R.fit(ii),ape,'样本内拟合'};
        end
        for ii=1:h
            D(n+ii,:)={sprintf('预测%d',ii),NaN,R.forecast(ii),NaN,'未来预测'};
        end
        resultTable.Data=D;
    end

    function saveResults(~,~)
        if isempty(lastResult), uialert(fig,'请先运行预测。','提示'); return; end
        [fn,fp]=uiputfile('GreySeasonal_results.xlsx','保存预测结果');
        if isequal(fn,0), return; end
        R=lastResult; n=numel(R.x); h=numel(R.forecast);
        Time=[string(R.times(:));"预测"+string((1:h)')];
        Actual=[R.x;nan(h,1)]; FitForecast=[R.fit;R.forecast];
        Type=[repmat("拟合",n,1);repmat("预测",h,1)];
        writetable(table(Time,Actual,FitForecast,Type),fullfile(fp,fn));
        uialert(fig,'预测结果已导出为 Excel。','导出完成');
    end

    function savePlot(~,~)
        if isempty(lastResult), uialert(fig,'请先运行预测。','提示'); return; end
        [fn,fp]=uiputfile('GreySeasonal_plot.png','保存预测图');
        if isequal(fn,0), return; end
        exportgraphics(ax,fullfile(fp,fn));
    end

    function showResults(~,~)
        if isempty(lastResult), uialert(fig,'请先运行预测。','提示'); return; end
        f2=uifigure('Name','预测结果明细','Position',[180 160 760 520]);
        uitable(f2,'Data',resultTable.Data,'ColumnName',resultTable.ColumnName,...
            'Position',[10 10 740 500]);
    end
end
