loaddata=function(datapath) {
  #reading CSV files into dataframe
  regdata=as.data.frame(c(
    Y=read.table(paste(datapath, "Y.csv", sep=""), header=FALSE, sep=","),
    X=read.table(paste(datapath, "X.csv", sep=""), header=FALSE, sep=","),
    W=read.table(paste(datapath, "Wfull.csv", sep=""), header=FALSE, sep=",")
  ))
  
  #change columns 1 and 2 of W to factors
  regdata[[3]]=factor(regdata[[3]])
  regdata[[4]]=factor(regdata[[4]])
  #changing columnames
  names(regdata)=c("Y", "X", "year.id", "monthlocation.id", paste("W", 1:(length(regdata)-4),sep=""))
  #switch signs - copay=1 means 0 transfer 
  regdata$X=1-regdata$X;
  
  regdata
}



gpregwelfare=function(regdata, #dataframe containing outcome, treatment, and controls
                      Yname="Y", Xname="X", #outcome variable and treatment variable
                      controlnames=names(regdata)[(names(regdata)!=Yname)&(names(regdata)!=Xname)], #setting variable names for controls as all variables except X, Y
                      t=seq(0,1, by=.01), #gridpoints at which to evaluate predictions
                      doSWF=FALSE, #whether to estimate SWF in addition to response function
                      doCI=FALSE, #whether to calculate frequentist confidence intervals
                      varyLambda=FALSE,  #whether to consider a range of values for lambda
                      ########################################
                      #setting parameters for regression
                      smootW=.2, smoothX=1, #smoothness of prior: smaller = smoother; inverse of lengthscale
                      sig2=1, #residual variance; this is relative to a prior variance of 1 for m
                      interceptvar=100, slopevar=50, #prior variance for intercept and slope
                      ########################################
                      #welfare weight
                      lambda= 1.5 # - value of $ to the sick relative to $ for government
                      )
{ 
  #size of data
  n=length(regdata$X) #number of observations
  nw=length(regdata)-2 #number of controls
  nt=length(t)    
  
  ###we wil calculate covariances as product of two terms:
  #one for covariates W, one for treatments X (T)
  ###########################################################################
  #distance squared betwee covariates
  distance2=matrix(0, n, n)
  for (j in controlnames){
    if (is.factor(regdata[[j]])) distance2 = distance2 + 4 * outer(regdata[[j]], regdata[[j]], "!=") #for factors, add 4 if the factor is not the same across observations
    else distance2 = distance2 +(smootW^2/var(regdata[[j]]))*outer(regdata[[j]], regdata[[j]], "-")^2 #for non-factors, add distance squared, normalized by std and lengthscale
  }
  
  
  #cov kernel for distance 
  CW=exp(-distance2/2)
  CWbar=apply(CW,1,mean)
  #same for policytreatment
  distance2X = smoothX^2*outer(regdata[[Xname]], regdata[[Xname]], "-")^2
  
  CX=(CW*exp(-distance2X/2) #variance matrix of Y involves variance due to squared exponential kernel (based on distance in X and W)
  + matrix(interceptvar,n,n) #plus high variance intercept term
  + slopevar * regdata[[Xname]]%o%regdata[[Xname]]) #plus high variance slope term
  
  #clear up memory
  rm(CW,distance2, distance2X)
  
  #key calculation for posterior expectation
  Ytilde =solve((CX #variance of k given X, W
                 + diag(sig2,n)), #plus idiosyncratic noise,
                regdata[[Yname]])
  
  
  ###########################################################################
  #delta: distance between X_i and argument value for evaluation T_j
  delta = smoothX*outer(t, regdata[[Xname]], "-") #rows correspond to values of T
  #estimate m
  cx=exp(-delta^2/2) 
  Cx= (rep(1,nt) %o% CWbar)*cx  + matrix(interceptvar,nt,n) +slopevar*(t%o%regdata[[Xname]])
  mhat = Cx %*% Ytilde
  
  #returnarguments - to be extended as appropriate
  predictions=list(t=t, mhat=mhat)
  
  #estimate the SWF u, and its derivative, uprime
  if (doSWF) {
    dx= (lambda /(smoothX*dnorm(0)))  * (pnorm(delta)-pnorm(-smoothX*rep(1,nt)%o% regdata[[Xname]])) - (t %o% rep(1,n)) * cx
    bx= (lambda-1 + smoothX* (t %o% rep(1,n))*delta)*cx;
    
    Dx= (rep(1,nt) %o% CWbar)*dx  +interceptvar*(lambda-1)*(t%o% rep(1,n)) + 0.5* slopevar*(lambda-2)*((t^2)%o%regdata[[Xname]])
    Bx= (rep(1,nt) %o% CWbar)*bx  +interceptvar*(lambda-1)*matrix(1,nt,n) + slopevar*(lambda-2)*(t%o%regdata[[Xname]])
    
    uhat = Dx %*% Ytilde
    uprimehat = Bx %*% Ytilde
    
    #appending to returnarguments
    predictions$uhat=uhat
    predictions$uprimehat=uprimehat
  }
  
  #frequentist confidence bands  
  if (doCI) {
    #simplified version of SE calculation, relative to matlab code
    
    #squared prediction residuals
    epsilon2=(regdata[[Yname]]-CX%*%Ytilde)^2
    #standard error of mhat
    stdmhat= sqrt(t(solve((CX + diag(sig2,n)), t(Cx)))^2  %*% epsilon2)
    #standard error of uprimehat
    stduprimehat= sqrt(t(solve((CX + diag(sig2,n)), t(Bx)))^2  %*% epsilon2)
  
    #appending to returnarguments
    predictions$stdmhat=stdmhat
    predictions$stduprimehat=stduprimehat
  }
  
  if (varyLambda) {
    predictions$lambda=seq(1,2, by=.01) #storing in same dataframe, for convenience of return argument
    
    uhat=function(lambda){
      dx= (lambda /(smoothX*dnorm(0)))  * (pnorm(delta)-pnorm(-smoothX*rep(1,nt)%o% regdata[[Xname]])) - (t %o% rep(1,n)) * cx
      Dx= (rep(1,nt) %o% CWbar)*dx  +interceptvar*(lambda-1)*(t%o% rep(1,n)) + 0.5* slopevar*(lambda-2)*((t^2)%o%regdata[[Xname]])
      Dx %*% Ytilde
    }
    
    predictions$optpol=sapply(predictions$lambda,
                  function(lambda) t[which.max(uhat(lambda))])
    
    predictions$optpolSuff2=1/(1+0.2/(predictions$lambda-1))
    predictions$optpolSuff5=1/(1+0.5/(predictions$lambda-1))
  }
    
  as.data.frame(predictions)
}


library(ggplot2)
library(ggthemes)
library(reshape2)


insuranceplots=function(regpredictions, printpdf=FALSE) {
  ggplot(data=regpredictions, aes(x=t, y=mhat, ymin=mhat-1.96*stdmhat, ymax=mhat+1.96*stdmhat))+
    #geom_hline(yintercept=0, size=.5, color="grey") + 
    geom_ribbon(alpha=0.2, fill="blue") + 
    geom_line(size=1) + 
    xlab("t") +
    ylab(expression(widehat(m))) +
    expand_limits(y=0) +
    xlim(0,1)+
    theme_economist() + scale_colour_economist()
  
  if (printpdf) ggsave("mhat.pdf", width = 6, height = 4)  
  
  ggplot(data=regpredictions, aes(x=t, y=uprimehat, ymin=uprimehat-1.96*stduprimehat, ymax=uprimehat+1.96*stduprimehat))+
    #geom_hline(yintercept=0, size=.5, color="grey") + 
    geom_line(size=1) + 
    geom_ribbon(alpha=0.2, fill="blue") + 
    xlab("t") +
    ylab(expression(widehat(u)*minute)) +
    #ylim(-800, 800)+
    xlim(0,1)+
    theme_economist() + scale_colour_economist()
  
  if (printpdf) ggsave("uprimehat.pdf", width = 6, height = 4)
  
  #multiple series in one plot
  uhatuhatprime=melt(regpredictions[c("t", "uhat", "uprimehat")], id="t")
  
  #find argmax of uhat for annotations
  argmax=which.max(regpredictions$uhat)
  tstar=regpredictions$t[argmax]
  ustar=regpredictions$uhat[argmax]
  txt=paste("widehat(t) ==",tstar)
  
  ggplot(data=uhatuhatprime, aes(x=t, y=value, colour=variable))+
    #geom_hline(yintercept=0, size=.5, color="grey") + 
    geom_vline(xintercept=tstar, size=.5, color="grey")+
    geom_line(size=1) +
    xlab("t") +
    ylab("") +
    #ylim(-500, 900) +
    xlim(0,1)+
    theme_economist() + 
    scale_colour_economist(labels=expression(widehat(u), widehat(u)*minute)) +
    theme(legend.title=element_blank())+
    annotate("text", x = tstar, y = ustar+70, label = txt, parse = TRUE)
  
  
  if (printpdf) ggsave("uhat.pdf", width = 6, height = 4)
}



varyingLambdaplots=function(regpredictions, printpdf=FALSE) {
  
  optpols=melt(regpredictions[c("lambda", "optpol", "optpolSuff2", "optpolSuff5")], id="lambda")

  ggplot(data=optpols, aes(x=lambda, y=value, colour=variable))+
    #geom_hline(yintercept=0, size=.5, color="grey") + 
    geom_line(size=1) +
    xlab(expression(lambda)) +
    ylab(expression(widehat(t))) +
    #ylim(-500, 900) +
    xlim(1,2)+
    theme_economist() + 
    #scale_colour_economist(labels=expression("optimal", "eta=.2", "eta=.5")) +
    scale_colour_economist(labels=expression(optimal, eta==.2, eta==.5))+
    theme(legend.title=element_blank())
  
  if (printpdf) ggsave("tstar.pdf", width = 6, height = 4)  
}



validationplots=function(regdata, regpredictions, printpdf=FALSE) {
  
  for (t in c(.5, .75)){
    regpredictionsdrop=gpregwelfare(regdata[regdata$X != t,], doSWF=TRUE)
    regpredictions[[paste("mhatdrop", t, sep="")]]=regpredictionsdrop$mhat
    regpredictions[[paste("uhatdrop", t, sep="")]]=regpredictionsdrop$uhat
    regpredictions[[paste("uprimehatdrop", t, sep="")]]=regpredictionsdrop$uprimehat
  }
  
  
  for (plotvar in c("mhat", "uhat", "uprimehat")){
    validationdat=melt(regpredictions[c("t",plotvar, paste(plotvar,"drop", "0.5",sep=""), paste(plotvar,"drop", "0.75",sep=""))], id="t")
    
    ylable=ifelse(plotvar == "mhat", expression(widehat(m)),
                  ifelse(plotvar == "uhat", expression(widehat(u)),
                      expression(widehat(u)*minute)))
    
    ggplot(data=validationdat, aes(x=t, y=value, colour=variable))+
      geom_line(size=1) +
      xlab("t") +
      ylab(ylable) +
      xlim(0,1)+
      expand_limits(y=0) +
      theme_economist() + 
      scale_colour_economist(labels=c("full data", "drop t=.5", "drop t=.75")) +
      theme(legend.title=element_blank())
    
    
    if (printpdf) ggsave(paste(plotvar, "Validation.pdf",sep=""), width = 6, height = 4)
  }
  
}
