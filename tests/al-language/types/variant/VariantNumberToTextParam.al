// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74930 "LT VarNum Text Param"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakeText(T: Text): Text
    begin
        exit('[' + T + ']');
    end;

    local procedure TakeCode(C: Code[20]): Text
    begin
        exit('[' + C + ']');
    end;

    [TryFunction]
    local procedure TryTakeText(V: Variant; var Result: Text)
    begin
        Result := TakeText(V);
    end;

    [TryFunction]
    local procedure TryTakeCode(V: Variant; var Result: Text)
    begin
        Result := TakeCode(V);
    end;

    local procedure ViaText(V: Variant): Text
    var
        R: Text;
    begin
        if TryTakeText(V, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure ViaCode(V: Variant): Text
    var
        R: Text;
    begin
        if TryTakeCode(V, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure TextParam_ByValue_VariantNumbers()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
    begin
        I := 1234567;
        Observer.Observe('integer', ViaText(I));
        Observer.Observe('integer_format', Format(I));
        Evaluate(B, '5000000000');
        Observer.Observe('biginteger', ViaText(B));
        Observer.Observe('biginteger_format', Format(B));
        D := 1234567.891;
        Observer.Observe('decimal', ViaText(D));
        Observer.Observe('decimal_format', Format(D));
        D := 3.10;
        Observer.Observe('decimal_trailing_zero', ViaText(D));
        Observer.Expect('integer', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('integer_format', '1234567');
        Observer.Expect('biginteger', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('biginteger_format', '5000000000');
        Observer.Expect('decimal', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('decimal_format', '1,234,567.891');
        Observer.Expect('decimal_trailing_zero', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;

    [Test]
    procedure CodeParam_ByValue_VariantNumbers()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
    begin
        I := 1234567;
        Observer.Observe('integer', ViaCode(I));
        Evaluate(B, '5000000000');
        Observer.Observe('biginteger', ViaCode(B));
        D := 1234.5;
        Observer.Observe('decimal', ViaCode(D));
        Observer.Expect('integer', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('biginteger', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('decimal', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Verify();
    end;

    [Test]
    procedure TextParam_ByValue_VariantTextAndBoolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text', ViaText('abc'));
        Observer.Observe('boolean', ViaText(true));
        Observer.Observe('date', ViaText(DMY2Date(5, 3, 2020)));
        Observer.Expect('text', 'ok:[abc]');
        Observer.Expect('boolean', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('date', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;
}
