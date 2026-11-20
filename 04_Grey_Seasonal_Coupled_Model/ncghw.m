function result = ncghw(x,h,s,opts)
% NCGHW  New-information-priority periodic grey Holt-Winters model.
% Periodic priority AGO (manuscript Definition 6):
% z(t)=sum_{i=floor((t-1)/s)*s+1}^t mu^(t-i)*x(i).
% Inverse: x(t)=z(t) at the first position of a seasonal block;
% otherwise x(t)=z(t)-mu*z(t-1).
% Holt-Winters states follow Eq. (5.4.1), initial states Eq. (5.4.2),
% forecast Eq. (5.4.3), and inverse Eq. (5.4.4).
% Usage: result = ncghw(x,h,s,opts)
% opts: optimize (default true), initialParams=[mu alpha beta gamma],
%       maxIter, memory. Optimizer is toolbox-free finite-difference L-BFGS.

if nargin<4 || isempty(opts), opts=struct(); end
x=x(:); n=numel(x);
if nargin<2 || isempty(h), h=1; end
if nargin<3 || isempty(s), error('Seasonal period s is required.'); end
if any(~isfinite(x)) || any(x<=0), error('NCGHW requires finite positive observations.'); end
if s<1 || s~=floor(s) || n<s+2, error('Invalid seasonal period or insufficient observations.'); end
if h<0 || h~=floor(h), error('h must be a nonnegative integer.'); end

optimize=getopt(opts,'optimize',true);
p0=getopt(opts,'initialParams',[0.8 0.3 0.2 0.3]);
maxIter=getopt(opts,'maxIter',60);
memory=getopt(opts,'memory',7);
u0=encode_params(p0);
if optimize
    fun=@(u)objective(u,x,s);
    [uopt,fval,iterations]=lbfgs_fd(fun,u0,maxIter,memory);
else
    uopt=u0; fval=objective(u0,x,s); iterations=0;
end
par=decode_params(uopt);
[fitted,forecast,states]=run_ncghw(x,h,s,par);
result.model='NCGHW';
result.fitted=fitted;
result.forecast=forecast;
result.residuals=x-fitted;
result.parameters=struct('mu',par(1),'alpha',par(2),'beta',par(3),'gamma',par(4));
result.states=states;
result.objective=fval;
result.optimizer=struct('method','finite-difference L-BFGS with Armijo backtracking','iterations',iterations);
result.metrics=error_metrics(x,fitted);
end

function f=objective(u,x,s)
p=decode_params(u);
try
    [fit,~,~]=run_ncghw(x,0,s,p);
    idx=(s+1:numel(x))';
    if isempty(idx), f=1e20; return; end
    e=(x(idx)-fit(idx))/max(mean(abs(x)),eps);
    f=mean(e.^2);
    if ~isfinite(f), f=1e20; end
catch
    f=1e20;
end
end

function [fit,forecast,st]=run_ncghw(x,h,s,p)
n=numel(x); mu=p(1); a=p(2); b=p(3); g=p(4);
z=priority_periodic_ago(x,mu,s);
S=nan(n+h,1); B=nan(n+h,1); C=nan(n+h+s,1);
av=mean(z(1:s)); if abs(av)<eps, av=eps; end
C(1:s)=z(1:s)/av;
S(1:s)=z(1:s);
if n>=2*s
    B(s)=mean(z(s+1:2*s)-z(1:s))/s;
else
    B(s)=mean(diff(z(1:s)));
end
for k=1:s-1, B(k)=B(s); end
zfit=z;
for k=s+1:n
    zfit(k)=(S(k-1)+B(k-1))*C(k-s);
    % The minus sign in the level recursion is retained from Eq. (5.4.1).
    S(k)=a*z(k)/safe_den(C(k-s))+(1-a)*(S(k-1)-B(k-1));
    B(k)=b*(S(k)-S(k-1))+(1-b)*B(k-1);
    C(k)=g*z(k)/safe_den(S(k))+(1-g)*C(k-s);
end
for j=1:h
    k=n+j; seas=mod(k-1,s)+1;
    zfit(k)=(S(n)+j*B(n))*C(seas);
end
allz=[z;zfit(n+1:n+h)];
xall=priority_periodic_iago(allz,mu,s);
xfitted=priority_periodic_iago(zfit(1:n),mu,s);
fit=nan(n,1); fit(s+1:n)=xfitted(s+1:n);
forecast=xall(n+1:end);
st=struct('transformed',z,'level',S(1:n),'trend',B(1:n),'seasonal',C(1:n));
end

function z=priority_periodic_ago(x,mu,s)
n=numel(x); z=zeros(n,1);
for t=1:n
    first=floor((t-1)/s)*s+1;
    for i=first:t
        z(t)=z(t)+mu^(t-i)*x(i);
    end
end
end

function x=priority_periodic_iago(z,mu,s)
n=numel(z); x=zeros(n,1);
for t=1:n
    first=floor((t-1)/s)*s+1;
    if t==first, x(t)=z(t); else, x(t)=z(t)-mu*z(t-1); end
end
end

function d=safe_den(x)
if abs(x)<1e-10, d=sign(x+eps)*1e-10; else, d=x; end
end

function p=decode_params(u)
v=1./(1+exp(-max(min(u,35),-35)));
p=0.001+0.998*v;
end

function u=encode_params(p)
p=p(:)'; v=(p-0.001)/0.998; v=max(min(v,0.999),0.001); u=log(v./(1-v));
end

function [x,f,iter]=lbfgs_fd(fun,x,mx,m)
x=x(:); f=fun(x); g=fdgrad(fun,x); S={}; Y={}; R=[]; iter=0;
for k=1:mx
    iter=k;
    if norm(g)<1e-5, break; end
    q=g; al=zeros(numel(S),1);
    for i=numel(S):-1:1
        al(i)=R(i)*(S{i}'*q); q=q-al(i)*Y{i};
    end
    if isempty(S), H=1; else, H=(S{end}'*Y{end})/(Y{end}'*Y{end}+eps); end
    z=H*q;
    for i=1:numel(S)
        be=R(i)*(Y{i}'*z); z=z+S{i}*(al(i)-be);
    end
    d=-z;
    if g'*d>=0, d=-g; end
    step=1; gd=g'*d;
    for ls=1:25
        xn=x+step*d; fn=fun(xn);
        if isfinite(fn)&&fn<=f+1e-4*step*gd, break; end
        step=step/2;
    end
    if step<1e-8, break; end
    gn=fdgrad(fun,xn); sv=xn-x; yv=gn-g; sy=sv'*yv;
    if sy>1e-12
        S{end+1}=sv; Y{end+1}=yv; R(end+1)=1/sy;
        if numel(S)>m, S(1)=[]; Y(1)=[]; R(1)=[]; end
    end
    x=xn; f=fn; g=gn;
end
end

function g=fdgrad(fun,x)
g=zeros(size(x)); h=1e-5;
for i=1:numel(x)
    xp=x; xm=x; xp(i)=xp(i)+h; xm(i)=xm(i)-h;
    g(i)=(fun(xp)-fun(xm))/(2*h);
end
end

function v=getopt(o,k,d)
if isfield(o,k)&&~isempty(o.(k)), v=o.(k); else, v=d; end
end
