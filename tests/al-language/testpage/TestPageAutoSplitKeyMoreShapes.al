// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Header (60915), ASK Line (60916), ASK Card (60920), ASK Dec Line (60926),
//   ASK Dec Card (60928); shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// More AutoSplitKey shapes than "ASK Range Tests" (60929): appends after a negative or zero last
// line, inserts across zero, inserts into narrow gaps, the refusal when there is no room, and
// Decimal keys. Each test seeds the lines, starts a new row after the first line (or after the
// last, for the appends) and lists the Line No. values that result.
// BC versions: 27.5

codeunit 68129 "Probe ASK More Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        DecLine: Record "ASK Dec Line";
    begin
        Line.DeleteAll();
        DecLine.DeleteAll();
        Header.DeleteAll();
        Header.Init();
        Header."No." := 'H1';
        Header.Insert();
    end;

    local procedure GivenLines(First: Integer; Second: Integer; HasSecond: Boolean)
    var
        Line: Record "ASK Line";
    begin
        Line.DeleteAll();
        Line.Init();
        Line."No." := 'H1';
        Line."Line No." := First;
        Line.Insert();
        if HasSecond then begin
            Line.Init();
            Line."No." := 'H1';
            Line."Line No." := Second;
            Line.Insert();
        end;
    end;

    local procedure NewRowAfter(AtEnd: Boolean): Text
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
        Keys: Text;
    begin
        Header.Get('H1');
        Card.OpenEdit();
        Card.GoToRecord(Header);
        if AtEnd then
            Card.Lines.Last()
        else
            Card.Lines.First();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new');
        Card.Close();

        Line.SetRange("No.", 'H1');
        Line.FindSet();
        repeat
            Keys += Format(Line."Line No.") + ' ';
        until Line.Next() = 0;
        exit(Keys);
    end;

    local procedure AppendAfter(Last: Integer): Text
    begin
        GivenLines(Last, 0, false);
        exit(NewRowAfter(true));
    end;

    local procedure InsertBetween(Lower: Integer; Upper: Integer): Text
    begin
        GivenLines(Lower, Upper, true);
        exit(NewRowAfter(false));
    end;

    [Test]
    procedure TestPage_New_AppendAfterASingleLine_NegativeZeroAndPositive()
    begin
        Initialize();

        Assert.AreEqual('-30000 -22500 ', AppendAfter(-30000), 'after -30000');
        Assert.AreEqual('-20000 -15000 ', AppendAfter(-20000), 'after -20000');
        Assert.AreEqual('-5 -4 ', AppendAfter(-5), 'after -5');
        Assert.AreEqual('-1 1 ', AppendAfter(-1), 'after -1: zero is skipped');
        Assert.AreEqual('0 10000 ', AppendAfter(0), 'after 0');
        Assert.AreEqual('5 10005 ', AppendAfter(5), 'after 5');
        Assert.AreEqual('10000 20000 ', AppendAfter(10000), 'after 10000');
    end;

    [Test]
    procedure TestPage_New_BetweenTwoLines_NegativeAndAcrossZero()
    begin
        Initialize();

        Assert.AreEqual('-30000 -20000 -10000 ', InsertBetween(-30000, -10000), 'between -30000 and -10000');
        Assert.AreEqual('-20000 -10000 10000 ', InsertBetween(-20000, 10000), 'between -20000 and 10000');
        Assert.AreEqual('-10000 1 20000 ', InsertBetween(-10000, 20000), 'between -10000 and 20000');
        Assert.AreEqual('-5 -1 5 ', InsertBetween(-5, 5), 'between -5 and 5');
        Assert.AreEqual('0 5000 10000 ', InsertBetween(0, 10000), 'between 0 and 10000');
        Assert.AreEqual('-10000 -5000 0 ', InsertBetween(-10000, 0), 'between -10000 and 0');
    end;

    [Test]
    procedure TestPage_New_BetweenTwoPositiveLines_StepIsHalfTheGapCappedAtTenThousand()
    begin
        Initialize();

        Assert.AreEqual('10 11 12 ', InsertBetween(10, 12), 'a gap of 2');
        Assert.AreEqual('10 11 13 ', InsertBetween(10, 13), 'a gap of 3');
        Assert.AreEqual('10000 20000 30000 ', InsertBetween(10000, 30000), 'a gap of 20000');
        Assert.AreEqual('10000 17500 25000 ', InsertBetween(10000, 25000), 'a gap of 15000');
        Assert.AreEqual('10000 15000 20001 ', InsertBetween(10000, 20001), 'a gap of 10001');
        Assert.AreEqual('100 150 200 ', InsertBetween(100, 200), 'a gap of 100');
        Assert.AreEqual('100 10100 50000 ', InsertBetween(100, 50000), 'a wide gap');
    end;

    [Test]
    procedure TestPage_New_BetweenAdjacentLines_ThrowsTheLineCannotBeSplit()
    // CLAIM: with no free number between the neighbours the new row cannot be saved and the error text is "The line cannot be split." (code TestWrapped).
    var
        Result: Text;
    begin
        Initialize();

        asserterror Result := InsertBetween(10, 11);

        Assert.AreEqual('The line cannot be split.', GetLastErrorText(), 'text for 10 and 11');
        Assert.AreEqual('TestWrapped', GetLastErrorCode(), 'code');

        asserterror Result := InsertBetween(1, 2);
        Assert.AreEqual('The line cannot be split.', GetLastErrorText(), 'text for 1 and 2');

        asserterror Result := InsertBetween(10000, 10001);
        Assert.AreEqual('The line cannot be split.', GetLastErrorText(), 'text for 10000 and 10001');
    end;

    local procedure DecimalNewRow(Lower: Decimal; Upper: Decimal; HasUpper: Boolean; AtEnd: Boolean): Text
    var
        Header: Record "ASK Header";
        DecLine: Record "ASK Dec Line";
        Card: TestPage "ASK Dec Card";
        Keys: Text;
    begin
        DecLine.DeleteAll();
        DecLine.Init();
        DecLine."No." := 'H1';
        DecLine."Line No." := Lower;
        DecLine.Insert();
        if HasUpper then begin
            DecLine.Init();
            DecLine."No." := 'H1';
            DecLine."Line No." := Upper;
            DecLine.Insert();
        end;
        Header.Get('H1');
        Card.OpenEdit();
        Card.GoToRecord(Header);
        if AtEnd then
            Card.Lines.Last()
        else
            Card.Lines.First();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('new');
        Card.Close();

        DecLine.SetRange("No.", 'H1');
        DecLine.FindSet();
        repeat
            Keys += Format(DecLine."Line No.", 0, 9) + ' ';
        until DecLine.Next() = 0;
        exit(Keys);
    end;

    [Test]
    procedure TestPage_New_DecimalKey_SplitsTheGapIncludingFractions()
    begin
        Initialize();

        Assert.AreEqual('1 1.5 2 ', DecimalNewRow(1, 2, true, false), 'between 1 and 2');
        Assert.AreEqual('1.5 2 2.5 ', DecimalNewRow(1.5, 2.5, true, false), 'between 1.5 and 2.5');
        Assert.AreEqual('10000.5 20000.5 30000.5 ', DecimalNewRow(10000.5, 30000.5, true, false), 'between 10000.5 and 30000.5');
        Assert.AreEqual('0 0.5 1 ', DecimalNewRow(0, 1, true, false), 'between 0 and 1');
        Assert.AreEqual('-1 -0.5 1 ', DecimalNewRow(-1, 1, true, false), 'between -1 and 1');
        Assert.AreEqual('1.5 10001.5 ', DecimalNewRow(1.5, 0, false, true), 'append after 1.5');
    end;
}
