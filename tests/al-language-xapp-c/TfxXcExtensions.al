// Objects of cross-app fixture C for the TransferFields probe between fields of different apps (al-runner issue 6982).
// Tests: tests/al-language/record/transferfields-cross-app/TransferFieldsFieldApps.al.
//   95837 extends fixture A's target table 95831 with field 95831 (Code[20]); fixture B, which this app depends on, adds field 95831 as
//          a Boolean to A's source table 95830.
// local object: the owner app of each field is under test.

tableextension 95837 "REC TFX XC Target Ext" extends "REC TFX Target"
{
    fields
    {
        field(95831; "XC Code"; Code[20]) { DataClassification = SystemMetadata; }
    }
}
