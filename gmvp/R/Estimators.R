
#### Sigma simple estimator (5) in EU tests paper
#' Simple covariance estimator
#'
#' Some description
#'
#' @param x numeric matrix in which columns are independent realizations of asset returns
#'
#' @examples
#' p<-5 # number of assets
#' n<-1e1 # number of realizations
#'
#' x <-matrix(data = rnorm(n*p), nrow = p, ncol = n)
#' Sigma_sample_estimator(x)
Sigma_sample_estimator <- function(x) {

  a <- rowMeans(x, na.rm = TRUE)
  a_x_size <- matrix(rep(a,ncol(x)),nrow=nrow(x), ncol=ncol(x))
  (x-a_x_size) %*% t(x-a_x_size)/(ncol(x)-1)
}


#### Q estimator (page 3, IEEE)
#' Q_n_hat
#'
#' Q estimator from (6) of EU_IEEE.
#'
#' @inheritParams Sigma_sample_estimator
#'
Q_hat_n <- function(x){

  SS <- Sigma_sample_estimator(x)
  invSS <- solve(SS)
  Ip <- rep.int(1, nrow(x))

  invSS - (invSS %*% Ip %*% t(Ip) %*% invSS)/as.numeric(t(Ip) %*% invSS %*% Ip)
}


Q <- function(Sigma){

  invSS <- solve(Sigma)
  Ip <- rep.int(1, nrow(Sigma))
  invSS - (invSS %*% Ip %*% t(Ip) %*% invSS)/as.numeric(t(Ip) %*% invSS %*% Ip)
}


#### W_EU estimator (page 3, IEEE)
#' W_EU estimator
#'
#' EU portfolio weights estimator from (6) of EU_IEEE.
#'
#' @inheritParams Sigma_sample_estimator
#' @param gamma positive numeric. Investors attitude towards risk
#'
W_EU_hat <- function(x, gamma){

  SS <- Sigma_sample_estimator(x)
  invSS <- solve(SS)
  Ip <- rep.int(1, nrow(x))
  Q_n_hat <- Q_hat_n(x)

  (invSS %*% Ip)/as.numeric(t(Ip) %*% invSS %*% Ip) +
  Q_n_hat %*% rowMeans(x, na.rm = TRUE)/gamma
}


#### S's

s_hat <- function(x) {

  a <- rowMeans(x, na.rm = TRUE)
  as.numeric(t(a) %*% Q_hat_n(x) %*% a)
}

s <- function(mu, Sigma) {

  as.numeric(t(mu) %*% Q(Sigma) %*% mu)
}

s_hat_c <- function(x) as.numeric((1-nrow(x)/ncol(x))*s_hat(x) - nrow(x)/ncol(x))

#### R_GMV (page 5, IEEE)
#' R_GMV. The deterministic value.
#'
#'
#'  The expected return of the GMV portfolio
#'
#' @inheritParams Sigma_sample_estimator
#' @param gamma positive numeric. Investors attitude towards risk
#'
#' @examples
#' mu <- c(1,5,3,4,9)
#' sm <- c(1,0,0,0,0,
#'         0,1,0,0,0,
#'         0,0,1,0,0,
#'         0,0,0,1,0,
#'         0,0,0,0,1)
#' Sigma <- matrix(data = sm, nrow = p, ncol = p)
R_GMV <- function(mu, Sigma){

  p <- length(mu)
  invSS <- solve(Sigma)
  Ip <- rep.int(1, p)

  as.numeric((t(Ip) %*% invSS %*% mu)/(t(Ip) %*% invSS %*% Ip))
}


R_hat_GMV <- function(x){

  a <- rowMeans(x, na.rm = TRUE)
  SS <- Sigma_sample_estimator(x)
  invSS <- solve(SS)
  Ip <- rep.int(1, nrow(x))

  as.numeric((t(Ip) %*% invSS %*% a)/(t(Ip) %*% invSS %*% Ip))
}


R_b <- function(mu, b) as.numeric(b %*% mu)

R_hat_b <- function(x, b) as.numeric(b %*% rowMeans(x, na.rm = TRUE))

#### V's

V_b <- function(Sigma, b) as.numeric(t(b) %*% Sigma %*% b)

V_hat_b <- function(x, b) {

  Sigma <- Sigma_sample_estimator(x)
  as.numeric(t(b) %*% Sigma %*% b)
}

V_GMV <- function(Sigma){

  as.numeric(1/(rep.int(1, nrow(Sigma)) %*% solve(Sigma) %*% rep.int(1, nrow(Sigma))))
}

V_hat_GMV <- function(x){

  Sigma <- Sigma_sample_estimator(x)
  as.numeric(1/(rep.int(1, nrow(Sigma)) %*% solve(Sigma) %*% rep.int(1, nrow(Sigma))))
}

V_hat_c <- function(x) {V_hat_GMV(x)/(1-nrow(x)/ncol(x))}

#### alphas, B and A expressions

# In case of GMV portfolio one needs to set gamma=infty
alpha_star <- function(gamma, mu, Sigma, b, c){

  R_GMV <- R_GMV(mu, Sigma)
  R_b <- R_b(mu, b)
  V_GMV <- V_GMV(Sigma)
  V_b <- V_b(Sigma, b)
  s <- s(mu, Sigma)

  Exp1 <- (R_GMV-R_b)*(1+1/(1-c))/gamma
  Exp2 <- gamma*(V_b-V_GMV)
  Exp3 <- s/(gamma*(1-c))
  numerator <- (Exp1 + Exp2 + Exp3)

  Exp4 <- V_GMV/(1-c)
  Exp5 <- -2*(V_GMV + (R_b - R_GMV)/(gamma*(1-c)))
  Exp6 <- ((s+c)/(1-c)^3)/(gamma^2)
  denomenator <- Exp4 + Exp5 + Exp6 + V_b

  as.numeric(numerator/denomenator)
}


# In case of GMV portfolio one needs to set gamma=infty
alpha_hat_star_c <- function(gamma, x, b){

  R_GMV <- R_hat_GMV(x)
  R_b <- R_hat_b(x, b)
  V_GMV <- V_hat_GMV(x)
  V_b <- V_hat_b(x, b)

  c <- nrow(x)/ncol(x)
  s <- s_hat_c(x)

  V_c <- V_GMV/(1-c)

  Exp1 <- (R_GMV-R_b)*(1+1/(1-c))/gamma
  Exp2 <- gamma*(V_b-V_c)
  Exp3 <- s/(gamma*(1-c))
  numerator <- (Exp1 + Exp2 + Exp3)

  Exp4 <- V_c/(1-c)
  Exp5 <- -2*(V_c + (R_b - R_GMV)/(gamma*(1-c)))
  Exp6 <- ((s+c)/(1-c)^3)/gamma^2
  denomenator <- Exp4 + Exp5 + Exp6 + V_b

  as.numeric(numerator/denomenator)
}


# A and B expressions
B_hat <- function(gamma, x, b){

  R_GMV <- R_hat_GMV(x)
  R_b <- R_hat_b(x, b)
  V_GMV <- V_hat_GMV(x)
  V_b <- V_hat_b(x, b)

  c <- nrow(x)/ncol(x)
  s <- s_hat_c(x)

  V_c <- V_GMV/(1-c)

  Exp4 <- V_c/(1-c)
  Exp5 <- -2*(V_c + (R_b - R_GMV)/(gamma*(1-c)))
  Exp6 <- ((s+c)/(1-c)^3)/gamma^2
  denomenator <- Exp4 + Exp5 + Exp6 + V_b

  as.numeric(denomenator)
}


#### W_BFGSE

W_hat_BFGSE <- function(x, gamma, b){

  # make output a vector instead of a matrix?
  al <- alpha_hat_star_c(gamma, x, b)
  al*W_EU_hat(x, gamma) + (1-al)*b
}




