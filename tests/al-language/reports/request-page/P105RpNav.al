// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained report 72230 and test codeunit 72231
// Facts: TestRequestPage First, Last, Next, Previous, New, GoToKey, GoToRecord on a request page (no repeater); one request page handler per test, each started by Report.Run (a fatal error drops only its own test)

report 72230 "LT P105 RpNav"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            RequestFilterFields = Id;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    field(TextCtl; TextVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Text Control';
                    }
                    field(IntCtl; IntVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Integer Control';
                    }
                }
                group(Advanced)
                {
                    field(AdvText; AdvVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Advanced Control';
                    }
                }
            }
        }
    }

    var
        TextVal: Text[20];
        IntVal: Integer;
        AdvVal: Text[20];
}

codeunit 72231 "LT P105 RpNav Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";
        Observer: Codeunit "Probe Observer";

    local procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNav(var RP: TestRequestPage "LT P105 RpNav"; Op: Integer; var R: Text)
    var
        Row: Record "LT P105 Row";
    begin
        case Op of
            1:
                R := Format(RP.First());
            2:
                R := Format(RP.Last());
            3:
                R := Format(RP.Next());
            4:
                R := Format(RP.Previous());
            5:
                RP.New();
            6:
                R := Format(RP.GoToKey(1));
            7:
                R := Format(RP.GoToRecord(Row));
            8:
                R := Format(RP.GoToKey());
        end;
    end;

    local procedure Nav(var RP: TestRequestPage "LT P105 RpNav"; Op: Integer): Text
    var
        R: Text;
    begin
        if TryNav(RP, Op, R) then
            exit('ok ' + R);
        exit(Failed());
    end;

    [Test]
    [HandlerFunctions('FirstHandler')]
    procedure P105_First()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('First', 'ok Yes');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FirstHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('First', Nav(RP, 1));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('LastHandler')]
    procedure P105_Last()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('Last', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LastHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('Last', Nav(RP, 2));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('NextHandler')]
    procedure P105_Next()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('Next', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure NextHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('Next', Nav(RP, 3));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('PreviousHandler')]
    procedure P105_Previous()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('Previous', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PreviousHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('Previous', Nav(RP, 4));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('NewHandler')]
    procedure P105_New()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('New', 'error:New method failed because Insert is not allowed. Page = LT P105 RpNav, Id = 0.|DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure NewHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('New', Nav(RP, 5));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('GoToKeyHandler')]
    procedure P105_GoToKey()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('GoToKey', 'error:The number of arguments does not match the number of primary key fields.|TestInvalidNumberOfKeyFieldValues');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure GoToKeyHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('GoToKey', Nav(RP, 6));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('GoToRecordHandler')]
    procedure P105_GoToRecord()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('GoToRecord', 'error:The input record belongs to a table different from the one the page is based on.|TestSourceTableMismatch');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure GoToRecordHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('GoToRecord', Nav(RP, 7));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('GoToKeyNoArgHandler')]
    procedure P105_GoToKeyNoArg()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpNav");
        Observer.Expect('GoToKeyNoArg', 'ok Yes');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure GoToKeyNoArgHandler(var RP: TestRequestPage "LT P105 RpNav")
    begin
        Observer.Observe('GoToKeyNoArg', Nav(RP, 8));
        RP.Cancel().Invoke();
    end;
}
