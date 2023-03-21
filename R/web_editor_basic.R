library(bslib)
library(htmltools)
library(d3r)

html_block <- tagList(
  d3r::d3_dep_v7(),
  tags$head(
    tags$script(src = "https://cdn.jsdelivr.net/npm/@yaireo/tagify"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/@yaireo/tagify/dist/tagify.polyfills.min.js"),
    tags$link(href = "https://cdn.jsdelivr.net/npm/@yaireo/tagify/dist/tagify.css", rel =
                "stylesheet", type = "text/css"),
    tags$script(
      '
// crude but functioning hierarchy to yaml converter
function dom_to_yaml() {
  const builder_groups = d3.selectAll(".dictionary-builder-group")
  const yaml_arr = []
  builder_groups.each(function() {
    yaml_arr.push(`${d3.select(this).select("h3").text()}:`)
    d3.select(this).selectAll("tags.tagify tag").each(function() {
      yaml_arr.push("  - " + d3.select(this).attr("value"))
    })
  })
  return yaml_arr.join("\\n")
}

function delete_group(evt) {
  d3.select(evt.target.parentElement.parentElement).remove()
}

function add_group(evt) {
  const tree = d3.select(this.event.target.parentElement.parentElement).select(".dictionary-builder-tree")
  const leveldiv = tree
    .append("div")
    .classed("dictionary-builder-group", true)
    .style("margin-top", "5px")

  leveldiv
    .append("h3")
    .style("margin", "0px")
    .style("display", "inline")
    .attr("contenteditable",true)
    .text("Group")

  // change this to trash icon
  leveldiv
    .append("span")
    .style("margin-left","2px")
    .append("button")
    .text("delete")
    .on("click", delete_group)

  const leavesdiv = leveldiv
    .append("div")
      .style("width", "100%")
      .style("display", "flex")
      .style("flex-wrap", "wrap")

  const tagify_el = leavesdiv
    .append("input")
    .attr("type", "tags")
    .attr("placeholder", "add more terms")

  const tagify = new Tagify(tagify_el.node())
  tagify.addTags(["word1","word2"])
}
'
    )
  ),
tags$div(
  class = "dictionary-builder",
  style = "width: 100%;",
  tags$div(class = "dictionary-builder-tree",
           style = "width: 100%; min-height: 20px;"),
  tags$div(style = "margin-top:10px;"),
  tags$button(class = "btn btn-primary",
              onclick = "add_group()",
              "Add Group")
)
)


browsable(html_block)
