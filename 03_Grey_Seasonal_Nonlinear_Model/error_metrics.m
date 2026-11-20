function M = error_metrics(actual,predicted)
% ERROR_METRICS Calculate MAE, RMSE, MAPE and sMAPE.
actual=actual(:); predicted=predicted(:);
if numel(actual)~=numel(predicted), error('Inputs must have equal lengths.'); end
e=predicted-actual;
nz=abs(actual)>eps;
if any(nz), mape=mean(abs(e(nz)./actual(nz)))*100; else, mape=NaN; end
den=abs(actual)+abs(predicted); q=den>eps;
if any(q), smape=mean(2*abs(e(q))./den(q))*100; else, smape=NaN; end
M=struct('MAE',mean(abs(e)),'RMSE',sqrt(mean(e.^2)),'MAPE',mape,'sMAPE',smape);
end
