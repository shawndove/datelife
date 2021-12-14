#' Generate one or multiple chronograms for a set of given taxon names
#'
#' @description \code{datelife_use} gets secondary calibrations available for any
#' pair of \code{input} taxon names, mined from code{\link[=opentree_chronograms]{opentree_chronograms}}
#' local DateLife database, and uses them to date a given tree topology with BLADJ
#' or PATHd8. If no tree topology is provided, it will attempt to generate one with
#' BOLD-OpenTree through [make_bold_otol_tree()].
#'
#' @inheritParams datelife_search
#' @inheritParams use_all_calibrations
#' @inheritDotParams make_datelife_query
#' @return A \code{datelife} object, which is a \code{phylo} or \code{multiPhylo}
#' object with secondary calibrations used for dating stored in attributes.
#' @export
#' @details
#' If input is a tree, it will use secondary calibrations to (1) date the tree with bladj
#' if it has no branch lengths, or (2) date the tree with PATHd8 if it has branch lengths.
#' If input is a vector of taxon names, it will attempt to reconstruct a BOLD tree first
#' to get a topology with branch lengths. If it can't, it will get an Open Tree
#' of Life synthetic tree topology and will date it with bladj.
datelife_use <- function(input = NULL,
                         each = FALSE,
                         dating_method = "bladj",
                         ...) {
  # use congruification to expand calibrations: already implemented in match_all_calibrations
  # and pathd8 still does not work sometimes
  # calibrations.df <- eachcal[[2]]
  # calibrations.df <- calibs$calibration
  # phy <- tax_phyloallall[[2]][[3]]


  datelife_query <- input
  if (suppressMessages(!is_datelife_query(input))) {
    # make_datelife_query also removes singleton nodes in phy
    # should we add extra arguments for make_datelife_query function
    # with hasArg (phytools method)???
    datelife_query <- make_datelife_query(input = input, ...)
  }
  phy <- datelife_query$phy
  # if datelife_query$phy is not a tree, get one with bold or otol:
  if (!inherits(datelife_query$phy, "phylo")) {
    # make_bold_otol_tree can take a datelifeQuery object, otherwise, it will make one again!
    phy <- make_bold_otol_tree(datelife_query,
                               chronogram = FALSE
    )
  }
  # if(!inherits(phy, "phylo")){
  #   message("BOLD tree reconstruction failed for the given set of taxon names.")
  #   phy <- get_dated_otol_induced_subtree(ott_ids = datelife_query$ott_ids)
  #   if (!inherits(phy, "phylo")) {
  #     message("Getting a dated subtree failed for the given set of taxon names.")}
  # } # unnecessary bc get_dated_otol_induced_subtree does not work
  # also, make_bold_otol_tree will at least return the OpenTree synthetic tree with no bl
  if (!inherits(phy, "phylo")) {
    warning("We could not retrieve a tree topology for the given set of taxon names. \
              Please provide a tree topology as 'input'.")
    return(NA)
  }
  datelife_query$phy <- phy
  # Finally, call datelife_search, get_all_calibrations and use_all_calibrations:
  res <- datelife_use_datelifequery(
    datelife_query = datelife_query,
    each = each,
    dating_method = dating_method
  )

  return(res)
}

#' Generate one or multiple chronograms from a `datelifeQuery` object.
#'
#' @description `datelife_use_datelifequery` generates one or multiple chronograms (i.e., phylogenetic
#' trees with branch lengths proportional to time) for a set of \code{input} taxa,
#' dated with bladj or PATHd8, using secondary calibrations available for any pair
#' of \code{input} taxa, mined from the code{\link[=opentree_chronograms]{opentree_chronograms}}
#' local DateLife database.
#'
#' @inheritParams get_taxon_summary
#' @inheritParams use_all_calibrations
#' @inheritParams get_all_calibrations
#' @return A list with a chronogram and secondary calibrations used.
#' @export
datelife_use_datelifequery <- function(datelife_query = NULL,
                                       dating_method = "bladj",
                                       each = FALSE) {
  #
  if (suppressMessages(!is_datelife_query(datelife_query))) {
    stop("'datelife_query' is not a 'datelifeQuery' object.")
  }
  if (!inherits(datelife_query$phy, "phylo")) {
    message("A tree topology is needed for a dating analysis.")
    warning("'datelife_query$phy' is not a 'phylo' object.")
    return(NA)
  }
  # get calibrations by performing a datelife_search with get_all_calibrations:
  calibrations <- get_calibrations_datelifequery(
    datelife_query = datelife_query,
    each = each
  )

  # date the topology with obtained calibrations
  res <- use_all_calibrations(
    phy = datelife_query$phy,
    calibrations = calibrations,
    dating_method = dating_method
  )
  # attributes(calibrations)
  attr(res, "datelife_query") <- datelife_query
  return(res)
}