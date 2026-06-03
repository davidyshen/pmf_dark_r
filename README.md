# pmfDarkR

`pmfDarkR` is an R wrapper package for the [`pmf_dark`](https://github.com/davidyshen/pmf_dark) Python package, which uses PyTorch and Pyro to estimate dark diversity.

## Prerequisites

Before using `pmfDarkR`, ensure you have the following installed in your active Python environment:

1. **Python 3.12 or greater**
2. **`torch`** (PyTorch)
   - *Note: CUDA `torch` must be installed manually. You can choose either standard CPU `torch` or CUDA-enabled `torch` depending on your hardware and requirements.*
3. **`pmf_dark`** Python package

Use CUDA enabled `torch` if you have a compatible NVIDIA GPU and want to leverage GPU acceleration for faster computations using SVI. If you do not have a compatible GPU or prefer to run on CPU, the standard `torch` package should be installed automatically.

For more details on installing these dependencies, please refer to the [`pmf_dark` GitHub repository](https://github.com/davidyshen/pmf_dark).

## Installation

You can install the development version of `pmfDarkR` from GitHub using `remotes`:

```r
# If remotes is not installed:
# install.packages("remotes")

remotes::install_github("davidyshen/pmf_dark_r")
```

## Configuring Python Version

If you need to specify a custom Python binary or virtual environment, use `reticulate::use_python()`. Because `pmfDarkR` eagerly imports the Python module when the package is loaded (to show CUDA device information), you must load `reticulate` and call `use_python()` **before** loading the `pmfDarkR` package with `library()`:

```r
library(reticulate)
# Specify the Python executable path before loading pmfDarkR
use_python("/path/to/python")

# Load the package
library(pmfDarkR)
```

Alternatively, you can set the `RETICULATE_PYTHON` environment variable in your system or in a `.Renviron` file before starting your R session.

## Usage

Here is a quick example showing how to check dependencies and run the solver:

```r
library(pmfDarkR)

# 1. Check if all Python dependencies are met (Python >= 3.12, torch, pmf_dark)
if (pmf_dark_available()) {
  message("Ready to run PMF-Dark!")
} else {
  # This throws a clear error indicating which dependency is missing
  check_pmf_dark_dependencies()
}

# 2. Prepare presence-absence matrix (Y) and environmental predictors (X)
# Y: n_sites x n_species matrix
# X: n_sites x n_env matrix
y <- matrix(c(1, 0, 1, 1, 0, 1), nrow = 2, ncol = 3)
x <- matrix(c(0.5, -1.2, 1.4, 0.9), nrow = 2, ncol = 2)

# 3. Compute dark diversity using the wrapper function
result <- compute_dark_diversity(
  y = y,
  x = x,
  model_type = "gaussian",  # "linear" | "gaussian" | "bnn"
  num_factors = 1,          # Number of latent factors for residual covariance
  method = "svi",           # "svi" | "mcmc"
  cuda = FALSE,             # GPU computation (SVI only)
  include_latent = TRUE,    # Include latent factors in predictions
  return_means = TRUE,      # Return means or full posterior samples
  categorical_cols = NULL   # Explicit list of columns in x to treat as categorical variables
)

print(result)
```
