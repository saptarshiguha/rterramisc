\name{tshifthd}
\alias{tshifthd}
\title{Computes the simaltaneous 95% confidence band for shift estimator}
\usage{
tshifthd(x, y, nboot = 300)
}
\arguments{
  \item{x}{a vector of the first distribution}

  \item{y}{the second distribution}

  \item{nboot}{number of bootstrap samples}
}
\value{
3 column matrix with lower, upper bounds of 95%CI and the
estimate of the differences
}
\description{
Computes the simaltaneous 95% confidence band for shift
estimator
}

