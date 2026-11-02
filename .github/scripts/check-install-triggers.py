#!/usr/bin/env python3
"""Fail the build when a codeunit with Subtype = Install or Upgrade is added to the corpus apps.

Why: an install or upgrade trigger runs when the app is published. One that raises (a per-company table written from OnInstallAppPerDatabase: "You must choose a
company before you can access the ... table.") makes the publish fail, and then the app does not install on ANY BC version: the whole matrix is red before a single test
runs. A probe must never live in an install trigger; read the effect from a test instead. The files below are the install codeunits that existed when this check was added;
a new one needs a conscious change of this list, after the batch was published to a local container that starts from an empty database.
"""
import re
import sys
from pathlib import Path

ALLOWED = {
    # corpus issue 661 (writer BF): writes only `if Insert() then;` into a DataPerCompany = false log; reads that can fail run in a TryFunction.
    'tests/al-language/install/lt-bf-install-probes/BfInstallFixtures.al',
    # corpus issue 812: install code writes only `if Insert() then;` into DataPerCompany = false logs; the tag calls write nothing else.
    'tests/al-language-xapp-a/QzXaUpgradeTagProbe.al',
    # al-runner issue 6367 (writer X3): first-install DataVersion seen by the app's own code and by a dependency; writes only `if Insert() then;`
    # into a DataPerCompany = false log, and the dependency helper it calls neither writes nor raises.
    'tests/al-language-xapp-b/X3XbFirstInstall.al',
    # al-runtime-rs install-order probes (writer Y8): each install code logs what it sees and writes one row, only `if Insert(..) then;` into
    # DataPerCompany = false tables; the only trigger on those inserts (fixture B's table extension) appends text.
    'tests/al-language-xapp-a/Y8XaInstallOrder.al',
    'tests/al-language-xapp-d/Y8XdInstallOrder.al',
    'tests/al-language-xapp-b/Y8XbInstallOrder.al',
    'tests/al-language/_fixtures/ALTInstallProbe.al',
    'tests/al-language/_fixtures/ALTQuotedInstallProbe.al',
    'tests/al-language/install/TestInstallSeeder.al',
    'tests/al-language/record/TestCodeunitMetadataVirtualTable.al',
    'tests/al-language/record/TestAllObjVirtualTable.al',
    'tests/al-language/types/TestBlankEnumInitInstaller.Codeunit.al',
    'tests/al-language/install/TestInstallStartSessionProbe.al',
    'tests/al-language/events/lt-trigger-pins/PUpgradeTriggers.al',
    'tests/al-language-onprem-dotnet/lt-bb-dotnet/BbNavHelpersInstall.al',
    'tests/al-language/record/lt-as-records/AsDtInstaller.al',
    # al-runner issue 6586 (writer Y47): DataTransfer in OnInstallAppPerCompany, same pattern as AsDtInstaller.al: every copy in a TryFunction,
    # every write `if Insert() then;` behind a Get, a 'DONE' row stops a second run. Published on BC 29 SaaS, Windows 27.5 and 28.5 from empty tables.
    'tests/al-language/record/lt-as-records/Y47DtInstall.al',
    'tests/al-language/install/lt-cm-install-leads/CmInstallObjects.al',
    # al-runner issue 6638 (writer Y56): install code creates the number sequences SeqCarry.al restarts and deletes; only NumberSequence
    # calls behind an Exists check of the same name, no table writes.
    'tests/al-language/codeunit/lt-seq-carry/SeqCarryInstall.al',
    # Not a corpus app: the helper app that nightly-windows.yml publishes to create the tenant encryption key (#282), and
    # unpublishes again. ci.yml never compiles it. Its install trigger cannot raise (TryFunction); measured on Windows
    # BC 27.5 onprem, 29.0 onprem and 29.0 sandbox (runs 39223208230, 39223203793, 39223200014).
    '.github/nightly-windows/encryption-key/src/EncryptionKeySetup.al',
}
PATTERN = re.compile(r'^\s*Subtype\s*=\s*(Install|Upgrade)\s*;', re.M | re.I)


def find(root: Path, allowed):
    bad = []
    for al in sorted(root.rglob('*.al')):
        rel = al.relative_to(root).as_posix()
        if '.git' in al.parts or rel in allowed:
            continue
        if PATTERN.search(al.read_text(encoding='utf-8-sig', errors='replace')):
            bad.append(rel)
    return bad


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
    bad = find(root, ALLOWED)
    for rel in bad:
        print('::error file=%s::codeunit with Subtype = Install/Upgrade: it runs at publish and one failure breaks the app on every BC version. See .github/scripts/check-install-triggers.py' % rel)
    if bad:
        return 1
    print('OK: no new install or upgrade codeunit')
    return 0


if __name__ == '__main__':
    sys.exit(main())
