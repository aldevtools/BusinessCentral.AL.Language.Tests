// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 75920, 75921, 75922, 75924, enum 75923, table extension 75925,
//                codeunit 75931; Base Application table Item (field "Item Category Code") and the platform table User
// Probe: written against local BC 27.5, 28.5 and 29.0 service tiers (Windows); every literal asserted below is what those tiers produced.
//        Other builds are checked by the corpus CI matrix. Asked by al-runner issue 8249.
// Facts:
//  - Field.RelationFieldNo is 0 for a TableRelation that names no field, whatever the target's primary key is: a key on field 1,
//    a key on field 5, a key with two fields; also with a where filter, with ValidateTableRelation = false, on a FlowFilter field,
//    on a table extension field, on a Guid field related to User, and on Item."Item Category Code" (5722/0). RelationTableNo is the
//    target table.
//  - A TableRelation that names a field gives that field's number, also when the field is the primary key (1, 5) or one field of
//    a two-field key (1 or 2), or a field outside the key (2).
//  - A conditional TableRelation (if ... else ..., if without else, the same table and field in both branches) gives 0/0.
//  - Field filters: SetRange(RelationFieldNo, 0) with RelationTableNo <> 0 lists the no-field relations (and SystemCreatedBy and
//    SystemModifiedBy, 2000000002 and 2000000004); RelationFieldNo <> 0 lists the relations that name a field.
//  - FieldRef.Relation() and Record.Relation() give the target table with or without a named field; for a conditional relation the
//    table of the branch the current record matches. FieldRef.Relation() is 0 for a field without a relation and for a conditional
//    relation no branch matches; Record.Relation() raises there ("No relationship has been associated with the field ...").
// BC versions: 27.5, 28.5, 29.0

table 75920 "RFN Target One"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

// The primary key is field 5, not field 1.
table 75921 "RFN Target Key Five"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Desc; Text[30]) { }
        field(5; KeyNo; Integer) { }
    }

    keys
    {
        key(PK; KeyNo) { Clustered = true; }
    }
}

// A primary key with two fields.
table 75922 "RFN Target Two Keys"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; First; Code[10]) { }
        field(2; Second; Code[10]) { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; First, Second) { Clustered = true; }
    }
}

enum 75923 "RFN Kind"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
}

table 75924 "RFN Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "RFN Kind") { }
        field(10; NoField; Code[20]) { TableRelation = "RFN Target One"; }
        field(11; PkField; Code[20]) { TableRelation = "RFN Target One".Code; }
        field(12; NonPkField; Text[50]) { TableRelation = "RFN Target One".Name; }
        field(13; KeyFiveNoField; Integer) { TableRelation = "RFN Target Key Five"; }
        field(14; KeyFiveField; Integer) { TableRelation = "RFN Target Key Five".KeyNo; }
        field(15; TwoKeysNoField; Code[10]) { TableRelation = "RFN Target Two Keys"; }
        field(16; TwoKeysSecond; Code[10]) { TableRelation = "RFN Target Two Keys".Second; }
        field(17; TwoKeysFirst; Code[10]) { TableRelation = "RFN Target Two Keys".First; }
        field(18; NoFieldWhere; Code[20]) { TableRelation = "RFN Target One" where(Name = const('X')); }
        field(19; TwoKeysNoFieldWhere; Code[10]) { TableRelation = "RFN Target Two Keys" where(First = const('F')); }
        field(20; CondNoField; Code[20])
        {
            TableRelation = if (Kind = const(A)) "RFN Target One" else "RFN Target Two Keys";
            ValidateTableRelation = false;
        }
        field(21; CondOneBranch; Code[20]) { TableRelation = if (Kind = const(A)) "RFN Target One"; }
        field(22; CondSameTarget; Code[20])
        {
            TableRelation = if (Kind = const(A)) "RFN Target One".Code else "RFN Target One".Code;
        }
        field(23; CondWithField; Code[20])
        {
            TableRelation = if (Kind = const(A)) "RFN Target One".Code else "RFN Target Two Keys".Second;
            ValidateTableRelation = false;
        }
        field(24; FilterNoField; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = "RFN Target One";
        }
        field(25; UserNoField; Guid) { TableRelation = User; }
        field(26; NoRelation; Code[20]) { }
        field(27; NoFieldNoValidate; Code[20])
        {
            TableRelation = "RFN Target One";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 75925 "RFN Source Ext" extends "RFN Source"
{
    fields
    {
        field(75925; ExtNoField; Code[20]) { DataClassification = SystemMetadata; TableRelation = "RFN Target One"; }
        field(75926; ExtNonPkField; Text[50]) { DataClassification = SystemMetadata; TableRelation = "RFN Target One".Name; }
    }
}

codeunit 75930 "RFN Relation Field No Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FieldRow(TableNo: Integer; FieldNo: Integer): Text
    var
        FieldRec: Record Field;
    begin
        FieldRec.Get(TableNo, FieldNo);
        exit(Format(FieldRec.RelationTableNo) + '/' + Format(FieldRec.RelationFieldNo));
    end;

    local procedure SourceRow(FieldNo: Integer): Text
    begin
        exit(FieldRow(Database::"RFN Source", FieldNo));
    end;

    [Test]
    procedure FieldTable_RelationWithoutField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('target one, no field', SourceRow(10));
        Observer.Observe('key is field 5, no field', SourceRow(13));
        Observer.Observe('two key fields, no field', SourceRow(15));
        Observer.Observe('target one, no field, where', SourceRow(18));
        Observer.Observe('two key fields, no field, where', SourceRow(19));
        Observer.Observe('no field, no validate', SourceRow(27));
        Observer.Observe('no relation', SourceRow(26));
        Observer.Expect('target one, no field', '75920/0');
        Observer.Expect('key is field 5, no field', '75921/0');
        Observer.Expect('two key fields, no field', '75922/0');
        Observer.Expect('target one, no field, where', '75920/0');
        Observer.Expect('two key fields, no field, where', '75922/0');
        Observer.Expect('no field, no validate', '75920/0');
        Observer.Expect('no relation', '0/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_RelationWithField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('target one, key field named', SourceRow(11));
        Observer.Observe('target one, other field named', SourceRow(12));
        Observer.Observe('key is field 5, key field named', SourceRow(14));
        Observer.Observe('two key fields, second named', SourceRow(16));
        Observer.Observe('two key fields, first named', SourceRow(17));
        Observer.Expect('target one, key field named', '75920/1');
        Observer.Expect('target one, other field named', '75920/2');
        Observer.Expect('key is field 5, key field named', '75921/5');
        Observer.Expect('two key fields, second named', '75922/2');
        Observer.Expect('two key fields, first named', '75922/1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_ConditionalRelations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('two tables, no field', SourceRow(20));
        Observer.Observe('one branch, no else', SourceRow(21));
        Observer.Observe('same table and field in both', SourceRow(22));
        Observer.Observe('two tables, fields named', SourceRow(23));
        Observer.Expect('two tables, no field', '0/0');
        Observer.Expect('one branch, no else', '0/0');
        Observer.Expect('same table and field in both', '0/0');
        Observer.Expect('two tables, fields named', '0/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_FlowFilterExtensionPlatformBaseApp()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record Item;
    begin
        Observer.Observe('flowfilter, no field', SourceRow(24));
        Observer.Observe('table extension, no field', SourceRow(75925));
        Observer.Observe('table extension, other field named', SourceRow(75926));
        Observer.Observe('guid to User, no field', SourceRow(25));
        Observer.Observe('Item Item Category Code', FieldRow(Database::Item, Item.FieldNo("Item Category Code")));
        Observer.Expect('flowfilter, no field', '75920/0');
        Observer.Expect('table extension, no field', '75920/0');
        Observer.Expect('table extension, other field named', '75920/2');
        Observer.Expect('guid to User, no field', '2000000120/0');
        Observer.Expect('Item Item Category Code', '5722/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_FilterOnRelationFieldNo()
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
        Numbers: Text;
    begin
        FieldRec.SetRange(TableNo, Database::"RFN Source");
        FieldRec.SetFilter(RelationTableNo, '<>0');
        FieldRec.SetRange(RelationFieldNo, 0);
        if FieldRec.FindSet() then
            repeat
                Numbers += Format(FieldRec."No.") + ',';
            until FieldRec.Next() = 0;
        Observer.Observe('related, field 0', Numbers);
        FieldRec.SetFilter(RelationFieldNo, '<>0');
        Numbers := '';
        if FieldRec.FindSet() then
            repeat
                Numbers += Format(FieldRec."No.") + ',';
            until FieldRec.Next() = 0;
        Observer.Observe('related, field not 0', Numbers);
        Observer.Expect('related, field 0', '10,13,15,18,19,24,25,27,75925,2000000002,2000000004,');
        Observer.Expect('related, field not 0', '11,12,14,16,17,75926,');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_Relation_PlainRelations()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"RFN Source");
        Observer.Observe('10 no field', Format(RecRef.Field(10).Relation()));
        Observer.Observe('11 key field', Format(RecRef.Field(11).Relation()));
        Observer.Observe('12 other field', Format(RecRef.Field(12).Relation()));
        Observer.Observe('13 key five, no field', Format(RecRef.Field(13).Relation()));
        Observer.Observe('15 two keys, no field', Format(RecRef.Field(15).Relation()));
        Observer.Observe('16 two keys, second', Format(RecRef.Field(16).Relation()));
        Observer.Observe('18 no field, where', Format(RecRef.Field(18).Relation()));
        Observer.Observe('24 flowfilter', Format(RecRef.Field(24).Relation()));
        Observer.Observe('25 user', Format(RecRef.Field(25).Relation()));
        Observer.Observe('75925 extension', Format(RecRef.Field(75925).Relation()));
        Observer.Expect('10 no field', '75920');
        Observer.Expect('11 key field', '75920');
        Observer.Expect('12 other field', '75920');
        Observer.Expect('13 key five, no field', '75921');
        Observer.Expect('15 two keys, no field', '75922');
        Observer.Expect('16 two keys, second', '75922');
        Observer.Expect('18 no field, where', '75920');
        Observer.Expect('24 flowfilter', '75920');
        Observer.Expect('25 user', '2000000120');
        Observer.Expect('75925 extension', '75920');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_Relation_ConditionalByKind()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"RFN Source");
        RecRef.Field(2).Value := "RFN Kind"::A;
        Observer.Observe('A: 20 two tables', Format(RecRef.Field(20).Relation()));
        Observer.Observe('A: 21 one branch', Format(RecRef.Field(21).Relation()));
        Observer.Observe('A: 23 fields named', Format(RecRef.Field(23).Relation()));
        RecRef.Field(2).Value := "RFN Kind"::B;
        Observer.Observe('B: 20 two tables', Format(RecRef.Field(20).Relation()));
        Observer.Observe('B: 23 fields named', Format(RecRef.Field(23).Relation()));
        Observer.Expect('A: 20 two tables', '75920');
        Observer.Expect('A: 21 one branch', '75920');
        Observer.Expect('A: 23 fields named', '75920');
        Observer.Expect('B: 20 two tables', '75922');
        Observer.Expect('B: 23 fields named', '75922');
        Observer.Verify();
    end;

    [Test]
    procedure Record_Relation_NoFieldAndConditional()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "RFN Source";
    begin
        Observer.Observe('no field', Format(Source.Relation(Source.NoField)));
        Observer.Observe('other field', Format(Source.Relation(Source.NonPkField)));
        Observer.Observe('two keys, no field', Format(Source.Relation(Source.TwoKeysNoField)));
        Source.Kind := Source.Kind::A;
        Observer.Observe('A: two tables, no field', Format(Source.Relation(Source.CondNoField)));
        Source.Kind := Source.Kind::B;
        Observer.Observe('B: two tables, no field', Format(Source.Relation(Source.CondNoField)));
        Observer.Expect('no field', '75920');
        Observer.Expect('other field', '75920');
        Observer.Expect('two keys, no field', '75922');
        Observer.Expect('A: two tables, no field', '75920');
        Observer.Expect('B: two tables, no field', '75922');
        Observer.Verify();
    end;

    // Reads that may raise go through Codeunit.Run, so a raise is observed as its text instead of failing the test.
    [Test]
    procedure Relation_NoRelationAndUnmatchedCondition()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('FieldRef 26 no relation', ReadRelation(1, 26, "RFN Kind"::A));
        Observer.Observe('FieldRef B: 21 one branch', ReadRelation(1, 21, "RFN Kind"::B));
        Observer.Observe('Record B: 21 one branch', ReadRelation(2, 21, "RFN Kind"::B));
        Observer.Observe('Record A: 21 one branch', ReadRelation(2, 21, "RFN Kind"::A));
        Observer.Expect('FieldRef 26 no relation', '0');
        Observer.Expect('FieldRef B: 21 one branch', '0');
        Observer.Expect('Record B: 21 one branch', 'error: No relationship has been associated with the field CondOneBranch in RFN Source.');
        Observer.Expect('Record A: 21 one branch', '75920');
        Observer.Verify();
    end;

    local procedure ReadRelation(How: Integer; FieldNo: Integer; Kind: Enum "RFN Kind"): Text
    var
        Reader: Codeunit "RFN Relation Reader";
    begin
        ClearLastError();
        Reader.SetUp(How, FieldNo, Kind);
        if Reader.Run() then
            exit(Format(Reader.Result()));
        exit('error: ' + GetLastErrorText());
    end;
    // Issue 8592: a TableRelation that names no field, against a target whose primary key has two fields of different types,
    // and a source field inside its own table's primary key. Source fields are in table 75929 "RFN Source Keyed".
    // Every cell reads RelationTableNo = the target table and RelationFieldNo = 0.
    // Measured directly on a local BC 29.0.54011.57673 service tier (invented repro): the control
    // (Code to a Code key, outside its own key), A (inside its own key), B (Code to a (Code, Text) key) and C (Integer to an
    // (Integer, Code) key). Confirmed by the corpus CI on real BC 27.5, 28.5 and 29.0: the key-order cells (Code to an
    // (Integer, Code) key, Code to a (Code, Integer) key) and Integer to a (Code, Integer) key.

    [Test]
    procedure FieldTable_NoField_ControlCodeKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('code to (code), outside own key', KeyedRow(10));
        Observer.Expect('code to (code), outside own key', '75920/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_NoField_SourceInsideOwnPrimaryKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('code to (code), inside own key (integer, code)', KeyedRow(2));
        Observer.Expect('code to (code), inside own key (integer, code)', '75920/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_NoField_CodeToCodeTextKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('code to (code, text)', KeyedRow(11));
        Observer.Expect('code to (code, text)', '75926/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_NoField_IntegerToIntegerCodeKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('integer to (integer, code)', KeyedRow(12));
        Observer.Expect('integer to (integer, code)', '75927/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_NoField_CodeToIntegerCodeKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('code to (integer, code)', KeyedRow(13));
        Observer.Expect('code to (integer, code)', '75927/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_NoField_CodeToCodeIntegerKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('code to (code, integer)', KeyedRow(14));
        Observer.Expect('code to (code, integer)', '75928/0');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_NoField_IntegerToCodeIntegerKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('integer to (code, integer)', KeyedRow(15));
        Observer.Expect('integer to (code, integer)', '75928/0');
        Observer.Verify();
    end;

    local procedure KeyedRow(FieldNo: Integer): Text
    begin
        exit(FieldRow(Database::"RFN Source Keyed", FieldNo));
    end;

    local procedure Initialize()
    var
        Source: Record "RFN Source Keyed";
        CodeText: Record "RFN Target Code Text";
        IntCode: Record "RFN Target Int Code";
        CodeInt: Record "RFN Target Code Int";
    begin
        Source.DeleteAll();
        CodeText.DeleteAll();
        IntCode.DeleteAll();
        CodeInt.DeleteAll();
    end;
}

codeunit 75931 "RFN Relation Reader"
{
    var
        How: Integer;
        FieldNo: Integer;
        Kind: Enum "RFN Kind";
        Value: Integer;

    trigger OnRun()
    var
        Source: Record "RFN Source";
        RecRef: RecordRef;
    begin
        if How = 1 then begin
            RecRef.Open(Database::"RFN Source");
            RecRef.Field(2).Value := Kind;
            Value := RecRef.Field(FieldNo).Relation();
        end else begin
            Source.Kind := Kind;
            Value := Source.Relation(Source.CondOneBranch);
        end;
    end;

    procedure SetUp(NewHow: Integer; NewFieldNo: Integer; NewKind: Enum "RFN Kind")
    begin
        How := NewHow;
        FieldNo := NewFieldNo;
        Kind := NewKind;
    end;

    procedure Result(): Integer
    begin
        exit(Value);
    end;
}

// local object: the shapes of these tables' primary keys and relations are what the issue 8592 tests read (Field table rows).
// A primary key of a Code and a Text field.
table 75926 "RFN Target Code Text"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K1; Code[20]) { }
        field(2; K2; Text[30]) { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; K1, K2) { Clustered = true; }
    }
}

// A primary key of an Integer and a Code field, in that order.
table 75927 "RFN Target Int Code"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K1; Integer) { }
        field(2; K2; Code[20]) { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; K1, K2) { Clustered = true; }
    }
}

// A primary key of a Code and an Integer field, in that order.
table 75928 "RFN Target Code Int"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; K1; Code[20]) { }
        field(2; K2; Integer) { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; K1, K2) { Clustered = true; }
    }
}

// Every relation names no field. The primary key is (Id, KeyCode), so KeyCode is a related field inside its own key.
table 75929 "RFN Source Keyed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; KeyCode; Code[20]) { TableRelation = "RFN Target One"; }
        field(10; ControlNoField; Code[20]) { TableRelation = "RFN Target One"; }
        field(11; CodeToCodeText; Code[20]) { TableRelation = "RFN Target Code Text"; }
        field(12; IntToIntCode; Integer) { TableRelation = "RFN Target Int Code"; }
        field(13; CodeToIntCode; Code[20]) { TableRelation = "RFN Target Int Code"; }
        field(14; CodeToCodeInt; Code[20]) { TableRelation = "RFN Target Code Int"; }
        field(15; IntToCodeInt; Integer) { TableRelation = "RFN Target Code Int"; }
    }

    keys
    {
        key(PK; Id, KeyCode) { Clustered = true; }
    }
}
