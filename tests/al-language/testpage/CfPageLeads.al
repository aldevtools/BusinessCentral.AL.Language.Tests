// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 84420-84435 (CfPageObjects.al), test codeunit 84439
// Probe: written against BC on CI; every literal asserted below is what BC produced. Corpus issue 667 items 81, 85, 86, 88, 89, 90.
// Facts:
//   81: an API page whose OnInsertRecord runs Rec.Insert(true) and answers false (or true): TestPage OpenNew is refused (DB:ClientInsertDenied),
//       so the trigger never runs from a TestPage; the OData insert path the lead asks about needs a web-service client.
//   85: a card whose OnNewRecord runs Rec.Insert(true) when "No." is blank: when the row reaches the database with TestPage OpenNew.
//   86: a FlowFilter field as a list column (page and page extension) compiles; what the TestPage shows.
//   88: a FlowField (lookup) used in a TableRelation filter and calculated in OnAfterGetCurrRecord: its value on OpenEdit, GoToRecord and OpenNew,
//       what SetValue accepts and which filter the Lookup page gets.
//   89: TestPage SetValue on an editable FlowField (Sum): which triggers run and whether a row is written.
//   90: a FlowFilter set by assignment or Validate in code, and by SetValue on a card: whether CalcFields uses it.
// BC versions: 27, 28, 29 by CI

codeunit 84439 "LT CF Page Leads"
{
    Subtype = Test;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT CF P Log";
        LookupSeen: Text;

    local procedure ApiRows(): Text
    var
        Row: Record "LT CF P Api Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += StrSubstNo('[%1/%2]', Row.Id, Row.Name);
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure DocRows(): Text
    var
        Doc: Record "LT CF P Doc";
        Result: Text;
    begin
        if Doc.FindSet() then
            repeat
                Result += StrSubstNo('[%1/%2]', Doc."No.", Doc.Description);
            until Doc.Next() = 0;
        exit(Result);
    end;

    local procedure EntryRows(): Text
    var
        Entry: Record "LT CF P Entry";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                Result += StrSubstNo('[%1/%2/%3]', Entry."Entry No.", Entry."Code", Entry.Amount);
            until Entry.Next() = 0;
        exit(Result);
    end;

    local procedure SeedRow()
    var
        Row: Record "LT CF P Row";
        Entry: Record "LT CF P Entry";
    begin
        Row.DeleteAll();
        Entry.DeleteAll();
        Row."Code" := 'R1';
        Row.Val := 'first';
        Row.Insert();
        Entry."Entry No." := 1;
        Entry."Code" := 'R1';
        Entry."Posting Date" := DMY2Date(10, 1, 2024);
        Entry.Amount := 10;
        Entry.Insert();
        Entry."Entry No." := 2;
        Entry."Code" := 'R1';
        Entry."Posting Date" := DMY2Date(10, 2, 2024);
        Entry.Amount := 20;
        Entry.Insert();
        Log.Reset();
    end;

    local procedure SeedLines()
    var
        Hdr: Record "LT CF P Hdr";
        Line: Record "LT CF P Line";
        Item: Record "LT CF P Item";
    begin
        Hdr.DeleteAll();
        Line.DeleteAll();
        Item.DeleteAll();
        Hdr."No." := 'H1';
        Hdr.Vendor := 'V1';
        Hdr.Insert();
        Item."Code" := 'I1';
        Item.Vendor := 'V1';
        Item.Insert();
        Item."Code" := 'I2';
        Item.Vendor := 'V2';
        Item.Insert();
        Line."Doc No." := 'H1';
        Line."Line No." := 10000;
        Line.Insert();
    end;

    // ---------- item 81 ----------

    [TryFunction]
    local procedure TryApiFalseSet(var P: TestPage "LT CF P Api False"; Id: Integer; Name: Text)
    begin
        P.id.SetValue(Id);
        P.name.SetValue(Name);
    end;

    [TryFunction]
    local procedure TryApiFalseOpenNew(var P: TestPage "LT CF P Api False")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryApiFalseClose(var P: TestPage "LT CF P Api False")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryApiTrueSet(var P: TestPage "LT CF P Api True"; Id: Integer; Name: Text)
    begin
        P.id.SetValue(Id);
        P.name.SetValue(Name);
    end;

    [TryFunction]
    local procedure TryApiTrueOpenNew(var P: TestPage "LT CF P Api True")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryApiTrueClose(var P: TestPage "LT CF P Api True")
    begin
        P.Close();
    end;

    [Test]
    procedure ApiPage_OnInsertRecordInsertsAndReturnsFalse()
    var
        Row: Record "LT CF P Api Row";
        P: TestPage "LT CF P Api False";
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Observer.Observe('open new ok', Format(TryApiFalseOpenNew(P)));
        Observer.ObserveError('open new');
        Observer.Observe('after open log', Log.Text());
        Observer.Observe('after open rows', ApiRows());
        Observer.Observe('set ok', Format(TryApiFalseSet(P, 1, 'One')));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set rows', ApiRows());
        Observer.Observe('close ok', Format(TryApiFalseClose(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close rows', ApiRows());
        Observer.Expect('open new ok', 'No');
        Observer.Expect('open new|text', 'Sorry, the current permissions prevented the action. (Page 84423 LT CF P Api False Insert: AL Language Coverage Tests)');
        Observer.Expect('open new|code', 'DB:ClientInsertDenied');
        Observer.Expect('after open log', '');
        Observer.Expect('after open rows', '');
        Observer.Expect('set ok', 'No');
        Observer.Expect('set|text', 'The TestPage is not open.');
        Observer.Expect('set|code', 'TestPageNotOpened');
        Observer.Expect('after set log', '');
        Observer.Expect('after set rows', '');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Expect('after close log', '');
        Observer.Expect('after close rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure ApiPage_OnInsertRecordInsertsAndReturnsTrue()
    var
        Row: Record "LT CF P Api Row";
        P: TestPage "LT CF P Api True";
    begin
        Row.DeleteAll();
        Log.Reset();
        ClearLastError();
        Observer.Observe('open new ok', Format(TryApiTrueOpenNew(P)));
        Observer.ObserveError('open new');
        Observer.Observe('after open log', Log.Text());
        Observer.Observe('after open rows', ApiRows());
        Observer.Observe('set ok', Format(TryApiTrueSet(P, 2, 'Two')));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set rows', ApiRows());
        Observer.Observe('close ok', Format(TryApiTrueClose(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close rows', ApiRows());
        Observer.Expect('open new ok', 'No');
        Observer.Expect('open new|text', 'Sorry, the current permissions prevented the action. (Page 84424 LT CF P Api True Insert: AL Language Coverage Tests)');
        Observer.Expect('open new|code', 'DB:ClientInsertDenied');
        Observer.Expect('after open log', '');
        Observer.Expect('after open rows', '');
        Observer.Expect('set ok', 'No');
        Observer.Expect('set|text', 'The TestPage is not open.');
        Observer.Expect('set|code', 'TestPageNotOpened');
        Observer.Expect('after set log', '');
        Observer.Expect('after set rows', '');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close|text', 'The TestPage is not open.');
        Observer.Expect('close|code', 'TestPageNotOpened');
        Observer.Expect('after close log', '');
        Observer.Expect('after close rows', '');
        Observer.Verify();
    end;

    // ---------- item 85 ----------

    [TryFunction]
    local procedure TryOpenNewCard(var P: TestPage "LT CF P New Card")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TrySetDescription(var P: TestPage "LT CF P New Card"; Value: Text)
    begin
        P.Description.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryCloseNewCard(var P: TestPage "LT CF P New Card")
    begin
        P.Close();
    end;

    [Test]
    procedure Card_OnNewRecordInserts_OpenNewSetClose()
    var
        Doc: Record "LT CF P Doc";
        P: TestPage "LT CF P New Card";
    begin
        Doc.DeleteAll();
        Log.Reset();
        ClearLastError();
        Observer.Observe('open ok', Format(TryOpenNewCard(P)));
        Observer.ObserveError('open');
        Observer.Observe('after open log', Log.Text());
        Observer.Observe('after open rows', DocRows());
        Observer.Observe('after open no', P."No.".Value());
        Observer.Observe('set ok', Format(TrySetDescription(P, 'Hello')));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set rows', DocRows());
        Observer.Observe('close ok', Format(TryCloseNewCard(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close rows', DocRows());
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('after open log', 'OnNewRecord,Doc.OnInsert:DOC1');
        Observer.Expect('after open rows', '[DOC1/]');
        Observer.Expect('after open no', 'DOC1');
        Observer.Expect('set ok', 'No');
        Observer.Expect('set|text', 'Validation error for Field: Description,  Message = ''This field cannot be validated since the key fields are not valid.''');
        Observer.Expect('set|code', 'TestValidation');
        Observer.Expect('after set log', 'OnNewRecord,Doc.OnInsert:DOC1,OnInsertRecord:DOC1,Doc.OnInsert:DOC1');
        Observer.Expect('after set rows', '[DOC1/]');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('after close log', 'OnNewRecord,Doc.OnInsert:DOC1,OnInsertRecord:DOC1,Doc.OnInsert:DOC1');
        Observer.Expect('after close rows', '[DOC1/]');
        Observer.Verify();
    end;

    // ---------- item 86 ----------

    [Test]
    procedure List_FlowFilterColumn_PageAndExtension()
    var
        Row: Record "LT CF P Row";
        P: TestPage "LT CF P FlowFilter List";
    begin
        SeedRow();
        P.OpenView();
        Observer.Observe('first', Format(P.First()));
        Observer.Observe('code', P."Code".Value());
        Observer.Observe('date filter', P.DateFilter.Value());
        Observer.Observe('ext date filter', P.ExtDateFilter.Value());
        Observer.Observe('amount', P.Amount.Value());
        Observer.Observe('date filter editable', Format(P.DateFilter.Editable()));
        Observer.Observe('date filter visible', Format(P.DateFilter.Visible()));
        P.Close();
        Row.SetRange("Date Filter", DMY2Date(10, 1, 2024));
        P.Trap();
        Page.Run(Page::"LT CF P FlowFilter List", Row);
        Observer.Observe('filtered first', Format(P.First()));
        Observer.Observe('filtered date filter', P.DateFilter.Value());
        Observer.Observe('filtered ext date filter', P.ExtDateFilter.Value());
        Observer.Observe('filtered amount', P.Amount.Value());
        Observer.Observe('filtered page filter', P.Filter.GetFilter("Date Filter"));
        P.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('code', 'R1');
        Observer.Expect('date filter', '');
        Observer.Expect('ext date filter', '');
        Observer.Expect('amount', '30.00');
        Observer.Expect('date filter editable', 'No');
        Observer.Expect('date filter visible', 'Yes');
        Observer.Expect('filtered first', 'Yes');
        Observer.Expect('filtered date filter', '');
        Observer.Expect('filtered ext date filter', '');
        Observer.Expect('filtered amount', '10.00');
        Observer.Expect('filtered page filter', '01/10/24');
        Observer.Verify();
    end;

    // ---------- item 88 ----------

    [TryFunction]
    local procedure TrySetItem(var P: TestPage "LT CF P Line Card"; Value: Text)
    begin
        P.Item.SetValue(Value);
    end;

    [Test]
    procedure FlowFieldRelation_OpenEditGoToRecord()
    var
        Line: Record "LT CF P Line";
        P: TestPage "LT CF P Line Card";
    begin
        SeedLines();
        ClearLastError();
        P.OpenEdit();
        Observer.Observe('open doc', P."Doc No.".Value());
        Observer.Observe('open vendor', P.HdrVendor.Value());
        Line.Get('H1', 10000);
        P.GoToRecord(Line);
        Observer.Observe('goto vendor', P.HdrVendor.Value());
        Observer.Observe('set other vendor item ok', Format(TrySetItem(P, 'I2')));
        Observer.ObserveError('set other vendor item');
        Observer.Observe('set same vendor item ok', Format(TrySetItem(P, 'I1')));
        Observer.ObserveError('set same vendor item');
        Observer.Observe('item value', P.Item.Value());
        P.Close();
        Line.Get('H1', 10000);
        Observer.Observe('db item', Line.Item);
        Observer.Expect('open doc', 'H1');
        Observer.Expect('open vendor', 'V1');
        Observer.Expect('goto vendor', 'V1');
        Observer.Expect('set other vendor item ok', 'No');
        Observer.Expect('set other vendor item|text', 'Validation error for Field: Item,  Message = ''The field Item of table LT CF P Line contains a value (I2) that cannot be found in the related table (LT CF P Item). (Select Refresh to discard errors)''');
        Observer.Expect('set other vendor item|code', 'TestValidation');
        Observer.Expect('set same vendor item ok', 'Yes');
        Observer.Expect('set same vendor item|text', '');
        Observer.Expect('set same vendor item|code', '');
        Observer.Expect('item value', 'I1');
        Observer.Expect('db item', 'I1');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFieldRelation_OpenNew()
    var
        Line: Record "LT CF P Line";
        P: TestPage "LT CF P Line Card";
    begin
        SeedLines();
        ClearLastError();
        P.OpenNew();
        Observer.Observe('new vendor', P.HdrVendor.Value());
        P."Doc No.".SetValue('H1');
        P."Line No.".SetValue(20000);
        Observer.Observe('after key vendor', P.HdrVendor.Value());
        Observer.Observe('set other vendor item ok', Format(TrySetItem(P, 'I2')));
        Observer.ObserveError('set other vendor item');
        Observer.Observe('set same vendor item ok', Format(TrySetItem(P, 'I1')));
        Observer.ObserveError('set same vendor item');
        Observer.Observe('item value', P.Item.Value());
        P.Close();
        Observer.Observe('db exists', Format(Line.Get('H1', 20000)));
        Observer.Observe('db item', Line.Item);
        Observer.Expect('new vendor', '');
        Observer.Expect('after key vendor', '');
        Observer.Expect('set other vendor item ok', 'No');
        Observer.Expect('set other vendor item|text', 'Validation error for Field: Item,  Message = ''The field Item of table LT CF P Line contains a value (I2) that cannot be found in the related table (LT CF P Item). (Select Refresh to discard errors)''');
        Observer.Expect('set other vendor item|code', 'TestValidation');
        Observer.Expect('set same vendor item ok', 'Yes');
        Observer.Expect('set same vendor item|text', '');
        Observer.Expect('set same vendor item|code', '');
        Observer.Expect('item value', 'I1');
        Observer.Expect('db exists', 'Yes');
        Observer.Expect('db item', 'I1');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure ItemLookupHandler(var L: TestPage "LT CF P Item List")
    var
        Codes: Text;
    begin
        if L.First() then
            repeat
                Codes += '[' + L."Code".Value() + ']';
            until not L.Next();
        LookupSeen := StrSubstNo('filter=%1 rows=%2', L.Filter.GetFilter(Vendor), Codes);
        L.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ItemLookupHandler')]
    procedure FlowFieldRelation_LookupFilter()
    var
        Line: Record "LT CF P Line";
        P: TestPage "LT CF P Line Card";
    begin
        SeedLines();
        LookupSeen := '';
        P.OpenEdit();
        Line.Get('H1', 10000);
        P.GoToRecord(Line);
        P.Item.Lookup();
        Observer.Observe('lookup', LookupSeen);
        P.Close();
        Observer.Expect('lookup', 'filter=V1 rows=[I1]');
        Observer.Verify();
    end;

    // ---------- item 89 ----------

    [TryFunction]
    local procedure TrySetAmount(var P: TestPage "LT CF P Row Card"; Value: Decimal)
    begin
        P.Amount.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryCloseRowCard(var P: TestPage "LT CF P Row Card")
    begin
        P.Close();
    end;

    [Test]
    procedure EditableFlowField_SetValue()
    var
        Row: Record "LT CF P Row";
        P: TestPage "LT CF P Row Card";
    begin
        SeedRow();
        ClearLastError();
        P.OpenEdit();
        Row.Get('R1');
        P.GoToRecord(Row);
        Observer.Observe('amount', P.Amount.Value());
        Observer.Observe('amount editable', Format(P.Amount.Editable()));
        Log.Reset();
        Observer.Observe('set ok', Format(TrySetAmount(P, 50)));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set amount', P.Amount.Value());
        Observer.Observe('after set entries', EntryRows());
        Observer.Observe('close ok', Format(TryCloseRowCard(P)));
        Observer.ObserveError('close');
        Observer.Observe('after close log', Log.Text());
        Observer.Observe('after close entries', EntryRows());
        Row.Get('R1');
        Row.CalcFields(Amount);
        Observer.Observe('db amount', Format(Row.Amount));
        Observer.Expect('amount', '30.00');
        Observer.Expect('amount editable', 'Yes');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('after set log', 'Amount.OnValidate:50/30,Entry.OnInsert');
        Observer.Expect('after set amount', '50.00');
        Observer.Expect('after set entries', '[1/R1/10][2/R1/20][3/R1/20]');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('after close log', 'Amount.OnValidate:50/30,Entry.OnInsert,OnModifyRecord,Row.OnModify');
        Observer.Expect('after close entries', '[1/R1/10][2/R1/20][3/R1/20]');
        Observer.Expect('db amount', '50');
        Observer.Verify();
    end;

    // ---------- item 90 ----------

    [Test]
    procedure FlowFilter_AssignValidateSetRange_InCode()
    var
        Row: Record "LT CF P Row";
    begin
        SeedRow();
        Row.Get('R1');
        Row.CalcFields(Amount);
        Observer.Observe('no filter amount', Format(Row.Amount));
        Row."Date Filter" := DMY2Date(10, 1, 2024);
        Observer.Observe('assigned value', Format(Row."Date Filter", 0, 9));
        Observer.Observe('assigned getfilter', Row.GetFilter("Date Filter"));
        Row.CalcFields(Amount);
        Observer.Observe('assigned amount', Format(Row.Amount));
        Clear(Row);
        Row.Get('R1');
        Log.Reset();
        Row.Validate("Date Filter", DMY2Date(10, 2, 2024));
        Observer.Observe('validated log', Log.Text());
        Observer.Observe('validated value', Format(Row."Date Filter", 0, 9));
        Observer.Observe('validated getfilter', Row.GetFilter("Date Filter"));
        Row.CalcFields(Amount);
        Observer.Observe('validated amount', Format(Row.Amount));
        Clear(Row);
        Row.Get('R1');
        Row.SetRange("Date Filter", DMY2Date(10, 2, 2024));
        Observer.Observe('setrange value', Format(Row."Date Filter", 0, 9));
        Row.CalcFields(Amount);
        Observer.Observe('setrange amount', Format(Row.Amount));
        Observer.Expect('no filter amount', '30');
        Observer.Expect('assigned value', '2024-01-10');
        Observer.Expect('assigned getfilter', '');
        Observer.Expect('assigned amount', '30');
        Observer.Expect('validated log', 'DateFilter.OnValidate');
        Observer.Expect('validated value', '2024-02-10');
        Observer.Expect('validated getfilter', '');
        Observer.Expect('validated amount', '30');
        Observer.Expect('setrange value', '');
        Observer.Expect('setrange amount', '20');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetDateFilter(var P: TestPage "LT CF P Row Card"; Value: Date)
    begin
        P.DateFilter.SetValue(Value);
    end;

    [Test]
    procedure FlowFilter_SetValueOnCard()
    var
        Row: Record "LT CF P Row";
        P: TestPage "LT CF P Row Card";
    begin
        SeedRow();
        ClearLastError();
        P.OpenEdit();
        Row.Get('R1');
        P.GoToRecord(Row);
        Observer.Observe('amount', P.Amount.Value());
        Observer.Observe('date filter editable', Format(P.DateFilter.Editable()));
        Log.Reset();
        Observer.Observe('set ok', Format(TrySetDateFilter(P, DMY2Date(10, 1, 2024))));
        Observer.ObserveError('set');
        Observer.Observe('after set log', Log.Text());
        Observer.Observe('after set date filter', P.DateFilter.Value());
        Observer.Observe('after set amount', P.Amount.Value());
        Observer.Observe('after set page filter', P.Filter.GetFilter("Date Filter"));
        P.Close();
        Observer.Expect('amount', '30.00');
        Observer.Expect('date filter editable', 'Yes');
        Observer.Expect('set ok', 'Yes');
        Observer.Expect('set|text', '');
        Observer.Expect('set|code', '');
        Observer.Expect('after set log', 'DateFilter.OnValidate');
        Observer.Expect('after set date filter', '1/10/2024');
        Observer.Expect('after set amount', '30.00');
        Observer.Expect('after set page filter', '');
        Observer.Verify();
    end;
}
