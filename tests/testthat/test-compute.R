test_that("compute_dark_diversity forwards arguments correctly", {
  ret_ns <- asNamespace("reticulate")
  orig_py_available <- ret_ns$py_available
  orig_py_version <- ret_ns$py_version
  orig_py_module_available <- ret_ns$py_module_available
  orig_import <- ret_ns$import

  # Mock storage for arguments
  called_args <- list()

  mock_compute <- function(
    y,
    x,
    model_type,
    num_factors,
    method,
    cuda,
    include_latent,
    return_means,
    batch_size,
    pred_batch_size,
    categorical_cols,
    ...
  ) {
    called_args <<- list(
      y = y,
      x = x,
      model_type = model_type,
      num_factors = num_factors,
      method = method,
      cuda = cuda,
      include_latent = include_latent,
      return_means = return_means,
      batch_size = batch_size,
      pred_batch_size = pred_batch_size,
      categorical_cols = categorical_cols,
      extra_arg = list(...)$extra_arg
    )
    return("test_result")
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
      function(...) numeric_version("3.13.1"),
      envir = ret_ns
    )
    assign("py_module_available", function(module) TRUE, envir = ret_ns)

    mock_mod <- new.env(parent = emptyenv())
    mock_mod$compute_dark_diversity <- mock_compute
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

  # Call the R function
  res <- compute_dark_diversity(
    y = matrix(1:4, 2, 2),
    x = matrix(5:8, 2, 2),
    model_type = "gaussian",
    num_factors = 1,
    method = "svi",
    cuda = FALSE,
    include_latent = TRUE,
    return_means = TRUE,
    batch_size = 10,
    pred_batch_size = NULL,
    categorical_cols = c("col1", "col2"),
    extra_arg = "extra_val"
  )

  # Check return value
  expect_equal(res, "test_result")

  # Verify arguments
  expect_equal(called_args$model_type, "gaussian")
  expect_equal(called_args$num_factors, 1L) # Should be cast to integer
  expect_equal(called_args$method, "svi")
  expect_false(called_args$cuda)
  expect_true(called_args$include_latent)
  expect_true(called_args$return_means)
  expect_equal(called_args$batch_size, 10L) # Should be cast to integer
  expect_null(called_args$pred_batch_size)
  expect_equal(called_args$categorical_cols, list("col1", "col2"))
  expect_equal(called_args$extra_arg, "extra_val")

  # Call with a single string to verify list conversion (prevents character splitting in Python)
  compute_dark_diversity(
    y = matrix(1:4, 2, 2),
    x = matrix(5:8, 2, 2),
    categorical_cols = "landuse"
  )
  expect_equal(called_args$categorical_cols, list("landuse"))
})

test_that("use_python forwards arguments correctly to reticulate", {
  ret_ns <- asNamespace("reticulate")
  orig_use_python <- ret_ns$use_python

  called_python <- NULL
  called_required <- NULL

  mock_use_python <- function(python, required) {
    called_python <<- python
    called_required <<- required
    invisible(NULL)
  }

  if (bindingIsLocked("use_python", ret_ns)) {
    unlockBinding("use_python", ret_ns)
  }
  assign("use_python", mock_use_python, envir = ret_ns)

  on.exit({
    if (bindingIsLocked("use_python", ret_ns)) {
      unlockBinding("use_python", ret_ns)
    }
    assign("use_python", orig_use_python, envir = ret_ns)
  })

  use_python("/path/to/python", required = FALSE)
  expect_equal(called_python, "/path/to/python")
  expect_false(called_required)

  use_python("/another/path")
  expect_equal(called_python, "/another/path")
  expect_true(called_required)
})
