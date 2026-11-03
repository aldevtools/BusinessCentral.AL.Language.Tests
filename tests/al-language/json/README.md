# json

JsonObject, JsonArray, JsonToken and JsonValue.

## Topics

- (area folder itself): 34 AL files that are about the area as a whole or were not given a topic yet.
- `json/`: the JSON types (33 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 55 files
- table 60008 "ALT Blob": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/json/`.
- Must-not-compile cases (33, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0007-appjson-assemblyprobingpaths`, `0071-appjson-assemblyprobingpaths-runtime-15_0`, `0072-appjson-assemblyprobingpaths-runtime-16_1`, `0073-appjson-assemblyprobingpaths-runtime-17_0`, `0228-jsonobject-no-put`, `0235-jsontoken-no-getname`, `0258-jsonobject-add-one-arg`, `0273-jsonobject-to-jsontoken-reverse`, `0364-jsonobject-selecttokens-runtime17`, `0640-jsonarray-selecttokens-runtime17-27`, `1200-jsontoken-selecttokens-runtime17-27`, `1244-appjson-assemblyprobingpaths-onprem-runtime-16_0`, `1245-appjson-assemblyprobingpaths-cloud-runtime-18_0`, `1264-appjson-contextsensitivehelpurl-not-a-url`, `1816-jsonobject-no-removeall`, `1817-jsonarray-no-removeall`, `1818-jsonobject-no-clear-method`, `1819-jsonarray-no-clear-method`, `1824-jsontoken-selecttokens-runtime17-27`, `2048-jsonarray-remove-token`, `2310-appjson-runtime-string-14`, `2311-appjson-runtime-number-14`, `2312-appjson-runtime-number-14-0`, `2313-appjson-runtime-abc`, `2314-appjson-runtime-three-parts`, `2315-appjson-runtime-four-parts`, `2316-appjson-runtime-trailing-dot`, `2317-appjson-runtime-leading-dot`, `2318-appjson-runtime-negative`, `2319-appjson-runtime-zero`, `2320-appjson-runtime-19-0`, `2321-appjson-runtime-99-0`, `2368-jsonobject-readfrom-assign`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
