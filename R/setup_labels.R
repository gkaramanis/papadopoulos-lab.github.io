# setup_labels.R
#
# One-time script: creates the three GitHub labels used by the
# publications pipeline. Run once before the first fetch.
#
# Run: Rscript R/setup_labels.R
# Requires: GITHUB_TOKEN with repo write access

library(gh)

OWNER <- "gkaramanis"
REPO  <- "papadopoulos-lab.github.io"

labels <- list(
  list(
    name        = "publication: pending",
    color       = "e4e669",
    description = "New publication awaiting review"
  ),
  list(
    name        = "publication: approved",
    color       = "0e8a16",
    description = "Approved — will be included in publications.bib"
  ),
  list(
    name        = "publication: rejected",
    color       = "d93f0b",
    description = "Excluded from publications.bib"
  )
)

for (l in labels) {
  tryCatch({
    gh::gh(
      "POST /repos/{owner}/{repo}/labels",
      owner       = OWNER,
      repo        = REPO,
      name        = l$name,
      color       = l$color,
      description = l$description
    )
    cat("Created:", l$name, "\n")
  }, error = function(e) {
    cat("Already exists (or error):", l$name, "\n")
  })
}
