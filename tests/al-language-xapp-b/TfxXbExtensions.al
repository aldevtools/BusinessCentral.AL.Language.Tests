// Objects of cross-app fixture B for the TransferFields probe between fields of different apps (al-runner issue 6982).
// Tests: tests/al-language/record/transferfields-cross-app/TransferFieldsFieldApps.al.
//   95834 extends fixture A's source table 95830 with fields whose numbers fixture D (95830, 95832, 95833, 95834), fixture C (95831)
//          and fixture A itself (95835, a field of A's target table) use on A's target table 95831 with another or the same type.
//   95835 and 95836 extend fixture A's tables 95832 and 95833 with field 95830 of two types (two fields of this one app).
// local object: the owner app of each field is under test.

tableextension 95834 "REC TFX XB Source Ext" extends "REC TFX Source"
{
    fields
    {
        field(95830; "XB Flag D"; Boolean) { DataClassification = SystemMetadata; }
        field(95831; "XB Flag C"; Boolean) { DataClassification = SystemMetadata; }
        field(95832; "XB Qty D"; Integer) { DataClassification = SystemMetadata; }
        field(95833; "XB Code D"; Code[20]) { DataClassification = SystemMetadata; }
        field(95834; "XB Text D"; Text[30]) { DataClassification = SystemMetadata; }
        field(95835; "XB Flag A"; Boolean) { DataClassification = SystemMetadata; }
    }
}

tableextension 95835 "REC TFX XB Source2 Ext" extends "REC TFX Source 2"
{
    fields
    {
        field(95830; "XB Same Flag"; Boolean) { DataClassification = SystemMetadata; }
    }
}

tableextension 95836 "REC TFX XB Target2 Ext" extends "REC TFX Target 2"
{
    fields
    {
        field(95830; "XB Same Code"; Code[20]) { DataClassification = SystemMetadata; }
    }
}
