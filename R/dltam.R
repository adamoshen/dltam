#' Calculate the dynamic local trend association measure
#'
#' Calculate the dynamic local trend association measure (DLTAM) for a pair of time series.
#'
#' For a time series, the Moving Approximation Transform (MAT) uses a least-sqaures approach similar
#' to what is used in simple linear regression, to calculate the slope coefficients for subsequences
#' (windows) of a time series. The DLTAM then uses windows (of same or different size) of the MAT
#' values for a pair of time series to calculate the Local Trend Association Measure (LTAM), which
#' is simply a cosine similarity of the slope values. As such, this gives a representation of
#' the local strength of co-movement and the direction of movement for time series pairs.
#'
#' @param .data A data frame or a data frame extension (e.g. a tibble).
#' @param x,y Names of the columns containing the time series data, as symbols.
#' @param timestamp An optional parameter specifying the name of the column, as a symbol, containing
#' timestamps corresponding to `x` and `y`.
#' @param window_size The size of the window to use when calculating the Moving Approximation
#' Transform slope values from the time series values.
#' @param mat_seq_size The size of the window to use when calculating Local Trend Association
#' Measure values from the Moving Approximation Transform slope values.
#' @return A [tibble][tibble::tibble-package] with columns `timestamp` (if supplied) and `score`.
#' @references García-López F. J., Batyrshin, I., Gelbukh, A. (2018) *Dynamic Local Trend
#' Associations in Analysis of Comovements of Financial Time Series*. In: Fuzzy Logic in Intelligent
#' System Design. NAFIPS 2017. Advances in Intelligent Systems and Computing, vol 648. Springer.
#' [doi:10.1007/978-3-319-67137-6_20](https://doi.org/10.1007/978-3-319-67137-6_20).
#' @export
dltam <- function(
  .data,
  x,
  y,
  timestamp = NULL,
  window_size,
  mat_seq_size
) {
  check_data_frame(.data)
  initial_length <- nrow(.data)

  check_column_exists(.data, {{ x }})
  check_column_exists(.data, {{ y }})
  check_column_exists(.data, {{ timestamp }}, allow_null=TRUE)

  check_number_whole(window_size, min=1, max=as.double(initial_length))
  check_number_whole(mat_seq_size, min=1, max=initial_length - window_size + 1)

  mat_x <- dplyr::pull(.data, {{ x }})
  mat_y <- dplyr::pull(.data, {{ y }})

  check_complete(mat_x)
  check_complete(mat_y)

  mat_x <- mat(mat_x, window_size)
  mat_y <- mat(mat_y, window_size)

  mat_x_seq <- forward_window(mat_x, mat_seq_size)
  mat_y_seq <- forward_window(mat_y, mat_seq_size)

  score <- purrr::map2_dbl(mat_x_seq, mat_y_seq, ltam)

  if (rlang::quo_is_null(rlang::enquo(timestamp))) {
    return(tibble::as_tibble_col(score, "score"))
  }

  timestamp <- dplyr::pull(.data, {{ timestamp }})
  timestamp <- timestamp[1:(initial_length - window_size + 1 - mat_seq_size + 1)]

  tibble::tibble(timestamp, score)
}

#' Calculate Moving Approximation Transform (MAT) slope values over windows
#' @param x A vector of values.
#' @noRd
mat <- function(x, window_size) {
  x_windowed <- forward_window(x, window_size)
  purrr::map_dbl(x_windowed, ~ get_windowed_slope(.x, window_size))
}

#' Obtain the forward-looking window given a vector the window size
#' @param size The window size.
#' @noRd
forward_window <- function(x, size) {
  slider::hop(
    x,
    .starts = seq.int(
      from = 1,
      to = length(x) - size + 1,
      by = 1
    ),
    .stops = seq.int(
      from = size,
      to = length(x),
      by = 1
    ),
    identity
  )
}

#' Calculate the Moving Approximation Transform slope value for a window
#' @param k The window size.
#' @noRd
get_windowed_slope <- function(x, k) {
  weights <- (2 * ((1:k) - 1)) - k + 1

  (6 / (k * (k^2 - 1))) * sum(weights * x)
}

#' Calculate the Local Trend Association Measure (LTAM) for two sequences of slopes
#' @param mat_x,mat_y The sequences of slopes for two vectors obtained using the Moving
#' Approximation Transform method.
#' @noRd
ltam <- function(mat_x, mat_y) {
  # This is just the usual cosine similarity
  drop(crossprod(mat_x, mat_y)) / sqrt(drop(crossprod(mat_x)) * drop(crossprod(mat_y)))
}
