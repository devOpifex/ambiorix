Route <- R6::R6Class(
  "Route",
  public = list(
    path = NULL,
    components = list(),
    pattern = NULL,
    dynamic = FALSE,
    initialize = function(path){
      assert_that(not_missing(path))
      self$path <- gsub("\\?.*$", "", path) # remove query
      self$dynamic <- grepl(":", path)
      self$decompose()
      self$as_pattern()
    },
    as_pattern = function(){
      if(!is.null(.globals$pathToPattern)) {
        self$pattern <-.globals$pathToPattern(self$path)
        return(
          invisible(self)
        )
      }

      pattern <- sapply(self$components, function(comp){
        if(comp$dynamic)
          return("[[:alnum:][:space:][:punct:]]*")

        return(comp$name)
      })

      pattern <- paste0(pattern, collapse = "/")
      self$pattern <- paste0("^/", pattern, "$")
      invisible(self)
    },
    decompose = function(){
      # split
      components <- strsplit(self$path, "(?<=.)(?=[:/])", perl = TRUE)[[1]]

      # remove lonely /
      components <- components[components != "/"]

      if(length(components) == 0){
        self$components <- list(
          list(
            index = 1L, 
            dynamic = FALSE,
            name = ""
          )
        )
        return()
      }

      # cleanup
      components <- gsub("/", "", components)

      components <- as.list(components)
      comp <- list()
      for(i in 1:length(components)){
        c <- list(
          index = i, 
          dynamic = grepl(":", components[[i]]),
          name = gsub(":|$", "", components[[i]])
        )
        comp <- append(comp, list(c))
      }

      self$components <- comp
      invisible(self)
    },
    print = function(){
      cli::cli_rule("Ambiorix", right = "route")
      cat("Only used internally\n")
    }
  )
)

#' Path to pattern
#' 
#' identify a function as a path to pattern function;
#' a function that accepts a path and returns a matching pattern.
#' 
#' @param path A function that accepts a character vector of length 1
#' and returns another character vector of length 1.
#' 
#' @export 
as_path_to_pattern <- function(path) {
  assert_that(is_function(path))

  structure(
    path,
    class = c(
      "pathToPattern",
      class(path)
    )
  )
}


#' @export 
print.pathToPattern <- function(x, ...) {
  cli::cli_alert_info("A path to pattern converter")
}

#' @keywords internal
is_path_to_pattern <- function(obj) {
  inherits(obj, "pathToPattern")
}
