// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testaction/testaction-enabled-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-lookupmode-method
// Scope: in-scope (Cloud). TestPage in a ModalPageHandler.
// Fixtures used: Probe Observer (codeunit 69160); own table 64720, pages 64721 64722 64723, test codeunit 64724
// Probe: observe-only. Area: Enabled() and Visible() of the built-in actions OK, Cancel, Yes and No of a TestPage (a TestPage has no LookupOK or LookupCancel member: AL0132) in a
//   ModalPageHandler, for a List, a Card and a Worksheet run modally: Page.RunModal(Id, Rec) and Page.RunModal(Id) (no LookupMode set),
//   and a Page variable's RunModal with and without LookupMode(true). Then the handler invokes OK and the test records the returned Action.
//   A built-in action that the page does not have is recorded as the error text and code of Enabled().
//   Already pinned: testpage/LookupModeEditablePageTypes.al (Editable() in lookup mode), pages/run-modal/ModalFirstFromLaterRow.al
//   (the Action of Page.RunModal(Id, Rec) after OK). Not pinned: Enabled() and Visible() of a built-in action.
// local object: the page types are what the test checks
// BC versions: 27, 28, 29

table 64720 "PGA BA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 64721 "PGA BA List"
{
    PageType = List;
    SourceTable = "PGA BA Row";
    ApplicationArea = All;
    UsageCategory = None;

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

page 64722 "PGA BA Card"
{
    PageType = Card;
    SourceTable = "PGA BA Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 64723 "PGA BA Worksheet"
{
    PageType = Worksheet;
    SourceTable = "PGA BA Row";
    ApplicationArea = All;
    UsageCategory = None;

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

codeunit 64724 "PGA BA Builtin Action Enabled"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Initialize(var Row: Record "PGA BA Row")
    begin
        Observer.Discard();
        Row.DeleteAll();
        Row.Init();
        Row."Code" := 'A';
        Row.Insert();
        Row.Init();
        Row."Code" := 'B';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryListAction(var P: TestPage "PGA BA List"; Which: Text; var Result: Text)
    begin
        case Which of
            'OK':
                Result := Format(P.OK().Enabled()) + '/' + Format(P.OK().Visible());
            'Cancel':
                Result := Format(P.Cancel().Enabled()) + '/' + Format(P.Cancel().Visible());
            'Yes':
                Result := Format(P.Yes().Enabled()) + '/' + Format(P.Yes().Visible());
            'No':
                Result := Format(P.No().Enabled()) + '/' + Format(P.No().Visible());
            'InvokeOK':
                P.OK().Invoke();
        end;
    end;

    [TryFunction]
    local procedure TryCardAction(var P: TestPage "PGA BA Card"; Which: Text; var Result: Text)
    begin
        case Which of
            'OK':
                Result := Format(P.OK().Enabled()) + '/' + Format(P.OK().Visible());
            'Cancel':
                Result := Format(P.Cancel().Enabled()) + '/' + Format(P.Cancel().Visible());
            'Yes':
                Result := Format(P.Yes().Enabled()) + '/' + Format(P.Yes().Visible());
            'No':
                Result := Format(P.No().Enabled()) + '/' + Format(P.No().Visible());
            'InvokeOK':
                P.OK().Invoke();
        end;
    end;

    [TryFunction]
    local procedure TryWorksheetAction(var P: TestPage "PGA BA Worksheet"; Which: Text; var Result: Text)
    begin
        case Which of
            'OK':
                Result := Format(P.OK().Enabled()) + '/' + Format(P.OK().Visible());
            'Cancel':
                Result := Format(P.Cancel().Enabled()) + '/' + Format(P.Cancel().Visible());
            'Yes':
                Result := Format(P.Yes().Enabled()) + '/' + Format(P.Yes().Visible());
            'No':
                Result := Format(P.No().Enabled()) + '/' + Format(P.No().Visible());
            'InvokeOK':
                P.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure ListHandler(var P: TestPage "PGA BA List")
    var
        Which: Text;
        Result: Text;
    begin
        P.Last();
        foreach Which in 'OK,Cancel,Yes,No,InvokeOK'.Split(',') do
            if TryListAction(P, Which, Result) then
                Observer.Observe(Which, Result)
            else
                Observer.ObserveError(Which);
    end;

    [ModalPageHandler]
    procedure CardHandler(var P: TestPage "PGA BA Card")
    var
        Which: Text;
        Result: Text;
    begin
        foreach Which in 'OK,Cancel,Yes,No,InvokeOK'.Split(',') do
            if TryCardAction(P, Which, Result) then
                Observer.Observe(Which, Result)
            else
                Observer.ObserveError(Which);
    end;

    [ModalPageHandler]
    procedure WorksheetHandler(var P: TestPage "PGA BA Worksheet")
    var
        Which: Text;
        Result: Text;
    begin
        P.Last();
        foreach Which in 'OK,Cancel,Yes,No,InvokeOK'.Split(',') do
            if TryWorksheetAction(P, Which, Result) then
                Observer.Observe(Which, Result)
            else
                Observer.ObserveError(Which);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_StaticRunModalWithRec_NoLookupMode()
    var
        Row: Record "PGA BA Row";
    begin
        Initialize(Row);
        Observer.Observe('action', Format(Page.RunModal(Page::"PGA BA List", Row)));
        Observer.Observe('rec', Row."Code");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_StaticRunModalWithoutRec()
    var
        Row: Record "PGA BA Row";
    begin
        Initialize(Row);
        Observer.Observe('action', Format(Page.RunModal(Page::"PGA BA List")));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_PageVariableRunModal_NoLookupMode()
    var
        Row: Record "PGA BA Row";
        L: Page "PGA BA List";
    begin
        Initialize(Row);
        Observer.Observe('action', Format(L.RunModal()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_PageVariableRunModal_LookupModeTrue()
    var
        Row: Record "PGA BA Row";
        L: Page "PGA BA List";
    begin
        Initialize(Row);
        L.LookupMode(true);
        Observer.Observe('action', Format(L.RunModal()));
        L.GetRecord(Row);
        Observer.Observe('rec', Row."Code");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_StaticRunModalWithRec_NoLookupMode()
    var
        Row: Record "PGA BA Row";
    begin
        Initialize(Row);
        Row.Get('A');
        Observer.Observe('action', Format(Page.RunModal(Page::"PGA BA Card", Row)));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_PageVariableRunModal_LookupModeTrue()
    var
        Row: Record "PGA BA Row";
        C: Page "PGA BA Card";
    begin
        Initialize(Row);
        C.LookupMode(true);
        Observer.Observe('action', Format(C.RunModal()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WorksheetHandler')]
    procedure Worksheet_StaticRunModalWithRec_NoLookupMode()
    var
        Row: Record "PGA BA Row";
    begin
        Initialize(Row);
        Observer.Observe('action', Format(Page.RunModal(Page::"PGA BA Worksheet", Row)));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WorksheetHandler')]
    procedure Worksheet_PageVariableRunModal_LookupModeTrue()
    var
        Row: Record "PGA BA Row";
        W: Page "PGA BA Worksheet";
    begin
        Initialize(Row);
        W.LookupMode(true);
        Observer.Observe('action', Format(W.RunModal()));
        Observer.Finish();
    end;
}
