// Objects of cross-app fixture D for the TransferFields probe between fields of different apps (al-runner issue 6982).
// Tests: tests/al-language/record/transferfields-cross-app/TransferFieldsFieldApps.al.
//   95838 extends fixture A's target table 95831 with fields 95830 (Code[20]), 95832 (Integer), 95833 (Boolean) and 95834 (Code[20]);
//          fixture B, which this app does not depend on (and which does not depend on this app), adds the same numbers to A's source
//          table 95830 as Boolean, Integer, Code[20] and Text[30].
// local object: the owner app of each field is under test.

tableextension 95838 "REC TFX XD Target Ext" extends "REC TFX Target"
{
    fields
    {
        field(95830; "XD Code"; Code[20]) { DataClassification = SystemMetadata; }
        field(95832; "XD Qty"; Integer) { DataClassification = SystemMetadata; }
        field(95833; "XD Flag"; Boolean) { DataClassification = SystemMetadata; }
        field(95834; "XD Code 2"; Code[20]) { DataClassification = SystemMetadata; }
    }
}
