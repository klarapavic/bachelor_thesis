# -----------------------------------------------------------------------------
# Bachelor Thesis: Gas Price Volatility in Europe - A Comperative Modeling Study
# Author: Klara Pavic
# Date: February 2024
# -----------------------------------------------------------------------------

libs <- c("tseries", "zoo", "fGarch", "scoringRules", 
          "ggplot2", "dplyr", "stochvol", "tidyr", "stargazer")
lapply(libs, library, character.only = TRUE)

# -----------------------------------------------------------------------------
# 1. Load and Prepare Data
# -----------------------------------------------------------------------------

# Dutch TTF front-month futures (Bloomberg: FJSG4 Comdty)
ttf <- read.csv2("DUTCH2.1.csv")

# Parse dates and clean prices
ttf$Dates <- as.Date(ttf$Dates, format = "%d.%m.%Y")
ttf$LAST_PRICE <- as.numeric(gsub(",", ".", ttf$LAST_PRICE))

# Order chronologically
ttf <- ttf[order(ttf$Dates), ]
rownames(ttf) <- seq_len(nrow(ttf))

# Convert to xts time series
ts_ttf <- xts::xts(ttf$LAST_PRICE, order.by = ttf$Dates)

# -----------------------------------------------------------------------------
# 2. Exploratory Data Analysis
# -----------------------------------------------------------------------------

# Plot raw price series
plot(ttf$Dates, ts_ttf, type = "l", col = "black",
     xlab = "Year", ylab = "Last Price",
     main = "Daily EUR TTF Futures Prices")

# Highlight peak price (Aug 2022)
abline(v = ttf$Dates[which.max(ts_ttf)], col = "red", lwd = 0.5)

# Compute log returns
daily_log_ttf <- na.omit(diff(log(ts_ttf)))

# Check stationarity
adf.test(daily_log_ttf)

# Visualize returns and volatility clustering
par(mfrow = c(1,2))
plot(daily_log_ttf, main = "Daily Log Returns")
plot(daily_log_ttf^2, main = "Squared Returns")

# -----------------------------------------------------------------------------
# 3. GARCH(1,1) Estimation
# -----------------------------------------------------------------------------

# Model selection (based on AIC/BIC)
best_order <- GARCHselect(daily_log_ttf, max.order = 6)
print(best_order$ics[which.min(best_order$ics$BIC), ])

# Fit GARCH(1,1)
garch_11 <- garchFit(~ garch(1,1), data = daily_log_ttf, trace = FALSE)
summary(garch_11)

# Extract standardized residuals
garch_resid <- residuals(garch_11, standardize = TRUE)

# Diagnostics
par(mfrow = c(1,2))
acf(garch_resid^2, main = "ACF of Squared Residuals")
qqnorm(garch_resid); qqline(garch_resid)

# -----------------------------------------------------------------------------
# 4. Stochastic Volatility (SV) Model
# -----------------------------------------------------------------------------

# Priors (uninformative)
priors <- specify_priors(
  mu = sv_normal(0, 100),
  phi = sv_beta(1, 1),
  sigma2 = sv_gamma(0.5, 0.3)
)

# Run MCMC
set.seed(123)
sv_draws <- svsample(y = daily_log_ttf, priorspec = priors,
                     draws = 10000, burnin = 1000)

summary(sv_draws)
volplot(sv_draws)

# -----------------------------------------------------------------------------
# 5. Volatility Comparison (GARCH vs SV)
# -----------------------------------------------------------------------------

# Extract volatilities
garch_vol <- sqrt(garch_11@sigma.t^2) * 100
sv_vol_median <- exp(sv_draws$summary$latent[, "50%"]/2) * 100
sv_vol_low <- exp(sv_draws$summary$latent[, "5%"]/2) * 100
sv_vol_high <- exp(sv_draws$summary$latent[, "95%"]/2) * 100

# Plot comparison
plot(ttf$Dates[-1], garch_vol, type = "l", col = "blue",
     ylab = "Volatility (%)", xlab = "Date",
     main = "Volatility Estimates: GARCH vs SV")
lines(ttf$Dates[-1], sv_vol_median, col = "red")
lines(ttf$Dates[-1], sv_vol_low, col = "grey")
lines(ttf$Dates[-1], sv_vol_high, col = "grey")
legend("topright", legend = c("GARCH(1,1)", "SV Median", "SV 5-95%"),
       col = c("blue", "red", "grey"), lty = 1)

# -----------------------------------------------------------------------------
# 6. Forecasting & Rolling Estimation (Optional)
# -----------------------------------------------------------------------------
# Example: one-step-ahead GARCH rolling forecast
window_size <- 30
rolling_garch <- numeric(length(daily_log_ttf) - window_size)

for (i in seq_len(length(daily_log_ttf) - window_size)) {
  window_data <- daily_log_ttf[i:(i + window_size - 1)]
  fit <- garchFit(~garch(1,1), data = window_data, trace = FALSE)
  rolling_garch[i] <- predict(fit, n.ahead = 1)$standardDeviation[1]
}

plot(rolling_garch, type = "l", col = "blue",
     main = "Rolling GARCH Volatility Forecasts")
