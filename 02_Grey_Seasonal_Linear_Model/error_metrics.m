function M = error_metrics(actual, predicted)
%ERROR_METRICS Calculate common forecast error measures.
% M = error_metrics(actual,predicted)
% Returns MAE, MSE, RMSE, SSE, MAPE(%), MPE(%), sMAPE(%), and R2.
% MAPE/MPE exclude observations whose actual value is zero.

if ~isnumeric(actual) || ~isnumeric(predicted) || ~isreal(actual) || ~isreal(predicted)
    error('Inputs must be real numeric vectors.');
end
if ~isvector(actual) || ~isvector(predicted) || numel(actual) ~= numel(predicted)
    error('actual and predicted must be vectors of equal length.');
end
a = actual(:); p = predicted(:);
ok = isfinite(a) & isfinite(p);
a = a(ok); p = p(ok);
if isempty(a), error('No finite paired observations are available.'); end
e = a-p;
M.N = numel(a);
M.MAE = mean(abs(e));
M.MSE = mean(e.^2);
M.RMSE = sqrt(M.MSE);
M.SSE = sum(e.^2);
nonzero = abs(a) > eps;
if any(nonzero)
    M.MAPE = mean(abs(e(nonzero))./abs(a(nonzero)))*100;
    M.MPE = mean(e(nonzero)./a(nonzero))*100;
    M.MAPE_N = sum(nonzero);
else
    M.MAPE = NaN; M.MPE = NaN; M.MAPE_N = 0;
end
den = abs(a)+abs(p);
valid = den > eps;
if any(valid)
    M.sMAPE = mean(2*abs(e(valid))./den(valid))*100;
else
    M.sMAPE = NaN;
end
sst = sum((a-mean(a)).^2);
if sst > eps
    M.R2 = 1 - M.SSE/sst;
else
    M.R2 = NaN;
end
M.residual = e;
M.relativeError = NaN(size(e));
M.relativeError(nonzero) = e(nonzero)./a(nonzero)*100;
end
