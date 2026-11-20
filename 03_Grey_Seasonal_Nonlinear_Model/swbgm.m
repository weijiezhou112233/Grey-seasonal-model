function result = swbgm(x,s,h)
% SWBGM(1,1): seasonal Weibull-Bernoulli grey model.
% Usage: result = swbgm(x, seasonalPeriod, forecastHorizon)
% Source basis: Chapter 4, equations (4.2.1)-(4.2.16); u,v are optimized.
x=validateSeries(x,s,h); x=x(:)'; [season,xa]=localSeason(x,s);
n=numel(xa); y=cumsum(xa); t=(2:n)';
obj=@(q) fitShapeError(q,y,xa,t);
q=fminsearch(obj,[0.8 1.2],optimset('Display','off','MaxIter',600));
u=min(max(q(1),0.15),2.5); v=min(max(q(2),0.15),2.5);
[a,b,fitAdj]=fitShapeParams([u v],y,xa,t);
last=y(end); fcAdj=zeros(1,h);
for j=1:h
    k=n+j; fac=u*k^(u-1);
    fun=@(yn) ((yn-last)/fac)+a*max(0.5*(yn+last),1e-10)^u-b*max(0.5*(yn+last),1e-10)^v;
    yn=localRoot(fun,max(last,1e-8)); fcAdj(j)=yn-last; last=yn;
end
result=localPack('SWBGM(1,1)',x,s,h,fitAdj,fcAdj,struct('a',a,'b',b,'u',u,'v',v),season, ...
    struct('equation','x0(k)/(u*k^(u-1)) + a*z(k)^u = b*z(k)^v','optimizer','fminsearch for u,v; OLS for a,b'));
end
function val=fitShapeError(q,y,xa,t)
u=q(1); v=q(2);
if u<=0.15||u>=2.5||v<=0.15||v>=2.5, val=1e50; return; end
z=0.5*(y(2:end)+y(1:end-1)); lhs=xa(2:end)./(u*t'.^(u-1));
A=[-max(z(:),1e-10).^u, max(z(:),1e-10).^v]; rhs=lhs(:);
p=A\rhs; r=A*p-rhs; val=mean(r.^2);
end
function [a,b,fit]=fitShapeParams(q,y,xa,t)
u=q(1); v=q(2); z=0.5*(y(2:end)+y(1:end-1));
lhs=xa(2:end)./(u*t'.^(u-1)); A=[-max(z(:),1e-10).^u,max(z(:),1e-10).^v]; rhs=lhs(:);
p=A\rhs; a=p(1); b=p(2); fit=zeros(1,numel(xa)); fit(1)=xa(1);
fit(2:end)=(u*t'.^(u-1).*(-a*z.^u+b*z.^v));
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
