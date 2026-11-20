function plot_results(x,result)
% PLOT_RESULTS  Plot actual values, fitted values, forecasts and residuals.
x=x(:); n=numel(x); h=numel(result.forecast);
figure;
subplot(2,1,1);
plot(1:n,x,'ko-','LineWidth',1.1); hold on;
plot(1:n,result.fitted,'b.-','LineWidth',1.1);
plot(n+(1:h),result.forecast,'r*-','LineWidth',1.1);
grid on; xlabel('Time'); ylabel('Value');
legend('Actual','Fitted','Forecast','Location','best');
title(result.model);
subplot(2,1,2);
plot(1:n,result.residuals,'k.-'); hold on; plot([1 n],[0 0],'r--');
grid on; xlabel('Time'); ylabel('Residual');
title('Residual analysis');
end
