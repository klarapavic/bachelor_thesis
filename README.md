
# Volatility Modeling of Dutch TTF Gas Futures

This repository contains the R code and scripts for my **Bachelor Thesis**, focusing on volatility modeling of the Dutch TTF (Title Transfer Facility) natural gas futures market. The project compares **classical GARCH models** with **Bayesian Stochastic Volatility (SV) models** to evaluate volatility dynamics, clustering, and forecasting performance.

---

## Methods

1. **Data Preprocessing**

   * Import daily futures data (EUR).
   * Transform raw price data into log returns.
   * Check stationarity with ADF tests.

2. **Exploratory Data Analysis (EDA)**

   * Plot price series and log returns.
   * Visualize volatility clustering.
   * Examine autocorrelation (ACF/PACF).

3. **Volatility Models**

   * **GARCH(1,1)**: estimated via maximum likelihood.
   * **Stochastic Volatility (SV)**: estimated with Bayesian MCMC (via `stochvol`).
   * Diagnostics include residual tests and QQ plots.

4. **Volatility Comparison**

   * Overlay estimated volatilities (GARCH vs SV) with confidence bands.
   * Compare against realized volatility (rolling window).

5. **Forecasting and Rolling Estimation**

   * One-step-ahead forecasts from both models.
   * Rolling window estimation to capture time variation.

---

## Example Output

* Volatility comparison plot (GARCH vs SV median with 5–95% bands).
* Rolling volatility forecasts across different window sizes.
* Summary tables of parameter estimates and diagnostics.

---

## Requirements

R packages used:

```r
libs <- c("tseries", "zoo", "fGarch", "scoringRules", 
          "ggplot2", "dplyr", "stochvol", "tidyr", "stargazer")
lapply(libs, library, character.only = TRUE)
```

Data: Bloomberg exports of Dutch TTF futures (not included due to license restrictions).

---

## Notes

* Results are part of my **Bachelor Thesis** (WU Vienna, 2024).
* Data is not included in this repo due to Bloomberg licensing.
* Code is provided for replicability and demonstration purposes.
