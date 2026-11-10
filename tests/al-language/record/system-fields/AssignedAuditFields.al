// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields
// Scope: in-scope
// local object: the triggers of table 61801 assign the audit fields and are what is under test; table 61800 is read row by row for its audit fields, so no other test may write to it
// Fixtures used: Probe Observer (codeunit 69160); own tables 61800 and 61801, test codeunit 61802
// Probe (al-runner issue 5207): what BC stores when AL code assigns SystemCreatedAt, SystemCreatedBy, SystemModifiedAt or SystemModifiedBy and
//   then writes the row. Area: the four audit fields crossed with the write (Insert, Modify with no other change, Modify with another field
//   changed, Rename, ModifyAll), the way the value is assigned (field assignment, Validate, FieldRef.Value, Rec := another row,
//   TransferFields), the place (test code, the table's OnInsert and OnModify triggers), a blank value, and a temporary record.
//   Each observation is a kind, never a clock value: 'assigned' (the value the test assigned), 'same as before' (the value the stored row held
//   before the write), 'clock' or 'user' (a stamp BC made), 'blank', or 'other <value>'.
// Next to: record/TestSystemFieldStampsContracts.al and record/PnASystemFields.al (when BC stamps the fields; no test assigns one),
//   record/TestXRecStampFields.al (what xRec holds for the audit fields in the table triggers; no assignment),
//   record/TestBCSystemFieldContracts.al (the By fields hold the user id).
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

table 61800 "REC Audit Assign Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61801 "REC Audit Assign Trig"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; "Assign In OnInsert"; Boolean) { }
        field(4; "Assign In OnModify"; Boolean) { }
        field(5; "Seen Rec"; Text[100]) { }
        field(6; "Seen xRec"; Text[100]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }

    // The triggers note what Rec and xRec hold for SystemCreatedAt and SystemModifiedAt when they start, then assign the fixed value when the row asks for it.
    trigger OnInsert()
    begin
        "Seen Rec" := CopyStr('insert ' + KindOf(Rec.SystemCreatedAt) + '/' + KindOf(Rec.SystemModifiedAt), 1, 100);
        "Seen xRec" := CopyStr('insert ' + KindOf(xRec.SystemCreatedAt) + '/' + KindOf(xRec.SystemModifiedAt), 1, 100);
        if "Assign In OnInsert" then begin
            Rec.SystemCreatedAt := FixedAt();
            Rec.SystemModifiedAt := FixedAt();
        end;
    end;

    trigger OnModify()
    begin
        "Seen Rec" := CopyStr('modify ' + KindOf(Rec.SystemCreatedAt) + '/' + KindOf(Rec.SystemModifiedAt), 1, 100);
        "Seen xRec" := CopyStr('modify ' + KindOf(xRec.SystemCreatedAt) + '/' + KindOf(xRec.SystemModifiedAt), 1, 100);
        if "Assign In OnModify" then begin
            Rec.SystemCreatedAt := FixedAt();
            Rec.SystemModifiedAt := FixedAt();
        end;
    end;

    procedure FixedAt(): DateTime
    begin
        exit(CreateDateTime(20200102D, 120000T));
    end;

    procedure OtherAt(): DateTime
    begin
        exit(CreateDateTime(20210304D, 130000T));
    end;

    local procedure KindOf(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('blank');
        if Value = FixedAt() then
            exit('assigned');
        if Value = OtherAt() then
            exit('assigned by the test');
        if Value > CreateDateTime(20250101D, 0T) then
            exit('clock');
        exit('other ' + Format(Value, 0, 9));
    end;
}

codeunit 61802 "REC Audit Assign Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FixedAt(): DateTime
    begin
        exit(CreateDateTime(20200102D, 120000T));
    end;

    local procedure FixedBy(): Guid
    var
        Id: Guid;
    begin
        Evaluate(Id, '{11111111-2222-3333-4444-555555555555}');
        exit(Id);
    end;

    local procedure AtKind(Value: DateTime; Before: DateTime): Text
    begin
        if Value = 0DT then
            exit('blank');
        if Value = FixedAt() then
            exit('assigned');
        if Value = Before then
            exit('same as before');
        if Value > CreateDateTime(20250101D, 0T) then
            exit('clock');
        exit('other ' + Format(Value, 0, 9));
    end;

    local procedure ByKind(Value: Guid): Text
    begin
        if IsNullGuid(Value) then
            exit('blank');
        if Value = FixedBy() then
            exit('assigned');
        if Value = UserSecurityId() then
            exit('user');
        exit('other');
    end;

    // created at / created by / modified at / modified by
    local procedure Kinds(Row: Record "REC Audit Assign Row"; Before: Record "REC Audit Assign Row"): Text
    begin
        exit(AtKind(Row.SystemCreatedAt, Before.SystemCreatedAt) + ' / ' + ByKind(Row.SystemCreatedBy) + ' / ' +
             AtKind(Row.SystemModifiedAt, Before.SystemModifiedAt) + ' / ' + ByKind(Row.SystemModifiedBy));
    end;

    local procedure Seed(var Row: Record "REC Audit Assign Row")
    begin
        Row.DeleteAll();
        Clear(Row);
        Row."No." := 'A';
        Row.Name := 'first';
        Row.Insert();
        Row.Get('A');
    end;

    local procedure Assign(var Row: Record "REC Audit Assign Row"; Which: Integer)
    begin
        case Which of
            1:
                Row.SystemCreatedAt := FixedAt();
            2:
                Row.SystemCreatedBy := FixedBy();
            3:
                Row.SystemModifiedAt := FixedAt();
            4:
                Row.SystemModifiedBy := FixedBy();
        end;
    end;

    // One cell of the Modify matrix: assign one audit field, change Name or not, Modify, read the buffer and the stored row.
    local procedure ModifyCell(Which: Integer; ChangeName: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        Done: Boolean;
    begin
        Seed(Row);
        Before := Row;
        Sleep(20);
        Assign(Row, Which);
        if ChangeName then
            Row.Name := 'second';
        Observer.Observe('buffer before Modify', Kinds(Row, Before));
        Done := Row.Modify();
        Observer.Observe('Modify returned', Format(Done));
        Observer.Observe('buffer after Modify', Kinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('stored row', Kinds(Stored, Before));
        Observer.Observe('stored Name', Stored.Name);
    end;

    // ---- Insert

    [Test]
    procedure Insert_AllFourAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        Done: Boolean;
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.SystemCreatedAt := FixedAt();
        Row.SystemCreatedBy := FixedBy();
        Row.SystemModifiedAt := FixedAt();
        Row.SystemModifiedBy := FixedBy();
        Observer.Observe('buffer before Insert', Kinds(Row, Before));
        Done := Row.Insert();
        Observer.Observe('Insert returned', Format(Done));
        Observer.Observe('buffer after Insert', Kinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('stored row', Kinds(Stored, Before));
        Observer.Expect('buffer before Insert', 'assigned / assigned / assigned / assigned');
        Observer.Expect('Insert returned', 'Yes');
        Observer.Expect('buffer after Insert', 'clock / user / clock / user');
        Observer.Expect('stored row', 'clock / user / clock / user');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_OnlyCreatedAtAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        Done: Boolean;
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.SystemCreatedAt := FixedAt();
        Done := Row.Insert(true);
        Observer.Observe('Insert(true) returned', Format(Done));
        Observer.Observe('buffer after Insert', Kinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('stored row', Kinds(Stored, Before));
        Observer.Expect('Insert(true) returned', 'Yes');
        Observer.Expect('buffer after Insert', 'clock / user / clock / user');
        Observer.Expect('stored row', 'clock / user / clock / user');
        Observer.Verify();
    end;

    // ---- Modify: one audit field assigned, nothing else changed

    [Test]
    procedure Modify_CreatedAtAssigned_NothingElse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(1, false, Observer);
        Observer.Expect('buffer before Modify', 'assigned / user / same as before / user');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'assigned / user / same as before / user');
        Observer.Expect('stored row', 'same as before / user / same as before / user');
        Observer.Expect('stored Name', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_CreatedByAssigned_NothingElse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(2, false, Observer);
        Observer.Expect('buffer before Modify', 'same as before / assigned / same as before / user');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'same as before / assigned / same as before / user');
        Observer.Expect('stored row', 'same as before / user / same as before / user');
        Observer.Expect('stored Name', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ModifiedAtAssigned_NothingElse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(3, false, Observer);
        Observer.Expect('buffer before Modify', 'same as before / user / assigned / user');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'same as before / user / assigned / user');
        Observer.Expect('stored row', 'same as before / user / same as before / user');
        Observer.Expect('stored Name', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ModifiedByAssigned_NothingElse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(4, false, Observer);
        Observer.Expect('buffer before Modify', 'same as before / user / same as before / assigned');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'same as before / user / same as before / assigned');
        Observer.Expect('stored row', 'same as before / user / same as before / user');
        Observer.Expect('stored Name', 'first');
        Observer.Verify();
    end;

    // ---- Modify: one audit field assigned and Name changed

    [Test]
    procedure Modify_CreatedAtAssigned_NameChanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(1, true, Observer);
        Observer.Expect('buffer before Modify', 'assigned / user / same as before / user');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'assigned / user / clock / user');
        Observer.Expect('stored row', 'same as before / user / clock / user');
        Observer.Expect('stored Name', 'second');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_CreatedByAssigned_NameChanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(2, true, Observer);
        Observer.Expect('buffer before Modify', 'same as before / assigned / same as before / user');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'same as before / assigned / clock / user');
        Observer.Expect('stored row', 'same as before / user / clock / user');
        Observer.Expect('stored Name', 'second');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ModifiedAtAssigned_NameChanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(3, true, Observer);
        Observer.Expect('buffer before Modify', 'same as before / user / assigned / user');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'same as before / user / clock / user');
        Observer.Expect('stored row', 'same as before / user / clock / user');
        Observer.Expect('stored Name', 'second');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ModifiedByAssigned_NameChanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ModifyCell(4, true, Observer);
        Observer.Expect('buffer before Modify', 'same as before / user / same as before / assigned');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('buffer after Modify', 'same as before / user / clock / user');
        Observer.Expect('stored row', 'same as before / user / clock / user');
        Observer.Expect('stored Name', 'second');
        Observer.Verify();
    end;

    // ---- Modify: other values and other ways to assign

    [Test]
    procedure Modify_CreatedAtSetBlank()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        NoUser: Guid;
        Done: Boolean;
    begin
        Seed(Row);
        Before := Row;
        Sleep(20);
        Row.SystemCreatedAt := 0DT;
        Row.SystemCreatedBy := NoUser;
        Done := Row.Modify();
        Observer.Observe('blank, nothing else: Modify returned', Format(Done));
        Observer.Observe('blank, nothing else: buffer', Kinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('blank, nothing else: stored row', Kinds(Stored, Before));
        Row.Get('A');
        Row.SystemCreatedAt := 0DT;
        Row.SystemCreatedBy := NoUser;
        Row.Name := 'second';
        Done := Row.Modify();
        Observer.Observe('blank, Name changed: Modify returned', Format(Done));
        Observer.Observe('blank, Name changed: buffer', Kinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('blank, Name changed: stored row', Kinds(Stored, Before));
        Observer.Expect('blank, nothing else: Modify returned', 'Yes');
        Observer.Expect('blank, nothing else: buffer', 'blank / blank / same as before / user');
        Observer.Expect('blank, nothing else: stored row', 'same as before / user / same as before / user');
        Observer.Expect('blank, Name changed: Modify returned', 'Yes');
        Observer.Expect('blank, Name changed: buffer', 'blank / blank / clock / user');
        Observer.Expect('blank, Name changed: stored row', 'same as before / user / clock / user');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_CreatedAtValidated()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        Done: Boolean;
    begin
        Seed(Row);
        Before := Row;
        Sleep(20);
        Row.Validate(SystemCreatedAt, FixedAt());
        Row.Validate(SystemModifiedAt, FixedAt());
        Row.Validate(Name, 'second');
        Done := Row.Modify(true);
        Observer.Observe('Modify(true) returned', Format(Done));
        Observer.Observe('buffer after Modify', Kinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('stored row', Kinds(Stored, Before));
        Observer.Expect('Modify(true) returned', 'Yes');
        Observer.Expect('buffer after Modify', 'assigned / user / clock / user');
        Observer.Expect('stored row', 'same as before / user / clock / user');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ThroughFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Done: Boolean;
    begin
        Seed(Row);
        Before := Row;
        Sleep(20);
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(RecRef.SystemCreatedAtNo());
        FldRef.Value := FixedAt();
        FldRef := RecRef.Field(RecRef.SystemCreatedByNo());
        FldRef.Value := FixedBy();
        Done := RecRef.Modify();
        Observer.Observe('created pair, nothing else: Modify returned', Format(Done));
        Stored.Get('A');
        Observer.Observe('created pair, nothing else: stored row', Kinds(Stored, Before));
        RecRef.Close();

        Row.Get('A');
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(RecRef.SystemCreatedAtNo());
        FldRef.Value := FixedAt();
        FldRef := RecRef.Field(RecRef.SystemModifiedAtNo());
        FldRef.Value := FixedAt();
        FldRef := RecRef.Field(RecRef.SystemModifiedByNo());
        FldRef.Value := FixedBy();
        FldRef := RecRef.Field(Row.FieldNo(Name));
        FldRef.Value := 'second';
        Done := RecRef.Modify();
        Observer.Observe('three fields, Name changed: Modify returned', Format(Done));
        Stored.Get('A');
        Observer.Observe('three fields, Name changed: stored row', Kinds(Stored, Before));
        Observer.Expect('created pair, nothing else: Modify returned', 'Yes');
        Observer.Expect('created pair, nothing else: stored row', 'same as before / user / same as before / user');
        Observer.Expect('three fields, Name changed: Modify returned', 'Yes');
        Observer.Expect('three fields, Name changed: stored row', 'same as before / user / clock / user');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_ThroughFieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Done: Boolean;
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"REC Audit Assign Row");
        FldRef := RecRef.Field(1);
        FldRef.Value := 'A';
        FldRef := RecRef.Field(RecRef.SystemCreatedAtNo());
        FldRef.Value := FixedAt();
        FldRef := RecRef.Field(RecRef.SystemCreatedByNo());
        FldRef.Value := FixedBy();
        FldRef := RecRef.Field(RecRef.SystemModifiedAtNo());
        FldRef.Value := FixedAt();
        FldRef := RecRef.Field(RecRef.SystemModifiedByNo());
        FldRef.Value := FixedBy();
        Done := RecRef.Insert();
        Observer.Observe('Insert returned', Format(Done));
        Stored.Get('A');
        Observer.Observe('stored row', Kinds(Stored, Before));
        Observer.Expect('Insert returned', 'Yes');
        Observer.Expect('stored row', 'clock / user / clock / user');
        Observer.Verify();
    end;

    // ---- The buffer of another row: Rec := other row and TransferFields, then Modify of the target row

    [Test]
    procedure Modify_BufferCopiedFromAnOlderRow()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "REC Audit Assign Row";
        Target: Record "REC Audit Assign Row";
        TargetBefore: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        Done: Boolean;
    begin
        // Row A is created first, row B later; the buffer of A (with A's audit values) is written over B.
        Seed(Source);
        Sleep(20);
        Target."No." := 'B';
        Target.Name := 'target';
        Target.Insert();
        TargetBefore.Get('B');
        Sleep(20);

        Target := Source;
        Target."No." := 'B';
        Done := Target.Modify();
        Observer.Observe('Rec := other row: Modify returned', Format(Done));
        Stored.Get('B');
        Observer.Observe('Rec := other row: created at', WhoseValue(Stored.SystemCreatedAt, Source.SystemCreatedAt, TargetBefore.SystemCreatedAt));
        Observer.Observe('Rec := other row: modified at', WhoseValue(Stored.SystemModifiedAt, Source.SystemModifiedAt, TargetBefore.SystemModifiedAt));
        Observer.Observe('Rec := other row: stored Name', Stored.Name);
        Observer.Observe('Rec := other row: SystemId is the target''s', Format(Stored.SystemId = TargetBefore.SystemId));

        TargetBefore.Get('B');
        Sleep(20);
        Target.Get('B');
        Target.TransferFields(Source, false);
        Target.Name := 'transferred';
        Done := Target.Modify();
        Observer.Observe('TransferFields(Source, false): Modify returned', Format(Done));
        Stored.Get('B');
        Observer.Observe('TransferFields(Source, false): created at', WhoseValue(Stored.SystemCreatedAt, Source.SystemCreatedAt, TargetBefore.SystemCreatedAt));
        Observer.Observe('TransferFields(Source, false): modified at', WhoseValue(Stored.SystemModifiedAt, Source.SystemModifiedAt, TargetBefore.SystemModifiedAt));
        Observer.Expect('Rec := other row: Modify returned', 'Yes');
        Observer.Expect('Rec := other row: created at', 'the target row''s, as before');
        Observer.Expect('Rec := other row: modified at', 'a new stamp');
        Observer.Expect('Rec := other row: stored Name', 'first');
        Observer.Expect('Rec := other row: SystemId is the target''s', 'Yes');
        Observer.Expect('TransferFields(Source, false): Modify returned', 'Yes');
        Observer.Expect('TransferFields(Source, false): created at', 'the target row''s, as before');
        Observer.Expect('TransferFields(Source, false): modified at', 'a new stamp');
        Observer.Verify();
    end;

    local procedure WhoseValue(Value: DateTime; OfSource: DateTime; OfTarget: DateTime): Text
    begin
        if Value = 0DT then
            exit('blank');
        if Value = OfSource then
            exit('the source row''s');
        if Value = OfTarget then
            exit('the target row''s, as before');
        if Value > OfTarget then
            exit('a new stamp');
        exit('other ' + Format(Value, 0, 9));
    end;

    // ---- Rename and ModifyAll

    [Test]
    procedure Rename_AfterCreatedAtAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
        Done: Boolean;
    begin
        Seed(Row);
        Before := Row;
        Sleep(20);
        Row.SystemCreatedAt := FixedAt();
        Row.SystemCreatedBy := FixedBy();
        Done := Row.Rename('B');
        Observer.Observe('Rename returned', Format(Done));
        Observer.Observe('buffer after Rename', Kinds(Row, Before));
        Observer.Observe('row B exists', Format(Stored.Get('B')));
        Observer.Observe('stored row', Kinds(Stored, Before));
        Observer.Expect('Rename returned', 'Yes');
        Observer.Expect('buffer after Rename', 'assigned / assigned / clock / user');
        Observer.Expect('row B exists', 'Yes');
        Observer.Expect('stored row', 'same as before / user / clock / user');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_CreatedAt()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Row";
        Before: Record "REC Audit Assign Row";
        Stored: Record "REC Audit Assign Row";
    begin
        Seed(Row);
        Before := Row;
        Sleep(20);
        Row.Reset();
        asserterror
        begin
            Row.ModifyAll(SystemCreatedAt, FixedAt());
            Stored.Get('A');
            Error('no error; stored row: %1', Kinds(Stored, Before));
        end;
        Observer.ObserveError('ModifyAll(SystemCreatedAt)');
        asserterror
        begin
            Row.ModifyAll(SystemModifiedAt, FixedAt());
            Stored.Get('A');
            Error('no error; stored row: %1', Kinds(Stored, Before));
        end;
        Observer.ObserveError('ModifyAll(SystemModifiedAt)');
        asserterror
        begin
            Row.ModifyAll(SystemCreatedBy, FixedBy());
            Stored.Get('A');
            Error('no error; stored row: %1', Kinds(Stored, Before));
        end;
        Observer.ObserveError('ModifyAll(SystemCreatedBy)');
        Observer.Expect('ModifyAll(SystemCreatedAt)|text', 'You cannot change the value of the SystemCreatedAt field.\\Table: REC Audit Assign Row');
        Observer.Expect('ModifyAll(SystemCreatedAt)|code', 'DB:Ok');
        Observer.Expect('ModifyAll(SystemModifiedAt)|text', 'You cannot change the value of the SystemModifiedAt field.\\Table: REC Audit Assign Row');
        Observer.Expect('ModifyAll(SystemModifiedAt)|code', 'DB:Ok');
        Observer.Expect('ModifyAll(SystemCreatedBy)|text', 'You cannot change the value of the SystemCreatedBy field.\\Table: REC Audit Assign Row');
        Observer.Expect('ModifyAll(SystemCreatedBy)|code', 'DB:Ok');
        Observer.Verify();
    end;

    // ---- A temporary record

    [Test]
    procedure Temporary_AssignedValuesStay()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "REC Audit Assign Row" temporary;
        TempBefore: Record "REC Audit Assign Row" temporary;
        Done: Boolean;
    begin
        TempRow."No." := 'A';
        TempRow.SystemCreatedAt := FixedAt();
        TempRow.SystemCreatedBy := FixedBy();
        TempRow.SystemModifiedAt := FixedAt();
        TempRow.SystemModifiedBy := FixedBy();
        Done := TempRow.Insert();
        Observer.Observe('Insert returned', Format(Done));
        Clear(TempRow);
        TempRow.Get('A');
        Observer.Observe('row after Insert and Get', Kinds(TempRow, TempBefore));
        TempRow.SystemCreatedAt := 0DT;
        TempRow.Name := 'second';
        Done := TempRow.Modify();
        Observer.Observe('Modify returned', Format(Done));
        Clear(TempRow);
        TempRow.Get('A');
        Observer.Observe('row after created at set blank, Modify and Get', Kinds(TempRow, TempBefore));
        Observer.Expect('Insert returned', 'Yes');
        Observer.Expect('row after Insert and Get', 'assigned / assigned / assigned / assigned');
        Observer.Expect('Modify returned', 'Yes');
        Observer.Expect('row after created at set blank, Modify and Get', 'blank / assigned / assigned / assigned');
        Observer.Verify();
    end;

    // ---- The table's own triggers assign the fields

    local procedure TrigKinds(Row: Record "REC Audit Assign Trig"; Before: Record "REC Audit Assign Trig"): Text
    begin
        exit(AtKind(Row.SystemCreatedAt, Before.SystemCreatedAt) + ' / ' + AtKind(Row.SystemModifiedAt, Before.SystemModifiedAt));
    end;

    [Test]
    procedure OnInsertTrigger_AssignsBothAtFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Trig";
        Before: Record "REC Audit Assign Trig";
        Stored: Record "REC Audit Assign Trig";
        Done: Boolean;
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row."Assign In OnInsert" := true;
        Done := Row.Insert(true);
        Observer.Observe('Insert(true) returned', Format(Done));
        Observer.Observe('buffer after Insert (created at / modified at)', TrigKinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('stored row (created at / modified at)', TrigKinds(Stored, Before));
        Observer.Observe('Rec at the start of OnInsert', Stored."Seen Rec");
        Observer.Observe('xRec at the start of OnInsert', Stored."Seen xRec");
        Observer.Expect('Insert(true) returned', 'Yes');
        Observer.Expect('buffer after Insert (created at / modified at)', 'clock / clock');
        Observer.Expect('stored row (created at / modified at)', 'clock / clock');
        Observer.Expect('Rec at the start of OnInsert', 'insert blank/blank');
        Observer.Expect('xRec at the start of OnInsert', 'insert blank/blank');
        Observer.Verify();
    end;

    [Test]
    procedure OnModifyTrigger_AssignsBothAtFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Trig";
        Before: Record "REC Audit Assign Trig";
        Stored: Record "REC Audit Assign Trig";
        Done: Boolean;
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert(true);
        Row.Get('A');
        Before := Row;
        Sleep(20);
        Row."Assign In OnModify" := true;
        Done := Row.Modify(true);
        Observer.Observe('Modify(true) returned', Format(Done));
        Observer.Observe('buffer after Modify (created at / modified at)', TrigKinds(Row, Before));
        Stored.Get('A');
        Observer.Observe('stored row (created at / modified at)', TrigKinds(Stored, Before));
        Observer.Observe('Rec at the start of OnModify', Stored."Seen Rec");
        Observer.Observe('xRec at the start of OnModify', Stored."Seen xRec");
        Observer.Expect('Modify(true) returned', 'Yes');
        Observer.Expect('buffer after Modify (created at / modified at)', 'assigned / clock');
        Observer.Expect('stored row (created at / modified at)', 'same as before / clock');
        Observer.Expect('Rec at the start of OnModify', 'modify clock/clock');
        Observer.Expect('xRec at the start of OnModify', 'modify clock/clock');
        Observer.Verify();
    end;

    [Test]
    procedure OnModifyTrigger_SeesTheValueTheCallerAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "REC Audit Assign Trig";
        Before: Record "REC Audit Assign Trig";
        Stored: Record "REC Audit Assign Trig";
        Done: Boolean;
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Insert(true);
        Row.Get('A');
        Before := Row;
        Sleep(20);
        Row.SystemCreatedAt := Row.OtherAt();
        Row.SystemModifiedAt := Row.OtherAt();
        Row.Name := 'second';
        Done := Row.Modify(true);
        Observer.Observe('Modify(true) returned', Format(Done));
        Stored.Get('A');
        Observer.Observe('Rec at the start of OnModify', Stored."Seen Rec");
        Observer.Observe('xRec at the start of OnModify', Stored."Seen xRec");
        Observer.Observe('stored created at is the caller''s value', Format(Stored.SystemCreatedAt = Row.OtherAt()));
        Observer.Observe('stored created at is as before', Format(Stored.SystemCreatedAt = Before.SystemCreatedAt));
        Observer.Observe('stored modified at is the caller''s value', Format(Stored.SystemModifiedAt = Row.OtherAt()));
        Observer.Observe('stored modified at is later than before', Format(Stored.SystemModifiedAt > Before.SystemModifiedAt));
        Observer.Expect('Modify(true) returned', 'Yes');
        Observer.Expect('Rec at the start of OnModify', 'modify assigned by the test/assigned by the test');
        Observer.Expect('xRec at the start of OnModify', 'modify assigned by the test/assigned by the test');
        Observer.Expect('stored created at is the caller''s value', 'No');
        Observer.Expect('stored created at is as before', 'Yes');
        Observer.Expect('stored modified at is the caller''s value', 'No');
        Observer.Expect('stored modified at is later than before', 'Yes');
        Observer.Verify();
    end;
}
