#!/usr/bin/env python3
"""Fail the build when a codeunit with Subtype = Install or Upgrade is added to the corpus apps.

Why: an install or upgrade trigger runs when the app is published. One that raises (a per-company table written from OnInstallAppPerDatabase: "You must choose a
company before you can access the ... table.") makes the publish fail, and then the app does not install on ANY BC version: the whole matrix is red before a single test
runs. A probe must never live in an install trigger; read the effect from a test instead. The codeunits below are the install and upgrade codeunits that exist; a new one
needs a conscious change of this list, after the batch was published to a local container that starts from an empty database.

Keys: "<app folder> codeunit <id>". The app folder is the nearest folder above the file that holds an app.json. A key names the object, not the file, so moving or
renaming a file inside its app does not change it. A new install codeunit in a file that already holds an allowed one still needs its own line.
"""
import re
import sys
from pathlib import Path

ALLOWED = {
    # corpus issue 661 (writer BF): writes only `if Insert() then;` into a DataPerCompany = false log; reads that can fail run in a TryFunction.
    # (BfInstallFixtures.al)
    'tests/al-language codeunit 81254',  # "LT BF Install Late"
    'tests/al-language codeunit 90432',  # "LT UM b Install"
    # corpus issue 812: install code writes only `if Insert() then;` into DataPerCompany = false logs; the tag calls write nothing else.
    # (QzXaUpgradeTagProbe.al)
    'tests/al-language-xapp-a codeunit 61174',  # "LT UT Install"
    # corpus writer Y3: install order and subscribers; install code writes only `if Insert() then;` into DataPerCompany = false tables.
    # (Y3XaInstallEvents.al, Y3XbInstallEvents.al)
    'tests/al-language-xapp-a codeunit 61179',  # "LT Y3 XA Install"
    'tests/al-language-xapp-b codeunit 61149',  # "LT Y3 XB Install"
    # al-runner issue 6367 (writer X3): first-install DataVersion seen by the app's own code and by a dependency; writes only `if Insert() then;`
    # into a DataPerCompany = false log, and the dependency helper it calls neither writes nor raises. (X3XbFirstInstall.al)
    'tests/al-language-xapp-b codeunit 61141',  # "LT X3 XB Install"
    # al-runtime-rs install-order probes (writer Y8): each install code logs what it sees and writes one row, only `if Insert(..) then;` into
    # DataPerCompany = false tables; the only trigger on those inserts (fixture B's table extension) appends text.
    # (Y8XaInstallOrder.al, Y8XdInstallOrder.al, Y8XbInstallOrder.al)
    'tests/al-language-xapp-a codeunit 61183',  # "LT Y8 XA Install"
    'tests/al-language-xapp-a codeunit 61376',  # "LT Y79 XA Install"
    'tests/al-language-xapp-a codeunit 94449',  # "LT Y85 Pkg Install"
    'tests/al-language-xapp-a codeunit 94682',  # "LT Y88 Pkg Install"
    # al-runner issue 6649: LoadPackageData in the install part that does not match the table's DataPerCompany; each load in a TryFunction,
    # results only `if Insert() then;` into a DataPerCompany = false log. (PkgDataPartsFixture.al)
    'tests/al-language-xapp-a codeunit 97999',  # "LT PkgParts Install"
    # al-runner issue 7169: reads "Published As" in TryFunctions, writes only `if Insert() then;` into a DataPerCompany = false log. (R7169XaInstallPublishedAs.al)
    'tests/al-language-xapp-a codeunit 96081',  # "LT R7169 XA Install"
    'tests/al-language-xapp-d codeunit 61190',  # "LT Y8 XD Install"
    'tests/al-language-xapp-d codeunit 61365',  # "LT Y64 XD Install"
    'tests/al-language-xapp-d codeunit 61394',  # "LT Y79 XD Install"
    'tests/al-language-xapp-b codeunit 61186',  # "LT Y8 XB Install"
    'tests/al-language-xapp-b codeunit 61356',  # "LT Y64 XB Install"
    'tests/al-language-xapp-b codeunit 61384',  # "LT Y79 XB Install"
    # (ALTInstallProbe.al)
    'tests/al-language codeunit 60838',  # "ALT Install Probe"
    'tests/al-language codeunit 50302',  # "LT UR Install Low"
    # (TestInstallSeeder.al)
    'tests/al-language codeunit 60618',  # "Install Seeder"
    'tests/al-language codeunit 90431',  # "LT UM Mu Install"
    # (TestBlankEnumInitInstaller.Codeunit.al)
    'tests/al-language codeunit 60894',  # "BEI Installer"
    'tests/al-language codeunit 90515',  # "LT UR Install High"
    # (TestInstallStartSessionProbe.al)
    'tests/al-language codeunit 60445',  # "Install StartSession Probe"
    'tests/al-language codeunit 90435',  # "LT UM Zz Install"
    # (PUpgradeTriggers.al)
    'tests/al-language codeunit 67281',  # "LT P Upgrade Full"
    'tests/al-language codeunit 67282',  # "LT P Upgrade Empty"
    # (BbNavHelpersInstall.al)
    'tests/al-language-onprem-dotnet codeunit 99223',  # "LT BB Install NavHelper Probe"
    # (AsDtInstaller.al)
    'tests/al-language codeunit 79938',  # "LT AS DT Installer"
    'tests/al-language codeunit 90433',  # "LT UM Cu Install"
    # al-runner issue 6586 (writer Y47): DataTransfer in OnInstallAppPerCompany, same pattern as AsDtInstaller.al: every copy in a TryFunction,
    # every write `if Insert() then;` behind a Get, a 'DONE' row stops a second run. Published on BC 29 SaaS, Windows 27.5 and 28.5 from empty tables.
    # (Y47DtInstall.al)
    'tests/al-language codeunit 92912',  # "LT Y47 DT Installer"
    # (CmInstallObjects.al)
    'tests/al-language codeunit 84838',  # "LT CM Install"
    'tests/al-language codeunit 90434',  # "LT UM Ay Install"
    'tests/al-language codeunit 93329',  # "LT Y64 Install"
    # al-runner issue 6638 (writer Y56): install code creates the number sequences SeqCarry.al restarts and deletes; only NumberSequence
    # calls behind an Exists check of the same name, no table writes. (SeqCarryInstall.al)
    'tests/al-language codeunit 93600',  # "LT Y56 Seq Install"
    # Not a corpus app: the helper app that nightly-windows.yml publishes to create the tenant encryption key (#282), and
    # unpublishes again. ci.yml never compiles it. Its install trigger cannot raise (TryFunction); measured on Windows
    # BC 27.5 onprem, 29.0 onprem and 29.0 sandbox (runs 39223208230, 39223203793, 39223200014). (EncryptionKeySetup.al)
    '.github/nightly-windows/encryption-key codeunit 81846',  # "LT BK Encryption Key Install"
}
PATTERN = re.compile(r'^\s*Subtype\s*=\s*(Install|Upgrade)\s*;', re.M | re.I)
# The object a Subtype line belongs to is the last object header above it.
HEADER = re.compile(r'^\s*(codeunit|table|tableextension|page|pageextension|pagecustomization|report|reportextension|query|xmlport|enum|enumextension|'
                    r'interface|permissionset|permissionsetextension|profile|controladdin|entitlement|dotnet)\b(?:\s+(\d+))?', re.M | re.I)


def app_folder(root: Path, al: Path) -> str:
    d = al.parent
    while d != root and not (d / 'app.json').exists():
        d = d.parent
    return d.relative_to(root).as_posix() if d != root else '.'


def find(root: Path, allowed):
    """Every install or upgrade codeunit under root that is not in allowed, as (file, key). key is None when the Subtype line has no codeunit header above it."""
    bad = []
    for al in sorted(root.rglob('*.al')):
        if '.git' in al.parts:
            continue
        src = al.read_text(encoding='utf-8-sig', errors='replace')
        headers = list(HEADER.finditer(src))
        for m in PATTERN.finditer(src):
            above = [h for h in headers if h.start() < m.start()]
            h = above[-1] if above else None
            key = '%s codeunit %s' % (app_folder(root, al), h.group(2)) if h and h.group(1).lower() == 'codeunit' and h.group(2) else None
            if key not in allowed:
                bad.append((al.relative_to(root).as_posix(), key))
    return bad


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
    bad = find(root.resolve(), ALLOWED)
    for rel, key in bad:
        print('::error file=%s::codeunit with Subtype = Install/Upgrade (%s): it runs at publish and one failure breaks the app on every BC version. See .github/scripts/check-install-triggers.py'
              % (rel, key or 'no codeunit header found above the Subtype line'))
    if bad:
        return 1
    print('OK: no new install or upgrade codeunit')
    return 0


if __name__ == '__main__':
    sys.exit(main())
