rm(list = ls())

# set the following to the appropriate folder locations:
# setwd("")
datapath="Data/"

# loading all functions
source("optpolicyFunctions.R")

# loading data
regdata=loaddata(datapath)

#subsampling for debugging
#regdata=regdata[sample(dim(regdata)[1], 1000),] #subsample of 1000 random observations

# running main analysis
regpredictions=gpregwelfare(regdata, doSWF=TRUE, doCI=TRUE, varyLambda=TRUE)

# plots
insuranceplots(regpredictions, printpdf=TRUE)
varyingLambdaplots(regpredictions, printpdf=TRUE)
validationplots(regdata, regpredictions, printpdf=TRUE)
