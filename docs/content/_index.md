---
title: Business Central version changes
toc: false
---

This site lists the cases where Business Central gives a different result on one version than on another. It covers
major versions and minor updates. For each case it says whether Microsoft documented the change.

The site is written for AL developers. Use it when a test or an extension behaves differently after an update, or
before you move to a new minor.

## What is listed

Each entry is one change that AL code can see. There are two classes:

- **Behavior change.** The platform or an app does something different for the same AL code. For example, a page
  part runs a trigger one time more, or an insert that worked before now raises an error.
- **Version data.** The behavior is the same, but the data a version ships with is different. For example, a new row
  in a system table, a new caption, or a new library version that is written into generated output.

Each entry has its own page with the versions, the probe tests that measure it, and a link to Microsoft's
documentation when there is one.

## How it is measured

Every entry comes from the test corpus in this repository,
[BusinessCentral.AL.Language.Tests](https://github.com/aldevtools/BusinessCentral.AL.Language.Tests). Each test is a
probe: it runs AL code on a real Business Central service tier and asserts the exact result.

- **Corpus CI.** Every push runs the corpus on the newest minor of each supported major version.
- **Weekly sweep.** A weekly run covers every minor from 27.0 on, and the insider builds of the next version.

When a test gives a different result on two versions, it is checked by hand. A real change gets a version guard in
the probe (`#if BC29PLUS` and similar), a `// version change: <id>` comment at that guard, and an entry on this site.
A CI check fails when a guard comment has no entry here, so every guard stays documented.

A difference that only comes from how a test was written (for example a test that counts every row of a table that a
new app adds to) is fixed in the test and is not listed here.

## Where to start

- [All changes](changes/), with filters by version, area and class.
- [Changes by version](versions/).
- [How to contribute or report a change](contribute/).

## Limits

- An entry describes only the shapes the probes measure. Other code paths may or may not be affected.
- Build numbers are the builds the corpus ran on. A change can be in an earlier build of the same minor.
- "Documented by Microsoft: no" means we did not find it in the release notes, the what's new page or the update
  knowledge base article. It does not mean that no documentation exists anywhere.
