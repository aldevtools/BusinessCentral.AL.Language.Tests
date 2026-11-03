// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: JSON: Refused, not pinned: the error text of an out-of-range index in the typed getters
// Facts: typed getters of JsonArray/JsonObject: out-of-range index, missing key with RequireValueExists, wrong token kind, numeric text
// BC versions: 29 (27 and 28 by CI)

codeunit 70078 "LT PnA Json Getters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        JO: JsonObject;
        JA: JsonArray;
        JT: JsonToken;
        R: Text;

    local procedure Setup()
    begin
        JO.ReadFrom('{"a":1,"b":"txt","c":[1],"d":{"e":2},"n":"12","t":true,"z":null}');
        JA.ReadFrom('[10,"x",true,[1],{"k":1},null]');
    end;

    [TryFunction]
    local procedure TryOp(Op: Integer)
    begin
        R := '';
        case Op of
            1:
                R := JA.GetText(10);
            2:
                R := Format(JA.GetInteger(10));
            3:
                R := Format(JA.GetBoolean(10));
            4:
                R := Format(JA.GetObject(10));
            5:
                R := Format(JA.GetArray(10));
            6:
                R := JA.GetText(-1);
            7:
                R := JA.GetText(0);
            8:
                R := JA.GetText(JA.Count());
            9:
                R := Format(JA.GetInteger(1));
            10:
                R := Format(JA.GetInteger(2));
            11:
                R := JA.GetText(0);
            12:
                R := JO.GetText('zz', true);
            13:
                R := JO.GetText('zz', false);
            14:
                R := Format(JO.GetInteger('zz', true));
            15:
                R := Format(JO.GetInteger('zz', false));
            16:
                R := Format(JO.GetBoolean('zz', true));
            17:
                R := Format(JO.GetInteger('n'));
            18:
                R := Format(JO.GetInteger('b'));
            19:
                R := JO.GetText('a');
            20:
                R := JO.GetText('z');
            21:
                R := Format(JO.GetBoolean('t'));
        end;
    end;

    [TryFunction]
    local procedure TryKinds(Op: Integer)
    var
        O: JsonObject;
        A: JsonArray;
        V: JsonValue;
    begin
        R := '';
        case Op of
            1:
                begin
                    JO.Get('a', JT);
                    O := JT.AsObject();
                end;
            2:
                begin
                    JO.Get('a', JT);
                    A := JT.AsArray();
                end;
            3:
                begin
                    JO.Get('c', JT);
                    O := JT.AsObject();
                end;
            4:
                begin
                    JO.Get('d', JT);
                    A := JT.AsArray();
                end;
            5:
                begin
                    JO.Get('d', JT);
                    V := JT.AsValue();
                end;
            6:
                begin
                    JO.Get('c', JT);
                    V := JT.AsValue();
                end;
            7:
                begin
                    JO.Get('z', JT);
                    R := Format(JT.AsValue().IsNull());
                end;
            8:
                begin
                    JO.Get('b', JT);
                    R := Format(JT.AsValue().AsInteger());
                end;
            9:
                begin
                    JO.Get('a', JT);
                    R := JT.AsValue().AsText();
                end;
            10:
                begin
                    JO.Get('n', JT);
                    R := Format(JT.AsValue().AsInteger());
                end;
            11:
                begin
                    JO.Get('t', JT);
                    R := JT.AsValue().AsText();
                end;
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Integer)
    begin
        Observer.Observe(Name, Format(TryOp(Op)) + '|' + R);
        Observer.ObserveError(Name);
    end;

    local procedure ProbeKind(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Integer)
    begin
        Observer.Observe(Name, Format(TryKinds(Op)) + '|' + R);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure ArrayIndexOutOfRange()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Setup();
        for i := 1 to 8 do
            Probe(Observer, 'array-op' + Format(i), i);
        Observer.Expect('array-op1', 'No|');
        Observer.Expect('array-op1|text', 'Index out of bounds.');
        Observer.Expect('array-op1|code', 'IndexOutOfBounds');
        Observer.Expect('array-op2', 'No|');
        Observer.Expect('array-op2|text', 'Index out of bounds.');
        Observer.Expect('array-op2|code', 'IndexOutOfBounds');
        Observer.Expect('array-op3', 'No|');
        Observer.Expect('array-op3|text', 'Index out of bounds.');
        Observer.Expect('array-op3|code', 'IndexOutOfBounds');
        Observer.Expect('array-op4', 'No|');
        Observer.Expect('array-op4|text', 'Index out of bounds.');
        Observer.Expect('array-op4|code', 'IndexOutOfBounds');
        Observer.Expect('array-op5', 'No|');
        Observer.Expect('array-op5|text', 'Index out of bounds.');
        Observer.Expect('array-op5|code', 'IndexOutOfBounds');
        Observer.Expect('array-op6', 'No|');
        Observer.Expect('array-op6|text', 'Index out of bounds.');
        Observer.Expect('array-op6|code', 'IndexOutOfBounds');
        Observer.Expect('array-op7', 'Yes|10');
        Observer.Expect('array-op7|text', '');
        Observer.Expect('array-op7|code', '');
        Observer.Expect('array-op8', 'No|');
        Observer.Expect('array-op8|text', 'Index out of bounds.');
        Observer.Expect('array-op8|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayWrongKindAtIndex()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Probe(Observer, 'int-of-text', 9);
        Probe(Observer, 'int-of-bool', 10);
        Probe(Observer, 'text-of-int-at0', 11);
        Observer.Expect('int-of-text', 'No|');
        Observer.Expect('int-of-text|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        Observer.Expect('int-of-text|code', 'Conversion');
        Observer.Expect('int-of-bool', 'Yes|1');
        Observer.Expect('int-of-bool|text', '');
        Observer.Expect('int-of-bool|code', '');
        Observer.Expect('text-of-int-at0', 'Yes|10');
        Observer.Expect('text-of-int-at0|text', '');
        Observer.Expect('text-of-int-at0|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectMissingKeyAndKinds()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Setup();
        for i := 12 to 21 do
            Probe(Observer, 'object-op' + Format(i), i);
        Observer.Expect('object-op12', 'Yes|');
        Observer.Expect('object-op12|text', '');
        Observer.Expect('object-op12|code', '');
        Observer.Expect('object-op13', 'No|');
        Observer.Expect('object-op13|text', 'There is no property with the ''zz'' key on the JSON object.');
        Observer.Expect('object-op13|code', 'JsonPropertyNotFound');
        Observer.Expect('object-op14', 'Yes|0');
        Observer.Expect('object-op14|text', '');
        Observer.Expect('object-op14|code', '');
        Observer.Expect('object-op15', 'No|');
        Observer.Expect('object-op15|text', 'There is no property with the ''zz'' key on the JSON object.');
        Observer.Expect('object-op15|code', 'JsonPropertyNotFound');
        Observer.Expect('object-op16', 'Yes|No');
        Observer.Expect('object-op16|text', '');
        Observer.Expect('object-op16|code', '');
        Observer.Expect('object-op17', 'Yes|12');
        Observer.Expect('object-op17|text', '');
        Observer.Expect('object-op17|code', '');
        Observer.Expect('object-op18', 'No|');
        Observer.Expect('object-op18|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        Observer.Expect('object-op18|code', 'Conversion');
        Observer.Expect('object-op19', 'Yes|1');
        Observer.Expect('object-op19|text', '');
        Observer.Expect('object-op19|code', '');
        Observer.Expect('object-op20', 'Yes|');
        Observer.Expect('object-op20|text', '');
        Observer.Expect('object-op20|code', '');
        Observer.Expect('object-op21', 'Yes|Yes');
        Observer.Expect('object-op21|text', '');
        Observer.Expect('object-op21|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure TokenAsOtherKind()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Setup();
        for i := 1 to 11 do
            ProbeKind(Observer, 'token-op' + Format(i), i);
        Observer.Expect('token-op1', 'No|');
        Observer.Expect('token-op1|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.');
        Observer.Expect('token-op1|code', 'Conversion');
        Observer.Expect('token-op2', 'No|');
        Observer.Expect('token-op2|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.');
        Observer.Expect('token-op2|code', 'Conversion');
        Observer.Expect('token-op3', 'No|');
        Observer.Expect('token-op3|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.');
        Observer.Expect('token-op3|code', 'Conversion');
        Observer.Expect('token-op4', 'No|');
        Observer.Expect('token-op4|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.');
        Observer.Expect('token-op4|code', 'Conversion');
        Observer.Expect('token-op5', 'No|');
        Observer.Expect('token-op5|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonValue.');
        Observer.Expect('token-op5|code', 'Conversion');
        Observer.Expect('token-op6', 'No|');
        Observer.Expect('token-op6|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonValue.');
        Observer.Expect('token-op6|code', 'Conversion');
        Observer.Expect('token-op7', 'Yes|Yes');
        Observer.Expect('token-op7|text', '');
        Observer.Expect('token-op7|code', '');
        Observer.Expect('token-op8', 'No|');
        Observer.Expect('token-op8|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        Observer.Expect('token-op8|code', 'Conversion');
        Observer.Expect('token-op9', 'Yes|1');
        Observer.Expect('token-op9|text', '');
        Observer.Expect('token-op9|code', '');
        Observer.Expect('token-op10', 'Yes|12');
        Observer.Expect('token-op10|text', '');
        Observer.Expect('token-op10|code', '');
        Observer.Expect('token-op11', 'Yes|true');
        Observer.Expect('token-op11|text', '');
        Observer.Expect('token-op11|code', '');
        Observer.Verify();
    end;
}
