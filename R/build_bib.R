# build_bib.R
#
# Reads all GitHub issues labelled "publication: approved", resolves their
# DOIs via CrossRef, and writes publications.bib. Run this after approving
# issues in GitHub, then re-render the site locally.
#
# Run: Rscript R/build_bib.R
# Requires: GITHUB_TOKEN in environment

library(RefManageR)
library(gh)
library(glue)

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !is.na(a[1])) a else b

# ── Config ────────────────────────────────────────────────────────────────────

OWNER  <- "gkaramanis"
REPO   <- "papadopoulos-lab.github.io"
LABEL  <- "publication: approved"
OUTFILE <- "publications.bib"

# ── Read approved issues ──────────────────────────────────────────────────────

message("Reading approved issues from GitHub...")
issues <- tryCatch(
  gh::gh(
    "GET /repos/{owner}/{repo}/issues",
    owner    = OWNER,
    repo     = REPO,
    labels   = LABEL,
    state    = "all",
    per_page = 100,
    .limit   = Inf
  ),
  error = function(e) stop(glue("Could not read issues: {e$message}"))
)
message(glue("Found {length(issues)} approved issues."))

# ── Extract DOIs ──────────────────────────────────────────────────────────────

dois <- vapply(issues, function(i) {
  body <- i$body %||% ""
  m <- regmatches(body, regexpr("(?<=<!-- doi: )[^\\s]+(?= -->)", body, perl = TRUE))
  if (length(m) == 0) NA_character_ else m
}, character(1))

dois <- unique(dois[!is.na(dois)])

if (length(dois) == 0) {
  message("No approved issues found — publications.bib not updated.")
  quit(status = 0)
}

message(glue("Resolving {length(dois)} unique DOIs via CrossRef..."))

# ── Resolve DOIs ──────────────────────────────────────────────────────────────

entries <- list()
failed  <- character(0)

for (doi in dois) {
  bib <- tryCatch({
    message(glue("  {doi}"))
    RefManageR::GetBibEntryWithDOI(doi)
  }, error = function(e) {
    message(glue("  ✗ Could not resolve: {e$message}"))
    NULL
  })

  if (!is.null(bib) && length(bib) > 0) {
    # Append the BibEntry itself. Using c(entries, bib) would strip its class
    # and splice its fields into the list, which then breaks WriteBib.
    entries[[length(entries) + 1]] <- bib
  } else {
    failed <- c(failed, doi)
  }

  Sys.sleep(0.5)
}

# ── Report failures ───────────────────────────────────────────────────────────

if (length(failed) > 0) {
  message(glue("\n{length(failed)} DOI(s) could not be resolved:"))
  for (d in failed) message(glue("  - {d}"))
  message("Add these manually to publications.bib if needed.")
}

# ── Merge with existing publications.bib ─────────────────────────────────────

existing <- if (file.exists(OUTFILE)) {
  tryCatch(
    RefManageR::ReadBib(OUTFILE, check = FALSE),
    error = function(e) {
      message(glue("Could not read existing {OUTFILE}: {e$message}"))
      NULL
    }
  )
} else NULL

# ── Combine new entries into a BibEntry object ────────────────────────────────

if (length(entries) == 0) {
  message("No entries resolved — publications.bib not updated.")
  quit(status = 0)
}

new_bib <- do.call(c, entries)

if (!inherits(new_bib, "BibEntry")) {
  stop("Resolved entries did not combine into a BibEntry; got class ",
       paste(class(new_bib), collapse = "/"))
}

# ── Merge with existing publications.bib ─────────────────────────────────────

if (!is.null(existing) && length(existing) > 0) {
  message(glue("Merging with {length(existing)} existing entries in {OUTFILE}."))
  # Existing entries first, so hand-curated ones (local PDF links, corrected
  # metadata) win over a freshly resolved copy of the same paper.
  all_bib <- c(existing, new_bib)
} else {
  all_bib <- new_bib
}

# ── Deduplicate by DOI ────────────────────────────────────────────────────────

extract_doi_from_entry <- function(e) {
  doi <- tryCatch(as.character(e$doi), error = function(x) NA_character_)
  if (is.null(doi) || length(doi) == 0) return(NA_character_)
  tolower(sub("^https?://doi\\.org/", "", trimws(doi)))
}

# Some hand-added entries carry no DOI field, so fall back to the title.
# Without this they reappear as duplicates every time the pipeline runs.
extract_title_from_entry <- function(e) {
  ti <- tryCatch(as.character(e$title), error = function(x) NA_character_)
  if (is.null(ti) || length(ti) == 0) return(NA_character_)
  ti <- tolower(trimws(ti))
  gsub("[^a-z0-9]+", " ", ti)
}

# An entry is a duplicate if either its DOI or its title has been seen. Both
# checks are needed: hand-added entries may lack a DOI, so a resolved copy of
# the same paper would otherwise slip through as a separate entry.
entry_dois   <- vapply(seq_along(all_bib), function(i) extract_doi_from_entry(all_bib[i]), character(1))
entry_titles <- vapply(seq_along(all_bib), function(i) extract_title_from_entry(all_bib[i]), character(1))

seen_doi   <- character(0)
seen_title <- character(0)
keep       <- integer(0)

for (i in seq_along(all_bib)) {
  d <- entry_dois[i]
  t <- entry_titles[i]
  has_d <- !is.na(d) && nzchar(d)
  has_t <- !is.na(t) && nzchar(t)

  if ((has_d && d %in% seen_doi) || (has_t && t %in% seen_title)) next

  keep <- c(keep, i)
  if (has_d) seen_doi   <- c(seen_doi, d)
  if (has_t) seen_title <- c(seen_title, t)
}

all_bib <- all_bib[keep]

message(glue("{length(all_bib)} total entries after deduplication."))

# ── Write bib ─────────────────────────────────────────────────────────────────

if (!inherits(all_bib, "BibEntry")) {
  stop("Refusing to write: all_bib is ", paste(class(all_bib), collapse = "/"),
       ", not a BibEntry")
}

RefManageR::WriteBib(all_bib, file = OUTFILE, verbose = FALSE)
message(glue("\nWritten {length(all_bib)} entries to {OUTFILE}."))
message("Re-render the site locally to publish the updated list.")
