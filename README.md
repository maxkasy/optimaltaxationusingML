# Optimal insurance and taxation using machine learning

Readme for R-code implementing the procedures proposed in
"Optimal insurance and taxation using machine learning"
by Maximilian Kasy


### Background
**PolicyDecisions.pdf** discusses the use of Gaussian process regression for optimal policy choices.
The code in this archive implements the proposed methods


### Data
**data/** is the subfolder containing the .csv files required for applying the proposed methods to the RAND health insurance experiment.
These files are derived from the data available at https://www.aeaweb.org/jep/app/2701_RAND_data.zip using **datatomatlabRAND2.do**, available in the same subfolder.


### R-code
Running the R script **optpolicy.R** produces all the figures in the paper.
This script invokes the functions defined in **optpolicyFunctions.R**.


1) *loaddata*: This function loads the RAND health insurance data.

2) *gpregwelfare*: This function implements a general purpose function for Gaussian process regression, estimation of posterior expected welfare, and frequentist inference on the optimal policy. This is the function which users might wish to take to other applications. It takes the following arguments, all of which except for "regdata" are optional:
	+ regdata: dataframe containing outcome, treatment, and controls
	+ Yname, Xname: names of outcome variable and treatment variable, default are X and Y
	+ controlnames: variable names for controls, default are all variables in regdata except X, Y
	+ t: gridpoints at which to evaluate predictions, default is [0,1]
	+ doSWF: whether to estimate SWF in addition to response function, default is FALSE
	+ doCI: whether to calculate frequentist confidence intervals, default is FALSE
	+ varyLambda:  whether to consider a range of values for lambda

	+ smootW, smoothX: smoothness of prior: smaller = smoother; inverse of lengthscale
	+ sig2: residual variance; this is relative to a prior variance of 1 for m
	+ interceptvar, slopevar: prior variance for intercept and slope terms
	+ lambda: welfare weight, value of $ to the sick relative to $ for government


	The output of gpregwelfare is the data-frame "predictions," containing the grid t, as well as estimates mhat, uhat, uprimehat, stdmhat, and stduprimehat, if the corresponding options were set to TRUE.
	If varyLambda was set to TRUE, the output includes additional columns for lambda and optpol, corresponding to Figure 2 in the paper.

                      
3) Plotting:
	+ *insuranceplots*: This function plots the resulting estimates, cf. Figure 1 in the paper. It takes as its input the output of gpregwelfare. The optional argument printpdf determines whether the plots are saved as pdf files.
	+ *varyingLambdaplots*: This function plots optimal policies as a function of the welfare weight lambda, cf. Figure 2 in the paper.
	+ *validationplots*: This function plots estimates when subset of the data are dropped, to check robustness to function form assumptions, cf. Figure 3 in the paper.
