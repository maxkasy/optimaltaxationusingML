rm(list = ls())
setwd("~/Dropbox/research/WorkInProgress/PolicyDecisions/RCode")
datapath="../Applications/2701_RAND_data/"

source("optpolicyFunctions.R")

regdata=loaddata(datapath)

#subsampling for debugging
#regdata=regdata[sample(dim(regdata)[1], 5000),] #subsample of xxx random observations

regpredictions=gpregwelfare(regdata, doSWF=TRUE, doCI=TRUE, varyLambda=TRUE)

insuranceplots(regpredictions, printpdf=TRUE)
varyingLambdaplots(regpredictions, printpdf=TRUE)
validationplots(regdata, regpredictions, printpdf=TRUE)
