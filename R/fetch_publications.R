# fetch_publications.R
#
# Fetches works from ORCID for all lab members with an ORCID ID,
# filters by each member's join date, and opens a GitHub issue for
# every paper not yet tracked. Issues are labelled "publication: pending"
# for the team to review.
#
# Run: Rscript R/fetch_publications.R
# Requires: GITHUB_TOKEN in environment (set automatically in GitHub Actions)

library(orcidtr)
library(RefManageR)
library(gh)
library(glue)

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !is.na(a[1])) a else b

# ── Config ────────────────────────────────────────────────────────────────────

OWNER          <- "gkaramanis"
REPO           <- "papadopoulos-lab.github.io"
LABEL_PENDING  <- "publication: pending"
LABEL_APPROVED <- "publication: approved"
LABEL_REJECTED <- "publication: rejected"

# ── Load members ──────────────────────────────────────────────────────────────

members <- read.csv("members.csv", stringsAsFactors = FALSE)
members <- members[!is.na(members$orcid) & nchar(trimws(members$orcid)) > 0, ]

if (nrow(members) == 0) stop("No members with ORCID IDs found in members.csv")
message(glue("Processing {nrow(members)} members with ORCID IDs."))

# ── Fetch works per member ────────────────────────────────────────────────────

fetch_works <- function(name, orcid, joined) {
  message(glue("  Fetching works for {name} ({orcid})..."))
  works <- tryCatch(
    orcid_fetch_many(orcid, section = "works"),
    error = function(e) {
      message(glue("  ✗ Failed: {e$message}"))
      NULL
    }
  )
  if (is.null(works) || nrow(works) == 0) return(NULL)
  works$member_name  <- name
  works$member_orcid <- orcid
  works$joined_year  <- as.integer(format(as.Date(joined), "%Y"))
  works
}

all_works <- do.call(rbind, Filter(
  Negate(is.null),
  Map(fetch_works, members$name, members$orcid, members$joined)
))

if (is.null(all_works) || nrow(all_works) == 0) {
  message("No works returned from ORCID. Exiting.")
  quit(status = 0)
}

# ── Filter and clean ──────────────────────────────────────────────────────────

# Extract year from publication_date (format: "2023-07-01", "2023-04", or "2023")
all_works$pub_year <- as.integer(substr(all_works$publication_date, 1, 4))
all_works <- all_works[!is.na(all_works$pub_year) & all_works$pub_year >= all_works$joined_year, ]

# Normalise DOIs
all_works <- all_works[!is.na(all_works$doi) & nchar(trimws(all_works$doi)) > 0, ]
all_works$doi <- tolower(trimws(all_works$doi))
all_works$doi <- sub("^https?://doi\\.org/", "", all_works$doi)

# Deduplicate: a co-authored paper appears in multiple ORCID profiles
all_works <- all_works[!duplicated(all_works$doi), ]
message(glue("Found {nrow(all_works)} unique works after join-date filter."))

# ── Get DOIs already in publications.bib ─────────────────────────────────────

extract_dois_from_bib <- function(path) {
  if (!file.exists(path)) return(character(0))
  lines <- readLines(path, warn = FALSE)
  dois <- regmatches(lines, regexpr("(?<=doi\\s=\\s\\{)[^}]+", lines, perl = TRUE))
  dois <- tolower(trimws(dois))
  dois <- sub("^https?://doi\\.org/", "", dois)
  dois[nchar(dois) > 0]
}

bib_dois <- extract_dois_from_bib("publications.bib")
message(glue("{length(bib_dois)} DOIs already in publications.bib."))

# ── Get already-tracked DOIs from existing issues ─────────────────────────────

extract_doi <- function(body) {
  m <- regmatches(body, regexpr("(?<=<!-- doi: )[^\\s]+(?= -->)", body, perl = TRUE))
  if (length(m) == 0) NA_character_ else m
}

get_tracked_dois <- function(label) {
  issues <- tryCatch(
    gh::gh(
      "GET /repos/{owner}/{repo}/issues",
      owner = OWNER, repo = REPO,
      labels = label, state = "all",
      per_page = 100, .limit = Inf
    ),
    error = function(e) list()
  )
  dois <- vapply(issues, function(i) extract_doi(i$body %||% ""), character(1))
  dois[!is.na(dois)]
}

tracked_dois <- unique(c(
  bib_dois,
  get_tracked_dois(LABEL_PENDING),
  get_tracked_dois(LABEL_APPROVED),
  get_tracked_dois(LABEL_REJECTED)
))
message(glue("{length(tracked_dois)} DOIs already tracked as issues."))

new_works <- all_works[!all_works$doi %in% tracked_dois, ]
message(glue("{nrow(new_works)} new publications to create issues for."))

if (nrow(new_works) == 0) {
  message("Nothing new. Done.")
  quit(status = 0)
}

# ── Create GitHub issues ──────────────────────────────────────────────────────

for (i in seq_len(nrow(new_works))) {
  w <- new_works[i, ]

  bib <- tryCatch(
    RefManageR::GetBibEntryWithDOI(w$doi),
    error = function(e) NULL
  )

  if (!is.null(bib) && length(bib) > 0) {
    b       <- bib[[1]]
    authors <- paste(format(b$author), collapse = ", ")
    title   <- as.character(b$title)
    journal <- as.character(b$journal %||% b$booktitle %||% "—")
    year    <- as.character(b$year %||% w$pub_year)
  } else {
    authors <- w$member_name
    title   <- w$doi
    journal <- "—"
    year    <- as.character(w$pub_year)
  }

  body <- glue(
    "## Citation\n\n",
    "**Authors:** {authors}  \n",
    "**Title:** {title}  \n",
    "**Journal/source:** {journal}  \n",
    "**Year:** {year}  \n",
    "**DOI:** [{w$doi}](https://doi.org/{w$doi})\n\n",
    "---\n\n",
    "_Fetched from {w$member_name} ({w$member_orcid}) on {Sys.Date()}._\n\n",
    "<!-- doi: {w$doi} -->"
  )

  tryCatch({
    gh::gh(
      "POST /repos/{owner}/{repo}/issues",
      owner  = OWNER,
      repo   = REPO,
      title  = title,
      body   = body,
      labels = list(LABEL_PENDING)
    )
    message(glue("  ✓ {title}"))
  }, error = function(e) {
    message(glue("  ✗ Could not create issue for {w$doi}: {e$message}"))
  })

  Sys.sleep(1) # stay within GitHub rate limits
}

message("Done.")
