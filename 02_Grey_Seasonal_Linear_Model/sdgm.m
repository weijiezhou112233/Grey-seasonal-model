function out = sdgm(x,h,s,opts)
%SDGM Standalone implementation of SDGM(1,1).
% Usage: out = sdgm(x,h,s,opts)
% x: observed data vector; h: forecast horizon; s: seasonal period.
% opts.q: local accumulation window (DPD models, default 3).
% opts.lambda: new-information accumulation weight (NIP models, default 0.9).
% This file is self-contained and does not call gseason.fit or other model files.

if nargin < 2 || isempty(h), h = 1; end
if nargin < 3 || isempty(s), s = 4; end
if nargin < 4 || isempty(opts), opts = struct(); end
if ~isfield(opts,'q') || isempty(opts.q), opts.q = min(3,max(1,floor(numel(x)/3))); end
if ~isfield(opts,'lambda') || isempty(opts.lambda), opts.lambda = 0.9; end

x = x(:);
if ~isnumeric(x) || ~isreal(x) || isempty(x) || any(~isfinite(x))
    error('x must be a nonempty finite real numeric vector.');
end
if any(x < 0), error('This implementation requires nonnegative observations.'); end
if ~isscalar(h) || h < 1 || h ~= floor(h), error('h must be a positive integer.'); end
if ~isscalar(s) || s < 1 || s ~= floor(s), error('s must be a positive integer.'); end
if numel(x) < 3, error('At least three observations are required.'); end

out = local_fit_sdgm(x,h,s,opts);
out.model = 'SDGM';
out.options = opts;
out.seasonLength = s;
out.n = numel(x);
out.h = h;
out.metrics = local_metrics_sdgm(x,out.fitted);
end

function out = local_fit_sdgm(x,h,s,opts)
n = numel(x);
model = 'SDGM';
if strcmp(model,'CDGSM')
    % Seasonal-block cumulative transform, logarithmic transform and AGO.
    z = local_cycleAGO_sdgm(x,s);
    v = log(max(z,eps));
    vAgo = cumsum(v);
    inner = local_regfit_sdgm(vAgo,h,s,'DGSM');
    vhat = [inner.allLevel(1); diff(inner.allLevel)];
    zhat = exp(vhat);
    pred = local_cycleIAGO_sdgm(zhat,n,h,s);
    out = inner;
    out.transformed = z;
    out.allLevel = zhat;
    out.fitted = pred(1:n);
    out.forecast = pred(n+1:end);
else
    if any(strcmp(model,{'DPDGSM','DPDGSTM'}))
        z = local_localAGO_sdgm(x,opts.q);
    elseif any(strcmp(model,{'NIPDGSTM','NIPDDGSM'}))
        z = local_nipAGO_sdgm(x,opts.lambda);
    else
        z = cumsum(x);
    end
    inner = local_regfit_sdgm(z,h,s,model);
    if any(strcmp(model,{'DPDGSM','DPDGSTM'}))
        xhat = local_localIAGO_sdgm(inner.allLevel,opts.q);
    elseif any(strcmp(model,{'NIPDGSTM','NIPDDGSM'}))
        xhat = local_nipIAGO_sdgm(inner.allLevel,opts.lambda);
    else
        xhat = [inner.allLevel(1); diff(inner.allLevel)];
    end
    out = inner;
    out.transformed = z;
    out.allLevel = inner.allLevel;
    out.fitted = xhat(1:n);
    out.forecast = xhat(n+1:end);
end
end

function out = local_regfit_sdgm(z,h,s,model)
z = z(:); n = numel(z);
k = (2:n)';
lag = z(1:n-1);
season = mod(k-1,s)+1;
D = zeros(n-1,max(0,s-1));
for j=1:s-1, D(:,j) = (season==j); end
T = (k-1)/max(n-1,1);
switch upper(model)
    case {'DGSM','SDGM','DPDGSM'}
        X = [lag,ones(n-1,1),D];
    case {'DGSTM','DPDGSTM','NIPDGSTM'}
        X = [lag,T,ones(n-1,1),D];
    case {'DDVGSM','NIPDDGSM'}
        X = [lag,T,lag.*D,ones(n-1,1),D];
    otherwise
        error('Unsupported model structure: %s',model);
end
theta = pinv(X)*z(2:n);
N = n+h; level = zeros(N,1); level(1)=z(1);
for t=2:N
    st = mod(t-1,s)+1;
    d = zeros(1,max(0,s-1));
    for j=1:s-1, d(j) = (st==j); end
    tt = (t-1)/max(n-1,1);
    switch upper(model)
        case {'DGSM','SDGM','DPDGSM'}
            row = [level(t-1),1,d];
        case {'DGSTM','DPDGSTM','NIPDGSTM'}
            row = [level(t-1),tt,1,d];
        case {'DDVGSM','NIPDDGSM'}
            row = [level(t-1),tt,level(t-1)*d,1,d];
    end
    level(t) = row*theta;
end
out.theta = theta;
out.design = X;
out.levelFitted = level(1:n);
out.allLevel = level;
out.forecastLevel = level(n+1:end);
out.residual = z(2:n)-X*theta;
end

function z = local_localAGO_sdgm(x,q)
q = max(1,min(numel(x),round(q))); z=zeros(size(x));
for k=1:numel(x), z(k)=sum(x(max(1,k-q+1):k)); end
end

function x = local_localIAGO_sdgm(z,q)
q=max(1,round(q)); x=zeros(size(z)); x(1)=z(1);
for k=2:numel(z)
    if k<=q, x(k)=z(k)-z(k-1); else, x(k)=z(k)-z(k-1)+x(k-q); end
end
end

function z = local_nipAGO_sdgm(x,lambda)
if ~isscalar(lambda) || ~isfinite(lambda), error('opts.lambda must be finite scalar.'); end
z=zeros(size(x)); z(1)=x(1);
for k=2:numel(x), z(k)=lambda*z(k-1)+x(k); end
end

function x = local_nipIAGO_sdgm(z,lambda)
x=zeros(size(z)); x(1)=z(1);
for k=2:numel(z), x(k)=z(k)-lambda*z(k-1); end
end

function z = local_cycleAGO_sdgm(x,s)
x=x(:); n=numel(x); z=zeros(n,1);
for k=1:n
    first=floor((k-1)/s)*s+1;
    z(k)=sum(x(first:k));
end
end

function x = local_cycleIAGO_sdgm(z,n,h,s)
z=z(:); N=n+h; x=zeros(N,1);
for k=1:N
    if mod(k-1,s)==0
        x(k)=z(k);
    else
        x(k)=z(k)-z(k-1);
    end
end
end

function M = local_metrics_sdgm(a,p)
a=a(:); p=p(:); if numel(a)~=numel(p), error('Metric vectors must have equal lengths.'); end
ok=isfinite(a)&isfinite(p); a=a(ok); p=p(ok); e=a-p;
M.N=numel(a); M.MAE=mean(abs(e)); M.MSE=mean(e.^2); M.RMSE=sqrt(M.MSE); M.SSE=sum(e.^2);
nzv=abs(a)>eps;
if any(nzv), M.MAPE=mean(abs(e(nzv))./abs(a(nzv)))*100; M.MPE=mean(e(nzv)./a(nzv))*100; else, M.MAPE=NaN; M.MPE=NaN; end
D=abs(a)+abs(p); v=D>eps; if any(v), M.sMAPE=mean(2*abs(e(v))./D(v))*100; else, M.sMAPE=NaN; end
sst=sum((a-mean(a)).^2); if sst>eps, M.R2=1-M.SSE/sst; else, M.R2=NaN; end
end
