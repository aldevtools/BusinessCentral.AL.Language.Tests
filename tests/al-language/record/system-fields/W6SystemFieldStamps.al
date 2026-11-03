// Batch 6, md:86 [System fields]: what is open after record/TestSystemFieldStampsContracts.al is
//  (a) rows that a rename of ANOTHER table re-keys (propagation): is the modified pair stamped, with what, and is the created pair kept;
//  (b) the "strictly later than the previous stamp" rule: two writes in a row, with and without a pause.
// Observe-only. Own tables 67303 (parent), 67304 (child with the parent code in its primary key), 67305 (child with the parent code outside the key).
// Timing: the (b) tests depend on the clock of the tier; the publisher may Discard them.

table 67303 "W6 SF Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 67304 "W6 SF Child Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Parent; Code[10]) { TableRelation = "W6 SF Parent".Code; }
        field(2; Id; Integer) { }
        field(3; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Parent, Id) { Clustered = true; }
    }
}

table 67305 "W6 SF Child Plain"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Parent; Code[10]) { TableRelation = "W6 SF Parent".Code; }
        field(3; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67306 "W6 System Field Stamps"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Parent: Record "W6 SF Parent";
        ChildKey: Record "W6 SF Child Key";
        ChildPlain: Record "W6 SF Child Plain";
    begin
        ChildKey.DeleteAll();
        ChildPlain.DeleteAll();
        Parent.DeleteAll();
    end;

    [Test]
    procedure Rename_Propagation_ChildNotInKey_Stamp()
    var
        Parent: Record "W6 SF Parent";
        Child: Record "W6 SF Child Plain";
        CreatedBefore: DateTime;
        ModifiedBefore: DateTime;
        ParentModifiedBefore: DateTime;
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Parent.Code := 'P1';
        Parent.Insert();
        Child.Id := 1;
        Child.Parent := 'P1';
        Child.Insert();
        Sleep(60);
        Child.Get(1);
        CreatedBefore := Child.SystemCreatedAt;
        ModifiedBefore := Child.SystemModifiedAt;
        Parent.Get('P1');
        ParentModifiedBefore := Parent.SystemModifiedAt;

        Parent.Rename('P2');

        Child.Get(1);
        Parent.Get('P2');
        Observer.Observe('child_parent_after_rename', Child.Parent);
        Observer.Observe('child_created_unchanged', Format(Child.SystemCreatedAt = CreatedBefore));
        Observer.Observe('child_modified_later', Format(Child.SystemModifiedAt > ModifiedBefore));
        Observer.Observe('child_modified_by_is_session_user', Format(Child.SystemModifiedBy = UserSecurityId()));
        Observer.Observe('child_modified_equals_parent_modified', Format(Child.SystemModifiedAt = Parent.SystemModifiedAt));
        Observer.Observe('parent_modified_later', Format(Parent.SystemModifiedAt > ParentModifiedBefore));
        Observer.Expect('child_parent_after_rename', 'P2');
        Observer.Expect('child_created_unchanged', 'Yes');
        Observer.Expect('child_modified_later', 'Yes');
        Observer.Expect('child_modified_by_is_session_user', 'Yes');
        Observer.Expect('child_modified_equals_parent_modified', 'No');
        Observer.Expect('parent_modified_later', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_Propagation_ChildInKey_Stamp()
    var
        Parent: Record "W6 SF Parent";
        Child: Record "W6 SF Child Key";
        CreatedBefore: DateTime;
        ModifiedBefore: DateTime;
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Parent.Code := 'P1';
        Parent.Insert();
        Child.Parent := 'P1';
        Child.Id := 1;
        Child.Insert();
        Sleep(60);
        Child.Get('P1', 1);
        CreatedBefore := Child.SystemCreatedAt;
        ModifiedBefore := Child.SystemModifiedAt;

        Parent.Get('P1');
        Parent.Rename('P2');

        Observer.Observe('old_key_found', Format(Child.Get('P1', 1)));
        Observer.Observe('new_key_found', Format(Child.Get('P2', 1)));
        Observer.Observe('child_created_unchanged', Format(Child.SystemCreatedAt = CreatedBefore));
        Observer.Observe('child_modified_later', Format(Child.SystemModifiedAt > ModifiedBefore));
        Observer.Observe('child_modified_by_is_session_user', Format(Child.SystemModifiedBy = UserSecurityId()));
        Observer.Expect('old_key_found', 'No');
        Observer.Expect('new_key_found', 'Yes');
        Observer.Expect('child_created_unchanged', 'Yes');
        Observer.Expect('child_modified_later', 'Yes');
        Observer.Expect('child_modified_by_is_session_user', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_ParentRow_KeepsSystemIdAndCreatedPair()
    var
        Parent: Record "W6 SF Parent";
        IdBefore: Guid;
        CreatedBefore: DateTime;
        ModifiedBefore: DateTime;
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Parent.Code := 'P1';
        Parent.Insert();
        Sleep(60);
        Parent.Get('P1');
        IdBefore := Parent.SystemId;
        CreatedBefore := Parent.SystemCreatedAt;
        ModifiedBefore := Parent.SystemModifiedAt;

        Parent.Rename('P2');

        Observer.Observe('system_id_kept', Format(Parent.SystemId = IdBefore));
        Observer.Observe('created_kept', Format(Parent.SystemCreatedAt = CreatedBefore));
        Observer.Observe('modified_later', Format(Parent.SystemModifiedAt > ModifiedBefore));
        Observer.Observe('modified_by_is_session_user', Format(Parent.SystemModifiedBy = UserSecurityId()));
        Observer.Expect('system_id_kept', 'Yes');
        Observer.Expect('created_kept', 'Yes');
        Observer.Expect('modified_later', 'Yes');
        Observer.Expect('modified_by_is_session_user', 'Yes');
        Observer.Verify();
    end;

#if BC29PLUS // the four user-name system fields exist from BC 29 (metadata/W6FieldKeyRows.al pins the field lists per version)
    // ---- Added by writer bs (corpus issue #668, item 80): table 83157 "LT BS Opt Row" in tableextension/lt-bs-tableext-leads/BsObjects.al ----

    local procedure BsSystemNameFields(var RecRef: RecordRef; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        FieldRec: Record Field;
        UserRec: Record User;
        FRef: FieldRef;
        Names: List of [Text];
        FieldName: Text;
        FullName: Text;
    begin
        if UserRec.Get(UserSecurityId()) then
            FullName := UserRec."Full Name";
        Names.Add('SystemCreatedByUserName');
        Names.Add('SystemCreatedByFullName');
        Names.Add('SystemModifiedByUserName');
        Names.Add('SystemModifiedByFullName');
        foreach FieldName in Names do begin
            FieldRec.SetRange(TableNo, RecRef.Number());
            FieldRec.SetRange(FieldName, FieldName);
            if not FieldRec.FindFirst() then
                Observer.Observe(Prefix + FieldName, 'missing')
            else begin
                FRef := RecRef.Field(FieldRec."No.");
                if FRef.Class() = FieldClass::FlowField then
                    FRef.CalcField();
                Observer.Observe(Prefix + FieldName, Format(FieldRec."No.") + '|' + Format(FieldRec.Class) + '|' + Format(FieldRec.Type) + '|' + Format(FieldRec.Len)
                    + '|is_user_id=' + Format(Format(FRef.Value()) = UserId()) + '|is_full_name=' + Format(Format(FRef.Value()) = FullName)
                    + '|blank=' + Format(Format(FRef.Value()) = ''));
            end;
        end;
    end;

    [Test]
    procedure UserNameSystemFields_NormalAndTemporaryRecord()
    // CLAIM (issue #668 item 80): BC 29 adds SystemCreatedByUserName, SystemCreatedByFullName, SystemModifiedByUserName and
    // SystemModifiedByFullName. Per field: number, class, type, length, and whether the value after Insert equals UserId() or the user's
    // full name, on a normal and on a temporary record.
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BS Opt Row";
        TempRow: Record "LT BS Opt Row" temporary;
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        RecRef.GetTable(Row);
        BsSystemNameFields(RecRef, 'normal_', Observer);
        TempRow.Id := 1;
        TempRow.Insert();
        TempRow.Get(1);
        RecRef.GetTable(TempRow);
        BsSystemNameFields(RecRef, 'temporary_', Observer);
        Row.DeleteAll();
        Observer.Expect('normal_SystemCreatedByUserName', '2000000005|FlowField|Text|50|is_user_id=Yes|is_full_name=No|blank=No');
        Observer.Expect('normal_SystemCreatedByFullName', '2000000006|FlowField|Text|80|is_user_id=No|is_full_name=Yes|blank=No');
        Observer.Expect('normal_SystemModifiedByUserName', '2000000007|FlowField|Text|50|is_user_id=Yes|is_full_name=No|blank=No');
        Observer.Expect('normal_SystemModifiedByFullName', '2000000008|FlowField|Text|80|is_user_id=No|is_full_name=Yes|blank=No');
        Observer.Expect('temporary_SystemCreatedByUserName', '2000000005|FlowField|Text|50|is_user_id=No|is_full_name=No|blank=Yes');
        Observer.Expect('temporary_SystemCreatedByFullName', '2000000006|FlowField|Text|80|is_user_id=No|is_full_name=No|blank=Yes');
        Observer.Expect('temporary_SystemModifiedByUserName', '2000000007|FlowField|Text|50|is_user_id=No|is_full_name=No|blank=Yes');
        Observer.Expect('temporary_SystemModifiedByFullName', '2000000008|FlowField|Text|80|is_user_id=No|is_full_name=No|blank=Yes');
        Observer.Verify();
    end;
#endif
}
