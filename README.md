# Uppsala Transgender Health Research Group

Quarto website for the Uppsala Transgender Health Research Group.

**Guides for team members:** [Publishing a blog post](../../wiki/Publishing-a-blog-post) · [Updating publications](../../wiki/Updating-publications) · [all wiki pages](../../wiki)

Neither guide needs any coding. Everything below the line is for whoever maintains the site itself.

---

This repository publishes to https://gkaramanis.github.io/papadopoulos-lab.github.io/ through GitHub Pages, from `main` at `/docs`. Rendered output is committed, so a content change means running `quarto render` and committing both the source and `docs/`.

That URL is temporary. A custom domain, `uppsalatransresearch.se`, is registered and will serve the site once its DNS is configured.

## Publications pipeline

New publications are fetched monthly from ORCID and opened as GitHub issues labelled `publication: pending`. Team members review and relabel issues as `publication: approved` or `publication: rejected`. Approved issues are resolved via CrossRef and written to `publications.bib`, which the site renders from.

- **Fetch:** `Rscript R/fetch_publications.R` (or trigger the GitHub Actions workflow manually)
- **Build:** `Rscript R/build_bib.R` (runs automatically when a publication issue is labelled)
- **Members:** edit `members.csv` to add/update ORCID IDs and join dates

## Pages in progress

Three sections are still being written and are hidden from the site: Projects, For Participants and Funding. Each is hidden with `draft: true` in its front matter, which empties the page and drops it from the navbar, search and sitemap. Removing that line brings the page back.

The files carrying it are `projects.qmd` and the three pages in `projects/`, `public.qmd`, `funding.qmd`, and the two pages in `funding-items/`.

The live navbar is therefore People, Publications, Presentations and Blog.

The `render:` list in `_quarto.yml` is limited to `.qmd` files so that repository documentation is not published as site pages.

## TODO

- [ ] Move GitHub Pages to serve from a dedicated `gh-pages` branch instead of `docs/` — avoids hashed filename conflicts when multiple people render locally and push; prerequisite for render-on-push
- [ ] Add render-on-push GitHub Action (do this after moving to `gh-pages` branch, otherwise local and CI renders will conflict)
- [ ] Fix PDF links
- [ ] Add funding as a tag/filter on the Projects page
- [ ] Add all relevant studies from all team members to the projects pages
- [ ] All team members to get ORCID IDs and import their full publication history
- [ ] Delete or replace `update_bib.R` (superseded by `R/fetch_publications.R` and `R/build_bib.R`)
- [ ] Write the remaining page content and unhide the pages: Projects (Team and Key outputs sections), For Participants, Funding
- [ ] Set up the custom domain uppsalatransresearch.se — point its DNS at GitHub Pages, set the domain on this repository, commit a `CNAME` file and uncomment its line under `resources` in `_quarto.yml`, and change `site-url` from the temporary `gkaramanis.github.io` host to the domain
