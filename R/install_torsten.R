#' @title Installation for torsten
#' @description installation of torsten with rstan, that replaces stanHeaders.
#' @param StanHeaders_version package_version, package version of StanHeaders to append Torsten Default: NULL
#' @param rstan_version package_version, package version of rstan to install, Default: NULL
#' @param lib character, giving the library directory where to install the packages, Default: .libPaths()[1]
#' @param ... parameters to pass to install.packages
#' @details installation will replace the 'StanHeaders/include/src/stan' and 'StanHeaders/include/stan' of stanHeaders and install
#' source rstan without dependencies.
#' @rdname install_torsten
#' @export

install_torsten <- function(StanHeaders_version=NULL,
                            rstan_version=NULL,
                            lib=.libPaths()[1],
                            ...) {

  lib <- normalizePath(lib)

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

  TH <- find.package('torstenHeaders')

  system(sprintf("rm -rf %s/StanHeaders/include/src/stan",lib))
  system(sprintf("mv %s/stan %s/StanHeaders/include/src/stan",TH,lib))
  system(sprintf("rm -rf %s/StanHeaders/include/stan",lib))
  system(sprintf("mv %s/math/stan %s/StanHeaders/include/stan",TH,lib))

  if(is.null(rstan_version)) rstan_version <- read.dcf(system.file('CURRENT_VERSION',package = 'torstenHeaders'),fields = 'rstan')

  rstan_version <- as.package_version(rstan_version)

  devtools::install_version(package = 'rstan', version = rstan_version, lib=lib, ...)

}
