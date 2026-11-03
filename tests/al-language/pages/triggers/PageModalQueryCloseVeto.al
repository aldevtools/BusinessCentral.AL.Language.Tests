// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained page 70865, codeunits 70866 and 70867
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a modal page whose OnQueryClosePage returns false (always, only for OK, only for Cancel) while the handler closes it with OK, Cancel or Close: the RunModal outcome (result or error text and code), how often the trigger and OnClosePage ran, the CloseAction it saw, and whether a second Close in the handler is refused.
// BC versions: 29 (27 and 28 by CI)

page 70865 "LT QCVM Veto Modal"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'LT QCVM Veto Modal';

    layout
    {
        area(Content)
        {
            field(Marker; MarkerVar)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Probe: Codeunit "LT QCVM Probe";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Probe.Answer(CloseAction));
    end;

    trigger OnClosePage()
    begin
        Probe.NoteClosePage();
    end;
}

codeunit 70866 "LT QCVM Probe"
{
    SingleInstance = true;

    var
        Mode: Integer;
        QueryCount: Integer;
        CloseCount: Integer;
        Seen: Text;

    procedure Reset(NewMode: Integer)
    begin
        Mode := NewMode;
        QueryCount := 0;
        CloseCount := 0;
        Seen := '';
    end;

    procedure Answer(CloseAction: Action): Boolean
    begin
        QueryCount += 1;
        Seen += Format(CloseAction) + ';';
        case Mode of
            1:
                exit(false);
            2:
                exit(not (CloseAction in [Action::OK, Action::LookupOK]));
            3:
                exit(not (CloseAction in [Action::Cancel, Action::LookupCancel]));
        end;
        exit(true);
    end;

    procedure NoteClosePage()
    begin
        CloseCount += 1;
    end;

    procedure Summary(): Text
    begin
        exit('query=' + Format(QueryCount) + ' close=' + Format(CloseCount) + ' seen=' + Seen);
    end;
}

codeunit 70867 "LT Modal Close Veto"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT QCVM Probe";
        HandlerNote: Text;
        LookupFlag: Boolean;
        RpHandlerMode: Integer;

    [TryFunction]
    local procedure TryRunModal(var Result: Text)
    var
        Modal: Page "LT QCVM Veto Modal";
    begin
        Modal.LookupMode(LookupFlag);
        Result := Format(Modal.RunModal());
    end;

    local procedure Run(Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRunModal(Result);
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_result', Result);
        Observer.Observe(Name + '_err', GetLastErrorText());
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_probe', Probe.Summary());
        Observer.Observe(Name + '_handler', HandlerNote);
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_HandlerOk_AllowedControl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(0);
        HandlerNote := '';
        Run('allow_ok', Observer);
        Observer.Expect('allow_ok_ok', 'Yes');
        Observer.Expect('allow_ok_result', 'OK');
        Observer.Expect('allow_ok_err', '');
        Observer.Expect('allow_ok_code', '');
        Observer.Expect('allow_ok_probe', 'query=1 close=1 seen=OK;');
        Observer.Expect('allow_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_HandlerOk_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_ok', Observer);
        Observer.Expect('veto_ok_ok', 'Yes');
        Observer.Expect('veto_ok_result', 'None');
        Observer.Expect('veto_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_ok_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('veto_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupCancelHandler')]
    procedure Modal_HandlerCancel_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        LookupFlag := true;
        Run('veto_cancel', Observer);
        LookupFlag := false;
        Observer.Expect('veto_cancel_ok', 'Yes');
        Observer.Expect('veto_cancel_result', 'None');
        Observer.Expect('veto_cancel_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_cancel_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_cancel_probe', 'query=2 close=0 seen=LookupCancel;LookupCancel;');
        Observer.Expect('veto_cancel_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CloseHandler')]
    procedure Modal_HandlerClose_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_close', Observer);
        Observer.Expect('veto_close_ok', 'No');
        Observer.Expect('veto_close_result', '');
        Observer.Expect('veto_close_err', 'The RunModal procedure could not close the page 70865 as it has already been closed.');
        Observer.Expect('veto_close_code', 'TestCodeUnit');
        Observer.Expect('veto_close_probe', 'query=1 close=0 seen=OK;');
        Observer.Expect('veto_close_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_HandlerOk_VetoOnlyOk()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(2);
        HandlerNote := '';
        Run('veto_only_ok', Observer);
        Observer.Expect('veto_only_ok_ok', 'Yes');
        Observer.Expect('veto_only_ok_result', 'None');
        Observer.Expect('veto_only_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_only_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_only_ok_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('veto_only_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupCancelHandler')]
    procedure Modal_HandlerCancel_VetoOnlyOk_Closes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(2);
        HandlerNote := '';
        LookupFlag := true;
        Run('veto_only_ok_cancel', Observer);
        LookupFlag := false;
        Observer.Expect('veto_only_ok_cancel_ok', 'Yes');
        Observer.Expect('veto_only_ok_cancel_result', 'LookupCancel');
        Observer.Expect('veto_only_ok_cancel_err', '');
        Observer.Expect('veto_only_ok_cancel_code', '');
        Observer.Expect('veto_only_ok_cancel_probe', 'query=1 close=1 seen=LookupCancel;');
        Observer.Expect('veto_only_ok_cancel_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupCancelHandler')]
    procedure Modal_HandlerCancel_VetoOnlyCancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(3);
        HandlerNote := '';
        LookupFlag := true;
        Run('veto_only_cancel', Observer);
        LookupFlag := false;
        Observer.Expect('veto_only_cancel_ok', 'Yes');
        Observer.Expect('veto_only_cancel_result', 'None');
        Observer.Expect('veto_only_cancel_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_only_cancel_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_only_cancel_probe', 'query=2 close=0 seen=LookupCancel;LookupCancel;');
        Observer.Expect('veto_only_cancel_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkThenCloseHandler')]
    procedure Modal_HandlerOkThenClose_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_ok_then_close', Observer);
        Observer.Expect('veto_ok_then_close_ok', 'No');
        Observer.Expect('veto_ok_then_close_result', '');
        Observer.Expect('veto_ok_then_close_err', 'The RunModal procedure could not close the page 70865 as it has already been closed.');
        Observer.Expect('veto_ok_then_close_code', 'TestCodeUnit');
        Observer.Expect('veto_ok_then_close_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('veto_ok_then_close_handler', 'marker=OPENED after_ok_marker=OPENED close_returned');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoInvokeHandler')]
    procedure Modal_HandlerDoesNothing_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('veto_noinvoke', Observer);
        Observer.Expect('veto_noinvoke_ok', 'Yes');
        Observer.Expect('veto_noinvoke_result', 'None');
        Observer.Expect('veto_noinvoke_err', 'The page cannot be closed at this time.');
        Observer.Expect('veto_noinvoke_code', 'FormCloseNotAllowed');
        Observer.Expect('veto_noinvoke_probe', 'query=1 close=0 seen=OK;');
        Observer.Expect('veto_noinvoke_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupOkHandler')]
    procedure Modal_Lookup_HandlerLookupOk_VetoAlways()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        LookupFlag := true;
        Run('lookup_veto_ok', Observer);
        LookupFlag := false;
        Observer.Expect('lookup_veto_ok_ok', 'Yes');
        Observer.Expect('lookup_veto_ok_result', 'None');
        Observer.Expect('lookup_veto_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('lookup_veto_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('lookup_veto_ok_probe', 'query=2 close=0 seen=LookupOK;LookupCancel;');
        Observer.Expect('lookup_veto_ok_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Modal_AfterVetoedRun_NextRunIsClean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.Reset(1);
        HandlerNote := '';
        Run('first', Observer);
        Probe.Reset(0);
        HandlerNote := '';
        Run('second_allow', Observer);
        Observer.Expect('first_ok', 'Yes');
        Observer.Expect('first_result', 'None');
        Observer.Expect('first_err', 'The page cannot be closed at this time.');
        Observer.Expect('first_code', 'FormCloseNotAllowed');
        Observer.Expect('first_probe', 'query=2 close=0 seen=OK;OK;');
        Observer.Expect('first_handler', 'marker=OPENED');
        Observer.Expect('second_allow_ok', 'Yes');
        Observer.Expect('second_allow_result', 'OK');
        Observer.Expect('second_allow_err', '');
        Observer.Expect('second_allow_code', '');
        Observer.Expect('second_allow_probe', 'query=1 close=1 seen=OK;');
        Observer.Expect('second_allow_handler', 'marker=OPENED');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure OkHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupCancelHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupOkHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CloseHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.Close();
    end;

    [ModalPageHandler]
    procedure NoInvokeHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
    end;

    [ModalPageHandler]
    procedure OkThenCloseHandler(var Modal: TestPage "LT QCVM Veto Modal")
    begin
        HandlerNote := 'marker=' + Modal.Marker.Value();
        Modal.OK().Invoke();
        HandlerNote += ' after_ok_marker=' + TryMarker(Modal);
        Modal.Close();
        HandlerNote += ' close_returned';
    end;

    local procedure TryMarker(var Modal: TestPage "LT QCVM Veto Modal"): Text
    begin
        exit(Modal.Marker.Value());
    end;

    // Writer RP (al-runner issue 5762): the same veto on pages WITH parts: a List with a FactBox CardPart (SubPageLink), a Card
    // with a ListPart in its content, and a List whose host allows the close but whose FactBox part's OnQueryClosePage returns
    // false. The host page counts its own OnQueryClosePage calls (read through the page variable after RunModal, the reporter's
    // shape); "LT RP Veto Log" records every trigger of host and part in order.
    [TryFunction]
    local procedure RpTryRun(Which: Integer; var Result: Text; var HostCount: Integer)
    var
        VetoList: Page "LT RP Veto List";
        VetoCard: Page "LT RP Veto Part Card";
        PartVeto: Page "LT RP Veto By Part";
    begin
        case Which of
            1:
                begin
                    Result := Format(VetoList.RunModal());
                    HostCount := VetoList.GetQueryCloseCount();
                end;
            2:
                begin
                    Result := Format(VetoCard.RunModal());
                    HostCount := VetoCard.GetQueryCloseCount();
                end;
            3:
                begin
                    Result := Format(PartVeto.RunModal());
                    HostCount := PartVeto.GetQueryCloseCount();
                end;
        end;
    end;

    local procedure RpRun(Name: Text; Which: Integer; HostVeto: Boolean; PartVeto: Boolean; HandlerMode: Integer; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT RP Veto Row";
        RpLog: Codeunit "LT RP Veto Log";
        Result: Text;
        HostCount: Integer;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Alpha';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Bravo';
        Row.Insert();
        RpLog.Reset(HostVeto, PartVeto);
        RpHandlerMode := HandlerMode;
        HostCount := -1;
        ClearLastError();
        Ok := RpTryRun(Which, Result, HostCount);
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_result', Result);
        Observer.Observe(Name + '_err', GetLastErrorText());
        Observer.Observe(Name + '_code', GetLastErrorCode());
        Observer.Observe(Name + '_hostcount', Format(HostCount));
        Observer.Observe(Name + '_log', RpLog.Dump());
    end;

    [Test]
    [HandlerFunctions('RpVetoListHandler')]
    procedure RP_ListWithFactBox_HandlerDoesNothing_HostVetoes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RpRun('noinvoke', 1, true, false, 0, Observer);
        Observer.Expect('noinvoke_ok', 'Yes');
        Observer.Expect('noinvoke_result', 'None');
        Observer.Expect('noinvoke_err', 'The page cannot be closed at this time.');
        Observer.Expect('noinvoke_code', 'FormCloseNotAllowed');
        Observer.Expect('noinvoke_hostcount', '1');
        Observer.Expect('noinvoke_log', 'host OnOpenPage;part OnOpenPage;part OnQueryClosePage(None);host OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RpVetoListHandler')]
    procedure RP_ListWithFactBox_HandlerOk_HostVetoes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RpRun('ok', 1, true, false, 1, Observer);
        Observer.Expect('ok_ok', 'Yes');
        Observer.Expect('ok_result', 'None');
        Observer.Expect('ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('ok_code', 'FormCloseNotAllowed');
        Observer.Expect('ok_hostcount', '2');
        Observer.Expect('ok_log', 'host OnOpenPage;part OnOpenPage;part OnQueryClosePage(None);host OnQueryClosePage(OK);part OnQueryClosePage(None);host OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RpVetoListHandler')]
    procedure RP_ListWithFactBox_HandlerCancel_HostVetoes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RpRun('cancel', 1, true, false, 2, Observer);
        Observer.Expect('cancel_ok', 'No');
        Observer.Expect('cancel_result', '');
        Observer.Expect('cancel_err', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('cancel_code', 'TestActionNotFound');
        Observer.Expect('cancel_hostcount', '-1');
        Observer.Expect('cancel_log', 'host OnOpenPage;part OnOpenPage;part OnQueryClosePage(None);host OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RpVetoListHandler')]
    procedure RP_ListWithFactBox_HandlerOk_HostAllows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RpRun('allow_ok', 1, false, false, 1, Observer);
        RpRun('allow_noinvoke', 1, false, false, 0, Observer);
        Observer.Expect('allow_ok_ok', 'Yes');
        Observer.Expect('allow_ok_result', 'OK');
        Observer.Expect('allow_ok_err', '');
        Observer.Expect('allow_ok_code', '');
        Observer.Expect('allow_ok_hostcount', '1');
        Observer.Expect('allow_ok_log', 'host OnOpenPage;part OnOpenPage;part OnQueryClosePage(None);host OnQueryClosePage(OK);part OnClosePage;host OnClosePage');
        Observer.Expect('allow_noinvoke_ok', 'Yes');
        Observer.Expect('allow_noinvoke_result', 'OK');
        Observer.Expect('allow_noinvoke_err', '');
        Observer.Expect('allow_noinvoke_code', '');
        Observer.Expect('allow_noinvoke_hostcount', '1');
        Observer.Expect('allow_noinvoke_log', 'host OnOpenPage;part OnOpenPage;part OnQueryClosePage(None);host OnQueryClosePage(OK);part OnClosePage;host OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RpVetoCardHandler')]
    procedure RP_CardWithListPart_HostVetoes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RpRun('card_noinvoke', 2, true, false, 0, Observer);
        RpRun('card_ok', 2, true, false, 1, Observer);
        Observer.Expect('card_noinvoke_ok', 'Yes');
        Observer.Expect('card_noinvoke_result', 'None');
        Observer.Expect('card_noinvoke_err', 'The page cannot be closed at this time.');
        Observer.Expect('card_noinvoke_code', 'FormCloseNotAllowed');
        Observer.Expect('card_noinvoke_hostcount', '1');
        Observer.Expect('card_noinvoke_log', 'lines OnQueryClosePage(None);card OnQueryClosePage(OK)');
        Observer.Expect('card_ok_ok', 'Yes');
        Observer.Expect('card_ok_result', 'None');
        Observer.Expect('card_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('card_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('card_ok_hostcount', '2');
        Observer.Expect('card_ok_log', 'lines OnQueryClosePage(None);card OnQueryClosePage(OK);lines OnQueryClosePage(None);card OnQueryClosePage(OK)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RpVetoByPartHandler')]
    procedure RP_ListWithFactBox_PartVetoes_HostAllows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RpRun('part_noinvoke', 3, false, true, 0, Observer);
        RpRun('part_ok', 3, false, true, 1, Observer);
        Observer.Expect('part_noinvoke_ok', 'Yes');
        Observer.Expect('part_noinvoke_result', 'None');
        Observer.Expect('part_noinvoke_err', 'The page cannot be closed at this time.');
        Observer.Expect('part_noinvoke_code', 'FormCloseNotAllowed');
        Observer.Expect('part_noinvoke_hostcount', '0');
        Observer.Expect('part_noinvoke_log', 'part OnOpenPage;part OnQueryClosePage(None)');
        Observer.Expect('part_ok_ok', 'Yes');
        Observer.Expect('part_ok_result', 'None');
        Observer.Expect('part_ok_err', 'The page cannot be closed at this time.');
        Observer.Expect('part_ok_code', 'FormCloseNotAllowed');
        Observer.Expect('part_ok_hostcount', '0');
        Observer.Expect('part_ok_log', 'part OnOpenPage;part OnQueryClosePage(None);part OnQueryClosePage(None)');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure RpVetoListHandler(var VetoList: TestPage "LT RP Veto List")
    begin
        case RpHandlerMode of
            1:
                VetoList.OK().Invoke();
            2:
                VetoList.Cancel().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure RpVetoCardHandler(var VetoCard: TestPage "LT RP Veto Part Card")
    begin
        if RpHandlerMode = 1 then
            VetoCard.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure RpVetoByPartHandler(var PartVeto: TestPage "LT RP Veto By Part")
    begin
        if RpHandlerMode = 1 then
            PartVeto.OK().Invoke();
    end;

}

// Writer RP (al-runner issue 5762): pages with parts whose OnQueryClosePage refuses the close. Used only by codeunit 70867.
table 88391 "LT RP Veto Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 88396 "LT RP Veto Log"
{
    SingleInstance = true;

    var
        HostVeto: Boolean;
        PartVeto: Boolean;
        Entries: Text;

    procedure Reset(NewHostVeto: Boolean; NewPartVeto: Boolean)
    begin
        HostVeto := NewHostVeto;
        PartVeto := NewPartVeto;
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure HostAnswer(Who: Text; CloseAction: Action): Boolean
    begin
        Add(Who + ' OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(not HostVeto);
    end;

    procedure PartAnswer(Who: Text; CloseAction: Action): Boolean
    begin
        Add(Who + ' OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(not PartVeto);
    end;

    procedure Dump(): Text
    begin
        exit(Entries);
    end;
}

page 88392 "LT RP Veto FactBox"
{
    PageType = CardPart;
    SourceTable = "LT RP Veto Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        RpLog.Add('part OnOpenPage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        exit(RpLog.PartAnswer('part', CloseAction));
    end;

    trigger OnClosePage()
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        RpLog.Add('part OnClosePage');
    end;
}

page 88393 "LT RP Veto List"
{
    PageType = List;
    SourceTable = "LT RP Veto Row";
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT RP Veto FactBox")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnOpenPage()
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        RpLog.Add('host OnOpenPage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        QueryCloseCount += 1;
        exit(RpLog.HostAnswer('host', CloseAction));
    end;

    trigger OnClosePage()
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        RpLog.Add('host OnClosePage');
    end;

    var
        QueryCloseCount: Integer;

    procedure GetQueryCloseCount(): Integer
    begin
        exit(QueryCloseCount);
    end;
}

page 88394 "LT RP Veto Lines"
{
    PageType = ListPart;
    SourceTable = "LT RP Veto Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        exit(RpLog.PartAnswer('lines', CloseAction));
    end;

    trigger OnClosePage()
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        RpLog.Add('lines OnClosePage');
    end;
}

page 88395 "LT RP Veto Part Card"
{
    PageType = Card;
    SourceTable = "LT RP Veto Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            part(Lines; "LT RP Veto Lines")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        QueryCloseCount += 1;
        exit(RpLog.HostAnswer('card', CloseAction));
    end;

    trigger OnClosePage()
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        RpLog.Add('card OnClosePage');
    end;

    var
        QueryCloseCount: Integer;

    procedure GetQueryCloseCount(): Integer
    begin
        exit(QueryCloseCount);
    end;
}

page 88397 "LT RP Veto By Part"
{
    PageType = List;
    SourceTable = "LT RP Veto Row";
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Details; "LT RP Veto FactBox")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        QueryCloseCount += 1;
        exit(RpLog.HostAnswer('host', CloseAction));
    end;

    trigger OnClosePage()
    var
        RpLog: Codeunit "LT RP Veto Log";
    begin
        RpLog.Add('host OnClosePage');
    end;

    var
        QueryCloseCount: Integer;

    procedure GetQueryCloseCount(): Integer
    begin
        exit(QueryCloseCount);
    end;
}
