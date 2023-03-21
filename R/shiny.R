# simple Shiny app with modified shinytree connected to d3 tree visualization

library(shiny)
library(htmltools)
#remotes::install_github("timelyportfolio/shinyTree")
library(shinyTree)
library(robservable)
#remotes::install_github("timelyportfolio/dary")
library(dary)

library(quanteda) # only used for dictionary examples
dictfile <- tempfile()
download.file("https://provalisresearch.com/Download/LaverGarry.zip",dictfile, mode = "wb")
unzip(dictfile, exdir = (td <- tempdir()))
dict2 <- dictionary(file = paste(td, "LaverGarry.cat", sep = "/"))
dict_hier <- dary::convert_dict_hier(dict2)

ui <- div(
  style = "height: 100vh; width: 100%; display: flex;",
  div(
    style = "width: 30%; overflow: auto;",
    shinyTree::shinyTree(
      outputId = "dictionary",
      checkbox = TRUE,
      theme = "proton",
      themeIcons = FALSE,
      themeDots = FALSE,
      search = TRUE
    )
  ),
  div(
    style = "width: 70%; height: 100%",
    robservable(
      "@d3/radial-cluster",
      include = "chart",
      input = list(
        flare = dict_hier
      )
    )
  ),
  d3r::d3_dep_v7(),
  tags$script(HTML(
"
$(function() {
  $(document).on('shiny:inputchanged', function (evt) {
    let selected = new Map()
    if(evt.value && /select/.test(evt.value.action)) {
      d3.hierarchy($(evt.el).jstree().get_json()[0]).each(d => {
        if(d.data.state.selected) {
          selected.set(d.data.text, true)
        }
      })
      d3.selectAll('.chart g text').style('fill', function(d) {
        if(selected.get(d.data.name)) {
          return 'purple'
        }
      })
      d3.selectAll('.chart g path').style('stroke', function(d) {
        if(selected.get(d.target.data.name)) {
          return 'purple'
        }
      })
    }
  })
})
"
  ))
)
server <- function(input, output, session) {
  dict_hier <- dary::convert_dict_hier(dict2, idname = "text")  # shinytree wants "text" instead of "name"
  shinyTree::updateTree(
    session = session,
    treeId = "dictionary",
    data = dict_hier
  )
}
shinyApp(ui, server)
