#' get_awuds_data
#'
#' Get data from local excel export or dump file.
#' 
#' @param awuds.data.path character, path to files to try to load.
#' @param awuds.data.files character, a vector of files to try to load.
#' @return \code{data.frame} containing AWUDS data elements
#' 
#' @export
#' 
#' @examples 
#' awuds.data.path <- system.file("extdata/dump", package="wateRuse")
#' awuds.data <- get_awuds_data(awuds.data.path)
#' 
#' awuds.data.path <- system.file("extdata/excel", package="wateRuse")
#' awuds.data <- get_awuds_data(awuds.data.path)
#' 
#' fileList <- c(system.file("extdata/excel/Export_2005_County.xlsx", package="wateRuse"),
#' system.file("extdata/excel/Export_2010_County.xlsx", package="wateRuse"),
#' system.file("extdata/excel/Export_2015_County.xlsx", package="wateRuse"))
#' awuds.data <- get_awuds_data(awuds.data.files=fileList)
#' 
#' file <- c(system.file("extdata/dump/exampleAWUDSdump.txt", package="wateRuse"))
#' awuds.data <- get_awuds_data(awuds.data.files=file)
#' 
get_awuds_data <- function(awuds.data.path = NA, awuds.data.files = NA) {
  if ( !is.na(awuds.data.path) ) {
    files_to_scan <- list.files(path=awuds.data.path,full.names = TRUE)
  } else if ( is.vector(awuds.data.files) ) {
    if ( !file.exists(awuds.data.files[1]) || !is.vector(awuds.data.files) ) stop('Did not get a valid file.')
    files_to_scan <- awuds.data.files
  } else {
    stop('Must provide the folder where AWUDS Excel export files or dump file(s) are stored.')
  }
  for ( check_file in files_to_scan ) {
    if ( grepl('Export.*[1,2][0,9][0-9][0-5].*.xlsx', check_file) ) {
      if ( !exists('files_to_open')) files_to_open <- c()
      files_to_open <- c(files_to_open, file.path(check_file))
    } else if ( grepl('.*dump.txt',check_file) ) {
      if ( exists('dump_file_to_open') ) {
        stop('Found more than one dump file at the path given, only one is supported.')
      }
      dump_file_to_open<-check_file
    }
  }
  if( !exists('dump_file_to_open') && !exists('files_to_open') ) {
    stop('No excel or dump files found.')
  }
  if ( exists('files_to_open') ) {
    for ( file_open in files_to_open ) {
      new_awuds_data <- parseExport(file_open, citations = TRUE)
      year<-regmatches(file_open,regexpr('[1,2][0,9][0-9][0-5]',file_open))
      if ( !exists('awuds_data') ) {
        awuds_data<-normalize_awuds_excel( new_awuds_data )
        awuds_data['Year'] <- rep(x = year, times = nrow(awuds_data))
      } else {
        next_awuds_data<-normalize_awuds_excel( new_awuds_data )
        next_awuds_data['Year']<-rep(x = year, times = nrow(next_awuds_data))
        awuds_data<-merge(awuds_data,next_awuds_data, all.y=TRUE)
      }
    }
  } else {
    awuds_data<-read.delim(dump_file_to_open, na.strings="--", colClasses="character")
    awuds_data <- as.data.frame(lapply(awuds_data, function(x) {gsub("na", "NaN", x)}), stringsAsFactors=FALSE)
    for ( dataCol in names(awuds_data)[9:length(names(awuds_data))]) { # Convert all data elements to numeric
      awuds_data[[dataCol]]<-as.numeric(awuds_data[[dataCol]])
    }
  }
  # Still need to reorder the collumns to be in canonical order.
  # col_year <- grep("Year", names(awuds_data))
  # awuds_data <- awuds_data[, c(col_idx, (1:ncol(df))[-col_idx])]
  # names(awuds_data)
  return(awuds_data)
}

normalize_awuds_excel<-function(parseExport_out) {
  for ( awuds_category in names(parseExport_out) ) {
    if ( !exists('normalized_awuds') ) {
      normalized_awuds <- parseExport_out[[awuds_category]]
    } else {
      normalized_awuds <- merge(normalized_awuds, parseExport_out[[awuds_category]],by='Area')
      # This works, but requires Area to be in the right order.
      # normalized_awuds <- cbind(normalized_awuds, parseExport_out[[awuds_category]][-1])
    }
  }
  names(normalized_awuds) <- make.names(names(normalized_awuds))
  return(normalized_awuds)
}