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
links$from <- match(links$from, nodes)
links$to <- match(links$to, nodes)
ig <- igraph::graph_from_data_frame(links)
# set a value and group only so robservable second works
V(ig)$group <- 1
E(ig)$value <- 1

robservable(
  "https://observablehq.com/@mbostock/hello-cola",
  input = list(data = d3r::d3_igraph(ig), height = 1000),
  include = "chart"
)

# some transformation so it works with a sortable adjacency matrix
ig_d3 <- d3r::d3_igraph(ig, json=FALSE)
ig_d3$nodes$name <- nodes
ig_d3$nodes$id <- as.numeric(ig_d3$nodes$id)
ig_d3$links$source <- as.numeric(ig_d3$links$source)
ig_d3$links$target <- as.numeric(ig_d3$links$target)
robservable(
  "https://observablehq.com/d/36f9ac199d2228db",
  input = list(
    graph = jsonlite::toJSON(ig_d3, dataframe="rows", auto_unbox=TRUE))
)

robservable(
  "https://observablehq.com/d/199c65dc4ba270ac",
  input = list(
    graph = jsonlite::toJSON(ig_d3, dataframe="rows", auto_unbox=TRUE))
)

# add label to vertices so dot format will show words not id numbers
V(ig)$label <- nodes[as.numeric(names(V(ig)))]
# color by out degree
deg <- degree(ig, mode="out")
# highlight those with out degree > 1
V(ig)[which(deg>1)]$color <- "yellow" #scales::col_numeric(domain = NULL, palette="RdYlBu")(deg)
V(ig)[which(deg>1)]$style <- "filled"
#write.graph(ig, "ig.gv", format="dot")
# open output file in https://microsoft.github.io/msagljs/svg_backend/index.html
