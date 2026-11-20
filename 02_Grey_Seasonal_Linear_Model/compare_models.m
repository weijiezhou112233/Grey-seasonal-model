function [comparison, results] = compare_models(x, h, s, opts)
%COMPARE_MODELS Fit all nine Chapter 3 models and compare in-sample errors.
% [comparison,results] = compare_models(x,h,s,opts)
if nargin < 2 || isempty(h), h=1; end
if nargin < 3 || isempty(s), s=4; end
if nargin < 4 || isempty(opts), opts=struct(); end
names = {'dgsm','cdgsm','dgstm','dpdgsm','dpdgstm','sdgm','ddvgsm','nipdgstm','nipddgsm'};
results = struct();
rows = cell(numel(names),1);
for k=1:numel(names)
    nm=names{k};
    try
        r=feval(nm,x,h,s,opts);
        results.(nm)=r;
        m=error_metrics(x,r.fitted);
        rows{k}={upper(nm),m.MAE,m.MSE,m.RMSE,m.MAPE,m.MPE,m.sMAPE,m.R2,'OK'};
    catch ME
        results.(nm)=struct('error',ME.message);
        rows{k}={upper(nm),NaN,NaN,NaN,NaN,NaN,NaN,NaN,ME.message};
    end
end
if exist('table','file') == 2 || exist('table','builtin') == 5
    comparison=cell2table(vertcat(rows{:}), 'VariableNames', ...
        {'Model','MAE','MSE','RMSE','MAPE_percent','MPE_percent','sMAPE_percent','R2','Status'});
else
    comparison=rows;
end
end
