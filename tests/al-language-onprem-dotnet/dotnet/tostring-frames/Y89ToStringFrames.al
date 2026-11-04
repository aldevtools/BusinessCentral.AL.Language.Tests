// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (GetLastErrorObject and DotNet have scope OnPrem).
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; own objects 99335 - 99336
// Probe (writer Y89, from rt-values-1103f): every line of Exception.ToString() of the exception GetLastErrorObject answers after an asserterror, in full
// (Y76DotNet.al pins the head line and that a frame with NavMethodScope.AssertErrorAsync exists, not the whole frame lines: namespace and argument lists), for a
// plain Error, an Error three procedures deep, a missing Get and a division by zero, after asserterror, and the same errors caught by a TryFunction.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; LtY89Exc) { }
    }
}

codeunit 99335 "LT Y89 Frame Thrower"
{
    trigger OnRun()
    begin
        Level1();
    end;

    procedure Level1()
    begin
        Level2();
    end;

    local procedure Level2()
    begin
        Error('LT Y89 deep');
    end;

    procedure Divide()
    var
        Zero: Integer;
        Result: Integer;
    begin
        Result := 1 div Zero;
    end;
}

codeunit 99336 "LT Y89 Frame Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDeep()
    var
        T: Codeunit "LT Y89 Frame Thrower";
    begin
        T.Level1();
    end;

    [TryFunction]
    local procedure TryDivide()
    var
        T: Codeunit "LT Y89 Frame Thrower";
    begin
        T.Divide();
    end;

    local procedure Lines(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Exc: DotNet LtY89Exc;
        Full: Text;
        L: Text;
        Parts: List of [Text];
        I: Integer;
        Kept: Integer;
        Generated: Integer;
        Cr: Text[1];
        Lf: Text[1];
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        Exc := GetLastErrorObject();
        Full := Exc.ToString().Replace(Cr, '');
        Parts := Full.Split(Lf);
        // Lines of compiler-generated methods (their names carry numbers that change with the code around them) are only counted.
        for I := 1 to Parts.Count() do
            if Parts.Get(I).Contains('b__') then
                Generated += 1
            else begin
                Kept += 1;
                Observer.Observe(Name + ' ' + Format(Kept), Parts.Get(I));
            end;
        Observer.Observe(Name + ' generated', Format(Generated));
    end;

    [Test]
    procedure Y89_Asserterror_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('LT Y89 plain');
        Lines(Observer, 'l');
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y89 plain');
        Observer.Expect('l 2', '--- End of stack trace from previous location ---');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.Runtime.NavMethodScope.AssertErrorAsync(Func`1 body)');
        Observer.Expect('l generated', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Asserterror_Deep()
    var
        Observer: Codeunit "Probe Observer";
        T: Codeunit "LT Y89 Frame Thrower";
    begin
        asserterror T.Level1();
        Lines(Observer, 'l');
#if BC29PLUS
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y89 deep');
        Observer.Expect('l 2', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level2()');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level1()');
        Observer.Expect('l 4', '   at Microsoft.Dynamics.Nav.Types.ValueTaskExtensions.ManualResetValueTaskSource`1.GetResult(Int16 token)');
        Observer.Expect('l 5', '--- End of stack trace from previous location ---');
        Observer.Expect('l 6', '   at Microsoft.Dynamics.Nav.Runtime.NavMethodScope.AssertErrorAsync(Func`1 body)');
        Observer.Expect('l generated', '1');
#else
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y89 deep');
        Observer.Expect('l 2', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level2()');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level1()');
        Observer.Expect('l 4', '--- End of stack trace from previous location ---');
        Observer.Expect('l 5', '   at Microsoft.Dynamics.Nav.Runtime.NavMethodScope.AssertErrorAsync(Func`1 body)');
        Observer.Expect('l generated', '1');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Asserterror_Divide()
    var
        Observer: Codeunit "Probe Observer";
        T: Codeunit "LT Y89 Frame Thrower";
    begin
        asserterror T.Divide();
        Lines(Observer, 'l');
#if BC29PLUS
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero.');
        Observer.Expect('l 2', ' ---> System.DivideByZeroException: Attempted to divide by zero.');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 4', '   --- End of inner exception stack trace ---');
        Observer.Expect('l 5', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 6', '   at Microsoft.Dynamics.Nav.Types.ValueTaskExtensions.ManualResetValueTaskSource`1.GetResult(Int16 token)');
        Observer.Expect('l 7', '--- End of stack trace from previous location ---');
        Observer.Expect('l 8', '   at Microsoft.Dynamics.Nav.Runtime.NavMethodScope.AssertErrorAsync(Func`1 body)');
        Observer.Expect('l generated', '1');
#else
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero.');
        Observer.Expect('l 2', ' ---> System.DivideByZeroException: Attempted to divide by zero.');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 4', '   --- End of inner exception stack trace ---');
        Observer.Expect('l 5', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 6', '--- End of stack trace from previous location ---');
        Observer.Expect('l 7', '   at Microsoft.Dynamics.Nav.Runtime.NavMethodScope.AssertErrorAsync(Func`1 body)');
        Observer.Expect('l generated', '1');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Try_Deep()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryDeep() then;
        Lines(Observer, 'l');
#if BC29PLUS
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y89 deep');
        Observer.Expect('l 2', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level2()');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level1()');
        Observer.Expect('l 4', '   at Microsoft.Dynamics.Nav.Types.ValueTaskExtensions.ManualResetValueTaskSource`1.GetResult(Int16 token)');
        Observer.Expect('l 5', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99336.TryDeep()');
        Observer.Expect('l 6', '   at Microsoft.Dynamics.Nav.Runtime.NavApplicationObjectBase.TryInvokeAsync(NavSession session, Func`1 method)');
        Observer.Expect('l generated', '1');
#else
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT Y89 deep');
        Observer.Expect('l 2', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level2()');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Level1()');
        Observer.Expect('l 4', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99336.TryDeep()');
        Observer.Expect('l 5', '   at Microsoft.Dynamics.Nav.Runtime.NavApplicationObjectBase.TryInvokeAsync(NavSession session, Func`1 method)');
        Observer.Expect('l generated', '1');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Try_Divide()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryDivide() then;
        Lines(Observer, 'l');
#if BC29PLUS
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero.');
        Observer.Expect('l 2', ' ---> System.DivideByZeroException: Attempted to divide by zero.');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 4', '   --- End of inner exception stack trace ---');
        Observer.Expect('l 5', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 6', '   at Microsoft.Dynamics.Nav.Types.ValueTaskExtensions.ManualResetValueTaskSource`1.GetResult(Int16 token)');
        Observer.Expect('l 7', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99336.TryDivide()');
        Observer.Expect('l 8', '   at Microsoft.Dynamics.Nav.Runtime.NavApplicationObjectBase.TryInvokeAsync(NavSession session, Func`1 method)');
        Observer.Expect('l generated', '1');
#else
        Observer.Expect('l 1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero.');
        Observer.Expect('l 2', ' ---> System.DivideByZeroException: Attempted to divide by zero.');
        Observer.Expect('l 3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 4', '   --- End of inner exception stack trace ---');
        Observer.Expect('l 5', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99335.Divide()');
        Observer.Expect('l 6', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit99336.TryDivide()');
        Observer.Expect('l 7', '   at Microsoft.Dynamics.Nav.Runtime.NavApplicationObjectBase.TryInvokeAsync(NavSession session, Func`1 method)');
        Observer.Expect('l generated', '1');
#endif
        Observer.Verify();
    end;
}
