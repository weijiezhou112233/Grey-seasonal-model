function plot_results(actual, predicted, modelName)
%PLOT_RESULTS Plot actual/predicted series and residuals.
if nargin < 3 || isempty(modelName), modelName='Model'; end
a=actual(:); p=predicted(:);
if numel(a)~=numel(p), error('actual and predicted must have equal lengths.'); end
figure('Name',[char(modelName) ' results']);
subplot(2,1,1); plot(a,'k-o','LineWidth',1.2); hold on;
plot(p,'r--s','LineWidth',1.2); grid on;
legend('Actual','Predicted','Location','best'); xlabel('Observation'); ylabel('Value');
title([char(modelName) ': actual vs predicted']);
subplot(2,1,2); stem(a-p,'filled'); hold on; yline(0,'k--'); grid on;
xlabel('Observation'); ylabel('Residual'); title('Residuals');
end
