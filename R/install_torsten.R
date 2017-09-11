install_torsten <- function(StanHeaders_version="2.16.0-1",
                            rstan_version='2.16.2',
                            branch=c('master','develop'),
                            lib=.libPaths()[1],
                            destdir = NULL) {
  ## Download and edit StanHeaders (version 2.16)
  install.packages(sprintf("https://cran.r-project.org/src/contrib/StanHeaders_%s.tar.gz",StanHeaders_version),
                   repos = NULL,
                   type = "source",
                   lib=lib,...)
  setwd('lib')
  system("git clone https://github.com/metrumresearchgroup/stan.git")
  setwd("stan")

  system(sprintf("git checkout torsten-%s",branch))  # comment out to get torsten-master
  setwd('..')
  system("rm -rf StanHeaders/include/src/stan")
  system("mv stan/src/stan StanHeaders/include/src/stan")
  system("rm -rf stan")
  system("git clone https://github.com/metrumresearchgroup/math.git")
  setwd("math")
  system(sprintf("git checkout torsten-%s",branch))  # comment out to get torsten-master
  setwd('..')
  system("rm -rf StanHeaders/include/stan")
  system("mv math/stan StanHeaders/include/stan")
  system("rm -rf math")

  install.packages(sprintf("https://cran.r-project.org/src/contrib/rstan_%s.tar.gz",rstan_version),
                   repos = NULL,
                   type = "source",
                   lib=lib
                   )
}
