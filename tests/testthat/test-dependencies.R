test_that("check_pmf_dark_dependencies handles various scenarios correctly", {
  # Mock reticulate functions
  ret_ns <- asNamespace("reticulate")
  orig_py_available <- ret_ns$py_available
  orig_py_version <- ret_ns$py_version
  orig_py_module_available <- ret_ns$py_module_available
  orig_import <- ret_ns$import

  # Helper to mock reticulate functions
  mock_reticulate <- function(
    ver = "3.12.0",
    torch_avail = TRUE,
    pmf_avail = TRUE
  ) {
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
    assign("py_version", function(...) numeric_version(ver), envir = ret_ns)
    assign(
      "py_module_available",
      function(module) {
        if (module == "torch") {
          return(torch_avail)
        }
        if (module == "pmf_dark") {
          return(pmf_avail)
        }
        FALSE
      },
      envir = ret_ns
    )
    assign("import", function(...) "mock_module", envir = ret_ns)
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

  # Make sure we clean up even if a test fails
  on.exit(restore_reticulate())

  # 1. Test case: Python version is too old
  mock_reticulate(ver = "3.11.0", torch_avail = TRUE, pmf_avail = TRUE)
  expect_error(
    check_pmf_dark_dependencies(),
    "Python 3.12 or greater is required"
  )
  expect_false(pmf_dark_available())
  expect_error(
    pmf_dark_module(delay_load = FALSE),
    "Python 3.12 or greater is required"
  )

  # 2. Test case: Python version >= 3.12, but torch is missing
  mock_reticulate(ver = "3.12.1", torch_avail = FALSE, pmf_avail = TRUE)
  expect_error(check_pmf_dark_dependencies(), "torch.*is not installed")
  expect_false(pmf_dark_available())
  expect_error(pmf_dark_module(delay_load = FALSE), "torch.*is not installed")

  # 3. Test case: Python version >= 3.12, torch present, but pmf_dark is missing
  mock_reticulate(ver = "3.12.1", torch_avail = TRUE, pmf_avail = FALSE)
  expect_error(check_pmf_dark_dependencies(), "pmf_dark.*is not installed")
  expect_false(pmf_dark_available())
  expect_error(
    pmf_dark_module(delay_load = FALSE),
    "pmf_dark.*is not installed"
  )

  # 4. Test case: All dependencies met (Python >= 3.12, torch and pmf_dark present)
  mock_reticulate(ver = "3.12.1", torch_avail = TRUE, pmf_avail = TRUE)
  expect_silent(check_pmf_dark_dependencies())
  expect_true(pmf_dark_available())

  mod <- pmf_dark_module(delay_load = FALSE)
  expect_equal(mod, "mock_module")
})
