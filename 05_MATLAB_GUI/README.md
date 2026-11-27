# MATLAB Grey Seasonal Forecasting GUI

A graphical forecasting interface for the standalone MATLAB models in this repository.

## 1. Start the application

Download or clone the repository, then in MATLAB set the current folder to the repository root and run:

```matlab
cd('path/to/Grey-seasonal-model')
addpath(genpath(pwd))
GreySeasonalGUI
```

Alternatively, open `05_MATLAB_GUI/GreySeasonalGUI.m` and run `GreySeasonalGUI`.

**Requirements:** MATLAB R2019b or later. The GUI uses `uifigure`, `uigridlayout`, `uitable`, `readtable`, and `writetable`. Some individual models may require additional MATLAB functions described in their own folder documentation.

## 2. Main functions

- Import Excel (`.xlsx`, `.xls`) or CSV data.
- Paste/edit data directly in the table. The first column is a time label; subsequent columns are numeric series.
- Select a data series, model, seasonal period, forecast horizon, and holdout validation length.
- Calculate sample fitted values and future forecasts.
- Plot observed, fitted, and forecast values.
- Report holdout MAPE, MAE, RMSE and MSE.
- Export results to Excel and save the forecast chart as PNG.
- Provide descriptive time-trend, coefficient-of-variation and seasonal-lag-correlation diagnostics.

## 3. Models available

The GUI detects model files available on the MATLAB path and lists the repository's standalone models:

- Chapter 3 linear seasonal models: DGSM, CDGSM, DGSTM, DPDGSM, DPDGSTM, SDGM, DDVGSM, NIPDGSTM, NIPDDGSM.
- Chapter 4 nonlinear seasonal models: SNGBM, SWBGM, DGSTPM, NIPSGMP, NIPSWBGM, DDVGSTM.
- Chapter 5 coupled models: GSLSSVR, GSTLSSVR, NOFGHW, NCGHW.

The application uses the standalone model functions directly; it does not call `gseason.fit`. Function signatures are adapted by chapter according to the model files and their folder README files.

## 4. Validation and interpretation

The optional holdout length is used to fit the selected model on the earlier observations and forecast the final holdout block. MAPE, MAE, RMSE and MSE are calculated from that holdout block. The final model is then refitted to the full input series to generate the requested future forecast.

Feature diagnostics are descriptive and are not a statistical proof of linearity, nonlinearity, seasonality, or model suitability. The recommended DGSM is a baseline suggestion only; compare holdout errors before choosing a model.

Some models have model-specific data restrictions (for example, positive observations or minimum sample lengths). If a model rejects the data, check the error message and the model's own README.

## 5. Important research-use note

The GUI is an interface to the MATLAB model implementations in this repository. It does not certify that every model implementation has been independently validated against every equation in the manuscript. Consult each model folder's README and formula-audit notes, and run the provided tests in MATLAB before using outputs as research evidence or publication results.

## 6. Download

Use GitHub's **Code → Download ZIP** menu to download the complete repository, or download the GUI file directly:

[GreySeasonalGUI.m](https://github.com/weijiezhou112233/Grey-seasonal-model/blob/main/05_MATLAB_GUI/GreySeasonalGUI.m)
