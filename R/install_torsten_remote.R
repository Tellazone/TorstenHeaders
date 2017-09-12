#' @title Installation for torsten
#' @description installation of torsten with rstan, that replaces stanHeaders.
#' @param StanHeaders_version package_version, package version of StanHeaders to append Torsten Default: NULL
#' @param rstan_version package_version, package version of rstan to install, Default: NULL
#' @param branch character, install the current build ('master') or different
#' development branch of torsten (e.g. 'develop'), Default: 'master'
#' @param lib character, giving the library directory where to install the packages, Default: .libPaths()[1]
#' @param ... parameters to pass to install.packages
#' @details installation will replace the 'StanHeaders/include/src/stan' and 'StanHeaders/include/stan' of stanHeaders and install
#' source rstan without dependencies.
#' @rdname install_torsten_remote
#' @export

install_torsten_remote <- function(StanHeaders_version=NULL,
                            rstan_version=NULL,
                            branch='master',
                            lib=.libPaths()[1],
                            ...) {

  thiswd <- getwd()

  install_headers <- FALSE

  if(is.null(StanHeaders_version)){
    if(c('StanHeaders')%in%row.names(installed.packages())){
      StanHeaders_version <- packageVersion('StanHeaders')
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

  if(is.null(rstan_version)) rstan_version <- pkgVersionCRAN('rstan')

  td <- tempdir()

  setwd(td)

  for(repo in c('stan','math')){
    system(sprintf("git clone https://github.com/metrumresearchgroup/%s.git",repo))
    setwd(repo)

    if(branch!='master') system(sprintf("git checkout torsten-%s",branch))
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

  install.packages(sprintf("https://cran.r-project.org/src/contrib/rstan_%s.tar.gz",rstan_version),
                   repos = NULL,
                   type = "source",
                   lib=lib,...)

}
