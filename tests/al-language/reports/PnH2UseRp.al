// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-userequestpage-method
// Scope: in-scope
// Fixtures used: tables and helper of PnH1Fix.al; SingleInstance log 70580 is used only by test codeunit 70583
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed row: Report | `UseRequestPage(true)` on a report declaring `UseRequestPage = false`, and `UseRequestPage` read as a getter.
// What a Run, RunModal, Execute and RunRequestPage do after UseRequestPage(true) on a report that declares UseRequestPage = false
// (with and without a RequestPageHandler), and after UseRequestPage(false) on one that shows its page.
// BC versions: 29 (27 and 28 by CI)

codeunit 70580 "LT PnH UseRp Log"
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

report 70581 "LT PnH NoRP"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; Note)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('rp open');
        end;
    }

    trigger OnInitReport()
    begin
        L.Add('init');
    end;

    trigger OnPreReport()
    begin
        L.Add('pre note=[' + Note + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        Note: Text[20];
        L: Codeunit "LT PnH UseRp Log";
}

report 70582 "LT PnH WithRP"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT PnH Row")
        {
            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; Note)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('rp open');
        end;
    }

    trigger OnInitReport()
    begin
        L.Add('init');
    end;

    trigger OnPreReport()
    begin
        L.Add('pre note=[' + Note + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        Note: Text[20];
        L: Codeunit "LT PnH UseRp Log";
}

codeunit 70583 "LT PnH UseRp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT PnH UseRp Log";
        Helper: Codeunit "LT PnH Helper";

    local procedure Start()
    begin
        Helper.Seed();
        L.Take();
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryRunNo(var Rpt: Report "LT PnH NoRP")
    begin
        Rpt.Run();
    end;

    [TryFunction]
    local procedure TryRunModalNo(var Rpt: Report "LT PnH NoRP")
    begin
        Rpt.RunModal();
    end;

    [TryFunction]
    local procedure TryExecuteNo(var Rpt: Report "LT PnH NoRP")
    begin
        Rpt.Execute('');
    end;

    [TryFunction]
    local procedure TryParamsNo(var Rpt: Report "LT PnH NoRP"; var Params: Text)
    begin
        Params := Rpt.RunRequestPage();
    end;

    [TryFunction]
    local procedure TryRunWith(var Rpt: Report "LT PnH WithRP")
    begin
        Rpt.Run();
    end;

    [TryFunction]
    local procedure TryRunModalWith(var Rpt: Report "LT PnH WithRP")
    begin
        Rpt.RunModal();
    end;

    [TryFunction]
    local procedure TryExecuteWith(var Rpt: Report "LT PnH WithRP")
    begin
        Rpt.Execute('');
    end;

    [TryFunction]
    local procedure TryParamsWith(var Rpt: Report "LT PnH WithRP"; var Params: Text)
    begin
        Params := Rpt.RunRequestPage();
    end;

    [Test]
    procedure NoRP_UseTrue_NoHandler_Run()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH NoRP";
    begin
        Start();
        Rpt.UseRequestPage(true);
        Observer.Observe('getter', Format(Rpt.UseRequestPage()));
        Observer.Observe('run', Format(TryRunNo(Rpt)));
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Observe('getter after', Format(Rpt.UseRequestPage()));
        Observer.Expect('getter', 'Yes');
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('log', 'init;');
        Observer.Expect('getter after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure NoRP_UseTrue_NoHandler_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH NoRP";
    begin
        Start();
        Rpt.UseRequestPage(true);
        Observer.Observe('runmodal', Format(TryRunModalNo(Rpt)));
        Observer.ObserveError('runmodal');
        Observer.Observe('log', L.Take());
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('runmodal|code', 'DB:Ok');
        Observer.Expect('log', 'init;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRP_UseTrue_Execute()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH NoRP";
    begin
        Start();
        Rpt.UseRequestPage(true);
        Observer.Observe('execute', Format(TryExecuteNo(Rpt)));
        Observer.ObserveError('execute');
        Observer.Observe('log', L.Take());
        Observer.Expect('execute', 'Yes');
        Observer.Expect('execute|text', '');
        Observer.Expect('execute|code', '');
        Observer.Expect('log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRP_UseTrue_NoHandler_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH NoRP";
        Params: Text;
    begin
        Start();
        Rpt.UseRequestPage(true);
        Observer.Observe('params', Format(TryParamsNo(Rpt, Params)));
        Observer.ObserveError('params');
        Observer.Observe('params text', Params);
        Observer.Observe('log', L.Take());
        Observer.Expect('params', 'No');
        Observer.Expect('params|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('params|code', 'DB:Ok');
        Observer.Expect('params text', '');
        Observer.Expect('log', 'init;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRP_UseTrue_ThenFalse_Run()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH NoRP";
    begin
        Start();
        Rpt.UseRequestPage(true);
        Rpt.UseRequestPage(false);
        Observer.Observe('getter', Format(Rpt.UseRequestPage()));
        Observer.Observe('run', Format(TryRunNo(Rpt)));
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('getter', 'No');
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRP_Getter_PerVariable_AndAfterRun_AndClear()
    var
        Observer: Codeunit "Probe Observer";
        A: Report "LT PnH NoRP";
        B: Report "LT PnH NoRP";
    begin
        Start();
        Observer.Observe('A initial', Format(A.UseRequestPage()));
        Observer.Observe('B initial', Format(B.UseRequestPage()));
        A.UseRequestPage(true);
        Observer.Observe('A set true', Format(A.UseRequestPage()));
        Observer.Observe('B untouched', Format(B.UseRequestPage()));
        A.UseRequestPage(false);
        A.Run();
        Observer.Observe('A after run', Format(A.UseRequestPage()));
        A.UseRequestPage(true);
        Clear(A);
        Observer.Observe('A after clear', Format(A.UseRequestPage()));
        Observer.Observe('log', L.Take());
        Observer.Expect('A initial', 'No');
        Observer.Expect('B initial', 'No');
        Observer.Expect('A set true', 'Yes');
        Observer.Expect('B untouched', 'No');
        Observer.Expect('A after run', 'No');
        Observer.Expect('A after clear', 'No');
        Observer.Expect('log', 'init;init;pre note=[];row 1;row 2;row 3;post;init;init;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRP_Static_Run_RunModal_ShowNoPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"LT PnH NoRP");
        Observer.Observe('static run', L.Take());
        Report.RunModal(Report::"LT PnH NoRP");
        Observer.Observe('static runmodal', L.Take());
        Report.Run(Report::"LT PnH NoRP", false);
        Observer.Observe('static run requestpage false', L.Take());
        asserterror Report.Run(Report::"LT PnH NoRP", true);
        Observer.ObserveError('af369');
        Observer.Observe('static run requestpage true', L.Take());
        Observer.Expect('static run', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('static runmodal', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('static run requestpage false', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('af369|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af369|code', 'DB:Ok');
        Observer.Expect('static run requestpage true', 'init;');
        Observer.Verify();
    end;

    [Test]
    procedure WithRP_UseFalse_Run_RunModal_Execute()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH WithRP";
    begin
        Start();
        Rpt.UseRequestPage(false);
        Observer.Observe('run', Format(TryRunWith(Rpt)));
        Observer.ObserveError('run');
        Observer.Observe('run log', L.Take());
        Observer.Observe('runmodal', Format(TryRunModalWith(Rpt)));
        Observer.ObserveError('runmodal');
        Observer.Observe('runmodal log', L.Take());
        Observer.Observe('execute', Format(TryExecuteWith(Rpt)));
        Observer.ObserveError('execute');
        Observer.Observe('execute log', L.Take());
        Observer.Observe('getter', Format(Rpt.UseRequestPage()));
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('runmodal|code', 'DB:Ok');
        Observer.Expect('runmodal log', 'init;');
        Observer.Expect('execute', 'Yes');
        Observer.Expect('execute|text', '');
        Observer.Expect('execute|code', '');
        Observer.Expect('execute log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('getter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure WithRP_UseFalse_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH WithRP";
        Params: Text;
    begin
        Start();
        Rpt.UseRequestPage(false);
        Observer.Observe('params', Format(TryParamsWith(Rpt, Params)));
        Observer.ObserveError('params');
        Observer.Observe('params text', Params);
        Observer.Observe('log', L.Take());
        Observer.Expect('params', 'No');
        Observer.Expect('params|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('params|code', 'DB:Ok');
        Observer.Expect('params text', '');
        Observer.Expect('log', 'init;');
        Observer.Verify();
    end;

    [Test]
    procedure WithRP_NoHandler_Run_Default()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT PnH WithRP";
    begin
        Start();
        Observer.Observe('getter', Format(Rpt.UseRequestPage()));
        Observer.Observe('run', Format(TryRunWith(Rpt)));
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('getter', 'Yes');
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('log', 'init;');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Report runs and SaveAs": the static Report.RunModal(id, true / false) on a report that declares
    // UseRequestPage = false (only Report.Run(id, true) is pinned: NoRP_Static_Run_RunModal_ShowNoPage). With a RequestPageHandler for the
    // report the outcome was the same on BC 29.0 and the test then failed with 'The following UI handlers were not executed', so that form
    // is not a test here.
    [TryFunction]
    local procedure PwTryStaticRunModal(RequestWindow: Boolean)
    begin
        Report.RunModal(Report::"LT PnH NoRP", RequestWindow);
    end;

    [Test]
    procedure PW_NoRP_StaticRunModal_RequestWindow_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('runmodal true', Format(PwTryStaticRunModal(true)));
        Observer.ObserveError('runmodal true');
        Observer.Observe('runmodal true log', L.Take());
        Observer.Observe('runmodal false', Format(PwTryStaticRunModal(false)));
        Observer.ObserveError('runmodal false');
        Observer.Observe('runmodal false log', L.Take());
        Observer.Expect('runmodal true', 'No');
        Observer.Expect('runmodal true|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('runmodal true|code', 'DB:Ok');
        Observer.Expect('runmodal true log', 'init;');
        Observer.Expect('runmodal false', 'Yes');
        Observer.Expect('runmodal false|text', '');
        Observer.Expect('runmodal false|code', '');
        Observer.Expect('runmodal false log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    // Writer PW: UseRequestPage() after an Execute of a variable whose UseRequestPage was set (only a variable never set is pinned:
    // WithRP_UseFalse_Run_RunModal_Execute reads false after Execute).
    [Test]
    procedure PW_Getter_AfterExecute_OfASetVariable()
    var
        Observer: Codeunit "Probe Observer";
        NoTrue: Report "LT PnH NoRP";
        NoFalse: Report "LT PnH NoRP";
        NoNever: Report "LT PnH NoRP";
        WithTrue: Report "LT PnH WithRP";
        WithFalse: Report "LT PnH WithRP";
        WithNever: Report "LT PnH WithRP";
    begin
        Start();
        NoTrue.UseRequestPage(true);
        Observer.Observe('noRP true execute', Format(TryExecuteNo(NoTrue)));
        Observer.ObserveError('noRP true execute');
        Observer.Observe('noRP true getter', Format(NoTrue.UseRequestPage()));
        Observer.Observe('noRP true log', L.Take());
        NoFalse.UseRequestPage(false);
        Observer.Observe('noRP false execute', Format(TryExecuteNo(NoFalse)));
        Observer.Observe('noRP false getter', Format(NoFalse.UseRequestPage()));
        Observer.Observe('noRP false log', L.Take());
        Observer.Observe('noRP never execute', Format(TryExecuteNo(NoNever)));
        Observer.Observe('noRP never getter', Format(NoNever.UseRequestPage()));
        Observer.Observe('noRP never log', L.Take());
        WithTrue.UseRequestPage(true);
        Observer.Observe('withRP true execute', Format(TryExecuteWith(WithTrue)));
        Observer.ObserveError('withRP true execute');
        Observer.Observe('withRP true getter', Format(WithTrue.UseRequestPage()));
        Observer.Observe('withRP true log', L.Take());
        WithFalse.UseRequestPage(false);
        Observer.Observe('withRP false execute', Format(TryExecuteWith(WithFalse)));
        Observer.Observe('withRP false getter', Format(WithFalse.UseRequestPage()));
        Observer.Observe('withRP false log', L.Take());
        Observer.Observe('withRP never execute', Format(TryExecuteWith(WithNever)));
        Observer.Observe('withRP never getter', Format(WithNever.UseRequestPage()));
        Observer.Observe('withRP never log', L.Take());
        Observer.Expect('noRP true execute', 'Yes');
        Observer.Expect('noRP true execute|text', '');
        Observer.Expect('noRP true execute|code', '');
        Observer.Expect('noRP true getter', 'No');
        Observer.Expect('noRP true log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('noRP false execute', 'Yes');
        Observer.Expect('noRP false getter', 'No');
        Observer.Expect('noRP false log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('noRP never execute', 'Yes');
        Observer.Expect('noRP never getter', 'No');
        Observer.Expect('noRP never log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('withRP true execute', 'Yes');
        Observer.Expect('withRP true execute|text', '');
        Observer.Expect('withRP true execute|code', '');
        Observer.Expect('withRP true getter', 'No');
        Observer.Expect('withRP true log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('withRP false execute', 'Yes');
        Observer.Expect('withRP false getter', 'No');
        Observer.Expect('withRP false log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Expect('withRP never execute', 'Yes');
        Observer.Expect('withRP never getter', 'No');
        Observer.Expect('withRP never log', 'init;pre note=[];row 1;row 2;row 3;post;');
        Observer.Verify();
    end;
}
