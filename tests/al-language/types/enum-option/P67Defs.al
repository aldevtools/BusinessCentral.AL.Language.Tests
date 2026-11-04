// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-enum-assignment-compatibility
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained enums 70190-70194, table 70190, codeunit 70199
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: P67 enum and option conversion fixtures
// BC versions: 29 (27 and 28 by CI)

enum 70190 "LT P67 Src"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; One) { }
    value(3; Three) { }
    value(7; Seven) { }
}

enum 70191 "LT P67 Dst"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; Uno) { }
    value(2; Dos) { }
    value(3; Tres) { Caption = 'Tres Cap'; }
}

enum 70192 "LT P67 Plain"
{
    Extensible = true;

    value(0; None) { }
    value(1; Uno) { }
    value(2; Dos) { }
}

enum 70193 "LT P67 Plain2"
{
    Extensible = true;

    value(0; None) { }
    value(1; Uno) { }
    value(2; Dos) { }
}

enum 70194 "LT P67 NoZero"
{
    Extensible = false;

    value(1; One) { }
    value(2; Two) { }
}

table 70190 "LT P67 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Kind; Enum "LT P67 Dst") { }
        field(3; Plain; Enum "LT P67 Plain") { }
        field(4; Opt; Option) { OptionMembers = A,B,C,D,E; }
        field(5; InitKind; Enum "LT P67 Dst") { InitValue = Dos; }
        field(6; Info; Text[30]) { }
        field(7; Zero; Enum "LT P67 NoZero") { }
    }

    keys
    {
        key(PK; Code, Kind) { Clustered = true; }
    }
}

codeunit 70199 "LT P67 Helper"
{
    procedure TakeDst(D: Enum "LT P67 Dst"): Text
    begin
        exit(Format(D) + '|' + Format(D.AsInteger()));
    end;

    procedure SrcToDst(S: Enum "LT P67 Src"): Enum "LT P67 Dst"
    begin
        exit(S);
    end;

    procedure SrcToDstVarLocal(S: Enum "LT P67 Src"): Text
    var
        D: Enum "LT P67 Dst";
    begin
        D := S;
        exit(Format(D) + '|' + Format(D.AsInteger()));
    end;

    procedure BumpDst(var D: Enum "LT P67 Dst")
    begin
        D := D::Dos;
    end;

    procedure OutDst(var D: Enum "LT P67 Dst"; S: Enum "LT P67 Src")
    begin
        D := S;
    end;

    procedure TakeInt(I: Integer): Enum "LT P67 Dst"
    begin
        exit(I);
    end;
}
