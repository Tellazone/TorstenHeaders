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

  install_headers <- FALSE

  if(is.null(StanHeaders_version)){
    if(c('StanHeaders')%in%row.names(installed.packages(lib.loc = lib))){
      StanHeaders_version <- packageVersion('StanHeaders',lib.loc = lib)
    }else{
      StanHeaders_version <- pkgVersionCRAN('StanHeaders')
      install_headers <- TRUE
    }
  }

  if(install_headers)
    install.packages(sprintf("https://cran.r-project.org/src/contrib/StanHeaders_%s.tar.gz",StanHeaders_version),
                     repos = NULL,
                     type = "source",
                     lib=lib,...)

  td <- find.package('torstenHeaders')

  system(sprintf("rm -rf %s/StanHeaders/include/src/stan",lib))
  system(sprintf("mv %s/stan/src/stan %s/StanHeaders/include/src/stan",td,lib))
  system(sprintf("rm -rf %s/StanHeaders/include/stan",lib))
  system(sprintf("mv %s/math/stan %s/StanHeaders/include/stan",td,lib))

  if(is.null(rstan_version)) rstan_version <- pkgVersionCRAN('rstan')

  install.packages(sprintf("https://cran.r-project.org/src/contrib/rstan_%s.tar.gz",rstan_version),
                   repos = NULL,
                   type = "source",
                   lib=lib,...)

}
