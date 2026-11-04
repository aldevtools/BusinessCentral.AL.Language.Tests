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
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): SetRecord of a stored record + RunModal opens the temporary Card or NavigatePage EMPTY
//   (OnOpenPage sees the record's fields but temp=Yes, count 0, the page shows a blank row); an action's Rec.Modify or Rec.Delete then
//   raises 'The LT Y61 TC Row does not exist. Identification fields and values: Code=''' and nothing stored changes. Page.Run(Id, Rec) and
//   Page.RunModal(Id, Rec) make Rec NOT temporary (temp=No, count 2): the stored row is shown, Next walks the table, Modify writes to the
//   database and the caller's record holds the change. A record filtered to no row opens on no row; OK is not found there.
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
        ClearLastError();
        Observer.Discard();
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

    [TryFunction]
    local procedure TryNavigateAgree(var P: TestPage "LT Y61 TC Navigate")
    begin
        P.Agree.Invoke();
    end;

    [ModalPageHandler]
    procedure NavigateHandler(var P: TestPage "LT Y61 TC Navigate")
    begin
        Observer.Observe('handler open log', TakeLog());
        Observer.Observe('handler shown', P.CodeCtl.Value() + '/' + P.NameCtl.Value());
        Observer.Observe('handler agree ok', Format(TryNavigateAgree(P)));
        Observer.ObserveError('handler agree');
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
        Observer.Expect('handler open log', 'open N1/stored1/temp=Yes/count=0');
        Observer.Expect('handler shown', '/');
        Observer.Expect('handler last ok', 'No');
        Observer.Expect('handler last|text', 'The LT Y61 TC Row does not exist. Identification fields and values: Code=''''');
        Observer.Expect('handler last|code', 'TestWrapped:CSideRecordNotFound');
        Observer.Expect('handler log', 'act agree');
        Observer.Expect('action', 'OK');
        Observer.Expect('after log', '');
        Observer.Expect('stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Expect('result', '//Yes/count=0');
        Observer.Expect('getrecord', '//Yes');
        Observer.Expect('caller', 'N1/stored1/No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_SetRecord_RunModal_Ok()
    begin
        SetRecordRunModal('ok');
        Observer.Expect('handler open log', 'open N1/stored1/temp=Yes/count=0');
        Observer.Expect('handler shown', '/');
        Observer.Expect('handler last ok', 'Yes');
        Observer.Expect('handler last|text', '');
        Observer.Expect('handler last|code', '');
        Observer.Expect('handler log', '');
        Observer.Expect('action', 'OK');
        Observer.Expect('after log', '');
        Observer.Expect('stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Expect('result', '//No/count=0');
        Observer.Expect('getrecord', '//No');
        Observer.Expect('caller', 'N1/stored1/No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure G617b_SetRecord_RunModal_Nothing()
    begin
        SetRecordRunModal('nothing');
        Observer.Expect('handler open log', 'open N1/stored1/temp=Yes/count=0');
        Observer.Expect('handler shown', '/');
        Observer.Expect('handler last ok', 'Yes');
        Observer.Expect('handler last|text', '');
        Observer.Expect('handler last|code', '');
        Observer.Expect('handler log', '');
        Observer.Expect('action', 'OK');
        Observer.Expect('after log', '');
        Observer.Expect('stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Expect('result', '//No/count=0');
        Observer.Expect('getrecord', '//No');
        Observer.Expect('caller', 'N1/stored1/No');
        Observer.Verify();
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
        Observer.Expect('handler open log', 'open N1/stored1/temp=No/count=2;agr N1/stored1');
        Observer.Expect('handler shown', 'N1/stored1');
        Observer.Expect('handler rename ok', 'Yes');
        Observer.Expect('handler rename|text', '');
        Observer.Expect('handler rename|code', '');
        Observer.Expect('handler rename shown', 'N1/renamed');
        Observer.Expect('handler rename stored', 'N1/renamed/No,N2/stored2/No,');
        Observer.Expect('handler last ok', 'Yes');
        Observer.Expect('handler last|text', '');
        Observer.Expect('handler last|code', '');
        Observer.Expect('handler log', 'agr N1/stored1;act rename;agr N1/renamed;agr N1/renamed');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('after log', '');
        Observer.Expect('stored', 'N1/renamed/No,N2/stored2/No,');
        Observer.Expect('caller', 'N1/renamed/No');
        Observer.Verify();
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
        Observer.Expect('handler open log', 'open N1/stored1/temp=Yes/count=0');
        Observer.Expect('handler shown', '/');
        Observer.Expect('handler delete ok', 'No');
        Observer.Expect('handler delete|text', 'The LT Y61 TC Row does not exist. Identification fields and values: Code=''''');
        Observer.Expect('handler delete|code', 'TestWrapped:CSideRecordNotFound');
        Observer.Expect('handler delete stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Expect('handler last ok', 'Yes');
        Observer.Expect('handler last|text', '');
        Observer.Expect('handler last|code', '');
        Observer.Expect('handler log', 'act delete');
        Observer.Expect('action', 'OK');
        Observer.Expect('after log', '');
        Observer.Expect('stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Expect('result', '//No/count=0');
        Observer.Verify();
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
        Observer.Expect('open log', 'open N1/stored1/temp=No/count=2;agr N1/stored1');
        Observer.Expect('shown', 'N1/stored1');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next log', 'agr N2/stored2');
        Observer.Expect('next shown', 'N2/stored2');
        Observer.Expect('previous', 'Yes');
        Observer.Expect('previous shown', 'N1/stored1');
        Observer.Expect('close log', 'agr N1/stored1');
        Observer.Expect('stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Verify();
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
        Observer.Expect('handler open log', 'open N1/stored1/temp=Yes/count=0');
        Observer.Expect('handler shown', '/');
        Observer.Expect('handler agree ok', 'No');
        Observer.Expect('handler agree|text', 'The LT Y61 TC Row does not exist. Identification fields and values: Code=''''');
        Observer.Expect('handler agree|code', 'TestWrapped:CSideRecordNotFound');
        Observer.Expect('handler log', 'act agree');
        Observer.Expect('action', 'OK');
        Observer.Expect('after log', '');
        Observer.Expect('stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Expect('result', '//Yes/count=0');
        Observer.Expect('getrecord', '//Yes');
        Observer.Verify();
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
        Observer.Expect('handler open log', 'open //temp=No/count=0');
        Observer.Expect('handler shown', '/');
        Observer.Expect('handler last ok', 'No');
        Observer.Expect('handler last|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('handler last|code', 'TestActionNotFound');
        Observer.Expect('handler log', '');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('after log', '');
        Observer.Expect('stored', 'N1/stored1/No,N2/stored2/No,');
        Observer.Verify();
    end;
}
