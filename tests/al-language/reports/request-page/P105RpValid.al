// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained report 72234 and test codeunit 72235
// Facts: TestRequestPage.ValidationErrorCount and GetValidationError (index 0, 1, -1, out of range) before and after a field OnValidate raised an error through SetValue; one handler per test

report 72234 "LT P105 RpValid"
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
                field(IntCtl; IntVal)
                {
                    ApplicationArea = All;
                    Caption = 'Integer Control';

                    trigger OnValidate()
                    begin
                        if IntVal = 13 then
                            Error('unlucky %1', IntVal);
                    end;
                }
            }
        }
    }

    var
        IntVal: Integer;
}

codeunit 72235 "LT P105 RpValid Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('CountInitialHandler')]
    procedure P105_ValidationErrorCount_Initial()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpValid");
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CountInitialHandler(var RP: TestRequestPage "LT P105 RpValid")
    begin
        Observer.Observe('count', Format(RP.ValidationErrorCount()));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ErrorInitialHandler')]
    procedure P105_GetValidationError_Initial()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpValid");
        Observer.Expect('index default', 'ok ');
        Observer.Expect('index 1', 'error:Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('index 0', 'error:Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('index -1', 'error:Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('index 100', 'error:Index out of bounds.|IndexOutOfBounds');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ErrorInitialHandler(var RP: TestRequestPage "LT P105 RpValid")
    begin
        Observer.Observe('index default', GetErr(RP, 99));
        Observer.Observe('index 1', GetErr(RP, 1));
        Observer.Observe('index 0', GetErr(RP, 0));
        Observer.Observe('index -1', GetErr(RP, -1));
        Observer.Observe('index 100', GetErr(RP, 100));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('AfterErrorHandler')]
    procedure P105_ValidationError_AfterFailedSetValue()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpValid");
        Observer.Expect('set 13|text', 'Validation error for Field: IntCtl,  Message = ''unlucky 13''');
        Observer.Expect('set 13|code', 'TestValidation');
        Observer.Expect('count', '1');
        Observer.Expect('index default', 'ok unlucky 13');
        Observer.Expect('index 1', 'ok unlucky 13');
        Observer.Expect('index 2', 'error:Index out of bounds.|IndexOutOfBounds');
        Observer.Expect('index 0', 'error:Index out of bounds.|IndexOutOfBounds');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure AfterErrorHandler(var RP: TestRequestPage "LT P105 RpValid")
    begin
        asserterror RP.IntCtl.SetValue(13);
        Observer.ObserveError('set 13');
        Observer.Observe('count', Format(RP.ValidationErrorCount()));
        Observer.Observe('index default', GetErr(RP, 99));
        Observer.Observe('index 1', GetErr(RP, 1));
        Observer.Observe('index 2', GetErr(RP, 2));
        Observer.Observe('index 0', GetErr(RP, 0));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('TwiceHandler')]
    procedure P105_ValidationError_TwiceThenValid()
    begin
        Helper.Seed();
        Report.Run(Report::"LT P105 RpValid");
        Observer.Expect('first 13|text', 'Validation error for Field: IntCtl,  Message = ''unlucky 13''');
        Observer.Expect('first 13|code', 'TestValidation');
        Observer.Expect('second 13|text', 'Validation error for Field: IntCtl,  Message = ''unlucky 13''');
        Observer.Expect('second 13|code', 'TestValidation');
        Observer.Expect('count after two', '1');
        Observer.Expect('count after valid', '0');
        Observer.Expect('value', '7');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure TwiceHandler(var RP: TestRequestPage "LT P105 RpValid")
    begin
        asserterror RP.IntCtl.SetValue(13);
        Observer.ObserveError('first 13');
        asserterror RP.IntCtl.SetValue(13);
        Observer.ObserveError('second 13');
        Observer.Observe('count after two', Format(RP.ValidationErrorCount()));
        RP.IntCtl.SetValue(7);
        Observer.Observe('count after valid', Format(RP.ValidationErrorCount()));
        Observer.Observe('value', RP.IntCtl.Value());
        RP.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryErr(var RP: TestRequestPage "LT P105 RpValid"; Index: Integer; var R: Text)
    begin
        if Index = 99 then
            R := RP.GetValidationError()
        else
            R := RP.GetValidationError(Index);
    end;

    local procedure GetErr(var RP: TestRequestPage "LT P105 RpValid"; Index: Integer): Text
    var
        R: Text;
    begin
        if TryErr(RP, Index, R) then
            exit('ok ' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;
}
