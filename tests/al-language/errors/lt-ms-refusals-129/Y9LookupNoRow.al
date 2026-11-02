// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 91477, pages 91475 and 91478, test codeunit 91476
// Writer Y9 (NP lane 1030e, 2026-10-30). Probe: TestPage OK() in the ModalPageHandler of a lookup page that shows no row: Page.RunModal(Id, Rec) on an empty
//   table (Rec cleared or holding values, list editable or Editable = false), on a table with rows and Rec filtered to no row, and a Page variable in
//   LookupMode on an empty table: whether OK is found, the Action returned and the record afterwards. The same call on a table with rows is the reference.
//   Related pins: errors/lt-ms-refusals-129/P129PageMisc.al (Page variable RunModal on an empty table, lookup filtered by SetTableView).
// BC versions: 27, 28, 29

table 91477 "LT Y9 LK Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 91478 "LT Y9 LK List"
{
    PageType = List;
    SourceTable = "LT Y9 LK Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

// The same list with Editable = false (a read-only lookup list).
page 91475 "LT Y9 LK List RO"
{
    PageType = List;
    SourceTable = "LT Y9 LK Item";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 91476 "LT Y9 Lookup No Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Text;

    local procedure TakeLog() Result: Text
    begin
        Result := Log;
        Log := '';
    end;

    local procedure Y9Seed()
    var
        Item: Record "LT Y9 LK Item";
    begin
        Item.DeleteAll();
        Item.Id := 1;
        Item.Grp := 'A';
        Item.Qty := 5;
        Item.Insert();
        Item.Id := 2;
        Item.Grp := 'B';
        Item.Insert();
        Commit();
        TakeLog();
    end;

    // TestPage OK() in the ModalPageHandler of a lookup page that shows no row. The RunModal call runs inside
    // asserterror and ends with an error of its own, so both outcomes (OK found or not) are recorded: the error text, the Action and the record afterwards.

    [ModalPageHandler]
    procedure Y9OkHandler(var P: TestPage "LT Y9 LK List")
    begin
        Log += 'first=' + Format(P.First()) + ';';
        P.OK().Invoke();
        Log += 'ok invoked' + ';';
    end;

    [ModalPageHandler]
    procedure Y9OkRoHandler(var P: TestPage "LT Y9 LK List RO")
    begin
        Log += 'first=' + Format(P.First()) + ';';
        P.OK().Invoke();
        Log += 'ok invoked' + ';';
    end;

    local procedure Y9RecText(Row: Record "LT Y9 LK Item"): Text
    begin
        exit('id=' + Format(Row.Id) + '|grp=' + Row.Grp + '|qty=' + Format(Row.Qty) + '|filters=' + Row.GetFilters());
    end;

    local procedure Y9Empty()
    var
        Item: Record "LT Y9 LK Item";
    begin
        Item.DeleteAll();
        Commit();
        TakeLog();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_EmptyTable_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y9 LK Item";
        Result: Action;
    begin
        Y9Empty();
        asserterror begin
            Result := Page.RunModal(Page::"LT Y9 LK List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', TakeLog());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Expect('runmodal|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('runmodal|code', 'TestActionNotFound');
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'first=No;');
        Observer.Expect('record', 'id=0|grp=|qty=0|filters=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_EmptyTable_PrefilledRec_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y9 LK Item";
        Result: Action;
    begin
        Y9Empty();
        Row.Id := 5;
        Row.Grp := 'Q';
        Row.Qty := 9;
        asserterror begin
            Result := Page.RunModal(Page::"LT Y9 LK List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', TakeLog());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Expect('runmodal|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('runmodal|code', 'TestActionNotFound');
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'first=No;');
        Observer.Expect('record', 'id=5|grp=Q|qty=9|filters=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Y9OkRoHandler')]
    procedure Y9_Lookup_RunModalIdRec_EmptyTable_ReadOnlyList_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y9 LK Item";
        Result: Action;
    begin
        Y9Empty();
        asserterror begin
            Result := Page.RunModal(Page::"LT Y9 LK List RO", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', TakeLog());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Expect('runmodal|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('runmodal|code', 'TestActionNotFound');
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'first=No;');
        Observer.Expect('record', 'id=0|grp=|qty=0|filters=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_FilteredToNoRow_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y9 LK Item";
        Result: Action;
    begin
        Y9Seed();
        Row.SetRange(Grp, 'NONE');
        asserterror begin
            Result := Page.RunModal(Page::"LT Y9 LK List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', TakeLog());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Expect('runmodal|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('runmodal|code', 'TestActionNotFound');
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'first=No;');
        Observer.Expect('record', 'id=0|grp=|qty=0|filters=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_PageVarLookupMode_EmptyTable_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Pg: Page "LT Y9 LK List";
        Row: Record "LT Y9 LK Item";
        Result: Action;
    begin
        Y9Empty();
        Pg.LookupMode(true);
        asserterror begin
            Result := Pg.RunModal();
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', TakeLog());
        Row.Id := 5;
        Pg.GetRecord(Row);
        Observer.Observe('getrecord', Y9RecText(Row));
        Observer.Expect('runmodal|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('runmodal|code', 'TestActionNotFound');
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'first=No;');
        Observer.Expect('getrecord', 'id=0|grp=|qty=0|filters=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Y9OkHandler')]
    procedure Y9_Lookup_RunModalIdRec_WithRows_Ok()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y9 LK Item";
        Result: Action;
    begin
        // reference: the same call on a table that has rows (the handler's OK takes the first row)
        Y9Seed();
        asserterror begin
            Result := Page.RunModal(Page::"LT Y9 LK List", Row);
            Error('returned');
        end;
        Observer.ObserveError('runmodal');
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', TakeLog());
        Observer.Observe('record', Y9RecText(Row));
        Observer.Expect('runmodal|text', 'returned');
        Observer.Expect('runmodal|code', 'Dialog');
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('handler', 'first=Yes;ok invoked;');
        Observer.Expect('record', 'id=1|grp=A|qty=5|filters=');
        Observer.Verify();
    end;
}
