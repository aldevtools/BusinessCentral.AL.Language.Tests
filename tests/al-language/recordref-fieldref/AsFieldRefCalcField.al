// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-calcfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79902, 79903, 79910-79912, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, items 12 and 14).
// Facts: FieldRef.CalcField() on a Blob field of a stored row read without CalcFields (Value, HasValue and the content afterwards), on a Code
//   field (error text) and on a FlowField (item 12); Validate of a field whose TableRelation is filtered by a FlowField of the record, without
//   CalcFields before: the FlowField on the record afterwards (item 14).
// BC versions: 27-29

codeunit 79929 "LT AS FieldRef CalcField"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    local procedure SeedBlob()
    var
        Row: Record "LT AS Row";
        Out: OutStream;
    begin
        Helper.SeedRows();
        Row.Get('A');
        Row.Data.CreateOutStream(Out);
        Out.WriteText('blob text');
        Row.Modify();
    end;

    local procedure BlobText(var Row: Record "LT AS Row"): Text
    var
        Ins: InStream;
        T: Text;
    begin
        Row.Data.CreateInStream(Ins);
        Ins.ReadText(T);
        exit(T);
    end;

    [Test]
    procedure Blob_ReadWithoutCalcFields_ThenCalcField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS Row";
        Back: Record "LT AS Row";
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        SeedBlob();
        Row.Get('A');
        Observer.Observe('rec_hasvalue_before', Format(Row.Data.HasValue()));
        Ref.GetTable(Row);
        Fld := Ref.Field(4);
        Ref.SetTable(Back);
        Observer.Observe('text_before', BlobText(Back));
        Fld.CalcField();
        Observer.Observe('value_after', Format(Fld.Value));
        Ref.SetTable(Back);
        Observer.Observe('hasvalue_after', Format(Back.Data.HasValue()));
        Observer.Observe('text_after', BlobText(Back));
        Observer.Expect('rec_hasvalue_before', 'Yes');
        Observer.Expect('text_before', '');
        Observer.Expect('value_after', '*');
        Observer.Expect('hasvalue_after', 'Yes');
        Observer.Expect('text_after', 'blob text');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_CalcField()
    var
        Observer: Codeunit "Probe Observer";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Ref.Open(Database::"LT AS Row");
        Ref.FindFirst();
        ClearLastError();
        if TryCalcField(Ref, 5) then
            Observer.Observe('code', 'ok:' + Format(Ref.Field(5).Value))
        else
            Observer.Observe('code', Helper.LastError());
        Observer.Expect('code', 'The Cd field in the LT AS Row table must be a FlowField.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure FlowField_CalcField()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT AS Log";
        Ref: RecordRef;
    begin
        Helper.SeedRows();
        Log.Add('one');
        Log.Add('two');
        Ref.Open(Database::"LT AS Row");
        Ref.FindFirst();
        Observer.Observe('before', Format(Ref.Field(6).Value));
        Ref.Field(6).CalcField();
        Observer.Observe('after', Format(Ref.Field(6).Value));
        Observer.Expect('before', '0');
        Observer.Expect('after', '2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCalcField(var Ref: RecordRef; FieldNo: Integer)
    begin
        Ref.Field(FieldNo).CalcField();
    end;

    local procedure SeedRelation()
    var
        Parent: Record "LT AS Rel Parent";
        Head: Record "LT AS Flow Head";
        Line: Record "LT AS Flow Line";
    begin
        Parent.DeleteAll();
        Head.DeleteAll();
        Line.DeleteAll();
        Parent."Code" := 'P0';
        Parent.Kind := 0;
        Parent.Insert();
        Parent."Code" := 'P2';
        Parent.Kind := 2;
        Parent.Insert();
        Head."Code" := 'H';
        Head.Insert();
        Line.Head := 'H';
        Line.Line := 1;
        Line.Insert();
        Line.Line := 2;
        Line.Insert();
    end;

    [Test]
    procedure Validate_RelationOnFlowField_FlowFieldAfter()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT AS Flow Head";
    begin
        SeedRelation();
        Head.Get('H');
        Observer.Observe('flow_before', Format(Head.LineCount));
        ClearLastError();
        if TryValidate(Head, 'P2') then
            Observer.Observe('validate_p2', 'ok:' + Head.RelCode)
        else
            Observer.Observe('validate_p2', Helper.LastError());
        Observer.Observe('flow_after', Format(Head.LineCount));
        Observer.Expect('flow_before', '0');
        Observer.Expect('validate_p2', 'ok:P2');
        Observer.Expect('flow_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_RelationOnFlowField_KindZero()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT AS Flow Head";
    begin
        SeedRelation();
        Head.Get('H');
        ClearLastError();
        if TryValidate(Head, 'P0') then
            Observer.Observe('validate_p0', 'ok:' + Head.RelCode)
        else
            Observer.Observe('validate_p0', Helper.LastError());
        Observer.Observe('flow_after', Format(Head.LineCount));
        Observer.Expect('validate_p0', 'The field RelCode of table LT AS Flow Head contains a value (P0) that cannot be found in the related table (LT AS Rel Parent).|DB:NothingInsideFilter');
        Observer.Expect('flow_after', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryValidate(var Head: Record "LT AS Flow Head"; Value: Code[20])
    begin
        Head.Validate(RelCode, Value);
    end;
}
