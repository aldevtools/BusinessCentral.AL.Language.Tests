// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 92643 - 92648
// Probe: gap cycle 3 spec C3-14. A dialog with two line parts behind Visible variables, opened by Page.RunModal on a Page variable
//   (LookupMode); after RunModal returned, a procedure of the dialog reaches a part through CurrPage.<part>.Page and the part copies its
//   Rec and calls CurrPage.SetSelectionFilter (the shape of a "get posted document lines" dialog). Also CurrPage.Update / SaveRecord and a
//   part's CurrPage.Update called by the dialog's code after it closed. Every literal asserted below is what the BC service tier produced.
// Facts: the record the part hands out after the dialog closed (OK, Cancel, a moved part row, the other part shown by an option control),
//   on a dialog that never ran, and after Page.Run closed; ok or the error text and code of Update / SaveRecord after close.
// BC versions: 27, 28, 29

table 92643 "LT Y37 PC Vend"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92644 "LT Y37 PC Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Vend; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Kind; Integer) { }
        field(4; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Vend, "Line No.") { Clustered = true; }
    }
}

page 92645 "LT Y37 PC Part A"
{
    PageType = ListPart;
    SourceTable = "LT Y37 PC Line";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    procedure GetSelectedLine(var L: Record "LT Y37 PC Line")
    begin
        L.Copy(Rec);
        CurrPage.SetSelectionFilter(L);
    end;

    procedure PartUpdate()
    begin
        CurrPage.Update(false);
    end;

    procedure RecText(): Text
    begin
        exit(Rec.Vend + '/' + Format(Rec."Line No.") + ' filters [' + Rec.GetFilters() + ']');
    end;
}

page 92646 "LT Y37 PC Part B"
{
    PageType = ListPart;
    SourceTable = "LT Y37 PC Line";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    procedure GetSelectedLine(var L: Record "LT Y37 PC Line")
    begin
        L.Copy(Rec);
        CurrPage.SetSelectionFilter(L);
    end;
}

page 92647 "LT Y37 PC Dialog"
{
    PageType = Card;
    SourceTable = "LT Y37 PC Vend";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
            field(MenuOpt; MenuOpt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    ChangeMenu(MenuOpt);
                end;
            }
            part(PartA; "LT Y37 PC Part A")
            {
                ApplicationArea = All;
                SubPageLink = Vend = field("No.");
                SubPageView = where(Kind = const(0));
                Visible = VisA;
            }
            part(PartB; "LT Y37 PC Part B")
            {
                ApplicationArea = All;
                SubPageLink = Vend = field("No.");
                SubPageView = where(Kind = const(1));
                Visible = VisB;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ChangeMenu(MenuOpt::x0);
    end;

    var
        MenuOpt: Option x0,x1;
        CurrentMenu: Integer;
        VisA: Boolean;
        VisB: Boolean;

    local procedure ChangeMenu(NewMenu: Integer)
    begin
        VisA := NewMenu = 0;
        VisB := NewMenu = 1;
        CurrentMenu := NewMenu;
    end;

    procedure GetCurrentMenu(): Integer
    begin
        exit(CurrentMenu);
    end;

    procedure CopySel(Menu: Integer; var L: Record "LT Y37 PC Line")
    begin
        case Menu of
            0:
                CurrPage.PartA.Page.GetSelectedLine(L);
            1:
                CurrPage.PartB.Page.GetSelectedLine(L);
        end;
    end;

    procedure PartARecText(): Text
    begin
        exit(CurrPage.PartA.Page.RecText());
    end;

    procedure HostUpdate(Save: Boolean)
    begin
        CurrPage.Update(Save);
    end;

    procedure HostSaveRecord()
    begin
        CurrPage.SaveRecord();
    end;

    procedure PartAUpdate()
    begin
        CurrPage.PartA.Page.PartUpdate();
    end;
}

codeunit 92648 "LT Y37 PC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerMode: Integer;

    local procedure Seed(var V: Record "LT Y37 PC Vend")
    var
        L: Record "LT Y37 PC Line";
    begin
        V.DeleteAll();
        L.DeleteAll();
        V."No." := 'V2';
        V.Insert();
        AddLine('V2', 10000, 0, 'x1');
        V."No." := 'V1';
        V.Name := 'One';
        V.Insert();
        AddLine('V1', 10000, 0, 'a1');
        AddLine('V1', 20000, 0, 'a2');
        AddLine('V1', 30000, 1, 'b1');
        AddLine('V1', 40000, 1, 'b2');
    end;

    local procedure AddLine(Vend: Code[20]; LineNo: Integer; Kind: Integer; Descr: Text[30])
    var
        L: Record "LT Y37 PC Line";
    begin
        L.Vend := Vend;
        L."Line No." := LineNo;
        L.Kind := Kind;
        L.Descr := Descr;
        L.Insert();
    end;

    local procedure Lines(var L: Record "LT Y37 PC Line"): Text
    var
        T: Text;
    begin
        if L.FindSet() then
            repeat
                T += Format(L."Line No.") + ';';
            until L.Next() = 0;
        exit(T);
    end;

    // Copies the selection of part Menu into a record and observes its count, filters and rows; an error is observed instead.
    local procedure ObserveSel(Name: Text; var Pg: Page "LT Y37 PC Dialog"; Menu: Integer)
    var
        L: Record "LT Y37 PC Line";
    begin
        ClearLastError();
        if TryCopySel(Pg, Menu, L) then begin
            Observer.Observe(Name + ' count', Format(L.Count()));
            Observer.Observe(Name + ' filters', L.GetFilters());
            Observer.Observe(Name + ' rows', Lines(L));
        end else
            Observer.ObserveError(Name + ' error');
    end;

    [TryFunction]
    local procedure TryCopySel(var Pg: Page "LT Y37 PC Dialog"; Menu: Integer; var L: Record "LT Y37 PC Line")
    begin
        Pg.CopySel(Menu, L);
    end;

    [TryFunction]
    local procedure TryHostUpdate(var Pg: Page "LT Y37 PC Dialog"; Save: Boolean)
    begin
        Pg.HostUpdate(Save);
    end;

    [TryFunction]
    local procedure TryHostSaveRecord(var Pg: Page "LT Y37 PC Dialog")
    begin
        Pg.HostSaveRecord();
    end;

    [TryFunction]
    local procedure TryPartAUpdate(var Pg: Page "LT Y37 PC Dialog")
    begin
        Pg.PartAUpdate();
    end;

    [TryFunction]
    local procedure TryPartARecText(var Pg: Page "LT Y37 PC Dialog"; var T: Text)
    begin
        T := Pg.PartARecText();
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + ' error')
        else
            ClearLastError();
    end;

    local procedure RunDialog(var Pg: Page "LT Y37 PC Dialog"; var V: Record "LT Y37 PC Vend"; Mode: Integer)
    begin
        HandlerMode := Mode;
        Pg.SetRecord(V);
        Pg.LookupMode := true;
        Observer.Observe('runmodal', Format(Pg.RunModal()));
    end;

    [ModalPageHandler]
    procedure DialogHandler(var P: TestPage "LT Y37 PC Dialog")
    begin
        case HandlerMode of
            0:
                P.OK().Invoke();
            1:
                begin
                    P.PartA.Last();
                    P.OK().Invoke();
                end;
            2:
                begin
                    P.MenuOpt.SetValue('x1');
                    P.PartB.Last();
                    P.OK().Invoke();
                end;
            3:
                P.Cancel().Invoke();
        end;
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
        T: Text;
    begin
        Seed(V);
        RunDialog(Pg, V, 0);
        Observer.Observe('menu', Format(Pg.GetCurrentMenu()));
        ObserveSel('A', Pg, 0);
        if TryPartARecText(Pg, T) then
            Observer.Observe('A rec', T)
        else
            Observer.ObserveError('A rec error');
        Observer.Expect('runmodal', 'LookupOK');
        Observer.Expect('menu', '0');
        Observer.Expect('A count', '1');
        Observer.Expect('A filters', 'Vend: V1, Line No.: 10000');
        Observer.Expect('A rows', '10000;');
        Observer.Expect('A rec', 'V1/10000 filters []');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_PartRowMoved()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 1);
        ObserveSel('A', Pg, 0);
        Observer.Expect('runmodal', 'LookupOK');
        Observer.Expect('A count', '1');
        Observer.Expect('A filters', 'Vend: V1, Line No.: 20000');
        Observer.Expect('A rows', '20000;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_OtherPartShown()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 2);
        Observer.Observe('menu', Format(Pg.GetCurrentMenu()));
        ObserveSel('B', Pg, 1);
        ObserveSel('A hidden', Pg, 0);
        Observer.Expect('runmodal', 'LookupOK');
        Observer.Expect('menu', '1');
        Observer.Expect('B count', '1');
        Observer.Expect('B filters', 'Vend: V1, Line No.: 40000');
        Observer.Expect('B rows', '40000;');
        Observer.Expect('A hidden count', '1');
        Observer.Expect('A hidden filters', 'Vend: V1, Line No.: 10000');
        Observer.Expect('A hidden rows', '10000;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalCancel_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 3);
        ObserveSel('A', Pg, 0);
        Observer.Expect('runmodal', 'LookupCancel');
        Observer.Expect('A count', '1');
        Observer.Expect('A filters', 'Vend: V1, Line No.: 10000');
        Observer.Expect('A rows', '10000;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_UpdateAndSave()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 0);
        Step('host update false', TryHostUpdate(Pg, false));
        Step('host update true', TryHostUpdate(Pg, true));
        Step('host saverecord', TryHostSaveRecord(Pg));
        Step('part update', TryPartAUpdate(Pg));
        ObserveSel('A after', Pg, 0);
        V.Get('V1');
        Observer.Observe('stored name', V.Name);
        Observer.Expect('runmodal', 'LookupOK');
        Observer.Expect('host update false', 'Yes');
        Observer.Expect('host update true', 'Yes');
        Observer.Expect('host saverecord', 'Yes');
        Observer.Expect('part update', 'Yes');
        Observer.Expect('A after count', '1');
        Observer.Expect('A after filters', 'Vend: V1, Line No.: 10000');
        Observer.Expect('A after rows', '10000;');
        Observer.Expect('stored name', 'One');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C314_NeverRan_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        Pg.SetRecord(V);
        ObserveSel('A', Pg, 0);
        ObserveSel('B', Pg, 1);
        Step('host update false', TryHostUpdate(Pg, false));
        Observer.Expect('A count', '0');
        Observer.Expect('A filters', 'Vend: '''', Line No.: 0');
        Observer.Expect('A rows', '');
        Observer.Expect('B count', '0');
        Observer.Expect('B filters', 'Vend: '''', Line No.: 0');
        Observer.Expect('B rows', '');
        Observer.Expect('host update false', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C314_AfterRunClosed_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
        P: TestPage "LT Y37 PC Dialog";
    begin
        Seed(V);
        P.Trap();
        Pg.SetRecord(V);
        Pg.Run();
        Observer.Observe('shown no', P."No.".Value());
        P.PartA.Last();
        Observer.Observe('shown part row', P.PartA."Line No.".Value());
        ObserveSel('A shown', Pg, 0);
        P.Close();
        ObserveSel('A closed', Pg, 0);
        Step('host update false closed', TryHostUpdate(Pg, false));
        Observer.Expect('shown no', 'V1');
        Observer.Expect('shown part row', '20000');
        Observer.Expect('A shown count', '0');
        Observer.Expect('A shown filters', 'Vend: '''', Line No.: 0');
        Observer.Expect('A shown rows', '');
        Observer.Expect('A closed count', '0');
        Observer.Expect('A closed filters', 'Vend: '''', Line No.: 0');
        Observer.Expect('A closed rows', '');
        Observer.Expect('host update false closed', 'Yes');
        Observer.Verify();
    end;

    // Observe-only native bootstrap. Finish() deliberately fails with complete OBSERVE pairs.
    // TryFunction cases measure the catch context. Direct cases separately record native test-boundary follow-up.
    var
        ClpParent: TestPage "PAG Trigger Close Parent";
        ClpLog: Codeunit "PAG Trigger Close Log";
        ClpPreserveTrace: Boolean;
        ClpBoundaryTrace: Text;
        ClpBoundaryCase: Text;
        ClpBoundaryQueries: Integer;
        ClpBoundaryFlag: Boolean;

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
    begin
        // Snapshot continuation metadata before any reset, even if the codeunit flag was lost.
        ClpBoundaryTrace := ClpLog.ReadTrace();
        ClpBoundaryCase := ClpLog.ReadCase();
        ClpBoundaryQueries := ClpLog.QueryCount();
        ClpBoundaryFlag := ClpPreserveTrace;
        ClpPreserveTrace := false;
        Clear(ClpParent);
        ClpLog.Reset();
        Observer.Discard();
        Cleanup.Initialize();
    end;

    local procedure ClpFlag(Value: Boolean): Text
    begin
        if Value then
            exit('T');
        exit('F');
    end;

    [TryFunction]
    local procedure ClpTryOpen()
    begin
        ClpParent.OpenView();
    end;

    [TryFunction]
    local procedure ClpTryAction()
    begin
        ClpParent.ProbeAction.Invoke();
    end;

    [TryFunction]
    local procedure ClpTryParent(var Id: Integer)
    begin
        Id := ClpParent.ProbeId.AsInteger();
    end;

    [TryFunction]
    local procedure ClpTryPart(var Id: Integer)
    begin
        Id := ClpParent.PartBody.ProbeId.AsInteger();
    end;

    [TryFunction]
    local procedure ClpTryClose()
    begin
        ClpParent.Close();
    end;

    local procedure ClpCapture(UseAction: Boolean; RequestClose: Boolean; PermitClose: Boolean)
    var
        Opened: Boolean;
        ActionSucceeded: Boolean;
        ParentRead: Boolean;
        PartRead: Boolean;
        Closed: Boolean;
        ParentId: Integer;
        PartId: Integer;
        OpenCode: Text;
        OpenText: Text;
        ActionCode: Text;
        ActionText: Text;
        ParentCode: Text;
        ParentText: Text;
        PartCode: Text;
        PartText: Text;
        CloseCode: Text;
        CloseText: Text;
        OperationTrace: Text;
        OperationQueries: Integer;
    begin
        ClpLog.Configure(UseAction, RequestClose, PermitClose);
        ClearLastError();
        Opened := ClpTryOpen();
        if not Opened then begin
            OpenCode := GetLastErrorCode();
            OpenText := GetLastErrorText();
        end;
        if UseAction and Opened then begin
            ClearLastError();
            ActionSucceeded := ClpTryAction();
            if not ActionSucceeded then begin
                ActionCode := GetLastErrorCode();
                ActionText := GetLastErrorText();
            end;
        end;
        OperationTrace := ClpLog.ReadTrace();
        OperationQueries := ClpLog.QueryCount();
        ParentId := -777;
        PartId := -777;
        ClearLastError();
        ParentRead := ClpTryParent(ParentId);
        if not ParentRead then begin
            ParentCode := GetLastErrorCode();
            ParentText := GetLastErrorText();
        end;
        ClearLastError();
        PartRead := ClpTryPart(PartId);
        if not PartRead then begin
            PartCode := GetLastErrorCode();
            PartText := GetLastErrorText();
        end;
        ClearLastError();
        Closed := ClpTryClose();
        if not Closed then begin
            CloseCode := GetLastErrorCode();
            CloseText := GetLastErrorText();
        end;
        Observer.Observe('open.ok', ClpFlag(Opened));
        Observer.Observe('open.error.code', OpenCode);
        Observer.Observe('open.error.text', OpenText);
        Observer.Observe('action.requested', ClpFlag(UseAction));
        Observer.Observe('action.ok', ClpFlag(ActionSucceeded));
        Observer.Observe('action.error.code', ActionCode);
        Observer.Observe('action.error.text', ActionText);
        Observer.Observe('operation.trace', OperationTrace);
        Observer.Observe('operation.queries', Format(OperationQueries));
        Observer.Observe('follow.parent.ok', ClpFlag(ParentRead));
        Observer.Observe('follow.parent.id', Format(ParentId));
        Observer.Observe('follow.parent.error.code', ParentCode);
        Observer.Observe('follow.parent.error.text', ParentText);
        Observer.Observe('follow.part.ok', ClpFlag(PartRead));
        Observer.Observe('follow.part.id', Format(PartId));
        Observer.Observe('follow.part.error.code', PartCode);
        Observer.Observe('follow.part.error.text', PartText);
        Observer.Observe('follow.close.ok', ClpFlag(Closed));
        Observer.Observe('follow.close.error.code', CloseCode);
        Observer.Observe('follow.close.error.text', CloseText);
        Observer.Observe('follow.trace', ClpLog.ReadTrace());
        Observer.Observe('follow.queries', Format(ClpLog.QueryCount()));
        Observer.Observe('capture.end', 'COMPLETE');
        Observer.Verify();
    end;

    [Test]
    procedure CLP_AGCR_NoClose_PartAccess_Observe()
    begin
        Initialize();
        ClpExpect('CLP_AGCR_NoClose_PartAccess_Observe');
        ClpCapture(false, false, true);
    end;

    [Test]
    procedure CLP_AGCR_CloseAllowed_PartAccess_Observe()
    begin
        Initialize();
        ClpExpect('CLP_AGCR_CloseAllowed_PartAccess_Observe');
        ClpCapture(false, true, true);
    end;

    [Test]
    procedure CLP_AGCR_CloseVeto_PartAccess_Observe()
    begin
        Initialize();
        ClpExpect('CLP_AGCR_CloseVeto_PartAccess_Observe');
        ClpCapture(false, true, false);
    end;

    [Test]
    procedure CLP_Action_CloseAllowed_PartAccess_Observe()
    begin
        Initialize();
        ClpExpect('CLP_Action_CloseAllowed_PartAccess_Observe');
        ClpCapture(true, true, true);
    end;

    [Test]
    procedure CLP_Action_CloseVeto_PartAccess_Observe()
    begin
        Initialize();
        ClpExpect('CLP_Action_CloseVeto_PartAccess_Observe');
        ClpCapture(true, true, false);
    end;

    local procedure ClpDirect(UseAction: Boolean; RequestClose: Boolean; PermitClose: Boolean; Identity: Text)
    begin
        ClpLog.Configure(UseAction, RequestClose, PermitClose);
        ClpLog.SetCase(Identity);
        ClpPreserveTrace := true;
        ClpLog.Mark('TEST.BEFORE.OPEN');
        ClpParent.OpenView();
        ClpLog.Mark('TEST.AFTER.OPEN');
        if UseAction then begin
            ClpParent.ProbeAction.Invoke();
            ClpLog.Mark('TEST.AFTER.ACTION');
        end;
        Observer.Observe('direct.case', ClpLog.ReadCase());
        Observer.Observe('direct.returned', 'T');
        Observer.Observe('direct.trace', ClpLog.ReadTrace());
        Observer.Observe('direct.queries', Format(ClpLog.QueryCount()));
        Observer.Observe('capture.end', 'COMPLETE');
        Observer.Verify();
    end;

    local procedure ClpDirectBoundaryTrace(ExpectedIdentity: Text)
    begin
        // This includes any native test-runner cleanup after the previous test, not just the operation body.
        Observer.Observe('boundary.expected.case', ExpectedIdentity);
        Observer.Observe('boundary.actual.case', ClpBoundaryCase);
        Observer.Observe('boundary.paired', ClpFlag(ClpBoundaryCase = ExpectedIdentity));
        Observer.Observe('boundary.preserve.flag', ClpFlag(ClpBoundaryFlag));
        Observer.Observe('direct.post-test-boundary.trace', ClpBoundaryTrace);
        Observer.Observe('direct.post-test-boundary.queries', Format(ClpBoundaryQueries));
        Observer.Observe('capture.end', 'COMPLETE');
        Observer.Verify();
    end;

    [Test]
    procedure CLP_Direct_AGCR_NoClose_Observe()
    begin
        Initialize();
        ClpExpect('CLP_Direct_AGCR_NoClose_Observe');
        ClpDirect(false, false, true, 'AGCR_NoClose');
    end;

    [Test]
    procedure CLP_Direct_AGCR_NoClose_BoundaryTrace()
    begin
        Initialize();
        ClpExpect('CLP_Direct_AGCR_NoClose_BoundaryTrace');
        ClpDirectBoundaryTrace('AGCR_NoClose');
    end;

    [Test]
    procedure CLP_Direct_AGCR_CloseAllowed_Observe()
    begin
        Initialize();
        ClpExpect('CLP_Direct_AGCR_CloseAllowed_Observe');
        ClpDirect(false, true, true, 'AGCR_CloseAllowed');
    end;

    [Test]
    procedure CLP_Direct_AGCR_CloseAllowed_BoundaryTrace()
    begin
        Initialize();
        ClpExpect('CLP_Direct_AGCR_CloseAllowed_BoundaryTrace');
        ClpDirectBoundaryTrace('AGCR_CloseAllowed');
    end;

    [Test]
    procedure CLP_Direct_AGCR_CloseVeto_Observe()
    begin
        Initialize();
        ClpExpect('CLP_Direct_AGCR_CloseVeto_Observe');
        ClpDirect(false, true, false, 'AGCR_CloseVeto');
    end;

    [Test]
    procedure CLP_Direct_AGCR_CloseVeto_BoundaryTrace()
    begin
        Initialize();
        ClpExpect('CLP_Direct_AGCR_CloseVeto_BoundaryTrace');
        ClpDirectBoundaryTrace('AGCR_CloseVeto');
    end;

    [Test]
    procedure CLP_Direct_Action_CloseAllowed_Observe()
    begin
        Initialize();
        ClpExpect('CLP_Direct_Action_CloseAllowed_Observe');
        ClpDirect(true, true, true, 'Action_CloseAllowed');
    end;

    [Test]
    procedure CLP_Direct_Action_CloseAllowed_BoundaryTrace()
    begin
        Initialize();
        ClpExpect('CLP_Direct_Action_CloseAllowed_BoundaryTrace');
        ClpDirectBoundaryTrace('Action_CloseAllowed');
    end;

    [Test]
    procedure CLP_Direct_Action_CloseVeto_Observe()
    begin
        Initialize();
        ClpExpect('CLP_Direct_Action_CloseVeto_Observe');
        ClpDirect(true, true, false, 'Action_CloseVeto');
    end;

    [Test]
    procedure CLP_Direct_Action_CloseVeto_BoundaryTrace()
    begin
        Initialize();
        ClpExpect('CLP_Direct_Action_CloseVeto_BoundaryTrace');
        ClpDirectBoundaryTrace('Action_CloseVeto');
    end;

    // Exact native BC27.5 bootstrap pairs: run 41897699021, original JUnit retained.
    local procedure ClpExpect(ObservationCase: Text)
    begin
        case ObservationCase of
            'CLP_AGCR_NoClose_PartAccess_Observe':
                begin
                    Observer.Expect('open.ok', 'T');
                    Observer.Expect('open.error.code', '');
                    Observer.Expect('open.error.text', '');
                    Observer.Expect('action.requested', 'F');
                    Observer.Expect('action.ok', 'F');
                    Observer.Expect('action.error.code', '');
                    Observer.Expect('action.error.text', '');
                    Observer.Expect('operation.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;NO.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;');
                    Observer.Expect('operation.queries', '0');
                    Observer.Expect('follow.parent.ok', 'T');
                    Observer.Expect('follow.parent.id', '1');
                    Observer.Expect('follow.parent.error.code', '');
                    Observer.Expect('follow.parent.error.text', '');
                    Observer.Expect('follow.part.ok', 'T');
                    Observer.Expect('follow.part.id', '1');
                    Observer.Expect('follow.part.error.code', '');
                    Observer.Expect('follow.part.error.text', '');
                    Observer.Expect('follow.close.ok', 'T');
                    Observer.Expect('follow.close.error.code', '');
                    Observer.Expect('follow.close.error.text', '');
                    Observer.Expect('follow.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;NO.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;');
                    Observer.Expect('follow.queries', '1');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_AGCR_CloseAllowed_PartAccess_Observe':
                begin
                    Observer.Expect('open.ok', 'T');
                    Observer.Expect('open.error.code', '');
                    Observer.Expect('open.error.text', '');
                    Observer.Expect('action.requested', 'F');
                    Observer.Expect('action.ok', 'F');
                    Observer.Expect('action.error.code', '');
                    Observer.Expect('action.error.text', '');
                    Observer.Expect('operation.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;');
                    Observer.Expect('operation.queries', '1');
                    Observer.Expect('follow.parent.ok', 'F');
                    Observer.Expect('follow.parent.id', '-777');
                    Observer.Expect('follow.parent.error.code', 'TestPageNotOpened');
                    Observer.Expect('follow.parent.error.text', 'The TestPage is not open.');
                    Observer.Expect('follow.part.ok', 'F');
                    Observer.Expect('follow.part.id', '-777');
                    Observer.Expect('follow.part.error.code', 'TestPageNotOpened');
                    Observer.Expect('follow.part.error.text', 'The TestPage is not open.');
                    Observer.Expect('follow.close.ok', 'F');
                    Observer.Expect('follow.close.error.code', 'TestPageNotOpened');
                    Observer.Expect('follow.close.error.text', 'The TestPage is not open.');
                    Observer.Expect('follow.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;');
                    Observer.Expect('follow.queries', '1');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_AGCR_CloseVeto_PartAccess_Observe':
                begin
                    Observer.Expect('open.ok', 'T');
                    Observer.Expect('open.error.code', '');
                    Observer.Expect('open.error.text', '');
                    Observer.Expect('action.requested', 'F');
                    Observer.Expect('action.ok', 'F');
                    Observer.Expect('action.error.code', '');
                    Observer.Expect('action.error.text', '');
                    Observer.Expect('operation.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;');
                    Observer.Expect('operation.queries', '2');
                    Observer.Expect('follow.parent.ok', 'T');
                    Observer.Expect('follow.parent.id', '0');
                    Observer.Expect('follow.parent.error.code', '');
                    Observer.Expect('follow.parent.error.text', '');
                    Observer.Expect('follow.part.ok', 'T');
                    Observer.Expect('follow.part.id', '1');
                    Observer.Expect('follow.part.error.code', '');
                    Observer.Expect('follow.part.error.text', '');
                    Observer.Expect('follow.close.ok', 'T');
                    Observer.Expect('follow.close.error.code', '');
                    Observer.Expect('follow.close.error.text', '');
                    Observer.Expect('follow.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;PARENT.QUERY:OK;');
                    Observer.Expect('follow.queries', '3');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Action_CloseAllowed_PartAccess_Observe':
                begin
                    Observer.Expect('open.ok', 'T');
                    Observer.Expect('open.error.code', '');
                    Observer.Expect('open.error.text', '');
                    Observer.Expect('action.requested', 'T');
                    Observer.Expect('action.ok', 'T');
                    Observer.Expect('action.error.code', '');
                    Observer.Expect('action.error.text', '');
                    Observer.Expect('operation.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;');
                    Observer.Expect('operation.queries', '1');
                    Observer.Expect('follow.parent.ok', 'F');
                    Observer.Expect('follow.parent.id', '-777');
                    Observer.Expect('follow.parent.error.code', 'TestPageNotOpened');
                    Observer.Expect('follow.parent.error.text', 'The TestPage is not open.');
                    Observer.Expect('follow.part.ok', 'F');
                    Observer.Expect('follow.part.id', '-777');
                    Observer.Expect('follow.part.error.code', 'TestPageNotOpened');
                    Observer.Expect('follow.part.error.text', 'The TestPage is not open.');
                    Observer.Expect('follow.close.ok', 'F');
                    Observer.Expect('follow.close.error.code', 'TestPageNotOpened');
                    Observer.Expect('follow.close.error.text', 'The TestPage is not open.');
                    Observer.Expect('follow.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;');
                    Observer.Expect('follow.queries', '1');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Action_CloseVeto_PartAccess_Observe':
                begin
                    Observer.Expect('open.ok', 'T');
                    Observer.Expect('open.error.code', '');
                    Observer.Expect('open.error.text', '');
                    Observer.Expect('action.requested', 'T');
                    Observer.Expect('action.ok', 'T');
                    Observer.Expect('action.error.code', '');
                    Observer.Expect('action.error.text', '');
                    Observer.Expect('operation.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;');
                    Observer.Expect('operation.queries', '2');
                    Observer.Expect('follow.parent.ok', 'T');
                    Observer.Expect('follow.parent.id', '1');
                    Observer.Expect('follow.parent.error.code', '');
                    Observer.Expect('follow.parent.error.text', '');
                    Observer.Expect('follow.part.ok', 'T');
                    Observer.Expect('follow.part.id', '1');
                    Observer.Expect('follow.part.error.code', '');
                    Observer.Expect('follow.part.error.text', '');
                    Observer.Expect('follow.close.ok', 'T');
                    Observer.Expect('follow.close.error.code', '');
                    Observer.Expect('follow.close.error.text', '');
                    Observer.Expect('follow.trace', 'PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;PARENT.QUERY:OK;');
                    Observer.Expect('follow.queries', '3');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_AGCR_NoClose_Observe':
                begin
                    Observer.Expect('direct.case', 'AGCR_NoClose');
                    Observer.Expect('direct.returned', 'T');
                    Observer.Expect('direct.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;NO.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;TEST.AFTER.OPEN;');
                    Observer.Expect('direct.queries', '0');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_AGCR_NoClose_BoundaryTrace':
                begin
                    Observer.Expect('boundary.expected.case', 'AGCR_NoClose');
                    Observer.Expect('boundary.actual.case', 'AGCR_NoClose');
                    Observer.Expect('boundary.paired', 'T');
                    Observer.Expect('boundary.preserve.flag', 'T');
                    Observer.Expect('direct.post-test-boundary.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;NO.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;TEST.AFTER.OPEN;');
                    Observer.Expect('direct.post-test-boundary.queries', '0');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_AGCR_CloseAllowed_Observe':
                begin
                    Observer.Expect('direct.case', 'AGCR_CloseAllowed');
                    Observer.Expect('direct.returned', 'T');
                    Observer.Expect('direct.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;TEST.AFTER.OPEN;');
                    Observer.Expect('direct.queries', '1');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_AGCR_CloseAllowed_BoundaryTrace':
                begin
                    Observer.Expect('boundary.expected.case', 'AGCR_CloseAllowed');
                    Observer.Expect('boundary.actual.case', 'AGCR_CloseAllowed');
                    Observer.Expect('boundary.paired', 'T');
                    Observer.Expect('boundary.preserve.flag', 'T');
                    Observer.Expect('direct.post-test-boundary.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;TEST.AFTER.OPEN;');
                    Observer.Expect('direct.post-test-boundary.queries', '1');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_AGCR_CloseVeto_Observe':
                begin
                    Observer.Expect('direct.case', 'AGCR_CloseVeto');
                    Observer.Expect('direct.returned', 'T');
                    Observer.Expect('direct.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;TEST.AFTER.OPEN;');
                    Observer.Expect('direct.queries', '2');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_AGCR_CloseVeto_BoundaryTrace':
                begin
                    Observer.Expect('boundary.expected.case', 'AGCR_CloseVeto');
                    Observer.Expect('boundary.actual.case', 'AGCR_CloseVeto');
                    Observer.Expect('boundary.paired', 'T');
                    Observer.Expect('boundary.preserve.flag', 'T');
                    Observer.Expect('direct.post-test-boundary.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;PARENT.AGCR;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;TEST.AFTER.OPEN;');
                    Observer.Expect('direct.post-test-boundary.queries', '2');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_Action_CloseAllowed_Observe':
                begin
                    Observer.Expect('direct.case', 'Action_CloseAllowed');
                    Observer.Expect('direct.returned', 'T');
                    Observer.Expect('direct.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;TEST.AFTER.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;TEST.AFTER.ACTION;');
                    Observer.Expect('direct.queries', '1');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_Action_CloseAllowed_BoundaryTrace':
                begin
                    Observer.Expect('boundary.expected.case', 'Action_CloseAllowed');
                    Observer.Expect('boundary.actual.case', 'Action_CloseAllowed');
                    Observer.Expect('boundary.paired', 'T');
                    Observer.Expect('boundary.preserve.flag', 'T');
                    Observer.Expect('direct.post-test-boundary.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;TEST.AFTER.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;PART.CLOSE;PARENT.CLOSE;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:1042:1;AFTER.PART:1042:1;TEST.AFTER.ACTION;');
                    Observer.Expect('direct.post-test-boundary.queries', '1');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_Action_CloseVeto_Observe':
                begin
                    Observer.Expect('direct.case', 'Action_CloseVeto');
                    Observer.Expect('direct.returned', 'T');
                    Observer.Expect('direct.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;TEST.AFTER.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;TEST.AFTER.ACTION;');
                    Observer.Expect('direct.queries', '2');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            'CLP_Direct_Action_CloseVeto_BoundaryTrace':
                begin
                    Observer.Expect('boundary.expected.case', 'Action_CloseVeto');
                    Observer.Expect('boundary.actual.case', 'Action_CloseVeto');
                    Observer.Expect('boundary.paired', 'T');
                    Observer.Expect('boundary.preserve.flag', 'T');
                    Observer.Expect('direct.post-test-boundary.trace', 'TEST.BEFORE.OPEN;PART.INIT;PARENT.OPEN;PART.OPEN;TEST.AFTER.OPEN;PARENT.ACTION;BEFORE.CLOSE;PARENT.QUERY:OK;AFTER.CLOSE;BEFORE.PART;PART.TOUCH:42:1;AFTER.PART:42:1;PARENT.QUERY:OK;TEST.AFTER.ACTION;');
                    Observer.Expect('direct.post-test-boundary.queries', '2');
                    Observer.Expect('capture.end', 'COMPLETE');
                end;
            else
                Error('Unknown close/part observation case: %1', ObservationCase);
        end;
    end;
}
