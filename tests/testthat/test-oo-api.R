test_that("pmf_fit, pmf_distribution, pmf_pool, and pmf_dark work correctly", {
  ret_ns <- asNamespace("reticulate")
  orig_py_available <- ret_ns$py_available
  orig_py_version <- ret_ns$py_version
  orig_py_module_available <- ret_ns$py_module_available
  orig_import <- ret_ns$import

  # Mock class and model methods
  init_args <- list()
  fit_args <- list()
  distribution_args <- list()
  pool_args <- list()
  dark_args <- list()

  mock_fit <- function(y, x, categorical_cols, batch_size, ...) {
    fit_args <<- list(
      y = y,
      x = x,
      categorical_cols = categorical_cols,
      batch_size = batch_size,
      extra = list(...)$extra_fit_arg
    )
    invisible(NULL)
  }

  mock_distribution <- function(pred_batch_size, return_means) {
    distribution_args <<- list(
      pred_batch_size = pred_batch_size,
      return_means = return_means
    )
    return("distribution_result")
  }

  mock_pool <- function(pred_batch_size, return_means) {
    pool_args <<- list(
      pred_batch_size = pred_batch_size,
      return_means = return_means
    )
    return("pool_result")
  }

  mock_dark <- function(pred_batch_size, return_means) {
    dark_args <<- list(
      pred_batch_size = pred_batch_size,
      return_means = return_means
    )
    return("dark_result")
  }

  mock_pmf_dark_class <- function(model_type, num_factors, method, cuda, ...) {
    init_args <<- list(
      model_type = model_type,
      num_factors = num_factors,
      method = method,
      cuda = cuda,
      extra = list(...)$extra_model_arg
    )

    # Return mock model object
    model_obj <- new.env(parent = emptyenv())
    model_obj$fit <- mock_fit
    model_obj$distribution <- mock_distribution
    model_obj$pool <- mock_pool
    model_obj$dark <- mock_dark
    return(model_obj)
  }

  mock_reticulate <- function() {
    if (bindingIsLocked("py_available", ret_ns)) {
      unlockBinding("py_available", ret_ns)
    }
    if (bindingIsLocked("py_version", ret_ns)) {
      unlockBinding("py_version", ret_ns)
    }
    if (bindingIsLocked("py_module_available", ret_ns)) {
      unlockBinding("py_module_available", ret_ns)
    }
    if (bindingIsLocked("import", ret_ns)) {
      unlockBinding("import", ret_ns)
    }

    assign("py_available", function(...) TRUE, envir = ret_ns)
    assign(
      "py_version",
      function(...) numeric_version("3.12.1"),
      envir = ret_ns
    )
    assign("py_module_available", function(module) TRUE, envir = ret_ns)

    mock_mod <- new.env(parent = emptyenv())
    mock_mod$PMFDark <- mock_pmf_dark_class
    assign("import", function(...) mock_mod, envir = ret_ns)
  }

  restore_reticulate <- function() {
    if (bindingIsLocked("py_available", ret_ns)) {
      unlockBinding("py_available", ret_ns)
    }
    if (bindingIsLocked("py_version", ret_ns)) {
      unlockBinding("py_version", ret_ns)
    }
    if (bindingIsLocked("py_module_available", ret_ns)) {
      unlockBinding("py_module_available", ret_ns)
    }
    if (bindingIsLocked("import", ret_ns)) {
      unlockBinding("import", ret_ns)
    }

    assign("py_available", orig_py_available, envir = ret_ns)
    assign("py_version", orig_py_version, envir = ret_ns)
    assign("py_module_available", orig_py_module_available, envir = ret_ns)
    assign("import", orig_import, envir = ret_ns)
  }

  mock_reticulate()
  on.exit(restore_reticulate())

  # 1. Test model fitting
  y_mat <- matrix(1:4, 2, 2)
  x_mat <- matrix(5:8, 2, 2)
  model <- pmf_fit(
    y = y_mat,
    x = x_mat,
    model_type = "bnn",
    num_factors = 3,
    method = "mcmc",
    cuda = TRUE,
    categorical_cols = "landuse",
    batch_size = 50,
    model_args = list(extra_model_arg = "foo"),
    extra_fit_arg = "bar"
  )

  # Check constructor arguments
  expect_equal(init_args$model_type, "bnn")
  expect_equal(init_args$num_factors, 3L)
  expect_equal(init_args$method, "mcmc")
  expect_true(init_args$cuda)
  expect_equal(init_args$extra, "foo")

  # Check fit arguments
  expect_equal(fit_args$y, y_mat)
  expect_equal(fit_args$x, x_mat)
  expect_equal(fit_args$categorical_cols, list("landuse"))
  expect_equal(fit_args$batch_size, 50L)
  expect_equal(fit_args$extra, "bar")

  # 2. Test predictions and pipe chaining
  dist_res <- model |>
    pmf_distribution(pred_batch_size = 10, return_means = TRUE)
  pool_res <- model |> pmf_pool(pred_batch_size = NULL, return_means = FALSE)
  dark_res <- model |> pmf_dark()

  # Check distribution predictions
  expect_equal(dist_res, "distribution_result")
  expect_equal(distribution_args$pred_batch_size, 10L)
  expect_true(distribution_args$return_means)

  # Check pool predictions
  expect_equal(pool_res, "pool_result")
  expect_null(pool_args$pred_batch_size)
  expect_false(pool_args$return_means)

  # Check dark predictions
  expect_equal(dark_res, "dark_result")
  expect_null(dark_args$pred_batch_size)
  expect_true(dark_args$return_means)
})
