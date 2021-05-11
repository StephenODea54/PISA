This repository contains the files used for an undergraduate project done at Youngstown State University. The data comes from The Programme for International Student Assessment, otherwise known as PISA. This is a worldwide survey conducted by the Organisation for Economic Co-operation and Development (OECD) to evaluate the performance of math, reading, and science scores of 15 year olds. In addition to the scores, there are many aspects of the children’s lives included in the survey as well (parent’s education, number of televisions, wealth, etc). The data was obtained by using the learningtower R package created by Kevin Wang. The package allows users to easily access information from the OECD’s PISA survey. For more information on learningtower, visit the following github repository: https://github.com/kevinwang09/learningtower.

The goal of the project is to predict student performance in math without using any data pertaining to location.

This repository contains r scripts used to clean the data and build the models, summarized datasets, a data dictionary, and the flexdashboard rmarkdown file used to create the presentation.

For future work:
* A grouped lasso regression and a multi-level model would likely serve to improve the predictive power of the current models because of the nature and hierarchal structure of the data.
* Some of the correlations are hard to disentangle (for example, parental education is correlated with economic status and wealth). A principal component analysis needs to be done to explore this issue.
* The choropleths did not format nicely in the dashboard. It would be nice to have them displayed as a shiny app so that the users could switch between all of the possible summary statistics.
* There are other basic formatting things that could be changed.
  * The comparison model could be formatted in the correlation funnel.
  * The summary was done in base R and then piped through to kable. This did not work as well as expected. The summary should be piped to something with a more "tidy" format, like skmr.

## XGBoost Metrics
![1](https://github.com/StephenODea54/PISA/blob/main/plots/XGBoost_Metrics.png)

## LASSO Regression Metrics
![2](https://github.com/StephenODea54/PISA/blob/main/plots/Lasso_Metrics.png)

## EDA
![3](https://github.com/StephenODea54/PISA/blob/main/plots/Correlation_Funnel.png)
![4](https://github.com/StephenODea54/PISA/blob/main/plots/Math_Score_By_Country.png)
![5](https://github.com/StephenODea54/PISA/blob/main/plots/Average_Wealth_By_Country.png)
