\name{tpshifthd}
\alias{tpshifthd}
\title{Computes the simaltaneous 95% confidence band for shift estimator}
\usage{
tpshifthd(x, y, nboot = 300, grain = 10)
}
\arguments{
  \item{x}{a vector of the first distribution}

  \item{y}{the second distribution}

  \item{nboot}{number of bootstrap samples}

  \item{grain}{number of parallel tasks. Keep in mind the
  cost of the work should out weight the cost of launching
  a task.}
}
\value{
3 column matrix with lower, upper bounds of 95%CI and the
estimate of the differences
}
\description{
Computes the simaltaneous 95% confidence band for shift
estimator
}

