# Optimal insurance and taxation using machine learning

Readme for R-code implementing the procedures proposed in

"Optimal insurance and taxation using machine learning"

by Maximilian Kasy

This archive contains two R-files:
1) **optpolicy.R**, which applies the proposed methods to the RAND health insurance experiment.

2) **optpolicyFunctions.R**, which implements the following 3 functions:

    a) *loaddata(datapath)*:
This function loads the RAND health insurance data.

    b) *gpregwelfare*:
This function implements a general purpose function for Gaussian process regression, estimation of posterior expected welfare, and frequentist inference on the optimal policy. This is the function which users might wish to take to other applications. It takes the following arguments, all of which except for "regdata" are optional:

      + regdata: dataframe containing outcome, treatment, and controls
      + Yname, Xname: names of outcome variable and treatment variable, default are X and Y
      + controlnames: variable names for controls, default are all variables in regdata except X, Y
      + t: gridpoints at which to evaluate predictions, default is [0,1]
      + doSWF: whether to estimate SWF in addition to response function, default is FALSE
      + doCI: whether to calculate frequentist confidence intervals, default is FALSE

      + smootW, smoothX: smoothness of prior: smaller = smoother; inverse of lengthscale
      + sig2: residual variance; this is relative to a prior variance of 1 for m
      + interceptvar, slopevar: prior variance for intercept and slope terms
      + lambda: welfare weight, value of $ to the sick relative to $ for government


The output of gpregwelfare is the data-frame "predictions," containing the grid t, as well as estimates mhat, uhat, uprimehat, stdmhat, and stduprimehat, if the corresponding options were set to TRUE.

                      
    c) insuranceplots:
This function plots the resulting estimates. It takes as its input the output of gpregwelfare.
The optional argument printpdf determines whether the plots are saved as pdf files.
