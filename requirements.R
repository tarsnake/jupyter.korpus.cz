#!/usr/bin/env Rscript

suppressMessages(source("https://bioconductor.org/biocLite.R"))

install_dep <- function(dep) {
  system2("apt-get", c("install", "-qq", dep))
}

install_package <- function(package) {
  if (is.list(package)) {
    name <- package$name
    locator <- if (is.null(package$locator)) name else package$locator
    method <- if (is.null(package$method)) "default" else package$method
  } else {
    name <- package
    locator <- package
    method <- "default"
  }
  installed <- suppressMessages(require(name, quietly=TRUE, character.only=TRUE))
  if (!installed) {
    cat("Installing", name, "...\n", file=stderr())
    if (method == "default") {
      install.packages(locator)
    } else if (method == "apt") {
      system2("apt-get", c("install", "-qq", tolower(locator)))
    } else if (method == "bioc") {
      biocLite(locator)
    } else if (method == "github") {
      devtools::install_github(locator)
    }
  }
}

deps <- c(
  "libblas-dev",
  "liblapack-dev",
  "libmpfr-dev",
  "libgl-dev",
  "libglu-dev",
  "libjpeg-dev",
  "libpoppler-cpp-dev",
  "libapparmor-dev"
)

packages <- list(
  # the tidyverse™
  "tidyverse",

  # utils
  "devtools",
  list(
    name="formatR",
    method="apt"
  ),
  "pryr",
  list(
    name="RCurl",
    method="apt"
  ),

  # data manipulation libraries (in addition to tidyverse above)
  list(
    name="jsonlite",
    method="apt"
  ),
  list(
    name="plyr",
    method="apt"
  ),
  list(
    name="reshape2",
    method="apt"
  ),
  "xml2",

  # visualization
  "alluvial",
  "Cairo",
  "ellipse",
  "ggdendro",
  "ggrepel",
  "ggthemes",
  "googleVis",
  list(
    name="gridExtra",
    method="apt"
  ),
  list(
    name="igraph",
    method="apt"
  ),
  list(
    name="lattice",
    method="apt"
  ),
  "networkD3",
  "pals",
  "plotluck",
  "plotly",
  "qgraph",
  list(
    name="RColorBrewer",
    method="apt"
  ),

  # linguistics and text processing
  "corpora",
  "languageR",
  "lsa",
  "quanteda",
  "readtext",
  list(
    name="Rling",
    locator="https://benjamins.com/sites/z.195/download/r_package/Rling_1.0.tar.gz"
  ),
  list(
    name="stringi",
    method="apt"
  ),

  # apps
  "DT",
  "htmlwidgets",
  "shiny",
  "shinyBS",
  "shinyjs",

  # document generation
  "knitr",
  "revealjs",
  "rmarkdown",
  "roxygen2",

  # collections (personal, book-related...)
  list(
    name="Hmisc",
    method="apt"
  ),
  list(
    name="r4ds",
    locator="hadley/r4ds",
    method="github"
  ),
  "lsr",
  list(
    name="MASS",
    method="apt"
  ),
  "MESS",
  "Rmisc",

  # modeling
  "compute.es",
  "ez",
  list(
    name="limma",
    method="bioc"
  ),
  list(
    name="lme4",
    method="apt"
  ),
  "MuMIn",
  list(
    name="nlme",
    method="apt"
  ),

  # exploratory
  "FactoMineR",
  "psych",

  # Bayesian
  "BayesDA",
  "coda",
  list(
    name="rjags",
    method="apt"
  ),
  "runjags",
  "rstan",

  # programming with R
  "hash",
  list(
    name="memoise",
    method="apt"
  ),

  # ugly hodgepodge which I might sort through at some point in the future
  list(
    name="ape",
    method="apt"
  ),
  list(
    name="boot",
    method="apt"
  ),
  "broom",
  "ca",
  list(
    name="car",
    method="apt"
  ),
  list(
    name="cluster",
    method="apt"
  ),
  "data.table",
  "distances",
  "entropy",
  "fields",
  "fortunes",
  "gee",
  list(
    name="geepack",
    method="apt"
  ),
  "geiger",
  "HH",
  "irr",
  "ks",
  "lavaan",
  list(
    name="mvtnorm",
    method="apt"
  ),
  "nFactors",
  "paran",
  "party",
  list(
    name="relimp",
    method="apt"
  ),
  list(
    name="rms",
    method="apt"
  ),
  list(
    name="scales",
    method="apt"
  ),
  "smacof",
  list(
    name="vcd",
    method="apt"
  )
)

for (dep in deps) {
  install_dep(dep)
}

for (package in packages) {
  install_package(package)
}
