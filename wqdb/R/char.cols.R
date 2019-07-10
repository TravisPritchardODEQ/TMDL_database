#' Characteristics table column names.
#'
#' Returns a vector of column names used in the characteristics table in a wqdb.

#' @keywords characteristics
#' @export
#' @return Vector of column names
#'

char.cols <- function() {

  char_cols <- c('chr_uid',
                 'Char_Name',
                 'CASNumber')
  return(char_cols)

}
