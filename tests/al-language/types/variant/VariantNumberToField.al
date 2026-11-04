// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 74928 "LT VarNum Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; "Text Value"; Text[250]) { }
        field(3; "Code Value"; Code[50]) { }
        field(4; "Short Text"; Text[3]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 74929 "LT VarNum To Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryText(V: Variant; var Row: Record "LT VarNum Row")
    begin
        Row."Text Value" := V;
    end;

    [TryFunction]
    local procedure TryCode(V: Variant; var Row: Record "LT VarNum Row")
    begin
        Row."Code Value" := V;
    end;

    [TryFunction]
    local procedure TryShort(V: Variant; var Row: Record "LT VarNum Row")
    begin
        Row."Short Text" := V;
    end;

    local procedure ToTextField(V: Variant): Text
    var
        Row: Record "LT VarNum Row";
    begin
        if TryText(V, Row) then
            exit('ok:' + Row."Text Value");
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure ToCodeField(V: Variant): Text
    var
        Row: Record "LT VarNum Row";
    begin
        if TryCode(V, Row) then
            exit('ok:' + Row."Code Value");
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure ToShortField(V: Variant): Text
    var
        Row: Record "LT VarNum Row";
    begin
        if TryShort(V, Row) then
            exit('ok:' + Row."Short Text");
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure TextField_FromVariantInteger_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum Row";
        I: Integer;
    begin
        Row.DeleteAll();
        I := 1234567;
        Observer.Observe('stored', ToTextField(I));
        Observer.Observe('format', Format(I));
        I := -42;
        Observer.Observe('negative', ToTextField(I));
        I := 0;
        Observer.Observe('zero', ToTextField(I));
        Observer.Expect('stored', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('format', '1234567');
        Observer.Expect('negative', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('zero', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_FromVariantBigInteger_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum Row";
        B: BigInteger;
    begin
        Row.DeleteAll();
        Evaluate(B, '5000000000');
        Observer.Observe('stored', ToTextField(B));
        Observer.Observe('format', Format(B));
        B := 12;
        Observer.Observe('small', ToTextField(B));
        Evaluate(B, '-5000000000');
        Observer.Observe('negative', ToTextField(B));
        Observer.Expect('stored', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('format', '5000000000');
        Observer.Expect('small', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('negative', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_FromVariantDecimal_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum Row";
        D: Decimal;
    begin
        Row.DeleteAll();
        D := 1234567.891;
        Observer.Observe('stored', ToTextField(D));
        Observer.Observe('format', Format(D));
        D := 3.10;
        Observer.Observe('trailing_zero', ToTextField(D));
        D := -1234.5;
        Observer.Observe('negative', ToTextField(D));
        D := 0;
        Observer.Observe('zero', ToTextField(D));
        D := 0.000001;
        Observer.Observe('tiny', ToTextField(D));
        Observer.Expect('stored', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('format', '1,234,567.891');
        Observer.Expect('trailing_zero', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('negative', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('zero', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('tiny', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_FromVariantNumbers_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum Row";
        I: Integer;
        B: BigInteger;
        D: Decimal;
    begin
        Row.DeleteAll();
        I := 1234567;
        Observer.Observe('integer', ToCodeField(I));
        Evaluate(B, '5000000000');
        Observer.Observe('biginteger', ToCodeField(B));
        D := 1234.5;
        Observer.Observe('decimal', ToCodeField(D));
        Observer.Expect('integer', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('biginteger', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('decimal', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_FromVariantNumber_TooLong()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum Row";
        I: Integer;
        D: Decimal;
    begin
        Row.DeleteAll();
        I := 12345;
        Observer.Observe('integer_in_text3', ToShortField(I));
        I := 123;
        Observer.Observe('integer_fits_text3', ToShortField(I));
        D := 1234.5;
        Observer.Observe('decimal_in_text3', ToShortField(D));
        Observer.Expect('integer_in_text3', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('integer_fits_text3', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('decimal_in_text3', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;
}
