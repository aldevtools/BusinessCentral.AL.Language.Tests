// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/evaluate-function
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums of OjT71038.al, self-contained test codeunit 71043
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Enum FromInteger, Evaluate by name/caption/ordinal, comparison and in, assignment
// BC versions: 29 (27 and 28 by CI)
// Added by writer BN3 (corpus #664 items 67, 70): table 83865, BN3_EnumAgainstIntegers, BN3_EnumTestFieldWithInteger, BN3_EnumNamesOrdinalsWithoutParentheses.

codeunit 71043 "LT OjT Enum Convert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FromInteger_Valid()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        N: Enum "LT OjT NoZero";
    begin
        C := Enum::"LT OjT Color".FromInteger(0);
        Observer.Observe('c0', Format(C) + '|' + Format(C, 0, 2));
        C := Enum::"LT OjT Color".FromInteger(1);
        Observer.Observe('c1', Format(C) + '|' + Format(C, 0, 2));
        C := Enum::"LT OjT Color".FromInteger(5);
        Observer.Observe('c5', Format(C) + '|' + Format(C, 0, 2));
        C := Enum::"LT OjT Color".FromInteger(10);
        Observer.Observe('c10', Format(C) + '|' + Format(C, 0, 2));
        N := Enum::"LT OjT NoZero".FromInteger(2);
        Observer.Observe('n2', Format(N) + '|' + Format(N, 0, 2));
        Observer.Observe('eq', Format(Enum::"LT OjT Color".FromInteger(5) = Enum::"LT OjT Color"::"Dark Blue"));
        Observer.Expect('c0', 'Red|0');
        Observer.Expect('c1', 'Green Caption|1');
        Observer.Expect('c5', 'Navy|5');
        Observer.Expect('c10', 'Sunny|10');
        Observer.Expect('n2', 'Two|2');
        Observer.Expect('eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_ByName()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        Ok: Boolean;
    begin
        Ok := Evaluate(C, 'Green');
        Observer.Observe('Green', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'green');
        Observer.Observe('green', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'GREEN');
        Observer.Observe('GREEN', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'Dark Blue');
        Observer.Observe('DarkBlue', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'dark blue');
        Observer.Observe('darkblue', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'Yellow');
        Observer.Observe('Yellow', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, ' Red ');
        Observer.Observe('paddedRed', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'Pink');
        Observer.Observe('Pink', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '');
        Observer.Observe('empty', Format(Ok) + '|' + Format(C, 0, 2));
        Observer.Expect('Green', 'Yes|1');
        Observer.Expect('green', 'Yes|1');
        Observer.Expect('GREEN', 'Yes|1');
        Observer.Expect('DarkBlue', 'Yes|5');
        Observer.Expect('darkblue', 'Yes|5');
        Observer.Expect('Yellow', 'Yes|10');
        Observer.Expect('paddedRed', 'Yes|0');
        Observer.Expect('Pink', 'No|0');
        Observer.Expect('empty', 'No|0');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_ByCaption()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        Ok: Boolean;
    begin
        Ok := Evaluate(C, 'Navy');
        Observer.Observe('Navy', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'navy');
        Observer.Observe('navy', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'Green Caption');
        Observer.Observe('GreenCaption', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'Sunny');
        Observer.Observe('Sunny', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, 'Red');
        Observer.Observe('Red', Format(Ok) + '|' + Format(C, 0, 2));
        Observer.Expect('Navy', 'Yes|5');
        Observer.Expect('navy', 'Yes|5');
        Observer.Expect('GreenCaption', 'Yes|1');
        Observer.Expect('Sunny', 'Yes|10');
        Observer.Expect('Red', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_ByOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        Ok: Boolean;
    begin
        Ok := Evaluate(C, '0');
        Observer.Observe('0', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '1');
        Observer.Observe('1', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '5');
        Observer.Observe('5', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '10');
        Observer.Observe('10', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '2');
        Observer.Observe('2', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '-1');
        Observer.Observe('-1', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '1.0');
        Observer.Observe('1.0', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, ' 1');
        Observer.Observe('space1', Format(Ok) + '|' + Format(C, 0, 2));
        Ok := Evaluate(C, '99999999999');
        Observer.Observe('huge', Format(Ok) + '|' + Format(C, 0, 2));
        Observer.Expect('0', 'Yes|0');
        Observer.Expect('1', 'Yes|1');
        Observer.Expect('5', 'Yes|5');
        Observer.Expect('10', 'Yes|10');
        Observer.Expect('2', 'Yes|2');
        Observer.Expect('-1', 'No|2');
        Observer.Expect('1.0', 'No|2');
        Observer.Expect('space1', 'Yes|1');
        Observer.Expect('huge', 'No|1');
        Observer.Verify();
    end;

    [Test]
    procedure Comparison_EqualAndOrder()
    var
        Observer: Codeunit "Probe Observer";
        A: Enum "LT OjT Color";
        B: Enum "LT OjT Color";
    begin
        A := Enum::"LT OjT Color"::Green;
        B := Enum::"LT OjT Color"::Green;
        Observer.Observe('GG.eq', Format(A = B));
        Observer.Observe('GG.ne', Format(A <> B));
        Observer.Observe('GG.lt', Format(A < B));
        Observer.Observe('GG.le', Format(A <= B));
        B := Enum::"LT OjT Color"::"Dark Blue";
        Observer.Observe('GD.eq', Format(A = B));
        Observer.Observe('GD.ne', Format(A <> B));
        Observer.Observe('GD.lt', Format(A < B));
        Observer.Observe('GD.gt', Format(A > B));
        Observer.Observe('GD.le', Format(A <= B));
        Observer.Observe('GD.ge', Format(A >= B));
        B := Enum::"LT OjT Color"::Yellow;
        Observer.Observe('GY.lt', Format(A < B));
        Observer.Observe('YG.gt', Format(B > A));
        Observer.Observe('Yellow=literal', Format(B = Enum::"LT OjT Color"::Yellow));
        Observer.Expect('GG.eq', 'Yes');
        Observer.Expect('GG.ne', 'No');
        Observer.Expect('GG.lt', 'No');
        Observer.Expect('GG.le', 'Yes');
        Observer.Expect('GD.eq', 'No');
        Observer.Expect('GD.ne', 'Yes');
        Observer.Expect('GD.lt', 'Yes');
        Observer.Expect('GD.gt', 'No');
        Observer.Expect('GD.le', 'Yes');
        Observer.Expect('GD.ge', 'No');
        Observer.Expect('GY.lt', 'Yes');
        Observer.Expect('YG.gt', 'Yes');
        Observer.Expect('Yellow=literal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Comparison_InOperator()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
    begin
        C := Enum::"LT OjT Color"::Green;
        Observer.Observe('Green.inRG', Format(C in [Enum::"LT OjT Color"::Red, Enum::"LT OjT Color"::Green]));
        Observer.Observe('Green.inRB', Format(C in [Enum::"LT OjT Color"::Red, Enum::"LT OjT Color"::"Dark Blue"]));
        Observer.Observe('Green.inY', Format(C in [Enum::"LT OjT Color"::Yellow]));
        C := Enum::"LT OjT Color"::Yellow;
        Observer.Observe('Yellow.inY', Format(C in [Enum::"LT OjT Color"::Yellow]));
        Observer.Expect('Green.inRG', 'Yes');
        Observer.Expect('Green.inRB', 'No');
        Observer.Expect('Green.inY', 'No');
        Observer.Expect('Yellow.inY', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Assignment_BetweenVariables()
    var
        Observer: Codeunit "Probe Observer";
        A: Enum "LT OjT Color";
        B: Enum "LT OjT Color";
        I: Integer;
    begin
        A := Enum::"LT OjT Color"::"Dark Blue";
        B := A;
        A := Enum::"LT OjT Color"::Red;
        Observer.Observe('copy', Format(B, 0, 2));
        Observer.Observe('orig', Format(A, 0, 2));
        Evaluate(I, Format(B, 0, 2));
        Observer.Observe('viaText', Format(I + 1));
        Observer.Observe('caption', Format(B));
        Observer.Observe('name', Format(B, 0, 1));
        Observer.Expect('copy', '5');
        Observer.Expect('orig', '0');
        Observer.Expect('viaText', '6');
        Observer.Expect('caption', 'Navy');
        Observer.Expect('name', 'Navy');
        Observer.Verify();
    end;

    // Corpus #664 item 67: an enum against Integer values: `in` with an Integer set, `<`/`>`/`=` with an Integer literal, foreach over Ordinals().
    [Test]
    procedure BN3_EnumAgainstIntegers()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
        Seen: Text;
    begin
        C := Enum::"LT OjT Color"::Green;
        Observer.Observe('Green in [0,1,2]', Format(C in [0, 1, 2]));
        Observer.Observe('Green in [0,2]', Format(C in [0, 2]));
        Observer.Observe('Green < 5', Format(C < 5));
        Observer.Observe('Green > 0', Format(C > 0));
        Observer.Observe('Green = 1', Format(C = 1));
        C := Enum::"LT OjT Color"::Yellow;
        Observer.Observe('Yellow in [10]', Format(C in [10]));
        Observer.Observe('Yellow > 5', Format(C > 5));
        Observer.Observe('Yellow < 10', Format(C < 10));
        foreach C in C.Ordinals() do
            Seen += Format(C) + '/' + Format(C.AsInteger()) + ';';
        Observer.Observe('foreach Ordinals', Seen);
        Observer.Expect('Green in [0,1,2]', 'Yes');
        Observer.Expect('Green in [0,2]', 'No');
        Observer.Expect('Green < 5', 'Yes');
        Observer.Expect('Green > 0', 'Yes');
        Observer.Expect('Green = 1', 'Yes');
        Observer.Expect('Yellow in [10]', 'Yes');
        Observer.Expect('Yellow > 5', 'Yes');
        Observer.Expect('Yellow < 10', 'No');
        Observer.Expect('foreach Ordinals', 'Red/0;Green Caption/1;Navy/5;Sunny/10;');
        Observer.Verify();
    end;

    // Corpus #664 item 67: TestField of an enum field with an Integer value.
    [Test]
    procedure BN3_EnumTestFieldWithInteger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BN3 Enum Row";
    begin
        Row.Init();
        Row.Id := 1;
        Row.Col := Enum::"LT OjT Color"::"Dark Blue";
        Row.TestField(Col, 5);
        Observer.Observe('TestField 5', 'no error');
        asserterror Row.TestField(Col, 1);
        Observer.ObserveError('TestField 1');
        asserterror Row.TestField(Col, 3);
        Observer.ObserveError('TestField 3');
        Observer.Expect('TestField 5', 'no error');
        Observer.Expect('TestField 1|text', 'Col must be equal to ''Green Caption''  in LT BN3 Enum Row: Id=1. Current value is ''Navy''.');
        Observer.Expect('TestField 1|code', 'TestField');
        Observer.Expect('TestField 3|text', 'Col must be equal to ''3''  in LT BN3 Enum Row: Id=1. Current value is ''Navy''.');
        Observer.Expect('TestField 3|code', 'TestField');
        Observer.Verify();
    end;

    // Corpus #664 item 70: Names and Ordinals without parentheses, on the enum type and on a variable.
    [Test]
    procedure BN3_EnumNamesOrdinalsWithoutParentheses()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT OjT Color";
    begin
        Observer.Observe('type Names.Get(Ordinals.IndexOf(5))', Enum::"LT OjT Color".Names.Get(Enum::"LT OjT Color".Ordinals.IndexOf(5)));
        Observer.Observe('variable Names count', Format(C.Names.Count()));
        Observer.Observe('variable Ordinals last', Format(C.Ordinals.Get(C.Ordinals.Count())));
        Observer.Expect('type Names.Get(Ordinals.IndexOf(5))', 'Dark Blue');
        Observer.Expect('variable Names count', '4');
        Observer.Expect('variable Ordinals last', '10');
        Observer.Verify();
    end;
}

// Corpus #664 item 67: a table with a field of enum "LT OjT Color" (OjT71038.al) for TestField with an Integer value.
table 83865 "LT BN3 Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Col; Enum "LT OjT Color") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
