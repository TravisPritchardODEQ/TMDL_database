#' Characteristics table column names.
#'
#' Returns a vector of column names used in the characteristics table in a wqdb.

#' @keywords characteristics
#' @export
#' @return Vector of column names
#'

char_cols <- function() {

  char.cols <- c('chr_uid',
                 'Char_Name',
                 'CASNumber')
  return(char.cols)

}
