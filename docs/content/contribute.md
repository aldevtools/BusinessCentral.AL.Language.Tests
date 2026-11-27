---
title: Contribute or report a change
weight: 3
---

## Report a change

If you see Business Central give a different result on two versions, open an issue in
[BusinessCentral.AL.Language.Tests](https://github.com/aldevtools/BusinessCentral.AL.Language.Tests/issues). Include:

1. The two versions and builds (for example 29.0.54011.55816 and 29.1.57326.58076).
2. A small piece of AL code that shows the difference.
3. The result on each version.
4. A link to Microsoft's documentation if you found one.

We then write a probe test for it. An entry on this site needs a probe that measures the change on real service
tiers; a report alone is not enough.

## Add or change an entry

Each change is one Markdown file: `docs/content/changes/<id>.md`. The site is built with
[Hugo](https://gohugo.io/) and the [Hextra](https://github.com/imfing/hextra) theme. No Node.js is needed.

1. Add the version guard and the comment `// version change: <id>` in the probe, next to the guard.
2. Copy an existing file in `docs/content/changes/`, rename it to `<id>.md` and fill in the fields.
3. Build the site locally: `cd docs && hugo server`. Hugo downloads the theme on the first run (it needs Go).
4. Open a pull request. CI fails if a `// version change:` comment has no matching file.

The site is published to GitHub Pages when the pull request is merged into master.

## Fields

| Field | Meaning |
|---|---|
| `id` | `<version>-<slug>`, for example `29.1-page-part-refresh`. The version is the minor where the change was first seen. The id is also the file name and the text of the `// version change:` comment. |
| `title` | One line that says what changed. |
| `area` | One of: pages, reports, data, web services, platform libraries, test runner. |
| `class` | `behavior change` (the same AL code gives a different result) or `version data` (the data a version ships with is different). |
| `first_seen` | The first version and build where the new result was measured. |
| `last_seen_before` | The last version and build before that where the old result was measured. |
| `only_in` | Optional. Set it when the old result existed in one minor only and the new result is the same as in the versions before it. For example `29.0`: 27 and 28 gave one result, 29.0 another, 29.1 went back to the 27/28 result. |
| `also_differs_from` | Other versions that give a different result than `first_seen`, besides `last_seen_before`. |
| `microsoft_documented` | `yes` if Microsoft's release notes, what's new page or update knowledge base article mention the change, else `no`. |
| `microsoft_link` | The link to that documentation. Empty when `microsoft_documented` is `no`. |
| `probes` | The probe files that measure the change, as `path:line` from the repository root. |
| `summary` | Two sentences at most: what was different and what it is now. |

Below the front matter, describe the AL code, what changed, who is affected, and which Microsoft sources were
searched. Use short sentences. Say only what the probes measured.
