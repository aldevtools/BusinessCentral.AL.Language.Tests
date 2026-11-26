// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); tables 79159-79166, codeunits 79159-79160 (all self-contained)
// Probe (al-runner issues 8988 and 9178): Record.Rename and RecordRef.Rename of a Code[20] primary key to a new value that is longer
//   than a related field of another table (TableRelation to the renamed table), or that does not convert to the related field's
//   type. Each test commits its setup, runs the Rename inside Codeunit.Run (so an error rolls back only the Rename) and records:
//   whether Rename raised, GetLastErrorText and GetLastErrorCode, and the rows of both tables afterwards.
// Cells: the related field is a Text[4] field with ObsoleteState = Removed, an Integer field with ObsoleteState = Removed, a
//   Text[4] field with ObsoleteState = Pending, a live Text[4] field. The child table is empty, holds one row whose related field
//   holds the old key, or one row that holds another value (a removed field cannot hold a value, so its row sets only the other
//   fields). Record.Rename and RecordRef.Rename. Old key 'AB', new key 'ABCDEFGHIJ' (10 characters).
// Results (corpus CI, BC 27.5, 28.5 and 29.0 on Linux, identical on all three):
//   - A related field with ObsoleteState = Removed is not checked: Rename succeeds for a Text[4] field with a 10-character new key
//     and for an Integer field with a new key that is not a number, with Record.Rename and RecordRef.Rename, with the child table
//     empty or holding a row. The child row stays as it was.
//   - A related Text[4] field with ObsoleteState = Pending or live: Rename raises 'The record could not be renamed. A type conversion
//     error occurred while updating reference field <child table>.<field>. The record has data type Code and the referencing field
//     has data type Text.' with GetLastErrorCode 'InvalidType:StringLengthExceeded'. Whether any row holds the old key does not
//     matter: the same error with the child table empty, with a row that holds the old key, another value or a blank value.
//     RecordRef.Rename raises the same error. The master keeps its old key and the child row stays as it was.
// BC versions: 27, 28, 29

table 79159 "RSR RemText Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79160 "RSR RemText Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Text[4])
        {
            TableRelation = "RSR RemText Master";
            ObsoleteState = Removed;
            ObsoleteReason = 'Probe of a removed short field with a relation.';
        }
        field(3; Other; Text[30]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79161 "RSR RemInt Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79162 "RSR RemInt Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Integer)
        {
            TableRelation = "RSR RemInt Master";
            ObsoleteState = Removed;
            ObsoleteReason = 'Probe of a removed Integer field with a relation to a Code key.';
        }
        field(3; Other; Text[30]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79163 "RSR Pend Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79164 "RSR Pend Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Text[4])
        {
            TableRelation = "RSR Pend Master";
            ObsoleteState = Pending;
            ObsoleteReason = 'Probe of a pending obsolete short field with a relation.';
        }
        field(3; Other; Text[30]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 79165 "RSR Live Master"
{
    DataClassification = SystemMetadata;
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 79166 "RSR Live Child"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Ref; Text[4]) { TableRelation = "RSR Live Master"; }
        field(3; Other; Text[30]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 79159 "RSR Rename Runner"
{
    var
        TableId: Integer;
        OldCode: Code[20];
        NewCode: Code[20];
        UseRecRef: Boolean;

    trigger OnRun()
    var
        RemTextMaster: Record "RSR RemText Master";
        RemIntMaster: Record "RSR RemInt Master";
        PendMaster: Record "RSR Pend Master";
        LiveMaster: Record "RSR Live Master";
        MasterRef: RecordRef;
    begin
        if UseRecRef then begin
            MasterRef.Open(TableId);
            MasterRef.Field(1).SetRange(OldCode);
            MasterRef.FindFirst();
            MasterRef.Rename(NewCode);
            exit;
        end;
        case TableId of
            Database::"RSR RemText Master":
                begin
                    RemTextMaster.Get(OldCode);
                    RemTextMaster.Rename(NewCode);
                end;
            Database::"RSR RemInt Master":
                begin
                    RemIntMaster.Get(OldCode);
                    RemIntMaster.Rename(NewCode);
                end;
            Database::"RSR Pend Master":
                begin
                    PendMaster.Get(OldCode);
                    PendMaster.Rename(NewCode);
                end;
            Database::"RSR Live Master":
                begin
                    LiveMaster.Get(OldCode);
                    LiveMaster.Rename(NewCode);
                end;
        end;
    end;

    procedure SetRename(MasterTable: Integer; FromCode: Code[20]; ToCode: Code[20]; ByRecRef: Boolean)
    begin
        TableId := MasterTable;
        OldCode := FromCode;
        NewCode := ToCode;
        UseRecRef := ByRecRef;
    end;
}

codeunit 79160 "RSR Rename Short Related"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Prepare(MasterTable: Integer; ChildTable: Integer; ChildRow: Boolean; SetRef: Boolean; RefValue: Text)
    var
        MasterRef: RecordRef;
        ChildRef: RecordRef;
    begin
        MasterRef.Open(MasterTable);
        MasterRef.DeleteAll();
        ChildRef.Open(ChildTable);
        ChildRef.DeleteAll();
        MasterRef.Init();
        MasterRef.Field(1).Value := 'AB';
        MasterRef.Insert();
        if ChildRow then begin
            ChildRef.Init();
            ChildRef.Field(1).Value := 1;
            ChildRef.Field(3).Value := 'other';
            if SetRef then
                ChildRef.Field(2).Value := RefValue;
            ChildRef.Insert();
        end;
        Commit();
    end;

    local procedure RenameAndObserve(MasterTable: Integer; ChildTable: Integer; ByRecRef: Boolean; ReadRef: Boolean)
    var
        Runner: Codeunit "RSR Rename Runner";
    begin
        Runner.SetRename(MasterTable, 'AB', 'ABCDEFGHIJ', ByRecRef);
        ClearLastError();
        if Runner.Run() then
            Observer.Observe('rename', 'no error')
        else begin
            Observer.Observe('rename', 'error');
            Observer.ObserveError('error');
        end;
        Observer.Observe('master rows', MasterRows(MasterTable));
        Observer.Observe('child rows', ChildRows(ChildTable, ReadRef));
    end;

    local procedure MasterRows(MasterTable: Integer) Result: Text
    var
        MasterRef: RecordRef;
    begin
        MasterRef.Open(MasterTable);
        if MasterRef.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(MasterRef.Field(1).Value);
            until MasterRef.Next() = 0;
        Result := '[' + Result + ']';
    end;

    local procedure ChildRows(ChildTable: Integer; ReadRef: Boolean) Result: Text
    var
        ChildRef: RecordRef;
    begin
        ChildRef.Open(ChildTable);
        if ChildRef.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(ChildRef.Field(1).Value) + ':' + Format(ChildRef.Field(3).Value);
                if ReadRef then
                    Result += ':' + Format(ChildRef.Field(2).Value);
            until ChildRef.Next() = 0;
        Result := '[' + Result + ']';
    end;

    [Test]
    procedure RemovedText4_NoRows()
    begin
        Prepare(Database::"RSR RemText Master", Database::"RSR RemText Child", false, false, '');
        RenameAndObserve(Database::"RSR RemText Master", Database::"RSR RemText Child", false, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[ABCDEFGHIJ]');
        Observer.Expect('child rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedText4_OtherFieldsRow()
    begin
        Prepare(Database::"RSR RemText Master", Database::"RSR RemText Child", true, false, '');
        RenameAndObserve(Database::"RSR RemText Master", Database::"RSR RemText Child", false, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[ABCDEFGHIJ]');
        Observer.Expect('child rows', '[1:other]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedInteger_NoRows()
    begin
        Prepare(Database::"RSR RemInt Master", Database::"RSR RemInt Child", false, false, '');
        RenameAndObserve(Database::"RSR RemInt Master", Database::"RSR RemInt Child", false, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[ABCDEFGHIJ]');
        Observer.Expect('child rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedInteger_OtherFieldsRow()
    begin
        Prepare(Database::"RSR RemInt Master", Database::"RSR RemInt Child", true, false, '');
        RenameAndObserve(Database::"RSR RemInt Master", Database::"RSR RemInt Child", false, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[ABCDEFGHIJ]');
        Observer.Expect('child rows', '[1:other]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedText4_RecRef_NoRows()
    begin
        Prepare(Database::"RSR RemText Master", Database::"RSR RemText Child", false, false, '');
        RenameAndObserve(Database::"RSR RemText Master", Database::"RSR RemText Child", true, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[ABCDEFGHIJ]');
        Observer.Expect('child rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedText4_RecRef_OtherFieldsRow()
    begin
        Prepare(Database::"RSR RemText Master", Database::"RSR RemText Child", true, false, '');
        RenameAndObserve(Database::"RSR RemText Master", Database::"RSR RemText Child", true, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[ABCDEFGHIJ]');
        Observer.Expect('child rows', '[1:other]');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedInteger_RecRef_OtherFieldsRow()
    begin
        Prepare(Database::"RSR RemInt Master", Database::"RSR RemInt Child", true, false, '');
        RenameAndObserve(Database::"RSR RemInt Master", Database::"RSR RemInt Child", true, false);
        Observer.Expect('rename', 'no error');
        Observer.Expect('master rows', '[ABCDEFGHIJ]');
        Observer.Expect('child rows', '[1:other]');
        Observer.Verify();
    end;

    [Test]
    procedure PendingText4_NoRows()
    begin
        Prepare(Database::"RSR Pend Master", Database::"RSR Pend Child", false, false, '');
        RenameAndObserve(Database::"RSR Pend Master", Database::"RSR Pend Child", false, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Pend Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure PendingText4_MatchingRow()
    begin
        Prepare(Database::"RSR Pend Master", Database::"RSR Pend Child", true, true, 'AB');
        RenameAndObserve(Database::"RSR Pend Master", Database::"RSR Pend Child", false, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Pend Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[1:other:AB]');
        Observer.Verify();
    end;

    [Test]
    procedure PendingText4_OtherValueRow()
    begin
        Prepare(Database::"RSR Pend Master", Database::"RSR Pend Child", true, true, 'ZZ');
        RenameAndObserve(Database::"RSR Pend Master", Database::"RSR Pend Child", false, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Pend Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[1:other:ZZ]');
        Observer.Verify();
    end;

    [Test]
    procedure LiveText4_NoRows()
    begin
        Prepare(Database::"RSR Live Master", Database::"RSR Live Child", false, false, '');
        RenameAndObserve(Database::"RSR Live Master", Database::"RSR Live Child", false, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Live Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure LiveText4_MatchingRow()
    begin
        Prepare(Database::"RSR Live Master", Database::"RSR Live Child", true, true, 'AB');
        RenameAndObserve(Database::"RSR Live Master", Database::"RSR Live Child", false, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Live Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[1:other:AB]');
        Observer.Verify();
    end;

    [Test]
    procedure LiveText4_OtherValueRow()
    begin
        Prepare(Database::"RSR Live Master", Database::"RSR Live Child", true, true, 'ZZ');
        RenameAndObserve(Database::"RSR Live Master", Database::"RSR Live Child", false, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Live Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[1:other:ZZ]');
        Observer.Verify();
    end;

    [Test]
    procedure LiveText4_BlankValueRow()
    begin
        Prepare(Database::"RSR Live Master", Database::"RSR Live Child", true, false, '');
        RenameAndObserve(Database::"RSR Live Master", Database::"RSR Live Child", false, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Live Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[1:other:]');
        Observer.Verify();
    end;

    [Test]
    procedure LiveText4_RecRef_NoRows()
    begin
        Prepare(Database::"RSR Live Master", Database::"RSR Live Child", false, false, '');
        RenameAndObserve(Database::"RSR Live Master", Database::"RSR Live Child", true, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Live Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure LiveText4_RecRef_MatchingRow()
    begin
        Prepare(Database::"RSR Live Master", Database::"RSR Live Child", true, true, 'AB');
        RenameAndObserve(Database::"RSR Live Master", Database::"RSR Live Child", true, true);
        Observer.Expect('rename', 'error');
        Observer.Expect('error|text', 'The record could not be renamed. A type conversion error occurred while updating reference field RSR Live Child.Ref. The record has data type Code and the referencing field has data type Text.');
        Observer.Expect('error|code', 'InvalidType:StringLengthExceeded');
        Observer.Expect('master rows', '[AB]');
        Observer.Expect('child rows', '[1:other:AB]');
        Observer.Verify();
    end;
}
