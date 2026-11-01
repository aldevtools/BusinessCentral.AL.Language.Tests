// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-length-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93402 and 93403, test codeunit 93408
// Probe (al-runner issue 6663, writer Y66): FieldRef.Length of the field types and kinds that fieldref/lt-fieldref-length-kinds/
// FieldRefLengthKinds.al and record/lt-media-length-find-empty/MediaLengthFindEmpty.al do not cover: DateFormula, RecordId, TableFilter,
// Text and Code of the longest length, a FlowField of each result kind (Sum Decimal, Count Integer, Exist Boolean, Lookup Text and Date), a
// FlowFilter (Date, Code), a BigInteger with AutoIncrement, the system fields (2000000000 to 2000000005), the fields of virtual tables Integer and Date, and a field of a temporary record. Plus the reporter's helper that
// compares Type and Length of every field pair between two RecordRefs.
// BC versions: 27, 28, 29

table 93403 "LT Y66 FL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; HeadId; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; Txt; Text[40]) { }
        field(5; Dt; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 93402 "LT Y66 FL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Df; DateFormula) { }
        field(3; Rid; RecordId) { }
        field(4; Tf; TableFilter) { }
        field(5; TxMax; Text[2048]) { }
        field(6; CdMax; Code[2048]) { }
        field(7; FfSum; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT Y66 FL Line".Amount where(HeadId = field(Id))); }
        field(8; FfCount; Integer) { FieldClass = FlowField; CalcFormula = count("LT Y66 FL Line" where(HeadId = field(Id))); }
        field(9; FfExist; Boolean) { FieldClass = FlowField; CalcFormula = exist("LT Y66 FL Line" where(HeadId = field(Id))); }
        field(10; FfLookupTxt; Text[40]) { FieldClass = FlowField; CalcFormula = lookup("LT Y66 FL Line".Txt where(HeadId = field(Id))); }
        field(11; FfLookupDt; Date) { FieldClass = FlowField; CalcFormula = lookup("LT Y66 FL Line".Dt where(HeadId = field(Id))); }
        field(12; FlDate; Date) { FieldClass = FlowFilter; }
        field(13; FlCode; Code[20]) { FieldClass = FlowFilter; }
        field(14; AutoBig; BigInteger) { AutoIncrement = true; }
        field(15; Df2; DateFormula) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93408 "LT Y66 FieldRef Length Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Y66_FieldRefLength_FieldTypes()
    var
        RecRef: RecordRef;
        I: Integer;
    begin
        RecRef.Open(Database::"LT Y66 FL Row");
        for I := 2 to 15 do
            Observer.Observe(RecRef.Field(I).Name(), Describe(RecRef.Field(I)));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Y66_FieldRefLength_SystemFields()
    var
        RecRef: RecordRef;
        I: Integer;
    begin
        RecRef.Open(Database::"LT Y66 FL Row");
        for I := 2000000000 to 2000000005 do
            if RecRef.FieldExist(I) then
                Observer.Observe(Format(I) + ' ' + RecRef.Field(I).Name(), Describe(RecRef.Field(I)))
            else
                Observer.Observe(Format(I), 'no field');
        Observer.Finish();
    end;

    [Test]
    procedure Y66_FieldRefLength_VirtualAndTemporary()
    var
        RecRef: RecordRef;
        TempRow: Record "LT Y66 FL Row" temporary;
        I: Integer;
    begin
        RecRef.Open(Database::Integer);
        Observer.Observe('Integer.Number', Describe(RecRef.Field(1)));
        RecRef.Close();
        RecRef.Open(Database::Date);
        for I := 1 to RecRef.FieldCount() do
            Observer.Observe('Date.' + RecRef.FieldIndex(I).Name(), Describe(RecRef.FieldIndex(I)));
        RecRef.Close();
        RecRef.GetTable(TempRow);
        Observer.Observe('temporary DateFormula', Describe(RecRef.Field(2)));
        Observer.Finish();
    end;

    [Test]
    procedure Y66_FieldRefLength_ReporterHelper()
    var
        FromRec: RecordRef;
        ToRec: RecordRef;
        I: Integer;
        R: Text;
    begin
        FromRec.Open(Database::"LT Y66 FL Row");
        ToRec.Open(Database::"LT Y66 FL Row");
        for I := 1 to FromRec.FieldCount() do
            R += Format(FromRec.FieldIndex(I).Number()) + '=' + Format(FieldMatches(FromRec, ToRec, I, FromRec.FieldIndex(I).Number())) + ';';
        Observer.Observe('same table', R);
        Observer.Observe('DateFormula against DateFormula', Format(FieldMatches(FromRec, ToRec, 2, 15)));
        Observer.Observe('Text2048 against DateFormula', Format(FieldMatches(FromRec, ToRec, 5, 2)));
        Observer.Finish();
    end;

    local procedure FieldMatches(var FromRec: RecordRef; var ToRec: RecordRef; Index: Integer; ToFieldNo: Integer): Boolean
    var
        ToFieldRef: FieldRef;
    begin
        ToFieldRef := ToRec.Field(ToFieldNo);
        exit((ToFieldRef.Type() = FromRec.FieldIndex(Index).Type()) and
             (ToFieldRef.Length() >= FromRec.FieldIndex(Index).Length()));
    end;

    local procedure Describe(F: FieldRef): Text
    begin
        exit(Format(F.Type()) + '|' + Format(F.Class()) + '|' + Format(F.Length()));
    end;
}
