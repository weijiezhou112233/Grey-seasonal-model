function GreySeasonalGUI
% Grey Seasonal Model GUI (MATLAB R2019b+)
% DGSM option below is a seasonal-subseries GM(1,1) DEMONSTRATION PROTOTYPE.
% It is not a verified substitute for a book-specific DGSM equation.
f=uifigure('Name','Grey Seasonal Model | 灰色季节预测系统','Position',[80 60 1250 760]);
g=uigridlayout(f,[2 2]); g.RowHeight={310,'1x'}; g.ColumnWidth={'1.1x','1x'};
p=uipanel(g,'Title','数据导入'); p.Layout.Row=1; p.Layout.Column=1;
a=uigridlayout(p,[3 1]); a.RowHeight={30,'1x',30};
u= uigridlayout(a,[1 2]); u.ColumnWidth={'1x',100};
uilabel(u,'Text','第一列时间，其余列为数值序列');
uibutton(u,'Text','导入Excel/CSV','ButtonPushedFcn',@importFile);
tbl=uitable(a,'Data',cell(16,3),'ColumnName',{'时间','序列1','序列2'},'ColumnEditable',[true true true]);
uilabel(a,'Text','可直接粘贴数据到表格。');
p2=uipanel(g,'Title','序列特征识别与模型匹配'); p2.Layout.Row=1; p2.Layout.Column=2;
b=uigridlayout(p2,[7 2]); b.RowHeight={30,30,30,30,30,30,'1x'}; b.ColumnWidth={100,'1x'};
uilabel(b,'Text','数值序列'); series=uidropdown(b,'Items',{'序列1'},'Value','序列1');
uilabel(b,'Text','模型'); model=uidropdown(b,'Items',{'DGSM(1,1) - 季节分组GM原型'},'Value','DGSM(1,1) - 季节分组GM原型');
uilabel(b,'Text','季节周期'); period=uieditfield(b,'numeric','Value',4,'Limits',[2 Inf],'RoundFractionalValues','on');
uilabel(b,'Text','预测步长'); horizon=uieditfield(b,'numeric','Value',4,'Limits',[1 Inf],'RoundFractionalValues','on');
uilabel(b,'Text','验证长度'); holdout=uieditfield(b,'numeric','Value',4,'Limits',[0 Inf],'RoundFractionalValues','on');
uilabel(b,'Text','特征识别'); feature=uilabel(b,'Text','等待分析','WordWrap','on');
uilabel(b,'Text','提示'); hint=uilabel(b,'Text','模型推荐需结合留出样本误差判断。','WordWrap','on');
p3=uipanel(g,'Title','拟合、预测与误差'); p3.Layout.Row=2; p3.Layout.Column=[1 2];
c=uigridlayout(p3,[2 2]); c.RowHeight={'1.3x','1x'}; c.ColumnWidth={'1.2x','1x'};
ax=uiaxes(c); ax.Layout.Row=1; ax.Layout.Column=1; grid(ax,'on');
metrics=uitable(c,'Data',cell(5,2),'ColumnName',{'指标','数值'}); metrics.Layout.Row=1; metrics.Layout.Column=2;
res=uitable(c,'Data',cell(0,5),'ColumnName',{'时间','实际值','拟合/预测值','APE(%)','类型'}); res.Layout.Row=2; res.Layout.Column=[1 2];
bar=uigridlayout(c,[1 4]); bar.Layout.Row=1; bar.Layout.Column=[1 2]; bar.ColumnWidth={'1x','1x','1x','1x'};
uibutton(bar,'Text','特征分析','ButtonPushedFcn',@analyze);
uibutton(bar,'Text','运行预测','ButtonPushedFcn',@run);
uibutton(bar,'Text','保存Excel','ButtonPushedFcn',@save);
uibutton(bar,'Text','清空','ButtonPushedFcn',@clearAll);
last=[];
function importFile(~,~)
 [fn,fp]=uigetfile({'*.xlsx;*.xls;*.csv','Excel/CSV'}); if isequal(fn,0),return,end
 try
  T=readtable(fullfile(fp,fn),'VariableNamingRule','preserve');
  if width(T)<2,error('至少需要时间列和一个数值列。');end
  C=table2cell(T); names=[{'时间'},T.Properties.VariableNames(2:end)];
  vals=cell(height(T),width(T));
  for r=1:height(T)
   vals{r,1}=char(string(C{r,1}));
   for j=2:width(T)
    v=C{r,j}; if isnumeric(v),vals{r,j}=v;else,vals{r,j}=str2double(string(v));end
   end
  end
  tbl.Data=vals; tbl.ColumnName=names; series.Items=names(2:end); series.Value=names{2};
 catch ME,uialert(f,ME.message,'导入失败','Icon','error');end
end
function x=getX()
 C=tbl.Data; col=find(strcmp(tbl.ColumnName,series.Value),1);
 if isempty(col),error('请先导入或粘贴数据。');end
 x=nan(size(C,1),1);
 for ii=1:size(C,1)
  v=C{ii,col}; if isnumeric(v)&&isscalar(v),x(ii)=v;elseif ischar(v)||isstring(v),x(ii)=str2double(string(v));end
 end
 x=x(isfinite(x));
 if numel(x)<2*period.Value,error('有效数据至少应覆盖两个完整周期。');end
 if any(x<=0),error('当前演示模型要求数据为正数。');end
end
function analyze(~,~)
 try
  x=getX(); t=(1:numel(x))'; r=sum((t-mean(t)).*(x-mean(x)))/max(sqrt(sum((t-mean(t)).^2)*sum((x-mean(x)).^2)),eps);
  cv=std(x)/mean(x); feature.Text=sprintf('趋势相关系数 %.3f；变异系数 %.3f；周期=%d',r,cv,period.Value);
  hint.Text='特征指标仅作辅助描述；建议用留出样本比较模型误差。';
 catch ME,uialert(f,ME.message,'分析失败','Icon','error');end
end
function run(~,~)
 try
  x=getX(); s=round(period.Value); h=round(horizon.Value); v=round(holdout.Value);
  if v>0
   if v>=numel(x)-2*s,error('验证长度过大。');end
   [~,vf]=seasonalGM(x(1:end-v),s,v); actual=x(end-v+1:end); e=actual-vf;
   ape=abs(e)./abs(actual)*100; mape=mean(ape); mae=mean(abs(e)); rmse=sqrt(mean(e.^2)); mse=mean(e.^2);
  else
   mape=NaN;mae=NaN;rmse=NaN;mse=NaN;
  end
  [fit,fc]=seasonalGM(x,s,h); last=struct('x',x,'fit',fit,'fc',fc,'mape',mape,'mae',mae,'rmse',rmse,'mse',mse);
  metrics.Data={'MAPE (%)',mape;'MAE',mae;'RMSE',rmse;'MSE',mse;'验证长度',v};
  cla(ax); hold(ax,'on'); plot(ax,1:numel(x),x,'ko-','DisplayName','原始值'); plot(ax,1:numel(x),fit,'b--','DisplayName','拟合值');
  plot(ax,numel(x)+(1:h),fc,'r*-','DisplayName','预测值'); xline(ax,numel(x),'k:','预测起点'); legend(ax,'Location','best'); grid(ax,'on');
  R=cell(numel(x)+h,5);
  for k=1:numel(x),R(k,:)={k,x(k),fit(k),abs(x(k)-fit(k))/abs(x(k))*100,'拟合'};end
  for k=1:h,R(numel(x)+k,:)={sprintf('预测%d',k),NaN,fc(k),NaN,'预测'};end
  res.Data=R;
  uialert(f,'计算完成。注意：当前DGSM选项是季节分组GM(1,1)演示原型，并非已核验的书稿公式实现。','完成');
 catch ME,uialert(f,ME.message,'预测失败','Icon','error');end
end
function save(~,~)
 if isempty(last),uialert(f,'请先运行预测。','提示');return,end
 [fn,fp]=uiputfile('GreySeasonal_results.xlsx');if isequal(fn,0),return,end
 n=numel(last.x); h=numel(last.fc); Time=(1:n+h)'; Actual=[last.x;nan(h,1)]; FittedForecast=[last.fit;last.fc];
 Type=[repmat("拟合",n,1);repmat("预测",h,1)]; writetable(table(Time,Actual,FittedForecast,Type),fullfile(fp,fn));
 try,exportgraphics(ax,fullfile(fp,'GreySeasonal_plot.png'));catch,end
 uialert(f,'Excel和图像已保存。','导出完成');
end
function clearAll(~,~),tbl.Data=cell(16,3);last=[];res.Data=cell(0,5);cla(ax);end
end
function [fit,fc]=seasonalGM(x,s,h)
x=x(:);n=numel(x);fit=nan(n,1);fc=nan(h,1);
for j=1:s
 ids=j:s:n; y=x(ids); if numel(y)<2,error('每个季节位置至少需要两个周期观测。');end
 fit(ids)=gmFit(y);
end
fit(1:s)=x(1:s);
for k=1:h
 t=n+k;j=mod(t-1,s)+1;ids=j:s:n;y=x(ids);cycle=floor((t-1)/s)+1;ahead=max(1,cycle-numel(y));
 [~,z]=gmFit(y,ahead);fc(k)=z(end);
end
end
function [fit,fc]=gmFit(y,h)
if nargin<2,h=0;end
y=y(:);n=numel(y);x1=cumsum(y);B=[-0.5*(x1(1:end-1)+x1(2:end)),ones(n-1,1)];p=B\y(2:end);a=p(1);b=p(2);
if abs(a)<1e-10,fit=[y(1);y(1)+b*(1:n-1)'];fc=y(end)+b*(1:h)';return,end
k=(0:n-1)';z=(y(1)-b/a).*exp(-a*k)+b/a;fit=[y(1);diff(z)];
kf=(n:n+h-1)';zf=(y(1)-b/a).*exp(-a*kf)+b/a;fc=diff([z(end);zf]);
end