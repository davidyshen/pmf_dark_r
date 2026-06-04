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

## Usage (Object-Oriented API)

The recommended way to use `pmfDarkR` is via the object-oriented API, which fits the model once and allows you to easily query different predictions (current distribution, potential species pool, and dark diversity) using R's native pipe operator (`|>`):

```r
library(pmfDarkR)

# 1. Prepare presence-absence matrix (Y) and environmental predictors (X)
# Y: n_sites x n_species matrix
# X: n_sites x n_env matrix
y <- matrix(c(1, 0, 1, 1, 0, 1), nrow = 2, ncol = 3)
x <- matrix(c(0.5, -1.2, 1.4, 0.9), nrow = 2, ncol = 2)

# 2. Fit the model (instantiates PMFDark and immediately fits it)
model <- pmf_fit(
  y = y,
  x = x,
  model_type = "gaussian",  # Ecological response model: "linear" | "gaussian" | "bnn"
  num_factors = 1,          # Number of latent factors
  method = "svi",           # Inference method: "svi" | "mcmc"
  num_iterations = 2500,     # Fit hyperparameter passed via ...
  categorical_cols = NULL   # Explicitly treat columns in x as categorical
)

# 3. Generate predictions using pipe chaining
p_dist <- model |> pmf_distribution() # Current species distribution (with latent factors)
p_pool <- model |> pmf_pool()         # Potential species pool (counterfactual / env only)
p_dark <- model |> pmf_dark()         # Dark diversity (pool prediction where species is not observed)

print(p_dark)
```

### Backward Compatibility (Functional API)

For backward compatibility, the functional API `compute_dark_diversity()` is still provided:

```r
result <- compute_dark_diversity(
  y = y,
  x = x,
  model_type = "gaussian",
  num_factors = 1,
  method = "svi",
  cuda = FALSE,
  include_latent = TRUE,
  return_means = TRUE
)
```
