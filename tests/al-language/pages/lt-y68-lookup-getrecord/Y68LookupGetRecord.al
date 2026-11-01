// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-getrecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93658, pages 93650-93652, codeunits 93663-93664.
// Probe (writer Y68, NP lane probe Q3 and one of Q6): Page.GetRecord after a lookup Page.RunModal that closes with no row selected, on a table that
//   has rows but whose view is filtered to none: a non-editable list, an editable list and a card, closed by a Page-typed handler (Response :=
//   LookupOK / LookupCancel) and by a TestPage-typed handler (OK / LookupOK without selecting a row); the Action returned, the record GetRecord
//   gives, whether OnOpenPage ran. And Page.RunModal(Id, Rec) of a lookup page after the selected row left the view (changed or deleted) while
//   the page was open. Already pinned nearby: misc/lt-y14-triage/Y14PageTriage.al (Page-typed handler over a temporary source, First() = No, OK
//   on no row = TestActionNotFound).
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 93658 "LT Y68 Pg Item"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT Y68 Pg List RO";

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Rank; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 93663 "LT Y68 Pg Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 93650 "LT Y68 Pg List RO"
{
    PageType = List;
    SourceTable = "LT Y68 Pg Item";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode(true);
        Log.Add('open RO');
    end;

    var
        Log: Codeunit "LT Y68 Pg Log";
}

page 93651 "LT Y68 Pg List Edit"
{
    PageType = List;
    SourceTable = "LT Y68 Pg Item";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode(true);
        Log.Add('open Edit');
    end;

    var
        Log: Codeunit "LT Y68 Pg Log";
}

page 93652 "LT Y68 Pg Card"
{
    PageType = Card;
    SourceTable = "LT Y68 Pg Item";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode(true);
        Log.Add('open Card');
    end;

    var
        Log: Codeunit "LT Y68 Pg Log";
}

codeunit 93664 "LT Y68 Pg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y68 Pg Log";
        Mode: Integer;

    local procedure Seed()
    var
        Item: Record "LT Y68 Pg Item";
    begin
        Item.DeleteAll();
        Item."No." := 'A';
        Item.Name := 'alpha';
        Item.Rank := 1;
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'beta';
        Item.Rank := 1;
        Item.Insert();
        Item."No." := 'C';
        Item.Name := 'gamma';
        Item.Rank := 2;
        Item.Insert();
        Commit();
        Log.Take();
        ClearLastError();
    end;

    local procedure Describe(Cur: Record "LT Y68 Pg Item"): Text
    begin
        exit('no=[' + Cur."No." + '] name=[' + Cur.Name + '] rank=' + Format(Cur.Rank) + ' found=' + Format(Cur.Find()) + ' count=' + Format(Cur.Count()));
    end;

    local procedure NoRowView(var Item: Record "LT Y68 Pg Item")
    begin
        Item.Reset();
        Item.SetRange("No.", 'ZZ');
    end;

    // Page-typed handler, RO list.
    [ModalPageHandler]
    procedure RoPageLookupOK(var P: Page "LT Y68 Pg List RO"; var Response: Action)
    begin
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure RoPageLookupCancel(var P: Page "LT Y68 Pg List RO"; var Response: Action)
    begin
        Response := Action::LookupCancel;
    end;

    [ModalPageHandler]
    procedure EditPageLookupOK(var P: Page "LT Y68 Pg List Edit"; var Response: Action)
    begin
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure CardPageLookupOK(var P: Page "LT Y68 Pg Card"; var Response: Action)
    begin
        Response := Action::LookupOK;
    end;

    [TryFunction]
    local procedure TryRunRo(var Item: Record "LT Y68 Pg Item"; var Cur: Record "LT Y68 Pg Item"; var A: Action)
    var
        P: Page "LT Y68 Pg List RO";
    begin
        P.SetTableView(Item);
        P.LookupMode(true);
        A := P.RunModal();
        P.GetRecord(Cur);
    end;

    [TryFunction]
    local procedure TryRunEdit(var Item: Record "LT Y68 Pg Item"; var Cur: Record "LT Y68 Pg Item"; var A: Action)
    var
        P: Page "LT Y68 Pg List Edit";
    begin
        P.SetTableView(Item);
        P.LookupMode(true);
        A := P.RunModal();
        P.GetRecord(Cur);
    end;

    [TryFunction]
    local procedure TryRunCard(var Item: Record "LT Y68 Pg Item"; var Cur: Record "LT Y68 Pg Item"; var A: Action)
    var
        P: Page "LT Y68 Pg Card";
    begin
        P.SetTableView(Item);
        P.LookupMode(true);
        A := P.RunModal();
        P.GetRecord(Cur);
    end;

    local procedure Result(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; A: Action; Cur: Record "LT Y68 Pg Item")
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        if Ok then begin
            Observer.Observe(Name + ' action', Format(A));
            Observer.Observe(Name + ' cur', Describe(Cur));
        end else begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    [HandlerFunctions('RoPageLookupOK')]
    procedure Q3_PageHandler_LookupOK_NoRow_NonEditableList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunRo(Item, Cur, A);
        Result(Observer, 'ro lookupok', Ok, A, Cur);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RoPageLookupCancel')]
    procedure Q3_PageHandler_LookupCancel_NoRow_NonEditableList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunRo(Item, Cur, A);
        Result(Observer, 'ro lookupcancel', Ok, A, Cur);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('EditPageLookupOK')]
    procedure Q3_PageHandler_LookupOK_NoRow_EditableList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunEdit(Item, Cur, A);
        Result(Observer, 'edit lookupok', Ok, A, Cur);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardPageLookupOK')]
    procedure Q3_PageHandler_LookupOK_NoRow_Card()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunCard(Item, Cur, A);
        Result(Observer, 'card lookupok', Ok, A, Cur);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RoPageLookupOK')]
    procedure Q3_PageHandler_LookupOK_RowsInView_NonEditableList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        Item.SetRange(Rank, 1);
        Ok := TryRunRo(Item, Cur, A);
        Result(Observer, 'ro rows in view', Ok, A, Cur);
        Observer.Finish();
    end;

    // TestPage-typed handlers: OK / LookupOK without selecting a row.
    [ModalPageHandler]
    procedure RoTpOK(var TP: TestPage "LT Y68 Pg List RO")
    begin
        TP.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EditTpOK(var TP: TestPage "LT Y68 Pg List Edit")
    begin
        TP.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CardTpOK(var TP: TestPage "LT Y68 Pg Card")
    begin
        TP.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure RoTpCancel(var TP: TestPage "LT Y68 Pg List RO")
    begin
        TP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('RoTpOK')]
    procedure Q3_TestPageHandler_OK_NoRow_NonEditableList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunRo(Item, Cur, A);
        Result(Observer, 'ro tp ok', Ok, A, Cur);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('EditTpOK')]
    procedure Q3_TestPageHandler_OK_NoRow_EditableList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunEdit(Item, Cur, A);
        Result(Observer, 'edit tp ok', Ok, A, Cur);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardTpOK')]
    procedure Q3_TestPageHandler_OK_NoRow_Card()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunCard(Item, Cur, A);
        Result(Observer, 'card tp ok', Ok, A, Cur);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RoTpCancel')]
    procedure Q3_TestPageHandler_Cancel_NoRow_NonEditableList()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT Y68 Pg Item";
        Cur: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        NoRowView(Item);
        Ok := TryRunRo(Item, Cur, A);
        Result(Observer, 'ro tp cancel', Ok, A, Cur);
        Observer.Finish();
    end;

    // Q6: Page.RunModal(Id, Rec) of a lookup page after the selected row left the view while the page was open.
    [ModalPageHandler]
    procedure LeaveViewHandler(var TP: TestPage "LT Y68 Pg List RO")
    var
        Other: Record "LT Y68 Pg Item";
    begin
        Log.Add('first=' + Format(TP.First()) + ' no=' + TP."No.".Value());
        case Mode of
            1:
                begin
                    Other.Get('A');
                    Other.Rank := 5;
                    Other.Modify();
                    Log.Add('modified A');
                end;
            2:
                begin
                    Other.Get('A');
                    Other.Delete();
                    Log.Add('deleted A');
                end;
            3:
                begin
                    Other.Get('A');
                    Other.Name := 'renamed';
                    Other.Modify();
                    Log.Add('renamed A');
                end;
            4:
                begin
                    Other.Get('A');
                    Other.Rename('Z');
                    Log.Add('renamed key A to Z');
                end;
        end;
        TP.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryRunStatic(var Item: Record "LT Y68 Pg Item"; var A: Action)
    begin
        A := Page.RunModal(Page::"LT Y68 Pg List RO", Item);
    end;

    local procedure LeaveCase(var Observer: Codeunit "Probe Observer"; Name: Text; NewMode: Integer)
    var
        Item: Record "LT Y68 Pg Item";
        A: Action;
        Ok: Boolean;
    begin
        Seed();
        Mode := NewMode;
        Item.SetRange(Rank, 1);
        Ok := TryRunStatic(Item, A);
        Observer.Observe(Name + ' ok', Format(Ok));
        if Ok then
            Observer.Observe(Name + ' action', Format(A))
        else begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Observe(Name + ' rec', 'no=[' + Item."No." + '] name=[' + Item.Name + '] rank=' + Format(Item.Rank) + ' filter=[' + Item.GetFilter(Rank) + ']');
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    [HandlerFunctions('LeaveViewHandler')]
    procedure Q6_LookupRunModal_RowChangedOutOfView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LeaveCase(Observer, 'left view', 1);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LeaveViewHandler')]
    procedure Q6_LookupRunModal_RowDeleted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LeaveCase(Observer, 'deleted', 2);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LeaveViewHandler')]
    procedure Q6_LookupRunModal_RowChangedStaysInView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LeaveCase(Observer, 'renamed', 3);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LeaveViewHandler')]
    procedure Q6_LookupRunModal_RowKeyRenamed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LeaveCase(Observer, 'key renamed', 4);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('LeaveViewHandler')]
    procedure Q6_LookupRunModal_NothingChanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        LeaveCase(Observer, 'unchanged', 0);
        Observer.Finish();
    end;
}
