from numpy import genfromtxt
from scipy import stats

residualFile = '/Users/hatcher/32083poly5resid.csv'
residuals = genfromtxt(residualFile, delimiter=',')

p = stats.anderson(residuals, dist='norm')

print('Anderson-Darling test for normallity')
print('AD = ' + str(p.statistic))
print('Critical values = ' + p.critical_values)
print('Levels = ' + p.significance_level)

