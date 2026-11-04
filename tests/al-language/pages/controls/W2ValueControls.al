// Probe: TestPage controls bound to page variables of Enum, Date, DateFormula and Duration type, and what SetValue does with each spelling.
// Settles: md:233 (enum caption / name), md:253 (Date ISO text, two-digit year), md:281 (DateFormula and Duration spellings).
// Every attempt runs through a TryFunction on a freshly opened page, so a refused spelling is observed instead of ending the test.

enum 68662 "W2 Tier"
{
    Extensible = true;

    value(0; Alpha) { Caption = 'First Tier'; }
    value(1; Beta) { Caption = 'Second Tier'; }
    value(2; Gamma) { }
}

table 68663 "W2 Value Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tier; Enum "W2 Tier") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 68664 "W2 Value Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Value Row";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(RecTierCtl; Rec.Tier)
            {
                ApplicationArea = All;
            }
            field(TierCtl; TierVar)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    TierOrd := TierVar.AsInteger();
                end;
            }
            field(TierOrdCtl; TierOrd)
            {
                ApplicationArea = All;
            }
            field(DateCtl; DateVar)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    DateXml := Format(DateVar, 0, 9);
                end;
            }
            field(DateXmlCtl; DateXml)
            {
                ApplicationArea = All;
            }
            field(FormulaCtl; FormulaVar)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    FormulaXml := Format(FormulaVar, 0, 9);
                end;
            }
            field(FormulaXmlCtl; FormulaXml)
            {
                ApplicationArea = All;
            }
            field(DurationCtl; DurationVar)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    DurationMs := DurationVar;
                end;
            }
            field(DurationMsCtl; DurationMs)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        TierVar: Enum "W2 Tier";
        TierOrd: Integer;
        DateVar: Date;
        DateXml: Text;
        FormulaVar: DateFormula;
        FormulaXml: Text;
        DurationVar: Duration;
        DurationMs: BigInteger;
}

codeunit 68665 "W2 Value Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---- md:233 Enum control ----

    [Test]
    procedure Enum_VariableControl_CaptionAndNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryEnum(Observer, 'caption', 'First Tier');
        TryEnum(Observer, 'name_of_captioned', 'Alpha');
        TryEnum(Observer, 'name_without_caption', 'Gamma');
        TryEnum(Observer, 'other_caption', 'Second Tier');
        Observer.Expect('caption|ok', 'Yes');
        Observer.Expect('caption|value', 'First Tier');
        Observer.Expect('caption|ordinal', '0');
        Observer.Expect('name_of_captioned|ok', 'No');
        Observer.Expect('name_of_captioned|text', 'Validation error for Field: TierCtl,  Message = ''Your entry of ''Alpha'' is not an acceptable value for ''TierCtl''.''');
        Observer.Expect('name_of_captioned|code', 'TestValidation');
        Observer.Expect('name_of_captioned|value', '0');
        Observer.Expect('name_of_captioned|ordinal', '0');
        Observer.Expect('name_without_caption|ok', 'Yes');
        Observer.Expect('name_without_caption|value', 'Gamma');
        Observer.Expect('name_without_caption|ordinal', '2');
        Observer.Expect('other_caption|ok', 'Yes');
        Observer.Expect('other_caption|value', 'Second Tier');
        Observer.Expect('other_caption|ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_VariableControl_OtherSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryEnum(Observer, 'caption_lower_case', 'first tier');
        TryEnum(Observer, 'ordinal_text', '1');
        TryEnum(Observer, 'name_of_second', 'Beta');
        TryEnum(Observer, 'empty', '');
        Observer.Expect('caption_lower_case|ok', 'Yes');
        Observer.Expect('caption_lower_case|value', 'First Tier');
        Observer.Expect('caption_lower_case|ordinal', '0');
        Observer.Expect('ordinal_text|ok', 'No');
        Observer.Expect('ordinal_text|text', 'Validation error for Field: TierCtl,  Message = ''Your entry of ''1'' is not an acceptable value for ''TierCtl''.''');
        Observer.Expect('ordinal_text|code', 'TestValidation');
        Observer.Expect('ordinal_text|value', '0');
        Observer.Expect('ordinal_text|ordinal', '0');
        Observer.Expect('name_of_second|ok', 'No');
        Observer.Expect('name_of_second|text', 'Validation error for Field: TierCtl,  Message = ''Your entry of ''Beta'' is not an acceptable value for ''TierCtl''.''');
        Observer.Expect('name_of_second|code', 'TestValidation');
        Observer.Expect('name_of_second|value', '0');
        Observer.Expect('name_of_second|ordinal', '0');
        Observer.Expect('empty|ok', 'No');
        Observer.Expect('empty|text', 'Validation error for Field: TierCtl,  Message = ''Your entry of '''' is not an acceptable value for ''TierCtl''.''');
        Observer.Expect('empty|code', 'TestValidation');
        Observer.Expect('empty|value', '0');
        Observer.Expect('empty|ordinal', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_RecordFieldControl_CaptionAndNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryRecEnum(Observer, 'caption', 'First Tier');
        TryRecEnum(Observer, 'name_of_captioned', 'Alpha');
        TryRecEnum(Observer, 'name_without_caption', 'Gamma');
        TryRecEnum(Observer, 'ordinal_text', '1');
        Observer.Expect('caption|ok', 'No');
        Observer.Expect('caption|text', 'The row does not exist on the TestPage.');
        Observer.Expect('caption|code', 'TestRowNotFound');
        Observer.Expect('caption|value', '');
        Observer.Expect('name_of_captioned|ok', 'No');
        Observer.Expect('name_of_captioned|text', 'Validation error for Field: RecTierCtl,  Message = ''Your entry of ''Alpha'' is not an acceptable value for ''Tier''.''');
        Observer.Expect('name_of_captioned|code', 'TestValidation');
        Observer.Expect('name_of_captioned|value', '');
        Observer.Expect('name_without_caption|ok', 'No');
        Observer.Expect('name_without_caption|text', 'The row does not exist on the TestPage.');
        Observer.Expect('name_without_caption|code', 'TestRowNotFound');
        Observer.Expect('name_without_caption|value', '');
        Observer.Expect('ordinal_text|ok', 'No');
        Observer.Expect('ordinal_text|text', 'Validation error for Field: RecTierCtl,  Message = ''Your entry of ''1'' is not an acceptable value for ''Tier''.''');
        Observer.Expect('ordinal_text|code', 'TestValidation');
        Observer.Expect('ordinal_text|value', '');
        Observer.Verify();
    end;

    // ---- md:253 Date control ----

    [Test]
    procedure Date_IsoSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDate(Observer, 'iso', '2024-01-02');
        TryDate(Observer, 'iso_end_of_year', '2024-12-31');
        TryDate(Observer, 'iso_single_digits', '2024-1-5');
        TryDate(Observer, 'iso_two_digit_year', '24-03-04');
        TryDate(Observer, 'compact', '20240102');
        TryDate(Observer, 'empty', '');
        Observer.Expect('iso|ok', 'Yes');
        Observer.Expect('iso|iso', '2024-01-02');
        Observer.Expect('iso_end_of_year|ok', 'Yes');
        Observer.Expect('iso_end_of_year|iso', '2024-12-31');
        Observer.Expect('iso_single_digits|ok', 'No');
        Observer.Expect('iso_single_digits|text', 'Validation error for Field: DateCtl,  Message = ''Your entry of ''2024-1-5'' is not an acceptable value for ''DateCtl''. The format of the Date ''2024-1-5'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.''');
        Observer.Expect('iso_single_digits|code', 'TestValidation');
        Observer.Expect('iso_single_digits|iso', '');
        Observer.Expect('iso_two_digit_year|ok', 'No');
        Observer.Expect('iso_two_digit_year|text', 'Validation error for Field: DateCtl,  Message = ''Your entry of ''24-03-04'' is not an acceptable value for ''DateCtl''. The format of the Date ''24-03-04'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.''');
        Observer.Expect('iso_two_digit_year|code', 'TestValidation');
        Observer.Expect('iso_two_digit_year|iso', '');
        Observer.Expect('compact|ok', 'No');
        Observer.Expect('compact|text', 'Validation error for Field: DateCtl,  Message = ''Your entry of ''20240102'' is not an acceptable value for ''DateCtl''. The format of the Date ''20240102'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.''');
        Observer.Expect('compact|code', 'TestValidation');
        Observer.Expect('compact|iso', '');
        Observer.Expect('empty|ok', 'Yes');
        Observer.Expect('empty|iso', '');
        Observer.Verify();
    end;

    // The session format of Format(date) is used as the text: whatever it looks like, Evaluate reads the same text, and the control is compared with it.
    [Test]
    procedure Date_SessionFormatTwoDigitYear_Earlier()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SessionFormatYear(Observer, 1929);
        SessionFormatYear(Observer, 1930);
        SessionFormatYear(Observer, 1999);
        Observer.Expect('y1929|text_length', '10');
        Observer.Expect('y1929|evaluate', 'Yes 1929-06-15');
        Observer.Expect('y1929|control|ok', 'Yes');
        Observer.Expect('y1929|control|iso', '1929-06-15');
        Observer.Expect('y1930|text_length', '10');
        Observer.Expect('y1930|evaluate', 'Yes 1930-06-15');
        Observer.Expect('y1930|control|ok', 'Yes');
        Observer.Expect('y1930|control|iso', '1930-06-15');
        Observer.Expect('y1999|text_length', '8');
        Observer.Expect('y1999|evaluate', 'Yes 1999-06-15');
        Observer.Expect('y1999|control|ok', 'Yes');
        Observer.Expect('y1999|control|iso', '1999-06-15');
        Observer.Verify();
    end;

    [Test]
    procedure Date_SessionFormatTwoDigitYear_Later()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SessionFormatYear(Observer, 2000);
        SessionFormatYear(Observer, 2029);
        SessionFormatYear(Observer, 2030);
        Observer.Expect('y2000|text_length', '8');
        Observer.Expect('y2000|evaluate', 'Yes 2000-06-15');
        Observer.Expect('y2000|control|ok', 'Yes');
        Observer.Expect('y2000|control|iso', '2000-06-15');
        Observer.Expect('y2029|text_length', '8');
        Observer.Expect('y2029|evaluate', 'Yes 2029-06-15');
        Observer.Expect('y2029|control|ok', 'Yes');
        Observer.Expect('y2029|control|iso', '2029-06-15');
        Observer.Expect('y2030|text_length', '8');
        Observer.Expect('y2030|evaluate', 'Yes 2030-06-15');
        Observer.Expect('y2030|control|ok', 'Yes');
        Observer.Expect('y2030|control|iso', '2030-06-15');
        Observer.Verify();
    end;

    local procedure SessionFormatYear(var Observer: Codeunit "Probe Observer"; Year: Integer)
    var
        Text: Text;
        Parsed: Date;
        Ok: Boolean;
    begin
        Text := Format(DMY2Date(15, 6, Year));
        Observer.Observe('y' + Format(Year) + '|text_length', Format(StrLen(Text)));
        Ok := Evaluate(Parsed, Text);
        Observer.Observe('y' + Format(Year) + '|evaluate', Format(Ok) + ' ' + Format(Parsed, 0, 9));
        TryDate(Observer, 'y' + Format(Year) + '|control', Text);
    end;

    // ---- md:281 DateFormula control ----

    [Test]
    procedure DateFormula_BracketsAndPlainSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryFormula(Observer, 'plain', '1M');
        TryFormula(Observer, 'bracketed', '<1M>');
        TryFormula(Observer, 'negative_with_current', '<-1M+CM>');
        TryFormula(Observer, 'two_terms_plain', '1W+2D');
        TryFormula(Observer, 'current_month_end', 'CM');
        TryFormula(Observer, 'empty', '');
        Observer.Expect('plain|ok', 'Yes');
        Observer.Expect('plain|value', '1M');
        Observer.Expect('plain|xml', '1M');
        Observer.Expect('bracketed|ok', 'Yes');
        Observer.Expect('bracketed|value', '1M');
        Observer.Expect('bracketed|xml', '1M');
        Observer.Expect('negative_with_current|ok', 'Yes');
        Observer.Expect('negative_with_current|value', '-1M+CM');
        Observer.Expect('negative_with_current|xml', '-1M+CM');
        Observer.Expect('two_terms_plain|ok', 'Yes');
        Observer.Expect('two_terms_plain|value', '1W+2D');
        Observer.Expect('two_terms_plain|xml', '1W+2D');
        Observer.Expect('current_month_end|ok', 'Yes');
        Observer.Expect('current_month_end|value', 'CM');
        Observer.Expect('current_month_end|xml', 'CM');
        Observer.Expect('empty|ok', 'Yes');
        Observer.Expect('empty|value', '');
        Observer.Expect('empty|xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_RefusedAndLeadingTokenSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryFormula(Observer, 'garbage', 'abc');
        TryFormula(Observer, 'text_after_bracket', '<1M>junk');
        TryFormula(Observer, 'text_after_term', '1M junk');
        Observer.Expect('garbage|ok', 'No');
        Observer.Expect('garbage|text', 'Validation error for Field: FormulaCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''FormulaCtl''. The date formula ''ABC'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.''');
        Observer.Expect('garbage|code', 'TestValidation');
        Observer.Expect('garbage|value', '');
        Observer.Expect('garbage|xml', '');
        Observer.Expect('text_after_bracket|ok', 'No');
        Observer.Expect('text_after_bracket|text', 'Validation error for Field: FormulaCtl,  Message = ''Your entry of ''<1M>junk'' is not an acceptable value for ''FormulaCtl''. The date formula ''<1M>JUNK'' must include plus (+) or minus (-).''');
        Observer.Expect('text_after_bracket|code', 'TestValidation');
        Observer.Expect('text_after_bracket|value', '');
        Observer.Expect('text_after_bracket|xml', '');
        Observer.Expect('text_after_term|ok', 'No');
        Observer.Expect('text_after_term|text', 'Validation error for Field: FormulaCtl,  Message = ''Your entry of ''1M junk'' is not an acceptable value for ''FormulaCtl''. The date formula ''1M JUNK'' must include plus (+) or minus (-).''');
        Observer.Expect('text_after_term|code', 'TestValidation');
        Observer.Expect('text_after_term|value', '');
        Observer.Expect('text_after_term|xml', '');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_MoreRefusedSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryFormula(Observer, 'trailing_plus', '1M+');
        TryFormula(Observer, 'lower_case', '1m');
        TryFormula(Observer, 'only_brackets', '<>');
        TryFormula(Observer, 'number_only', '5');
        Observer.Expect('trailing_plus|ok', 'No');
        Observer.Expect('trailing_plus|text', 'Validation error for Field: FormulaCtl,  Message = ''Your entry of ''1M+'' is not an acceptable value for ''FormulaCtl''. The date formula ''1M+'' should include a number.''');
        Observer.Expect('trailing_plus|code', 'TestValidation');
        Observer.Expect('trailing_plus|value', '');
        Observer.Expect('trailing_plus|xml', '');
        Observer.Expect('lower_case|ok', 'Yes');
        Observer.Expect('lower_case|value', '1M');
        Observer.Expect('lower_case|xml', '1M');
        Observer.Expect('only_brackets|ok', 'Yes');
        Observer.Expect('only_brackets|value', '');
        Observer.Expect('only_brackets|xml', '');
        Observer.Expect('number_only|ok', 'No');
        Observer.Expect('number_only|text', 'Validation error for Field: FormulaCtl,  Message = ''Your entry of ''5'' is not an acceptable value for ''FormulaCtl''. The date formula ''5'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.''');
        Observer.Expect('number_only|code', 'TestValidation');
        Observer.Expect('number_only|value', '');
        Observer.Expect('number_only|xml', '');
        Observer.Verify();
    end;

    // ---- md:281 Duration control ----

    [Test]
    procedure Duration_ShownSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDuration(Observer, 'all_units', '1 hour 2 minutes 3 seconds');
        TryDuration(Observer, 'one_hour', '1 hour');
        TryDuration(Observer, 'negative', '-1 hour');
        TryDuration(Observer, 'empty', '');
        TryDuration(Observer, 'day_and_millisecond', '1 day 2 milliseconds');
        TryDuration(Observer, 'plural_hours', '2 hours');
        Observer.Expect('all_units|ok', 'Yes');
        Observer.Expect('all_units|value', '1 hour 2 minutes 3 seconds');
        Observer.Expect('all_units|milliseconds', '3723000');
        Observer.Expect('one_hour|ok', 'Yes');
        Observer.Expect('one_hour|value', '1 hour');
        Observer.Expect('one_hour|milliseconds', '3600000');
        Observer.Expect('negative|ok', 'Yes');
        Observer.Expect('negative|value', '-1 hour');
        Observer.Expect('negative|milliseconds', '-3600000');
        Observer.Expect('empty|ok', 'Yes');
        Observer.Expect('empty|value', '');
        Observer.Expect('empty|milliseconds', '0');
        Observer.Expect('day_and_millisecond|ok', 'Yes');
        Observer.Expect('day_and_millisecond|value', '1 day 2 milliseconds');
        Observer.Expect('day_and_millisecond|milliseconds', '86400002');
        Observer.Expect('plural_hours|ok', 'Yes');
        Observer.Expect('plural_hours|value', '2 hours');
        Observer.Expect('plural_hours|milliseconds', '7200000');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_OtherSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDuration(Observer, 'abbreviation', '1h');
        TryDuration(Observer, 'minutes_only_large', '90 minutes');
        TryDuration(Observer, 'milliseconds_number', '3723000');
        TryDuration(Observer, 'decimal_hours', '1.5 hours');
        Observer.Expect('abbreviation|ok', 'Yes');
        Observer.Expect('abbreviation|value', '1 hour');
        Observer.Expect('abbreviation|milliseconds', '3600000');
        Observer.Expect('minutes_only_large|ok', 'Yes');
        Observer.Expect('minutes_only_large|value', '1 hour 30 minutes');
        Observer.Expect('minutes_only_large|milliseconds', '5400000');
        Observer.Expect('milliseconds_number|ok', 'Yes');
        Observer.Expect('milliseconds_number|value', '155125 days');
        Observer.Expect('milliseconds_number|milliseconds', '13402800000000');
        Observer.Expect('decimal_hours|ok', 'Yes');
        Observer.Expect('decimal_hours|value', '1 hour 30 minutes');
        Observer.Expect('decimal_hours|milliseconds', '5400000');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_MoreOtherSpellings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDuration(Observer, 'capitalised', '1 Hour');
        TryDuration(Observer, 'comma_separated', '1 hour, 2 minutes');
        TryDuration(Observer, 'garbage', 'abc');
        TryDuration(Observer, 'unit_order_swapped', '2 minutes 1 hour');
        Observer.Expect('capitalised|ok', 'Yes');
        Observer.Expect('capitalised|value', '1 hour');
        Observer.Expect('capitalised|milliseconds', '3600000');
        Observer.Expect('comma_separated|ok', 'No');
        Observer.Expect('comma_separated|text', 'Validation error for Field: DurationCtl,  Message = ''Your entry of ''1 hour, 2 minutes'' is not an acceptable value for ''DurationCtl''. The value "1 hour, 2 minutes" can''t be evaluated into type Duration.''');
        Observer.Expect('comma_separated|code', 'TestValidation');
        Observer.Expect('comma_separated|value', '');
        Observer.Expect('comma_separated|milliseconds', '0');
        Observer.Expect('garbage|ok', 'No');
        Observer.Expect('garbage|text', 'Validation error for Field: DurationCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''DurationCtl''. The value "abc" can''t be evaluated into type Duration.''');
        Observer.Expect('garbage|code', 'TestValidation');
        Observer.Expect('garbage|value', '');
        Observer.Expect('garbage|milliseconds', '0');
        Observer.Expect('unit_order_swapped|ok', 'Yes');
        Observer.Expect('unit_order_swapped|value', '1 hour 2 minutes');
        Observer.Expect('unit_order_swapped|milliseconds', '3720000');
        Observer.Verify();
    end;

    // ---- helpers: one fresh page per attempt ----

    local procedure TryEnum(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        Pg: TestPage "W2 Value Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Ok := SetEnum(Pg, Input);
        Observer.Observe(Name + '|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Pg.TierCtl.Value());
        Observer.Observe(Name + '|ordinal', Pg.TierOrdCtl.Value());
        Pg.Close();
    end;

    local procedure TryRecEnum(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        Pg: TestPage "W2 Value Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Ok := SetRecEnum(Pg, Input);
        Observer.Observe(Name + '|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Pg.RecTierCtl.Value());
        Pg.Close();
    end;

    local procedure TryDate(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        Pg: TestPage "W2 Value Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Ok := SetDate(Pg, Input);
        Observer.Observe(Name + '|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|iso', Pg.DateXmlCtl.Value());
        Pg.Close();
    end;

    local procedure TryFormula(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        Pg: TestPage "W2 Value Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Ok := SetFormula(Pg, Input);
        Observer.Observe(Name + '|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Pg.FormulaCtl.Value());
        Observer.Observe(Name + '|xml', Pg.FormulaXmlCtl.Value());
        Pg.Close();
    end;

    local procedure TryDuration(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        Pg: TestPage "W2 Value Card";
        Ok: Boolean;
    begin
        Pg.OpenEdit();
        Ok := SetDuration(Pg, Input);
        Observer.Observe(Name + '|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Pg.DurationCtl.Value());
        Observer.Observe(Name + '|milliseconds', Pg.DurationMsCtl.Value());
        Pg.Close();
    end;

    [TryFunction]
    local procedure SetEnum(var Pg: TestPage "W2 Value Card"; Input: Text)
    begin
        Pg.TierCtl.SetValue(Input);
    end;

    [TryFunction]
    local procedure SetRecEnum(var Pg: TestPage "W2 Value Card"; Input: Text)
    begin
        Pg.RecTierCtl.SetValue(Input);
    end;

    [TryFunction]
    local procedure SetDate(var Pg: TestPage "W2 Value Card"; Input: Text)
    begin
        Pg.DateCtl.SetValue(Input);
    end;

    [TryFunction]
    local procedure SetFormula(var Pg: TestPage "W2 Value Card"; Input: Text)
    begin
        Pg.FormulaCtl.SetValue(Input);
    end;

    [TryFunction]
    local procedure SetDuration(var Pg: TestPage "W2 Value Card"; Input: Text)
    begin
        Pg.DurationCtl.SetValue(Input);
    end;
}
