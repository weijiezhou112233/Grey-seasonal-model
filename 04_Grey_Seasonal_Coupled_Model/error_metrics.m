function M = error_metrics(actual,predicted)
% ERROR_METRICS  Error indicators for fitted or forecast values.
% NaN entries (e.g. initialization periods) are excluded automatically.
a=actual(:); p=predicted(:);
if numel(a)~=numel(p), error('actual and predicted must have equal lengths.'); end
ok=isfinite(a)&isfinite(p);
a=a(ok); p=p(ok);
if isempty(a), error('No finite pairs available for error evaluation.'); end
e=a-p;
nz=abs(a)>eps;
if any(nz), ape=abs(e(nz)./a(nz))*100; mpe=mean(e(nz)./a(nz))*100; mape=mean(ape);
else, ape=NaN; mpe=NaN; mape=NaN; end
M=struct();
M.N=numel(a);
M.MAE=mean(abs(e));
M.MSE=mean(e.^2);
M.RMSE=sqrt(M.MSE);
M.SSE=sum(e.^2);
M.MAPE=mape;
M.MPE=mpe;
M.R2=1-sum(e.^2)/(sum((a-mean(a)).^2)+eps);
M.APE=ape;
end
