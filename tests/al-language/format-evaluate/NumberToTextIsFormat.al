// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: A Variant holding an Integer, BigInteger or Decimal converted to Text or Code, FieldRef.Value into a Text, TextBuilder.Append(Variant), FieldRef.SetValue of a number on a Code field (assumption number-to-text-is-format); types/lt-variant/VaTConvert.al:117 pins T := V with an Integer variant (no text). Every conversion that may or may not raise goes through a TryFunction, the outcome is observed either way.
// BC versions: 29 (27 and 28 by CI)

table 70656 "LT NumTxt Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; "Int Value"; Integer) { }
        field(3; "Big Value"; BigInteger) { }
        field(4; "Dec Value"; Decimal) { }
        field(5; "Code Value"; Code[20]) { }
        field(6; "Short Code"; Code[2]) { }
        field(7; "Text Value"; Text[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70657 "LT NumTxt Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryToText(V: Variant; var T: Text)
    begin
        T := V;
    end;

    [TryFunction]
    local procedure TryToCode(V: Variant; var C: Code[20])
    begin
        C := V;
    end;

    [TryFunction]
    local procedure TryToShortCode(V: Variant; var C: Code[2])
    begin
        C := V;
    end;

    [TryFunction]
    local procedure TryAppend(V: Variant; var SB: TextBuilder)
    begin
        SB.Append(V);
    end;

    [TryFunction]
    local procedure TrySetValue(var RR: RecordRef; FieldNo: Integer; V: Variant)
    begin
        RR.Field(FieldNo).Value := V;
    end;

    local procedure ToText(V: Variant): Text
    var
        T: Text;
    begin
        ClearLastError();
        if TryToText(V, T) then
            exit('ok:' + T);
        exit('error:' + GetLastErrorText());
    end;

    local procedure ToCode(V: Variant): Text
    var
        C: Code[20];
    begin
        ClearLastError();
        if TryToCode(V, C) then
            exit('ok:' + C);
        exit('error:' + GetLastErrorText());
    end;

    local procedure ToShortCode(V: Variant): Text
    var
        C: Code[2];
    begin
        ClearLastError();
        if TryToShortCode(V, C) then
            exit('ok:' + C);
        exit('error:' + GetLastErrorText());
    end;

    local procedure SeedRow()
    var
        Row: Record "LT NumTxt Row";
    begin
        Row.DeleteAll();
        Row."No." := 1;
        Row."Int Value" := -42;
        Evaluate(Row."Big Value", '5000000000');
        Row."Dec Value" := 12.50;
        Row.Insert();
    end;

    [Test]
    procedure VariantToText_Numbers_Result()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
    begin
        I := 1234567;
        Observer.Observe('int', ToText(I));
        I := -7;
        Observer.Observe('int_negative', ToText(I));
        I := 0;
        Observer.Observe('int_zero', ToText(I));
        B := 123456;
        Observer.Observe('big', ToText(B));
        Evaluate(B, '5000000000');
        Observer.Observe('big_beyond_int', ToText(B));
        D := 3.10;
        Observer.Observe('dec_trailing_zero', ToText(D));
        D := -1234.5;
        Observer.Observe('dec_negative', ToText(D));
        D := 0;
        Observer.Observe('dec_zero', ToText(D));
        D := 1234567.891;
        Observer.Observe('dec_large', ToText(D));
        Observer.Expect('int', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('int_negative', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('int_zero', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('big', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('big_beyond_int', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dec_trailing_zero', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dec_negative', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dec_zero', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dec_large', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToCode_Numbers_Result()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        D: Decimal;
    begin
        I := 1234567;
        Observer.Observe('int', ToCode(I));
        B := 123456;
        Observer.Observe('big', ToCode(B));
        D := 3.10;
        Observer.Observe('dec', ToCode(D));
        I := 5;
        Observer.Observe('int_to_code2', ToShortCode(I));
        I := 123;
        Observer.Observe('int_too_long_for_code2', ToShortCode(I));
        D := 12.5;
        Observer.Observe('dec_too_long_for_code2', ToShortCode(D));
        Observer.Expect('int', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('big', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('dec', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('int_to_code2', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('int_too_long_for_code2', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('dec_too_long_for_code2', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefValue_ToText_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        SeedRow();
        RR.Open(Database::"LT NumTxt Row");
        RR.FindFirst();
        Observer.Observe('int_field', ToText(RR.Field(2).Value()));
        Observer.Observe('big_field', ToText(RR.Field(3).Value()));
        Observer.Observe('dec_field', ToText(RR.Field(4).Value()));
        Observer.Observe('int_field_format', Format(RR.Field(2).Value()));
        Observer.Observe('dec_field_format', Format(RR.Field(4).Value()));
        Observer.Expect('int_field', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('big_field', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dec_field', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('int_field_format', '-42');
        Observer.Expect('dec_field_format', '12.5');
        Observer.Verify();
    end;

    [Test]
    procedure TextBuilderAppend_VariantNumber_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        SB: TextBuilder;
        I: Integer;
        Outcome: Text;
    begin
        SeedRow();
        RR.Open(Database::"LT NumTxt Row");
        RR.FindFirst();
        for I := 2 to 4 do begin
            ClearLastError();
            if TryAppend(RR.Field(I).Value(), SB) then
                Outcome := 'ok'
            else
                Outcome := 'error:' + GetLastErrorText();
            Observer.Observe('append_field_' + Format(I), Outcome);
            Observer.Observe('builder_after_' + Format(I), SB.ToText());
        end;
        Observer.Expect('append_field_2', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('builder_after_2', '');
        Observer.Expect('append_field_3', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('builder_after_3', '');
        Observer.Expect('append_field_4', 'error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('builder_after_4', '');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefSetValue_NumberOnCodeAndText_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        SeedRow();
        RR.Open(Database::"LT NumTxt Row");
        RR.FindFirst();
        Observer.Observe('code_set_int', Format(TrySetValue(RR, 5, 10)));
        Observer.Observe('code_after_int', Format(RR.Field(5).Value()));
        Observer.Observe('code_set_dec', Format(TrySetValue(RR, 5, 2.5)));
        Observer.Observe('code_after_dec', Format(RR.Field(5).Value()));
        Observer.Observe('text_set_int', Format(TrySetValue(RR, 7, -3)));
        Observer.Observe('text_after_int', Format(RR.Field(7).Value()));
        Observer.Observe('short_code_set_long_int', Format(TrySetValue(RR, 6, 12345)));
        Observer.Observe('short_after', Format(RR.Field(6).Value()));
        Observer.Expect('code_set_int', 'Yes');
        Observer.Expect('code_after_int', '10');
        Observer.Expect('code_set_dec', 'Yes');
        Observer.Expect('code_after_dec', '2.5');
        Observer.Expect('text_set_int', 'Yes');
        Observer.Expect('text_after_int', '-3');
        Observer.Expect('short_code_set_long_int', 'No');
        Observer.Expect('short_after', '');
        Observer.Verify();
    end;
}
