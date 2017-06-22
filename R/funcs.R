library(tidyverse)
library(raster)
library(rgdal)

#' Get I, J (column, row) values from dxdy file
#'
#' @param dxdyin chr string for input dxdy grid file
#'
#' @return Two column data.frame of I, J values
#'
getij <- function(dxdyin){
  
  # import dxdy file
  dxdy <- readLines(dxdyin)
  
  # get i, j
  ij <- dxdy[-c(1:4)] %>% 
    strsplit(., '\\s+') %>% 
    do.call('rbind', .) %>% 
    data.frame(stringsAsFactors = F) %>% 
    rename(
      I = X2, 
      J = X3
    ) %>% 
    dplyr::select(I, J)
  
  return(ij)
  
}

#' Generic function to setup TEMP.INP, SALT.INP, DYE.INP
#'
#' @param dxdyin chr string for input dxdy grid file
#' @param sig numeric for number of sigma layers
#' @param val numeric for starting value, as temp c, sal ppt, or dye
#' @param outfl chr string for name of output file to save, \code{NULL} returns to console
#' @param frstrow chr string of text to put on first row, describes file name, location, value
#' 
#' @import dplyr 
#' 
#' @return Saves file as \code{outfl} unless \code{outfl = NULL}
#' 
getinp <- function(dxdyin = 'EFDC/dxdy.inp', sig = 5,  val, outfl, frstrow){
  
  # get ij values
  ij <- getij(dxdyin)
  
  # temp matrix
  mat <- matrix(nrow = nrow(ij), ncol = sig, val)
  
  # headers
  hds <- c(
    frstrow,
    'C',
    'C              I       J       Lay 1   Lay 2   Lay 3   Lay 4   Lay 5   Lay 6   Lay 7   Lay 8   Lay 9   Lay 10',
    'C'
  )
  
  # combine
  out <- cbind(ij, mat) %>% 
    rbind(rep('', 2 + sig), .) %>% 
    rownames_to_column(.) %>% 
    apply(., 1, paste, collapse = '\t') %>% 
    unlist %>% 
    c(hds, .)
  
  # to console if null
  if(is.null(outfl)) return(out)
  
  writeLines(out, outfl)
  
}

#' Get card info
#' 
#' Get card information from EDFC.inp
#' 
#' @param path chr string of card path
#' @param crd chr string of card number, e.g., 'C7'
#' @param txts logical indicating if all text is returned, otherwise just a header and values
#' 
getcrd <- function(path, crd = 'C7', txts = FALSE){
  
  # read input
  inps <- readLines(paste0(path, '/EFDC.inp')) 
  
  # next card
  crdnxt <- gsub('C', '', crd) %>% 
    as.numeric %>% 
    `+`(1) %>% 
    paste0('C', ., '\\s')
  
  # ending line from next card
  endln <- grep(crdnxt, inps)[1] - 2
  
  # potential start lines
  strlns <- paste0(crd, '\\s') %>% 
    grep(., inps)
  
  # return all
  if(txts){
    out <- inps[strlns[1]:endln]
  } else {
    out <- inps[strlns[2]:endln] %>% 
      gsub('%.*$|\\|', '', .) %>% 
      gsub(crd, '', .) %>% 
      gsub('^\\s+|\\s+$', '', .) %>% 
      strsplit('\\s+') %>% 
      do.call('rbind', .)
  }
  
  return(out)
  
}