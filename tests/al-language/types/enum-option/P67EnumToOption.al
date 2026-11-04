// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enums 70190-70194 and table 70190 (P67Defs.al), self-contained test codeunit 70195
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 Enum assigned to an Option variable and field
// BC versions: 29 (27 and 28 by CI)
// Added by writer BN3 (corpus #664 item 68): tables 83866, 83867 and BN3_CalcFormulaOptionAgainstEnum (CalcFormula field() between Option and Enum).

codeunit 70195 "LT P67 Enum To Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnumToOptionVariable()
    var
        Observer: Codeunit "Probe Observer";
        S: Enum "LT P67 Src";
        Opt: Option A,B,C;
        Ords: List of [Integer];
        i: Integer;
    begin
        Ords := Enum::"LT P67 Src".Ordinals();
        for i := 1 to Ords.Count() do begin
            S := Enum::"LT P67 Src".FromInteger(Ords.Get(i));
            Opt := S;
            Observer.Observe('opt' + Format(Ords.Get(i)), '[' + Format(Opt) + ']');
            Observer.Observe('opt' + Format(Ords.Get(i)) + '_n', Format(Opt, 0, 2));
            Observer.Observe('opt' + Format(Ords.Get(i)) + '_eqC', Format(Opt = Opt::C));
        end;
        Observer.Expect('opt0', '[A]');
        Observer.Expect('opt0_n', '0');
        Observer.Expect('opt0_eqC', 'No');
        Observer.Expect('opt1', '[B]');
        Observer.Expect('opt1_n', '1');
        Observer.Expect('opt1_eqC', 'No');
        Observer.Expect('opt3', '[3]');
        Observer.Expect('opt3_n', '3');
        Observer.Expect('opt3_eqC', 'No');
        Observer.Expect('opt7', '[7]');
        Observer.Expect('opt7_n', '7');
        Observer.Expect('opt7_eqC', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure EnumToOptionVariable_Other()
    var
        Observer: Codeunit "Probe Observer";
        D: Enum "LT P67 Dst";
        P: Enum "LT P67 Plain";
        Opt: Option A,B,C;
    begin
        D := D::Tres;
        Opt := D;
        Observer.Observe('dst_tres', '[' + Format(Opt) + ']');
        Observer.Observe('dst_tres_n', Format(Opt, 0, 2));
        P := P::Dos;
        Opt := P;
        Observer.Observe('plain_dos', '[' + Format(Opt) + ']');
        Observer.Observe('plain_dos_n', Format(Opt, 0, 2));
        P := P::None;
        Opt := P;
        Observer.Observe('plain_none', '[' + Format(Opt) + ']');
        Observer.Expect('dst_tres', '[3]');
        Observer.Expect('dst_tres_n', '3');
        Observer.Expect('plain_dos', '[C]');
        Observer.Expect('plain_dos_n', '2');
        Observer.Expect('plain_none', '[A]');
        Observer.Verify();
    end;

    [Test]
    procedure EnumToOptionField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        S: Enum "LT P67 Src";
    begin
        Row.DeleteAll();
        S := S::One;
        Row.Opt := S;
        Observer.Observe('one', '[' + Format(Row.Opt) + ']');
        Observer.Observe('one_n', Format(Row.Opt, 0, 2));
        S := S::Three;
        Row.Opt := S;
        Observer.Observe('three', '[' + Format(Row.Opt) + ']');
        Observer.Observe('three_n', Format(Row.Opt, 0, 2));
        S := S::Seven;
        Row.Opt := S;
        Observer.Observe('seven', '[' + Format(Row.Opt) + ']');
        Observer.Observe('seven_n', Format(Row.Opt, 0, 2));
        Row.Code := 'A';
        Row.Insert();
        Observer.Observe('insert_seven', 'no error');
        Observer.Observe('count_after', Format(Row.Count()));
        Observer.Expect('one', '[B]');
        Observer.Expect('one_n', '1');
        Observer.Expect('three', '[D]');
        Observer.Expect('three_n', '3');
        Observer.Expect('seven', '[7]');
        Observer.Expect('seven_n', '7');
        Observer.Expect('insert_seven', 'no error');
        Observer.Expect('count_after', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EnumToOptionField_Validate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P67 Row";
        S: Enum "LT P67 Src";
    begin
        Row.DeleteAll();
        S := S::Seven;
        Row.Validate(Opt, S);
        Observer.Observe('validate_seven', 'no error');
        S := S::Three;
        Row.Validate(Opt, S);
        Observer.Observe('validate_three', Format(Row.Opt, 0, 2));
        Observer.Expect('validate_seven', 'no error');
        Observer.Expect('validate_three', '3');
        Observer.Verify();
    end;

    // Corpus #664 item 68: CalcFields of count() FlowFields that filter an Option source field by an Enum field and an Enum source field by an
    // Option field (the compiler gives warning AL0603 for both).
    [Test]
    procedure BN3_CalcFormulaOptionAgainstEnum()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT BN3 CF Src";
        Hdr: Record "LT BN3 CF Hdr";
    begin
        Src.DeleteAll();
        Hdr.DeleteAll();
        Src.Id := 1;
        Src.Opt := Src.Opt::B;
        Src.Kind := Enum::"LT P67 Dst"::Dos;
        Src.Insert();
        Src.Id := 2;
        Src.Opt := Src.Opt::B;
        Src.Kind := Enum::"LT P67 Dst"::Uno;
        Src.Insert();
        Src.Id := 3;
        Src.Opt := Src.Opt::D;
        Src.Kind := Enum::"LT P67 Dst"::Uno;
        Src.Insert();
        Hdr.Code := 'H';
        Hdr.Kind := Enum::"LT P67 Dst"::Uno;
        Hdr.Opt := Hdr.Opt::B;
        Hdr.Insert();
        Hdr.CalcFields(OptByEnum, EnumByOpt);
        Observer.Observe('Kind Uno / Opt B', Format(Hdr.OptByEnum) + '|' + Format(Hdr.EnumByOpt));
        Hdr.Kind := Enum::"LT P67 Dst"::Tres;
        Hdr.Opt := Hdr.Opt::C;
        Hdr.Modify();
        Hdr.CalcFields(OptByEnum, EnumByOpt);
        Observer.Observe('Kind Tres / Opt C', Format(Hdr.OptByEnum) + '|' + Format(Hdr.EnumByOpt));
        Hdr.Kind := Enum::"LT P67 Dst"::Dos;
        Hdr.Opt := Hdr.Opt::A;
        Hdr.Modify();
        Hdr.CalcFields(OptByEnum, EnumByOpt);
        Observer.Observe('Kind Dos / Opt A', Format(Hdr.OptByEnum) + '|' + Format(Hdr.EnumByOpt));
        Observer.Expect('Kind Uno / Opt B', '2|2');
        Observer.Expect('Kind Tres / Opt C', '1|1');
        Observer.Expect('Kind Dos / Opt A', '0|0');
        Observer.Verify();
    end;
}

// Corpus #664 item 68 (microsoft/AL issue 7613): CalcFormula count() whose where(... = field(...)) pairs an Option field with an Enum field.
// The option members (A,B,C,D) share no names with the enum values (None,Uno,Dos,Tres), so a match by name would find nothing.
table 83866 "LT BN3 CF Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = A,B,C,D; }
        field(3; Kind; Enum "LT P67 Dst") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 83867 "LT BN3 CF Hdr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Kind; Enum "LT P67 Dst") { }
        field(3; Opt; Option) { OptionMembers = A,B,C,D; }
        field(4; OptByEnum; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BN3 CF Src" where(Opt = field(Kind)));
        }
        field(5; EnumByOpt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BN3 CF Src" where(Kind = field(Opt)));
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}
