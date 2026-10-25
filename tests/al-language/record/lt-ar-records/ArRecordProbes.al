// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 79800-79803 (ArFixtures.al)
// Probe: corpus issue 643 (records, fields and table relations, part 1); every literal asserted below is what the BC service tier produced
// on the corpus CI matrix.
// Facts: FilterPageBuilder.AddRecord twice with one name (item 1); Media and MediaSet ImportStream on a field that already holds media (item 2);
// SetCurrentKey on a Media and a MediaSet field (item 7); table globals of a record in an array element and through RecordRef.SetTable (item 9);
// Format(Record) position of FlowFilter fields among FlowFields (item 12); a Variant holding a filtered RecordRef assigned to a Record and
// passed to a Record parameter (item 14).
// Results (BC 29.0): a second AddRecord under one name for another table fails "A table that has the name Rows already exists with a different ID."
// (Argument), for the same table it succeeds and keeps the first control; a re-imported Media gets a new id and Modify deletes the old Tenant
// Media row, a MediaSet import adds an item and keeps the old one; SetCurrentKey on a Media or MediaSet field succeeds; an array element keeps
// its own table globals (assignment does not copy them); Format(Record) lists normal fields, then FlowFilter fields, then FlowFields; a Record
// assigned from a Variant holding a filtered RecordRef gets the current row and position but not the filters.
// Already pinned elsewhere: SetView on an unknown control (filterpage/W3FilterPageBuilder.al), MediaSet.Item(0) / Item(Count + 1) and
// ExportStream of an empty Media (streams/StTMedia.al), SetCurrentKey on a FlowField, FlowFilter and Blob (record/ProbeClearAllSetKeyHyperlink.al).
// BC versions: 27, 28, 29

codeunit 79850 "LT AR Record Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure PngIn(var TempBlob: Codeunit "Temp Blob"; var Ins: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        Out: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(Out);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Out);
        TempBlob.CreateInStream(Ins);
    end;

    local procedure Seed()
    var
        Row: Record "LT AR Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 4 do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'r' + Format(i);
            Row.Insert();
        end;
    end;

    // ---- item 1: FilterPageBuilder.AddRecord twice with the same name ----

    [TryFunction]
    local procedure TryAddOther(var FPB: FilterPageBuilder; Name: Text)
    var
        Other: Record "LT AR Other";
    begin
        FPB.AddRecord(Name, Other);
    end;

    [TryFunction]
    local procedure TryAddRow(var FPB: FilterPageBuilder; Name: Text)
    var
        Row: Record "LT AR Row";
    begin
        Row.SetRange(Id, 2);
        FPB.AddRecord(Name, Row);
    end;

    [Test]
    procedure AddRecord_SameNameOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Row: Record "LT AR Row";
        Other: Record "LT AR Other";
    begin
        FPB.AddRecord('Rows', Row);
        Observer.Observe('try', Format(TryAddOther(FPB, 'Rows')));
        Observer.ObserveError('e');
        Observer.Observe('count', Format(FPB.Count()));
        asserterror FPB.AddRecord('Rows', Other);
        Observer.ObserveError('ae');
        Observer.Expect('try', 'No');
        Observer.Expect('e|text', 'A table that has the name Rows already exists with a different ID.');
        Observer.Expect('e|code', 'Argument');
        Observer.Expect('count', '1');
        Observer.Expect('ae|text', 'A table that has the name Rows already exists with a different ID.');
        Observer.Expect('ae|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure AddRecord_SameNameSameTable()
    var
        Observer: Codeunit "Probe Observer";
        FPB: FilterPageBuilder;
        Row: Record "LT AR Row";
    begin
        FPB.AddRecord('Rows', Row);
        Observer.Observe('try', Format(TryAddRow(FPB, 'Rows')));
        Observer.ObserveError('e');
        Observer.Observe('count', Format(FPB.Count()));
        Observer.Observe('view', FPB.GetView('Rows'));
        Observer.Expect('try', 'Yes');
        Observer.Expect('e|text', '');
        Observer.Expect('e|code', '');
        Observer.Expect('count', '1');
        Observer.Expect('view', 'VERSION(1) SORTING(Id)');
        Observer.Verify();
    end;

    // ---- item 2: ImportStream on a Media / MediaSet field that already holds media ----

    [Test]
    procedure Media_ImportStream_OnFilledField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AR Row";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        Ins: InStream;
        First: Guid;
        Second: Guid;
    begin
        Seed();
        Row.Get(1);
        PngIn(TempBlob, Ins);
        Row.Pic.ImportStream(Ins, 'one');
        Row.Modify();
        First := Row.Pic.MediaId();
        PngIn(TempBlob, Ins);
        Row.Pic.ImportStream(Ins, 'two');
        Second := Row.Pic.MediaId();
        Observer.Observe('changed', Format(First <> Second));
        Observer.Observe('old before modify', Format(TenantMedia.Get(First)));
        Row.Modify();
        Observer.Observe('old after modify', Format(TenantMedia.Get(First)));
        Observer.Observe('new', Format(TenantMedia.Get(Second)));
        Row.Get(1);
        Observer.Observe('stored is new', Format(Row.Pic.MediaId() = Second));
        Observer.Expect('changed', 'Yes');
        Observer.Expect('old before modify', 'Yes');
        Observer.Expect('old after modify', 'No');
        Observer.Expect('new', 'Yes');
        Observer.Expect('stored is new', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSet_ImportStream_OnFilledField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AR Row";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        Ins: InStream;
        SetId: Guid;
        Item1: Guid;
    begin
        Seed();
        Row.Get(1);
        PngIn(TempBlob, Ins);
        Row.Pics.ImportStream(Ins, 'one');
        Row.Modify();
        SetId := Row.Pics.MediaId();
        Item1 := Row.Pics.Item(1);
        PngIn(TempBlob, Ins);
        Row.Pics.ImportStream(Ins, 'two');
        Row.Modify();
        Row.Get(1);
        Observer.Observe('count', Format(Row.Pics.Count()));
        Observer.Observe('same set', Format(Row.Pics.MediaId() = SetId));
        Observer.Observe('item1 kept', Format(Row.Pics.Item(1) = Item1));
        Observer.Observe('item2 new', Format(Row.Pics.Item(2) <> Item1));
        Observer.Observe('old media', Format(TenantMedia.Get(Item1)));
        Observer.Expect('count', '2');
        Observer.Expect('same set', 'Yes');
        Observer.Expect('item1 kept', 'Yes');
        Observer.Expect('item2 new', 'Yes');
        Observer.Expect('old media', 'Yes');
        Observer.Verify();
    end;

    // ---- item 7: SetCurrentKey on a Media and a MediaSet field ----

    [TryFunction]
    local procedure TryKeyMedia(var Row: Record "LT AR Row")
    begin
        Row.SetCurrentKey(Pic);
    end;

    [TryFunction]
    local procedure TryKeyMediaSet(var Row: Record "LT AR Row")
    begin
        Row.SetCurrentKey(Pics);
    end;

    [Test]
    procedure SetCurrentKey_Media()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AR Row";
    begin
        Seed();
        Observer.Observe('ok', Format(TryKeyMedia(Row)));
        Observer.ObserveError('e');
        Observer.Observe('key', Row.CurrentKey());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('e|text', '');
        Observer.Expect('e|code', '');
        Observer.Expect('key', 'Pic');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_MediaSet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AR Row";
    begin
        Seed();
        Observer.Observe('ok', Format(TryKeyMediaSet(Row)));
        Observer.ObserveError('e');
        Observer.Observe('key', Row.CurrentKey());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('e|text', '');
        Observer.Expect('e|code', '');
        Observer.Expect('key', 'Pics');
        Observer.Verify();
    end;

    // ---- item 9: table globals of a record in an array element, and through RecordRef.SetTable / GetTable ----

    [Test]
    procedure TableGlobals_ArrayElement()
    var
        Observer: Codeunit "Probe Observer";
        Rows: array[2] of Record "LT AR Row";
        Plain: Record "LT AR Row";
    begin
        Rows[1].Bump();
        Rows[1].Bump();
        Observer.Observe('elem1', Format(Rows[1].GetCounter()));
        Observer.Observe('elem2', Format(Rows[2].GetCounter()));
        Rows[2] := Rows[1];
        Observer.Observe('elem2 after assign', Format(Rows[2].GetCounter()));
        Rows[2].Bump();
        Observer.Observe('elem1 after bump2', Format(Rows[1].GetCounter()));
        Observer.Observe('elem2 after bump2', Format(Rows[2].GetCounter()));
        Plain := Rows[1];
        Observer.Observe('plain from elem', Format(Plain.GetCounter()));
        Plain.Bump();
        Rows[1] := Plain;
        Observer.Observe('elem1 from plain', Format(Rows[1].GetCounter()));
        Observer.Expect('elem1', '2');
        Observer.Expect('elem2', '0');
        Observer.Expect('elem2 after assign', '0');
        Observer.Expect('elem1 after bump2', '2');
        Observer.Expect('elem2 after bump2', '1');
        Observer.Expect('plain from elem', '0');
        Observer.Expect('elem1 from plain', '2');
        Observer.Verify();
    end;

    [Test]
    procedure TableGlobals_ArrayElement_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Rows: array[2] of Record "LT AR Row";
        Plain: Record "LT AR Row";
        RecRef: RecordRef;
    begin
        Rows[1].Bump();
        Rows[1].Bump();
        Plain.Bump();
        RecRef.GetTable(Rows[1]);
        RecRef.SetTable(Rows[2]);
        Observer.Observe('settable into elem2', Format(Rows[2].GetCounter()));
        RecRef.SetTable(Plain);
        Observer.Observe('settable into plain', Format(Plain.GetCounter()));
        RecRef.GetTable(Plain);
        RecRef.SetTable(Rows[1]);
        Observer.Observe('settable into elem1', Format(Rows[1].GetCounter()));
        Observer.Expect('settable into elem2', '0');
        Observer.Expect('settable into plain', '1');
        Observer.Expect('settable into elem1', '2');
        Observer.Verify();
    end;

    // ---- item 12: Format(Record) with FlowFilter fields before and after FlowFields ----

    [Test]
    procedure Format_FlowFilterPositions()
    var
        Observer: Codeunit "Probe Observer";
        F: Record "LT AR Fmt";
        L: Record "LT AR Fmt Line";
    begin
        F.DeleteAll();
        L.DeleteAll();
        F.Id := 1;
        F.Name := 'n';
        F.Insert();
        L.Id := 1;
        L.Owner := 1;
        L.Qty := 4;
        L.Insert();
        L.Id := 2;
        L.Owner := 1;
        L.Qty := 3;
        L.Insert();
        F.Get(1);
        F.FltA := 11;
        F.FltB := 22;
        Observer.Observe('assigned', Format(F));
        F.CalcFields(Cnt, Total);
        Observer.Observe('calc', Format(F));
        F.SetRange(FltA, 5);
        Observer.Observe('filtered', Format(F));
        Observer.Expect('assigned', '1\tn\t11\t22\t0\t0');
        Observer.Expect('calc', '1\tn\t11\t22\t2\t7');
        Observer.Expect('filtered', '1\tn\t11\t22\t2\t7');
        Observer.Verify();
    end;

    // ---- item 14: a Variant holding a filtered, found RecordRef, assigned to a Record or passed to a Record parameter ----

    local procedure Describe(R: Record "LT AR Row"): Text
    begin
        exit(Format(R.Id) + '|' + R.Name + '|' + R.GetFilters() + '|' + Format(R.Count()));
    end;

    [Test]
    procedure VariantRecordRef_AssignedToRecord()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT AR Row";
        Check: Record "LT AR Row";
    begin
        Seed();
        RR.Open(Database::"LT AR Row");
        RR.Field(1).SetRange(2, 3);
        RR.FindFirst();
        V := RR;
        Row := V;
        Observer.Observe('row', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('filters', Row.GetFilters());
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('next', Format(Row.Next()));
        Observer.Observe('after next', Format(Row.Id));
        Row.Name := 'm';
        Row.Modify();
        Check.Get(Row.Id);
        Observer.Observe('stored', Format(Check.Id) + '|' + Check.Name);
        Observer.Expect('row', '2|r2');
        Observer.Expect('filters', '');
        Observer.Expect('count', '4');
        Observer.Expect('next', '1');
        Observer.Expect('after next', '3');
        Observer.Expect('stored', '3|m');
        Observer.Verify();
    end;

    [Test]
    procedure VariantRecordRef_PassedToRecordParameter()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        RR.Open(Database::"LT AR Row");
        RR.Field(1).SetRange(2, 3);
        RR.FindLast();
        V := RR;
        Observer.Observe('param', Describe(V));
        Observer.Expect('param', '3|r3||4');
        Observer.Verify();
    end;

    // Writer SG (al-runtime-rs assumption recordref-into-record): the same with a RecordRef of another table, a RecordRef that is not open,
    // a temporary RecordRef, and the key and view the Record gets.
    [TryFunction]
    local procedure TryAssignVariant(V: Variant; var Row: Record "LT AR Row")
    begin
        Row := V;
    end;

    [TryFunction]
    local procedure TryDescribeVariant(V: Variant; var R: Text)
    begin
        R := Describe(V);
    end;

    local procedure SeedOther()
    var
        Other: Record "LT AR Other";
    begin
        Other.DeleteAll();
        Other.Init();
        Other.Code := 'O1';
        Other.Insert();
    end;

    [Test]
    procedure SG_VariantRecordRef_OtherTable_AssignAndParameter()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT AR Row";
        R: Text;
    begin
        Seed();
        SeedOther();
        RR.Open(Database::"LT AR Other");
        RR.FindFirst();
        V := RR;
        Row.Get(2);
        Observer.Observe('assign_ok', Format(TryAssignVariant(V, Row)));
        Observer.ObserveError('assign');
        Observer.Observe('row_after', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('param_ok', Format(TryDescribeVariant(V, R)));
        Observer.ObserveError('param');
        Observer.Observe('param_r', R);
        Observer.Finish();
    end;

    [Test]
    procedure SG_VariantRecordRef_NotOpen_Assign()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT AR Row";
    begin
        Seed();
        V := RR;
        Row.Get(2);
        Observer.Observe('assign_ok', Format(TryAssignVariant(V, Row)));
        Observer.ObserveError('assign');
        Observer.Observe('row_after', Format(Row.Id) + '|' + Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure SG_VariantRecordRef_KeyViewAndUnsavedValue()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT AR Row";
    begin
        Seed();
        RR.Open(Database::"LT AR Row");
        RR.SetView('SORTING(Id) ORDER(Descending) WHERE(Id=FILTER(1..3))');
        RR.FindFirst();
        RR.Field(2).Value := 'unsaved';
        V := RR;
        Row := V;
        Observer.Observe('row', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('view', Row.GetView(false));
        Observer.Observe('ascending', Format(Row.Ascending()));
        Observer.Observe('next', Format(Row.Next()) + '|' + Format(Row.Id));
        Observer.Observe('rr_name', Format(RR.Field(2).Value));
        Observer.Finish();
    end;

    [Test]
    procedure SG_VariantRecordRef_Temporary_Assign()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT AR Row";
        Check: Record "LT AR Row";
    begin
        Seed();
        RR.Open(Database::"LT AR Row", true);
        RR.Field(1).Value := 77;
        RR.Field(2).Value := 'temp';
        RR.Insert();
        V := RR;
        Row := V;
        Observer.Observe('row', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('istemp', Format(Row.IsTemporary()));
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('db_has_77', Format(Check.Get(77)));
        Observer.Finish();
    end;
}
