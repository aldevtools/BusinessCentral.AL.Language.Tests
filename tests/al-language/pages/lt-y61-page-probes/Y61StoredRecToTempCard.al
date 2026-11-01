// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); table 93253, pages 93014-93015, test codeunit 93249
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: a stored record handed to a Card (and a NavigatePage) whose SourceTableTemporary is true, through SetRecord + RunModal,
//   Page.RunModal(Id, Rec) and Page.Run(Id, Rec): what OnOpenPage sees (Code, Name, IsTemporary, Count), whether an action's Rec.Modify
//   or Rec.Delete reaches the stored row, what GetRecord of the Page variable and the caller's record hold after the close, the action
//   returned, and Next on a page run with an unfiltered record. Control: a record filtered to a code that has no row.
//   Log: open <Code>/<Name>/temp=<IsTemporary>/count=<Count>, agr <Code>/<Name> = OnAfterGetRecord, act <name> = an action ran.
// Neighbours: pages/lt-be-card-onfindrecord/BeCardOnFindRecord.al CardTemp_PageRun_StoredRec (the row is shown),
//   record/lt-loadfields-pagesource-validate/P81PageTempSource.al.
// BC versions: all (CI)

table 93253 "LT Y61 TC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Enabled; Boolean) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

page 93014 "LT Y61 TC Card"
{
    PageType = Card;
    SourceTable = "LT Y61 TC Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(EnabledCtl; Rec.Enabled) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Agree)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Record "LT Y61 Log";
                begin
                    Log.AddLine('act agree');
                    Rec.Enabled := true;
                    Rec.Modify();
                    CurrPage.Close();
                end;
            }
            action(Rename)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Record "LT Y61 Log";
                begin
                    Log.AddLine('act rename');
                    Rec.Name := 'renamed';
                    Rec.Modify();
                end;
            }
            action(DeleteIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Record "LT Y61 Log";
                begin
                    Log.AddLine('act delete');
                    Rec.Delete();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('open ' + Rec.Code + '/' + Rec.Name + '/temp=' + Format(Rec.IsTemporary()) + '/count=' + Format(Rec.Count()));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('agr ' + Rec.Code + '/' + Rec.Name);
    end;

    procedure Result(): Text
    begin
        exit(Rec.Code + '/' + Rec.Name + '/' + Format(Rec.Enabled) + '/count=' + Format(Rec.Count()));
    end;
}

page 93015 "LT Y61 TC Navigate"
{
    PageType = NavigatePage;
    SourceTable = "LT Y61 TC Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(EnabledCtl; Rec.Enabled) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Agree)
            {
                ApplicationArea = All;
                InFooterBar = true;
                trigger OnAction()
                var
                    Log: Record "LT Y61 Log";
                begin
                    Log.AddLine('act agree');
                    Rec.Enabled := true;
                    Rec.Modify();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('open ' + Rec.Code + '/' + Rec.Name + '/temp=' + Format(Rec.IsTemporary()) + '/count=' + Format(Rec.Count()));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('agr ' + Rec.Code + '/' + Rec.Name);
    end;

    procedure Result(): Text
    begin
        exit(Rec.Code + '/' + Rec.Name + '/' + Format(Rec.Enabled) + '/count=' + Format(Rec.Count()));
    end;
}

codeunit 93249 "LT Y61 Stored Rec To Temp Card"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerMode: Text;

    local procedure Seed()
    var
        R: Record "LT Y61 TC Row";
        Log: Record "LT Y61 Log";
    begin
        R.DeleteAll();
        R.Code := 'N1';
        R.Name := 'stored1';
        R.Insert();
        R.Code := 'N2';
        R.Name := 'stored2';
        R.Insert();
        Log.ClearLog();
    end;

    local procedure StoredRows(): Text
    var
        R: Record "LT Y61 TC Row";
        Txt: Text;
    begin
        if R.FindSet() then
            repeat
                Txt += R.Code + '/' + R.Name + '/' + Format(R.Enabled) + ',';
            until R.Next() = 0;
        exit(Txt);
    end;

    local procedure TakeLog(): Text
    var
        Log: Record "LT Y61 Log";
    begin
        exit(Log.Take());
    end;

    [TryFunction]
    local procedure TryCard(var P: TestPage "LT Y61 TC Card"; Which: Text)
    begin
        case Which of
            'agree':
                P.Agree.Invoke();
            'rename':
                P.Rename.Invoke();
            'delete':
                P.DeleteIt.Invoke();
            'ok':
                P.OK().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure CardHandler(var P: TestPage "LT Y61 TC Card")
    var
        Ok: Boolean;
    begin
        Observer.Observe('handler open log', TakeLog());
        Observer.Observe('handler shown', P.CodeCtl.Value() + '/' + P.NameCtl.Value());
        case HandlerMode of
            'agree':
                Ok := TryCard(P, 'agree');
            'ok':
                Ok := TryCard(P, 'ok');
            'nothing':
                Ok := true;
            'rename-ok':
                begin
                    Ok := TryCard(P, 'rename');
                    Observer.Observe('handler rename ok', Format(Ok));
                    Observer.ObserveError('handler rename');
                    Observer.Observe('handler rename shown', P.CodeCtl.Value() + '/' + P.NameCtl.Value());
                    Observer.Observe('handler rename stored', StoredRows());
                    Ok := TryCard(P, 'ok');
                end;
            'delete-ok':
                begin
                    Ok := TryCard(P, 'delete');
                    Observer.Observe('handler delete ok', Format(Ok));
                    Observer.ObserveError('handler delete');
                    Observer.Observe('handler delete stored', StoredRows());
                    Ok := TryCard(P, 'ok');
                end;
        end;
        Observer.Observe('handler last ok', Format(Ok));
        Observer.ObserveError('handler last');
        Observer.Observe('handler log', TakeLog());
    end;

    [ModalPageHandler]
    procedure NavigateHandler(var P: TestPage "LT Y61 TC Navigate")
    begin
        Observer.Observe('handler open log', TakeLog());
        Observer.Observe('handler shown', P.CodeCtl.Value() + '/' + P.NameCtl.Value());
        P.Agree.Invoke();
        Observer.Observe('handler log', TakeLog());
    end;

    local procedure SetRecordRunModal(Mode: Text)
    var
        PN: Record "LT Y61 TC Row";
        R2: Record "LT Y61 TC Row";
        P: Page "LT Y61 TC Card";
    begin
        Seed();
        HandlerMode := Mode;
        PN.Get('N1');
        P.SetRecord(PN);
        Observer.Observe('action', Format(P.RunModal()));
        Observer.Observe('after log', TakeLog());
        Observer.Observe('stored', StoredRows());
        Observer.Observe('result', P.Result());
        P.GetRecord(R2);
        Observer.Observe('getrecord', R2.Code + '/' + R2.Name + '/' + Format(R2.Enabled));
        Observer.Observe('caller', PN.Code + '/' + PN.Name + '/' + Format(PN.Enabled));
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_SetRecord_RunModal_Agree()
    begin
        SetRecordRunModal('agree');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_SetRecord_RunModal_Ok()
    begin
        SetRecordRunModal('ok');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_SetRecord_RunModal_Nothing()
    begin
        SetRecordRunModal('nothing');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_PageRunModalIdRec_Rename()
    var
        PN: Record "LT Y61 TC Row";
    begin
        Seed();
        HandlerMode := 'rename-ok';
        PN.Get('N1');
        Observer.Observe('action', Format(Page.RunModal(Page::"LT Y61 TC Card", PN)));
        Observer.Observe('after log', TakeLog());
        Observer.Observe('stored', StoredRows());
        Observer.Observe('caller', PN.Code + '/' + PN.Name + '/' + Format(PN.Enabled));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_SetRecord_StoredRow_Delete()
    var
        PN: Record "LT Y61 TC Row";
        P: Page "LT Y61 TC Card";
    begin
        Seed();
        HandlerMode := 'delete-ok';
        PN.Get('N1');
        P.SetRecord(PN);
        Observer.Observe('action', Format(P.RunModal()));
        Observer.Observe('after log', TakeLog());
        Observer.Observe('stored', StoredRows());
        Observer.Observe('result', P.Result());
        Observer.Finish();
    end;

    [Test]
    procedure G617b_PageRunIdRec_TrapTestPage_CountAndStep()
    var
        PN: Record "LT Y61 TC Row";
        TP: TestPage "LT Y61 TC Card";
    begin
        Seed();
        PN.Get('N1');
        TP.Trap();
        Page.Run(Page::"LT Y61 TC Card", PN);
        Observer.Observe('open log', TakeLog());
        Observer.Observe('shown', TP.CodeCtl.Value() + '/' + TP.NameCtl.Value());
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('next log', TakeLog());
        Observer.Observe('next shown', TP.CodeCtl.Value() + '/' + TP.NameCtl.Value());
        Observer.Observe('previous', Format(TP.Previous()));
        Observer.Observe('previous shown', TP.CodeCtl.Value() + '/' + TP.NameCtl.Value());
        TP.Close();
        Observer.Observe('close log', TakeLog());
        Observer.Observe('stored', StoredRows());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('NavigateHandler')]
    procedure G617b_NavigatePage_SetRecord_RunModal_Agree()
    var
        PN: Record "LT Y61 TC Row";
        R2: Record "LT Y61 TC Row";
        P: Page "LT Y61 TC Navigate";
    begin
        Seed();
        PN.Get('N1');
        P.SetRecord(PN);
        Observer.Observe('action', Format(P.RunModal()));
        Observer.Observe('after log', TakeLog());
        Observer.Observe('stored', StoredRows());
        Observer.Observe('result', P.Result());
        P.GetRecord(R2);
        Observer.Observe('getrecord', R2.Code + '/' + R2.Name + '/' + Format(R2.Enabled));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_RecordFilteredToNoRow()
    var
        PN: Record "LT Y61 TC Row";
    begin
        Seed();
        HandlerMode := 'ok';
        PN.SetRange(Code, 'N9');
        Observer.Observe('action', Format(Page.RunModal(Page::"LT Y61 TC Card", PN)));
        Observer.Observe('after log', TakeLog());
        Observer.Observe('stored', StoredRows());
        Observer.Finish();
    end;
}
