// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/format/format-function
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enum 74268, table 74269, pages 74270 and 74271, codeunit 74272
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reason 17): "Format of a TestPage control (standard format N) is not pinned yet" (Format(TestPage.Field) of a Decimal control: `Assert.AreEqual('10', Format(DeferralTemplateList."Deferral %"))`).
// Facts: Format(<TestPage field>) without .Value on a card and on a list page, for every field type (Text, Code, Integer, BigInteger, Decimal, Boolean, Date, Time, DateTime, Duration, Option, Enum), blank and filled rows, a Decimal with and without DecimalPlaces, BlankZero; next to the control's own Value text; with standard format 9, with a length and through StrSubstNo.
// BC versions: 29 (27 and 28 by CI)

enum 74268 "LT P135 Fmt Enum"
{
    Extensible = true;

    value(0; First)
    {
        Caption = 'First Cap';
    }
    value(1; Second)
    {
        Caption = 'Second Cap';
    }
}

table 74269 "LT P135 Fmt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cd; Code[10]) { }
        field(4; Int; Integer) { }
        field(5; Big; BigInteger) { }
        field(6; Dec; Decimal) { }
        field(7; Bool; Boolean) { }
        field(8; Dt; Date) { }
        field(9; Tm; Time) { }
        field(10; Dtm; DateTime) { }
        field(11; Dur; Duration) { }
        field(12; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
        field(13; En; Enum "LT P135 Fmt Enum") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 74270 "LT P135 Fmt Card"
{
    PageType = Card;
    SourceTable = "LT P135 Fmt Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TxtCtl; Rec.Txt)
                {
                    ApplicationArea = All;
                }
                field(CdCtl; Rec.Cd)
                {
                    ApplicationArea = All;
                }
                field(IntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                }
                field(BigCtl; Rec.Big)
                {
                    ApplicationArea = All;
                }
                field(DecCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                }
                field(DecPlacesCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                }
                field(BoolCtl; Rec.Bool)
                {
                    ApplicationArea = All;
                }
                field(DtCtl; Rec.Dt)
                {
                    ApplicationArea = All;
                }
                field(TmCtl; Rec.Tm)
                {
                    ApplicationArea = All;
                }
                field(DtmCtl; Rec.Dtm)
                {
                    ApplicationArea = All;
                }
                field(DurCtl; Rec.Dur)
                {
                    ApplicationArea = All;
                }
                field(OptCtl; Rec.Opt)
                {
                    ApplicationArea = All;
                }
                field(EnCtl; Rec.En)
                {
                    ApplicationArea = All;
                }
                field(BlankIntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                }
            }
        }
    }
}

page 74271 "LT P135 Fmt List"
{
    PageType = List;
    SourceTable = "LT P135 Fmt Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TxtCtl; Rec.Txt)
                {
                    ApplicationArea = All;
                }
                field(CdCtl; Rec.Cd)
                {
                    ApplicationArea = All;
                }
                field(IntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                }
                field(BigCtl; Rec.Big)
                {
                    ApplicationArea = All;
                }
                field(DecCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                }
                field(DecPlacesCtl; Rec.Dec)
                {
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 2;
                }
                field(BoolCtl; Rec.Bool)
                {
                    ApplicationArea = All;
                }
                field(DtCtl; Rec.Dt)
                {
                    ApplicationArea = All;
                }
                field(TmCtl; Rec.Tm)
                {
                    ApplicationArea = All;
                }
                field(DtmCtl; Rec.Dtm)
                {
                    ApplicationArea = All;
                }
                field(DurCtl; Rec.Dur)
                {
                    ApplicationArea = All;
                }
                field(OptCtl; Rec.Opt)
                {
                    ApplicationArea = All;
                }
                field(EnCtl; Rec.En)
                {
                    ApplicationArea = All;
                }
                field(BlankIntCtl; Rec.Int)
                {
                    ApplicationArea = All;
                    BlankZero = true;
                }
            }
        }
    }
}

codeunit 74272 "LT P135 Fmt TestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(Id: Integer; Dec: Decimal)
    var
        R: Record "LT P135 Fmt Row";
    begin
        R.Init();
        R.Id := Id;
        R.Dec := Dec;
        R.Insert();
    end;

    local procedure Seed()
    var
        R: Record "LT P135 Fmt Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Txt := 'Hello';
        R.Cd := 'abc';
        R.Int := 1234567;
        R.Big := 2147483647;
        R.Big := R.Big * 2;
        R.Dec := 1234.5;
        R.Bool := true;
        R.Dt := 20240302D;
        R.Tm := 123456T;
        R.Dtm := CreateDateTime(20240302D, 123456T);
        R.Dur := 3723000;
        R.Opt := R.Opt::One;
        R.En := R.En::Second;
        R.Insert();
        Add(2, 0);
        Add(3, 10);
        Add(4, 10.5);
        Add(5, 0.5);
        Add(6, -5.5);
        Add(7, 1234567.891);
        Add(8, 100000);
    end;

    [Test]
    procedure P135_Card_BlankRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P135 Fmt Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey(2);
        Observer.Observe('txtctl', Format(Card.TxtCtl) + '|' + Format(Card.TxtCtl.Value));
        Observer.Observe('cdctl', Format(Card.CdCtl) + '|' + Format(Card.CdCtl.Value));
        Observer.Observe('intctl', Format(Card.IntCtl) + '|' + Format(Card.IntCtl.Value));
        Observer.Observe('bigctl', Format(Card.BigCtl) + '|' + Format(Card.BigCtl.Value));
        Observer.Observe('decctl', Format(Card.DecCtl) + '|' + Format(Card.DecCtl.Value));
        Observer.Observe('decplacesctl', Format(Card.DecPlacesCtl) + '|' + Format(Card.DecPlacesCtl.Value));
        Observer.Observe('boolctl', Format(Card.BoolCtl) + '|' + Format(Card.BoolCtl.Value));
        Observer.Observe('dtctl', Format(Card.DtCtl) + '|' + Format(Card.DtCtl.Value));
        Observer.Observe('tmctl', Format(Card.TmCtl) + '|' + Format(Card.TmCtl.Value));
        Observer.Observe('dtmctl', Format(Card.DtmCtl) + '|' + Format(Card.DtmCtl.Value));
        Observer.Observe('durctl', Format(Card.DurCtl) + '|' + Format(Card.DurCtl.Value));
        Observer.Observe('optctl', Format(Card.OptCtl) + '|' + Format(Card.OptCtl.Value));
        Observer.Observe('enctl', Format(Card.EnCtl) + '|' + Format(Card.EnCtl.Value));
        Observer.Observe('blankintctl', Format(Card.BlankIntCtl) + '|' + Format(Card.BlankIntCtl.Value));
        Card.Close();
        Observer.Expect('txtctl', '|');
        Observer.Expect('cdctl', '|');
        Observer.Expect('intctl', '0|0');
        Observer.Expect('bigctl', '0|0');
        Observer.Expect('decctl', '0.00|0.00');
        Observer.Expect('decplacesctl', '0.00|0.00');
        Observer.Expect('boolctl', 'No|No');
        Observer.Expect('dtctl', '|');
        Observer.Expect('tmctl', '|');
        Observer.Expect('dtmctl', '|');
        Observer.Expect('durctl', '|');
        Observer.Expect('optctl', 'Zero|Zero');
        Observer.Expect('enctl', 'First Cap|First Cap');
        Observer.Expect('blankintctl', '|');
        Observer.Verify();
    end;
}
