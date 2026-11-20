function T = compare_models(x,s,h)
% COMPARE_MODELS Run the six Chapter 4 models and compare their forecasts.
names={'sngbm','swbgm','dgstpm','nipsgmp','nipswbgm','ddvgstm'};
fns={@sngbm,@swbgm,@dgstpm,@nipsgmp,@nipswbgm,@ddvgstm};
T=table('Size',[numel(names) 4],'VariableTypes',{'string','double','double','double'}, ...
    'VariableNames',{'Model','MAPE_in_sample','RMSE_in_sample','ForecastMean'});
for i=1:numel(names)
    r=fns{i}(x,s,h); m=error_metrics(x(:),r.fitted(:));
    T.Model(i)=string(names{i}); T.MAPE_in_sample(i)=m.MAPE;
    T.RMSE_in_sample(i)=m.RMSE; T.ForecastMean(i)=mean(r.forecast);
end
end
