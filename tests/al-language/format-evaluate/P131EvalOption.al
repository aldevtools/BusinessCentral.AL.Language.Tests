// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73647 and codeunit 73627
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate into an Option table field whose OptionCaption differs from its OptionMembers (member names, captions, ordinals, out of
//        range ordinals, a blank first member) and into an Option variable at its last ordinal; what the variable holds after a failure.
// BC versions: 29 (27 and 28 by CI)

table 73647 "LT P131 Opt Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = " ",Alpha,Beta,Gamma;
            OptionCaption = ' ,Alpha cap,Beta cap,Gamma cap';
        }
        field(3; Opt2; Option)
        {
            OptionMembers = A,B,C;
            OptionCaption = 'One,Two,Three';
        }
        field(4; Opt3; Option)
        {
            OptionMembers = " ",Open,Closed;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73627 "LT P131 Eval Opt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure E1(Txt: Text): Text
    var
        R: Record "LT P131 Opt Rec";
        Ok: Boolean;
        Ord: Integer;
    begin
        R.Opt := R.Opt::Gamma;
        Ok := Evaluate(R.Opt, Txt);
        Ord := R.Opt;
        exit(Format(Ok) + '|' + Format(Ord) + '|' + Format(R.Opt));
    end;

    local procedure E2(Txt: Text): Text
    var
        R: Record "LT P131 Opt Rec";
        Ok: Boolean;
        Ord: Integer;
    begin
        R.Opt2 := R.Opt2::C;
        Ok := Evaluate(R.Opt2, Txt);
        Ord := R.Opt2;
        exit(Format(Ok) + '|' + Format(Ord) + '|' + Format(R.Opt2));
    end;

    local procedure E3(Txt: Text): Text
    var
        R: Record "LT P131 Opt Rec";
        Ok: Boolean;
        Ord: Integer;
    begin
        R.Opt3 := R.Opt3::Closed;
        Ok := Evaluate(R.Opt3, Txt);
        Ord := R.Opt3;
        exit(Format(Ok) + '|' + Format(Ord) + '|' + Format(R.Opt3));
    end;

    [Test]
    procedure P131_EvaluateOption_FieldWithCaptions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Alpha', E1('Alpha'));
        Observer.Observe('alpha', E1('alpha'));
        Observer.Observe('Alpha cap', E1('Alpha cap'));
        Observer.Observe('alpha cap', E1('alpha cap'));
        Observer.Observe('Gamma cap', E1('Gamma cap'));
        Observer.Observe('0', E1('0'));
        Observer.Observe('1', E1('1'));
        Observer.Observe('3', E1('3'));
        Observer.Observe('4', E1('4'));
        Observer.Observe('-1', E1('-1'));
        Observer.Observe('empty', E1(''));
        Observer.Observe('space', E1(' '));
        Observer.Observe('padded 2', E1(' 2 '));
        Observer.Observe('1.0', E1('1.0'));
        Observer.Observe('+1', E1('+1'));
        Observer.Observe('two members', E1('Beta,Gamma'));
        Observer.Expect('Alpha', 'Yes|1|Alpha cap');
        Observer.Expect('alpha', 'Yes|1|Alpha cap');
        Observer.Expect('Alpha cap', 'Yes|1|Alpha cap');
        Observer.Expect('alpha cap', 'Yes|1|Alpha cap');
        Observer.Expect('Gamma cap', 'Yes|3|Gamma cap');
        Observer.Expect('0', 'Yes|0| ');
        Observer.Expect('1', 'Yes|1|Alpha cap');
        Observer.Expect('3', 'Yes|3|Gamma cap');
        Observer.Expect('4', 'Yes|4|4');
        Observer.Expect('-1', 'No|3|Gamma cap');
        Observer.Expect('empty', 'Yes|0| ');
        Observer.Expect('space', 'Yes|0| ');
        Observer.Expect('padded 2', 'Yes|2|Beta cap');
        Observer.Expect('1.0', 'No|3|Gamma cap');
        Observer.Expect('+1', 'Yes|1|Alpha cap');
        Observer.Expect('two members', 'No|3|Gamma cap');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateOption_FieldCaptionsDifferentWords()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('A', E2('A'));
        Observer.Observe('B', E2('B'));
        Observer.Observe('b', E2('b'));
        Observer.Observe('One', E2('One'));
        Observer.Observe('Two', E2('Two'));
        Observer.Observe('two', E2('two'));
        Observer.Observe('Three', E2('Three'));
        Observer.Observe('0', E2('0'));
        Observer.Observe('1', E2('1'));
        Observer.Observe('2', E2('2'));
        Observer.Observe('3', E2('3'));
        Observer.Observe('C padded', E2('C '));
        Observer.Observe('empty', E2(''));
        Observer.Expect('A', 'Yes|0|One');
        Observer.Expect('B', 'Yes|1|Two');
        Observer.Expect('b', 'Yes|1|Two');
        Observer.Expect('One', 'Yes|0|One');
        Observer.Expect('Two', 'Yes|1|Two');
        Observer.Expect('two', 'Yes|1|Two');
        Observer.Expect('Three', 'Yes|2|Three');
        Observer.Expect('0', 'Yes|0|One');
        Observer.Expect('1', 'Yes|1|Two');
        Observer.Expect('2', 'Yes|2|Three');
        Observer.Expect('3', 'Yes|3|3');
        Observer.Expect('C padded', 'Yes|2|Three');
        Observer.Expect('empty', 'No|2|Three');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateOption_BlankFirstMemberNoCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Open', E3('Open'));
        Observer.Observe('Closed', E3('Closed'));
        Observer.Observe('0', E3('0'));
        Observer.Observe('1', E3('1'));
        Observer.Observe('2', E3('2'));
        Observer.Observe('3', E3('3'));
        Observer.Observe('empty', E3(''));
        Observer.Observe('space', E3(' '));
        Observer.Expect('Open', 'Yes|1|Open');
        Observer.Expect('Closed', 'Yes|2|Closed');
        Observer.Expect('0', 'Yes|0| ');
        Observer.Expect('1', 'Yes|1|Open');
        Observer.Expect('2', 'Yes|2|Closed');
        Observer.Expect('3', 'Yes|3|3');
        Observer.Expect('empty', 'Yes|0| ');
        Observer.Expect('space', 'Yes|0| ');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateOption_VariableLastOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        V: Option A,B,C,D;
        Ok: Boolean;
        Ord: Integer;
    begin
        V := V::A;
        Ok := Evaluate(V, '3');
        Ord := V;
        Observer.Observe('3', Format(Ok) + '|' + Format(Ord) + '|' + Format(V));
        V := V::A;
        Ok := Evaluate(V, '4');
        Ord := V;
        Observer.Observe('4', Format(Ok) + '|' + Format(Ord) + '|' + Format(V));
        V := V::A;
        Ok := Evaluate(V, 'D');
        Ord := V;
        Observer.Observe('D', Format(Ok) + '|' + Format(Ord) + '|' + Format(V));
        V := V::A;
        Ok := Evaluate(V, '-1');
        Ord := V;
        Observer.Observe('-1', Format(Ok) + '|' + Format(Ord) + '|' + Format(V));
        V := V::B;
        Ok := Evaluate(V, 'x');
        Ord := V;
        Observer.Observe('x keeps', Format(Ok) + '|' + Format(Ord) + '|' + Format(V));
        V := V::B;
        Ok := Evaluate(V, '');
        Ord := V;
        Observer.Observe('empty keeps', Format(Ok) + '|' + Format(Ord) + '|' + Format(V));
        Observer.Expect('3', 'Yes|3|D');
        Observer.Expect('4', 'Yes|4|4');
        Observer.Expect('D', 'Yes|3|D');
        Observer.Expect('-1', 'No|0|A');
        Observer.Expect('x keeps', 'No|1|B');
        Observer.Expect('empty keeps', 'No|1|B');
        Observer.Verify();
    end;
}
