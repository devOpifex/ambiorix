#' Core Routing Class
#' 
#' Core routing class.
#' Do not use directly, see [Ambiorix], and [Router].
#' 
#' @field error Error handler.
#' 
#' @keywords export
Routing <- R6::R6Class(
  "Routing",
  public = list(
    error = NULL,
#' @details Initialise
#' @param path Prefix path.
    initialize = function(path = "") {
      self$error <- \(req, res) {
        response_500()
      }
      private$.basepath <- path
      private$.is_router <- path != ""
    },
#' @details GET Method
#' 
#' Add routes to listen to.
#' 
#' @param path Route to listen to, `:` defines a parameter.
#' @param handler Function that accepts the request and returns an object 
#' describing an httpuv response, e.g.: [response()].
#' @param error Handler function to run on error.
#' 
#' @examples 
#' app <- Ambiorix$new()
#' 
#' app$get("/", function(req, res){
#'  res$send("Using {ambiorix}!")
#' })
#' 
#' if(interactive())
#'  app$start()
    get = function(path, handler, error = NULL){
      assert_that(valid_path(path))
      assert_that(not_missing(handler))
      assert_that(is_handler(handler))

      private$.routes[[uuid()]] <- list(
        route = Route$new(private$.make_path(path)), 
        path = path, 
        fun = handler, 
        method = "GET",
        error = error %error% self$error
      )

      invisible(self)
    },
#' @details PUT Method
#' 
#' Add routes to listen to.
#' 
#' @param path Route to listen to, `:` defines a parameter.
#' @param handler Function that accepts the request and returns an object 
#' describing an httpuv response, e.g.: [response()].
#' @param error Handler function to run on error.
    put = function(path, handler, error = NULL){
      assert_that(valid_path(path))
      assert_that(not_missing(handler))
      assert_that(is_handler(handler))

      private$.routes[[uuid()]] <- list(
        route = Route$new(private$.make_path(path)), 
        path = path, 
        fun = handler, 
        method = "PUT",
        error = error %error% self$error
      )

      invisible(self)
    },
#' @details PATCH Method
#' 
#' Add routes to listen to.
#' 
#' @param path Route to listen to, `:` defines a parameter.
#' @param handler Function that accepts the request and returns an object 
#' describing an httpuv response, e.g.: [response()].
#' @param error Handler function to run on error.
    patch = function(path, handler, error = NULL){
      assert_that(valid_path(path))
      assert_that(not_missing(handler))
      assert_that(is_handler(handler))

      private$.routes[[uuid()]] <- list(
        route = Route$new(private$.make_path(path)), 
        path = path, 
        fun = handler, 
        method = "PATCH",
        error = error %error% self$error
      )

      invisible(self)
    },
#' @details DELETE Method
#' 
#' Add routes to listen to.
#' 
#' @param path Route to listen to, `:` defines a parameter.
#' @param handler Function that accepts the request and returns an object 
#' describing an httpuv response, e.g.: [response()].
#' @param error Handler function to run on error.
    delete = function(path, handler, error = NULL){
      assert_that(valid_path(path))
      assert_that(not_missing(handler))
      assert_that(is_handler(handler))

      private$.routes[[uuid()]] <- list(
        route = Route$new(private$.make_path(path)), 
        path = path, 
        fun = handler, 
        method = "DELETE",
        error = error %error% self$error
      )

      invisible(self)
    },
#' @details POST Method
#' 
#' Add routes to listen to.
#' 
#' @param path Route to listen to.
#' @param handler Function that accepts the request and returns an object 
#' describing an httpuv response, e.g.: [response()].
#' @param error Handler function to run on error.
    post = function(path, handler, error = NULL){
      assert_that(valid_path(path))
      assert_that(not_missing(handler))
      assert_that(is_handler(handler))

      private$.routes[[uuid()]] <- list(
        route = Route$new(private$.make_path(path)), 
        path = path, 
        fun = handler, 
        method = "POST",
        error = error %error% self$error
      )

      invisible(self)
    },
#' @details OPTIONS Method
#'
#' Add routes to listen to.
#'
#' @param path Route to listen to.
#' @param handler Function that accepts the request and returns an object
#' describing an httpuv response, e.g.: [response()].
#' @param error Handler function to run on error.
    options = function(path, handler, error = NULL){
      assert_that(valid_path(path))
      assert_that(not_missing(handler))
      assert_that(is_handler(handler))

      private$.routes[[uuid()]] <- list(
        route = Route$new(private$.make_path(path)), 
        path = path,
        fun = handler,
        method = "OPTIONS",
        error = error %error% self$error
      )

      invisible(self)
    },
#' @details All Methods
#' 
#' Add routes to listen to for all methods `GET`, `POST`, `PUT`, `DELETE`, and `PATCH`.
#' 
#' @param path Route to listen to.
#' @param handler Function that accepts the request and returns an object 
#' describing an httpuv response, e.g.: [response()].
#' @param error Handler function to run on error.
    all = function(path, handler, error = NULL){
      assert_that(valid_path(path))
      assert_that(not_missing(handler))
      assert_that(is_handler(handler))

      private$.routes[[uuid()]] <- list(
        route = Route$new(private$.make_path(path)), 
        path = path, 
        fun = handler, 
        method = c("GET", "POST", "PUT", "DELETE", "PATCH"),
        error = error %error% self$error
      )
      
      invisible(self)
    },
#' @details Receive Websocket Message
#' @param name Name of message.
#' @param handler Function to run when message is received.
#' 
#' @examples 
#' app <- Ambiorix$new()
#' 
#' app$get("/", function(req, res){
#'  res$send("Using {ambiorix}!")
#' })
#' 
#' app$receive("hello", function(msg, ws){
#'  print(msg) # print msg received
#'  
#'  # send a message back
#'  ws$send("hello", "Hello back! (sent from R)")
#' })
#' 
#' if(interactive())
#'  app$start()
    receive = function(name, handler){
      private$.receivers[[uuid()]] <- WebsocketHandler$new(name, handler)
      invisible(self)
    },
#' @details Print
    print = function(){
      cli::cli_rule("Ambiorix", right = "web server")
      cli::cli_li("routes: {.val {private$.n_routes()}}")
    },
#' @details Use a router or middleware
#' @param use Either a router as returned by [Router], a function to use as middleware,
#' or a `list` of functions.
#' If a function is passed, it must accept two arguments (the request, and the response): 
#' this function will be executed every time the server receives a request.
#' _Middleware may but does not have to return a response, unlike other methods such as `get`_
#' Note that multiple routers and middlewares can be used.
    use = function(use){
      assert_that(not_missing(use))
      
      # recurse through items
      if(is.list(use)) {
        for(i in 1:length(use)) {
          self$use(use[[i]])
        }
      }
      
      # mount router
      if(inherits(use, "Router")){
        private$.routes <- append(private$.routes, use$get_routes())
        private$.receivers <- append(private$.receivers, use$get_receivers())
      } 
      
      if(is_cookie_parser(use) && private$.is_router){
        .globals$errorLog$log(
          "Cannot pass cookie parser to `Router`, only to `Ambiorix`"
        )
        return(invisible(self))
      }

      if(is_cookie_parser(use)) {
        .globals$cookieParser <- use
        return(invisible(self))
      }

      if(is_cookie_preprocessor(use) && private$.is_router){
        .globals$errorLog$log(
          "Cannot pass cookie preprocessor to `Router`, only to `Ambiorix`"
        )
        return(invisible(self))
      }

      if(is_cookie_preprocessor(use)) {
        .globals$cookiePreprocessors <- append(
          .globals$cookiePreprocessors,
          use
        )
        return(invisible(self))
      }

      # pass middleware
      if(is.function(use)) { 
        assert_that(is_handler(use))
        private$.middleware <- append(private$.middleware, use)
        return(invisible(self))
      }

      invisible(self)
    },
#' @details Get the routes
    get_routes = function(){
      return(private$.routes)
    },
#' @details Get the receivers
    get_receivers = function(){
      return(private$.receivers)
    }
  ),
  private = list(
    .basepath = "",
    .is_router = FALSE,
    .routes = list(),
    .static = list(),
    .receivers = list(),
    .middleware = list(),
    .is_running = FALSE,
    # we reorder the routes before launching the app
    # we make sure the longest patterns are checked first
    # this makes sure /:id/x matches BEFORE /:id does
    reorder_routes = function() {
      if(length(private$.routes) < 3L)
        return()

      indices <- 1:length(private$.routes)
      pats <- sapply(private$.routes, \(route) {
        route$route$pattern
      })
        
      pats <- nchar(pats)

      names(pats) <- indices
      pats <- sort(pats, decreasing = TRUE)
      order <- as.integer(names(pats))
      
      new_routes <- as.list(c(1:length(order)))
      for(i in 1:length(order)) {
        new_routes[[i]] <- private$.routes[[order[i]]]
      }

      private$.routes <- new_routes
    },
    .call = function(req){

      request <- Request$new(req)
      res <- Response$new()

      if(length(private$.middleware) > 0){
        for(i in 1:length(private$.middleware)) {
          mid_res <- private$.middleware[[i]](request, res)

          if(is_response(mid_res))
            res <- mid_res
        }
      }
      
      # loop over routes
      for(i in 1:length(private$.routes)){
        # if path matches pattern and method
        if(grepl(private$.routes[[i]]$route$pattern, req$PATH_INFO) && req$REQUEST_METHOD %in% private$.routes[[i]]$method){
          
          .globals$infoLog$log(req$REQUEST_METHOD, "on", req$PATH_INFO)

          # parse request
          request$params <- set_params(request$PATH_INFO, private$.routes[[i]]$route)

          # get response
          response <- tryCatch(private$.routes[[i]]$fun(request, res),
            error = function(error){
              warning(error)
              private$.routes[[i]]$error(request, res)
            }
          )

          if(promises::is.promising(response)){
            return(
              promises::then(
                response, 
                onFulfilled = function(response){
                  return(
                    response %response% response("Must return a response", status = 206L)
                  )
                },
                onRejected = function(error){
                  message(error)
                  .globals$errorLog$log(req$REQUEST_METHOD, "on", req$PATH_INFO, "-", "Server error")
                  private$.routes[[i]]$error(request, res)
                }
              )
            )
          }

          if(is_forward(response))
            next

          # if not a response return something that is
          return(
            response %response% response("Must return a response", status = 206L)
          )
        }
      }

      .globals$errorLog$log(request$REQUEST_METHOD, "on", request$PATH_INFO, "- Not found")

      # return 404
      request$params <- set_params(request$PATH_INFO, Route$new(request$PATH_INFO))
      return(self$not_found(request, res))
    },
    .wss = function(ws){

      # receive
      ws$onMessage(function(binary, message) {
        # don't run if no receiver
        if(length(private$.receivers) == 0) return(NULL)

        message <- jsonlite::fromJSON(message)

        for(i in 1:length(private$.receivers)){
          if(private$.receivers[[i]]$is_handler(message)){
            .globals$infoLog$log("Received message from websocket:", message$name)
            return(private$.receivers[[i]]$receive(message, ws))
          }
        }

      })
    }, 
    n_routes = function(){
      length(private$.routes)
    },
    .make_path = function(path){
      paste0(private$.basepath, path)
    }
  )
)
