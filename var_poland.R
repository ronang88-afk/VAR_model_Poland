library(urca)
library(vars)
library(tseries)
library(forecast)
library(tidyverse)
library(zoo)

set.seed(123)

sink("output_results.txt", split = TRUE)

if (!dir.exists("plots")) {
  dir.create("plots")
}

# load the data set 
yt1_2 <- read.csv("yt1.csv")
summary(yt1_2)

UNEM <- yt1_2$Unemployment

#a simple graph
ggplot(data = yt1_2) + geom_point(mapping = aes(x = UNEM,y = GDP))
ggsave("plots/scatter_GDP_vs_UNEM.png", width = 8, height = 6)

# declare my time series variables 
GDP <- ts(yt1_2$GDP, start = c(1996,3), frequency = 4)
UNEM <- ts(UNEM, start = c(1996,3), frequency = 4)


autoplot(cbind(GDP,UNEM))
ggsave("plots/ts_GDP_UNEM.png", width = 8, height = 6)

# OLS (unemployment affects GDP is the assumption)
#GDP = dependent v and Unemployment = independent 

OLS1 <- lm(GDP ~ UNEM)
summary(OLS1)

# This OLS regression tests the linear relationship between GDP and unemployment. 
#  the very low p value signifies a statistically significant negative relation ship 
# the r2 of 0.60 indicates that about 61% of the variation is explained by unemployment 
# therefore an ~1 unit increase in unemployment decreases GDP significantly 

# ACF and PACF 
# Autocorrelation and partial autocorrelation: is the series stationary or does it have unit roots? 

# determine the persistence of the model
png("plots/acf_GDP.png", width = 800, height = 600)
acf(GDP, main = "ACF for real GDP growth")
dev.off()
# GDP ACF shows a slow decay

png("plots/pacf_GDP.png", width = 800, height = 600)
pacf(GDP, main = "PACF for real GDP growth")
dev.off()
# pacf shows a sharp decay after lag 1

# 8 NAs - cleaned through linear interpolation - NEW CLEAN DATASET IS UNEM_CLEAN
summary(UNEM) # 8 NAs
UNEM_clean <- zoo::na.approx(UNEM)

png("plots/acf_UNEM_clean.png", width = 800, height = 600)
acf(UNEM_clean, main = "ACF for Unemployment") 
dev.off()
# similar slow decay 
summary(UNEM_clean)

png("plots/pacf_UNEM_clean.png", width = 800, height = 600)
pacf(UNEM_clean,main = "PACF for unemployment") 
dev.off()
# similar cut off after lag 1 

# both series appear to be non-stationary because the ACF doesn't drop to 0 too quickly. Is the OLS spurious? what different methods should i consider? 

# Model
# finding the optimal lags - VAR uses auto regressive lags 
yt1_2.bv <- cbind(GDP, UNEM_clean)
colnames(yt1_2.bv) <- cbind("GDP", "Unemployment")

# cleaning YT1.2
summary(yt1_2.bv)
yt1_2.bv_clean <- na.omit(yt1_2.bv)

# Lag selection function 
lagselect <- VARselect(yt1_2.bv_clean, lag.max = 10, type = "const")
lagselect$selection


#MODEL 1 YT1.2 (10 lags)
modelyt1.2 <- VAR(yt1_2.bv_clean, p = 10, type = "const", season = NULL, exogen = NULL) 
summary(modelyt1.2)
# while the unemployment lags are mainly insignificant, the GDP R2 AND adj r2 are very high, with multiple significant lags 
# unemployment r2 and adj r2 also are a very good fit on multiple lags, but GDP lags here are mainly insignificant. 
# Both series have a lot of their variation explained in the model. Both are mostly determined by their past values.  

#Diagnosing the VAR 
#Serial Correlation
# Are the residuals of the VAR serially correlated? 
Serial1 <- serial.test(modelyt1.2, lags.pt = 30, type = "PT.asymptotic")
Serial1
# chi-squared = 0.14, because its less than 0.05 null rejection failed. There is no serial correlation in the residuals. 

# Heteroscedasticity  - testing for periods of volatility 
# Is the residual variance constant over time ? 
# p value = greater than 0.05 = positive 
Arch1 <- arch.test(modelyt1.2, lags.multi = 30, multivariate.only = TRUE)
Arch1
# p value is very high (0.9972) so null rejection failed, no sign of volatility clustering in the residuals. They are homoskedastic. 


# Normal distribution of the residuals 
#want them to be normally distributed  - the multivariate normal
Norm1 <- normality.test(modelyt1.2, multivariate.only = TRUE)
Norm1
# p value is very small for the JB test, highly significant. 
# p-values are less than 0.05, so normality rejected, kurtosis and skewness present as residuals are not normally distributed 


# Testing for structural breaks in the residuals 
# Are the coeffs in the VAR stable over time?  
# The plot shows the cumulative sum of residuals, if the process stays within the 5% bands the null of stability is not rejected. 
Stability1 <- stability(modelyt1.2, type = "OLS-CUSUM")
png("plots/stability_OLS_CUSUM.png", width = 800, height = 600)
plot(Stability1)
dev.off()
# The line stayed between the red bands, no evidence of instability. 
# this supports the use of this model for foreasting 

#Granger Causality 
# whether the past values of one variable help predict the other beyond its own past. 
GrangerGDP <- causality(modelyt1.2, cause = "GDP")
GrangerGDP
# p-val = 0.1357 -> not significant 
# instant causality, p val = 0.6949 -> not significant 

# there is no granger causality in either direction, unemployment does not granger-cause GDP and vice versa for unemployment. Suggests that the two series above are largely independently consistent with the 
# VAR coefficients where cross lags were for the most part insignificant. 

GrangerUnemployment <- causality(modelyt1.2, cause = "Unemployment")
GrangerUnemployment

# Impulse Response functions
png("plots/irf_Unemployment_to_GDP.png", width = 800, height = 600)
GDPirf <- irf(modelyt1.2, impulse = "Unemployment", response = "GDP", n.ahead = 20, boot = TRUE)
plot(GDPirf, ylab = "GDP", main = "Shock from Unemployment")
dev.off()

png("plots/irf_GDP_to_Unemployment.png", width = 800, height = 600)
Unemploymentirf <- irf(modelyt1.2, impulse = "GDP", response = "Unemployment", n.ahead = 20, boot = TRUE)
plot(Unemploymentirf, ylab = "Unemployment", main = "Shock from GDP")
dev.off()

# Variance decomposition 
FEVD1 <- fevd(modelyt1.2, n.ahead = 10)
png("plots/FEVD.png", width = 800, height = 600)
plot(FEVD1)
dev.off()

#VAR forecast 

forecast <- predict(modelyt1.2, n.ahead = 4, ci = 0.95)
png("plots/fanchart_GDP.png", width = 800, height = 600)
fanchart(forecast, names = "GDP")
dev.off()

png("plots/fanchart_Unemployment.png", width = 800, height = 600)
fanchart(forecast, names = "Unemployment")
dev.off()

sink()
