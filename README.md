# Uppsala Transgender Health Research Group

Quarto website for the Uppsala Transgender Health Research Group.

**Guides for team members:** [Publishing a blog post](../../wiki/Publishing-a-blog-post) · [Updating publications](../../wiki/Updating-publications) · [all wiki pages](../../wiki)

Neither guide needs any coding. Everything below the line is for whoever maintains the site itself.

---

This repository publishes to https://gkaramanis.github.io/papadopoulos-lab.github.io/ through GitHub Pages.

Pushing to `main` is all it takes. A GitHub Action renders the site and publishes it to the `gh-pages` branch, which is what Pages serves. Built output is no longer committed, so edit the source, push, and the site follows a few minutes later. Nothing in `gh-pages` should ever be edited by hand.

Render locally with `quarto preview` or `quarto render`, which write to `_site/`. That folder is ignored by git.

That URL is temporary. A custom domain, `uppsalatransresearch.se`, is registered and will serve the site once its DNS is configured.

## Publications pipeline

New publications are fetched monthly from ORCID and opened as GitHub issues labelled `publication: pending`. Team members review and relabel issues as `publication: approved` or `publication: rejected`. Approved issues are resolved via CrossRef and written to `publications.bib`, which the site renders from.

- **Fetch:** `Rscript R/fetch_publications.R` (or trigger the GitHub Actions workflow manually)
- **Build:** `Rscript R/build_bib.R` (runs automatically when a publication issue is labelled)
- **Members:** edit `members.csv` to add/update ORCID IDs and join dates

## Pages in progress

Three sections are still being written and are hidden from the site: Projects, For Participants and Funding. Each is hidden with `draft: true` in its front matter, which empties the page and drops it from the navbar, search and sitemap. Removing that line brings the page back.

To read a hidden page, run `quarto render --profile drafts`, which renders drafts in full into `_site/`. Normal builds and the live site are unaffected. `quarto preview` does not work for this, as it blanks drafts again on re-render.

The files carrying it are `projects.qmd` and the three pages in `projects/`, `public.qmd`, `funding.qmd`, and the two pages in `funding-items/`.

The live navbar is therefore People, Publications, Presentations and Blog.

The `render:` list in `_quarto.yml` is limited to `.qmd` files so that repository documentation is not published as site pages.

## Full-text PDFs

Put a paper's PDF in `articles/`, named `<year>-<first author surname>.pdf`, for example `2025-ozel.pdf`. The publications page finds it by year and surname and adds a PDF link to that entry. Nothing needs to be written into `publications.bib`, and the link is relative, so it survives a change of domain.

Three PDFs currently have no matching entry: `2021-makris.pdf`, `2022-bilal.pdf` and `2022-fransson.pdf`.

## Linking a paper to its blog post

A blog post can declare the paper it is about by putting its DOI in the front matter:

```yaml
doi: 10.1001/jamanetworkopen.2025.27780
```

The publications page then adds a "Plain-language summary" link to the matching entry. Matching is on DOI alone, so nothing else needs to be kept in step. Posts created from the dissemination issue form get this automatically from the form's DOI field.

## TODO

- [ ] Add funding as a tag/filter on the Projects page
- [ ] Add all relevant studies from all team members to the projects pages
- [ ] All team members to get ORCID IDs and import their full publication history
- [ ] Write the remaining page content and unhide the pages: Projects (Team and Key outputs sections), For Participants, Funding
- [ ] Set up the custom domain uppsalatransresearch.se — point its DNS at GitHub Pages, set the domain on this repository, commit a `CNAME` file and uncomment its line under `resources` in `_quarto.yml`, and change `site-url` from the temporary `gkaramanis.github.io` host to the domain
