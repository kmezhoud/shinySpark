#' Display dataframe in table using DT package
#'
#' @usage displayTable(df)
#' @param df a dataframe
#'
#' @return A table
#'
#' @examples
#' session <- NULL
#' cgds <- CGDS("http://www.cbioportal.org/public-portal/")
#' Studies<- getCancerStudies(cgds)
#' \dontrun{
#' displayTable(Studies)
#' }
#'@export
displayTable <- function(df){
  # action = DT::dataTableAjax(session, dat, rownames = FALSE, toJSONfun = my_dataTablesJSON)
  action = DT::dataTableAjax(session, df, rownames = FALSE)
  
  #DT::datatable(dat, filter = "top", rownames =FALSE, server = TRUE,
  table <- DT::datatable(df, filter = list(position = "top", clear = FALSE, plain = TRUE),
                         rownames = FALSE, style = "bootstrap", escape = FALSE,
                         # class = "compact",
                         options = list(
                           ajax = list(url = action),
                           search = list(search = "",regex = TRUE),
                           columnDefs = list(list(className = 'dt-center', targets = "_all")),
                           autoWidth = FALSE,
                           processing = FALSE,
                           pageLength = 5,
                           lengthMenu = list(c(5,10, 25, 50, -1), c('5','10','25','50','All'))
                         )
  )
  return(table)
}


## define a helper function
empty_as_na <- function(x){
  if("factor" %in% class(x)) x <- as.character(x) ## since ifelse wont work with factors
  ifelse(as.character(x)!="", x, NA)
}

empty_as_na_sdf <- function(x) {
  if (is.factor(x)) {
    gsub(pattern = "", replacement = NA, x = as.character(x), fixed = T)
  } else { x }
}
