// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-copy-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73926, codeunit 73927
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "RecordRef.Copy(FromRecordRef [, ShareTable]) and Copy(var FromRecord [, ShareTable])" (Media.ImportFile, MediaSet.ImportFile, RecordRef.Copy, ClientType::Teams)
// Facts: RecordRef.Copy from a RecordRef and from a Record that carry a filter, a current key and a table view, then Count, GetFilters, CurrentKeyIndex, GetView and the field values;
//   with ShareTable true and false and a change through the copy (value, filter, Insert)
// BC versions: 29 (27 and 28 by CI)

table 73926 "LT PnF RC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Id) { }
    }
}

codeunit 73927 "LT PnF RecRef Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnF RC Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 6 do begin
            Row.Id := i;
            Row.Grp := 10 - i;
            Row.Name := 'n' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure State(Name: Text; var RecRef: RecordRef; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '|count', Format(RecRef.Count()));
        Observer.Observe(Name + '|filters', RecRef.GetFilters());
        Observer.Observe(Name + '|key', Format(RecRef.CurrentKeyIndex()));
        Observer.Observe(Name + '|view', RecRef.GetView());
        Observer.Observe(Name + '|has_filter', Format(RecRef.HasFilter()));
        if RecRef.FindFirst() then
            Observer.Observe(Name + '|first_id', Format(RecRef.Field(1).Value()))
        else
            Observer.Observe(Name + '|first_id', 'none');
    end;

    [Test]
    procedure Copy_FromRecordRef_Filters()
    var
        Observer: Codeunit "Probe Observer";
        Src: RecordRef;
        Dst: RecordRef;
    begin
        Seed();
        Src.Open(Database::"LT PnF RC Row");
        Src.Field(1).SetRange(2, 5);
        Src.CurrentKeyIndex(2);
        Dst.Open(Database::"LT PnF RC Row");
        Dst.Copy(Src);
        State('source', Src, Observer);
        State('copy', Dst, Observer);
        Observer.Expect('source|count', '4');
        Observer.Expect('source|filters', 'Id: 2..5');
        Observer.Expect('source|key', '2');
        Observer.Expect('source|view', 'VERSION(1) SORTING(Grp,Id) WHERE(Id=FILTER(2..5))');
        Observer.Expect('source|has_filter', 'Yes');
        Observer.Expect('source|first_id', '5');
        Observer.Expect('copy|count', '4');
        Observer.Expect('copy|filters', 'Id: 2..5');
        Observer.Expect('copy|key', '2');
        Observer.Expect('copy|view', 'VERSION(1) SORTING(Grp,Id) WHERE(Id=FILTER(2..5))');
        Observer.Expect('copy|has_filter', 'Yes');
        Observer.Expect('copy|first_id', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_FromRecordRef_Values()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF RC Row";
        Src: RecordRef;
        Dst: RecordRef;
    begin
        Seed();
        Row.Get(3);
        Src.GetTable(Row);
        Dst.Open(Database::"LT PnF RC Row");
        Dst.Copy(Src);
        Observer.Observe('copy_is_temporary', Format(Dst.IsTemporary()));
        Observer.Observe('copy_id', Format(Dst.Field(1).Value()));
        Observer.Observe('copy_name', Format(Dst.Field(3).Value()));
        Observer.Observe('copy_number', Format(Dst.Number()));
        Observer.Observe('copy_count', Format(Dst.Count()));
        Observer.Expect('copy_is_temporary', 'No');
        Observer.Expect('copy_id', '3');
        Observer.Expect('copy_name', 'n3');
        Observer.Expect('copy_number', '73926');
        Observer.Expect('copy_count', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_FromRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF RC Row";
        Dst: RecordRef;
    begin
        Seed();
        Row.SetRange(Grp, 6, 8);
        Row.SetCurrentKey(Grp, Id);
        Dst.Open(Database::"LT PnF RC Row");
        Dst.Copy(Row);
        State('copy', Dst, Observer);
        Observer.Expect('copy|count', '3');
        Observer.Expect('copy|filters', 'Grp: 6..8');
        Observer.Expect('copy|key', '2');
        Observer.Expect('copy|view', 'VERSION(1) SORTING(Grp,Id) WHERE(Grp=FILTER(6..8))');
        Observer.Expect('copy|has_filter', 'Yes');
        Observer.Expect('copy|first_id', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_FromRecord_WithView()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF RC Row";
        Dst: RecordRef;
    begin
        Seed();
        Row.SetView('SORTING(Grp) ORDER(Descending) WHERE(Id=FILTER(2..4))');
        Dst.Open(Database::"LT PnF RC Row");
        Dst.Copy(Row);
        State('copy', Dst, Observer);
        Observer.Expect('copy|count', '3');
        Observer.Expect('copy|filters', 'Id: 2..4');
        Observer.Expect('copy|key', '2');
        Observer.Expect('copy|view', 'VERSION(1) SORTING(Grp,Id) ORDER(Descending) WHERE(Id=FILTER(2..4))');
        Observer.Expect('copy|has_filter', 'Yes');
        Observer.Expect('copy|first_id', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_ShareTable_False_ChangeThroughCopy()
    var
        Observer: Codeunit "Probe Observer";
        Src: RecordRef;
        Dst: RecordRef;
    begin
        Seed();
        Src.Open(Database::"LT PnF RC Row");
        Src.Field(1).SetRange(1, 3);
        Src.FindFirst();
        Dst.Open(Database::"LT PnF RC Row");
        Dst.Copy(Src, false);
        Dst.Field(1).SetRange(2, 2);
        Observer.Observe('src_filters', Src.GetFilters());
        Observer.Observe('dst_filters', Dst.GetFilters());
        Observer.Observe('src_id', Format(Src.Field(1).Value()));
        Observer.Observe('dst_id', Format(Dst.Field(1).Value()));
        Dst.Field(3).Value := 'changed';
        Observer.Observe('src_name_after_dst_change', Format(Src.Field(3).Value()));
        Observer.Expect('src_filters', 'Id: 1..3');
        Observer.Expect('dst_filters', 'Id: 2');
        Observer.Expect('src_id', '1');
        Observer.Expect('dst_id', '1');
        Observer.Expect('src_name_after_dst_change', 'n1');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_ShareTable_True_ChangeThroughCopy()
    var
        Observer: Codeunit "Probe Observer";
        Src: RecordRef;
        Dst: RecordRef;
    begin
        Seed();
        Src.Open(Database::"LT PnF RC Row");
        Src.Field(1).SetRange(1, 3);
        Src.FindFirst();
        Dst.Open(Database::"LT PnF RC Row");
        asserterror Dst.Copy(Src, true);
        Observer.ObserveError('af165');
        Dst.Field(1).SetRange(2, 2);
        Observer.Observe('src_filters', Src.GetFilters());
        Observer.Observe('dst_filters', Dst.GetFilters());
        Observer.Observe('src_id', Format(Src.Field(1).Value()));
        Observer.Observe('dst_id', Format(Dst.Field(1).Value()));
        Dst.Field(3).Value := 'changed';
        Observer.Observe('src_name_after_dst_change', Format(Src.Field(3).Value()));
        Observer.Expect('af165|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('af165|code', 'Argument');
        Observer.Expect('src_filters', 'Id: 1..3');
        Observer.Expect('dst_filters', 'Id: 2');
        Observer.Expect('src_id', '1');
        Observer.Expect('dst_id', '0');
        Observer.Expect('src_name_after_dst_change', 'n1');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_ShareTable_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "LT PnF RC Row" temporary;
        Src: RecordRef;
        Dst: RecordRef;
    begin
        Seed();
        TempRow.Id := 100;
        TempRow.Name := 'temp';
        TempRow.Insert();
        Src.GetTable(TempRow);
        Dst.Open(Database::"LT PnF RC Row");
        asserterror Dst.Copy(Src, true);
        Observer.ObserveError('af191');
        Observer.Expect('af191|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('af191|code', 'Argument');
        Observer.Verify();
    end;
}
