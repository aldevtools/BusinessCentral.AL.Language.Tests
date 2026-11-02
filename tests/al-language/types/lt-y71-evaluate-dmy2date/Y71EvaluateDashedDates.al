// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93824, enum 93825, test codeunit 93826 (writer Y71, gap cycle 7 spec G7-06)
// Probe: Evaluate of a Date from dashed, dotted and slashed texts with leading and trailing blanks (the Filter Tokens module of the System
//        Application reads ` 01-01-2012 ` that way after removing the leading blanks), with the order of day and month (en-US), two- and
//        four-digit years, and DMY2Date with the argument kinds Microsoft code hands over: an Enum AsInteger() result, an Integer table field, Byte,
//        BigInteger, Decimal, Option, Char and Integer.
//        Per call: the Boolean result and Format(date, 0, 9), or the error text and code of the statement form.
//        DMY2Date with one or two arguments is pinned in errors/lt-ms-refusals-133/P133DateEvaluateFormat.al.

table 93824 "LT Y71 DMY Tab"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; IntField; Integer) { }
        field(3; EnumField; Enum "LT Y71 DMY Month") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 93825 "LT Y71 DMY Month"
{
    Extensible = false;

    value(0; Zero) { }
    value(1; One) { }
    value(3; Three) { }
}

codeunit 93826 "LT Y71 Evaluate Dashed Dates"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Ev(Name: Text; Value: Text)
    var
        D: Date;
        Ok: Boolean;
    begin
        Ok := Evaluate(D, Value);
        Obs.Observe(Name, StrSubstNo('%1|%2', Ok, Format(D, 0, 9)));
    end;

    [TryFunction]
    local procedure TryEvaluate(Value: Text; var D: Date)
    begin
        Evaluate(D, Value);
    end;

    local procedure EvStatement(Name: Text; Value: Text)
    var
        D: Date;
    begin
        if TryEvaluate(Value, D) then
            Obs.Observe(Name, 'ok|' + Format(D, 0, 9))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure Evaluate_DashedDate_Blanks()
    begin
        Ev('plain', '01-01-2012');
        Ev('trailing', '01-01-2012 ');
        Ev('leading', ' 01-01-2012');
        Ev('both', ' 01-01-2012 ');
        Ev('two_digit_year', '11-11-12');
        Ev('two_digit_year_trailing', '11-11-12 ');
        Ev('day_13', '13-01-2012');
        Ev('month_13', '01-13-2012');
        Ev('single_digits', '1-1-2012');
        Ev('day_first_ambiguous', '05-03-2024');
        Ev('year_first', '2012-01-31');
        Ev('year_first_trailing', '2012-01-31 ');
        Obs.Finish();
    end;

    [Test]
    procedure Evaluate_DashedDate_AfterLeadingBlanksRemoved()
    var
        Value: Text;
    begin
        Value := DelChr(' 01-01-2012 ', '<', ' ');
        Ev('trimmed_leading', Value);
        Value := DelChr(' 11-11-12 ', '<', ' ');
        Ev('trimmed_leading_short_year', Value);
        Value := DelChr('  01-01-2012', '<', ' ');
        Ev('two_blanks_removed', Value);
        EvStatement('statement_trailing', '01-01-2012 ');
        EvStatement('statement_clean', '01-01-2012');
        EvStatement('statement_garbage', '01-xx-2012');
        EvStatement('statement_trailing_two', '01-01-2012  ');
        Obs.Finish();
    end;

    [Test]
    procedure Evaluate_DottedAndSlashed_Blanks()
    begin
        Ev('dotted_trailing', '05.03.2024 ');
        Ev('dotted_leading_short', ' 05.03.24');
        Ev('slashed_trailing', '03/05/2024 ');
        Ev('slashed_both_short', ' 3/5/24 ');
        Ev('dotted_plain', '05.03.2024');
        Ev('slashed_plain', '03/05/2024');
        Ev('slashed_day_13', '13/05/2024');
        Ev('slashed_month_13', '05/13/2024');
        Obs.Finish();
    end;

    [TryFunction]
    local procedure TryDmy(Which: Integer; var Answer: Date)
    var
        Rec: Record "LT Y71 DMY Tab";
        E: Enum "LT Y71 DMY Month";
        B: Byte;
        Big: BigInteger;
        Dec: Decimal;
        Opt: Option Zero,One,Two,Three;
        Ch: Char;
        I: Integer;
    begin
        Rec.IntField := 1;
        Rec.EnumField := Rec.EnumField::Three;
        E := E::Three;
        B := 3;
        Big := 3;
        Dec := 3;
        Opt := Opt::Three;
        Ch := 3;
        I := 3;
        case Which of
            1:
                Answer := DMY2Date(1, E.AsInteger(), 2026);
            2:
                Answer := DMY2Date(Rec.IntField, 3, 2026);
            3:
                Answer := DMY2Date(1, B, 2026);
            4:
                Answer := DMY2Date(1, Big, 2026);
            5:
                Answer := DMY2Date(1, Dec, 2026);
            6:
                Answer := DMY2Date(1, Opt, 2026);
            7:
                Answer := DMY2Date(1, Ch, 2026);
            8:
                Answer := DMY2Date(1, Rec.EnumField.AsInteger(), Date2DMY(20260315D, 3));
            9:
                Answer := DMY2Date(Rec.IntField, I, Date2DMY(20260315D, 3));
            10:
                Answer := DMY2Date(1, I, 2026);
        end;
    end;

    local procedure Dmy(Name: Text; Which: Integer)
    var
        Answer: Date;
    begin
        if TryDmy(Which, Answer) then
            Obs.Observe(Name, Format(Answer, 0, 9))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure DMY2Date_ArgumentKinds()
    begin
        Dmy('enum_asinteger', 1);
        Dmy('integer_field_day', 2);
        Dmy('byte_month', 3);
        Dmy('biginteger_month', 4);
        Dmy('decimal_month', 5);
        Dmy('option_month', 6);
        Dmy('char_month', 7);
        Dmy('enum_field_asinteger_date2dmy_year', 8);
        Dmy('integer_variable', 9);
        Dmy('integer_month', 10);
        Obs.Finish();
    end;
}
