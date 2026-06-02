#' Check if Python module pmf_dark is available
#'
#' @return `TRUE` if `pmf_dark` is available in the active Python environment.
#' @export
pmf_dark_available <- function() {
  reticulate::py_module_available("pmf_dark")
}

#' Import the Python pmf_dark module
#'
#' @param delay_load Whether to delay module loading until first use.
#'
#' @return A Python module object from `reticulate::import()`.
#' @export
pmf_dark_module <- function(delay_load = TRUE) {
  reticulate::import("pmf_dark", delay_load = delay_load)
}
