// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72611, enums 72612-72614, table 72615
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "NP Retail blockers - An Enum of another type, and an Integer, into an Enum" (an argument and an `exit` value, `=` and `<`
// between enum types, BigInteger into an Enum, Get keyed by an enum of another type or an Integer and its not-found error)
// Facts: enum conversions through arguments and exit values, comparison between enums, BigInteger, Get/GetLastErrorText for keys of another enum type
// BC versions: 29 (27 and 28 by CI)

enum 72612 "LT PnE Src Enum"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
    value(7; Seven) { }
    value(9; Nine) { }
}

enum 72613 "LT PnE Dst Enum"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; Uno) { }
    value(2; Dos) { }
    value(9; Nueve) { }
}

enum 72614 "LT PnE Plain Enum"
{
    Extensible = true;

    value(0; None) { }
    value(1; Uno) { }
    value(2; Dos) { }
}

table 72615 "LT PnE Enum Row"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Kind; Enum "LT PnE Dst Enum") { }
        field(3; Info; Text[30]) { }
    }
    keys
    {
        key(PK; Code, Kind) { Clustered = true; }
    }
}

codeunit 72611 "LT PnE Enum Convert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakeDst(D: Enum "LT PnE Dst Enum"): Text
    begin
        exit(Format(D) + '|' + Format(D.AsInteger()));
    end;

    local procedure ReturnDst(S: Enum "LT PnE Src Enum"): Enum "LT PnE Dst Enum"
    begin
        exit(S);
    end;

    local procedure TakeDstFromInt(I: Integer): Text
    begin
        exit(TakeDst(I));
    end;

    local procedure ReturnDstFromInt(I: Integer): Enum "LT PnE Dst Enum"
    begin
        exit(I);
    end;

    [Test]
    procedure Argument_And_Exit_TakeTheOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        S: Enum "LT PnE Src Enum";
        D: Enum "LT PnE Dst Enum";
    begin
        S := S::One;
        Observer.Observe('argDeclared', TakeDst(S));
        Observer.Observe('exitDeclared', Format(ReturnDst(S)) + '|' + Format(ReturnDst(S).AsInteger()));
        S := S::Seven;
        Observer.Observe('argLacking', TakeDst(S));
        Observer.Observe('exitLacking', Format(ReturnDst(S)) + '|' + Format(ReturnDst(S).AsInteger()));
        D := ReturnDst(S);
        Observer.Observe('assignedFromExit', Format(D.AsInteger()));
        Observer.Observe('intArgDeclared', TakeDstFromInt(2));
        Observer.Observe('intArgLacking', TakeDstFromInt(5));
        D := ReturnDstFromInt(9);
        Observer.Observe('intExitDeclared', Format(D) + '|' + Format(D.AsInteger()));
        D := ReturnDstFromInt(5);
        Observer.Observe('intExitLacking', Format(D) + '|' + Format(D.AsInteger()));
        Observer.Expect('argDeclared', 'Uno|1');
        Observer.Expect('exitDeclared', 'Uno|1');
        Observer.Expect('argLacking', '7|7');
        Observer.Expect('exitLacking', '7|7');
        Observer.Expect('assignedFromExit', '7');
        Observer.Expect('intArgDeclared', 'Dos|2');
        Observer.Expect('intArgLacking', '5|5');
        Observer.Expect('intExitDeclared', 'Nueve|9');
        Observer.Expect('intExitLacking', '5|5');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_EnumsOfDifferentTypes()
    var
        Observer: Codeunit "Probe Observer";
        S: Enum "LT PnE Src Enum";
        D: Enum "LT PnE Dst Enum";
    begin
        S := S::One;
        D := D::Uno;
        Observer.Observe('oneEqualsUno', Format(D = S));
        S := S::Seven;
        Observer.Observe('sevenEqualsUno', Format(D = S));
        Observer.Observe('unoLessThanSeven', Format(D < S));
        Observer.Observe('unoGreaterThanSeven', Format(D > S));
        Observer.Observe('unoNotEqualSeven', Format(D <> S));
        S := S::Nine;
        D := D::Nueve;
        Observer.Observe('nineEqualsNueve', Format(S = D));
        Observer.Expect('oneEqualsUno', 'Yes');
        Observer.Expect('sevenEqualsUno', 'No');
        Observer.Expect('unoLessThanSeven', 'Yes');
        Observer.Expect('unoGreaterThanSeven', 'No');
        Observer.Expect('unoNotEqualSeven', 'Yes');
        Observer.Expect('nineEqualsNueve', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Compare_NeitherCompatible()
    var
        Observer: Codeunit "Probe Observer";
        P: Enum "LT PnE Plain Enum";
        Other: Enum "LT PnE Src Enum";
    begin
        Other := Other::One;
        P := P::Uno;
        Observer.Observe('plainEqualsSrc', Format(P = Other));
        Observer.Observe('plainLessSrc', Format(P < Other));
        Other := Other::Seven;
        Observer.Observe('plainLessSeven', Format(P < Other));
        Observer.Expect('plainEqualsSrc', 'Yes');
        Observer.Expect('plainLessSrc', 'No');
        Observer.Expect('plainLessSeven', 'Yes');
        Observer.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure BigInteger_IntoEnum()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT PnE Dst Enum";
        B: BigInteger;
    begin
        B := 2;
        D := B;
        Observer.Observe('declared', Format(D) + '|' + Format(D.AsInteger()));
        B := 5;
        D := B;
        Observer.Observe('lacking', Format(D) + '|' + Format(D.AsInteger()));
        Observer.Expect('declared', 'Dos|2');
        Observer.Expect('lacking', '5|5');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Get_KeyedByAnotherEnumOrInteger_NotFound()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnE Enum Row";
        S: Enum "LT PnE Src Enum";
        I: Integer;
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Uno;
        Row.Insert();
        S := S::One;
        Observer.Observe('getDeclared', Format(Row.Get('A', S)));
        S := S::Seven;
        asserterror Row.Get('A', S);
        Observer.ObserveError('getLackingEnum');
        S := S::Nine;
        asserterror Row.Get('A', S);
        Observer.ObserveError('getDeclaredButAbsentEnum');
        I := 1;
        Observer.Observe('getIntDeclared', Format(Row.Get('A', I)));
        I := 2;
        asserterror Row.Get('A', I);
        Observer.ObserveError('getIntDeclaredButAbsent');
        I := 5;
        asserterror Row.Get('A', I);
        Observer.ObserveError('getIntLacking');
        Row.DeleteAll();
        Observer.Expect('getDeclared', 'Yes');
        Observer.Expect('getLackingEnum|text', 'The LT PnE Enum Row does not exist. Identification fields and values: Code=''A'',Kind=''Seven''');
        Observer.Expect('getLackingEnum|code', 'DB:RecordNotFound');
        Observer.Expect('getDeclaredButAbsentEnum|text', 'The LT PnE Enum Row does not exist. Identification fields and values: Code=''A'',Kind=''Nine''');
        Observer.Expect('getDeclaredButAbsentEnum|code', 'DB:RecordNotFound');
        Observer.Expect('getIntDeclared', 'No');
        Observer.Expect('getIntDeclaredButAbsent|text', 'The LT PnE Enum Row does not exist. Identification fields and values: Code=''A'',Kind=''Dos''');
        Observer.Expect('getIntDeclaredButAbsent|code', 'DB:RecordNotFound');
        Observer.Expect('getIntLacking|text', 'The LT PnE Enum Row does not exist. Identification fields and values: Code=''A'',Kind=''5''');
        Observer.Expect('getIntLacking|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}
