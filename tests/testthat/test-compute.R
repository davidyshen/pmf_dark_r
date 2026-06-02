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
    pred_batch_size
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
      pred_batch_size = pred_batch_size
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
    pred_batch_size = NULL
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
})
