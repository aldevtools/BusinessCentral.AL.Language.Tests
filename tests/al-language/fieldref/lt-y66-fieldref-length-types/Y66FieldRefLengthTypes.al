// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-length-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 93402 and 93403, test codeunit 93408
// Probe (al-runner issue 6663, writer Y66): FieldRef.Length of the field types and kinds that fieldref/lt-fieldref-length-kinds/
// FieldRefLengthKinds.al and record/lt-media-length-find-empty/MediaLengthFindEmpty.al do not cover: DateFormula, RecordId, TableFilter,
// Text and Code of the longest length, a FlowField of each result kind (Sum Decimal, Count Integer, Exist Boolean, Lookup Text and Date), a
// FlowFilter (Date, Code), a BigInteger with AutoIncrement, the system fields (2000000000 to 2000000004; 2000000005
// SystemCreatedByUserName on BC 29), the fields of virtual tables Integer and Date, and a field of a temporary record. Plus the reporter's helper that
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
        Observer.Expect('Df', 'DateFormula|Normal|32');
        Observer.Expect('Rid', 'RecordID|Normal|448');
        Observer.Expect('Tf', 'TableFilter|Normal|504');
        Observer.Expect('TxMax', 'Text|Normal|2048');
        Observer.Expect('CdMax', 'Code|Normal|2048');
        Observer.Expect('FfSum', 'Decimal|FlowField|12');
        Observer.Expect('FfCount', 'Integer|FlowField|4');
        Observer.Expect('FfExist', 'Boolean|FlowField|4');
        Observer.Expect('FfLookupTxt', 'Text|FlowField|40');
        Observer.Expect('FfLookupDt', 'Date|FlowField|4');
        Observer.Expect('FlDate', 'Date|FlowFilter|4');
        Observer.Expect('FlCode', 'Code|FlowFilter|20');
        Observer.Expect('AutoBig', 'BigInteger|Normal|8');
        Observer.Expect('Df2', 'DateFormula|Normal|32');
        Observer.Verify();
    end;

    [Test]
    procedure Y66_FieldRefLength_SystemFields()
    var
        RecRef: RecordRef;
        I: Integer;
    begin
        RecRef.Open(Database::"LT Y66 FL Row");
        for I := 2000000000 to 2000000004 do
            if RecRef.FieldExist(I) then
                Observer.Observe(Format(I) + ' ' + RecRef.Field(I).Name(), Describe(RecRef.Field(I)))
            else
                Observer.Observe(Format(I), 'no field');
#if BC29PLUS
        Observer.Observe('2000000005 ' + RecRef.Field(2000000005).Name(), Describe(RecRef.Field(2000000005)));
#endif
        Observer.Expect('2000000000 $systemId', 'GUID|Normal|16');
        Observer.Expect('2000000001 SystemCreatedAt', 'DateTime|Normal|8');
        Observer.Expect('2000000002 SystemCreatedBy', 'GUID|Normal|16');
        Observer.Expect('2000000003 SystemModifiedAt', 'DateTime|Normal|8');
        Observer.Expect('2000000004 SystemModifiedBy', 'GUID|Normal|16');
#if BC29PLUS
        Observer.Expect('2000000005 SystemCreatedByUserName', 'Text|FlowField|50');
#endif
        Observer.Verify();
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
        Observer.Expect('Integer.Number', 'Integer|Normal|4');
        Observer.Expect('Date.Period Type', 'Option|Normal|4');
        Observer.Expect('Date.Period Start', 'Date|Normal|4');
        Observer.Expect('Date.Period End', 'Date|Normal|4');
        Observer.Expect('Date.Period No.', 'Integer|Normal|4');
        Observer.Expect('Date.Period Name', 'Text|Normal|31');
        Observer.Expect('Date.Period Invariant Name', 'Text|Normal|31');
        Observer.Expect('temporary DateFormula', 'DateFormula|Normal|32');
        Observer.Verify();
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
        Observer.Expect('same table', '1=Yes;2=Yes;3=Yes;4=Yes;5=Yes;6=Yes;14=Yes;15=Yes;12=Yes;13=Yes;7=Yes;8=Yes;9=Yes;10=Yes;11=Yes;');
        Observer.Expect('DateFormula against DateFormula', 'Yes');
        Observer.Expect('Text2048 against DateFormula', 'No');
        Observer.Verify();
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
