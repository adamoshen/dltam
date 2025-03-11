#' Check that a column exists in a data frame
#' @param df A data frame or data frame extension (e.g. tibble).
#' @param x A column name.
#' @param allow_null For use when a column's existence is optional.
#' @noRd
check_column_exists <- function(
  df,
  x,
  allow_null = FALSE,
  arg_df = rlang::caller_arg(df),
  arg_x = rlang::caller_arg(x),
  call = rlang::caller_env()
) {
  x <- rlang::enquo(x)

  if (rlang::quo_is_null(x) & allow_null) {
    return(invisible(NULL))
  }
  if (rlang::as_name(x) %in% names(df)) {
    return(invisible(NULL))
  }

  cli::cli_abort(
    "{.arg {arg_x}} must be a column in {.arg {arg_df}}.",
    arg_df = arg_df,
    arg_x = arg_x,
    call = call
  )
}

#' Check that a vector does not contain any missing values
#' @param x A vector of values.
#' @noRd
check_complete <- function(x, arg=rlang::caller_arg(x), call=rlang::caller_env()) {
  if (all(!is.na(x))) {
    return(invisible(NULL))
  }

  cli::cli_abort(
    "{.arg {arg}} cannot contain missing values.",
    arg = arg,
    call = call
  )
}
