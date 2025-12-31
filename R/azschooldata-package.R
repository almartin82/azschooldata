#' azschooldata: Fetch and Process Arizona School Data
#'
#' Downloads and processes school enrollment data from the Arizona Department
#' of Education (ADE). Provides functions for fetching October 1 enrollment data
#' from the Accountability & Research division and transforming it into tidy
#' format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Arizona uses the following ID system:
#' \itemize{
#'   \item Entity IDs (CTDSNumber): Variable length numeric IDs for LEAs and schools
#'   \item Entity names identify whether it's a district, charter, or school
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Arizona Department of Education:
#' \itemize{
#'   \item Accountability & Research: \url{https://www.azed.gov/accountability-research/data}
#'   \item October 1 Enrollment Reports published annually
#' }
#'
#' @section Available Years:
#' \itemize{
#'   \item Era 1 (2011-2017): Original Excel format with multiple tabs
#'   \item Era 2 (2018-present): Updated format with demographic breakdowns
#' }
#'
#' @docType package
#' @name azschooldata-package
#' @aliases azschooldata
#' @keywords internal
"_PACKAGE"

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL
