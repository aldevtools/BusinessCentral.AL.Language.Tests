# http

HttpClient, HttpRequestMessage, HttpResponseMessage, HttpContent and HttpHeaders.

## Topics

- (area folder itself): 13 AL files that are about the area as a whole or were not given a topic yet.
- `client/`: HttpClient and requests (10 AL files).
- `headers/`: HttpHeaders and cookies (20 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 38 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/http/`.
- Must-not-compile cases (11, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0124-http-status-code-299-is-not-valid`, `0229-httpclient-no-send2`, `0651-httpclient-defaultnetworkwindowsauth-cloud`, `0652-httpclient-windowsauth-text-cloud`, `0653-httpclient-windowsauth-secrettext-cloud`, `0990-httprequesttype-asinteger-and-integer-assign`, `1389-invalid-return-types`, `1800-http-mock-status-code-redirect`, `1801-http-mock-status-code-not-valid`, `2367-httpclient-timeout-compound-assign`, `2615-httpcontent-clear-result-used`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
