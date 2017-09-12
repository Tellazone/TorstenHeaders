#' @title Installation for torsten through remote repository
#' @description installation of torsten with rstan, that replaces stanHeaders.
#' This function allows to specify which branch of torsten to install from.
#' @param StanHeaders_version package_version, package version of StanHeaders to append Torsten Default: NULL
#' @param rstan_version package_version, package version of rstan to install, Default: NULL
#' @param math_branch character, install the current build ('master') or different
#' development branch of torsten math library (e.g. 'develop'), Default: 'torsten-master'
#' @param stan_branch character, install the current build ('master') or different
#' development branch of torsten stan library (e.g. 'develop'), Default: 'torsten-master'
#' @param lib character, giving the library directory where to install the packages, Default: .libPaths()[1]
#' @param ... parameters to pass to install.packages
#' @details installation will replace the 'StanHeaders/include/src/stan' and 'StanHeaders/include/stan' of stanHeaders and install
#' source rstan without dependencies.
#' @rdname install_torsten_remote
#' @export

install_torsten_remote <- function(
  StanHeaders_version=NULL,
  rstan_version=NULL,
  math_branch='torsten-master',
  stan_branch='torsten-master',
  lib=.libPaths()[1],
  ...) {

  thiswd <- getwd()

  install_headers <- FALSE

  if(is.null(StanHeaders_version)){
    if(c('StanHeaders')%in%row.names(installed.packages())){
      StanHeaders_version <- packageVersion('StanHeaders')
    }else{
      StanHeaders_version <- read.dcf(system.file('CURRENT_VERSION',package = 'torstenHeaders'),fields = 'StanHeaders')
      StanHeaders_version <- as.package_version(StanHeaders_version)
      install_headers <- TRUE
    }
  }

  if(install_headers)
    devtools::install_version(package = 'StanHeaders',version = StanHeaders_version,lib=lib, ...)

  td <- tempdir()

  setwd(td)

  for(repo in c('stan','math')){
    system(sprintf("git clone --depth 1 https://github.com/metrumresearchgroup/%s.git",repo))
    setwd(repo)

    branch <- eval(parse(text = sprintf('%s_branch',repo)))
    if(branch!='torsten-master')
      system(sprintf("git checkout %s",branch))

    setwd('..')

    switch(repo,
           stan={
             system(sprintf("rm -rf %s/StanHeaders/include/src/stan",lib))
             system(sprintf("mv %s/stan/src/stan %s/StanHeaders/include/src/stan",td,lib))
           },
           math={
             system(sprintf("rm -rf %s/StanHeaders/include/stan",lib))
             system(sprintf("mv %s/math/stan %s/StanHeaders/include/stan",td,lib))
           })

    system(sprintf("rm -rf %s",file.path(td,repo)))
  }

  setwd(thiswd)

  if(is.null(rstan_version)) rstan_version <- read.dcf(system.file('CURRENT_VERSION',package = 'torstenHeaders'),fields = 'rstan')

  rstan_version <- as.package_version(rstan_version)

  devtools::install_version(package = 'rstan', version = rstan_version, lib=lib, ...)

}
