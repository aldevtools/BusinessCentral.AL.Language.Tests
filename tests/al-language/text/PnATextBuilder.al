// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Text: TextBuilder operations outside the text
// Facts: TextBuilder.Insert, Remove, Replace and ToText with positions and lengths inside, at the edges and outside the text
// BC versions: 29 (27 and 28 by CI)

codeunit 70097 "LT PnA TextBuilder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TB: TextBuilder;
        Res: Text;

    [TryFunction]
    local procedure TryOp(Op: Integer)
    begin
        Clear(TB);
        TB.Append('hello');
        Res := '';
        case Op of
            1:
                TB.Insert(0, 'X');
            2:
                TB.Insert(1, 'X');
            3:
                TB.Insert(3, 'X');
            4:
                TB.Insert(5, 'X');
            5:
                TB.Insert(6, 'X');
            6:
                TB.Insert(7, 'X');
            7:
                TB.Insert(-1, 'X');
            8:
                TB.Remove(0, 1);
            9:
                TB.Remove(1, 1);
            10:
                TB.Remove(5, 1);
            11:
                TB.Remove(6, 1);
            12:
                TB.Remove(3, 10);
            13:
                TB.Remove(1, 0);
            14:
                TB.Remove(1, -1);
            15:
                TB.Remove(-1, 1);
            16:
                TB.Replace('l', 'L');
            17:
                TB.Replace('', 'x');
            18:
                TB.Replace('hello', '');
            19:
                TB.Replace('z', 'y');
            20:
                Res := TB.ToText(0, 2);
            21:
                Res := TB.ToText(1, 2);
            22:
                Res := TB.ToText(5, 1);
            23:
                Res := TB.ToText(6, 1);
            24:
                Res := TB.ToText(2, 10);
            25:
                Res := TB.ToText(2, -1);
            26:
                Res := TB.ToText(1, 0);
            27:
                Res := TB.ToText(1, 5);
            28:
                Res := TB.ToText(-1, 2);
        end;
        if Res = '' then
            Res := '<' + TB.ToText() + '>';
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Op: Integer)
    begin
        Observer.Observe('op' + Format(Op), Format(TryOp(Op)) + '|' + Res);
        Observer.ObserveError('op' + Format(Op));
    end;

    [Test]
    procedure Insert_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 7 do
            Probe(Observer, i);
        Observer.Expect('op1', 'No|');
        Observer.Expect('op1|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op1|code', 'ArgumentOutOfRange');
        Observer.Expect('op2', 'Yes|<Xhello>');
        Observer.Expect('op2|text', '');
        Observer.Expect('op2|code', '');
        Observer.Expect('op3', 'Yes|<heXllo>');
        Observer.Expect('op3|text', '');
        Observer.Expect('op3|code', '');
        Observer.Expect('op4', 'Yes|<hellXo>');
        Observer.Expect('op4|text', '');
        Observer.Expect('op4|code', '');
        Observer.Expect('op5', 'Yes|<helloX>');
        Observer.Expect('op5|text', '');
        Observer.Expect('op5|code', '');
        Observer.Expect('op6', 'No|');
        Observer.Expect('op6|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op6|code', 'ArgumentOutOfRange');
        Observer.Expect('op7', 'No|');
        Observer.Expect('op7|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op7|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 8 to 15 do
            Probe(Observer, i);
        Observer.Expect('op8', 'No|');
        Observer.Expect('op8|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op8|code', 'ArgumentOutOfRange');
        Observer.Expect('op9', 'Yes|<ello>');
        Observer.Expect('op9|text', '');
        Observer.Expect('op9|code', '');
        Observer.Expect('op10', 'Yes|<hell>');
        Observer.Expect('op10|text', '');
        Observer.Expect('op10|code', '');
        Observer.Expect('op11', 'No|');
        Observer.Expect('op11|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op11|code', 'ArgumentOutOfRange');
        Observer.Expect('op12', 'No|');
        Observer.Expect('op12|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op12|code', 'ArgumentOutOfRange');
        Observer.Expect('op13', 'Yes|<hello>');
        Observer.Expect('op13|text', '');
        Observer.Expect('op13|code', '');
        Observer.Expect('op14', 'No|');
        Observer.Expect('op14|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op14|code', 'ArgumentOutOfRange');
        Observer.Expect('op15', 'No|');
        Observer.Expect('op15|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op15|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_Cases()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 16 to 19 do
            Probe(Observer, i);
        Observer.Expect('op16', 'Yes|<heLLo>');
        Observer.Expect('op16|text', '');
        Observer.Expect('op16|code', '');
        Observer.Expect('op17', 'No|');
        Observer.Expect('op17|text', 'An invalid argument was passed to a ''TextBuilder'' data type method.');
        Observer.Expect('op17|code', 'Argument');
        Observer.Expect('op18', 'Yes|<>');
        Observer.Expect('op18|text', '');
        Observer.Expect('op18|code', '');
        Observer.Expect('op19', 'Yes|<hello>');
        Observer.Expect('op19|text', '');
        Observer.Expect('op19|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ToTextWithStartAndLength()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 20 to 28 do
            Probe(Observer, i);
        Observer.Expect('op20', 'Yes|he');
        Observer.Expect('op20|text', '');
        Observer.Expect('op20|code', '');
        Observer.Expect('op21', 'Yes|he');
        Observer.Expect('op21|text', '');
        Observer.Expect('op21|code', '');
        Observer.Expect('op22', 'Yes|o');
        Observer.Expect('op22|text', '');
        Observer.Expect('op22|code', '');
        Observer.Expect('op23', 'Yes|<hello>');
        Observer.Expect('op23|text', '');
        Observer.Expect('op23|code', '');
        Observer.Expect('op24', 'Yes|ello');
        Observer.Expect('op24|text', '');
        Observer.Expect('op24|code', '');
        Observer.Expect('op25', 'Yes|<hello>');
        Observer.Expect('op25|text', '');
        Observer.Expect('op25|code', '');
        Observer.Expect('op26', 'Yes|<hello>');
        Observer.Expect('op26|text', '');
        Observer.Expect('op26|code', '');
        Observer.Expect('op27', 'Yes|hello');
        Observer.Expect('op27|text', '');
        Observer.Expect('op27|code', '');
        Observer.Expect('op28', 'Yes|he');
        Observer.Expect('op28|text', '');
        Observer.Expect('op28|code', '');
        Observer.Verify();
    end;
}
