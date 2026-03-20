# Uppsala Transgender Health Research Group — website

Quarto website for the [Uppsala Transgender Health Research Group](https://papadopoulos-lab.github.io).

## Publications pipeline

New publications are fetched monthly from ORCID and opened as GitHub issues labelled `publication: pending`. Team members review and relabel issues as `publication: approved` or `publication: rejected`. Approved issues are resolved via CrossRef and written to `publications.bib`, which the site renders from.

- **Fetch:** `Rscript R/fetch_publications.R` (or trigger the GitHub Actions workflow manually)
- **Build:** `Rscript R/build_bib.R` (runs automatically when a publication issue is labelled)
- **Members:** edit `members.csv` to add/update ORCID IDs and join dates

## TODO

- [ ] Move GitHub Pages to serve from a dedicated `gh-pages` branch instead of `docs/` — avoids hashed filename conflicts when multiple people render locally and push; prerequisite for render-on-push
- [ ] Add render-on-push GitHub Action (do this after moving to `gh-pages` branch, otherwise local and CI renders will conflict)
- [ ] Fix PDF links
- [ ] Add funding as a tag/filter on the Projects page
- [ ] Add all relevant studies from all team members to the projects pages
- [ ] All team members to get ORCID IDs and import their full publication history
- [ ] Delete or replace `update_bib.R` (superseded by `R/fetch_publications.R` and `R/build_bib.R`)
- [ ] Set up custom domain uppsalatransresearch.se
