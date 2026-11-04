// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields
// Scope: in-scope
// Fixtures used: self-contained tables 70520, 70521
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: system fields SystemId, SystemCreatedAt, SystemCreatedBy, SystemModifiedAt, SystemModifiedBy as relations only (null/non-null, stability across reads, Modify, Rename, GetBySystemId, TransferFields, Copy).
// BC versions: 29 (27 and 28 by CI)

table 70520 "LT DbT Sys"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 70521 "LT DbT Sys Copy"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70522 "LT DbT SystemFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prep()
    var
        Rec: Record "LT DbT Sys";
        Cp: Record "LT DbT Sys Copy";
    begin
        Rec.DeleteAll(false);
        Cp.DeleteAll(false);
    end;

    local procedure Add(Id: Integer; Name: Text)
    var
        Rec: Record "LT DbT Sys";
    begin
        Rec.Init();
        Rec.Id := Id;
        Rec.Name := CopyStr(Name, 1, 30);
        Rec.Insert(true);
    end;

    [Test]
    procedure Insert_SystemFieldsSet()
    var
        Rec: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
        NullId: Guid;
    begin
        Prep();
        Rec.Init();
        Rec.Id := 1;
        Observer.Observe('systemid before insert null', Format(Rec.SystemId = NullId));
        Rec.Insert(true);
        Observer.Observe('systemid after insert null', Format(Rec.SystemId = NullId));
        Observer.Observe('created at after insert zero', Format(Rec.SystemCreatedAt = 0DT));
        Observer.Observe('modified at after insert zero', Format(Rec.SystemModifiedAt = 0DT));
        Observer.Observe('created by null', Format(IsNullGuid(Rec.SystemCreatedBy)));
        Observer.Observe('modified by null', Format(IsNullGuid(Rec.SystemModifiedBy)));
        Rec.Get(1);
        Observer.Observe('systemid after get null', Format(IsNullGuid(Rec.SystemId)));
        Observer.Observe('created at after get zero', Format(Rec.SystemCreatedAt = 0DT));
        Observer.Observe('modified at >= created at', Format(Rec.SystemModifiedAt >= Rec.SystemCreatedAt));
        Observer.Observe('created by null after get', Format(IsNullGuid(Rec.SystemCreatedBy)));
        Observer.Observe('modified by null after get', Format(IsNullGuid(Rec.SystemModifiedBy)));
        Observer.Expect('systemid before insert null', 'Yes');
        Observer.Expect('systemid after insert null', 'No');
        Observer.Expect('created at after insert zero', 'No');
        Observer.Expect('modified at after insert zero', 'No');
        Observer.Expect('created by null', 'No');
        Observer.Expect('modified by null', 'No');
        Observer.Expect('systemid after get null', 'No');
        Observer.Expect('created at after get zero', 'No');
        Observer.Expect('modified at >= created at', 'Yes');
        Observer.Expect('created by null after get', 'No');
        Observer.Expect('modified by null after get', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_InsertFalse()
    var
        Rec: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Rec.Id := 1;
        Rec.Insert(false);
        Rec.Get(1);
        Observer.Observe('systemid null', Format(IsNullGuid(Rec.SystemId)));
        Observer.Observe('created at zero', Format(Rec.SystemCreatedAt = 0DT));
        Observer.Observe('modified >= created', Format(Rec.SystemModifiedAt >= Rec.SystemCreatedAt));
        Observer.Expect('systemid null', 'No');
        Observer.Expect('created at zero', 'No');
        Observer.Expect('modified >= created', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_ExplicitSystemId()
    var
        Rec: Record "LT DbT Sys";
        Wanted: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Wanted := CreateGuid();
        Rec.Init();
        Rec.Id := 1;
        Rec.SystemId := Wanted;
        Rec.Insert(true);
        Observer.Observe('kept after insert', Format(Rec.SystemId = Wanted));
        Rec.Get(1);
        Observer.Observe('kept after get', Format(Rec.SystemId = Wanted));
        Observer.Expect('kept after insert', 'No');
        Observer.Expect('kept after get', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Distinct_PerRecord()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        Add(2, 'b');
        A.Get(1);
        B.Get(2);
        Observer.Observe('distinct', Format(A.SystemId <> B.SystemId));
        B.Get(1);
        Observer.Observe('same record equal', Format(A.SystemId = B.SystemId));
        Observer.Expect('distinct', 'Yes');
        Observer.Expect('same record equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Stable_AcrossReads()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        B.Get(1);
        Observer.Observe('two gets equal', Format(A.SystemId = B.SystemId));
        B.Reset();
        B.FindFirst();
        Observer.Observe('findfirst equal', Format(A.SystemId = B.SystemId));
        B.FindLast();
        Observer.Observe('findlast equal', Format(A.SystemId = B.SystemId));
        B.SetRange(Id, 1);
        B.FindSet();
        Observer.Observe('findset equal', Format(A.SystemId = B.SystemId));
        Observer.Observe('created at equal', Format(A.SystemCreatedAt = B.SystemCreatedAt));
        Observer.Observe('created by equal', Format(A.SystemCreatedBy = B.SystemCreatedBy));
        Observer.Expect('two gets equal', 'Yes');
        Observer.Expect('findfirst equal', 'Yes');
        Observer.Expect('findlast equal', 'Yes');
        Observer.Expect('findset equal', 'Yes');
        Observer.Expect('created at equal', 'Yes');
        Observer.Expect('created by equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_KeepsSystemId()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Before: Guid;
        BeforeCreated: DateTime;
        BeforeCreatedBy: Guid;
        BeforeModified: DateTime;
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        Before := A.SystemId;
        BeforeCreated := A.SystemCreatedAt;
        BeforeCreatedBy := A.SystemCreatedBy;
        BeforeModified := A.SystemModifiedAt;
        A.Name := 'changed';
        A.Modify(true);
        Observer.Observe('systemid on variable after modify', Format(A.SystemId = Before));
        B.Get(1);
        Observer.Observe('systemid after modify', Format(B.SystemId = Before));
        Observer.Observe('created at unchanged', Format(B.SystemCreatedAt = BeforeCreated));
        Observer.Observe('created by unchanged', Format(B.SystemCreatedBy = BeforeCreatedBy));
        Observer.Observe('modified at >= before', Format(B.SystemModifiedAt >= BeforeModified));
        Observer.Observe('modified at >= created at', Format(B.SystemModifiedAt >= B.SystemCreatedAt));
        Observer.Expect('systemid on variable after modify', 'Yes');
        Observer.Expect('systemid after modify', 'Yes');
        Observer.Expect('created at unchanged', 'Yes');
        Observer.Expect('created by unchanged', 'Yes');
        Observer.Expect('modified at >= before', 'Yes');
        Observer.Expect('modified at >= created at', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Unchanged()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        A.Modify(true);
        B.Get(1);
        Observer.Observe('systemid', Format(A.SystemId = B.SystemId));
        Observer.Observe('modified at equal', Format(A.SystemModifiedAt = B.SystemModifiedAt));
        Observer.Observe('modified >= created', Format(B.SystemModifiedAt >= B.SystemCreatedAt));
        Observer.Expect('systemid', 'Yes');
        Observer.Expect('modified at equal', 'Yes');
        Observer.Expect('modified >= created', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_KeepsSystemId()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Before: Guid;
        BeforeCreated: DateTime;
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        Before := A.SystemId;
        BeforeCreated := A.SystemCreatedAt;
        A.Rename(2);
        Observer.Observe('systemid on variable', Format(A.SystemId = Before));
        B.Get(2);
        Observer.Observe('systemid after rename', Format(B.SystemId = Before));
        Observer.Observe('created at after rename', Format(B.SystemCreatedAt = BeforeCreated));
        Observer.Observe('modified >= created', Format(B.SystemModifiedAt >= B.SystemCreatedAt));
        Observer.Observe('old key', Format(B.Get(1)));
        Observer.Expect('systemid on variable', 'Yes');
        Observer.Expect('systemid after rename', 'Yes');
        Observer.Expect('created at after rename', 'Yes');
        Observer.Expect('modified >= created', 'Yes');
        Observer.Expect('old key', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetBySystemId_RoundTrip()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Found: Boolean;
        Missing: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        Add(2, 'b');
        A.Get(2);
        Found := B.GetBySystemId(A.SystemId);
        Observer.Observe('found', Format(Found));
        Observer.Observe('id', Format(B.Id));
        Observer.Observe('name', B.Name);
        Missing := CreateGuid();
        Found := B.GetBySystemId(Missing);
        Observer.Observe('missing returns', Format(Found));
        Found := B.GetBySystemId(A.SystemId);
        Observer.Observe('id after refind', Format(B.Id));
        Observer.Expect('found', 'Yes');
        Observer.Expect('id', '2');
        Observer.Expect('name', 'b');
        Observer.Expect('missing returns', 'No');
        Observer.Expect('id after refind', '2');
        Observer.Verify();
    end;

    [Test]
    procedure GetBySystemId_NullGuid()
    var
        B: Record "LT DbT Sys";
        NullId: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        Observer.Observe('null guid returns', Format(B.GetBySystemId(NullId)));
        Observer.Expect('null guid returns', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetBySystemId_AfterRename()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        A.Rename(5);
        Observer.Observe('found', Format(B.GetBySystemId(A.SystemId)));
        Observer.Observe('new key', Format(B.Id));
        Observer.Expect('found', 'Yes');
        Observer.Expect('new key', '5');
        Observer.Verify();
    end;

    [Test]
    procedure GetBySystemId_AfterDelete()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Old: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        Old := A.SystemId;
        A.Delete(true);
        Observer.Observe('found after delete', Format(B.GetBySystemId(Old)));
        Observer.Expect('found after delete', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_BySystemId()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        Add(2, 'b');
        A.Get(2);
        B.SetRange(SystemId, A.SystemId);
        Observer.Observe('count', Format(B.Count()));
        B.FindFirst();
        Observer.Observe('id', Format(B.Id));
        B.Reset();
        B.SetFilter(SystemId, '<>%1', A.SystemId);
        Observer.Observe('count not equal', Format(B.Count()));
        B.Reset();
        B.SetRange(SystemCreatedAt, A.SystemCreatedAt);
        Observer.Observe('same created at count >= 1', Format(B.Count() >= 1));
        Observer.Expect('count', '1');
        Observer.Expect('id', '2');
        Observer.Expect('count not equal', '1');
        Observer.Expect('same created at count >= 1', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TransferFields_SystemFields()
    var
        Src: Record "LT DbT Sys";
        Dst: Record "LT DbT Sys Copy";
        Dst2: Record "LT DbT Sys Copy";
        Dst3: Record "LT DbT Sys Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'src');
        Src.Get(1);
        Dst.TransferFields(Src);
        Observer.Observe('id', Format(Dst.Id));
        Observer.Observe('name', Dst.Name);
        Observer.Observe('systemid default tr', Format(Dst.SystemId = Src.SystemId));
        Dst.Insert(true);
        Dst.Get(1);
        Observer.Observe('systemid after insert equals source', Format(Dst.SystemId = Src.SystemId));
        Observer.Observe('systemid after insert null', Format(IsNullGuid(Dst.SystemId)));
        Dst2.TransferFields(Src, true, true);
        Observer.Observe('systemid with flag', Format(Dst2.SystemId = Src.SystemId));
        Dst3.TransferFields(Src, true, false);
        Observer.Observe('systemid with flag false', Format(Dst3.SystemId = Src.SystemId));
        Observer.Expect('id', '1');
        Observer.Expect('name', 'src');
        Observer.Expect('systemid default tr', 'No');
        Observer.Expect('systemid after insert equals source', 'No');
        Observer.Expect('systemid after insert null', 'No');
        Observer.Expect('systemid with flag', 'No');
        Observer.Expect('systemid with flag false', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_SystemFields()
    var
        A: Record "LT DbT Sys";
        B: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        B.Copy(A);
        Observer.Observe('systemid', Format(B.SystemId = A.SystemId));
        B := A;
        Observer.Observe('assigned systemid', Format(B.SystemId = A.SystemId));
        Observer.Observe('modified at', Format(B.SystemModifiedAt = A.SystemModifiedAt));
        Observer.Expect('systemid', 'Yes');
        Observer.Expect('assigned systemid', 'Yes');
        Observer.Expect('modified at', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Init_ClearsSystemFields()
    var
        A: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        A.Init();
        Observer.Observe('systemid null after init', Format(IsNullGuid(A.SystemId)));
        Observer.Observe('created at zero after init', Format(A.SystemCreatedAt = 0DT));
        Observer.Observe('modified at zero after init', Format(A.SystemModifiedAt = 0DT));
        Observer.Observe('id after init', Format(A.Id));
        Observer.Expect('systemid null after init', 'Yes');
        Observer.Expect('created at zero after init', 'Yes');
        Observer.Expect('modified at zero after init', 'Yes');
        Observer.Expect('id after init', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_SystemFields()
    var
        A: Record "LT DbT Sys";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        A.Get(1);
        Clear(A);
        Observer.Observe('systemid null', Format(IsNullGuid(A.SystemId)));
        Observer.Observe('created at zero', Format(A.SystemCreatedAt = 0DT));
        Observer.Observe('created by null', Format(IsNullGuid(A.SystemCreatedBy)));
        Observer.Expect('systemid null', 'Yes');
        Observer.Expect('created at zero', 'Yes');
        Observer.Expect('created by null', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_SystemFields()
    var
        Tmp: Record "LT DbT Sys" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Tmp.Id := 1;
        Tmp.Insert(true);
        Observer.Observe('systemid null', Format(IsNullGuid(Tmp.SystemId)));
        Observer.Observe('created at zero', Format(Tmp.SystemCreatedAt = 0DT));
        Tmp.Id := 2;
        Tmp.Insert(true);
        Observer.Observe('two rows', Format(Tmp.Count()));
        Observer.Expect('systemid null', 'Yes');
        Observer.Expect('created at zero', 'Yes');
        Observer.Expect('two rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SystemFields_FieldRefs()
    var
        Rec: Record "LT DbT Sys";
        RecRef: RecordRef;
        FRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1, 'a');
        Rec.Get(1);
        RecRef.GetTable(Rec);
        FRef := RecRef.Field(RecRef.SystemIdNo());
        Observer.Observe('systemid via recref', Format(Format(FRef.Value) = Format(Rec.SystemId)));
        Observer.Observe('systemid field type', Format(FRef.Type));
        Observer.Observe('createdat via recref', Format(RecRef.Field(RecRef.SystemCreatedAtNo()).Type));
        Observer.Observe('modifiedat via recref', Format(RecRef.Field(RecRef.SystemModifiedAtNo()).Type));
        Observer.Observe('createdby via recref', Format(RecRef.Field(RecRef.SystemCreatedByNo()).Type));
        Observer.Observe('modifiedby via recref', Format(RecRef.Field(RecRef.SystemModifiedByNo()).Type));
        Observer.Expect('systemid via recref', 'Yes');
        Observer.Expect('systemid field type', 'GUID');
        Observer.Expect('createdat via recref', 'DateTime');
        Observer.Expect('modifiedat via recref', 'DateTime');
        Observer.Expect('createdby via recref', 'GUID');
        Observer.Expect('modifiedby via recref', 'GUID');
        Observer.Verify();
    end;
}
