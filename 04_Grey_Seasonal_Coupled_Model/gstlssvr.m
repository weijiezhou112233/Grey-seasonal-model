function result = gstlssvr(x,h,s,opts)
% GSTLSSVR  Grey Seasonal Trend Least-Squares Support Vector Regression.
% Usage: result = gstlssvr(x,h,s,opts)
% Implements manuscript Eq. (5.2.1):
% X1(k+1)=w'*phi(X1(k))+beta_M(k+1,s)+b*k+e(k+1).
% AGO, seasonal dummy variables, linear time trend and LS-SVR kernel are
% estimated together. Hyperparameters are selected by last-block validation.

if nargin < 4 || isempty(opts), opts=struct(); end
x=x(:); n=numel(x);
if nargin<2 || isempty(h), h=1; end
if nargin<3 || isempty(s), error('Seasonal period s is required.'); end
if any(~isfinite(x)) || n<max(6,s+2), error('Insufficient or nonfinite observations.'); end
if s<1 || s~=floor(s), error('s must be a positive integer.'); end
if h<0 || h~=floor(h), error('h must be a nonnegative integer.'); end

optimize=getopt(opts,'optimize',true);
kernelOpt=getopt(opts,'kernel','auto');
penaltyGrid=getopt(opts,'penaltyGrid',[0.1 1 10 100]);
sigmaGrid=getopt(opts,'sigmaGrid',[0.5 1 2 5]);
penalty=getopt(opts,'penalty',10);
sigma=getopt(opts,'sigma',1);
lastBlock=getopt(opts,'lastBlock',min(max(s,ceil(0.2*n)),max(1,n-s-2)));
best=struct('kernel',kernelOpt,'penalty',penalty,'sigma',sigma,'score',NaN);

if optimize
    nv=min(lastBlock,n-s-2);
    if nv>=1
        xtr=x(1:n-nv); xv=x(n-nv+1:end);
        if strcmpi(kernelOpt,'auto'), kernels={'linear','rbf'}; else, kernels={lower(kernelOpt)}; end
        best.score=Inf;
        for ik=1:numel(kernels)
            if strcmp(kernels{ik},'linear'), sigmas=1; else, sigmas=sigmaGrid; end
            for ip=1:numel(penaltyGrid)
                for isg=1:numel(sigmas)
                    try
                        mdl=train_model(xtr,s,kernels{ik},penaltyGrid(ip),sigmas(isg));
                        pred=forecast_model(mdl,numel(xtr),numel(xv),s);
                        sc=sqrt(mean((pred-xv).^2))/max(mean(abs(xv)),eps);
                        if isfinite(sc) && sc<best.score
                            best=struct('kernel',kernels{ik},'penalty',penaltyGrid(ip),'sigma',sigmas(isg),'score',sc);
                        end
                    catch
                    end
                end
            end
        end
    end
end
if ~isfield(best,'kernel') || strcmpi(best.kernel,'auto')
    best.kernel='rbf'; best.penalty=penalty; best.sigma=sigma;
end
mdl=train_model(x,s,best.kernel,best.penalty,best.sigma);
[fitted,forecast,zfit]=predict_full(mdl,x,h,s);
result.model='GSTLSSVR';
result.fitted=fitted;
result.forecast=forecast;
result.residuals=x-fitted;
result.beta=struct('dual',mdl.alpha,'seasonal',mdl.coef(1:s),'trend',mdl.coef(end));
result.parameters=struct('kernel',best.kernel,'penalty',best.penalty,'sigma',best.sigma);
result.level_fitted=zfit;
result.validation_score=best.score;
result.metrics=error_metrics(x,fitted);
end

function mdl=train_model(x,s,kernel,penalty,sigma)
x=x(:); z=cumsum(x); N=numel(x)-1;
X=z(1:N); Y=z(2:N+1); t=(1:N)';
H=season_matrix((2:N+1)',s);
H=[H t];
K=kernel_matrix(X,X,kernel,sigma);
A=[K+eye(N)/penalty H; H' zeros(size(H,2))];
rhs=[Y;zeros(size(H,2),1)];
if rcond(A)<1e-12, sol=pinv(A)*rhs; else, sol=A\rhs; end
mdl.X=X; mdl.alpha=sol(1:N); mdl.coef=sol(N+1:end);
mdl.kernel=kernel; mdl.sigma=sigma; mdl.penalty=penalty; mdl.lastLevel=z(end);
end

function [fitted,forecast,zfit]=predict_full(mdl,x,h,s)
x=x(:); z=cumsum(x); n=numel(x);
zfit=nan(n,1); zfit(1)=z(1);
for k=1:n-1, zfit(k+1)=predict_level(mdl,z(k),k+1,s); end
fitted=nan(n,1); fitted(2:n)=diff(zfit);
zcur=z(end); forecast=zeros(h,1);
for j=1:h
    zn=predict_level(mdl,zcur,n+j,s);
    forecast(j)=zn-zcur; zcur=zn;
end
end

function pred=forecast_model(mdl,n,h,s)
zcur=mdl.lastLevel; pred=zeros(h,1);
for j=1:h
    zn=predict_level(mdl,zcur,n+j,s);
    pred(j)=zn-zcur; zcur=zn;
end
end

function y=predict_level(mdl,zcur,targetT,s)
if strcmpi(mdl.kernel,'linear'), kval=mdl.X*zcur;
else, kval=exp(-((mdl.X-zcur).^2)/(2*mdl.sigma^2)); end
row=zeros(1,s); row(mod(targetT-1,s)+1)=1;
row=[row targetT-1];
y=kval'*mdl.alpha+row*mdl.coef;
end

function K=kernel_matrix(a,b,kernel,sigma)
a=a(:); b=b(:)';
if strcmpi(kernel,'linear'), K=a*b;
elseif strcmpi(kernel,'rbf'), K=exp(-((a-b).^2)/(2*sigma^2));
else, error('kernel must be linear or rbf.'); end
end

function H=season_matrix(t,s)
H=zeros(numel(t),s);
for i=1:numel(t), H(i,mod(t(i)-1,s)+1)=1; end
end

function v=getopt(o,k,d)
if isfield(o,k)&&~isempty(o.(k)), v=o.(k); else, v=d; end
end
