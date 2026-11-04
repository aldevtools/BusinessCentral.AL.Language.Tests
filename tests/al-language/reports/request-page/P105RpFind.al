// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained report 72232 and test codeunit 72233
// Facts: TestRequestPage FindFirstField, FindNextField, FindPreviousField, IsExpanded, Expand on request page fields; one handler per test

report 72232 "LT P105 RpFind"
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

codeunit 72233 "LT P105 RpFind Tests"
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
    local procedure TryFind(var RP: TestRequestPage "LT P105 RpFind"; Op: Integer; var R: Text)
    begin
        case Op of
            1:
                R := Format(RP.FindFirstField(RP.TextCtl, ''));
            2:
                R := Format(RP.FindNextField(RP.TextCtl, ''));
            3:
                R := Format(RP.FindPreviousField(RP.TextCtl, ''));
            4:
                R := Format(RP.FindFirstField(RP.IntCtl, 0));
            5:
                R := Format(RP.FindNextField(RP.IntCtl, 0));
            6:
                R := Format(RP.FindPreviousField(RP.IntCtl, 0));
            7:
                R := Format(RP.FindFirstField(RP.TextCtl, 'nomatch'));
            8:
                R := Format(RP.FindFirstField(RP.IntCtl, 5));
        end;
    end;

    local procedure Find(var RP: TestRequestPage "LT P105 RpFind"; Op: Integer): Text
    var
        R: Text;
    begin
        if TryFind(RP, Op, R) then
            exit('ok ' + R);
        exit(Failed());
    end;

    [TryFunction]
    local procedure TryExp(var RP: TestRequestPage "LT P105 RpFind"; Op: Integer; var R: Text)
    begin
        case Op of
            1:
                R := Format(RP.IsExpanded());
            2:
                RP.Expand(true);
            3:
                RP.Expand(false);
        end;
    end;

    local procedure Exp(var RP: TestRequestPage "LT P105 RpFind"; Op: Integer): Text
    var
        R: Text;
    begin
        if TryExp(RP, Op, R) then
            exit('ok ' + R);
        exit(Failed());
    end;

    [Test]
    [HandlerFunctions('FindFirstTextHandler')]
    procedure P105_FindFirstText()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindFirstText', 'ok Yes');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindFirstTextHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindFirstText', Find(RP, 1));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindNextTextHandler')]
    procedure P105_FindNextText()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindNextText', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindNextTextHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindNextText', Find(RP, 2));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindPrevTextHandler')]
    procedure P105_FindPrevText()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindPrevText', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindPrevTextHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindPrevText', Find(RP, 3));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindFirstIntHandler')]
    procedure P105_FindFirstInt()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindFirstInt', 'ok Yes');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindFirstIntHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindFirstInt', Find(RP, 4));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindNextIntHandler')]
    procedure P105_FindNextInt()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindNextInt', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindNextIntHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindNextInt', Find(RP, 5));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindPrevIntHandler')]
    procedure P105_FindPrevInt()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindPrevInt', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindPrevIntHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindPrevInt', Find(RP, 6));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindFirstNoMatchHandler')]
    procedure P105_FindFirstNoMatch()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindFirstNoMatch', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindFirstNoMatchHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindFirstNoMatch', Find(RP, 7));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('FindFirstIntOtherHandler')]
    procedure P105_FindFirstIntOther()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('FindFirstIntOther', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure FindFirstIntOtherHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('FindFirstIntOther', Find(RP, 8));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('IsExpInitHandler')]
    procedure P105_IsExpanded_Initial()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('initial', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure IsExpInitHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('initial', Exp(RP, 1));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ExpTrueHandler')]
    procedure P105_Expand_True()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('expand', 'ok ');
        Observer.Expect('after', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ExpTrueHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('expand', Exp(RP, 2));
        Observer.Observe('after', Exp(RP, 1));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ExpFalseHandler')]
    procedure P105_Expand_TrueFalse()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpFind");
        Observer.Expect('expand', 'ok ');
        Observer.Expect('collapse', 'ok ');
        Observer.Expect('after', 'ok No');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ExpFalseHandler(var RP: TestRequestPage "LT P105 RpFind")
    begin
        Observer.Observe('expand', Exp(RP, 2));
        Observer.Observe('collapse', Exp(RP, 3));
        Observer.Observe('after', Exp(RP, 1));
        RP.Cancel().Invoke();
    end;
}
