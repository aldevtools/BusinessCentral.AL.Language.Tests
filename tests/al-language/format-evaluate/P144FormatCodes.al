// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: spelling of the format codes <Sign>, <Integer>, <Precision>, <Standard Format> (case, blanks inside the brackets) on Integer and Decimal values
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 70232 "LT P144 Format Codes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(Value: Variant; Spec: Text; var Result: Text)
    begin
        Result := Format(Value, 0, Spec);
    end;

    local procedure Obs(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Variant; Spec: Text)
    var
        Result: Text;
    begin
        if TryFmt(Value, Spec, Result) then
            Observer.Observe(Name, '[' + Result + ']')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P144_Int_SignInteger()
    var
        Observer: Codeunit "Probe Observer";
        Pos: Integer;
        Neg: Integer;
        Zero: Integer;
    begin
        Pos := 5;
        Neg := -5;
        Zero := 0;
        Obs(Observer, 'canon_pos', Pos, '<Sign><Integer>');
        Obs(Observer, 'canon_neg', Neg, '<Sign><Integer>');
        Obs(Observer, 'canon_zero', Zero, '<Sign><Integer>');
        Obs(Observer, 'lower_pos', Pos, '<sign><integer>');
        Obs(Observer, 'lower_neg', Neg, '<sign><integer>');
        Obs(Observer, 'lower_zero', Zero, '<sign><integer>');
        Obs(Observer, 'upper_pos', Pos, '<SIGN><INTEGER>');
        Obs(Observer, 'upper_neg', Neg, '<SIGN><INTEGER>');
        Obs(Observer, 'upper_zero', Zero, '<SIGN><INTEGER>');
        Obs(Observer, 'spaced_pos', Pos, '< Sign >< Integer >');
        Obs(Observer, 'spaced_neg', Neg, '< Sign >< Integer >');
        Obs(Observer, 'spaced_zero', Zero, '< Sign >< Integer >');
        Obs(Observer, 'trail_pos', Pos, '<Sign ><Integer >');
        Obs(Observer, 'trail_neg', Neg, '<Sign ><Integer >');
        Obs(Observer, 'lead_pos', Pos, '< Sign><Integer>');
        Obs(Observer, 'lead_neg', Neg, '< Sign><Integer>');
        Obs(Observer, 'mixed_pos', Pos, '<sIgN><InTeGeR>');
        Obs(Observer, 'mixed_neg', Neg, '<sIgN><InTeGeR>');
        Obs(Observer, 'spacecomma_pos', Pos, '<Sign , 1><Integer>');
        Obs(Observer, 'spacecomma_neg', Neg, '<Sign , 1><Integer>');
        Observer.Expect('canon_pos', '[5]');
        Observer.Expect('canon_neg', '[-5]');
        Observer.Expect('canon_zero', '[0]');
        Observer.Expect('lower_pos', '[5]');
        Observer.Expect('lower_neg', '[-5]');
        Observer.Expect('lower_zero', '[0]');
        Observer.Expect('upper_pos', '[5]');
        Observer.Expect('upper_neg', '[-5]');
        Observer.Expect('upper_zero', '[0]');
        Observer.Expect('spaced_pos|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign >< Integer >');
        Observer.Expect('spaced_pos|code', 'InvalidFormatString');
        Observer.Expect('spaced_neg|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign >< Integer >');
        Observer.Expect('spaced_neg|code', 'InvalidFormatString');
        Observer.Expect('spaced_zero|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign >< Integer >');
        Observer.Expect('spaced_zero|code', 'InvalidFormatString');
        Observer.Expect('trail_pos|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Sign ><Integer >');
        Observer.Expect('trail_pos|code', 'InvalidFormatString');
        Observer.Expect('trail_neg|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Sign ><Integer >');
        Observer.Expect('trail_neg|code', 'InvalidFormatString');
        Observer.Expect('lead_pos|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign><Integer>');
        Observer.Expect('lead_pos|code', 'InvalidFormatString');
        Observer.Expect('lead_neg|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign><Integer>');
        Observer.Expect('lead_neg|code', 'InvalidFormatString');
        Observer.Expect('mixed_pos', '[5]');
        Observer.Expect('mixed_neg', '[-5]');
        Observer.Expect('spacecomma_pos|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Sign , 1><Integer>');
        Observer.Expect('spacecomma_pos|code', 'InvalidFormatString');
        Observer.Expect('spacecomma_neg|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Sign , 1><Integer>');
        Observer.Expect('spacecomma_neg|code', 'InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure P144_Int_Precision()
    var
        Observer: Codeunit "Probe Observer";
        Pos: Integer;
        Neg: Integer;
        Zero: Integer;
    begin
        Pos := 1234;
        Neg := -1234;
        Zero := 0;
        Obs(Observer, 'canon_pos', Pos, '<Precision,2:2><Standard Format,0>');
        Obs(Observer, 'canon_neg', Neg, '<Precision,2:2><Standard Format,0>');
        Obs(Observer, 'canon_zero', Zero, '<Precision,2:2><Standard Format,0>');
        Obs(Observer, 'lower_pos', Pos, '<precision,2:2><standard format,0>');
        Obs(Observer, 'lower_neg', Neg, '<precision,2:2><standard format,0>');
        Obs(Observer, 'lower_zero', Zero, '<precision,2:2><standard format,0>');
        Obs(Observer, 'upper_pos', Pos, '<PRECISION,2:2><STANDARD FORMAT,0>');
        Obs(Observer, 'upper_neg', Neg, '<PRECISION,2:2><STANDARD FORMAT,0>');
        Obs(Observer, 'spaced_pos', Pos, '<precision, 2:2><standard format,0>');
        Obs(Observer, 'spaced_neg', Neg, '<precision, 2:2><standard format,0>');
        Obs(Observer, 'spaced_zero', Zero, '<precision, 2:2><standard format,0>');
        Obs(Observer, 'trail_pos', Pos, '<Precision,2:2 ><Standard Format,0>');
        Obs(Observer, 'trail_neg', Neg, '<Precision,2:2 ><Standard Format,0>');
        Obs(Observer, 'fmtspace_pos', Pos, '<Precision,2:2><Standard Format, 0>');
        Obs(Observer, 'fmtspace_neg', Neg, '<Precision,2:2><Standard Format, 0>');
        Obs(Observer, 'precalone_pos', Pos, '<Precision,2:2 >');
        Obs(Observer, 'precalone_neg', Neg, '<Precision,2:2 >');
        Obs(Observer, 'precalone_canon_pos', Pos, '<Precision,2:2>');
        Obs(Observer, 'precalone_canon_neg', Neg, '<Precision,2:2>');
        Observer.Expect('canon_pos', '[1234]');
        Observer.Expect('canon_neg', '[-1234]');
        Observer.Expect('canon_zero', '[0]');
        Observer.Expect('lower_pos', '[1234]');
        Observer.Expect('lower_neg', '[-1234]');
        Observer.Expect('lower_zero', '[0]');
        Observer.Expect('upper_pos', '[1234]');
        Observer.Expect('upper_neg', '[-1234]');
        Observer.Expect('spaced_pos', '[1234]');
        Observer.Expect('spaced_neg', '[-1234]');
        Observer.Expect('spaced_zero', '[0]');
        Observer.Expect('trail_pos', '[1234]');
        Observer.Expect('trail_neg', '[-1234]');
        Observer.Expect('fmtspace_pos', '[1234]');
        Observer.Expect('fmtspace_neg', '[-1234]');
        Observer.Expect('precalone_pos', '[]');
        Observer.Expect('precalone_neg', '[]');
        Observer.Expect('precalone_canon_pos', '[]');
        Observer.Expect('precalone_canon_neg', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P144_Dec_SignInteger()
    var
        Observer: Codeunit "Probe Observer";
        Pos: Decimal;
        Neg: Decimal;
        Zero: Decimal;
    begin
        Pos := 5.75;
        Neg := -5.75;
        Zero := 0;
        Obs(Observer, 'canon_pos', Pos, '<Sign><Integer>');
        Obs(Observer, 'canon_neg', Neg, '<Sign><Integer>');
        Obs(Observer, 'canon_zero', Zero, '<Sign><Integer>');
        Obs(Observer, 'lower_pos', Pos, '<sign><integer>');
        Obs(Observer, 'lower_neg', Neg, '<sign><integer>');
        Obs(Observer, 'lower_zero', Zero, '<sign><integer>');
        Obs(Observer, 'upper_pos', Pos, '<SIGN><INTEGER>');
        Obs(Observer, 'upper_neg', Neg, '<SIGN><INTEGER>');
        Obs(Observer, 'upper_zero', Zero, '<SIGN><INTEGER>');
        Obs(Observer, 'spaced_pos', Pos, '< Sign >< Integer >');
        Obs(Observer, 'spaced_neg', Neg, '< Sign >< Integer >');
        Obs(Observer, 'spaced_zero', Zero, '< Sign >< Integer >');
        Obs(Observer, 'dec_canon_neg', Neg, '<Sign><Integer><Decimals>');
        Obs(Observer, 'dec_lower_neg', Neg, '<sign><integer><decimals>');
        Obs(Observer, 'dec_upper_pos', Pos, '<SIGN><INTEGER><DECIMALS>');
        Obs(Observer, 'dec_spaced_neg', Neg, '< Sign >< Integer >< Decimals >');
        Observer.Expect('canon_pos', '[5]');
        Observer.Expect('canon_neg', '[-5]');
        Observer.Expect('canon_zero', '[0]');
        Observer.Expect('lower_pos', '[5]');
        Observer.Expect('lower_neg', '[-5]');
        Observer.Expect('lower_zero', '[0]');
        Observer.Expect('upper_pos', '[5]');
        Observer.Expect('upper_neg', '[-5]');
        Observer.Expect('upper_zero', '[0]');
        Observer.Expect('spaced_pos|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign >< Integer >');
        Observer.Expect('spaced_pos|code', 'InvalidFormatString');
        Observer.Expect('spaced_neg|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign >< Integer >');
        Observer.Expect('spaced_neg|code', 'InvalidFormatString');
        Observer.Expect('spaced_zero|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign >< Integer >');
        Observer.Expect('spaced_zero|code', 'InvalidFormatString');
        Observer.Expect('dec_canon_neg', '[-5.75]');
        Observer.Expect('dec_lower_neg', '[-5.75]');
        Observer.Expect('dec_upper_pos', '[5.75]');
        Observer.Expect('dec_spaced_neg|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\< Sign >< Integer >< Decimals >');
        Observer.Expect('dec_spaced_neg|code', 'InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure P144_Dec_Precision()
    var
        Observer: Codeunit "Probe Observer";
        Pos: Decimal;
        Neg: Decimal;
        Zero: Decimal;
    begin
        Pos := 1234.567;
        Neg := -1234.567;
        Zero := 0;
        Obs(Observer, 'canon_pos', Pos, '<Precision,2:2><Standard Format,0>');
        Obs(Observer, 'canon_neg', Neg, '<Precision,2:2><Standard Format,0>');
        Obs(Observer, 'canon_zero', Zero, '<Precision,2:2><Standard Format,0>');
        Obs(Observer, 'lower_pos', Pos, '<precision,2:2><standard format,0>');
        Obs(Observer, 'lower_neg', Neg, '<precision,2:2><standard format,0>');
        Obs(Observer, 'lower_zero', Zero, '<precision,2:2><standard format,0>');
        Obs(Observer, 'upper_pos', Pos, '<PRECISION,2:2><STANDARD FORMAT,0>');
        Obs(Observer, 'upper_neg', Neg, '<PRECISION,2:2><STANDARD FORMAT,0>');
        Obs(Observer, 'spaced_pos', Pos, '<precision, 2:2><standard format,0>');
        Obs(Observer, 'spaced_neg', Neg, '<precision, 2:2><standard format,0>');
        Obs(Observer, 'spaced_zero', Zero, '<precision, 2:2><standard format,0>');
        Obs(Observer, 'trail_pos', Pos, '<Precision,2:2 ><Standard Format,0>');
        Obs(Observer, 'trail_neg', Neg, '<Precision,2:2 ><Standard Format,0>');
        Obs(Observer, 'trail_zero', Zero, '<Precision,2:2 ><Standard Format,0>');
        Obs(Observer, 'precalone_pos', Pos, '<Precision,2:2 >');
        Obs(Observer, 'precalone_neg', Neg, '<Precision,2:2 >');
        Obs(Observer, 'precalone_zero', Zero, '<Precision,2:2 >');
        Obs(Observer, 'precalone_canon_pos', Pos, '<Precision,2:2>');
        Obs(Observer, 'precalone_canon_neg', Neg, '<Precision,2:2>');
        Obs(Observer, 'fmtspace_pos', Pos, '<Precision,2:2><Standard Format, 0>');
        Observer.Expect('canon_pos', '[1,234.57]');
        Observer.Expect('canon_neg', '[-1,234.57]');
        Observer.Expect('canon_zero', '[0.00]');
        Observer.Expect('lower_pos', '[1,234.57]');
        Observer.Expect('lower_neg', '[-1,234.57]');
        Observer.Expect('lower_zero', '[0.00]');
        Observer.Expect('upper_pos', '[1,234.57]');
        Observer.Expect('upper_neg', '[-1,234.57]');
        Observer.Expect('spaced_pos', '[1,234.57]');
        Observer.Expect('spaced_neg', '[-1,234.57]');
        Observer.Expect('spaced_zero', '[0.00]');
        Observer.Expect('trail_pos', '[1,234.57]');
        Observer.Expect('trail_neg', '[-1,234.57]');
        Observer.Expect('trail_zero', '[0.00]');
        Observer.Expect('precalone_pos', '[]');
        Observer.Expect('precalone_neg', '[]');
        Observer.Expect('precalone_zero', '[]');
        Observer.Expect('precalone_canon_pos', '[]');
        Observer.Expect('precalone_canon_neg', '[]');
        Observer.Expect('fmtspace_pos', '[1,234.57]');
        Observer.Verify();
    end;
}
