function result = ddvgstm(x,s,h)
% DDVGSTM(1,1): discrete double-dummy-variable grey seasonal time-power model.
% Usage: result = ddvgstm(x, seasonalPeriod, forecastHorizon)
% Source basis: Chapter 4, equations (4.6.1)-(4.6.14).
x=validateSeries(x,s,h); x=x(:)'; n=numel(x); y=cumsum(x);
obj=@(g) fitGammaError(g,y,s);
gamma=fminsearch(obj,1,optimset('Display','off','MaxIter',600));
gamma=min(max(gamma,0.05),3);
[coef,yp]=fitGammaParams(gamma,y,s);
alpha=coef(1); beta=coef(2:1+s); delta=coef(2+s:end);
fit=[x(1),diff(yp)];
last=y(end); fc=zeros(1,h);
for j=1:h
 t=n+j-1; q=mod(t,s)+1;
 yn=alpha*last+beta(q)*(t^gamma)+delta(q);
 fc(j)=yn-last; last=yn;
end
result=localPack('DDVGSTM(1,1)',x,s,h,fit,fc,struct('alpha',alpha,'beta',beta(:),'delta',delta(:),'gamma',gamma),ones(1,s), ...
 struct('equation','h1(t+1)=alpha*h1(t)+beta_season*t^gamma+delta_season','optimizer','OLS conditional on gamma; gamma optimized by fminsearch'));
end
function val=fitGammaError(g,y,s)
if g<=0.05||g>=3, val=1e50; return; end
[~,yp]=fitGammaParams(g,y,s); r=y(2:end)'-yp(2:end)'; val=mean(r.^2);
end
function [coef,yp]=fitGammaParams(g,y,s)
n=numel(y); B=zeros(n-1,1+2*s);
for k=1:n-1
 q=mod(k,s)+1; B(k,1)=y(k); B(k,1+q)=k^g; B(k,1+s+q)=1;
end
target=y(2:end)'; coef=B\target; yp=y;
for k=1:n-1, yp(k+1)=B(k,:)*coef; end
end
function x=validateSeries(x,s,h)
if ~isnumeric(x)||~isvector(x)||numel(x)<max(6,s+2)||any(~isfinite(x(:)))||any(x(:)<=0), error('x must be a finite positive vector with at least max(6,s+2) values.'); end
if ~isscalar(s)||s<2||s~=floor(s), error('s must be an integer >=2.'); end
if ~isscalar(h)||h<1||h~=floor(h), error('h must be a positive integer.'); end
x=x(:)';
end

function [seasonal,adj] = localSeason(x,s)
n=numel(x); seasonal=ones(1,s);
mu=mean(x);
for j=1:s
    v=x(j:s:n);
    if isempty(v) || mean(v)<=0, seasonal(j)=1; else, seasonal(j)=mean(v)/mu; end
end
seasonal=seasonal/mean(seasonal);
adj=x./seasonal(mod(0:n-1,s)+1);
end

function root=localRoot(fun,x0)
% Positive-domain scalar root/minimum fallback for implicit one-step response.
lo=max(1e-10,0.05*x0); hi=max(2*x0+1,lo+1);
fl=fun(lo); fh=fun(hi);
for q=1:30
    if isfinite(fl)&&isfinite(fh)&&fl*fh<=0
        root=fzero(fun,[lo hi]); return
    end
    hi=hi*2; fh=fun(hi);
end
obj=@(z) safeSquare(fun(max(z,1e-10)));
root=fminsearch(obj,max(x0,1e-8),optimset('Display','off','MaxIter',300));
root=max(root,1e-10);
end

function v=safeSquare(x)
if ~isfinite(x), v=1e100; else, v=x.^2; end
end

function y=localSeasonRestore(xhat,season,s)
y=xhat.*season(mod(0:numel(xhat)-1,s)+1);
end

function out=localPack(name,x,s,h,fitAdj,fcAdj,par,season,extra)
fitAdj=fitAdj(:)'; fcAdj=fcAdj(:)';
fit=localSeasonRestore(fitAdj,season,s);
fc=localSeasonRestore(fcAdj,season,s);
out.model=name; out.period=s; out.horizon=h; out.fitted=fit(:);
out.forecast=fc(:); out.allPred=[fit(:);fc(:)];
out.parameters=par; out.seasonalIndex=season(:);
out.adjustedFitted=fitAdj(:); out.adjustedForecast=fcAdj(:);
out.details=extra;
end
