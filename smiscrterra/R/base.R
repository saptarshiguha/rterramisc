##' Initializes smisc
##' @details you must call tinit (in package rterra) before calling this
##' @export
smisc.init <- function(){
    terraAddLookupPaths(system.file("terra", package="smiscrterra"),package="smiscrterra")
    terraStr(sprintf("terralib.linklibrary('%s')", system.file("libs/tbb.so",package="smiscrterra")))
}
