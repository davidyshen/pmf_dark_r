#' Check PMF-Dark Python Dependencies
#'
#' Verifies that the required Python environment and dependencies are available:
#' 1. Python version 3.12 or greater.
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

  # 2. Check Python version >= 3.12
  py_ver <- reticulate::py_version()
  if (py_ver < "3.12") {
    stop(sprintf(
      "Python 3.12 or greater is required. Active Python version is %s.",
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
#' @return `TRUE` if Python >= 3.12 is available, and both `torch` and `pmf_dark`
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

#' Compute Dark Diversity (Functional API)
#'
#' Exposes the `compute_dark_diversity` function from the Python `pmf_dark` package.
#' Kept for backward compatibility.
#'
#' @param y Species presence-absence/count matrix (n_sites, n_species)
#' @param x Environmental predictor matrix (n_sites, n_env)
#' @param model_type "linear" | "gaussian" | "bnn" (default: "gaussian")
#' @param num_factors Number of latent factors for residual covariance (default: 1)
#' @param method "svi" | "mcmc" (default: "svi")
#' @param cuda GPU computation (SVI only) (default: FALSE)
#' @param include_latent Include latent factors in predictions (default: TRUE)
#' @param return_means Return means or full posterior samples (default: TRUE)
#' @param batch_size Mini-batch size for SVI training (default: NULL)
#' @param pred_batch_size Site-chunk size for prediction output (default: NULL)
#' @param categorical_cols Explicit list of column names in x to treat as categorical variables (default: NULL)
#' @param ... Extra model/method specific arguments (kwargs)
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
  pred_batch_size = NULL,
  categorical_cols = NULL,
  ...
) {
  # 1. Retrieve the imported python module (which triggers dependency checks)
  mod <- pmf_dark_module()

  # Ensure categorical_cols is passed as a list (to avoid single-string split issues in Python)
  if (!is.null(categorical_cols)) {
    categorical_cols <- as.list(categorical_cols)
  }

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
    },
    categorical_cols = categorical_cols,
    ...
  )
}

#' Fit a PMFDark Model (Object-Oriented API)
#'
#' Instantiates a `PMFDark` model from the Python package `pmf_dark` and trains
#' it on the provided datasets.
#'
#' @param y Species presence-absence/count matrix (n_sites, n_species)
#' @param x Environmental predictor matrix (n_sites, n_env)
#' @param model_type Ecological response model: "linear", "gaussian", or "bnn" (default: "gaussian")
#' @param num_factors Number of latent factors for residual covariance (default: 1)
#' @param method Inference method: "svi" or "mcmc" (default: "svi")
#' @param cuda Use GPU computation (SVI only) (default: FALSE)
#' @param categorical_cols Explicit list of column names in x to treat as categorical variables (default: NULL)
#' @param batch_size Mini-batch size (SVI only) (default: NULL)
#' @param model_args List of extra response-model specific arguments passed to the `PMFDark` constructor.
#' @param ... Extra hyperparameters for SVI (e.g. `num_iterations`, `lr`) or MCMC (e.g. `num_chains`) passed to `model$fit()`.
#'
#' @return A fitted `PMFDark` Python model object.
#' @export
pmf_fit <- function(
  y,
  x,
  model_type = "gaussian",
  num_factors = 1,
  method = "svi",
  cuda = FALSE,
  categorical_cols = NULL,
  batch_size = NULL,
  model_args = list(),
  ...
) {
  # 1. Retrieve raw module
  mod <- pmf_dark_module()

  # 2. Instantiate PMFDark class
  init_args <- c(
    list(
      model_type = model_type,
      num_factors = as.integer(num_factors),
      method = method,
      cuda = cuda
    ),
    model_args
  )
  model <- do.call(mod$PMFDark, init_args)

  # 3. Handle categorical cols list conversion
  if (!is.null(categorical_cols)) {
    categorical_cols <- as.list(categorical_cols)
  }

  # 4. Fit the model
  model$fit(
    y = y,
    x = x,
    categorical_cols = categorical_cols,
    batch_size = if (is.null(batch_size)) NULL else as.integer(batch_size),
    ...
  )

  # 5. Return the fitted model
  return(model)
}

#' Predict current species distribution
#'
#' Generates species occurrence probabilities (with latent factors) from a fitted `PMFDark` model.
#'
#' @param model A fitted `PMFDark` model object returned by `pmf_fit()`.
#' @param pred_batch_size Chunk size to process sites during prediction (default: NULL).
#' @param return_means Returns a data frame of posterior means if TRUE, or a raw array of posterior samples if FALSE.
#'
#' @return A data frame of posterior means (if TRUE) or a NumPy array of raw posterior samples (if FALSE).
#' @export
pmf_distribution <- function(
  model,
  pred_batch_size = NULL,
  return_means = TRUE
) {
  model$distribution(
    pred_batch_size = if (is.null(pred_batch_size)) {
      NULL
    } else {
      as.integer(pred_batch_size)
    },
    return_means = return_means
  )
}

#' Predict potential species pool
#'
#' Generates species pool predictions (environment-only / counterfactuals) from a fitted `PMFDark` model.
#'
#' @param model A fitted `PMFDark` model object returned by `pmf_fit()`.
#' @param pred_batch_size Chunk size to process sites during prediction (default: NULL).
#' @param return_means Returns a data frame of posterior means if TRUE, or a raw array of posterior samples if FALSE.
#'
#' @return A data frame of posterior means (if TRUE) or a NumPy array of raw posterior samples (if FALSE).
#' @export
pmf_pool <- function(model, pred_batch_size = NULL, return_means = TRUE) {
  model$pool(
    pred_batch_size = if (is.null(pred_batch_size)) {
      NULL
    } else {
      as.integer(pred_batch_size)
    },
    return_means = return_means
  )
}

#' Predict dark diversity
#'
#' Generates estimated dark diversity (potential pool where not observed) from a fitted `PMFDark` model.
#'
#' @param model A fitted `PMFDark` model object returned by `pmf_fit()`.
#' @param pred_batch_size Chunk size to process sites during prediction (default: NULL).
#' @param return_means Returns a data frame of posterior means if TRUE, or a raw array of posterior samples if FALSE.
#'
#' @return A data frame of posterior means (if TRUE) or a NumPy array of raw posterior samples (if FALSE).
#' @export
pmf_dark <- function(model, pred_batch_size = NULL, return_means = TRUE) {
  model$dark(
    pred_batch_size = if (is.null(pred_batch_size)) {
      NULL
    } else {
      as.integer(pred_batch_size)
    },
    return_means = return_means
  )
}

.onLoad <- function(libname, pkgname) {
  if (pmf_dark_available()) {
    tryCatch(
      {
        reticulate::import("pmf_dark", delay_load = FALSE)
      },
      error = function(e) {
        # Ignore error to avoid failing package load if there's an import issue
      }
    )
  }
}
