// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 70190-70194 and table 70190 (P67Defs.al), self-contained test codeunit 70201
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 Clear of an enum variable and of an enum field
// BC versions: 29 (27 and 28 by CI)

codeunit 70201 "LT P67 Enum Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClearEnumVariable()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
        S: Enum "LT P67 Src";
    begin
        D := D::Dos;
        Clear(D);
        Observer.Observe('dst', '[' + Format(D) + ']|' + Format(D.AsInteger()));
        S := S::Seven;
        Clear(S);
        Observer.Observe('src', '[' + Format(S) + ']|' + Format(S.AsInteger()));
        D := D::None;
        Clear(D);
        Observer.Observe('dst_none', '[' + Format(D) + ']|' + Format(D.AsInteger()));
        Observer.Expect('dst', '[None]|0');
        Observer.Expect('src', '[None]|0');
        Observer.Expect('dst_none', '[None]|0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearEnumWithoutZeroOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        Z: Enum "LT P67 NoZero";
        Z2: Enum "LT P67 NoZero";
    begin
        Observer.Observe('default', '[' + Format(Z) + ']|' + Format(Z.AsInteger()));
        Z := Z::Two;
        Observer.Observe('two', Format(Z));
        Clear(Z);
        Observer.Observe('cleared', '[' + Format(Z) + ']|' + Format(Z.AsInteger()));
        Observer.Observe('eq_default', Format(Z = Z2));
        Observer.Observe('eq_one', Format(Z = Z::One));
        Observer.Expect('default', '[0]|0');
        Observer.Expect('two', 'Two');
        Observer.Expect('cleared', '[0]|0');
        Observer.Expect('eq_default', 'Yes');
        Observer.Expect('eq_one', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ClearEnumField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
    begin
        Row.Kind := Row.Kind::Tres;
        Row.Plain := Row.Plain::Dos;
        Row.Zero := Row.Zero::Two;
        Row.Opt := Row.Opt::D;
        Clear(Row.Kind);
        Clear(Row.Plain);
        Clear(Row.Zero);
        Clear(Row.Opt);
        Observer.Observe('kind', '[' + Format(Row.Kind) + ']|' + Format(Row.Kind.AsInteger()));
        Observer.Observe('plain', '[' + Format(Row.Plain) + ']|' + Format(Row.Plain.AsInteger()));
        Observer.Observe('zero', '[' + Format(Row.Zero) + ']|' + Format(Row.Zero.AsInteger()));
        Observer.Observe('opt', '[' + Format(Row.Opt) + ']|' + Format(Row.Opt, 0, 2));
        Observer.Expect('kind', '[None]|0');
        Observer.Expect('plain', '[None]|0');
        Observer.Expect('zero', '[0]|0');
        Observer.Expect('opt', '[A]|0');
        Observer.Verify();
    end;

    [Test]
    procedure ClearEnumFieldWithInitValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
    begin
        Observer.Observe('fresh', Format(Row.InitKind));
        Row.InitKind := Row.InitKind::Tres;
        Clear(Row.InitKind);
        Observer.Observe('clear_field', '[' + Format(Row.InitKind) + ']|' + Format(Row.InitKind.AsInteger()));
        Row.InitKind := Row.InitKind::Tres;
        Row.Init();
        Observer.Observe('init', Format(Row.InitKind));
        Row.InitKind := Row.InitKind::Tres;
        Row.Kind := Row.Kind::Tres;
        Clear(Row);
        Observer.Observe('clear_rec_initkind', '[' + Format(Row.InitKind) + ']');
        Observer.Observe('clear_rec_kind', '[' + Format(Row.Kind) + ']');
        Observer.Expect('fresh', 'Dos');
        Observer.Expect('clear_field', '[None]|0');
        Observer.Expect('init', 'Dos');
        Observer.Expect('clear_rec_initkind', '[Dos]');
        Observer.Expect('clear_rec_kind', '[None]');
        Observer.Verify();
    end;

    [Test]
    procedure ClearRecordWithEnumFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
    begin
        Row.Code := 'X';
        Row.Plain := Row.Plain::Dos;
        Row.Zero := Row.Zero::Two;
        Row.Opt := Row.Opt::E;
        Clear(Row);
        Observer.Observe('code', '[' + Format(Row.Code) + ']');
        Observer.Observe('plain', '[' + Format(Row.Plain) + ']');
        Observer.Observe('zero', '[' + Format(Row.Zero) + ']|' + Format(Row.Zero.AsInteger()));
        Observer.Observe('opt', '[' + Format(Row.Opt) + ']');
        Observer.Expect('code', '[]');
        Observer.Expect('plain', '[None]');
        Observer.Expect('zero', '[0]|0');
        Observer.Expect('opt', '[A]');
        Observer.Verify();
    end;

    [Test]
    procedure ClearEnumInstanceAfterFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.Kind := Row.Kind::Uno;
        Row.Insert();
        Row.SetRange(Kind, Row.Kind::Uno);
        Observer.Observe('filter', Row.GetFilter(Kind));
        Clear(Row);
        Observer.Observe('filter_cleared', '[' + Row.GetFilter(Kind) + ']');
        Observer.Observe('count_all', Format(Row.Count()));
        Observer.Expect('filter', 'Uno');
        Observer.Expect('filter_cleared', '[]');
        Observer.Expect('count_all', '1');
        Observer.Verify();
    end;
}
