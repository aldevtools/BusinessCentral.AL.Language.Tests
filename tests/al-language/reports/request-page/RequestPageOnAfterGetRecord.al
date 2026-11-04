// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-request-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained log 72768, report 72769, test codeunit 72770
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: the request page trigger OnAfterGetRecord may not compile on a report request page; this file is separate so only it drops.
// Facts: Whether and when the request page trigger OnAfterGetRecord runs for a data item report request page, against OnOpenPage, field validation and closing.
codeunit 72768 "LT RP GetRec Log"
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

report 72769 "LT RP GetRec Rpt"
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

        trigger OnAfterGetRecord()
        begin
            Trace.Add('rp OnAfterGetRecord');
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
        Trace: Codeunit "LT RP GetRec Log";
        Amount: Integer;
        Note: Text[30];
}

codeunit 72770 "LT RP GetRec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Trace: Codeunit "LT RP GetRec Log";

    [Test]
    [HandlerFunctions('OkOnlyHandler')]
    procedure P195_RequestPage_OpenThenOk_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Trace.Reset();
        Commit();
        Report.Run(Report::"LT RP GetRec Rpt");
        DumpTrace(Observer);
        Observer.Expect('count', '8');
        Observer.Expect('e1', 'rp OnOpenPage');
        Observer.Expect('e2', 'handler opened');
        Observer.Expect('e3', 'rp OnQueryClosePage OK');
        Observer.Expect('e4', 'rp OnClosePage');
        Observer.Expect('e5', 'report OnPreReport');
        Observer.Expect('e6', 'report Row.OnAfterGetRecord 1');
        Observer.Expect('e7', 'report Row.OnAfterGetRecord 2');
        Observer.Expect('e8', 'report OnPostReport');
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

    [Test]
    [HandlerFunctions('FieldChangeHandler')]
    procedure P195_RequestPage_FieldChanges_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Trace.Reset();
        Commit();
        Report.Run(Report::"LT RP GetRec Rpt");
        DumpTrace(Observer);
        Observer.Expect('count', '13');
        Observer.Expect('e1', 'rp OnOpenPage');
        Observer.Expect('e2', 'handler opened');
        Observer.Expect('e3', 'rp Amount.OnValidate 5');
        Observer.Expect('e4', 'handler after Amount=5');
        Observer.Expect('e5', 'handler after Note');
        Observer.Expect('e6', 'rp Amount.OnValidate 7');
        Observer.Expect('e7', 'handler after Amount=7');
        Observer.Expect('e8', 'rp OnQueryClosePage OK');
        Observer.Expect('e9', 'rp OnClosePage');
        Observer.Expect('e10', 'report OnPreReport');
        Observer.Expect('e11', 'report Row.OnAfterGetRecord 1');
        Observer.Expect('e12', 'report Row.OnAfterGetRecord 2');
        Observer.Expect('e13', 'report OnPostReport');
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
    [HandlerFunctions('CancelHandler')]
    procedure P195_RequestPage_Cancel_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Trace.Reset();
        Commit();
        Report.Run(Report::"LT RP GetRec Rpt");
        DumpTrace(Observer);
        Observer.Expect('count', '4');
        Observer.Expect('e1', 'rp OnOpenPage');
        Observer.Expect('e2', 'handler opened');
        Observer.Expect('e3', 'rp OnQueryClosePage Cancel');
        Observer.Expect('e4', 'rp OnClosePage');
        Observer.Expect('e5', '<none>');
        Observer.Expect('e6', '<none>');
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
    procedure OkOnlyHandler(var RequestPage: TestRequestPage "LT RP GetRec Rpt")
    begin
        Trace.Add('handler opened');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure FieldChangeHandler(var RequestPage: TestRequestPage "LT RP GetRec Rpt")
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
    procedure CancelHandler(var RequestPage: TestRequestPage "LT RP GetRec Rpt")
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
