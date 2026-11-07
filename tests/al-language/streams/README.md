# streams

InStream and OutStream, Blob fields, TempBlob, Media and MediaSet, files in memory.

## Topics

- (area folder itself): 74 AL files that are about the area as a whole or were not given a topic yet.
- `blob-tempblob/`: Blob fields and TempBlob (3 AL files).
- `instream-outstream/`: InStream and OutStream (17 AL files).
- `media/`: Media and MediaSet (17 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 77 files
- table 60008 "ALT Blob": 7 files
- table 60980 "ALT Media": 4 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/streams/`.
- Must-not-compile cases (16, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0076-media-importstream-four-arguments`, `0563-blob-export-is-onprem`, `0564-blob-import-is-onprem`, `0574-system-importstreamwithurlaccess-is-onprem`, `0641-mediaset-importstream-filename`, `0642-media-importstream-filename-all-majors`, `0643-media-exportfile-cloud`, `0644-media-importfile-cloud`, `0645-mediaset-exportfile-cloud`, `0646-mediaset-importfile-cloud`, `1749-list-of-blob`, `1788-blob-variable`, `2218-media-setfilter-guid-argument`, `2219-media-setrange-guid`, `2220-media-setrange-text`, `2555-blob-field-compare-direct`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `StTMedia.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.

- `excel-buffer-roundtrip/`: neutral public-API and page contracts reproduced from AL Runner reports.

- `excel-buffer-roundtrip/`: worksheet selection followed by reading the same or a fresh stream, with a persisted Blob control.
