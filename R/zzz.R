.onLoad <- function(libname, pkgname) {

  td <- file.path(tempdir(),'torsten')
  dir.create(td,showWarnings = FALSE)
  TH <- find.package('torstenHeaders')

  if(length(list.files(file.path(TH,'stan')))==0){
    system(sprintf('git clone --depth 1 https://github.com/metrumresearchgroup/stan.git %s/stan',td))
    system(sprintf("mv %s/stan/src/stan %s",td,TH))
  }

  if(length(list.files(file.path(TH,'math')))==0){
    system(sprintf('git clone --depth 1 https://github.com/metrumresearchgroup/math.git %s/math',td))
    system(sprintf("mv %s/math/stan %s/math/stan",td,TH))
  }

  unlink(file.path(td,'math'),recursive = TRUE,force=TRUE)
  unlink(file.path(td,'stan'),recursive = TRUE,force=TRUE)
}

.onAttach <- function(libname, pkgname) {

  td <- file.path(tempdir(),'torsten')
  dir.create(td,showWarnings = FALSE)
  TH <- find.package('torstenHeaders')

  if(length(list.files(file.path(TH,'stan')))==0){
    system(sprintf('git clone --depth 1 https://github.com/metrumresearchgroup/stan.git %s/stan',td))
    system(sprintf("mv %s/stan/src/stan %s",td,TH))
  }

  if(length(list.files(file.path(TH,'math')))==0){
    system(sprintf('git clone --depth 1 https://github.com/metrumresearchgroup/math.git %s/math',td))
    system(sprintf("mv %s/math/stan %s/math",td,TH))
  }

  unlink(file.path(td,'math'),recursive = TRUE,force=TRUE)
  unlink(file.path(td,'stan'),recursive = TRUE,force=TRUE)
}
