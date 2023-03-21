# demonstrate dictionary in tabular hierarchy form with reactable
#   also convert dictionaries with JavaScript

library(htmltools)
library(reactable)
library(d3r)
#remotes::install_github("timelyportfolio/dary")
# library(dary)

library(quanteda) # only used for dictionary examples
dictfile <- tempfile()
download.file("https://provalisresearch.com/Download/LaverGarry.zip",dictfile, mode = "wb")
unzip(dictfile, exdir = (td <- tempdir()))
dict2 <- dictionary(file = paste(td, "LaverGarry.cat", sep = "/"))
dict_hier <- dary::convert_dict_hier(dict2)

html_block <- tagList(
  d3r::d3_dep_v7(),
  reactable::reactable(elementId = "tbl", dary::convert_dict_flat(dict2), pagination = FALSE),
  tags$script(HTML(
    sprintf(
      '
// unnecessary since we have a flat conversion for data.frame
//  but keep for now in case we want to use
const hier = d3.hierarchy(%s)
const flat_arr = []
const flat_obj = []
const height = hier.height
hier.eachBefore( d => {
  if(d.depth === 0) return
  let row = Array(height + 1).fill(null)
  let row_obj = {}
  // initialize row object with each level as null
  Array(height + 1).forEach( (d,i) => {
    row_obj["level" + i] = null
  })

  d.path(hier).reverse().forEach( (nd, i) => {
    row[i] = nd.data.name
    row_obj["level"+i] = nd.data.name
  })
  flat_arr.push(row)
  flat_obj.push(row_obj)
})
',
jsonlite::toJSON(dict_hier, auto_unbox = TRUE)
    )
  ))
)

browsable(html_block)
