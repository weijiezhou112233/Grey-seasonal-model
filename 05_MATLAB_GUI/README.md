# MATLAB Grey Seasonal Forecasting GUI

A MATLAB desktop application for the standalone grey seasonal models in this repository. The GUI is the user interface; the model algorithms remain separate, independently callable `.m` files in the linear, nonlinear, and coupled model folders.

## 1. Start the application

Download or clone the complete repository. In MATLAB, set the current folder to the repository root and run:

```matlab
addpath(genpath(pwd));
GreySeasonalGUI
```

**Requirement:** MATLAB R2018b or later. The GUI avoids `uilabel.WordWrap` and `exportgraphics`, which are not available in R2018b. The GUI uses `uifigure`, `uigridlayout`, `uitable`, `readtable`, `writetable`, and `print` for chart export. Individual model implementations may have their own data restrictions.

## 2. Functions

- Import Excel (`.xlsx`, `.xls`) and CSV files.
- Edit or paste data directly into the table. The first column is a time label; subsequent columns are numeric series.
- Select one of multiple series.
- Select a model category: linear, nonlinear, or coupled; then select an individual model.
- Set seasonal period, forecast horizon, and holdout validation length.
- Configure common advanced parameters (`q`, `lambda`, and coupled-model optimization).
- Display original observations, fitted values, and future forecasts.
- Calculate holdout and in-sample MAPE, MAE, RMSE, and MSE.
- Export period-by-period actual/fitted/forecast values and APE to Excel.
- Export the forecast chart as PNG.
- Display descriptive trend, coefficient-of-variation, and seasonal-lag-correlation diagnostics.

## 3. Included model entries

**Linear seasonal models (9):** DGSM, CDGSM, DGSTM, DPDGSM, DPDGSTM, SDGM, DDVGSM, NIPDGSTM, NIPDDGSM.

**Nonlinear seasonal models (6):** SNGBM, SWBGM, DGSTPM, NIPSGMP, NIPSWBGM, DDVGSTM.

**Coupled models (4):** GSLSSVR, GSTLSSVR, NOFGHW, NCGHW.

The GUI checks whether each model function is available on the MATLAB path. It calls the standalone functions directly and does not use `gseason.fit`.

## 4. Model calling conventions

The GUI adapts the calls to the signatures in the repository:

- Chapter 3 linear models: `out = model(x, horizon, period, opts)`
- Chapter 4 nonlinear models: `out = model(x, period, horizon)`
- Chapter 5 coupled models: `out = model(x, horizon, period, opts)`

The GUI expects each model to return a structure containing `fitted` and `forecast` fields. If a model file is changed, its function signature and output fields must remain compatible or the adapter must be updated.

## 5. Validation and interpretation

If holdout length is greater than zero, the GUI fits the selected model to the earlier observations and forecasts the final holdout block. It calculates validation MAPE, MAE, RMSE, and MSE from the held-out observations. It then refits the selected model to the complete input series and generates the requested future forecast.

The feature diagnostics are descriptive indicators, not formal proof of linearity, nonlinearity, or seasonality. The DGSM button is a baseline-model suggestion, not an automatic claim that DGSM is optimal. Compare models on the same holdout observations before selecting a preferred model.

Model-specific data constraints still apply. For example, some nonlinear and Holt-Winters implementations require positive observations and a minimum sample length. Review the corresponding model file and README if an input is rejected.

## 6. Research-use note

The GUI is an interface to the model implementations in this repository. A successful GUI run does not by itself establish that a model has been independently validated against every equation in a manuscript. Verify the algorithms, input restrictions, and forecasting results in MATLAB before using them as research or publication evidence.

## 7. Download

Use GitHub's **Code → Download ZIP** menu to download the complete repository, or download [GreySeasonalGUI.m](https://github.com/weijiezhou112233/Grey-seasonal-model/blob/main/05_MATLAB_GUI/GreySeasonalGUI.m) directly.
