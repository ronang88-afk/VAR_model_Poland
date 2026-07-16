# VAR_model_Poland
This project performs a Vector Autoregression (VAR) analysis to investigate the dynamic relationship between **Gross Domestic Product (GDP)** and **Unemployment** in Poland over the period 1996 Q3 – 2024 Q4.

The analysis includes:

- Exploratory data visualisation (scatter plot, time series plot)
- Ordinary Least Squares (OLS) regression (static relationship)
- Autocorrelation (ACF) and partial autocorrelation (PACF) to assess persistence
- VAR model estimation with lag selection
- Diagnostic checks (serial correlation, heteroscedasticity, normality, structural stability)
- Granger causality tests
- Impulse Response Functions (IRF) and Forecast Error Variance Decomposition (FEVD)
- Out‑of‑sample forecasts with fan charts

All plots and console outputs are automatically saved for reproducibility.

---

## Data

The dataset `yt1.csv` contains quarterly observations of:

- **GDP**: Real Gross Domestic Product (index, 2015 = 100? or levels – adjust as needed)
- **Unemployment**: Registered unemployment rate (%)

The sample runs from **1996 Q3 to 2024 Q4**. There are 8 missing values for unemployment in the final quarters; these are linearly interpolated using `zoo::na.approx`.

**Note**: The data file is included in the repository. For confidentiality, you may need to replace it with public data (e.g., from Eurostat or the Polish Central Statistical Office).

---

## Results:

OLS shows a strong negative correlation, but this is likely spurious due to non‑stationarity.

VAR(10) fits the data extremely well (R² > 0.98), but the cross‑equation lags are mostly insignificant.

No Granger causality – unemployment does not help predict GDP, and GDP does not help predict unemployment.

IRFs and FEVD confirm that the two series are largely driven by their own past innovations.

The model is diagnostically sound (no serial correlation, no heteroscedasticity, stable coefficients), though residuals are not normally distributed (common in macro time series).

Implication: Despite a contemporaneous correlation, there is no dynamic predictive relationship between GDP and unemployment in Poland over this period.

---

## Requirements

The analysis is written in **R version 4.5.2** (or later) and requires the following packages:

- `urca`      – for unit root tests (if extended)
- `vars`      – for VAR modelling
- `tseries`   – for time series diagnostics
- `forecast`  – for forecasting and fan charts
- `tidyverse` – for data manipulation and ggplot2 graphics
- `zoo`       – for linear interpolation of missing values

Install them with:

```r
install.packages(c("urca", "vars", "tseries", "forecast", "tidyverse", "zoo"))


