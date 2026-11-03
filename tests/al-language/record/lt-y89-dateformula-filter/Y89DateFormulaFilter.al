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
        Observer.Finish();
    end;

    [Test]
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
        Observer.Finish();
    end;

    [Test]
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
        Observer.Finish();
    end;

    [Test]
    procedure Y89_Date_ZeroOffsets()
    var
        R: Record "LT Y89 DF Row";
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        T: Text;
        Plain: Integer;
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
        Plain := 0;
        Observer.Observe('plain', Format(Plain));
        Observer.Finish();
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
}
