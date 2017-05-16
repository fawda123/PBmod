#' Setup SALT.INP
#'
#' @param dxdyin chr string for input dxdy grid file
#' @param sig numeric for number of sigma layers
#' @param sal numeric for starting salinity value, PPT
#' @param outfl chr string for name of output file to save
#' 
#' @import dplyr 
#' 
#' @return Nothing
getsalt <- function(dxdyin = 'EFDC/dxdy.inp', sig = 5,  sal = 23, outfl = 'EFDC/SALT.INP'){
  
  # import dxdy file
  dxdy <- readLines(dxdyin)
  
  # get i, j
  dxdy <- dxdy[-c(1:4)] %>% 
    strsplit(., '\\s+') %>% 
    do.call('rbind', .) %>% 
    data.frame(stringsAsFactors = F) %>% 
    rename(
      I = X2, 
      J = X3
    ) %>% 
    select(I, J)
  
  # salt matrix
  salt <- matrix(nrow = nrow(dxdy), ncol = sig, sal)
  
  # headers
  hds <- c(
    'C       SALT.inp      PENSACOLA BAY      PPT',
    'C',
    'C              I       J       Lay 1   Lay 2   Lay 3   Lay 4   Lay 5   Lay 6   Lay 7   Lay 8   Lay 9   Lay 10',
    'C'
  )
  
  # combine
  out <- cbind(dxdy, salt) %>% 
    rbind(rep('', 2 + sig), .) %>% 
    rownames_to_column(.) %>% 
    apply(., 1, paste, collapse = '\t') %>% 
    unlist %>% 
    c(hds, .)
  
  # save
  writeLines(out, outfl)
  
}