##' Initializes smisc
##' @details you must call tinit (in package rterra) before calling this
##' @export
smisc.init <- function(){
    terraAddLookupPaths(system.file("terra", package="smiscrterra"))
}
