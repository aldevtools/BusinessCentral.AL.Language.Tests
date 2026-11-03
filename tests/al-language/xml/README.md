# xml

XmlDocument, XmlElement, XmlNode, XmlAttribute, namespaces and XPath.

## Topics

- (area folder itself): 33 AL files that are about the area as a whole or were not given a topic yet.
- `xml/`: the XML types (74 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 91 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (5, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `2365-xmldocument-nametable-assign`, `2366-xmlelement-innertext-assign`, `2369-xmlnsmgr-addnamespace-assign`, `2371-xmlnsmgr-pushscope-assign`, `2372-xmldocument-setdeclaration-assign-wrong-type`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `TestProbeXmlContracts.al`
- `TestXmlRuntimeContracts.al`
- `XmlAttributes.al`
- `XmlDocReadWrite.al`
- `XmlElement.al`
- `XmlEntitiesMisc.al`
- `XmlNodes.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
