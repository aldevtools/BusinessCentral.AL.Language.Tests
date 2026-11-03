// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus issue 656 item 2: the Field table's "Type Name" (and Len) for a field of each data type (PZFieldObsoleteRows.al pins only Text).
// Probe: observed values; every literal asserted below is what the BC tier produced.
// BC versions: 27, 28, 29
enum 80771 "LT BA Kind"
{
    Extensible = false;
    value(0; First) { }
    value(1; Second) { }
}

table 80770 "LT BA Types"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; FInteger; Integer) { }
        field(2; FCode; Code[20]) { }
        field(3; FDecimal; Decimal) { }
        field(4; FOption; Option) { OptionMembers = A,B,C; }
        field(5; FEnum; Enum "LT BA Kind") { }
        field(6; FBoolean; Boolean) { }
        field(7; FDate; Date) { }
        field(8; FDateTime; DateTime) { }
        field(9; FTime; Time) { }
        field(10; FGuid; Guid) { }
        field(11; FBlob; Blob) { }
        field(12; FMedia; Media) { }
        field(13; FMediaSet; MediaSet) { }
        field(14; FBigInteger; BigInteger) { }
        field(15; FDuration; Duration) { }
        field(16; FDateFormula; DateFormula) { }
        field(17; FRecordId; RecordId) { }
        field(18; FText; Text[100]) { }
        field(19; FTableFilter; TableFilter) { }
    }
    keys
    {
        key(PK; FInteger) { Clustered = true; }
    }
}

codeunit 80772 "LT BA Field Type Name"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BaFieldTypeName_Scalars()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(1, 9));
        Observer.Expect('rows', 'FInteger:Integer/4 FCode:Code20/20 FDecimal:Decimal/12 FOption:Option/4 FEnum:Option/4 FBoolean:Boolean/4 FDate:Date/4 FDateTime:DateTime/8 FTime:Time/4 ');
        Observer.Verify();
    end;

    [Test]
    procedure BaFieldTypeName_Others()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(10, 19));
        Observer.Expect('rows', 'FGuid:GUID/16 FBlob:BLOB/8 FMedia:Media/16 FMediaSet:MediaSet/16 FBigInteger:BigInteger/8 FDuration:Duration/8 FDateFormula:DateFormula/32 FRecordId:RecordID/448 FText:Text100/100 FTableFilter:TableFilter/504 ');
        Observer.Verify();
    end;

    // "<field name>:<Type Name>/<Len>" for the fields FromNo..ToNo of table 80770.
    local procedure Rows(FromNo: Integer; ToNo: Integer): Text
    var
        FieldRec: Record Field;
        Result: Text;
    begin
        FieldRec.SetRange(TableNo, Database::"LT BA Types");
        FieldRec.SetRange("No.", FromNo, ToNo);
        if FieldRec.FindSet() then
            repeat
                Result += FieldRec.FieldName + ':' + FieldRec."Type Name" + '/' + Format(FieldRec.Len) + ' ';
            until FieldRec.Next() = 0;
        exit(Result);
    end;
}
