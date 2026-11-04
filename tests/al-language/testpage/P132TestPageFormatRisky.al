// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-function
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73714, page 73715. RISKY: Format applied to a TestPage control itself (not its Value); the file is dropped when that does not compile.
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73714 "LT P132 Fmt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dec; Decimal) { }
        field(3; Txt; Text[30]) { }
        field(4; Flag; Boolean) { }
        field(5; Dt; Date) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 73715 "LT P132 Fmt Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P132 Fmt Row";

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(DecCtl; Rec.Dec) { ApplicationArea = All; }
            field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            field(FlagCtl; Rec.Flag) { ApplicationArea = All; }
            field(DtCtl; Rec.Dt) { ApplicationArea = All; }
        }
    }
}

codeunit 73713 "LT P132 TestPage Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P132 Fmt Row";
    begin
        R.DeleteAll();
        R.Id := 1234;
        R.Dec := 1234.5;
        R.Txt := 'Hello';
        R.Flag := true;
        R.Dt := 20240305D;
        R.Insert();
    end;

    [Test]
    procedure P132_FormatOfControl_Standard0()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P132 Fmt Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('int_0', Format(Card.IdCtl));
        Observer.Observe('dec_0', Format(Card.DecCtl));
        Observer.Observe('txt_0', Format(Card.TxtCtl));
        Observer.Observe('flag_0', Format(Card.FlagCtl));
        Observer.Observe('dt_0', Format(Card.DtCtl));
        Observer.Observe('int_value', Format(Card.IdCtl.Value));
        Observer.Observe('dec_value', Format(Card.DecCtl.Value));
        Observer.Observe('txt_value', Format(Card.TxtCtl.Value));
        Card.Close();
        Observer.Expect('int_0', '1234');
        Observer.Expect('dec_0', '1,234.50');
        Observer.Expect('txt_0', 'Hello');
        Observer.Expect('flag_0', 'Yes');
        Observer.Expect('dt_0', '3/5/2024');
        Observer.Expect('int_value', '1234');
        Observer.Expect('dec_value', '1,234.50');
        Observer.Expect('txt_value', 'Hello');
        Observer.Verify();
    end;

    [Test]
    procedure P132_FormatOfControl_StandardNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P132 Fmt Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('int_1', Format(Card.IdCtl, 0, 1));
        Observer.Observe('int_2', Format(Card.IdCtl, 0, 2));
        Observer.Observe('int_9', Format(Card.IdCtl, 0, 9));
        Observer.Observe('dec_1', Format(Card.DecCtl, 0, 1));
        Observer.Observe('dec_2', Format(Card.DecCtl, 0, 2));
        Observer.Observe('dec_9', Format(Card.DecCtl, 0, 9));
        Observer.Observe('txt_9', Format(Card.TxtCtl, 0, 9));
        Observer.Observe('flag_9', Format(Card.FlagCtl, 0, 9));
        Observer.Observe('flag_1', Format(Card.FlagCtl, 0, 1));
        Observer.Observe('dt_1', Format(Card.DtCtl, 0, 1));
        Observer.Observe('dt_9', Format(Card.DtCtl, 0, 9));
        Observer.Observe('int_len', Format(Card.IdCtl, 8));
        Card.Close();
        Observer.Expect('int_1', '1234');
        Observer.Expect('int_2', '1234');
        Observer.Expect('int_9', '1234');
        Observer.Expect('dec_1', '1,234.50');
        Observer.Expect('dec_2', '1,234.50');
        Observer.Expect('dec_9', '1,234.50');
        Observer.Expect('txt_9', 'Hello');
        Observer.Expect('flag_9', 'Yes');
        Observer.Expect('flag_1', 'Yes');
        Observer.Expect('dt_1', '3/5/2024');
        Observer.Expect('dt_9', '3/5/2024');
        Observer.Expect('int_len', '1234    ');
        Observer.Verify();
    end;
}
