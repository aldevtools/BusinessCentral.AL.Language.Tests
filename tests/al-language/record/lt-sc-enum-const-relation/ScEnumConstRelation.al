// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 91240, tables 91241 to 91243 and test codeunit 91244
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: a field with a conditional TableRelation whose conditions compare enum fields with an enum-qualified const,
//   TableRelation = if (Standard = const("LT SC Std"::A)) "LT SC Rel A".Code else if (Kind = const("LT SC Std"::B)) "LT SC Rel B".Code.
//   Validate of a value that is and is not in the table of the branch that applies, a row for which no branch applies, a change of the condition field
//   after the value was set, Insert of a value the relation would reject, and the rows of Table Relations Metadata that describe the two branches.
// BC versions: 27, 28, 29
enum 91240 "LT SC Std"
{
    Extensible = true;

    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
}

table 91241 "LT SC Rel A"
{
    fields
    {
        field(1; Code; Code[20]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 91242 "LT SC Rel B"
{
    fields
    {
        field(1; Code; Code[20]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 91243 "LT SC Rel Host"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Standard; Enum "LT SC Std") { }
        field(3; Kind; Enum "LT SC Std") { }
        field(4; Bic; Text[50])
        {
            TableRelation = if (Standard = const("LT SC Std"::A)) "LT SC Rel A".Code
            else if (Kind = const("LT SC Std"::B)) "LT SC Rel B".Code;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 91244 "LT SC Enum Const Relation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        RelA: Record "LT SC Rel A";
        RelB: Record "LT SC Rel B";
        Host: Record "LT SC Rel Host";
    begin
        RelA.DeleteAll();
        RelB.DeleteAll();
        Host.DeleteAll();
        RelA.Code := 'AA';
        RelA.Insert();
        RelB.Code := 'BB';
        RelB.Insert();
    end;

    [TryFunction]
    local procedure DoValidate(Standard: Enum "LT SC Std"; Kind: Enum "LT SC Std"; Value: Text)
    var
        Host: Record "LT SC Rel Host";
    begin
        Host.Init();
        Host.Standard := Standard;
        Host.Kind := Kind;
        Host.Validate(Bic, CopyStr(Value, 1, 50));
    end;

    local procedure TryValidate(var Observer: Codeunit "Probe Observer"; Name: Text; Standard: Enum "LT SC Std"; Kind: Enum "LT SC Std"; Value: Text)
    begin
        if DoValidate(Standard, Kind, Value) then
            Observer.Observe(Name, 'accepted')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure Validate_FirstBranch_StandardIsA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        TryValidate(Observer, 'std A, AA', "LT SC Std"::A, "LT SC Std"::A, 'AA');
        TryValidate(Observer, 'std A, BB', "LT SC Std"::A, "LT SC Std"::A, 'BB');
        TryValidate(Observer, 'std A kind B, BB (first branch wins)', "LT SC Std"::A, "LT SC Std"::B, 'BB');
        TryValidate(Observer, 'std A kind B, AA', "LT SC Std"::A, "LT SC Std"::B, 'AA');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_SecondBranch_StandardNotA_KindIsB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        TryValidate(Observer, 'std B kind B, BB', "LT SC Std"::B, "LT SC Std"::B, 'BB');
        TryValidate(Observer, 'std B kind B, AA', "LT SC Std"::B, "LT SC Std"::B, 'AA');
        TryValidate(Observer, 'std C kind B, BB', "LT SC Std"::C, "LT SC Std"::B, 'BB');
        TryValidate(Observer, 'std C kind B, ZZ', "LT SC Std"::C, "LT SC Std"::B, 'ZZ');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_NoBranchApplies()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        TryValidate(Observer, 'std B kind A, ZZ', "LT SC Std"::B, "LT SC Std"::A, 'ZZ');
        TryValidate(Observer, 'std C kind C, ZZ', "LT SC Std"::C, "LT SC Std"::C, 'ZZ');
        TryValidate(Observer, 'std B kind A, empty', "LT SC Std"::B, "LT SC Std"::A, '');
        TryValidate(Observer, 'std A, empty', "LT SC Std"::A, "LT SC Std"::A, '');
        Observer.Finish();
    end;

    [Test]
    procedure ChangeConditionAfterValue_InsertInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Host: Record "LT SC Rel Host";
    begin
        Seed();
        Host.Init();
        Host.Id := 1;
        Host.Standard := "LT SC Std"::A;
        Host.Validate(Bic, 'AA');
        Host.Validate(Standard, "LT SC Std"::B);
        Observer.Observe('bic kept after standard change', Host.Bic);
        Host.Kind := "LT SC Std"::B;
        asserterror Host.Validate(Bic, 'AA');
        Observer.ObserveError('now AA under second branch');
        Host.Bic := 'NOWHERE';
        Observer.Observe('insert invalid', Format(Host.Insert(true)));
        Observer.Observe('stored', Host.Bic);
        Observer.Finish();
    end;

    [Test]
    procedure TableRelationsMetadata_TwoEnumConditions()
    var
        Observer: Codeunit "Probe Observer";
        Rel: Record "Table Relations Metadata";
        Result: Text;
    begin
        Rel.SetRange("Table ID", Database::"LT SC Rel Host");
        Rel.SetRange("Field No.", 4);
        Result := 'rows=' + Format(Rel.Count()) + ' ';
        if Rel.FindSet() then
            repeat
                Result += StrSubstNo('[%1.%2 condfield %3 %4 "%5"] ', Rel."Related Table ID", Rel."Related Field No.", Rel."Condition Field No.", Rel."Condition Type", Rel."Condition Value");
            until Rel.Next() = 0;
        Observer.Observe('relations', Result);
        Observer.Finish();
    end;
}
