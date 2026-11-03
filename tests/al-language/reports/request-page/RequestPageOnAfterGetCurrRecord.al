// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-request-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained log 72765, report 72766, test codeunit 72767
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: the request page trigger OnAfterGetCurrRecord may not compile on a report request page; this file is separate so only it drops.
// Facts: Order of the request page trigger OnAfterGetCurrRecord against OnOpenPage, field validation and closing, for OK and Cancel.
codeunit 72765 "LT RP CurrRec Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Count(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        if (Index < 1) or (Index > Entries.Count()) then
            exit('<none>');
        exit(Entries.Get(Index));
    end;

    var
        Entries: List of [Text];
}

report 72766 "LT RP CurrRec Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            trigger OnAfterGetRecord()
            begin
                Trace.Add('report Row.OnAfterGetRecord ' + Format(Row.Number));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount';

                    trigger OnValidate()
                    begin
                        Trace.Add('rp Amount.OnValidate ' + Format(Amount));
                    end;
                }
                field(Note; Note)
                {
                    ApplicationArea = All;
                    Caption = 'Note';
                }
            }
        }

        trigger OnOpenPage()
        begin
            Trace.Add('rp OnOpenPage');
        end;

        trigger OnAfterGetCurrRecord()
        begin
            Trace.Add('rp OnAfterGetCurrRecord');
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Trace.Add('rp OnQueryClosePage ' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            Trace.Add('rp OnClosePage');
        end;
    }

    trigger OnPreReport()
    begin
        Trace.Add('report OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Trace.Add('report OnPostReport');
    end;

    var
        Trace: Codeunit "LT RP CurrRec Log";
        Amount: Integer;
        Note: Text[30];
}

codeunit 72767 "LT RP CurrRec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Trace: Codeunit "LT RP CurrRec Log";

    [Test]
    [HandlerFunctions('OkOnlyHandler')]
    procedure P195_RequestPage_OpenThenOk_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Trace.Reset();
        Commit();
        Report.Run(Report::"LT RP CurrRec Rpt");
        DumpTrace(Observer);
        Observer.Expect('count', '9');
        Observer.Expect('e1', 'rp OnOpenPage');
        Observer.Expect('e2', 'rp OnAfterGetCurrRecord');
        Observer.Expect('e3', 'handler opened');
        Observer.Expect('e4', 'rp OnQueryClosePage OK');
        Observer.Expect('e5', 'rp OnClosePage');
        Observer.Expect('e6', 'report OnPreReport');
        Observer.Expect('e7', 'report Row.OnAfterGetRecord 1');
        Observer.Expect('e8', 'report Row.OnAfterGetRecord 2');
        Observer.Expect('e9', 'report OnPostReport');
        Observer.Expect('e10', '<none>');
        Observer.Expect('e11', '<none>');
        Observer.Expect('e12', '<none>');
        Observer.Expect('e13', '<none>');
        Observer.Expect('e14', '<none>');
        Observer.Expect('e15', '<none>');
        Observer.Expect('e16', '<none>');
        Observer.Expect('e17', '<none>');
        Observer.Expect('e18', '<none>');
        Observer.Expect('e19', '<none>');
        Observer.Expect('e20', '<none>');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FieldChangeHandler')]
    procedure P195_RequestPage_FieldChanges_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Trace.Reset();
        Commit();
        Report.Run(Report::"LT RP CurrRec Rpt");
        DumpTrace(Observer);
        Observer.Expect('count', '14');
        Observer.Expect('e1', 'rp OnOpenPage');
        Observer.Expect('e2', 'rp OnAfterGetCurrRecord');
        Observer.Expect('e3', 'handler opened');
        Observer.Expect('e4', 'rp Amount.OnValidate 5');
        Observer.Expect('e5', 'handler after Amount=5');
        Observer.Expect('e6', 'handler after Note');
        Observer.Expect('e7', 'rp Amount.OnValidate 7');
        Observer.Expect('e8', 'handler after Amount=7');
        Observer.Expect('e9', 'rp OnQueryClosePage OK');
        Observer.Expect('e10', 'rp OnClosePage');
        Observer.Expect('e11', 'report OnPreReport');
        Observer.Expect('e12', 'report Row.OnAfterGetRecord 1');
        Observer.Expect('e13', 'report Row.OnAfterGetRecord 2');
        Observer.Expect('e14', 'report OnPostReport');
        Observer.Expect('e15', '<none>');
        Observer.Expect('e16', '<none>');
        Observer.Expect('e17', '<none>');
        Observer.Expect('e18', '<none>');
        Observer.Expect('e19', '<none>');
        Observer.Expect('e20', '<none>');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure P195_RequestPage_Cancel_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Trace.Reset();
        Commit();
        Report.Run(Report::"LT RP CurrRec Rpt");
        DumpTrace(Observer);
        Observer.Expect('count', '6');
        Observer.Expect('e1', 'rp OnOpenPage');
        Observer.Expect('e2', 'rp OnAfterGetCurrRecord');
        Observer.Expect('e3', 'handler opened');
        Observer.Expect('e4', 'rp OnAfterGetCurrRecord');
        Observer.Expect('e5', 'rp OnQueryClosePage Cancel');
        Observer.Expect('e6', 'rp OnClosePage');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Expect('e11', '<none>');
        Observer.Expect('e12', '<none>');
        Observer.Expect('e13', '<none>');
        Observer.Expect('e14', '<none>');
        Observer.Expect('e15', '<none>');
        Observer.Expect('e16', '<none>');
        Observer.Expect('e17', '<none>');
        Observer.Expect('e18', '<none>');
        Observer.Expect('e19', '<none>');
        Observer.Expect('e20', '<none>');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkOnlyHandler(var RequestPage: TestRequestPage "LT RP CurrRec Rpt")
    begin
        Trace.Add('handler opened');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure FieldChangeHandler(var RequestPage: TestRequestPage "LT RP CurrRec Rpt")
    begin
        Trace.Add('handler opened');
        RequestPage.Amount.SetValue(5);
        Trace.Add('handler after Amount=5');
        RequestPage.Note.SetValue('x');
        Trace.Add('handler after Note');
        RequestPage.Amount.SetValue(7);
        Trace.Add('handler after Amount=7');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RequestPage: TestRequestPage "LT RP CurrRec Rpt")
    begin
        Trace.Add('handler opened');
        RequestPage.Cancel().Invoke();
    end;

    local procedure DumpTrace(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        Observer.Observe('count', Format(Trace.Count()));
        for I := 1 to 20 do
            Observer.Observe('e' + Format(I), Trace.Get(I));
    end;
}
