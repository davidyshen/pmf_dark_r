#' Check PMF-Dark Python Dependencies
#'
#' Verifies that the required Python environment and dependencies are available:
#' 1. Python version 3.13 or greater.
#' 2. Python package `torch`.
#' 3. Python package `pmf_dark`.
#'
#' @return Invisible `TRUE` if all dependencies are met, otherwise throws an error.
#' @export
check_pmf_dark_dependencies <- function() {
  # 1. Check Python is available and initialize
  if (!reticulate::py_available(initialize = TRUE)) {
    stop(
      "Python is not available or could not be initialized. Please install Python and ensure reticulate can access it."
    )
  }

  # 2. Check Python version >= 3.13
  py_ver <- reticulate::py_version()
  if (py_ver < "3.13") {
    stop(sprintf(
      "Python 3.13 or greater is required. Active Python version is %s.",
      as.character(py_ver)
    ))
  }

  # 3. Check if torch is installed
  if (!reticulate::py_module_available("torch")) {
    stop(
      "The Python 'torch' package is not installed. Please install it in the active Python environment."
    )
  }

  # 4. Check if pmf-dark package is installed
  if (!reticulate::py_module_available("pmf_dark")) {
    stop(
      "The Python 'pmf_dark' (pmf-dark) package is not installed. Please install it in the active Python environment."
    )
  }

  invisible(TRUE)
}

#' Check if Python module pmf_dark and its dependencies are available
#'
#' @return `TRUE` if Python >= 3.13 is available, and both `torch` and `pmf_dark`
#'   are installed; `FALSE` otherwise.
#' @export
pmf_dark_available <- function() {
  tryCatch(
    {
      check_pmf_dark_dependencies()
      TRUE
    },
    error = function(e) {
      FALSE
    }
  )
}

#' Import the Python pmf_dark module
#'
#' @param delay_load Whether to delay module loading until first use. Can be a
#'   logical value or a list of callbacks for `reticulate::import()`.
#'
#' @return A Python module object from `reticulate::import()`.
#' @export
pmf_dark_module <- function(delay_load = TRUE) {
  if (isTRUE(delay_load)) {
    delay_load <- list(
      before_load = function() {
        check_pmf_dark_dependencies()
      }
    )
  } else if (identical(delay_load, FALSE)) {
    check_pmf_dark_dependencies()
  }

  reticulate::import("pmf_dark", delay_load = delay_load)
}

#' Compute Dark Diversity
#'
#' Exposes the `compute_dark_diversity` function from the Python `pmf_dark` package.
#'
#' @param y Species presence-absence matrix (n_sites, n_species)
#' @param x Environmental predictor matrix (n_sites, n_env)
#' @param model_type "linear" | "gaussian" | "bnn" (default: "gaussian")
#' @param num_factors Number of latent factors for residual covariance (default: 1)
#' @param method "svi" | "mcmc" (default: "svi")
#' @param cuda GPU computation (SVI only) (default: FALSE)
#' @param include_latent Include latent factors in predictions (default: TRUE)
#' @param return_means Return means or full posterior samples (default: TRUE)
#' @param batch_size Mini-batch size for SVI training (default: NULL)
#' @param pred_batch_size Site-chunk size for prediction output (default: NULL)
#'
#' @return The result from the underlying Python call.
#' @export
compute_dark_diversity <- function(
  y,
  x,
  model_type = "gaussian",
  num_factors = 1,
  method = "svi",
  cuda = FALSE,
  include_latent = TRUE,
  return_means = TRUE,
  batch_size = NULL,
  pred_batch_size = NULL
) {
  # 1. Retrieve the imported python module (which triggers dependency checks)
  mod <- pmf_dark_module()

  # 2. Call the Python function, casting integer types as needed so they are correctly passed to python
  mod$compute_dark_diversity(
    y = y,
    x = x,
    model_type = model_type,
    num_factors = as.integer(num_factors),
    method = method,
    cuda = cuda,
    include_latent = include_latent,
    return_means = return_means,
    batch_size = if (is.null(batch_size)) NULL else as.integer(batch_size),
    pred_batch_size = if (is.null(pred_batch_size)) {
      NULL
    } else {
      as.integer(pred_batch_size)
    }
  )
}
