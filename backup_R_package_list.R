#!/usr/bin/env Rscript

packages <- setdiff(
  row.names(installed.packages()),
  # remove base packages (they should not be updated)
  c(
    "base", "compiler", "datasets", "graphics", "grDevices", "grid", "methods",
    "parallel", "splines", "stats", "stats4", "tcltk", "tools", "utils"
  )
)
save(packages, file="packages.RData")
