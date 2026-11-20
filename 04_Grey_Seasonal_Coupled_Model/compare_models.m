function [comparison,results] = compare_models(x,h,s,opts)
% COMPARE_MODELS  Run all four Chapter 5 models independently and compare.
if nargin<4, opts=struct(); end
if nargin<2 || isempty(h), h=1; end
results=struct();
results.GSLSSVR=gslssvr(x,h,s,opts);
results.GSTLSSVR=gstlssvr(x,h,s,opts);
results.NOFGHW=nofghw(x,h,s,opts);
results.NCGHW=ncghw(x,h,s,opts);
names={'GSLSSVR';'GSTLSSVR';'NOFGHW';'NCGHW'};
MAE=zeros(4,1); RMSE=MAE; MAPE=MAE; R2=MAE;
for i=1:4
    r=results.(names{i});
    m=error_metrics(x,r.fitted);
    MAE(i)=m.MAE; RMSE(i)=m.RMSE; MAPE(i)=m.MAPE; R2(i)=m.R2;
end
comparison=table(names,MAE,RMSE,MAPE,R2,'VariableNames',{'Model','MAE','RMSE','MAPE','R2'});
end
