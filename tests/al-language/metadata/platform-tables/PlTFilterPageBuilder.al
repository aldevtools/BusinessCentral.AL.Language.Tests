// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/filterpagebuilder/filterpagebuilder-data-type
// Scope: in-scope
// Fixtures used: table 74209 "LT PlT Row" (PlTRow.Table.al), self-contained codeunit 74212 (the handlers observe through the codeunit-level observer)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Members: FilterPageBuilder.AddTable, AddRecord, AddField, AddFieldNo, PageCaption, Count, Name, GetView, SetView, RunModal with a [FilterPageHandler].
// BC versions: 29 (27 and 28 by CI)

codeunit 74212 "LT PlT FilterPageBuilder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [FilterPageHandler]
    procedure AcceptAndObserve(var Rec: RecordRef): Boolean
    begin
        Observer.Observe('h_table_is_row', Format(Rec.Number() = Database::"LT PlT Row"));
        Observer.Observe('h_view', Rec.GetView());
        Observer.Observe('h_view_no_names', Rec.GetView(false));
        exit(true);
    end;

    [FilterPageHandler]
    procedure Cancel(var Rec: RecordRef): Boolean
    begin
        Rec.SetView('WHERE(No.=CONST(7))');
        exit(false);
    end;

    [FilterPageHandler]
    procedure SetFilters(var Rec: RecordRef): Boolean
    begin
        Rec.SetView('SORTING(No.) WHERE(No.=FILTER(2..5),Name=CONST(abc))');
        exit(true);
    end;

    [FilterPageHandler]
    procedure SetBadView(var Rec: RecordRef): Boolean
    begin
        Rec.SetView('WHERE(Nope=CONST(1))');
        exit(true);
    end;

    local procedure ScrubCaller(Value: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := StrPos(Value, ' from the object ');
        EndPos := StrPos(Value, '. An object with that ID');
        if (StartPos = 0) or (EndPos < StartPos) then
            exit(Value);
        exit(CopyStr(Value, 1, StartPos - 1) + ' from the object <caller>' + CopyStr(Value, EndPos));
    end;

    [Test]
    procedure AddTable_CountAndNames()
    var
        Fpb: FilterPageBuilder;
    begin
        Observer.Observe('empty_count', Format(Fpb.Count()));
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Observer.Observe('count_1', Format(Fpb.Count()));
        Observer.Observe('name_1', Fpb.Name(1));
        Fpb.AddTable('Second', Database::"LT PlT Row");
        Observer.Observe('count_2', Format(Fpb.Count()));
        Observer.Observe('name_2', Fpb.Name(2));
        Observer.Expect('empty_count', '0');
        Observer.Expect('count_1', '1');
        Observer.Expect('name_1', 'Rows');
        Observer.Expect('count_2', '2');
        Observer.Expect('name_2', 'Second');
        Observer.Verify();
    end;

    [Test]
    procedure AddTable_ReturnValueAndDefaults()
    var
        Fpb: FilterPageBuilder;
        Added: Text;
    begin
        Added := Fpb.AddTable('Rows', Database::"LT PlT Row");
        Observer.Observe('returned', Added);
        Observer.Observe('default_view', Fpb.GetView('Rows'));
        Observer.Observe('default_view_no_names', Fpb.GetView('Rows', false));
        Observer.Observe('caption_default', Fpb.PageCaption);
        Observer.Expect('returned', 'Rows');
        Observer.Expect('default_view', 'VERSION(1) SORTING(No.)');
        Observer.Expect('default_view_no_names', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('caption_default', 'Filter Page');
        Observer.Verify();
    end;

    [Test]
    procedure AddTable_Errors()
    var
        Fpb: FilterPageBuilder;
    begin
        asserterror Fpb.AddTable('Rows', 99999999);
        Observer.Observe('unknown_table|text', ScrubCaller(GetLastErrorText()));
        Observer.Observe('unknown_table|code', GetLastErrorCode());
        ClearLastError();
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Observer.Observe('duplicate_name', 'no error');
        Observer.Observe('count_after', Format(Fpb.Count()));
        Observer.Expect('unknown_table|text', 'You tried to invoke the Table object with the ID 99999999 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_table|code', 'AL:MetadataNotFound');
        Observer.Expect('duplicate_name', 'no error');
        Observer.Expect('count_after', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Name_IndexErrors()
    var
        Fpb: FilterPageBuilder;
    begin
        asserterror Observer.Observe('empty', Fpb.Name(1));
        Observer.ObserveError('empty_builder');
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        asserterror Observer.Observe('zero', Fpb.Name(0));
        Observer.ObserveError('zero');
        asserterror Observer.Observe('negative', Fpb.Name(-1));
        Observer.ObserveError('negative');
        asserterror Observer.Observe('past_end', Fpb.Name(2));
        Observer.ObserveError('past_end');
        Observer.Expect('empty_builder|text', 'The filter control index value 1 is out of range. The value must be greater than or equal to 1 and less than or equal to 0.');
        Observer.Expect('empty_builder|code', 'ArgumentOutOfRange');
        Observer.Expect('zero|text', 'The filter control index value 0 is out of range. The value must be greater than or equal to 1 and less than or equal to 1.');
        Observer.Expect('zero|code', 'ArgumentOutOfRange');
        Observer.Expect('negative|text', 'The filter control index value -1 is out of range. The value must be greater than or equal to 1 and less than or equal to 1.');
        Observer.Expect('negative|code', 'ArgumentOutOfRange');
        Observer.Expect('past_end|text', 'The filter control index value 2 is out of range. The value must be greater than or equal to 1 and less than or equal to 1.');
        Observer.Expect('past_end|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure PageCaption_SetAndRead()
    var
        Fpb: FilterPageBuilder;
    begin
        Fpb.PageCaption := 'My caption';
        Observer.Observe('set', Fpb.PageCaption);
        Fpb.PageCaption := '';
        Observer.Observe('empty', Fpb.PageCaption);
        Fpb.PageCaption := PadStr('', 300, 'c');
        Observer.Observe('long_len', Format(StrLen(Fpb.PageCaption)));
        Fpb.PageCaption := 'Gr' + 'ü' + 'ße';
        Observer.Observe('unicode', Fpb.PageCaption);
        Observer.Expect('set', 'My caption');
        Observer.Expect('empty', 'Filter Page');
        Observer.Expect('long_len', '300');
        Observer.Expect('unicode', 'Grüße');
        Observer.Verify();
    end;

    [Test]
    procedure GetSetView_RoundTrip()
    var
        Fpb: FilterPageBuilder;
    begin
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Fpb.SetView('Rows', 'WHERE(No.=FILTER(1..3))');
        Observer.Observe('names', Fpb.GetView('Rows'));
        Observer.Observe('no_names', Fpb.GetView('Rows', false));
        Fpb.SetView('Rows', 'SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>10),Code=CONST(A))');
        Observer.Observe('sorted', Fpb.GetView('Rows'));
        Observer.Observe('sorted_no_names', Fpb.GetView('Rows', false));
        asserterror Fpb.SetView('Rows', '');
        Observer.ObserveError('af153');
        Observer.Observe('cleared', Fpb.GetView('Rows'));
        Observer.Expect('names', 'VERSION(1) SORTING(No.) WHERE(No.=FILTER(1..3))');
        Observer.Expect('no_names', 'VERSION(1) SORTING(Field1) WHERE(Field1=1(1..3))');
        Observer.Expect('sorted', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>10),Code=FILTER(A))');
        Observer.Expect('sorted_no_names', 'VERSION(1) SORTING(Field2) ORDER(1) WHERE(Field3=1(>10),Field4=1(A))');
        Observer.Expect('af153|text', 'The filter page view cannot be empty.');
        Observer.Expect('af153|code', 'Argument');
        Observer.Expect('cleared', 'VERSION(1) SORTING(Name) ORDER(Descending) WHERE(Amount=FILTER(>10),Code=FILTER(A))');
        Observer.Verify();
    end;

    [Test]
    procedure AddRecord_WithFilters()
    var
        Fpb: FilterPageBuilder;
        Row: Record "LT PlT Row";
    begin
        Row.SetFilter("No.", '2..5');
        Row.SetRange(Name, 'abc');
        Fpb.AddRecord('Rows', Row);
        Observer.Observe('count', Format(Fpb.Count()));
        Observer.Observe('view', Fpb.GetView('Rows'));
        Observer.Observe('view_no_names', Fpb.GetView('Rows', false));
        Observer.Expect('count', '1');
        Observer.Expect('view', 'VERSION(1) SORTING(No.) WHERE(No.=FILTER(2..5),Name=FILTER(abc))');
        Observer.Expect('view_no_names', 'VERSION(1) SORTING(Field1) WHERE(Field1=1(2..5),Field2=1(abc))');
        Observer.Verify();
    end;

    [Test]
    procedure AddRecord_NoFiltersAndSorting()
    var
        Fpb: FilterPageBuilder;
        Row: Record "LT PlT Row";
    begin
        Row.SetCurrentKey(Name);
        Row.Ascending(false);
        Fpb.AddRecord('Rows', Row);
        Observer.Observe('view_sorted', Fpb.GetView('Rows'));
        Observer.Expect('view_sorted', 'VERSION(1) SORTING(Name) ORDER(Descending)');
        Observer.Verify();
    end;

    [Test]
    procedure AddField_Variants()
    var
        Fpb: FilterPageBuilder;
        Row: Record "LT PlT Row";
    begin
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Fpb.AddField('Rows', Row."No.");
        Observer.Observe('add_field', 'no error');
        Fpb.AddField('Rows', Row.Name, 'abc');
        Observer.Observe('add_field_filter', 'no error');
        Observer.Observe('view_after', Fpb.GetView('Rows'));
        Fpb.AddField('Rows', Row.Amount, '>5');
        Observer.Observe('view_after_amount', Fpb.GetView('Rows'));
        Observer.Observe('count', Format(Fpb.Count()));
        Observer.Expect('add_field', 'no error');
        Observer.Expect('add_field_filter', 'no error');
        Observer.Expect('view_after', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(abc))');
        Observer.Expect('view_after_amount', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(abc),Amount=FILTER(>5))');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure AddFieldNo_Variants()
    var
        Fpb: FilterPageBuilder;
        Row: Record "LT PlT Row";
    begin
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Fpb.AddFieldNo('Rows', 1);
        Observer.Observe('add_field_no', 'no error');
        Fpb.AddFieldNo('Rows', 2, 'xyz');
        Observer.Observe('add_field_no_filter', 'no error');
        Observer.Observe('view_after', Fpb.GetView('Rows'));
        Fpb.AddFieldNo('Rows', 3, '1..9');
        Observer.Observe('view_after_amount', Fpb.GetView('Rows'));
        Observer.Expect('add_field_no', 'no error');
        Observer.Expect('add_field_no_filter', 'no error');
        Observer.Expect('view_after', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(xyz))');
        Observer.Expect('view_after_amount', 'VERSION(1) SORTING(No.) WHERE(Name=FILTER(xyz),Amount=FILTER(1..9))');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptAndObserve')]
    procedure RunModal_Accept()
    var
        Fpb: FilterPageBuilder;
    begin
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Fpb.PageCaption := 'Pick rows';
        Observer.Observe('run', Format(Fpb.RunModal()));
        Observer.Expect('h_table_is_row', 'Yes');
        Observer.Expect('h_view', 'VERSION(1) SORTING(No.)');
        Observer.Expect('h_view_no_names', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('run', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Cancel')]
    procedure RunModal_CancelKeepsSetView()
    var
        Fpb: FilterPageBuilder;
    begin
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Observer.Observe('run', Format(Fpb.RunModal()));
        Observer.Observe('view_after_cancel', Fpb.GetView('Rows'));
        Observer.Expect('run', 'No');
        Observer.Expect('view_after_cancel', 'VERSION(1) SORTING(No.) WHERE(No.=FILTER(7))');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetFilters')]
    procedure RunModal_HandlerSetsView()
    var
        Fpb: FilterPageBuilder;
        Row: Record "LT PlT Row";
    begin
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Observer.Observe('run', Format(Fpb.RunModal()));
        Observer.Observe('view', Fpb.GetView('Rows'));
        Row.SetView(Fpb.GetView('Rows'));
        Observer.Observe('applied_filter_no', Row.GetFilter("No."));
        Observer.Observe('applied_filter_name', Row.GetFilter(Name));
        Observer.Expect('run', 'Yes');
        Observer.Expect('view', 'VERSION(1) SORTING(No.) WHERE(No.=FILTER(2..5),Name=FILTER(abc))');
        Observer.Expect('applied_filter_no', '2..5');
        Observer.Expect('applied_filter_name', 'abc');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetBadView')]
    procedure RunModal_HandlerSetsBadView()
    var
        Fpb: FilterPageBuilder;
    begin
        Fpb.AddTable('Rows', Database::"LT PlT Row");
        Fpb.RunModal();
        Observer.Observe('bad_view', 'no error');
        Observer.Expect('bad_view', 'no error');
        Observer.Verify();
    end;
}
