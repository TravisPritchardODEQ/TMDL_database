# Run this to update the package

library(devtools)
library(roxygen2)

#setwd("E:/GitHub/")
#create_package("E:/GitHub/wqdb")

setwd("E:/GitHub/wqdb/wqdb")
devtools::document()
setwd("..")
install("wqdb")
