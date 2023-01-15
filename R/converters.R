#' @keywords internal
recurse <- function(l, func, ...) {
  l <- func(l, ...)
  if (is.list(l) && length(l) > 0) {
    l <- lapply(l,
                function(ll) {
                  if (is.list(ll$children)) {
                    ll$children <- recurse(ll$children, func, ...)
                  }
                  return(ll)
                })
  } else {

  }
  return(l)
}

#' @keywords internal
convert_level <- function(l, idname = "name") {
  if (is.list(l) && !is.null(names(l))) {
    mapply(function(ll, nm) {
      if (!is.list(ll)) {
        ll <-
          lapply(ll, function(l3) {
            x <- list(l3)
            names(x) <- idname
            x
          })
      }
      x <- list(name = nm,
                children = ll)
      names(x) <- c(idname, "children")
      x
    },
    l,
    names(l),
    SIMPLIFY = FALSE,
    USE.NAMES = FALSE)
  } else {
    l
  }
}

#' Convert 'Quanteda' Dictionary to 'd3.js' Hierarchy
#'
#' @param dict \code{dictionary} from \code{quanteda}
#' @param idname \code{string} for the object property that contains the dictionary text; default is \code{"name"}
#'
#' @return \code{list} in `d3` hierarchy form
#' @export
convert_dict_hier <- function(dict, idname = "name") {
  x <- list(name = "dictionary",
            children = recurse(as.list(dict), convert_level, idname = idname))
  names(x) <- c(idname, "children")
  x
}

#' Convert 'Quanteda' Dictionary to Flat Hierarchy Data Frame
#'
#' @param dict \code{dictionary} from \code{quanteda}
#'
#' @return \code{data.frame}
#' @export
convert_dict_flat <- function(dict) {
  rows <-
    unlist(lapply(readLines(textConnection(as.yaml(
      dict
    ))), strsplit, split = "  "), recursive = FALSE)
  height <- max(sapply(rows, length))
  l <- lapply(rows,
              function(rw) {
                l <- length(rw)
                if (l == 0) {
                  return(NULL)
                }
                pad <- rep("", height - l)
                # handle when only one element then as.yaml combines to one row
                rw2 <- NULL
                if (grepl(x = tail(rw, 1), pattern = ":")) {
                  empties <- Filter(function(x) {
                    x == ""
                  }, rw)
                  sp <- unlist(strsplit(tail(rw, 1), split = ":"))
                  rw <- c(empties, head(sp, 1))
                  if (length(unlist(sp)) > 1) {
                    rw2 <- c(empties, "", trimws(tail(sp, 1)))
                  }
                }
                df <- data.frame(structure(as.list(c(
                  trimws(gsub(rw, pattern = "^(- )", replacement = "")), pad
                )),
                names = paste0("level", 1:height)),
                stringsAsFactors = FALSE)
                if (!is.null(rw2)) {
                  rbind(df,
                        data.frame(structure(
                          as.list(c(rw2, head(
                            pad, length(pad) - 1
                          ))),
                          names = paste0("level", 1:height)
                        ),
                        stringsAsFactors = FALSE))
                } else {
                  df
                }
              })
  df <- do.call(rbind, Filter(Negate(is.null), l))

  # fill "" for all levels except last
  filler <- unlist(df[1, ])

  unique(do.call(rbind,
                 apply(df, MARGIN = 1, function(rw) {
                   notblank <- which(rw != "")
                   if (notblank > 1) {
                     rw[(1:(notblank - 1))] <- filler[(1:(notblank - 1))]
                   }
                   filler[notblank] <<- trimws(rw[notblank])
                   return(data.frame(as.list(rw), stringsAsFactors = FALSE))
                 })))
}
