// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73922
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Describe(1.5) (Decimal) with candidates Integer, Text and Boolean" (Page extension overload of a base page procedure: the run-time error of an argument that does not fit)
// Facts: GetLastErrorText and GetLastErrorCode of a non-integral Decimal passed to an Integer parameter; whether an assignment I := 1.5 rounds; Evaluate of a fraction into an Integer; the overload set Integer, Text, Boolean called with a Decimal variable
// BC versions: 29 (27 and 28 by CI)

codeunit 73922 "LT PnF Decimal To Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTake(D: Decimal; var R: Text)
    begin
        R := TakeInteger(D);
    end;

    [TryFunction]
    local procedure TryAssign(D: Decimal; var R: Text)
    var
        I: Integer;
    begin
        I := D;
        R := Format(I);
    end;

    [TryFunction]
    local procedure TryDescribe(D: Decimal; var R: Text)
    begin
        R := Describe(D);
    end;

    local procedure TakeInteger(I: Integer): Text
    begin
        exit('int ' + Format(I));
    end;

    local procedure Describe(I: Integer): Text
    begin
        exit('integer ' + Format(I));
    end;

    local procedure Describe(T: Text): Text
    begin
        exit('text ' + T);
    end;

    local procedure Describe(B: Boolean): Text
    begin
        exit('boolean ' + Format(B));
    end;

    local procedure Res(Ok: Boolean; R: Text): Text
    begin
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DecimalToIntegerParameter()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryTake(1.5, R);
        Observer.Observe('take_1_5', Res(Ok, R));
        Ok := TryTake(2.5, R);
        Observer.Observe('take_2_5', Res(Ok, R));
        Ok := TryTake(-1.5, R);
        Observer.Observe('take_neg_1_5', Res(Ok, R));
        Ok := TryTake(0.4, R);
        Observer.Observe('take_0_4', Res(Ok, R));
        Ok := TryTake(0.6, R);
        Observer.Observe('take_0_6', Res(Ok, R));
        Ok := TryTake(3, R);
        Observer.Observe('take_3', Res(Ok, R));
        Ok := TryTake(3.0, R);
        Observer.Observe('take_3_0', Res(Ok, R));
        Ok := TryTake(3.00001, R);
        Observer.Observe('take_3_00001', Res(Ok, R));
        Ok := TryTake(2147483648.0, R);
        Observer.Observe('take_over_max', Res(Ok, R));
        Observer.Expect('take_1_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|ConversionCast');
        Observer.Expect('take_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('take_neg_1_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.|ConversionCast');
        Observer.Expect('take_0_4', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.4 to System.Int32.|ConversionCast');
        Observer.Expect('take_0_6', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.6 to System.Int32.|ConversionCast');
        Observer.Expect('take_3', 'int 3');
        Observer.Expect('take_3_0', 'int 3');
        Observer.Expect('take_3_00001', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.00001 to System.Int32.|ConversionCast');
        Observer.Expect('take_over_max', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2147483648.0 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalAssignedToInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryAssign(1.5, R);
        Observer.Observe('assign_1_5', Res(Ok, R));
        Ok := TryAssign(2.5, R);
        Observer.Observe('assign_2_5', Res(Ok, R));
        Ok := TryAssign(-1.5, R);
        Observer.Observe('assign_neg_1_5', Res(Ok, R));
        Ok := TryAssign(-2.5, R);
        Observer.Observe('assign_neg_2_5', Res(Ok, R));
        Ok := TryAssign(0.4, R);
        Observer.Observe('assign_0_4', Res(Ok, R));
        Ok := TryAssign(0.49999, R);
        Observer.Observe('assign_0_49999', Res(Ok, R));
        Ok := TryAssign(1.4999, R);
        Observer.Observe('assign_1_4999', Res(Ok, R));
        Ok := TryAssign(2147483647.6, R);
        Observer.Observe('assign_max_plus_fraction', Res(Ok, R));
        Observer.Expect('assign_1_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|ConversionCast');
        Observer.Expect('assign_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.|ConversionCast');
        Observer.Expect('assign_neg_1_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.|ConversionCast');
        Observer.Expect('assign_neg_2_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2.5 to System.Int32.|ConversionCast');
        Observer.Expect('assign_0_4', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.4 to System.Int32.|ConversionCast');
        Observer.Expect('assign_0_49999', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.49999 to System.Int32.|ConversionCast');
        Observer.Expect('assign_1_4999', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.4999 to System.Int32.|ConversionCast');
        Observer.Expect('assign_max_plus_fraction', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2147483647.6 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalToOverloadedDescribe()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryDescribe(1.5, R);
        Observer.Observe('describe_1_5', Res(Ok, R));
        Ok := TryDescribe(5, R);
        Observer.Observe('describe_5', Res(Ok, R));
        Ok := TryDescribe(0, R);
        Observer.Observe('describe_0', Res(Ok, R));
        Observer.Observe('describe_text', Describe('t'));
        Observer.Observe('describe_bool', Describe(true));
        Observer.Observe('describe_int', Describe(5));
        Observer.Expect('describe_1_5', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.|ConversionCast');
        Observer.Expect('describe_5', 'integer 5');
        Observer.Expect('describe_0', 'integer 0');
        Observer.Expect('describe_text', 'text t');
        Observer.Expect('describe_bool', 'boolean Yes');
        Observer.Expect('describe_int', 'integer 5');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateFractionIntoInteger()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        Observer.Observe('evaluate_1_5', Format(Evaluate(I, '1.5')));
        Observer.Observe('value_after', Format(I));
        Observer.Observe('evaluate_whole', Format(Evaluate(I, '2')));
        Observer.Observe('value_whole', Format(I));
        Observer.Expect('evaluate_1_5', 'No');
        Observer.Expect('value_after', '0');
        Observer.Expect('evaluate_whole', 'Yes');
        Observer.Expect('value_whole', '2');
        Observer.Verify();
    end;
}
