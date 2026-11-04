// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-type-conversion-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 85480, test codeunit 85481
// Probe: written against the local BC 29.0 test loop; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Corpus issue 670 (lead list E), items 76, 80, 81, 88 and 90 (writer CX):
//   76 an Option field with blank members (" ",,,"A","B","C",,,,,"D","E") given integers (microsoft/AL#571);
//   80 a Guid compared with a Text and with literals (microsoft/AL#6785, #4912);
//   81 a Guid in text form assigned to a Code[20] (microsoft/AL#7143; the direct assignment is must-not-compile case 1785);
//   88 the type and value of mixed expressions (Char + 1, Text + Code, Code + Code, Option + Integer, Byte + Byte);
//   90 FieldRef.Value assigned straight to a Text variable (microsoft/AL#1456).
// BC versions: 27, 28, 29

table 85480 "LT CX Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = " ",,,"A","B","C",,,,,"D","E"; }
        field(3; G; Guid) { }
        field(4; "Post Code"; Code[20]) { }
        field(5; Name; Text[50]) { }
        field(6; Amount; Decimal) { }
        field(7; Day; Date) { }
        field(8; Flag; Boolean) { }
        field(9; Plain; Option) { OptionMembers = Alpha,"Beta Two",Gamma; }
        field(10; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85481 "LT CX Scalars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Kind(V: Variant): Text
    begin
        case true of
            V.IsChar():
                exit('Char');
            V.IsByte():
                exit('Byte');
            V.IsInteger():
                exit('Integer');
            V.IsBigInteger():
                exit('BigInteger');
            V.IsDecimal():
                exit('Decimal');
            V.IsOption():
                exit('Option');
            V.IsCode():
                exit('Code');
            V.IsText():
                exit('Text');
        end;
        exit('other');
    end;

    local procedure Show(V: Variant): Text
    begin
        exit(Kind(V) + ':' + Format(V));
    end;

    local procedure Opt(var Row: Record "LT CX Row"): Text
    begin
        exit(Format(Row.Opt) + '|' + Format(Row.Opt, 0, 2) + '|' + Format(Row.Opt, 0, 9));
    end;

    [TryFunction]
    local procedure TryOptFromInteger(var Row: Record "LT CX Row"; Value: Integer)
    begin
        Row.Opt := Value;
    end;

    local procedure OptFromInteger(Value: Integer): Text
    var
        Row: Record "LT CX Row";
    begin
        ClearLastError();
        if TryOptFromInteger(Row, Value) then
            exit('ok:' + Opt(Row));
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure OptionWithBlankMembers_IntegerAssignment()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CX Row";
        RecRef: RecordRef;
    begin
        Row.Opt := 11;
        Observer.Observe('const_11', Opt(Row));
        Row.Opt := 5;
        Observer.Observe('const_5', Opt(Row));
        Row.Opt := 3;
        Observer.Observe('const_3', Opt(Row));
        Row.Opt := 1;
        Observer.Observe('const_1_blank', Opt(Row));
        Row.Opt := 12;
        Observer.Observe('const_12', Opt(Row));
        Row.Opt := Row.Opt::E;
        Observer.Observe('member_E', Opt(Row));
        Row.Opt := Row.Opt::D;
        Observer.Observe('member_D', Opt(Row));
        Observer.Observe('var_10', OptFromInteger(10));
        Observer.Observe('var_7_blank', OptFromInteger(7));
        Observer.Observe('var_12', OptFromInteger(12));
        Observer.Observe('var_minus_1', OptFromInteger(-1));
        RecRef.Open(Database::"LT CX Row");
        Observer.Observe('option_members', RecRef.Field(2).OptionMembers());
        Observer.Observe('option_caption', RecRef.Field(2).OptionCaption());
        Observer.Expect('const_11', 'E|11|11');
        Observer.Expect('const_5', 'C|5|5');
        Observer.Expect('const_3', 'A|3|3');
        Observer.Expect('const_1_blank', '1|1|1');
        Observer.Expect('const_12', '12|12|12');
        Observer.Expect('member_E', 'E|11|11');
        Observer.Expect('member_D', 'D|10|10');
        Observer.Expect('var_10', 'ok:D|10|10');
        Observer.Expect('var_7_blank', 'ok:7|7|7');
        Observer.Expect('var_12', 'ok:12|12|12');
        Observer.Expect('var_minus_1', 'ok:-1|-1|-1');
        Observer.Expect('option_members', ' ,,,A,B,C,,,,,D,E');
        Observer.Expect('option_caption', ' ,,,A,B,C,,,,,D,E');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEquals(G: Guid; T: Text; var Result: Boolean)
    begin
        Result := G = T;
    end;

    [TryFunction]
    local procedure TryNotEquals(G: Guid; T: Text; var Result: Boolean)
    begin
        Result := G <> T;
    end;

    [TryFunction]
    local procedure TryTextFirst(G: Guid; T: Text; var Result: Boolean)
    begin
        Result := T = G;
    end;

    local procedure Compare(G: Guid; T: Text): Text
    var
        Eq: Boolean;
        Ne: Boolean;
        Rev: Boolean;
        R: Text;
    begin
        ClearLastError();
        if TryEquals(G, T, Eq) then
            R := 'eq=' + Format(Eq)
        else
            R := 'eq error:' + GetLastErrorCode() + ':' + GetLastErrorText();
        ClearLastError();
        if TryNotEquals(G, T, Ne) then
            R += '|ne=' + Format(Ne)
        else
            R += '|ne error:' + GetLastErrorCode();
        ClearLastError();
        if TryTextFirst(G, T, Rev) then
            R += '|text_first=' + Format(Rev)
        else
            R += '|text_first error:' + GetLastErrorCode();
        exit(R);
    end;

    [TryFunction]
    local procedure TryLiteralEmpty(G: Guid; var Result: Boolean)
    begin
        Result := G <> '';
    end;

    [TryFunction]
    local procedure TryLiteralAbc(G: Guid; var Result: Boolean)
    begin
        Result := G = 'abc';
    end;

    [TryFunction]
    local procedure TryFieldEmpty(var Row: Record "LT CX Row"; var Result: Boolean)
    begin
        Result := Row.G = '';
    end;

    local procedure Outcome(Ok: Boolean; Result: Boolean): Text
    begin
        if Ok then
            exit(Format(Result));
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure Guid_ComparedWithText()
    var
        Observer: Codeunit "Probe Observer";
        Null: Guid;
        G: Guid;
    begin
        Evaluate(G, '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        Observer.Observe('null_vs_empty', Compare(Null, ''));
        Observer.Observe('null_vs_null_text', Compare(Null, '{00000000-0000-0000-0000-000000000000}'));
        Observer.Observe('g_vs_braced', Compare(G, '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}'));
        Observer.Observe('g_vs_no_braces', Compare(G, '0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D'));
        Observer.Observe('g_vs_lower', Compare(G, '{0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d}'));
        Observer.Observe('g_vs_other', Compare(G, '{00000000-0000-0000-0000-000000000001}'));
        Observer.Observe('g_vs_garbage', Compare(G, 'garbage'));
        Observer.Observe('g_vs_empty', Compare(G, ''));
        Observer.Observe('null_vs_garbage', Compare(Null, 'garbage'));
        Observer.Expect('null_vs_empty', 'eq error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|ne error:InvalidGuidFormat|text_first error:InvalidGuidFormat');
        Observer.Expect('null_vs_null_text', 'eq=Yes|ne=No|text_first=Yes');
        Observer.Expect('g_vs_braced', 'eq=Yes|ne=No|text_first=Yes');
        Observer.Expect('g_vs_no_braces', 'eq=Yes|ne=No|text_first=Yes');
        Observer.Expect('g_vs_lower', 'eq=Yes|ne=No|text_first=Yes');
        Observer.Expect('g_vs_other', 'eq=No|ne=Yes|text_first=No');
        Observer.Expect('g_vs_garbage', 'eq error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|ne error:InvalidGuidFormat|text_first error:InvalidGuidFormat');
        Observer.Expect('g_vs_empty', 'eq error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|ne error:InvalidGuidFormat|text_first error:InvalidGuidFormat');
        Observer.Expect('null_vs_garbage', 'eq error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|ne error:InvalidGuidFormat|text_first error:InvalidGuidFormat');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_ComparedWithLiterals()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CX Row";
        Null: Guid;
        G: Guid;
        Result: Boolean;
        Ok: Boolean;
    begin
        Evaluate(G, '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        ClearLastError();
        Ok := TryLiteralEmpty(Null, Result);
        Observer.Observe('null_ne_empty_literal', Outcome(Ok, Result));
        ClearLastError();
        Ok := TryLiteralEmpty(G, Result);
        Observer.Observe('g_ne_empty_literal', Outcome(Ok, Result));
        ClearLastError();
        Ok := TryLiteralAbc(G, Result);
        Observer.Observe('g_eq_abc_literal', Outcome(Ok, Result));
        ClearLastError();
        Ok := TryFieldEmpty(Row, Result);
        Observer.Observe('null_field_eq_empty_literal', Outcome(Ok, Result));
        Row.G := G;
        ClearLastError();
        Ok := TryFieldEmpty(Row, Result);
        Observer.Observe('field_eq_empty_literal', Outcome(Ok, Result));
        Observer.Observe('field_vs_text', Compare(Row.G, '0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'));
        Observer.Expect('null_ne_empty_literal', 'error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('g_ne_empty_literal', 'error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('g_eq_abc_literal', 'error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('null_field_eq_empty_literal', 'error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('field_eq_empty_literal', 'error:InvalidGuidFormat:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('field_vs_text', 'eq=Yes|ne=No|text_first=Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryToCode20(Value: Text; var Target: Code[20])
    begin
        Target := Value;
    end;

    [Test]
    procedure GuidText_ToCode20()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        C: Code[20];
        Ok: Boolean;
    begin
        Evaluate(G, '{0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        C := 'BEFORE';
        Observer.Observe('maxstrlen_before', Format(MaxStrLen(C)));
        ClearLastError();
        Ok := TryToCode20(Format(G), C);
        Observer.Observe('assign_ok', Format(Ok));
        Observer.Observe('assign_error', GetLastErrorCode() + ':' + GetLastErrorText());
        Observer.Observe('after_value', C);
        Observer.Observe('strlen_after', Format(StrLen(C)));
        Observer.Observe('maxstrlen_after', Format(MaxStrLen(C)));
        C := CopyStr(Format(G), 1, MaxStrLen(C));
        Observer.Observe('copystr_strlen', Format(StrLen(C)));
        Observer.Expect('maxstrlen_before', '20');
        Observer.Expect('assign_ok', 'No');
        Observer.Expect('assign_error', 'StringLengthExceeded:The length of the string is 38, but it must be less than or equal to 20 characters. Value: {0A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D}');
        Observer.Expect('after_value', 'BEFORE');
        Observer.Expect('strlen_after', '6');
        Observer.Expect('maxstrlen_after', '20');
        Observer.Expect('copystr_strlen', '20');
        Observer.Verify();
    end;

    [Test]
    procedure MixedExpressions_TypeAndValue()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        Ch2: Char;
        T: Text;
        C: Code[10];
        C2: Code[10];
        O: Option A,B,C;
        By: Byte;
        By2: Byte;
        I: Integer;
        D: Decimal;
    begin
        Ch := 'A';
        Ch2 := 'B';
        T := 'text';
        C := 'ab';
        C2 := 'cd';
        O := O::C;
        By := 200;
        By2 := 100;
        I := 3;
        D := 0.5;
        Observer.Observe('char_plus_1', Show(Ch + 1));
        Observer.Observe('char_plus_char', Show(Ch + Ch2));
        Observer.Observe('char_minus_char', Show(Ch2 - Ch));
        Observer.Observe('text_plus_code', Show(T + C));
        Observer.Observe('code_plus_text', Show(C + T));
        Observer.Observe('code_plus_code', Show(C + C2));
        Observer.Observe('code_plus_lower_literal', Show(C + 'xy'));
        Observer.Observe('integer_plus_decimal', Show(I + D));
        Observer.Observe('option_plus_integer', Show(O + 1));
        Observer.Observe('option_times_integer', Show(O * I));
        Observer.Observe('byte_plus_byte', Show(By + By2));
        Observer.Observe('byte_times_byte', Show(By * By2));
        Observer.Observe('byte_plus_integer', Show(By + I));
        Observer.Observe('char_plus_text', Show(Ch + T));
        Observer.Expect('char_plus_1', 'Integer:66');
        Observer.Expect('char_plus_char', 'Integer:131');
        Observer.Expect('char_minus_char', 'Integer:1');
        Observer.Expect('text_plus_code', 'Text:textAB');
        Observer.Expect('code_plus_text', 'Text:ABtext');
        Observer.Expect('code_plus_code', 'Text:ABCD');
        Observer.Expect('code_plus_lower_literal', 'Text:ABxy');
        Observer.Expect('integer_plus_decimal', 'Decimal:3.5');
        Observer.Expect('option_plus_integer', 'Integer:3');
        Observer.Expect('option_times_integer', 'Integer:6');
        Observer.Expect('byte_plus_byte', 'Integer:300');
        Observer.Expect('byte_times_byte', 'Integer:20000');
        Observer.Expect('byte_plus_integer', 'Integer:203');
        Observer.Expect('char_plus_text', 'Text:Atext');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFieldToText(var RecRef: RecordRef; FieldNo: Integer; var Target: Text)
    begin
        Target := RecRef.Field(FieldNo).Value;
    end;

    local procedure FieldToText(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        T: Text;
    begin
        ClearLastError();
        if TryFieldToText(RecRef, FieldNo, T) then
            exit('ok:' + T + '|concat:' + 'x' + T);
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure FieldRefValue_ToTextVariable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CX Row";
        RecRef: RecordRef;
        PostCode: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row."Post Code" := 'ab-123';
        Row.Name := 'Mixed Case';
        Row.Amount := 1234.5;
        Row.Day := DMY2Date(3, 4, 2021);
        Row.Flag := true;
        Row.Plain := Row.Plain::"Beta Two";
        Row.Qty := 42;
        Row.Insert();
        RecRef.GetTable(Row);
        PostCode := RecRef.Field(Row.FieldNo("Post Code")).Value;
        Observer.Observe('post_code_direct', 'x' + PostCode);
        Observer.Observe('code', FieldToText(RecRef, 4));
        Observer.Observe('text', FieldToText(RecRef, 5));
        Observer.Observe('decimal', FieldToText(RecRef, 6));
        Observer.Observe('date', FieldToText(RecRef, 7));
        Observer.Observe('boolean', FieldToText(RecRef, 8));
        Observer.Observe('option', FieldToText(RecRef, 9));
        Observer.Observe('integer', FieldToText(RecRef, 10));
        Observer.Observe('guid', FieldToText(RecRef, 3));
        Observer.Expect('post_code_direct', 'xAB-123');
        Observer.Expect('code', 'ok:AB-123|concat:xAB-123');
        Observer.Expect('text', 'ok:Mixed Case|concat:xMixed Case');
        Observer.Expect('decimal', 'ok:1,234.5|concat:x1,234.5');
        Observer.Expect('date', 'ok:04/03/21|concat:x04/03/21');
        Observer.Expect('boolean', 'ok:Yes|concat:xYes');
        Observer.Expect('option', 'ok:Beta Two|concat:xBeta Two');
        Observer.Expect('integer', 'ok:42|concat:x42');
        Observer.Expect('guid', 'ok:{00000000-0000-0000-0000-000000000000}|concat:x{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;
}
