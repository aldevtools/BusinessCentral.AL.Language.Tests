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
        Cr: Text[1];
        Lf: Text[1];
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        Exc := GetLastErrorObject();
        Full := Exc.ToString().Replace(Cr, '');
        Parts := Full.Split(Lf);
        Observer.Observe(Name + ' count', Format(Parts.Count()));
        for I := 1 to Parts.Count() do
            Observer.Observe(Name + ' ' + Format(I), Parts.Get(I));
    end;

    [Test]
    procedure Y89_Asserterror_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('LT Y89 plain');
        Lines(Observer, 'l');
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Asserterror_Deep()
    var
        Observer: Codeunit "Probe Observer";
        T: Codeunit "LT Y89 Frame Thrower";
    begin
        asserterror T.Level1();
        Lines(Observer, 'l');
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Asserterror_Divide()
    var
        Observer: Codeunit "Probe Observer";
        T: Codeunit "LT Y89 Frame Thrower";
    begin
        asserterror T.Divide();
        Lines(Observer, 'l');
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Try_Deep()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryDeep() then;
        Lines(Observer, 'l');
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Try_Divide()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryDivide() then;
        Lines(Observer, 'l');
        Observer.Finish();
    end;
}
