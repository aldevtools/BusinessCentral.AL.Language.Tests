// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: corpus issue 673 item 3 (al-runtime-rs #294). Every literal asserted below is what BC 27.5, 28.5 and 29.0 produced in the corpus CI.
// Facts: Evaluate of a list of numbers with separators (; | : / .. blank) into Decimal, Integer and BigInteger: the Boolean result and the value of the variable afterwards (it starts at -1); and the error text and code when the result is not used.
// BC versions: 27+

codeunit 81865 "LT BL Evaluate Lists"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Inputs(var L: List of [Text])
    begin
        L.Add('1;5;10');
        L.Add('1;5');
        L.Add('1;');
        L.Add(';1');
        L.Add(';');
        L.Add('1|5|10');
        L.Add('1:5');
        L.Add('1/5');
        L.Add('1..10');
        L.Add('1 5 10');
        L.Add('1-5');
        L.Add('1&5');
        L.Add('1;5.5');
        L.Add(' 1 ; 5 ');
    end;

    // The al-runtime-rs #294 repro: the result used in an if.
    [Test]
    procedure Repro_SemicolonList_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Number: Decimal;
    begin
        if Evaluate(Number, '1;5;10') then
            Observer.Observe('if', 'true')
        else
            Observer.Observe('if', 'false');
        Observer.Observe('number', Format(Number, 0, 9));
        Observer.Expect('if', 'false');
        Observer.Expect('number', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Separators_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        T: Text;
        D: Decimal;
        Ok: Boolean;
    begin
        Inputs(L);
        foreach T in L do begin
            D := -1;
            Ok := Evaluate(D, T);
            Observer.Observe('[' + T + ']', Format(Ok) + ' ' + Format(D, 0, 9));
        end;
        Observer.Expect('[1;5;10]', 'No -1');
        Observer.Expect('[1;5]', 'No -1');
        Observer.Expect('[1;]', 'No -1');
        Observer.Expect('[;1]', 'No -1');
        Observer.Expect('[;]', 'No -1');
        Observer.Expect('[1|5|10]', 'No -1');
        Observer.Expect('[1:5]', 'No -1');
        Observer.Expect('[1/5]', 'No -1');
        Observer.Expect('[1..10]', 'No -1');
        Observer.Expect('[1 5 10]', 'No -1');
        Observer.Expect('[1-5]', 'No -1');
        Observer.Expect('[1&5]', 'No -1');
        Observer.Expect('[1;5.5]', 'No -1');
        Observer.Expect('[ 1 ; 5 ]', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure Separators_Integer()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        T: Text;
        I: Integer;
        Ok: Boolean;
    begin
        Inputs(L);
        foreach T in L do begin
            I := -1;
            Ok := Evaluate(I, T);
            Observer.Observe('[' + T + ']', Format(Ok) + ' ' + Format(I, 0, 9));
        end;
        Observer.Expect('[1;5;10]', 'No -1');
        Observer.Expect('[1;5]', 'No -1');
        Observer.Expect('[1;]', 'No -1');
        Observer.Expect('[;1]', 'No -1');
        Observer.Expect('[;]', 'No -1');
        Observer.Expect('[1|5|10]', 'No -1');
        Observer.Expect('[1:5]', 'No -1');
        Observer.Expect('[1/5]', 'No -1');
        Observer.Expect('[1..10]', 'No -1');
        Observer.Expect('[1 5 10]', 'No -1');
        Observer.Expect('[1-5]', 'No -1');
        Observer.Expect('[1&5]', 'No -1');
        Observer.Expect('[1;5.5]', 'No -1');
        Observer.Expect('[ 1 ; 5 ]', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure Separators_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        T: Text;
        B: BigInteger;
        Ok: Boolean;
    begin
        Inputs(L);
        foreach T in L do begin
            B := -1;
            Ok := Evaluate(B, T);
            Observer.Observe('[' + T + ']', Format(Ok) + ' ' + Format(B, 0, 9));
        end;
        Observer.Expect('[1;5;10]', 'No -1');
        Observer.Expect('[1;5]', 'No -1');
        Observer.Expect('[1;]', 'No -1');
        Observer.Expect('[;1]', 'No -1');
        Observer.Expect('[;]', 'No -1');
        Observer.Expect('[1|5|10]', 'No -1');
        Observer.Expect('[1:5]', 'No -1');
        Observer.Expect('[1/5]', 'No -1');
        Observer.Expect('[1..10]', 'No -1');
        Observer.Expect('[1 5 10]', 'No -1');
        Observer.Expect('[1-5]', 'No -1');
        Observer.Expect('[1&5]', 'No -1');
        Observer.Expect('[1;5.5]', 'No -1');
        Observer.Expect('[ 1 ; 5 ]', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure ResultNotUsed_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        I: Integer;
        B: BigInteger;
    begin
        D := -1;
        asserterror Evaluate(D, '1;5;10');
        Observer.ObserveError('decimal');
        Observer.Observe('decimal value', Format(D, 0, 9));
        I := -1;
        asserterror Evaluate(I, '1;5;10');
        Observer.ObserveError('integer');
        Observer.Observe('integer value', Format(I, 0, 9));
        B := -1;
        asserterror Evaluate(B, '1|5');
        Observer.ObserveError('biginteger pipe');
        Observer.Expect('decimal|text', 'The value "1;5;10" can''t be evaluated into type Decimal.');
        Observer.Expect('decimal|code', 'Evaluate');
        Observer.Expect('decimal value', '-1');
        Observer.Expect('integer|text', 'The value "1;5;10" can''t be evaluated into type Integer.');
        Observer.Expect('integer|code', 'Evaluate');
        Observer.Expect('integer value', '-1');
        Observer.Expect('biginteger pipe|text', 'The value "1|5" can''t be evaluated into type BigInteger.');
        Observer.Expect('biginteger pipe|code', 'Evaluate');
        Observer.Verify();
    end;
}
