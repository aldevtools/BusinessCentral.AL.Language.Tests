// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// TransferFields between an Enum field and an Option field of the same field number, both directions, with an ordinal the target lacks.
// BC versions: 29 (27 and 28 by CI)

enum 70334 "LT P98 Kind"
{
    Extensible = true;
    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
    value(9; Nine) { }
}

table 70330 "LT P98 EnumRow"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Kind; Enum "LT P98 Kind") { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 70331 "LT P98 OptRow"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Kind; Option) { OptionMembers = " ",O1,O2,O3,O4; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 70332 "LT P98 OptSmallRow"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Kind; Option) { OptionMembers = X0,X1,X2; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70335 "LT P98 TransferEnumOpt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_OptionToEnum_Present()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT P98 EnumRow";
        O: Record "LT P98 OptRow";
    begin
        O.Id := 'K1';
        O.Kind := O.Kind::O2;
        E.TransferFields(O);
        Observer.Observe('id', E.Id);
        Observer.Observe('kind', Format(E.Kind));
        Observer.Observe('ord', Format(E.Kind.AsInteger()));
        O.Kind := O.Kind::" ";
        E.TransferFields(O);
        Observer.Observe('zero', Format(E.Kind));
        O.Kind := O.Kind::O1;
        E.TransferFields(O, false);
        Observer.Observe('noinit', Format(E.Kind) + '|' + E.Id);
        Observer.Expect('id', 'K1');
        Observer.Expect('kind', 'C');
        Observer.Expect('ord', '2');
        Observer.Expect('zero', 'A');
        Observer.Expect('noinit', 'B|K1');
        Observer.Verify();
    end;

    [Test]
    procedure P98_OptionToEnum_MissingOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT P98 EnumRow";
        O: Record "LT P98 OptRow";
    begin
        O.Id := 'K2';
        O.Kind := O.Kind::O3;
        E.TransferFields(O);
        Observer.Observe('o3', 'no error');
        Observer.Observe('after3', Format(E.Kind.AsInteger()) + '|' + E.Id);
        O.Kind := O.Kind::O4;
        E.TransferFields(O);
        Observer.Observe('o4', 'no error');
        Observer.Observe('after4', Format(E.Kind.AsInteger()) + '|' + E.Id);
        E.TransferFields(O, false);
        Observer.Observe('o4noinit', 'no error');
        Observer.Expect('o3', 'no error');
        Observer.Expect('after3', '3|K2');
        Observer.Expect('o4', 'no error');
        Observer.Expect('after4', '4|K2');
        Observer.Expect('o4noinit', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure P98_EnumToOption_Present()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT P98 EnumRow";
        O: Record "LT P98 OptRow";
    begin
        E.Id := 'K3';
        E.Kind := E.Kind::B;
        O.TransferFields(E);
        Observer.Observe('id', O.Id);
        Observer.Observe('kind', Format(O.Kind));
        Observer.Observe('kind9', Format(O.Kind, 0, 9));
        E.Kind := E.Kind::C;
        O.TransferFields(E);
        Observer.Observe('c', Format(O.Kind));
        E.Kind := E.Kind::A;
        O.TransferFields(E);
        Observer.Observe('a', '[' + Format(O.Kind) + ']');
        Observer.Expect('id', 'K3');
        Observer.Expect('kind', 'O1');
        Observer.Expect('kind9', '1');
        Observer.Expect('c', 'O2');
        Observer.Expect('a', '[ ]');
        Observer.Verify();
    end;

    [Test]
    procedure P98_EnumToOption_MissingOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT P98 EnumRow";
        O: Record "LT P98 OptRow";
    begin
        E.Id := 'K4';
        E.Kind := E.Kind::Nine;
        O.TransferFields(E);
        Observer.Observe('nine', 'no error');
        Observer.Observe('afterNine', Format(O.Kind, 0, 9) + '|' + O.Id);
        Observer.Expect('nine', 'no error');
        Observer.Expect('afterNine', '9|K4');
        Observer.Verify();
    end;

    [Test]
    procedure P98_EnumToSmallOption_Boundary()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT P98 EnumRow";
        S: Record "LT P98 OptSmallRow";
    begin
        E.Id := 'K5';
        E.Kind := E.Kind::C;
        S.TransferFields(E);
        Observer.Observe('c', Format(S.Kind));
        E.Kind := E.Kind::Nine;
        S.TransferFields(E);
        Observer.Observe('nine', 'no error');
        Observer.Observe('afterNine', Format(S.Kind, 0, 9));
        Observer.Expect('c', 'X2');
        Observer.Expect('nine', 'no error');
        Observer.Expect('afterNine', '9');
        Observer.Verify();
    end;

    [Test]
    procedure P98_SmallOptionToEnum_ThenBack()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT P98 EnumRow";
        S: Record "LT P98 OptSmallRow";
        O: Record "LT P98 OptRow";
    begin
        S.Id := 'K6';
        S.Kind := S.Kind::X2;
        E.TransferFields(S);
        Observer.Observe('enum', Format(E.Kind));
        O.TransferFields(E);
        Observer.Observe('opt', Format(O.Kind, 0, 9));
        Observer.Expect('enum', 'C');
        Observer.Expect('opt', '2');
        Observer.Verify();
    end;
}
