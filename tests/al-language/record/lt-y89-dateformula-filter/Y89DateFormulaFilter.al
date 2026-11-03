// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94740, test codeunit 94741
// Probe (writer Y89, from the runtime lane rt-values-1103): Record.SetFilter on a DateFormula field. errors/lt-ms-refusals-136/P136Filter.al:225 pins that '1M|1D' on rows 1M, 1D, blank, 1M counts 2
// where a union of the single filters would count 3; this probe measures which rows (by Id) every OR / AND / range / comparison form matches, so the rule is visible: the formulas written
// as 1M, 1D, 1W, -1M, CM and 1D+1M, in either order, repeated, with a blank term, with <> and with the comparison signs, and the same text on the
// Format(DF) of the rows. Each observation is the list of matched Ids and GetFilter.
// BC versions: 27, 28, 29

table 94740 "LT Y89 DF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; DF; DateFormula) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 94741 "LT Y89 DateFormula Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT Y89 DF Row";
        Forms: List of [Text];
        I: Integer;
    begin
        R.DeleteAll();
        Forms.Add('<1M>');
        Forms.Add('<1D>');
        Forms.Add('');
        Forms.Add('<1M>');
        Forms.Add('<1W>');
        Forms.Add('<-1M>');
        Forms.Add('<CM>');
        Forms.Add('<1D+1M>');
        for I := 1 to Forms.Count() do begin
            R.Init();
            R.Id := I;
            if Forms.Get(I) <> '' then
                Evaluate(R.DF, Forms.Get(I));
            R.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryFilter(Txt: Text; var Outcome: Text)
    var
        R: Record "LT Y89 DF Row";
    begin
        R.SetFilter(DF, Txt);
        Outcome := '';
        if R.FindSet() then
            repeat
                if Outcome <> '' then
                    Outcome += ',';
                Outcome += Format(R.Id);
            until R.Next() = 0;
        Outcome := Format(R.Count()) + '|' + Outcome + '|' + R.GetFilter(DF);
    end;

    local procedure F(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryFilter(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure Y89_DF_Single()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        F(Observer, '0 1M', '1M');
        F(Observer, '1 1D', '1D');
        F(Observer, '2 1W', '1W');
        F(Observer, '3 1Y', '1Y');
        F(Observer, '4 1Q', '1Q');
        F(Observer, '5 1WD', '1WD');
        F(Observer, '6 -1M', '-1M');
        F(Observer, '7 +1M', '+1M');
        F(Observer, '8 CM', 'CM');
        F(Observer, '9 1D+1M', '1D+1M');
        F(Observer, '10 1M+1D', '1M+1D');
        F(Observer, '11 <1M>', '<1M>');
        F(Observer, '12 <1D+1M>', '<1D+1M>');
        F(Observer, '13 1m', '1m');
        F(Observer, '14 1d', '1d');
        F(Observer, '15 0D', '0D');
        F(Observer, '16 1M1D', '1M1D');
        Observer.Expect('0 1M', '2|1,4|1M');
        Observer.Expect('1 1D', '1|2|1D');
        Observer.Expect('2 1W', '1|5|1W');
        Observer.Expect('3 1Y', '0||1Y');
        Observer.Expect('4 1Q', '0||1Q');
        Observer.Expect('5 1WD', '0||1WD');
        Observer.Expect('6 -1M', '1|6|-1M');
        Observer.Expect('7 +1M', '0||+1M');
        Observer.Expect('8 CM', '1|7|CM');
        Observer.Expect('9 1D+1M', '1|8|1D+1M');
        Observer.Expect('10 1M+1D', '0||1M+1D');
        Observer.Expect('11 <1M>|text', 'The filter "<1M>" is not valid for the DF field on the LT Y89 DF Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('11 <1M>|code', 'Filter:CSide');
        Observer.Expect('12 <1D+1M>|text', 'The filter "<1D+1M>" is not valid for the DF field on the LT Y89 DF Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('12 <1D+1M>|code', 'Filter:CSide');
        Observer.Expect('13 1m', '2|1,4|1M');
        Observer.Expect('14 1d', '1|2|1D');
        Observer.Expect('15 0D', '0||0D');
        Observer.Expect('16 1M1D|text', 'The filter "1M1D" is not valid for the DF field on the LT Y89 DF Row table. The date formula ''1M1D'' must include plus (+) or minus (-).');
        Observer.Expect('16 1M1D|code', 'Filter:CSide');
        Observer.Verify();
    end;

    // Linux suspect (writer Y89): the values below are Windows BC 27.5 and 28.5. The Linux containers (27.5, 28.5, 29.0) differ, for example
    // they count 2 for '1M|1D' (as errors/lt-ms-refusals-136/P136Filter.al:248 asserts) where Windows counts the union, 3 rows. Not a test until the Windows nightly decides for BC 29.
    procedure Y89_DF_Or()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        F(Observer, '0 1M|1D', '1M|1D');
        F(Observer, '1 1D|1M', '1D|1M');
        F(Observer, '2 1M|1M', '1M|1M');
        F(Observer, '3 1D|1D', '1D|1D');
        F(Observer, '4 1M|', '1M|');
        F(Observer, '5 |1M', '|1M');
        F(Observer, '6 1M|1D|1W', '1M|1D|1W');
        F(Observer, '7 1D|1W|1M', '1D|1W|1M');
        F(Observer, '8 1M|-1M', '1M|-1M');
        F(Observer, '9 1M|CM', '1M|CM');
        F(Observer, '10 1D+1M|1D', '1D+1M|1D');
        F(Observer, '11 1M|<>1M', '1M|<>1M');
        F(Observer, '12 1M|0D', '1M|0D');
        F(Observer, '13 1M|x', '1M|x');
        F(Observer, '14 x|1M', 'x|1M');
        F(Observer, '15 1M||1D', '1M||1D');
        F(Observer, '16 1M| |1D', '1M| |1D');
        F(Observer, '17 (1M|1D)', '(1M|1D)');
        F(Observer, '18 1M|1D+1M|1W', '1M|1D+1M|1W');
        Observer.Expect('0 1M|1D', '3|1,2,4|1M|1D');
        Observer.Expect('1 1D|1M', '3|1,2,4|1D|1M');
        Observer.Expect('2 1M|1M', '2|1,4|1M|1M');
        Observer.Expect('3 1D|1D', '1|2|1D|1D');
        Observer.Expect('4 1M||text', 'The filter "1M|" is not valid for the DF field on the LT Y89 DF Row table. The right side of ''|'' operators cannot be empty.');
        Observer.Expect('4 1M||code', 'Filter:CSide');
        Observer.Expect('5 |1M|text', 'The filter "|1M" is not valid for the DF field on the LT Y89 DF Row table. The left side of ''|'' operators cannot be empty.');
        Observer.Expect('5 |1M|code', 'Filter:CSide');
        Observer.Expect('6 1M|1D|1W', '4|1,2,4,5|1M|1D|1W');
        Observer.Expect('7 1D|1W|1M', '4|1,2,4,5|1D|1W|1M');
        Observer.Expect('8 1M|-1M', '3|1,4,6|1M|-1M');
        Observer.Expect('9 1M|CM', '3|1,4,7|1M|CM');
        Observer.Expect('10 1D+1M|1D', '2|2,8|1D+1M|1D');
        Observer.Expect('11 1M|<>1M', '8|1,2,3,4,5,6,7,8|1M|<>1M');
        Observer.Expect('12 1M|0D', '2|1,4|1M|0D');
        Observer.Expect('13 1M|x|text', 'The filter "1M|x" is not valid for the DF field on the LT Y89 DF Row table. The date formula ''X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('13 1M|x|code', 'Filter:CSide');
        Observer.Expect('14 x|1M|text', 'The filter "x|1M" is not valid for the DF field on the LT Y89 DF Row table. The date formula ''X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('14 x|1M|code', 'Filter:CSide');
        Observer.Expect('15 1M||1D|text', 'The filter "1M||1D" is not valid for the DF field on the LT Y89 DF Row table. The right side of ''|'' operators cannot be empty.');
        Observer.Expect('15 1M||1D|code', 'Filter:CSide');
        Observer.Expect('16 1M| |1D|text', 'The filter "1M| |1D" is not valid for the DF field on the LT Y89 DF Row table. The right side of ''|'' operators cannot be empty.');
        Observer.Expect('16 1M| |1D|code', 'Filter:CSide');
        Observer.Expect('17 (1M|1D)', '3|1,2,4|1M|1D');
        Observer.Expect('18 1M|1D+1M|1W', '4|1,4,5,8|1M|1D+1M|1W');
        Observer.Verify();
    end;

    // Linux suspect (writer Y89): the values below are Windows BC 27.5 and 28.5. The Linux containers (27.5, 28.5, 29.0) differ, for example
    // they count 2 for '1M|1D' (as errors/lt-ms-refusals-136/P136Filter.al:248 asserts) where Windows counts the union, 3 rows. Not a test until the Windows nightly decides for BC 29.
    procedure Y89_DF_AndRange()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        F(Observer, '0 1M&1D', '1M&1D');
        F(Observer, '1 1M&<>1D', '1M&<>1D');
        F(Observer, '2 <>1M&<>1D', '<>1M&<>1D');
        F(Observer, '3 <>1M&<>1D&<>', '<>1M&<>1D&<>');
        F(Observer, '4 1D..1M', '1D..1M');
        F(Observer, '5 1M..1D', '1M..1D');
        F(Observer, '6 1D..1M|1W', '1D..1M|1W');
        F(Observer, '7 1D..', '1D..');
        F(Observer, '8 ..1M', '..1M');
        F(Observer, '9 >1D', '>1D');
        F(Observer, '10 <1M', '<1M');
        F(Observer, '11 >=1D&<=1M', '>=1D&<=1M');
        F(Observer, '12 >=1D&<1M', '>=1D&<1M');
        F(Observer, '13 <>1M', '<>1M');
        F(Observer, '14 <>1D', '<>1D');
        F(Observer, '15 <>', '<>');
        F(Observer, '16 <>1M|1D', '<>1M|1D');
        F(Observer, '17 >1M|<1D', '>1M|<1D');
        F(Observer, '18 =1M', '=1M');
        F(Observer, '19 =1M|=1D', '=1M|=1D');
        F(Observer, '20 1M..1M', '1M..1M');
        F(Observer, '21 @1M', '@1M');
        F(Observer, '22 *', '*');
        F(Observer, '23 ?', '?');
        F(Observer, '24 1*', '1*');
        F(Observer, '25 *M', '*M');
        Observer.Expect('0 1M&1D', '0||1M&1D');
        Observer.Expect('1 1M&<>1D', '2|1,4|1M&<>1D');
        Observer.Expect('2 <>1M&<>1D', '5|3,5,6,7,8|<>1M&<>1D');
        Observer.Expect('3 <>1M&<>1D&<>|text', 'The filter "<>1M&<>1D&<>" is not valid for the DF field on the LT Y89 DF Row table. A value is expected after the ''<>''.');
        Observer.Expect('3 <>1M&<>1D&<>|code', 'Filter:CSide');
        Observer.Expect('4 1D..1M', '4|1,2,4,5|1D..1M');
        Observer.Expect('5 1M..1D', '0||1M..1D');
        Observer.Expect('6 1D..1M|1W', '4|1,2,4,5|1D..1M|1W');
        Observer.Expect('7 1D..', '5|1,2,4,5,8|1D..');
        Observer.Expect('8 ..1M', '7|1,2,3,4,5,6,7|..1M');
        Observer.Expect('9 >1D', '4|1,4,5,8|>1D');
        Observer.Expect('10 <1M', '5|2,3,5,6,7|<1M');
        Observer.Expect('11 >=1D&<=1M', '4|1,2,4,5|>=1D&<=1M');
        Observer.Expect('12 >=1D&<1M', '2|2,5|>=1D&<1M');
        Observer.Expect('13 <>1M', '6|2,3,5,6,7,8|<>1M');
        Observer.Expect('14 <>1D', '7|1,3,4,5,6,7,8|<>1D');
        Observer.Expect('15 <>|text', 'The filter "<>" is not valid for the DF field on the LT Y89 DF Row table. A value is expected after the ''<>''.');
        Observer.Expect('15 <>|code', 'Filter:CSide');
        Observer.Expect('16 <>1M|1D', '6|2,3,5,6,7,8|<>1M|1D');
        Observer.Expect('17 >1M|<1D', '4|3,6,7,8|>1M|<1D');
        Observer.Expect('18 =1M', '2|1,4|1M');
        Observer.Expect('19 =1M|=1D', '3|1,2,4|1M|1D');
        Observer.Expect('20 1M..1M', '2|1,4|1M..1M');
        Observer.Expect('21 @1M', '2|1,4|1M');
        Observer.Expect('22 *', '1|3|''''');
        Observer.Expect('23 ?', '1|3|''''');
        Observer.Expect('24 1*|text', 'The filter "1*" is not valid for the DF field on the LT Y89 DF Row table. The date formula ''1*'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('24 1*|code', 'Filter:CSide');
        Observer.Expect('25 *M|text', 'The filter "*M" is not valid for the DF field on the LT Y89 DF Row table. The date formula ''*M'' should include a number.');
        Observer.Expect('25 *M|code', 'Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_Date_ZeroOffsets()
    var
        R: Record "LT Y89 DF Row";
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
    begin
        Texts.Add('T');
        Texts.Add('T-0D');
        Texts.Add('T+0D');
        Texts.Add('W-0D');
        Texts.Add('W+0D');
        Texts.Add('CW-0W');
        Texts.Add('CM+0M');
        foreach T in Texts do begin
            Clear(R);
            R.Init();
            Observer.Observe(T + ' valid', Format(TryDateFilter(T)));
            if not TryDateFilter(T) then
                Observer.ObserveError(T);
        end;
        Observer.Expect('T valid', 'Yes');
        Observer.Expect('T-0D valid', 'Yes');
        Observer.Expect('T+0D valid', 'Yes');
        Observer.Expect('W-0D valid', 'Yes');
        Observer.Expect('W+0D valid', 'Yes');
        Observer.Expect('CW-0W valid', 'Yes');
        Observer.Expect('CM+0M valid', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDateFilter(Txt: Text)
    var
        P136: Record "LT P136 Row";
        N: Integer;
    begin
        P136.SetFilter(D, Txt);
        N := P136.Count();
    end;

    // The shape of errors/lt-ms-refusals-136/P136Filter.al P136_SetFilter_DateFormula: four rows (1M, 1D, blank, 1M) and Count straight after SetFilter.
    // Linux suspect (writer Y89): Windows BC 27.5 counts 3 for '1M|1D' here; the Linux containers count 2 (P136Filter.al:248). Not a test.
    procedure Y89_DF_FourRowsCountOnly()
    var
        R: Record "LT Y89 DF Row";
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        Evaluate(R.DF, '<1M>');
        R.Insert();
        R.Init();
        R.Id := 2;
        Evaluate(R.DF, '<1D>');
        R.Insert();
        R.Init();
        R.Id := 3;
        R.Insert();
        R.Init();
        R.Id := 4;
        Evaluate(R.DF, '<1M>');
        R.Insert();
        Texts.Add('1M');
        Texts.Add('1D');
        Texts.Add('1M|1D');
        Texts.Add('1D|1M');
        foreach T in Texts do begin
            Clear(R);
            R.SetFilter(DF, T);
            Observer.Observe(T + ' count', Format(R.Count()));
        end;
        Observer.Expect('1M count', '2');
        Observer.Expect('1D count', '1');
        Observer.Expect('1M|1D count', '3');
        Observer.Expect('1D|1M count', '3');
        Observer.Verify();
    end;
}
