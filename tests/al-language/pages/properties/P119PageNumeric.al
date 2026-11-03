// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: page field properties Numeric, ClosingDates, BlankNumbers, MinValue/MaxValue and DecimalPlaces on page fields bound to table fields without those properties.

page 71671 "LT P119 PgProps Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(NumF; Rec.Phone)
            {
                ApplicationArea = All;
                Numeric = true;
            }
            field(ClosF; Rec.Closing)
            {
                ApplicationArea = All;
                ClosingDates = true;
            }
            field(BlankNumF; Rec.BlankZP)
            {
                ApplicationArea = All;
                BlankNumbers = BlankNeg;
            }
            field(RangedF; Rec.Dec)
            {
                ApplicationArea = All;
                MinValue = 1;
                MaxValue = 10;
                DecimalPlaces = 1 : 2;
            }
        }
    }
}

codeunit 71672 "LT P119 PgProps Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_PageFieldValues()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 PgProps Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('num-value', TP.NumF.Value());
        Observer.Observe('clos-value', TP.ClosF.Value());
        Observer.Observe('blanknum-value', TP.BlankNumF.Value());
        Observer.Observe('ranged-value', TP.RangedF.Value());
        Observer.Observe('num-visible', Format(TP.NumF.Visible()));
        Observer.Observe('ranged-editable', Format(TP.RangedF.Editable()));
        TP.BlankNumF.SetValue(5);
        Observer.Observe('blanknum-pos', TP.BlankNumF.Value());
        TP.BlankNumF.SetValue(-5);
        Observer.Observe('blanknum-neg', TP.BlankNumF.Value());
        TP.BlankNumF.SetValue(0);
        Observer.Observe('blanknum-zero', TP.BlankNumF.Value());
        TP.Close();
        Observer.Expect('num-value', '');
        Observer.Expect('clos-value', '');
        Observer.Expect('blanknum-value', '0.00');
        Observer.Expect('ranged-value', '0.0');
        Observer.Expect('num-visible', 'Yes');
        Observer.Expect('ranged-editable', 'Yes');
        Observer.Expect('blanknum-pos', '5.00');
        Observer.Expect('blanknum-neg', '0.00');
        Observer.Expect('blanknum-zero', '0.00');
        Observer.Verify();
    end;

    [Test]
    procedure P119_PageMinMax()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 PgProps Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.RangedF.SetValue(5.123);
        Observer.Observe('five', TP.RangedF.Value());
        asserterror TP.RangedF.SetValue(0.5);
        Observer.ObserveError('below');
        asserterror TP.RangedF.SetValue(11);
        Observer.ObserveError('above');
        Observer.Observe('after', TP.RangedF.Value());
        TP.Close();
        Observer.Expect('five', '5.12');
        Observer.Expect('below|text', 'Validation error for Field: RangedF,  Message = ''The value must be greater than or equal to 1. Value: 0.5. (Select Refresh to discard errors)''');
        Observer.Expect('below|code', 'TestValidation');
        Observer.Expect('above|text', 'Validation error for Field: RangedF,  Message = ''The value must be less than or equal to 10. Value: 11.0. (Select Refresh to discard errors)''');
        Observer.Expect('above|code', 'TestValidation');
        Observer.Expect('after', '5.12');
        Observer.Verify();
    end;

    [Test]
    procedure P119_PageNumericSetValue()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 PgProps Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.NumF.SetValue('12345');
        Observer.Observe('digits', TP.NumF.Value());
        asserterror TP.NumF.SetValue('abc');
        Observer.ObserveError('af102');
        Observer.Observe('letters', TP.NumF.Value());
        TP.Close();
        Observer.Expect('digits', '12345');
        Observer.Expect('af102|text', 'Validation error for Field: NumF,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Phone''. Only numeric characters are allowed in field. (Select Refresh to discard errors)''');
        Observer.Expect('af102|code', 'TestValidation');
        Observer.Expect('letters', '12345');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;
}
