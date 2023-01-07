# demonstrate with observable d3 visualization examples
library(robservable)
#remotes::install_github("timelyportfolio/dary")
library(dary)

library(quanteda) # only used for dictionary examples

dictfile <- tempfile()
download.file("https://provalisresearch.com/Download/LaverGarry.zip",dictfile, mode = "wb")
unzip(dictfile, exdir = (td <- tempdir()))
dict2 <- dictionary(file = paste(td, "LaverGarry.cat", sep = "/"))
dict_hier <- dary::convert_dict_hier(dict2)

# hierarchy as nested table
robservable(
  "https://observablehq.com/d/1e503245f2d67193",
  include = "chart",
  input = list(
    data = dict_hier
  )
)
# collapsible tree
robservable(
  "@d3/collapsible-tree",
  include = "chart",
  input = list(
    data = dict_hier
  )
)
# radial tree
robservable(
  "@d3/radial-cluster",
  include = "chart",
  input = list(
    flare = dict_hier
  )
)
# circle pack
robservable(
  "https://observablehq.com/d/393754898c809624",
  include = "chart",
  input = list(
    data = dict_hier
  )
)
