# MATLAB Grey Seasonal Forecasting GUI

## Run
Requires MATLAB R2019b or later.

1. Download `GreySeasonalGUI.m`.
2. Set MATLAB Current Folder to the downloaded directory.
3. Run:

```matlab
GreySeasonalGUI
```

## Features
- Import Excel/CSV data or paste data into the editable table.
- First column is the time label; remaining columns are numeric series.
- Select a series, seasonal period, forecast horizon and holdout length.
- View original, fitted and forecast curves.
- Report MAPE, MAE, RMSE and MSE for the optional holdout evaluation.
- Export forecast table to Excel and chart to PNG.

## Model status — read before interpreting results
The current selectable DGSM entry is explicitly a **seasonal-subseries GM(1,1) demonstration prototype**. It fits a separate GM(1,1) to each seasonal-position subsequence. It has not been verified against the exact equations of the book-specific DGSM(1,1) model, and must not be represented as a faithful reproduction of that model.

The repository currently did not contain a confirmed DGSM source file when this GUI was added. Before using it for research conclusions or publishing results, replace the prototype in the local helper `seasonalGM` / `gmFit` with the verified model equations and validate against test data.

## Limitations
- MATLAB R2019b+ required.
- Current demonstration model requires positive data and at least two observations for every seasonal position.
- Feature analysis is descriptive and does not automatically prove a model is suitable.
- MAPE can be misleading around zero; zero actual values are not supported by the current positive-data prototype.
