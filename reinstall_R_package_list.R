#!/usr/bin/env Rscript

usage <- "Usage: reinstall_R_package_list.R <packages.RData>

packages.RData contains a vector of package names in the variable `packages`.
It can be created using export_R_packages."

sep <- paste0("\n", strrep("=", 79), "\n\n")
cat_sep <- function() {
  cat(sep, file=stderr())
}

args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 1) {
  stop(usage)
}

cat_sep()
cat("Updating package database...\n\n", file=stderr())
system2("apt-get", c("update"))

load(args[1])
no_precompiled <- c()
cat_sep()
cat("Trying to install precompiled packages...\n\n", file=stderr())
for (p in packages) {
  lower <- tolower(p)
  exit_code <- system2("apt-get", c("install", "--yes", paste0("r-cran-", lower)))
  if (exit_code != 0) {
    no_precompiled <- c(no_precompiled, p)
  }
}

cat_sep()
cat("Installing remaining packages from source...\n\n", file=stderr())
install.packages(
  no_precompiled,
  lib="/usr/local/lib/R/site-library",
  repos="https://cloud.r-project.org"
)
