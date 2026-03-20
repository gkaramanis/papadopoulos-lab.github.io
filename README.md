# Uppsala Transgender Health Research Group — website

Quarto website for the [Uppsala Transgender Health Research Group](https://papadopoulos-lab.github.io).

## Publications pipeline

New publications are fetched monthly from ORCID and opened as GitHub issues labelled `publication: pending`. Team members review and relabel issues as `publication: approved` or `publication: rejected`. Approved issues are resolved via CrossRef and written to `publications.bib`, which the site renders from.

- **Fetch:** `Rscript R/fetch_publications.R` (or trigger the GitHub Actions workflow manually)
- **Build:** `Rscript R/build_bib.R` (runs automatically when a publication issue is labelled)
- **Members:** edit `members.csv` to add/update ORCID IDs and join dates

## TODO

- [ ] Move GitHub Pages to serve from a dedicated `gh-pages` branch instead of `docs/` — avoids hashed filename conflicts in `docs/` when multiple people render locally and push
