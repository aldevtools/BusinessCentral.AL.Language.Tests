// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope (Cloud). ModalPageHandler with a TestPage.
// local object: the lookup list and the row the caller leaves the record on are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 63400, page 63401, test codeunit 63402
// Probe (al-runner issue 7453): Page.RunModal(Page::X, Rec) where the caller's record stands on a row other than the first of the view (the row
//   inserted last into a temporary record, a row read with Get), and the ModalPageHandler moves back with First() or Previous() before OK or
//   Cancel. The reading is the row the handler sees when it starts and after its move, the returned Action and the row Rec holds afterwards.
//   Already pinned: PageRunModalRecAfterClose.al (the record starts on the first row, the handler moves forward with Next, Last, GoToKey).
// BC versions: 27, 28, 29

table 63400 "PNL Modal Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 63401 "PNL Modal Rows"
{
    PageType = List;
    SourceTable = "PNL Modal Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 63402 "PNL Modal First Later Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mode: Text;

    local procedure Initialize()
    var
        Row: Record "PNL Modal Row";
    begin
        Row.DeleteAll();
        Observer.Discard();
        Mode := '';
    end;

    // Inserts A, B, C and does not read afterwards: the record is left on C, the row inserted last.
    local procedure Fill(var Row: Record "PNL Modal Row")
    begin
        Row.Init();
        Row."Code" := 'A';
        Row.Name := 'alpha';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'bravo';
        Row.Insert();
        Row."Code" := 'C';
        Row.Name := 'charlie';
        Row.Insert();
    end;

    local procedure ObserveRec(var Row: Record "PNL Modal Row"; Result: Action)
    begin
        Observer.Observe('action', Format(Result));
        Observer.Observe('rec', Row."Code" + '|' + Row.Name);
        Observer.Observe('rec count', Format(Row.Count()));
    end;

    [TryFunction]
    local procedure TryMove(var P: TestPage "PNL Modal Rows"; Step: Text; var Moved: Boolean)
    begin
        case Step of
            'FIRST':
                Moved := P.First();
            'PREVIOUS':
                Moved := P.Previous();
        end;
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Temp_LeftOnLastInserted_HandlerFirstThenOk()
    var
        Row: Record "PNL Modal Row" temporary;
        Result: Action;
    begin
        Initialize();
        Fill(Row);
        Mode := 'FIRST,OK';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'C');
        Observer.Expect('move', 'Yes');
        Observer.Expect('after move', 'A');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec', 'A|alpha');
        Observer.Expect('rec count', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Temp_LeftOnLastInserted_HandlerPreviousThenOk()
    var
        Row: Record "PNL Modal Row" temporary;
        Result: Action;
    begin
        Initialize();
        Fill(Row);
        Mode := 'PREVIOUS,OK';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'C');
        Observer.Expect('move', 'Yes');
        Observer.Expect('after move', 'B');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec', 'B|bravo');
        Observer.Expect('rec count', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Temp_LeftOnLastInserted_HandlerFirstThenCancel()
    var
        Row: Record "PNL Modal Row" temporary;
        Result: Action;
    begin
        Initialize();
        Fill(Row);
        Mode := 'FIRST,CANCEL';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'C');
        Observer.Expect('move', 'Yes');
        Observer.Expect('after move', 'A');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('rec', 'A|alpha');
        Observer.Expect('rec count', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Temp_LeftOnLastInserted_HandlerOkWithoutMoving()
    var
        Row: Record "PNL Modal Row" temporary;
        Result: Action;
    begin
        Initialize();
        Fill(Row);
        Mode := 'OK';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'C');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec', 'C|charlie');
        Observer.Expect('rec count', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Temp_GetMiddleRow_HandlerFirstThenOk()
    var
        Row: Record "PNL Modal Row" temporary;
        Result: Action;
    begin
        Initialize();
        Fill(Row);
        Row.Get('B');
        Mode := 'FIRST,OK';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'B');
        Observer.Expect('move', 'Yes');
        Observer.Expect('after move', 'A');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec', 'A|alpha');
        Observer.Expect('rec count', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Temp_TwoRows_LeftOnLastInserted_HandlerFirstThenOk()
    var
        Row: Record "PNL Modal Row" temporary;
        Result: Action;
    begin
        // The reporter's data: two rows, the record left on the second.
        Initialize();
        Row."Code" := 'A';
        Row.Name := 'alpha';
        Row.Insert();
        Row."Code" := 'B';
        Row.Name := 'bravo';
        Row.Insert();
        Mode := 'FIRST,OK';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'B');
        Observer.Expect('move', 'Yes');
        Observer.Expect('after move', 'A');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec', 'A|alpha');
        Observer.Expect('rec count', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Stored_LeftOnLastInserted_HandlerFirstThenOk()
    var
        Row: Record "PNL Modal Row";
        Result: Action;
    begin
        Initialize();
        Fill(Row);
        Mode := 'FIRST,OK';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'C');
        Observer.Expect('move', 'Yes');
        Observer.Expect('after move', 'A');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec', 'A|alpha');
        Observer.Expect('rec count', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RowsHandler')]
    procedure Stored_LeftOnLastInserted_HandlerPreviousThenOk()
    var
        Row: Record "PNL Modal Row";
        Result: Action;
    begin
        Initialize();
        Fill(Row);
        Mode := 'PREVIOUS,OK';
        Result := Page.RunModal(Page::"PNL Modal Rows", Row);
        ObserveRec(Row, Result);
        Observer.Expect('opened on', 'C');
        Observer.Expect('move', 'Yes');
        Observer.Expect('after move', 'B');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('rec', 'B|bravo');
        Observer.Expect('rec count', '3');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure RowsHandler(var Rows: TestPage "PNL Modal Rows")
    var
        Moved: Boolean;
        Step: Text;
    begin
        Observer.Observe('opened on', Rows."Code".Value());
        Step := Mode.Split(',').Get(1);
        if Step in ['FIRST', 'PREVIOUS'] then begin
            if TryMove(Rows, Step, Moved) then
                Observer.Observe('move', Format(Moved))
            else
                Observer.ObserveError('move error');
            Observer.Observe('after move', Rows."Code".Value());
        end;
        if Mode.EndsWith('CANCEL') then
            Rows.Cancel().Invoke()
        else
            Rows.OK().Invoke();
    end;
}
