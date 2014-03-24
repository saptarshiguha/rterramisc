##' Computes the simaltaneous 95% confidence band for shift estimator
##' @param x a vector of the first distribution
##' @param y the second distribution
##' @param nboot number of bootstrap samples
##' @return 3 column matrix with  lower, upper bounds of 95%CI and the estimate of the differences
##' @export
tshifthd <- function(x,y,nboot=300){
    a <- do.call(rbind,terra("shifthd", x,y,nboot,table='smisc'))
    colnames(a)=c("ci.lower","ci.upper","Delta.hat")
    a
}
