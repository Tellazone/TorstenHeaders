.onLoad <- function(libname, pkgname) {

  td <- tempdir()
  TH <- find.package('torstenHeaders')

  if(length(list.files(file.path(TH,'stan')))==0){
    system(sprintf('git clone --depth 1 git@github.com:metrumresearchgroup/stan.git %s',td))
    system(sprintf("mv %s/stan/src/stan %s/stan",td,TH))
  }

  if(length(list.files(file.path(TH,'math')))==0){
    system(sprintf('git clone --depth 1 git@github.com:metrumresearchgroup/math.git %s',td))
    system(sprintf("mv %s/math/stan %s/math",td,TH))
  }

  unlink(file.path(td,'math'),recursive = TRUE,force=TRUE)
  unlink(file.path(td,'stan'),recursive = TRUE,force=TRUE)

}

.onAttach <- function(libname, pkgname) {
  td <- tempdir()
  TH <- find.package('torstenHeaders')

  if(length(list.files(file.path(TH,'stan')))==0){
    system(sprintf('git clone --depth 1 git@github.com:metrumresearchgroup/stan.git %s',td))
    system(sprintf("mv %s/stan/src/stan %s/stan",td,TH))
  }

  if(length(list.files(file.path(TH,'math')))==0){
    system(sprintf('git clone --depth 1 git@github.com:metrumresearchgroup/math.git %s',td))
    system(sprintf("mv %s/math/stan %s/math",td,TH))
  }

  unlink(file.path(td,'math'),recursive = TRUE,force=TRUE)
  unlink(file.path(td,'stan'),recursive = TRUE,force=TRUE)
}
