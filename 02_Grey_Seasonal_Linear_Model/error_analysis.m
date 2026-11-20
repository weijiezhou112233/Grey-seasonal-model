function A = error_analysis(actual, predicted, makePlots)
%ERROR_ANALYSIS Detailed residual analysis and optional diagnostic plots.
% A = error_analysis(actual,predicted,makePlots)
% Produces a table (when supported) and residual/relative-error vectors.
if nargin < 3 || isempty(makePlots), makePlots = true; end
M = error_metrics(actual,predicted);
a = actual(:); p = predicted(:);
ok = isfinite(a) & isfinite(p); a=a(ok); p=p(ok);
r = a-p;
A.metrics = rmfield(M, {'residual','relativeError'});
A.actual = a; A.predicted = p; A.residual = r;
A.relativeErrorPercent = M.relativeError;
A.meanResidual = mean(r);
A.residualStd = std(r,0);
A.maxAbsoluteError = max(abs(r));
A.minAbsoluteError = min(abs(r));
if exist('table','file') == 2 || exist('table','builtin') == 5
    A.detail = table((1:numel(a))',a,p,r,M.relativeError, ...
        'VariableNames',{'Index','Actual','Predicted','Residual','RelativeErrorPercent'});
else
    A.detail = [(1:numel(a))' a p r M.relativeError];
end
if makePlots
    figure('Name','Model error analysis');
    subplot(2,1,1); plot(a,'k-o','LineWidth',1.1); hold on;
    plot(p,'r--s','LineWidth',1.1); grid on;
    legend('Actual','Predicted','Location','best'); xlabel('Observation'); ylabel('Value');
    title('Actual and fitted values');
    subplot(2,1,2); stem(r,'filled'); hold on; yline(0,'k--'); grid on;
    xlabel('Observation'); ylabel('Residual'); title('Residual sequence');
end
end
