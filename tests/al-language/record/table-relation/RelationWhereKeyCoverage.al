// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 66340 to 66342, test codeunit 66344
// local object: the TableRelation definitions and the primary keys of the related tables are what the tests measure.
// Probe (al-runner issue 7438: a failed Validate of Sales Line "Variant Code", whose relation is
//   `if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false))`): observation form, the values
//   are read from the corpus CI matrix.
// Area: the error code and text of a failed TableRelation check, by how the where() conditions and the related field cover the primary
//   key of the related table. Related table Variant, primary key (ItemNo, Code), non-key field Blocked. Related table Bin, primary key
//   (Loc, Zone, Code), non-key field Blocked. Relations: a key condition and a Boolean const non-key condition, inside an if() arm and
//   plain; a key condition only, inside an if() arm; key conditions that leave one primary key field unnamed (Bin.Code where Loc);
//   the same with a non-key condition; no where() on a related field that is the last primary key field; two key conditions that name
//   the whole key; a condition on the related field itself. Values: one the conditions accept, one that exists for another key value,
//   one a non-key condition excludes, one that exists nowhere, and blank.
// Existing pins: RelationWhereMulti.al (two key, two non-key, key and non-key with filter(<> x), three conditions, a relation to a field
//   in no key), RelationWhereValidated.al (a where() that names the validated field), PnF13RelationFilterConditions.al (one condition).
// BC versions: 27, 28, 29 by CI

table 66340 "REC WhKey Variant"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ItemNo; Code[10]) { }
        field(2; "Code"; Code[10]) { }
        field(3; Blocked; Boolean) { }
    }

    keys { key(PK; ItemNo, "Code") { Clustered = true; } }
}

table 66341 "REC WhKey Bin"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Loc; Code[10]) { }
        field(2; Zone; Code[10]) { }
        field(3; "Code"; Code[10]) { }
        field(4; Blocked; Boolean) { }
    }

    keys { key(PK; Loc, Zone, "Code") { Clustered = true; } }
}

table 66342 "REC WhKey Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Type; Option) { OptionMembers = " ",Item,Resource; }
        field(3; "No."; Code[10]) { }
        field(4; Loc; Code[10]) { }
        field(5; Zone; Code[10]) { }
        field(10; ArmKeyNonKey; Code[10])
        {
            TableRelation = if (Type = const(Item)) "REC WhKey Variant"."Code" where(ItemNo = field("No."), Blocked = const(false));
        }
        field(11; PlainKeyNonKey; Code[10])
        {
            TableRelation = "REC WhKey Variant"."Code" where(ItemNo = field("No."), Blocked = const(false));
        }
        field(12; ArmKeyOnly; Code[10])
        {
            TableRelation = if (Type = const(Item)) "REC WhKey Variant"."Code" where(ItemNo = field("No."));
        }
        field(13; PlainKeyOnly; Code[10])
        {
            TableRelation = "REC WhKey Variant"."Code" where(ItemNo = field("No."));
        }
        field(14; NonKeyOnly; Code[10])
        {
            TableRelation = "REC WhKey Variant"."Code" where(Blocked = const(false));
        }
        field(15; SelfAndKey; Code[10])
        {
            TableRelation = "REC WhKey Variant"."Code" where(ItemNo = field("No."), "Code" = field(SelfAndKey));
        }
        field(20; BinPartialKey; Code[10])
        {
            TableRelation = "REC WhKey Bin"."Code" where(Loc = field(Loc));
        }
        field(21; BinPartialKeyNonKey; Code[10])
        {
            TableRelation = "REC WhKey Bin"."Code" where(Loc = field(Loc), Blocked = const(false));
        }
        field(22; BinNoWhere; Code[10])
        {
            TableRelation = "REC WhKey Bin"."Code";
        }
        field(23; BinWholeKey; Code[10])
        {
            TableRelation = "REC WhKey Bin"."Code" where(Loc = field(Loc), Zone = field(Zone));
        }
        field(24; BinSecondKeyFieldOnly; Code[10])
        {
            TableRelation = "REC WhKey Bin"."Code" where(Zone = field(Zone));
        }
        field(25; BinWholeKeyNonKey; Code[10])
        {
            TableRelation = "REC WhKey Bin"."Code" where(Loc = field(Loc), Zone = field(Zone), Blocked = const(false));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 66344 "REC WhKey Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        V: Record "REC WhKey Variant";
        B: Record "REC WhKey Bin";
        L: Record "REC WhKey Line";
    begin
        V.DeleteAll();
        B.DeleteAll();
        L.DeleteAll();
        AddVariant('I1', 'V1', false);
        AddVariant('I1', 'VB', true);
        AddVariant('I2', 'V2', false);
        AddBin('L1', 'Z1', 'B1', false);
        AddBin('L1', 'Z1', 'BB', true);
        AddBin('L1', 'Z2', 'B2', false);
        AddBin('L2', 'Z1', 'B3', false);
    end;

    local procedure AddVariant(ItemNo: Code[10]; VariantCode: Code[10]; Blocked: Boolean)
    var
        V: Record "REC WhKey Variant";
    begin
        V.ItemNo := ItemNo;
        V."Code" := VariantCode;
        V.Blocked := Blocked;
        V.Insert();
    end;

    local procedure AddBin(Loc: Code[10]; Zone: Code[10]; BinCode: Code[10]; Blocked: Boolean)
    var
        B: Record "REC WhKey Bin";
    begin
        B.Loc := Loc;
        B.Zone := Zone;
        B."Code" := BinCode;
        B.Blocked := Blocked;
        B.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(var L: Record "REC WhKey Line"; FieldNo: Integer; Value: Code[10])
    begin
        case FieldNo of
            L.FieldNo(ArmKeyNonKey):
                L.Validate(ArmKeyNonKey, Value);
            L.FieldNo(PlainKeyNonKey):
                L.Validate(PlainKeyNonKey, Value);
            L.FieldNo(ArmKeyOnly):
                L.Validate(ArmKeyOnly, Value);
            L.FieldNo(PlainKeyOnly):
                L.Validate(PlainKeyOnly, Value);
            L.FieldNo(NonKeyOnly):
                L.Validate(NonKeyOnly, Value);
            L.FieldNo(SelfAndKey):
                L.Validate(SelfAndKey, Value);
            L.FieldNo(BinPartialKey):
                L.Validate(BinPartialKey, Value);
            L.FieldNo(BinPartialKeyNonKey):
                L.Validate(BinPartialKeyNonKey, Value);
            L.FieldNo(BinNoWhere):
                L.Validate(BinNoWhere, Value);
            L.FieldNo(BinWholeKey):
                L.Validate(BinWholeKey, Value);
            L.FieldNo(BinSecondKeyFieldOnly):
                L.Validate(BinSecondKeyFieldOnly, Value);
            L.FieldNo(BinWholeKeyNonKey):
                L.Validate(BinWholeKeyNonKey, Value);
            else
                Error('no Validate case for field %1', FieldNo);
        end;
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; LineType: Option; Value: Code[10])
    var
        L: Record "REC WhKey Line";
    begin
        L.Init();
        L.Type := LineType;
        L."No." := 'I1';
        L.Loc := 'L1';
        L.Zone := 'Z1';
        if TryValidate(L, FieldNo, Value) then
            Observer.Observe(Name, 'ok')
        else begin
            Observer.Observe(Name, GetLastErrorCode() + ' | ' + GetLastErrorText());
            ClearLastError();
        end;
    end;

    local procedure VariantCells(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; LineType: Option)
    begin
        Cell(Observer, 'accepted V1', FieldNo, LineType, 'V1');
        Cell(Observer, 'blocked VB', FieldNo, LineType, 'VB');
        Cell(Observer, 'other item V2', FieldNo, LineType, 'V2');
        Cell(Observer, 'missing NOPE', FieldNo, LineType, 'NOPE');
        Cell(Observer, 'blank', FieldNo, LineType, '');
    end;

    local procedure BinCells(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    begin
        Cell(Observer, 'accepted B1', FieldNo, 0, 'B1');
        Cell(Observer, 'blocked BB', FieldNo, 0, 'BB');
        Cell(Observer, 'other zone B2', FieldNo, 0, 'B2');
        Cell(Observer, 'other location B3', FieldNo, 0, 'B3');
        Cell(Observer, 'missing NOPE', FieldNo, 0, 'NOPE');
    end;

    [Test]
    procedure IfArm_KeyAndBooleanNonKeyCondition_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        VariantCells(Observer, L.FieldNo(ArmKeyNonKey), L.Type::Item);
        Observer.Finish();
    end;

    [Test]
    procedure IfArm_KeyAndBooleanNonKeyCondition_ArmDoesNotApply()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        VariantCells(Observer, L.FieldNo(ArmKeyNonKey), L.Type::Resource);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_KeyAndBooleanNonKeyCondition_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        VariantCells(Observer, L.FieldNo(PlainKeyNonKey), L.Type::Item);
        Observer.Finish();
    end;

    [Test]
    procedure IfArm_KeyConditionOnly_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        VariantCells(Observer, L.FieldNo(ArmKeyOnly), L.Type::Item);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_KeyConditionOnly_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        VariantCells(Observer, L.FieldNo(PlainKeyOnly), L.Type::Item);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_BooleanNonKeyConditionOnly_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        VariantCells(Observer, L.FieldNo(NonKeyOnly), L.Type::Item);
        Observer.Finish();
    end;

    [Test]
    procedure Plain_KeyConditionAndTheValidatedField_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        VariantCells(Observer, L.FieldNo(SelfAndKey), L.Type::Item);
        Observer.Finish();
    end;

    [Test]
    procedure ThreeFieldKey_OneKeyCondition_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        BinCells(Observer, L.FieldNo(BinPartialKey));
        Observer.Finish();
    end;

    [Test]
    procedure ThreeFieldKey_OneKeyAndNonKeyCondition_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        BinCells(Observer, L.FieldNo(BinPartialKeyNonKey));
        Observer.Finish();
    end;

    [Test]
    procedure ThreeFieldKey_NoWhere_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        BinCells(Observer, L.FieldNo(BinNoWhere));
        Observer.Finish();
    end;

    [Test]
    procedure ThreeFieldKey_TwoKeyConditionsWholeKey_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        BinCells(Observer, L.FieldNo(BinWholeKey));
        Observer.Finish();
    end;

    [Test]
    procedure ThreeFieldKey_SecondKeyFieldOnly_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        BinCells(Observer, L.FieldNo(BinSecondKeyFieldOnly));
        Observer.Finish();
    end;

    [Test]
    procedure ThreeFieldKey_WholeKeyAndNonKeyCondition_ErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC WhKey Line";
    begin
        Initialize();
        BinCells(Observer, L.FieldNo(BinWholeKeyNonKey));
        Observer.Finish();
    end;
}
