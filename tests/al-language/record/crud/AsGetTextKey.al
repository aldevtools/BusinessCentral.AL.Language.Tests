// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79900, 79901)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 1).
// Facts: Record.Get given a text for an Integer and for a BigInteger primary key: Format(5), '5', 'x', '' and ' 5 ' (found row, false, or the error text).
// BC versions: 27-29

codeunit 79920 "LT AS Get Text Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        I: Record "LT AS Int Key";
        B: Record "LT AS Big Key";
    begin
        I.DeleteAll();
        B.DeleteAll();
        I.Id := 5;
        I.Name := 'five';
        I.Insert();
        I.Id := 0;
        I.Name := 'zero';
        I.Insert();
        B.Id := 5;
        B.Name := 'big five';
        B.Insert();
        B.Id := 0;
        B.Name := 'big zero';
        B.Insert();
    end;

    [TryFunction]
    local procedure TryGetInt(KeyText: Text; var Found: Boolean; var Name: Text)
    var
        I: Record "LT AS Int Key";
    begin
        Found := I.Get(KeyText);
        Name := I.Name;
    end;

    [TryFunction]
    local procedure TryGetBig(KeyText: Text; var Found: Boolean; var Name: Text)
    var
        B: Record "LT AS Big Key";
    begin
        Found := B.Get(KeyText);
        Name := B.Name;
    end;

    local procedure IntOutcome(KeyText: Text): Text
    var
        Found: Boolean;
        Name: Text;
    begin
        if TryGetInt(KeyText, Found, Name) then
            exit(Format(Found) + ':' + Name);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure BigOutcome(KeyText: Text): Text
    var
        Found: Boolean;
        Name: Text;
    begin
        if TryGetBig(KeyText, Found, Name) then
            exit(Format(Found) + ':' + Name);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure IntKey_FormatAndDigits()
    var
        Observer: Codeunit "Probe Observer";
        I: Record "LT AS Int Key";
    begin
        Seed();
        Observer.Observe('format5', IntOutcome(Format(5)));
        Observer.Observe('literal', Format(I.Get('5')) + ':' + I.Name);
        Observer.Observe('spaces', IntOutcome(' 5 '));
        Observer.Expect('format5', 'Yes:five');
        Observer.Expect('literal', 'Yes:five');
        Observer.Expect('spaces', 'Yes:five');
        Observer.Verify();
    end;

    [Test]
    procedure IntKey_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('x', IntOutcome('x'));
#if BC28PLUS
        Observer.Expect('x', 'error:The value "x" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('x', 'error:The type NavInteger is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure IntKey_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('empty', IntOutcome(''));
#if BC28PLUS
        Observer.Expect('empty', 'error:The value "" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('empty', 'error:The type NavInteger is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure IntKey_Missing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('seven', IntOutcome('7'));
        Observer.Expect('seven', 'No:');
        Observer.Verify();
    end;

    [Test]
    procedure BigKey_FormatAndDigits()
    var
        Observer: Codeunit "Probe Observer";
        B: Record "LT AS Big Key";
    begin
        Seed();
        Observer.Observe('format5', BigOutcome(Format(5)));
        Observer.Observe('literal', Format(B.Get('5')) + ':' + B.Name);
        Observer.Observe('spaces', BigOutcome(' 5 '));
        Observer.Expect('format5', 'Yes:big five');
        Observer.Expect('literal', 'Yes:big five');
        Observer.Expect('spaces', 'Yes:big five');
        Observer.Verify();
    end;

    [Test]
    procedure BigKey_Letter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('x', BigOutcome('x'));
#if BC28PLUS
        Observer.Expect('x', 'error:The value "x" can''t be evaluated into type BigInteger.|Evaluate:Format');
#else
        Observer.Expect('x', 'error:The type NavBigInteger is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure BigKey_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('empty', BigOutcome(''));
#if BC28PLUS
        Observer.Expect('empty', 'error:The value "" can''t be evaluated into type BigInteger.|Evaluate:Format');
#else
        Observer.Expect('empty', 'error:The type NavBigInteger is unknown.|NotSupportedType');
#endif
        Observer.Verify();
    end;
}
