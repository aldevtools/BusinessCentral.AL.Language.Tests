// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own test codeunit 91353
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: Format(Decimal, 0, S) for format strings that start with <Precision,0:3> and carry <Comma,.>: with <Sign><Integer><Decimals>, with <Integer Thousand>,
//   without <Sign>, and with <Comma,.> first; values with 0 to 5 decimals, rounding at the fourth decimal, negative, zero and a large number.
//   misc/lt-np4-probes/Np4FormatJson.al pins '<Precision,0:3><Sign><Integer><Decimals><Comma,.>' for 1234.5678 only.
// BC versions: 27, 28, 29

codeunit 91353 "LT Y7 Format Prec 0:3 Comma"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(Value: Decimal; Spec: Text; var Result: Text)
    begin
        Result := Format(Value, 0, Spec);
    end;

    local procedure Values(var Observer: Codeunit "Probe Observer"; Spec: Text)
    begin
        F(Observer, '1234', 1234, Spec);
        F(Observer, '1234.5', 1234.5, Spec);
        F(Observer, '1234.56789', 1234.56789, Spec);
        F(Observer, '0.1', 0.1, Spec);
        F(Observer, '0.0005', 0.0005, Spec);
        F(Observer, '0.0004', 0.0004, Spec);
        F(Observer, '-1234.5', -1234.5, Spec);
        F(Observer, '-0.0004', -0.0004, Spec);
        F(Observer, '0', 0, Spec);
        F(Observer, '1234567.125', 1234567.125, Spec);
    end;

    local procedure F(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Decimal; Spec: Text)
    var
        Result: Text;
    begin
        if TryFmt(Value, Spec, Result) then
            Observer.Observe(Name, '[' + Result + ']')
        else begin
            Observer.Observe(Name, 'err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    procedure Y7_Prec03_Sign_Integer_Decimals_Comma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, '<Precision,0:3><Sign><Integer><Decimals><Comma,.>');
        Observer.Expect('1234', '[1234]');
        Observer.Expect('1234.5', '[1234.5]');
        Observer.Expect('1234.56789', '[1234.568]');
        Observer.Expect('0.1', '[0.1]');
        Observer.Expect('0.0005', '[0.001]');
        Observer.Expect('0.0004', '[0]');
        Observer.Expect('-1234.5', '[-1234.5]');
        Observer.Expect('-0.0004', '[-0]');
        Observer.Expect('0', '[0]');
        Observer.Expect('1234567.125', '[1234567.125]');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Prec03_Sign_IntegerThousand_Decimals_Comma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, '<Precision,0:3><Sign><Integer Thousand><Decimals><Comma,.>');
        Observer.Expect('1234', '[1,234]');
        Observer.Expect('1234.5', '[1,234.5]');
        Observer.Expect('1234.56789', '[1,234.568]');
        Observer.Expect('0.1', '[0.1]');
        Observer.Expect('0.0005', '[0.001]');
        Observer.Expect('0.0004', '[0]');
        Observer.Expect('-1234.5', '[-1,234.5]');
        Observer.Expect('-0.0004', '[-0]');
        Observer.Expect('0', '[0]');
        Observer.Expect('1234567.125', '[1,234,567.125]');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Prec03_Integer_Decimals_Comma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, '<Precision,0:3><Integer><Decimals><Comma,.>');
        Observer.Expect('1234', '[1234]');
        Observer.Expect('1234.5', '[1234.5]');
        Observer.Expect('1234.56789', '[1234.568]');
        Observer.Expect('0.1', '[0.1]');
        Observer.Expect('0.0005', '[0.001]');
        Observer.Expect('0.0004', '[0]');
        Observer.Expect('-1234.5', '[1234.5]');
        Observer.Expect('-0.0004', '[0]');
        Observer.Expect('0', '[0]');
        Observer.Expect('1234567.125', '[1234567.125]');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_Comma_First_Prec03()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Values(Observer, '<Comma,.><Precision,0:3><Sign><Integer><Decimals>');
        Observer.Expect('1234', '[1234]');
        Observer.Expect('1234.5', '[1234.5]');
        Observer.Expect('1234.56789', '[1234.568]');
        Observer.Expect('0.1', '[0.1]');
        Observer.Expect('0.0005', '[0.001]');
        Observer.Expect('0.0004', '[0]');
        Observer.Expect('-1234.5', '[-1234.5]');
        Observer.Expect('-0.0004', '[-0]');
        Observer.Expect('0', '[0]');
        Observer.Expect('1234567.125', '[1234567.125]');
        Observer.Verify();
    end;
}
