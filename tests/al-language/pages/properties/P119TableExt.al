// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: DecimalPlaces, OptionCaption, BlankNumbers, BlankZero and MaxValue on the fields of a table extension (Format, validation, Evaluate).

tableextension 71627 "LT P119 Row Ext" extends "LT P119 Row"
{
    fields
    {
        field(71650; ExtDec; Decimal) { DecimalPlaces = 1 : 4; }
        field(71651; ExtOpt; Option)
        {
            OptionMembers = Red,Green,Blue;
            OptionCaption = 'Rot,Gruen,Blau';
        }
        field(71652; ExtBlankNum; Decimal) { BlankNumbers = BlankZeroAndPos; }
        field(71653; ExtBlankZ; Decimal) { BlankZero = true; }
        field(71654; ExtMax; Decimal) { MaxValue = 100; }
    }
}

codeunit 71628 "LT P119 TableExt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_ExtDecimalPlaces()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.ExtDec := 2.5;
        Observer.Observe('two-five', Format(Row.ExtDec));
        Row.ExtDec := 1.23456789;
        Observer.Observe('long', Format(Row.ExtDec));
        Observer.Observe('long-xml', Format(Row.ExtDec, 0, 9));
        Observer.Observe('validate-ok', Format(TryDec(Row, 3.987654321)));
        Observer.Observe('validate-value-times', Format(Row.ExtDec * 1000000000));
        Row.ExtDec := 0;
        Observer.Observe('zero', Format(Row.ExtDec));
        Observer.Expect('two-five', '2.5');
        Observer.Expect('long', '1.2346');
        Observer.Expect('long-xml', '1.2346');
        Observer.Expect('validate-ok', 'Yes');
        Observer.Expect('validate-value-times', '3,987,654,321');
        Observer.Expect('zero', '0.0');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ExtOptionCaption()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.ExtOpt := Row.ExtOpt::Green;
        Observer.Observe('format', Format(Row.ExtOpt));
        Observer.Observe('format-1', Format(Row.ExtOpt, 0, 1));
        Observer.Observe('format-2', Format(Row.ExtOpt, 0, 2));
        Observer.Observe('format-9', Format(Row.ExtOpt, 0, 9));
        Observer.Observe('eval-member-ok', Format(Evaluate(Row.ExtOpt, 'Blue')));
        Observer.Observe('eval-caption-ok', Format(Evaluate(Row.ExtOpt, 'Rot')));
        Observer.Expect('format', 'Gruen');
        Observer.Expect('format-1', 'Gruen');
        Observer.Expect('format-2', '1');
        Observer.Expect('format-9', '1');
        Observer.Expect('eval-member-ok', 'Yes');
        Observer.Expect('eval-caption-ok', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ExtBlank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Observer.Observe('zero-blanknum', Format(Row.ExtBlankNum));
        Observer.Observe('zero-blankz', Format(Row.ExtBlankZ));
        Row.ExtBlankNum := 3;
        Row.ExtBlankZ := 3;
        Observer.Observe('pos-blanknum', Format(Row.ExtBlankNum));
        Observer.Observe('pos-blankz', Format(Row.ExtBlankZ));
        Row.ExtBlankNum := -3;
        Row.ExtBlankZ := -3;
        Observer.Observe('neg-blanknum', Format(Row.ExtBlankNum));
        Observer.Observe('neg-blankz', Format(Row.ExtBlankZ));
        Observer.Expect('zero-blanknum', '0');
        Observer.Expect('zero-blankz', '0');
        Observer.Expect('pos-blanknum', '3');
        Observer.Expect('pos-blankz', '3');
        Observer.Expect('neg-blanknum', '-3');
        Observer.Expect('neg-blankz', '-3');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ExtMaxValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Observer.Observe('hundred-ok', Format(TryMax(Row, 100)));
        Observer.Observe('over-ok', Format(TryMax(Row, 100.01)));
        Observer.ObserveError('over');
        Observer.Observe('negative-ok', Format(TryMax(Row, -500)));
        Observer.Observe('value', Format(Row.ExtMax));
        Observer.Expect('hundred-ok', 'Yes');
        Observer.Expect('over-ok', 'Yes');
        Observer.Expect('over|text', '');
        Observer.Expect('over|code', '');
        Observer.Expect('negative-ok', 'Yes');
        Observer.Expect('value', '-500');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDec(var Row: Record "LT P119 Row"; V: Decimal)
    begin
        Row.Validate(ExtDec, V);
    end;

    [TryFunction]
    local procedure TryMax(var Row: Record "LT P119 Row"; V: Decimal)
    begin
        Row.Validate(ExtMax, V);
    end;
}
