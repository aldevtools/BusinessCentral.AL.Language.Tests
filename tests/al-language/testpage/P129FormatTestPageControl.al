// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained enum 73324, table 73303, page 73304 and codeunit 73305
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of a TestPage control (the control itself, not its Value) of a card, with no format number and with the standard formats 0, 1, 2, 9, and with a length, for controls bound to
// Integer, Decimal, Date, Time, DateTime, Boolean, Option, Code, Text and Enum fields.
// BC versions: 29 (27 and 28 by CI)

enum 73324 "LT P129 TP Kind"
{
    Extensible = true;

    value(0; None) { }
    value(1; "Big Kind") { }
}

table 73303 "LT P129 TP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(3; Dec; Decimal) { }
        field(5; D; Date) { }
        field(6; T; Time) { }
        field(7; Dt; DateTime) { }
        field(8; Flag; Boolean) { }
        field(9; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
            OptionCaption = 'Nil,Uno,Dos';
        }
        field(10; Cd; Code[10]) { }
        field(11; Txt; Text[30]) { }
        field(12; Kind; Enum "LT P129 TP Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73304 "LT P129 TP Card"
{
    PageType = Card;
    SourceTable = "LT P129 TP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Dec; Rec.Dec) { ApplicationArea = All; }
                field(D; Rec.D) { ApplicationArea = All; }
                field(T; Rec.T) { ApplicationArea = All; }
                field(Dt; Rec.Dt) { ApplicationArea = All; }
                field(Flag; Rec.Flag) { ApplicationArea = All; }
                field(Opt; Rec.Opt) { ApplicationArea = All; }
                field(Cd; Rec.Cd) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 73305 "LT P129 Format TestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P129 TP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1234;
        Row.Dec := 1234.5;
        Row.D := 20240305D;
        Row.T := 134506T;
        Row.Dt := CreateDateTime(20240305D, 134506T);
        Row.Flag := true;
        Row.Opt := Row.Opt::Two;
        Row.Cd := 'abc';
        Row.Txt := 'Hello world';
        Row.Kind := Row.Kind::"Big Kind";
        Row.Insert();
    end;

    [Test]
    procedure P129_FormatTestPageControl_BooleanOptionCodeTextEnum()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P129 TP Card";
    begin
        Seed();
        Pg.OpenView();
        Observer.Observe('bool default', Format(Pg.Flag));
        Observer.Observe('bool 0', Format(Pg.Flag, 0, 0));
        Observer.Observe('bool 9', Format(Pg.Flag, 0, 9));
        Observer.Observe('option default', Format(Pg.Opt));
        Observer.Observe('option 0', Format(Pg.Opt, 0, 0));
        Observer.Observe('option 2', Format(Pg.Opt, 0, 2));
        Observer.Observe('option 9', Format(Pg.Opt, 0, 9));
        Observer.Observe('code default', Format(Pg.Cd));
        Observer.Observe('code 0', Format(Pg.Cd, 0, 0));
        Observer.Observe('text default', Format(Pg.Txt));
        Observer.Observe('text 0', Format(Pg.Txt, 0, 0));
        Observer.Observe('text 9', Format(Pg.Txt, 0, 9));
        Observer.Observe('text length 5', Format(Pg.Txt, 5));
        Observer.Observe('enum default', Format(Pg.Kind));
        Observer.Observe('enum 0', Format(Pg.Kind, 0, 0));
        Observer.Observe('enum 2', Format(Pg.Kind, 0, 2));
        Observer.Observe('enum 9', Format(Pg.Kind, 0, 9));
        Pg.Close();
        Observer.Expect('bool default', 'Yes');
        Observer.Expect('bool 0', 'Yes');
        Observer.Expect('bool 9', 'Yes');
        Observer.Expect('option default', 'Dos');
        Observer.Expect('option 0', 'Dos');
        Observer.Expect('option 2', 'Dos');
        Observer.Expect('option 9', 'Dos');
        Observer.Expect('code default', 'ABC');
        Observer.Expect('code 0', 'ABC');
        Observer.Expect('text default', 'Hello world');
        Observer.Expect('text 0', 'Hello world');
        Observer.Expect('text 9', 'Hello world');
        Observer.Expect('text length 5', 'Hello');
        Observer.Expect('enum default', 'Big Kind');
        Observer.Expect('enum 0', 'Big Kind');
        Observer.Expect('enum 2', 'Big Kind');
        Observer.Expect('enum 9', 'Big Kind');
        Observer.Verify();
    end;
}
