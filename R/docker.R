#' Dockerfile
#' 
#' Create the dockerfile required to run the application.
#' The dockerfile created will install packages from 
#' RStudio Public Package Manager 
#' which comes with pre-built binaries
#' that much improve the speed of building of Dockerfiles.
#' 
#' @details Reads the `DESCRIPTION` file of the project to produce the `Dockerfile`.
#' 
#' @param port,host Port and host to serve the application.
#' 
#' @examples 
#' \dontrun{create_dockerfile()}
#' 
#' @export
create_dockerfile <- function(port, host = "0.0.0.0"){
  assert_that(has_file("DESCRIPTION"))
  assert_that(not_missing(port))

  cli::cli_alert_warning("Ensure your {.file DESCRIPTION} file is up to date with {.fun devtools::check}")

  # ensure integer
  port <- as.integer(port)

  dockerfile <- c(
    "FROM jcoenep/ambiorix",
    "RUN echo \"options(repos = c(CRAN = 'https://packagemanager.rstudio.com/all/latest'))\" >> /usr/local/lib/R/etc/Rprofile.site",
    "RUN R -e 'install.packages(\"remotes\")'"
  )

  # CRAN packages
  desc <- read.dcf("DESCRIPTION")
  pkgs <- desc[, "Imports"]
  pkgs <- strsplit(pkgs, ",")[[1]]
  pkgs <- gsub("\\\n", "", pkgs)
  cran <- sapply(pkgs, function(pkg){
    sprintf("RUN R -e \"install.packages('%s')\"", pkg)
  })

  # remotes
  rmts <- tryCatch(desc[, 'Remotes'], error = function(e) NULL)
  if(!is.null(rmts)){
    rmts <- strsplit(rmts, ",")[[1]]
    rmts <- gsub("\\\n", "", rmts)
    rmts <- rmts[rmts != "ambiorix"]
    rmts <- sapply(rmts, function(pkg){
      sprintf("RUN R -e \"remotes::install_github('%s', force=FALSE)\"", pkg)
    })
    cran <- c(cran, rmts)
  }

  cmd <- sprintf(
    "CMD R -e \"options(ambiorix.host='%s', 'ambiorix.port'=%s);source('app.R')\"", 
    host, port
  )

  dockerfile <- c(
    dockerfile,
    cran,
    "COPY . .",
    cmd
  )

  x <- writeLines(dockerfile, "Dockerfile")

  cli::cli_alert_success("Created {.file Dockerfile}")

  invisible()
}