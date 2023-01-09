library(htmltools)
#remotes::install_github("timelyportfolio/dary")
# library(dary)
library(d3r)

library(quanteda) # only used for dictionary examples

dictfile <- tempfile()
download.file("https://provalisresearch.com/Download/LaverGarry.zip",
              dictfile,
              mode = "wb")
unzip(dictfile, exdir = (td <- tempdir()))
dict2 <- dictionary(file = paste(td, "LaverGarry.cat", sep = "/"))
dict_hier <- convert_dict_hier(dict2)

div_monaco <- div(
  style = "display: flex;",
  div(id = "hierlist", style = "width: 50%; margin-right:50px;"),
  div(
    style = "min-width:50%",
    htmlwidgets::onRender(
      monaco::monaco("", language = "yaml", width = "100%"),
      "() => {
  monaco.editor.getModels()[0].onDidChangeContent(function() {
    try {
      const yml = yaml_to_hier(monaco.editor.getModels()[0].getValue())
      hier_to_dom(yml,'#hierlist')
    } catch(e) {}
  })
  monaco.editor.getModels()[0].setValue(hier_to_yaml(hier))
}"
    )
  )
)

html_block <- tagList(
  d3r::d3_dep_v7(),
  # I do not think we need but include for experimentation
  #   as of now we write our own d3 hierarchy to yaml conversion
  tags$head(
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/js-yaml/4.1.0/js-yaml.min.js")
  ),
  div_monaco,
tags$script(
  HTML(
    "
// crude but functioning hierarchy to yaml converter
function hier_to_yaml(hier) {
  let yaml_arr = []
  hier.eachBefore(d => {
    if(d.depth === 0) return
    let indent = new Array(d.depth - 1).fill('  ').join('')
    if(d.height > 0) yaml_arr.push(indent + d.data.name + ':')
    if(d.height === 0) yaml_arr.push(indent + '- ' + d.data.name)
  })
  return yaml_arr.join('\\n')
}

// crude but functioning yaml/JSON to hierarchy converter
function yaml_to_hier(yaml) {
  const yme = Object.entries(jsyaml.load(yaml));
  const ym1 = {
    name: 'dictionary',
    children: yme.map( d => ({name: d[0], children: Array.isArray(d[1]) ? d[1].map( dd => ({name: dd}) ) : Object.entries(d[1])}))
  }
  d3.Node.prototype.eachAfter.call(ym1, d => {
    if(!d.name) {
      if(Array.isArray(d[1])) {
        d.name = d[0]; d.children= d[1].map( dd => ({name: dd}) );
      } else {
        d.name = d[0]; d.children= Object.entries(d[1]);
      }
    }
  })
  d3.Node.prototype.eachAfter.call(ym1, d => {
    if(d.depth > 0 && d.children) {
      d.children = d.children.map(({name, children}) => (children ? {name, children} : {name}))
    }
  })
  return d3.hierarchy(ym1)
}
"
  )
),
tags$script(HTML(
  sprintf(
    '
// unnecessary since we have a flat conversion for data.frame
//  but keep for now in case we want to use
const hier = d3.hierarchy(%s)
function hier_to_dom(hier, selector) {
  const sel = d3.select(selector)
  // clear selected
  //   need to refine to use d3 enter, exit, update pattern
  //   partially implemented at the leaf level
  sel.selectAll("*").remove()
  let parentdiv  // there is a better way of doing this but keep simple and ugly for now

  hier.eachBefore(d => {
    if(d.depth === 0) return  // ignore root
    if(d.height === 0) return // ignore leaves since handled at parent level
    if(d.height === 1) {
      parentdiv
        .append("div")
        .text(`${d.data.name} (${d.leaves().length})`)
        .style("margin-left", d.depth * 10 + "px")
        .style("margin-top", "5px")
        //.style("font-size", "1.25em")
        //.style("font-weight","bold")
        .append("div")
          .style("width", "100%%")
          .style("display", "flex")
          .style("flex-wrap", "wrap")
          //.style("overflow-x","auto")
          //.style("overflow-y","hidden")
          .style("margin-left", (d.depth + 1) * 10 + "px")
          .style("margin-top", "5px")
          .style("margin-bottom", "5px")
          .selectAll("div")
            .data(d.children)
            .join(
              enter => {
                enter
                  .append("div")
                  .text(d => d.data.name)
                  .style("font-size", "1em")
                  .style("font-weight", "normal")
                  .style("background", "#ccc")
                  .style("margin-right", "5px")
                  .style("margin-bottom", "5px")
                  .style("padding", "4px")
                  .style("line-height", "1.25em")
                  .style("border-radius", "10px")
                  .attr("contenteditable", true)
                  .on("input", (e) => {d3.select(e.target).datum().data.name = e.target.textContent})
                  .on("blur", () => {monaco.editor.getModels()[0].setValue(hier_to_yaml(hier))})
              },
              update => update.text(d => d.data.name),
              exit => exit.remove()
            )
    } else {
      parentdiv = sel
        .append("div")
        .text(`${d.data.name} (${d.leaves().length})`)
        .style("margin-left", d.depth * 10 + "px")
        .style("font-size", "1.25em")
        .style("font-weight","bold")
    }
  })
}
',
jsonlite::toJSON(dict_hier, auto_unbox = TRUE)
  )
))
)

browsable(html_block)
