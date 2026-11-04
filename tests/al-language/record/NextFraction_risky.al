// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-next-method
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: Record.Next with a fractional Decimal steps value (1.5, -1.5).
// BC versions: 29 (27 and 28 by CI)

table 70344 "LT P98 NextFracRow"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70345 "LT P98 NextFraction"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill()
    var
        R: Record "LT P98 NextFracRow";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 6 do begin
            R.Id := I;
            R.Insert();
        end;
    end;

    [Test]
    procedure P98_Next_FractionLiteral()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 NextFracRow";
    begin
        Fill();
        R.FindFirst();
        asserterror R.Next(1.5);
        Observer.ObserveError('next15');
        Observer.Observe('id1', Format(R.Id));
        asserterror R.Next(-1.5);
        Observer.ObserveError('nextm15');
        Observer.Observe('id2', Format(R.Id));
        R.DeleteAll();
        Observer.Expect('next15|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('next15|code', 'ConversionCast');
        Observer.Expect('id1', '1');
        Observer.Expect('nextm15|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Observer.Expect('nextm15|code', 'ConversionCast');
        Observer.Expect('id2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Next_FractionVariable()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 NextFracRow";
        Dec: Decimal;
    begin
        Fill();
        R.FindFirst();
        Dec := 1.5;
        asserterror R.Next(Dec);
        Observer.ObserveError('var15');
        Observer.Observe('id1', Format(R.Id));
        Dec := -1.5;
        asserterror R.Next(Dec);
        Observer.ObserveError('varm15');
        Dec := 2;
        Observer.Observe('whole', Format(R.Next(Dec)) + '|' + Format(R.Id));
        R.DeleteAll();
        Observer.Expect('var15|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('var15|code', 'ConversionCast');
        Observer.Expect('id1', '1');
        Observer.Expect('varm15|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Observer.Expect('varm15|code', 'ConversionCast');
        Observer.Expect('whole', '0|1');
        Observer.Verify();
    end;
}
