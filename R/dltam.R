dltam <- function(.data, x, y, timestamp=NULL, window_size, mat_seq_size) {
  initial_length <- nrow(.data)

  mat_x <- dplyr::pull(.data, {{ x }})
  mat_y <- dplyr::pull(.data, {{ y }})

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

mat <- function(x, window_size) {
  x_windowed <- forward_window(x, window_size)
  purrr::map_dbl(x_windowed, ~ get_windowed_slope(.x, window_size))
}

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

get_windowed_slope <- function(x, k) {
  weights <- (2 * ((1:k) - 1)) - k + 1

  (6 / (k * (k^2 - 1))) * sum(weights * x)
}

ltam <- function(mat_x, mat_y) {
  # This is just the usual cosine similarity
  drop(crossprod(x, y)) / sqrt(drop(crossprod(x^2)) * drop(crossprod(y^2)))
}
