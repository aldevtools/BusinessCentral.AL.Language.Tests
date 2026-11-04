// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 67509, codeunit 67511
// Probe: a Variant cannot be compared with = or <> (must-not-compile case 0502), but it can be the subject of a case statement. Whether a case statement over an unassigned Variant matches (or raises on): an enum member (ordinal 0 and 1), the integers 0 and 1, an empty text, false and the zero date; the same for a Variant that holds an enum member (issue 580 item 6).
// BC versions: 27+

enum 67509 "LT VUE Kind"
{
    Extensible = true;

    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
}

codeunit 67511 "LT VUE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure MatchZeroMember(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            "LT VUE Kind"::Zero:
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure MatchOneMember(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            "LT VUE Kind"::One:
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure MatchInteger0(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            0:
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure MatchInteger1(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            1:
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure MatchEmptyText(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            '':
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure MatchFalse(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            false:
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure MatchZeroDate(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            0D:
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure MatchDecimalZero(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            0.0:
                Matched := true;
        end;
    end;

    [TryFunction]
    local procedure TwoBranches(V: Variant; var Matched: Boolean)
    begin
        Matched := false;
        case V of
            "LT VUE Kind"::Zero:
                Matched := true;
            "LT VUE Kind"::One:
                Matched := true;
            else
                Matched := false;
        end;
    end;

    local procedure Outcome(Ok: Boolean; Matched: Boolean): Text
    begin
        exit('ran=' + Format(Ok) + ' matched=' + Format(Matched) + ' error=' + GetLastErrorText());
    end;

    local procedure MatchAll(var Observer: Codeunit "Probe Observer"; V: Variant)
    var
        Matched: Boolean;
    begin
        Observer.Observe('enum_zero', Outcome(MatchZeroMember(V, Matched), Matched));
        Observer.Observe('enum_one', Outcome(MatchOneMember(V, Matched), Matched));
        Observer.Observe('integer_0', Outcome(MatchInteger0(V, Matched), Matched));
        Observer.Observe('integer_1', Outcome(MatchInteger1(V, Matched), Matched));
        Observer.Observe('empty_text', Outcome(MatchEmptyText(V, Matched), Matched));
        Observer.Observe('false', Outcome(MatchFalse(V, Matched), Matched));
        Observer.Observe('zero_date', Outcome(MatchZeroDate(V, Matched), Matched));
        Observer.Observe('decimal_zero', Outcome(MatchDecimalZero(V, Matched), Matched));
    end;

    [Test]
    procedure Unassigned_Variant_Kind_Flags()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        Observer.Observe('is_integer', Format(V.IsInteger()));
        Observer.Observe('is_option', Format(V.IsOption()));
        Observer.Observe('is_text', Format(V.IsText()));
        Observer.Observe('is_boolean', Format(V.IsBoolean()));
        Observer.Observe('is_decimal', Format(V.IsDecimal()));
        Observer.Observe('is_code', Format(V.IsCode()));
        Observer.Observe('is_record', Format(V.IsRecord()));
        Observer.Observe('format', '[' + Format(V) + ']');
        Observer.Expect('is_integer', 'No');
        Observer.Expect('is_option', 'No');
        Observer.Expect('is_text', 'No');
        Observer.Expect('is_boolean', 'No');
        Observer.Expect('is_decimal', 'No');
        Observer.Expect('is_code', 'No');
        Observer.Expect('is_record', 'No');
        Observer.Expect('format', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Unassigned_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        MatchAll(Observer, V);
        Observer.Expect('enum_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('enum_one', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_0', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_1', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('empty_text', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('false', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('zero_date', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('decimal_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Verify();
    end;


    [Test]
    procedure Unassigned_Variant_CaseMatches_InsideProcedure()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Matched: Boolean;
    begin
        Observer.Observe('two_branches_and_else', Outcome(TwoBranches(V, Matched), Matched));
        Observer.Expect('two_branches_and_else', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Verify();
    end;

    [Test]
    procedure EnumZero_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Kind: Enum "LT VUE Kind";
    begin
        Kind := Kind::Zero;
        V := Kind;
        Observer.Observe('is_option', Format(V.IsOption()));
        MatchAll(Observer, V);
        Observer.Expect('is_option', 'Yes');
        Observer.Expect('enum_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('enum_one', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_0', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_1', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('empty_text', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('false', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('zero_date', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('decimal_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Verify();
    end;

    [Test]
    procedure EnumOne_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Kind: Enum "LT VUE Kind";
    begin
        Kind := Kind::One;
        V := Kind;
        MatchAll(Observer, V);
        Observer.Expect('enum_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('enum_one', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_0', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_1', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('empty_text', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('false', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('zero_date', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('decimal_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerZero_Variant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Zero: Integer;
    begin
        V := Zero;
        MatchAll(Observer, V);
        Observer.Expect('enum_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('enum_one', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_0', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_1', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('empty_text', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('false', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('zero_date', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('decimal_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Verify();
    end;

    [Test]
    procedure ClearedVariant_CaseMatches()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := 5;
        Clear(V);
        MatchAll(Observer, V);
        Observer.Expect('enum_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('enum_one', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_0', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('integer_1', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('empty_text', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('false', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('zero_date', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Expect('decimal_zero', 'ran=No matched=No error=Unable to compare operands of type NavVariant with NavVariant.');
        Observer.Verify();
    end;
}
