# library(bslib)
library(htmltools)
library(d3r)

# should we add ability to use existing dictionary
dictionary_builder_html <- function(id = NULL) {
  html_block <- tagList(
    d3r::d3_dep_v7(),
    tags$head(
      tags$script(src = "https://cdn.jsdelivr.net/npm/@yaireo/tagify"),
      tags$script(src = "https://cdn.jsdelivr.net/npm/@yaireo/tagify/dist/tagify.polyfills.min.js"),
      tags$link(
        href = "https://cdn.jsdelivr.net/npm/@yaireo/tagify/dist/tagify.css",
        rel = "stylesheet",
        type = "text/css"
      ),
      tags$script(HTML(
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

  // update monaco editor and send shiny on change
  function update_monaco_shiny() {
    var dict_yml = dom_to_yaml()
    try {
      monaco.editor.getModels()[0].setValue(dict_yml)
    } catch(e) {
      console.log("update monaco failed", e)
    }

    if(typeof(window.Shiny) !== "undefined" &&  Shiny.hasOwnProperty("setInputValue")) {
      var id = d3.select(d3.select(".dictionary-builder").node().parentNode).attr("id")
      if(id) {
        Shiny.setInputValue(id, dict_yml)
      }
    }
  }

  function delete_group(evt) {
    d3.select(evt.target.parentElement.parentElement).remove()
    update_monaco_shiny()
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
      .on("input", function() {update_monaco_shiny()});

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

    const tagify = new Tagify(tagify_el.node(), {
      callbacks: {
        "change": () => {update_monaco_shiny()},
      }
    })
    tagify.addTags(["word1","word2"])
  }
  '
      )
    )),
    tags$div(
      style = "display: flex; max-height: 95vh;",
      id = id,
      tags$div(
        class = "dictionary-builder",
        style = "width: 50%; overflow-y: auto;",
        tags$div(
          class = "dictionary-builder-tree",
          style = "width: 100%; min-height: 20px;"
        ),
        tags$div(style = "margin-top:10px;"),
        tags$button(
          class = "btn btn-primary",
          onclick = "add_group()","Add Group"
        )
      ),
      tags$div(
        style = "min-width:50%; min-height:95vh;",
        monaco::monaco("", language = "yaml", width = "100%")
      )
    ),
  )


  browsable(html_block)
}

### html example ----
# dictionary_builder_html("dictionary")

### Shiny example ----
# library(shiny)
# shinyApp(ui= dictionary_builder_html("dictionary"), server = function(input, output, session) {
#     observeEvent(input$dictionary, {print(input$dictionary)})
# })
