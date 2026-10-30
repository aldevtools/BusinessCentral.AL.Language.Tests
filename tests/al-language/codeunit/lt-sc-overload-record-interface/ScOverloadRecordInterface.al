// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own interface 91270, enum 91271, table 91272, codeunits 91273 / 91274 and test codeunit 91275
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: which overload BC calls when one procedure name has a variant with a var Record parameter and a variant with an Interface parameter (same second
//   parameter, a JsonObject), and the argument is an enum that implements the interface, an interface variable, a codeunit variable that implements it, or a
//   record variable. Interface overloads among themselves are pinned in codeunit/lt-enums-interfaces/OjT71060.al.
// BC versions: 27, 28, 29
interface "LT SC Importer"
{
    procedure Name(): Text;
}

enum 91271 "LT SC Importer Kind" implements "LT SC Importer"
{
    Extensible = false;
    DefaultImplementation = "LT SC Importer" = "LT SC Importer Impl";

    value(0; Plain) { }
    value(1; Special) { Implementation = "LT SC Importer" = "LT SC Importer Special"; }
}

table 91272 "LT SC Importer Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 91273 "LT SC Importer Impl" implements "LT SC Importer"
{
    procedure Name(): Text
    begin
        exit('impl');
    end;
}

codeunit 91274 "LT SC Importer Special" implements "LT SC Importer"
{
    procedure Name(): Text
    begin
        exit('special');
    end;

    procedure Get(var Rec: Record "LT SC Importer Row"; J: JsonObject): Text
    begin
        exit('record overload');
    end;

    local procedure Get(I: Interface "LT SC Importer"; J: JsonObject): Text
    begin
        exit('interface overload ' + I.Name());
    end;

    procedure ByEnum(E: Enum "LT SC Importer Kind"; J: JsonObject): Text
    begin
        exit(Get(E, J));
    end;

    procedure ByInterface(I: Interface "LT SC Importer"; J: JsonObject): Text
    begin
        exit(Get(I, J));
    end;

    procedure ByCodeunit(var C: Codeunit "LT SC Importer Impl"; J: JsonObject): Text
    begin
        exit(Get(C, J));
    end;

    procedure ByRecord(var Row: Record "LT SC Importer Row"; J: JsonObject): Text
    begin
        exit(Get(Row, J));
    end;
}

codeunit 91275 "LT SC Overload Record Interface"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RecordVersusInterface_ArgumentKinds()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT SC Importer Special";
        Impl: Codeunit "LT SC Importer Impl";
        Row: Record "LT SC Importer Row";
        Kind: Enum "LT SC Importer Kind";
        I: Interface "LT SC Importer";
        J: JsonObject;
    begin
        Observer.Observe('enum plain', Host.ByEnum(Kind::Plain, J));
        Observer.Observe('enum special', Host.ByEnum(Kind::Special, J));
        I := Impl;
        Observer.Observe('interface variable', Host.ByInterface(I, J));
        Observer.Observe('codeunit variable', Host.ByCodeunit(Impl, J));
        Observer.Observe('record variable', Host.ByRecord(Row, J));
        Observer.Finish();
    end;
}
