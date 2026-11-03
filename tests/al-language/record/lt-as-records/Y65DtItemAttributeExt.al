// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: Base Application table "Item Attribute"; filled by the install codeunit 92912 (Y47DtInstall.al, scenarios S8-S9), read by
//   test codeunit 92913 (Y47DtInstallRead.al, Y65_DtItemAttribute_Outcomes)
// Probe (al-runner issue 6668, writer Y65): a table extension of this app on a table of another app, as DataTransfer source filter and
//   destination in install code.
// BC versions: 27.5+

tableextension 93340 "LT Y65 Item Attribute" extends "Item Attribute"
{
    fields
    {
        field(93340; "LT Y65 Display Name"; Text[250]) { DataClassification = SystemMetadata; }
        field(93341; "LT Y65 Tag"; Text[30]) { DataClassification = SystemMetadata; }
    }
}
