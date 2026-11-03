// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74464, enum 74465, test codeunit 74466
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a Variant that holds a Text assigned to a Decimal (value or error text and code); Format of a Time with <Hours24,2> at midnight and from 01:00 to 09:00 and with <Minutes> below 10 and without a width; SetFilter on an Enum field with a text that matches no caption and no name (error text and code), and with a matching name and caption.
// BC versions: 29 (27 and 28 by CI)

table 74464 "LT VT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT VT Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

enum 74465 "LT VT Kind"
{
    Extensible = true;

    value(0; Alpha) { Caption = 'Alpha Caption'; }
    value(1; Beta) { Caption = 'Beta Caption'; }
}

codeunit 74466 "LT Variant Time Enum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryToDecimal(V: Variant; var D: Decimal)
    begin
        D := V;
    end;

    local procedure DecimalOf(V: Variant): Text
    var
        D: Decimal;
    begin
        ClearLastError();
        if TryToDecimal(V, D) then
            exit('ok|' + Format(D, 0, 9));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [Test]
    procedure Variant_Text_ToDecimal()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := '-111.69';
        Observer.Observe('negative', DecimalOf(T));
        T := '5';
        Observer.Observe('integer_text', DecimalOf(T));
        T := '1,000.5';
        Observer.Observe('thousands', DecimalOf(T));
        T := '';
        Observer.Observe('empty', DecimalOf(T));
        T := 'x';
        Observer.Observe('letters', DecimalOf(T));
        T := ' 7 ';
        Observer.Observe('spaces', DecimalOf(T));
        T := '1e3';
        Observer.Observe('exponent', DecimalOf(T));
        Observer.Expect('negative', 'ok|-111.69');
        Observer.Expect('integer_text', 'ok|5');
        Observer.Expect('thousands', 'ok|1000.5');
        Observer.Expect('empty', 'error|TypeConversion:Format|The expression Variant cannot be type-converted to a Decimal value.');
        Observer.Expect('letters', 'error|TypeConversion:Format|The expression Variant cannot be type-converted to a Decimal value.');
        Observer.Expect('spaces', 'ok|7');
        Observer.Expect('exponent', 'error|TypeConversion:Format|The expression Variant cannot be type-converted to a Decimal value.');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_CodeAndOtherTypes_ToDecimal()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[10];
        I: Integer;
        B: Boolean;
    begin
        C := '12.5';
        Observer.Observe('code', DecimalOf(C));
        I := 42;
        Observer.Observe('integer', DecimalOf(I));
        B := true;
        Observer.Observe('boolean', DecimalOf(B));
        Observer.Expect('code', 'ok|12.5');
        Observer.Expect('integer', 'ok|42');
        Observer.Expect('boolean', 'ok|1');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Time_Hours24AndMinutes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('midnight', Format(000000T, 0, '<Hours24,2>'));
        Observer.Observe('h1', Format(010000T, 0, '<Hours24,2>'));
        Observer.Observe('h5', Format(050000T, 0, '<Hours24,2>'));
        Observer.Observe('h9', Format(090000T, 0, '<Hours24,2>'));
        Observer.Observe('h10', Format(100000T, 0, '<Hours24,2>'));
        Observer.Observe('h23', Format(230000T, 0, '<Hours24,2>'));
        Observer.Observe('midnight_no_width', Format(000000T, 0, '<Hours24>'));
        Observer.Observe('h9_no_width', Format(090000T, 0, '<Hours24>'));
        Observer.Observe('min0', Format(120000T, 0, '<Minutes>'));
        Observer.Observe('min5', Format(120500T, 0, '<Minutes>'));
        Observer.Observe('min9', Format(120900T, 0, '<Minutes>'));
        Observer.Observe('min10', Format(121000T, 0, '<Minutes>'));
        Observer.Observe('min5_width2', Format(120500T, 0, '<Minutes,2>'));
        Observer.Observe('undefined_time', Format(0T, 0, '<Hours24,2>:<Minutes,2>'));
        Observer.Observe('combined', Format(070503T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Expect('midnight', ' 0');
        Observer.Expect('h1', ' 1');
        Observer.Expect('h5', ' 5');
        Observer.Expect('h9', ' 9');
        Observer.Expect('h10', '10');
        Observer.Expect('h23', '23');
        Observer.Expect('midnight_no_width', '0');
        Observer.Expect('h9_no_width', '9');
        Observer.Expect('min0', '0');
        Observer.Expect('min5', '5');
        Observer.Expect('min9', '9');
        Observer.Expect('min10', '10');
        Observer.Expect('min5_width2', '05');
        Observer.Expect('undefined_time', ' 0:00');
        Observer.Expect('combined', ' 7:05:03');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetFilter(var Row: Record "LT VT Row"; Filter: Text)
    begin
        Row.SetFilter(Kind, Filter);
    end;

    local procedure FilterOf(var Row: Record "LT VT Row"; Filter: Text): Text
    begin
        Row.Reset();
        ClearLastError();
        if TrySetFilter(Row, Filter) then
            exit('ok|' + Format(Row.Count()));
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [Test]
    procedure SetFilter_EnumField_UnknownText()
    var
        Row: Record "LT VT Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1; Row.Kind := Row.Kind::Alpha; Row.Insert();
        Row.Id := 2; Row.Kind := Row.Kind::Beta; Row.Insert();
        Observer.Observe('unknown', FilterOf(Row, 'Gamma'));
        Observer.Observe('number_out_of_range', FilterOf(Row, '5'));
        Observer.Observe('one_known_one_unknown', FilterOf(Row, 'Alpha|Gamma'));
        Observer.Observe('by_name', FilterOf(Row, 'Beta'));
        Observer.Observe('by_caption', FilterOf(Row, 'Beta Caption'));
        Observer.Observe('by_ordinal', FilterOf(Row, '1'));
        Observer.Observe('lower_case_name', FilterOf(Row, 'beta'));
        Observer.Observe('partial_name', FilterOf(Row, 'Bet'));
        Observer.Observe('wildcard', FilterOf(Row, 'Bet*'));
        Observer.Observe('blank_filter', FilterOf(Row, ''));
        Observer.Expect('unknown', 'error|Filter:CSide|The filter "Gamma" is not valid for the Kind field on the LT VT Row table. ''Gamma'' is not an option. The existing options are: Alpha Caption,Beta Caption');
        Observer.Expect('number_out_of_range', 'ok|0');
        Observer.Expect('one_known_one_unknown', 'error|Filter:CSide|The filter "Alpha|Gamma" is not valid for the Kind field on the LT VT Row table. ''Gamma'' is not an option. The existing options are: Alpha Caption,Beta Caption');
        Observer.Expect('by_name', 'ok|1');
        Observer.Expect('by_caption', 'ok|1');
        Observer.Expect('by_ordinal', 'ok|1');
        Observer.Expect('lower_case_name', 'ok|1');
        Observer.Expect('partial_name', 'error|Filter:CSide|The filter "Bet" is not valid for the Kind field on the LT VT Row table. ''Bet'' is not an option. The existing options are: Alpha Caption,Beta Caption');
        Observer.Expect('wildcard', 'error|Filter:CSide|The filter "Bet*" is not valid for the Kind field on the LT VT Row table. ''Bet*'' is not an option. The existing options are: Alpha Caption,Beta Caption');
        Observer.Expect('blank_filter', 'ok|2');
        Observer.Verify();
    end;
}
