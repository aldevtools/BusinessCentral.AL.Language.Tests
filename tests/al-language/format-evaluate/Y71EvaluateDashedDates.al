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
        Obs.Expect('plain', 'Yes|2012-01-01');
        Obs.Expect('trailing', 'Yes|2012-01-01');
        Obs.Expect('leading', 'Yes|2012-01-01');
        Obs.Expect('both', 'Yes|2012-01-01');
        Obs.Expect('two_digit_year', 'Yes|2012-11-11');
        Obs.Expect('two_digit_year_trailing', 'Yes|2012-11-11');
        Obs.Expect('day_13', 'No|');
        Obs.Expect('month_13', 'Yes|2012-01-13');
        Obs.Expect('single_digits', 'Yes|2012-01-01');
        Obs.Expect('day_first_ambiguous', 'Yes|2024-05-03');
        Obs.Expect('year_first', 'Yes|2012-01-31');
        Obs.Expect('year_first_trailing', 'Yes|2012-01-31');
        Obs.Verify();
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
        Obs.Expect('trimmed_leading', 'Yes|2012-01-01');
        Obs.Expect('trimmed_leading_short_year', 'Yes|2012-11-11');
        Obs.Expect('two_blanks_removed', 'Yes|2012-01-01');
        Obs.Expect('statement_trailing', 'ok|2012-01-01');
        Obs.Expect('statement_clean', 'ok|2012-01-01');
        Obs.Expect('statement_garbage', 'ok|2012-01-20');
        Obs.Expect('statement_trailing_two', 'ok|2012-01-01');
        Obs.Verify();
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
        Obs.Expect('dotted_trailing', 'Yes|2024-05-03');
        Obs.Expect('dotted_leading_short', 'Yes|2024-05-03');
        Obs.Expect('slashed_trailing', 'Yes|2024-03-05');
        Obs.Expect('slashed_both_short', 'Yes|2024-03-05');
        Obs.Expect('dotted_plain', 'Yes|2024-05-03');
        Obs.Expect('slashed_plain', 'Yes|2024-03-05');
        Obs.Expect('slashed_day_13', 'No|');
        Obs.Expect('slashed_month_13', 'Yes|2024-05-13');
        Obs.Verify();
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
        Obs.Expect('enum_asinteger', '2026-03-01');
        Obs.Expect('integer_field_day', '2026-03-01');
        Obs.Expect('byte_month', '2026-03-01');
        Obs.Expect('biginteger_month', '2026-03-01');
        Obs.Expect('decimal_month', '2026-03-01');
        Obs.Expect('option_month', '2026-03-01');
        Obs.Expect('char_month', '2026-03-01');
        Obs.Expect('enum_field_asinteger_date2dmy_year', '2026-03-01');
        Obs.Expect('integer_variable', '2026-03-01');
        Obs.Expect('integer_month', '2026-03-01');
        Obs.Verify();
    end;

    // Evaluate into a Date of a date text with a trailing D (al-runner issue 7363: Config. Validate Management stores Format(Date) + 'D' as a default value),
    // of filter texts with an operator (issue 7364: Filter Tokens.MakeDateFilter), and into a DateTime of a date-only text (issue 7384).
    local procedure DeEv(Name: Text; Value: Text)
    var
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        Ev(Name, Value);
        GlobalLanguage(Saved);
    end;

    [Test]
    procedure Evaluate_Date_TrailingD_En()
    begin
        Ev('slash_2y_D', '12/09/26D');
        Ev('slash_4y_D', '12/09/2026D');
        Ev('slash_2y_d_lower', '12/09/26d');
        Ev('slash_2y_blank_D', '12/09/26 D');
        Ev('slash_01_01_D', '01/01/26D');
        Ev('dash_D', '12-09-26D');
        Ev('dot_D', '12.09.26D');
        Ev('compact_D', '120926D');
        Ev('compact_4y_D', '12092026D');
        Ev('day_13_D', '13/09/26D');
        Ev('only_D', 'D');
        Ev('digits_D', '1D');
        Ev('zero_D', '0D');
        Ev('double_D', '12/09/26DD');
        Ev('trailing_blank_D', '12/09/26D ');
        Ev('plain_control', '12/09/26');
        Obs.Finish();
    end;

    [Test]
    procedure Evaluate_Date_TrailingD_De()
    begin
        DeEv('de_dot_2y_D', '12.09.26D');
        DeEv('de_dot_4y_D', '12.09.2026D');
        DeEv('de_slash_2y_D', '12/09/26D');
        DeEv('de_dot_plain_control', '12.09.26');
        DeEv('de_zero_D', '0D');
        Obs.Finish();
    end;

    [Test]
    procedure Evaluate_Date_FilterOperatorTexts()
    begin
        Ev('le', '<=11/09/26');
        Ev('ge', '>=11/09/26');
        Ev('lt', '<11/09/26');
        Ev('gt', '>11/09/26');
        Ev('ne', '<>11/09/26');
        Ev('eq', '=11/09/26');
        Ev('le_blank', '<= 11/09/26');
        Ev('le_4y', '<=11/09/2026');
        Ev('range', '11/09/26..12/09/26');
        Ev('range_open_start', '..11/09/26');
        Ev('range_open_end', '11/09/26..');
        Ev('le_alone', '<=');
        Ev('le_dash', '<=11-09-26');
        Obs.Finish();
    end;

    [Test]
    procedure Evaluate_Date_FilterOperatorTexts_De()
    begin
        DeEv('de_le', '<=11.09.26');
        DeEv('de_le_4y', '<=11.09.2026');
        DeEv('de_ge', '>=11.09.26');
        DeEv('de_le_slash', '<=11/09/26');
        Obs.Finish();
    end;

    local procedure MakeDate(Name: Text; Filter: Text)
    begin
        if TryMakeDate(Filter) then
            Obs.Observe(Name, Filter)
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [TryFunction]
    local procedure TryMakeDate(var Filter: Text)
    var
        FilterTokens: Codeunit System.Text."Filter Tokens";
    begin
        FilterTokens.MakeDateFilter(Filter);
    end;

    [Test]
    procedure FilterTokens_MakeDateFilter_OperatorTexts()
    begin
        MakeDate('le', '<=11/09/26');
        MakeDate('ge', '>=11/09/26');
        MakeDate('range', '11/09/26..12/09/26');
        MakeDate('plain', '11/09/26');
        MakeDate('today_token', '%today');
        MakeDate('le_4y', '<=11/09/2026');
        MakeDate('empty', '');
        Obs.Finish();
    end;

    local procedure EvDT(Name: Text; Value: Text)
    var
        DT: DateTime;
        Ok: Boolean;
    begin
        DT := CreateDateTime(DMY2Date(5, 5, 2005), 123456T);
        Ok := Evaluate(DT, Value);
        Obs.Observe(Name, StrSubstNo('%1|%2|%3', Ok, Format(DT, 0, 9), Format(DT)));
    end;

    local procedure EvDTFormat(Name: Text; Value: Text; FormatNumber: Integer)
    var
        DT: DateTime;
        Ok: Boolean;
    begin
        Ok := Evaluate(DT, Value, FormatNumber);
        Obs.Observe(Name, StrSubstNo('%1|%2', Ok, Format(DT, 0, 9)));
    end;

    [Test]
    procedure Evaluate_DateTime_DateOnlyText_En()
    begin
        EvDT('slash_2y', '01/01/26');
        EvDT('slash_2y_23', '01/01/23');
        EvDT('slash_2y_nov', '11/01/26');
        EvDT('slash_4y', '01/01/2026');
        EvDT('slash_day_13', '13/01/26');
        EvDT('dash', '01-01-26');
        EvDT('dot', '01.01.26');
        EvDT('compact', '010126');
        EvDT('iso_date', '2026-01-01');
        EvDT('iso_date_t', '2026-01-01T00:00:00');
        Obs.Finish();
    end;

    [Test]
    procedure Evaluate_DateTime_DateAndTimeText_En()
    begin
        EvDT('date_time', '01/01/26 12:00:00');
        EvDT('date_time_short', '01/01/26 12:00');
        EvDT('date_blank', '01/01/26 ');
        EvDT('garbage', '01/xx/26');
        EvDT('empty', '');
        EvDTFormat('format9_date_only', '2026-01-01', 9);
        EvDTFormat('format9_slash', '01/01/26', 9);
        Obs.Finish();
    end;

    [Test]
    procedure Evaluate_DateTime_DateOnlyText_De()
    var
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvDT('de_dot_2y', '01.01.26');
        EvDT('de_dot_4y', '01.01.2026');
        EvDT('de_slash_2y', '01/01/26');
        EvDT('de_date_time', '01.01.26 12:00:00');
        GlobalLanguage(Saved);
        Obs.Finish();
    end;
}
