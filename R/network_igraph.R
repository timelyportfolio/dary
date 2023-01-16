library(quanteda)
library(dary)
library(htmltools)
library(d3r)
library(igraph)
library(robservable)

dict_corrosion <- dictionary(file = "./inst/corrosion_keywords.yml")

browsable(
  tagList(
    d3r::d3_dep_v7(),
    tags$script(HTML(sprintf(
"
const hier = d3.hierarchy(%s)
// in JavaScript with can get source/target format easily with d3
console.log(hier.links())
",
jsonlite::toJSON(dary::convert_dict_hier(dict_corrosion), auto_unbox = TRUE)
    )))
  )
)

dict_corrosion_flat <- convert_dict_flat(dict_corrosion)
nodes <- data.frame(name=unique(unlist(dict_corrosion_flat[,c("level2","level3")])))
# remove empty nodes
nodes <- nodes[which(nodes$name != ""),]
links <- dict_corrosion_flat[which(dict_corrosion_flat$level3 != ""),c("level2","level3")][,c(2,1)]
colnames(links) <- c("from","to")
ig <- igraph::graph_from_data_frame(links, vertices=nodes)

robservable(
  "https://observablehq.com/@mbostock/hello-cola",
  input = list(data = d3r::d3_igraph(ig), height = 1000),
  include = "chart"
)

# add label to vertices so dot format will show words not id numbers
V(ig)$label <- names(V(ig))
# color by out degree
deg <- degree(ig, mode="out")
# highlight those with out degree > 1
V(ig)[which(deg>1)]$color <- "yellow" #scales::col_numeric(domain = NULL, palette="RdYlBu")(deg)
V(ig)[which(deg>1)]$style <- "filled"
#write.graph(ig, "ig.gv", format="dot")
# open output file in https://microsoft.github.io/msagljs/svg_backend/index.html
