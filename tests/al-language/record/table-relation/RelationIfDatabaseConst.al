// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 66320, tables 66321 to 66324, test codeunit 66326; Base Application table Customer
//   (only its number, as a constant)
// local object: the TableRelation definitions are what the tests measure.
// Probe (al-runner issue 7365: `TableRelation = if ("Source Type" = const(Database::Customer)) Customer."No." else if (...)`): observation
//   form, the values are read from the corpus CI matrix.
// Area: a conditional TableRelation whose if() condition compares an Integer field with a table number. Condition forms:
//   const(Database::"Own Table"), const(Database::Customer) (a table of another app), const(<the number as a literal>),
//   filter(Database::A | Database::B), an if / else if chain, an if with a plain else, and an arm with where(Status = field(Subtype)).
//   Per field and per value of the Integer field (each table number, 0, a number no arm names): the table FieldRef.Relation answers and
//   what Validate does with a value of each related table, a value that exists nowhere and a blank value (ok, or the error text and code).
// Existing pins: RelationWhereQualifiedConst.al pins const(Database::X) inside where(); ScEnumConstRelation.al pins if() conditions with an
//   enum-qualified const; record/filters/P68G_RelationArms.al pins which arm applies for const(x) and filter(...) on Option and Code fields.
// BC versions: 27, 28, 29 by CI

enum 66320 "REC IfDb Status"
{
    Extensible = false;
    value(0; Open) { }
    value(1; Released) { }
}

table 66321 "REC IfDb Cust"
{
    DataClassification = SystemMetadata;
    fields { field(1; "No."; Code[20]) { } }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 66322 "REC IfDb Vend"
{
    DataClassification = SystemMetadata;
    fields { field(1; "No."; Code[20]) { } }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 66323 "REC IfDb Order"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Status; Enum "REC IfDb Status") { }
        field(2; "No."; Code[20]) { }
    }
    keys { key(PK; Status, "No.") { Clustered = true; } }
}

table 66324 "REC IfDb Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Source Type"; Integer) { }
        field(3; "Source Subtype"; Enum "REC IfDb Status") { }
        field(10; "Source No."; Code[20])
        {
            TableRelation = if ("Source Type" = const(Database::"REC IfDb Cust")) "REC IfDb Cust"."No."
            else if ("Source Type" = const(Database::"REC IfDb Vend")) "REC IfDb Vend"."No.";
        }
        field(11; "Source Id"; Code[20])
        {
            TableRelation = if ("Source Type" = const(Database::"REC IfDb Order")) "REC IfDb Order"."No." where(Status = field("Source Subtype"));
        }
        field(12; "By Filter"; Code[20])
        {
            TableRelation = if ("Source Type" = filter(Database::"REC IfDb Cust" | Database::"REC IfDb Order")) "REC IfDb Cust"."No."
            else if ("Source Type" = filter(Database::"REC IfDb Vend")) "REC IfDb Vend"."No.";
        }
        field(13; "By Number"; Code[20])
        {
            TableRelation = if ("Source Type" = const(66321)) "REC IfDb Cust"."No."
            else if ("Source Type" = const(66322)) "REC IfDb Vend"."No.";
        }
        field(14; "With Else"; Code[20])
        {
            TableRelation = if ("Source Type" = const(Database::"REC IfDb Cust")) "REC IfDb Cust"."No."
            else "REC IfDb Vend"."No.";
        }
        field(15; "Other App"; Code[20])
        {
            TableRelation = if ("Source Type" = const(Database::Customer)) "REC IfDb Cust"."No."
            else if ("Source Type" = const(Database::"REC IfDb Vend")) "REC IfDb Vend"."No.";
        }
        field(16; "Table Form"; Code[20])
        {
            TableRelation = if ("Source Type" = const(Database::"REC IfDb Cust")) "REC IfDb Cust"
            else if ("Source Type" = const(Database::"REC IfDb Vend")) "REC IfDb Vend";
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 66326 "REC IfDb Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        C: Record "REC IfDb Cust";
        V: Record "REC IfDb Vend";
        O: Record "REC IfDb Order";
        L: Record "REC IfDb Line";
    begin
        C.DeleteAll();
        V.DeleteAll();
        O.DeleteAll();
        L.DeleteAll();
        C."No." := 'C1';
        C.Insert();
        C."No." := 'BOTH';
        C.Insert();
        V."No." := 'V1';
        V.Insert();
        V."No." := 'BOTH';
        V.Insert();
        O.Status := O.Status::Open;
        O."No." := 'O1';
        O.Insert();
        O.Status := O.Status::Released;
        O."No." := 'O2';
        O.Insert();
    end;

    [TryFunction]
    local procedure TryValidate(var L: Record "REC IfDb Line"; FieldNo: Integer; Value: Code[20])
    begin
        case FieldNo of
            L.FieldNo("Source No."):
                L.Validate("Source No.", Value);
            L.FieldNo("Source Id"):
                L.Validate("Source Id", Value);
            L.FieldNo("By Filter"):
                L.Validate("By Filter", Value);
            L.FieldNo("By Number"):
                L.Validate("By Number", Value);
            L.FieldNo("With Else"):
                L.Validate("With Else", Value);
            L.FieldNo("Other App"):
                L.Validate("Other App", Value);
            L.FieldNo("Table Form"):
                L.Validate("Table Form", Value);
        end;
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; SourceType: Integer; Subtype: Enum "REC IfDb Status"; Value: Code[20])
    var
        L: Record "REC IfDb Line";
    begin
        L.Init();
        L."Source Type" := SourceType;
        L."Source Subtype" := Subtype;
        if TryValidate(L, FieldNo, Value) then
            Observer.Observe(Name, 'ok')
        else begin
            Observer.Observe(Name, GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
        end;
    end;

    local procedure RelationOf(FieldNo: Integer; SourceType: Integer): Text
    var
        L: Record "REC IfDb Line";
        Ref: RecordRef;
        Related: Integer;
    begin
        L.Init();
        L."Source Type" := SourceType;
        Ref.GetTable(L);
        Related := Ref.Field(FieldNo).Relation();
        case Related of
            0:
                exit('none');
            Database::"REC IfDb Cust":
                exit('Cust');
            Database::"REC IfDb Vend":
                exit('Vend');
            Database::"REC IfDb Order":
                exit('Order');
        end;
        exit(Format(Related));
    end;

    local procedure State(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; SourceType: Integer)
    var
        Subtype: Enum "REC IfDb Status";
    begin
        Observer.Observe(Name + ' relation', RelationOf(FieldNo, SourceType));
        One(Observer, Name + ' C1', FieldNo, SourceType, Subtype::Open, 'C1');
        One(Observer, Name + ' V1', FieldNo, SourceType, Subtype::Open, 'V1');
        One(Observer, Name + ' NOPE', FieldNo, SourceType, Subtype::Open, 'NOPE');
        One(Observer, Name + ' blank', FieldNo, SourceType, Subtype::Open, '');
    end;

    [Test]
    procedure IfConstDatabase_OwnTables_ArmOfEachTableNumber()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'cust', L.FieldNo("Source No."), Database::"REC IfDb Cust");
        State(Observer, 'vend', L.FieldNo("Source No."), Database::"REC IfDb Vend");
        Observer.Finish();
    end;

    [Test]
    procedure IfConstDatabase_OwnTables_NoArmApplies()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'zero', L.FieldNo("Source No."), 0);
        State(Observer, 'order', L.FieldNo("Source No."), Database::"REC IfDb Order");
        State(Observer, 'customer 18', L.FieldNo("Source No."), Database::Customer);
        Observer.Finish();
    end;

    [Test]
    procedure IfConstDatabase_ArmWithWhereField()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
        Subtype: Enum "REC IfDb Status";
    begin
        Initialize();
        Observer.Observe('order relation', RelationOf(L.FieldNo("Source Id"), Database::"REC IfDb Order"));
        One(Observer, 'order open O1', L.FieldNo("Source Id"), Database::"REC IfDb Order", Subtype::Open, 'O1');
        One(Observer, 'order open O2', L.FieldNo("Source Id"), Database::"REC IfDb Order", Subtype::Open, 'O2');
        One(Observer, 'order released O2', L.FieldNo("Source Id"), Database::"REC IfDb Order", Subtype::Released, 'O2');
        One(Observer, 'order released O1', L.FieldNo("Source Id"), Database::"REC IfDb Order", Subtype::Released, 'O1');
        One(Observer, 'order open NOPE', L.FieldNo("Source Id"), Database::"REC IfDb Order", Subtype::Open, 'NOPE');
        One(Observer, 'order open blank', L.FieldNo("Source Id"), Database::"REC IfDb Order", Subtype::Open, '');
        Observer.Observe('cust relation', RelationOf(L.FieldNo("Source Id"), Database::"REC IfDb Cust"));
        One(Observer, 'cust O1', L.FieldNo("Source Id"), Database::"REC IfDb Cust", Subtype::Open, 'O1');
        One(Observer, 'cust NOPE', L.FieldNo("Source Id"), Database::"REC IfDb Cust", Subtype::Open, 'NOPE');
        One(Observer, 'zero NOPE', L.FieldNo("Source Id"), 0, Subtype::Open, 'NOPE');
        Observer.Finish();
    end;

    [Test]
    procedure IfFilterDatabaseList_ArmOfEachTableNumber()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'cust', L.FieldNo("By Filter"), Database::"REC IfDb Cust");
        State(Observer, 'order', L.FieldNo("By Filter"), Database::"REC IfDb Order");
        Observer.Finish();
    end;

    [Test]
    procedure IfFilterDatabaseList_SecondArmAndNoArm()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'vend', L.FieldNo("By Filter"), Database::"REC IfDb Vend");
        State(Observer, 'zero', L.FieldNo("By Filter"), 0);
        Observer.Finish();
    end;

    [Test]
    procedure IfConstNumberLiteral_ArmOfEachTableNumber()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'cust', L.FieldNo("By Number"), Database::"REC IfDb Cust");
        State(Observer, 'vend', L.FieldNo("By Number"), Database::"REC IfDb Vend");
        State(Observer, 'zero', L.FieldNo("By Number"), 0);
        Observer.Finish();
    end;

    [Test]
    procedure IfConstDatabase_PlainElse_ArmOfEachTableNumber()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'cust', L.FieldNo("With Else"), Database::"REC IfDb Cust");
        State(Observer, 'vend', L.FieldNo("With Else"), Database::"REC IfDb Vend");
        State(Observer, 'zero', L.FieldNo("With Else"), 0);
        Observer.Finish();
    end;

    [Test]
    procedure IfConstDatabase_TableOfAnotherApp_ArmOfEachTableNumber()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'customer 18', L.FieldNo("Other App"), Database::Customer);
        State(Observer, 'vend', L.FieldNo("Other App"), Database::"REC IfDb Vend");
        State(Observer, 'cust', L.FieldNo("Other App"), Database::"REC IfDb Cust");
        Observer.Finish();
    end;

    [Test]
    procedure IfConstDatabase_TableFormWithoutField_ArmOfEachTableNumber()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        State(Observer, 'cust', L.FieldNo("Table Form"), Database::"REC IfDb Cust");
        State(Observer, 'vend', L.FieldNo("Table Form"), Database::"REC IfDb Vend");
        State(Observer, 'zero', L.FieldNo("Table Form"), 0);
        Observer.Finish();
    end;

    [Test]
    procedure IfConstDatabase_ConditionChangedAfterValue_KeepsValue()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "REC IfDb Line";
    begin
        Initialize();
        L.Init();
        L.Id := 1;
        L."Source Type" := Database::"REC IfDb Cust";
        if TryValidate(L, L.FieldNo("Source No."), 'C1') then
            Observer.Observe('validate C1 as cust', 'ok')
        else
            Observer.ObserveError('validate C1 as cust');
        L.Insert();
        L.Validate("Source Type", Database::"REC IfDb Vend");
        Observer.Observe('value after the type changed', L."Source No.");
        if L.Modify() then
            Observer.Observe('modify', 'ok')
        else
            Observer.Observe('modify', 'no');
        if TryValidate(L, L.FieldNo("Source No."), 'C1') then
            Observer.Observe('validate C1 as vend', 'ok')
        else
            Observer.ObserveError('validate C1 as vend');
        Observer.Finish();
    end;
}
