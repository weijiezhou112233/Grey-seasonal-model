function plot_results(x,result)
% PLOT_RESULTS Plot observed, fitted and forecast values from a model result.
x=x(:); n=numel(x); h=numel(result.forecast);
figure('Color','w'); hold on; grid on;
plot(1:n,x,'ko-','LineWidth',1.2,'DisplayName','Observed');
plot(1:n,result.fitted,'b--','LineWidth',1.4,'DisplayName','Fitted');
plot(n+(1:h),result.forecast,'r*-','LineWidth',1.4,'DisplayName','Forecast');
xlabel('Time'); ylabel('Value'); title(result.model); legend('Location','best');
xline(n,':k','Forecast origin');
end
