// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPF Row (69932), TPF Card (69932), TPF Enum (69932), TPF Media Row (69933), TPF Media Card (69933), Assert (60021)
// BC versions: 27.0+
//
// CLAIM UNDER TEST: what a TestPage field answers to Value() and accepts in AssertEquals(<expected>)
// and SetValue(<typed value>), for every field type a control can show. NavTestField.ALAssertEquals
// converts a non-text expected value to the field's own type and spells it through the control's
// formatter, then compares it ORDINALLY with the control's text, so both sides have to be spelled
// alike; a text expected value is compared as written.
//
// MEASURED, not read: every expectation below is what the service tier answered to a probe
// revision of this file (corpus PR 558), which asserted nothing and ended in Error(<what it saw>),
// on all nine cloud legs (27.0 to 28.5) and on the Windows nightly.
//
//   Integer, BigInteger     plain digits, no thousands separator ('1234567')
//   Decimal                 the control's own format: thousands separators and the DecimalPlaces or
//                           AutoFormat places ('1,234,567.89', '999.50', '1,234.5000'), rounding half
//                           away from zero
//   BlankZero, BlankNumbers the text is '' for a blanked number, on Value() and on the expected side
//   Boolean                 'Yes' / 'No'
//   Option, Enum            the caption: the control's OptionCaption, else the source field's, else
//                           the enum value's Caption; the member name is refused
//   Date, Time, DateTime    the short forms ('3/2/2024', '12:34:56 PM', '3/2/2024 12:34 PM', no
//                           seconds); blank is ''
//   Guid                    braced ('{...}'), and the null Guid is NOT blank
//   Duration                AL Format()'s words ('1 hour 2 minutes 3 seconds'); zero is ''
//   Media, MediaSet         a Media shows its id, a MediaSet the id of its first media, lowercase;
//                           '' when no media is set (the filled case is codeunit 69934)
//
// SetValue(<typed value>) is spelled the same way and read back by the client's own parser, so a
// DateTime loses its seconds and a blank text written to a numeric control is zero.
//
// DATES: the Linux tier's license refuses a page write of a Date to a RECORD field: on 27.x every
// one, on 28.x and later any outside the months 11, 12, 01 and 02 ('??11*|??12*|??01*|??02*'). So
// SetValue of a Date is written to a page-variable control, which validates nothing.

codeunit 69932 "TPF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Open(var Row: Record "TPF Row"; var Card: TestPage "TPF Card")
    var
        Old: Record "TPF Row";
    begin
        Old.DeleteAll();
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey(Row.PK);
    end;

    // The space before AM/PM is U+202F where the runtime's culture data is CLDR 42 or newer, and
    // U+0020 where it is older; the expectations below are written with U+0020.
    local procedure Plain(T: Text): Text
    var
        Nnbsp: Text[1];
        Nbsp: Text[1];
    begin
        Nnbsp[1] := 8239;
        Nbsp[1] := 160;
        exit(T.Replace(Nnbsp, ' ').Replace(Nbsp, ' '));
    end;


    local procedure T_Num(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := v;
        Open(Row, Card);
        T := Card.Num.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Big(v: Text): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Big, v);
        Open(Row, Card);
        T := Card.Big.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Dec2(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := v;
        Open(Row, Card);
        T := Card.Dec2.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Dec1(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec1 := v;
        Open(Row, Card);
        T := Card.Dec1.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Dec5(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec5 := v;
        Open(Row, Card);
        T := Card.Dec5.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_DecDef(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := v;
        Open(Row, Card);
        T := Card.DecDef.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_DecRng(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecRng := v;
        Open(Row, Card);
        T := Card.DecRng.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_DecBZ(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := v;
        Open(Row, Card);
        T := Card.DecBZ.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_DecBZT(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZT := v;
        Open(Row, Card);
        T := Card.DecBZT.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_DecBNP(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := v;
        Open(Row, Card);
        T := Card.DecBNP.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_DecBNN(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := v;
        Open(Row, Card);
        T := Card.DecBNN.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_DecAF(v: Decimal): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecAF := v;
        Open(Row, Card);
        T := Card.DecAF.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_NumBZ(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := v;
        Open(Row, Card);
        T := Card.NumBZ.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Flag(v: Boolean): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Flag := v;
        Open(Row, Card);
        T := Card.Flag.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Opt(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := v;
        Open(Row, Card);
        T := Card.Opt.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Enm(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum".FromInteger(v);
        Open(Row, Card);
        T := Card.Enm.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Dt(v: Date): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := v;
        Open(Row, Card);
        T := Card.Dt.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Tm(v: Time): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Tm := v;
        Open(Row, Card);
        T := Card.Tm.Value();
        Card.Close();
        exit(Plain(T));
    end;

    local procedure T_DtTm(v: DateTime): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DtTm := v;
        Open(Row, Card);
        T := Card.DtTm.Value();
        Card.Close();
        exit(Plain(T));
    end;

    local procedure T_Cd(v: Code[20]): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Cd := v;
        Open(Row, Card);
        T := Card.Cd.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Txt(v: Text[50]): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Txt := v;
        Open(Row, Card);
        T := Card.Txt.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Gd(v: Text): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Gd, v);
        Open(Row, Card);
        T := Card.Gd.Value();
        Card.Close();
        exit(T);
    end;

    local procedure T_Dur(v: Integer): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        T: Text;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := v;
        Open(Row, Card);
        T := Card.Dur.Value();
        Card.Close();
        exit(T);
    end;

    [Test]
    procedure Value_Integer()
    begin
        Assert.AreEqual('0', T_Num(0), 'Num(0)');
        Assert.AreEqual('42', T_Num(42), 'Num(42)');
        Assert.AreEqual('1000', T_Num(1000), 'Num(1000)');
        Assert.AreEqual('1234567', T_Num(1234567), 'Num(1234567)');
        Assert.AreEqual('-1234567', T_Num(-1234567), 'Num(-1234567)');
    end;

    [Test]
    procedure Value_BigInteger()
    begin
        Assert.AreEqual('9000000000', T_Big('9000000000'), 'Big(9000000000)');
        Assert.AreEqual('1234567890123', T_Big('1234567890123'), 'Big(1234567890123)');
        Assert.AreEqual('-5000', T_Big('-5000'), 'Big(-5000)');
    end;

    [Test]
    procedure Value_Decimal_TwoPlaces()
    begin
        Assert.AreEqual('0.00', T_Dec2(0), 'Dec2(0)');
        Assert.AreEqual('999.50', T_Dec2(999.5), 'Dec2(999.5)');
        Assert.AreEqual('1,000.00', T_Dec2(1000), 'Dec2(1,000)');
        Assert.AreEqual('1,234,567.89', T_Dec2(1234567.89), 'Dec2(1,234,567.89)');
        Assert.AreEqual('-1,234,567.89', T_Dec2(-1234567.89), 'Dec2(-1,234,567.89)');
        Assert.AreEqual('0.01', T_Dec2(0.005), 'Dec2(0.005)');
        Assert.AreEqual('0.02', T_Dec2(0.015), 'Dec2(0.015)');
        Assert.AreEqual('99,999,999,999,999.99', T_Dec2(99999999999999.99), 'Dec2(99,999,999,999,999.99)');
    end;

    [Test]
    procedure Value_Decimal_OnePlace()
    begin
        Assert.AreEqual('3.3', T_Dec1(3.25), 'Dec1(3.25)');
        Assert.AreEqual('1,234.6', T_Dec1(1234.56), 'Dec1(1,234.56)');
        Assert.AreEqual('0.0', T_Dec1(0), 'Dec1(0)');
    end;

    [Test]
    procedure Value_Decimal_FivePlaces()
    begin
        Assert.AreEqual('1.50000', T_Dec5(1.5), 'Dec5(1.5)');
        Assert.AreEqual('1,234.12345', T_Dec5(1234.12345), 'Dec5(1,234.12345)');
        Assert.AreEqual('0.00000', T_Dec5(0), 'Dec5(0)');
    end;

    [Test]
    procedure Value_Decimal_NoDecimalPlaces()
    begin
        Assert.AreEqual('0.00', T_DecDef(0), 'DecDef(0)');
        Assert.AreEqual('3.14', T_DecDef(3.14159), 'DecDef(3.14159)');
        Assert.AreEqual('1,234.50', T_DecDef(1234.5), 'DecDef(1,234.5)');
        Assert.AreEqual('1,234,567.89', T_DecDef(1234567.891), 'DecDef(1,234,567.891)');
        Assert.AreEqual('1,000.00', T_DecDef(1000), 'DecDef(1,000)');
    end;

    [Test]
    procedure Value_Decimal_ZeroToFivePlaces()
    begin
        Assert.AreEqual('1,000', T_DecRng(1000), 'DecRng(1,000)');
        Assert.AreEqual('1,234.5', T_DecRng(1234.5), 'DecRng(1,234.5)');
        Assert.AreEqual('1.12346', T_DecRng(1.123456), 'DecRng(1.123456)');
        Assert.AreEqual('0', T_DecRng(0), 'DecRng(0)');
    end;

    [Test]
    procedure Value_Decimal_BlankZero()
    begin
        Assert.AreEqual('', T_DecBZ(0), 'DecBZ(0)');
        Assert.AreEqual('5.00', T_DecBZ(5), 'DecBZ(5)');
        Assert.AreEqual('1,000.00', T_DecBZ(1000), 'DecBZ(1,000)');
    end;

    [Test]
    procedure Value_Decimal_BlankZeroOnTheField()
    begin
        Assert.AreEqual('', T_DecBZT(0), 'DecBZT(0)');
        Assert.AreEqual('5.00', T_DecBZT(5), 'DecBZT(5)');
    end;

    [Test]
    procedure Value_Decimal_BlankZeroAndPositive()
    begin
        Assert.AreEqual('-5.00', T_DecBNP(-5), 'DecBNP(-5)');
        Assert.AreEqual('', T_DecBNP(0), 'DecBNP(0)');
        Assert.AreEqual('', T_DecBNP(5), 'DecBNP(5)');
    end;

    [Test]
    procedure Value_Decimal_BlankNegative()
    begin
        Assert.AreEqual('', T_DecBNN(-5), 'DecBNN(-5)');
        Assert.AreEqual('0.00', T_DecBNN(0), 'DecBNN(0)');
        Assert.AreEqual('5.00', T_DecBNN(5), 'DecBNN(5)');
    end;

    [Test]
    procedure Value_Decimal_AutoFormat()
    begin
        Assert.AreEqual('1,234.5000', T_DecAF(1234.5), 'DecAF(1,234.5)');
        Assert.AreEqual('0.0000', T_DecAF(0), 'DecAF(0)');
    end;

    [Test]
    procedure Value_Integer_BlankZero()
    begin
        Assert.AreEqual('', T_NumBZ(0), 'NumBZ(0)');
        Assert.AreEqual('7', T_NumBZ(7), 'NumBZ(7)');
        Assert.AreEqual('1000', T_NumBZ(1000), 'NumBZ(1000)');
    end;

    [Test]
    procedure Value_Boolean()
    begin
        Assert.AreEqual('Yes', T_Flag(true), 'Flag(Yes)');
        Assert.AreEqual('No', T_Flag(false), 'Flag(No)');
    end;

    [Test]
    procedure Value_Option()
    begin
        Assert.AreEqual('Eins', T_Opt(0), 'Opt(0)');
        Assert.AreEqual('Zwei', T_Opt(1), 'Opt(1)');
        Assert.AreEqual('Drei', T_Opt(2), 'Opt(2)');
    end;

    [Test]
    procedure Value_Enum()
    begin
        Assert.AreEqual('Eins', T_Enm(0), 'Enm(0)');
        Assert.AreEqual('Zwei', T_Enm(1), 'Enm(1)');
        Assert.AreEqual('Drei', T_Enm(2), 'Enm(2)');
    end;

    [Test]
    procedure Value_Date()
    begin
        Assert.AreEqual('3/2/2024', T_Dt(20240302D), 'Dt(03/02/24)');
        Assert.AreEqual('', T_Dt(0D), 'Dt()');
        Assert.AreEqual('12/31/2024', T_Dt(20241231D), 'Dt(12/31/24)');
    end;

    [Test]
    procedure Value_Time()
    begin
        Assert.AreEqual('12:34:56 PM', T_Tm(123456T), 'Tm(12:34:56 PM)');
        Assert.AreEqual('', T_Tm(0T), 'Tm()');
        Assert.AreEqual('11:59:59 PM', T_Tm(235959T), 'Tm(11:59:59 PM)');
        Assert.AreEqual('12:00:01 AM', T_Tm(000001T), 'Tm(12:00:01 AM)');
    end;

    [Test]
    procedure Value_DateTime()
    begin
        Assert.AreEqual('3/2/2024 12:34 PM', T_DtTm(CreateDateTime(20240302D, 123456T)), 'DtTm(03/02/24 12:34 PM)');
        Assert.AreEqual('', T_DtTm(0DT), 'DtTm()');
        Assert.AreEqual('3/2/2024 12:00 AM', T_DtTm(CreateDateTime(20240302D, 0T)), 'DtTm(03/02/24 12:00 AM)');
        Assert.AreEqual('12/31/2024 11:59 PM', T_DtTm(CreateDateTime(20241231D, 235959T)), 'DtTm(12/31/24 11:59 PM)');
    end;

    [Test]
    procedure Value_Code()
    begin
        Assert.AreEqual('ABC', T_Cd('ABC'), 'Cd(ABC)');
    end;

    [Test]
    procedure Value_Text()
    begin
        Assert.AreEqual('text', T_Txt('text'), 'Txt(text)');
    end;

    [Test]
    procedure Value_Guid()
    begin
        Assert.AreEqual('{11111111-2222-3333-4444-555555555555}', T_Gd('{11111111-2222-3333-4444-555555555555}'), 'Gd({11111111-2222-3333-4444-555555555555})');
        Assert.AreEqual('{00000000-0000-0000-0000-000000000000}', T_Gd('{00000000-0000-0000-0000-000000000000}'), 'Gd({00000000-0000-0000-0000-000000000000})');
    end;

    [Test]
    procedure Value_Duration()
    begin
        Assert.AreEqual('', T_Dur(0), 'Dur(0)');
        Assert.AreEqual('5 seconds', T_Dur(5000), 'Dur(5000)');
        Assert.AreEqual('1 hour 2 minutes 3 seconds', T_Dur(3723000), 'Dur(3723000)');
        Assert.AreEqual('1 day 1 hour', T_Dur(90000000), 'Dur(90000000)');
        Assert.AreEqual('1 day', T_Dur(86400000), 'Dur(86400000)');
        Assert.AreEqual('1 millisecond', T_Dur(1), 'Dur(1)');
    end;

    [Test]
    procedure Value_PageVariableControls()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := 1234567.89;
        Row.Num := 1234567;
        Row.Dt := 20240302D;
        Row.Dur := 5000;
        Row.Flag := true;
        Open(Row, Card);
        Assert.AreEqual('1,234,567.89', Card.GlobDec.Value(), 'Decimal');
        Assert.AreEqual('1234567', Card.GlobNum.Value(), 'Integer');
        Assert.AreEqual('3/2/2024', Card.GlobDt.Value(), 'Date');
        Assert.AreEqual('5 seconds', Card.GlobDur.Value(), 'Duration');
        Assert.AreEqual('Yes', Card.GlobFlag.Value(), 'Boolean');
        Card.Close();
    end;

    [Test]
    procedure Value_Media_NoMedia()
    var
        Row: Record "TPF Media Row";
        Card: TestPage "TPF Media Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Assert.AreEqual('', Card.Pic.Value(), 'MediaSet');
        Assert.AreEqual('', Card.One.Value(), 'Media');
        Card.Pic.AssertEquals('');
        Card.One.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dec2_Negative()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := -1234567.89;
        Open(Row, Card);
        Card.Dec2.AssertEquals(-1234567.89);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dec2_StringFormatted()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := 1234567.89;
        Open(Row, Card);
        Card.Dec2.AssertEquals('1,234,567.89');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dec2_Integer()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := 1234567;
        Open(Row, Card);
        Card.Dec2.AssertEquals(1234567);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Num_1234567()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1234567;
        Open(Row, Card);
        Card.Num.AssertEquals(1234567);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Num_42()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 42;
        Open(Row, Card);
        Card.Num.AssertEquals(42);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Num_1000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1000;
        Open(Row, Card);
        Card.Num.AssertEquals(1000);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Num_DecimalExpected()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1000;
        Open(Row, Card);
        Card.Num.AssertEquals(1000.0);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Big_9000000000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        B: BigInteger;
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Big, '9000000000');
        B := Row.Big;
        Open(Row, Card);
        Card.Big.AssertEquals(B);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Big_5000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Big := 5000;
        Open(Row, Card);
        Card.Big.AssertEquals(5000);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dec1_325()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec1 := 3.25;
        Open(Row, Card);
        Card.Dec1.AssertEquals(3.25);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dec1_123456()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec1 := 1234.56;
        Open(Row, Card);
        Card.Dec1.AssertEquals(1234.56);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dec5_15()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec5 := 1.5;
        Open(Row, Card);
        Card.Dec5.AssertEquals(1.5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dec5_123412345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec5 := 1234.12345;
        Open(Row, Card);
        Card.Dec5.AssertEquals(1234.12345);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecDef_12345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := 1234.5;
        Open(Row, Card);
        Card.DecDef.AssertEquals(1234.5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecDef_0()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := 0;
        Open(Row, Card);
        Card.DecDef.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecDef_314159()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecDef := 3.14159;
        Open(Row, Card);
        Card.DecDef.AssertEquals(3.14159);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecRng_12345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecRng := 1234.5;
        Open(Row, Card);
        Card.DecRng.AssertEquals(1234.5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecRng_1000()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecRng := 1000;
        Open(Row, Card);
        Card.DecRng.AssertEquals(1000);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBZ_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := 0;
        Open(Row, Card);
        Card.DecBZ.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBZ_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := 0;
        Open(Row, Card);
        Card.DecBZ.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBZ_5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZ := 5;
        Open(Row, Card);
        Card.DecBZ.AssertEquals(5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBZT_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZT := 0;
        Open(Row, Card);
        Card.DecBZT.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBZT_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBZT := 0;
        Open(Row, Card);
        Card.DecBZT.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBNP_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := 0;
        Open(Row, Card);
        Card.DecBNP.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBNP_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := 0;
        Open(Row, Card);
        Card.DecBNP.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBNP_Pos5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := 5;
        Open(Row, Card);
        Card.DecBNP.AssertEquals(5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBNP_Neg5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNP := -5;
        Open(Row, Card);
        Card.DecBNP.AssertEquals(-5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBNN_Neg5_Neg5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := -5;
        Open(Row, Card);
        Card.DecBNN.AssertEquals(-5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBNN_Neg5_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := -5;
        Open(Row, Card);
        Card.DecBNN.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecBNN_Pos5()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecBNN := 5;
        Open(Row, Card);
        Card.DecBNN.AssertEquals(5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DecAF_12345()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DecAF := 1234.5;
        Open(Row, Card);
        Card.DecAF.AssertEquals(1234.5);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_NumBZ_Zero_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := 0;
        Open(Row, Card);
        Card.NumBZ.AssertEquals(0);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_NumBZ_Zero_Empty()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := 0;
        Open(Row, Card);
        Card.NumBZ.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_NumBZ_7()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.NumBZ := 7;
        Open(Row, Card);
        Card.NumBZ.AssertEquals(7);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Flag_True()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Flag := true;
        Open(Row, Card);
        Card.Flag.AssertEquals(true);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Flag_False()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Flag := false;
        Open(Row, Card);
        Card.Flag.AssertEquals(false);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Opt_Member()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        Card.Opt.AssertEquals(Row.Opt::Beta);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Opt_Ordinal()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        Card.Opt.AssertEquals(1);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Opt_Caption()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        Card.Opt.AssertEquals('Zwei');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Opt_MemberName_IsRefused()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Opt := Row.Opt::Beta;
        Open(Row, Card);
        asserterror Card.Opt.AssertEquals('Beta');
        Assert.ExpectedError('AssertEquals for Field: Opt Expected = ''Beta'', Actual = ''Zwei''');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Enm_Value()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        Card.Enm.AssertEquals("TPF Enum"::Two);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Enm_Ordinal()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        Card.Enm.AssertEquals(1);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Enm_Caption()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        Card.Enm.AssertEquals('Zwei');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Enm_Name_IsRefused()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Enm := "TPF Enum"::Two;
        Open(Row, Card);
        asserterror Card.Enm.AssertEquals('Two');
        Assert.ExpectedError('AssertEquals for Field: Enm Expected = ''Two'', Actual = ''Zwei''');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dt_Date()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 20240302D;
        Open(Row, Card);
        Card.Dt.AssertEquals(20240302D);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dt_Blank()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 0D;
        Open(Row, Card);
        Card.Dt.AssertEquals(0D);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dt_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 20240302D;
        Open(Row, Card);
        Card.Dt.AssertEquals('3/2/2024');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Tm_Time()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Tm := 123456T;
        Open(Row, Card);
        Card.Tm.AssertEquals(123456T);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Tm_Blank()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Tm := 0T;
        Open(Row, Card);
        Card.Tm.AssertEquals(0T);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DtTm_Value()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DtTm := CreateDateTime(20240302D, 123456T);
        Open(Row, Card);
        Card.DtTm.AssertEquals(CreateDateTime(20240302D, 123456T));
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_DtTm_Blank()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.DtTm := 0DT;
        Open(Row, Card);
        Card.DtTm.AssertEquals(0DT);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Cd_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Cd := 'ABC';
        Open(Row, Card);
        Card.Cd.AssertEquals('ABC');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Txt_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Txt := 'text';
        Open(Row, Card);
        Card.Txt.AssertEquals('text');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Gd_Guid()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        G: Guid;
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Gd, '{11111111-2222-3333-4444-555555555555}');
        G := Row.Gd;
        Open(Row, Card);
        Card.Gd.AssertEquals(G);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Gd_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Evaluate(Row.Gd, '{11111111-2222-3333-4444-555555555555}');
        Open(Row, Card);
        Card.Gd.AssertEquals('{11111111-2222-3333-4444-555555555555}');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Gd_Null()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        G: Guid;
    begin
        Row.Init();
        Row.PK := 'R1';
        Clear(Row.Gd);
        G := Row.Gd;
        Open(Row, Card);
        Card.Gd.AssertEquals(G);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dur_Value()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        D := 5000;
        Open(Row, Card);
        Card.Dur.AssertEquals(D);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dur_Integer()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        Open(Row, Card);
        Card.Dur.AssertEquals(5000);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dur_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        Open(Row, Card);
        Card.Dur.AssertEquals('5 seconds');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dur_Zero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 0;
        D := 0;
        Open(Row, Card);
        Card.Dur.AssertEquals(D);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_Dur_BigValue()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 3723000;
        D := 3723000;
        Open(Row, Card);
        Card.Dur.AssertEquals(D);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_PlainDecimalTextIsRefused()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := 1234567.89;
        Open(Row, Card);
        asserterror Card.Dec2.AssertEquals('1234567.89');
        Assert.ExpectedError('AssertEquals for Field: Dec2 Expected = ''1234567.89'', Actual = ''1,234,567.89''');
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_PageVariableDecimal()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dec2 := 1234567.89;
        Open(Row, Card);
        Card.GlobDec.AssertEquals(1234567.89);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_PageVariableInteger()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Num := 1234567;
        Open(Row, Card);
        Card.GlobNum.AssertEquals(1234567);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_PageVariableDate()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dt := 20240302D;
        Open(Row, Card);
        Card.GlobDt.AssertEquals(20240302D);
        Card.Close();
    end;

    [Test]
    procedure AssertEquals_PageVariableDuration()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.Init();
        Row.PK := 'R1';
        Row.Dur := 5000;
        D := 5000;
        Open(Row, Card);
        Card.GlobDur.AssertEquals(D);
        Card.Close();
    end;


    [Test]
    procedure SetValue_Decimal_ThousandsTyped()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Dec2.SetValue(1234567.89);
        Assert.AreEqual('1,234,567.89', Card.Dec2.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Dec2 = 1234567.89, 'the stored value');
    end;

    [Test]
    procedure SetValue_Decimal_NoDecimalPlaces()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.DecDef.SetValue(1234.5);
        Assert.AreEqual('1,234.50', Card.DecDef.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.DecDef = 1234.5, 'the stored value');
    end;

    [Test]
    procedure SetValue_Integer()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Num.SetValue(1234567);
        Assert.AreEqual('1234567', Card.Num.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Num = 1234567, 'the stored value');
    end;

    [Test]
    procedure SetValue_Date_PageVariable()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.GlobDt.SetValue(20240302D);
        Assert.AreEqual('3/2/2024', Card.GlobDt.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.PK = 'R1', 'the stored value');
    end;

    [Test]
    procedure SetValue_Time()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Tm.SetValue(123456T);
        Assert.AreEqual('12:34:56 PM', Plain(Card.Tm.Value()), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Tm = 123456T, 'the stored value');
    end;

    [Test]
    procedure SetValue_DateTime_LosesItsSeconds()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.DtTm.SetValue(CreateDateTime(20240302D, 123456T));
        Assert.AreEqual('3/2/2024 12:34 PM', Plain(Card.DtTm.Value()), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.DtTm = CreateDateTime(20240302D, 123400T), 'the stored value');
    end;

    [Test]
    procedure SetValue_Duration()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        D := 3723000;
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Dur.SetValue(D);
        Assert.AreEqual('1 hour 2 minutes 3 seconds', Card.Dur.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Dur = D, 'the stored value');
    end;

    [Test]
    procedure SetValue_Duration_Text()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        D := 5000;
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Dur.SetValue('5 seconds');
        Assert.AreEqual('5 seconds', Card.Dur.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Dur = D, 'the stored value');
    end;

    [Test]
    procedure SetValue_Duration_BlankText()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        D: Duration;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        D := 0;
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Dur.SetValue('');
        Assert.AreEqual('', Card.Dur.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Dur = D, 'the stored value');
    end;

    [Test]
    procedure SetValue_Decimal_BlankText_IsZero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Dec2.SetValue('');
        Assert.AreEqual('0.00', Card.Dec2.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Dec2 = 0, 'the stored value');
    end;

    [Test]
    procedure SetValue_Integer_BlankText_IsZero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Num.SetValue('');
        Assert.AreEqual('0', Card.Num.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Num = 0, 'the stored value');
    end;

    [Test]
    procedure SetValue_Decimal_BlankZero_TypedZero()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.DecBZ.SetValue(0);
        Assert.AreEqual('', Card.DecBZ.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.DecBZ = 0, 'the stored value');
    end;

    [Test]
    procedure SetValue_Decimal_BlankZero_ZeroText()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.DecBZ.SetValue('0');
        Assert.AreEqual('', Card.DecBZ.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.DecBZ = 0, 'the stored value');
    end;

    [Test]
    procedure SetValue_Decimal_BlankZero_BlankText()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.DecBZ.SetValue('');
        Assert.AreEqual('', Card.DecBZ.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.DecBZ = 0, 'the stored value');
    end;

    [Test]
    procedure SetValue_Option()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Opt.SetValue(Row.Opt::Gamma);
        Assert.AreEqual('Drei', Card.Opt.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Opt = Row.Opt::Gamma, 'the stored value');
    end;

    [Test]
    procedure SetValue_Enum()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Enm.SetValue("TPF Enum"::Three);
        Assert.AreEqual('Drei', Card.Enm.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Enm = "TPF Enum"::Three, 'the stored value');
    end;

    [Test]
    procedure SetValue_Boolean()
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.Flag.SetValue(true);
        Assert.AreEqual('Yes', Card.Flag.Value(), 'the control after SetValue');
        Card.Close();
        Row.Get('R1');
        Assert.IsTrue(Row.Flag, 'the stored value');
    end;
}
