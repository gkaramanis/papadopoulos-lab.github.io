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
    entries <- c(entries, bib)
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

if (!is.null(existing) && length(existing) > 0) {
  message(glue("Merging with {length(existing)} existing entries in {OUTFILE}."))
  entries <- c(entries, as.list(existing))
}

# ── Deduplicate by DOI ────────────────────────────────────────────────────────

if (length(entries) == 0) {
  message("No entries — publications.bib not updated.")
  quit(status = 0)
}

extract_doi_from_entry <- function(e) {
  doi <- tryCatch(as.character(e$doi), error = function(x) NA_character_)
  if (is.null(doi) || length(doi) == 0) return(NA_character_)
  tolower(sub("^https?://doi\\.org/", "", trimws(doi)))
}

entry_dois <- vapply(entries, extract_doi_from_entry, character(1))
entries    <- entries[!duplicated(entry_dois) | is.na(entry_dois)]
message(glue("{length(entries)} total entries after deduplication."))

# ── Write bib ─────────────────────────────────────────────────────────────────

all_bib <- do.call(c, entries)
RefManageR::WriteBib(all_bib, file = OUTFILE, verbose = FALSE)
message(glue("\nWritten {length(all_bib)} entries to {OUTFILE}."))
message("Re-render the site locally to publish the updated list.")
