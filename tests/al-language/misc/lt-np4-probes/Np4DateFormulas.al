// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Writer NP4 (NP lane, 2026-10-30), codeunit 93400. Probe: CalcDate with the date formula letters Dn, Wn, Qn and Mn (n a number) from fixed base dates in a leap
//   year (2024) and a non-leap year (2023): the date it gives or the error text and code. No test depends on the run date.
// BC versions: 27, 28, 29

codeunit 93400 "LT NP4 Date Formulas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, Base);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Formula: Text; Base: Date)
    var
        R: Date;
    begin
        if TryCalc(Formula, Base, R) then
            Observer.Observe(Format(Base, 0, 9), 'ok|' + Format(R, 0, 9))
        else begin
            Observer.Observe(Format(Base, 0, 9), CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 600));
            ClearLastError();
        end;
    end;

    local procedure Bases(var Observer: Codeunit "Probe Observer"; Formula: Text)
    begin
        One(Observer, Formula, 20230101D);
        One(Observer, Formula, 20230131D);
        One(Observer, Formula, 20230214D);
        One(Observer, Formula, 20230228D);
        One(Observer, Formula, 20230415D);
        One(Observer, Formula, 20230630D);
        One(Observer, Formula, 20231231D);
        One(Observer, Formula, 20240101D);
        One(Observer, Formula, 20240131D);
        One(Observer, Formula, 20240215D);
        One(Observer, Formula, 20240229D);
        One(Observer, Formula, 20240331D);
        One(Observer, Formula, 20240615D);
        One(Observer, Formula, 20241231D);
    end;

    [Test]
    procedure NP4_CalcDate_D15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<D15>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_D28()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<D28>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_D29()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<D29>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_D31()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<D31>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_W17()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<W17>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_Q3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<Q3>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_M1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<M1>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_M3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<M3>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_CalcDate_M12()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Bases(Observer, '<M12>');
        Observer.Finish();
    end;
}
