// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 84884-84885, test codeunit 84886
// Probe: corpus issue #669 (writer CN), item 51 (microsoft/AL#3875): Rec1.Insert(), then Rec1.TransferFields(Rec2) with the same primary key,
// then Rec1.Modify(). Does Modify raise "Sorry, we have just updated this page" because TransferFields or Copy carry the source row's version?
// Sources: Rec2 built in memory, Rec2 read from the database, Rec2 read and then modified by another variable (Rec1 is then stale), a row of
// another table, TransferFields(Rec2, false), and Record.Copy. The stale Modify without TransferFields is the control.
// Measured (local BC 29, checked by the CI matrix): every case starts from a committed row. In-memory and freshly read sources modify fine. A stale Modify (Commit after the other write) fails with
//   DB:RecordChanged; TransferFields(Newer) with the primary key (the default) and Copy(Newer) make the buffer current, so Modify succeeds;
//   TransferFields(Newer, false) does not, and Modify fails with DB:RecordChanged. A row of another table with the same key transfers and modifies.
// Writer QE (2026-10-20), QE_* tests: TransferFields from ANOTHER table leaves the buffer's SystemId and SystemRowVersion as they
//   were but copies SystemCreatedAt and SystemModifiedAt from the source. A stale buffer stays stale (Modify fails with
//   DB:RecordChanged whether the source row is older, newer or in memory, with or without the key); a current buffer modifies
//   fine even when the source row is older; a buffer that never read the row (only the key set by TransferFields) modifies the
//   stored row, also when another variable changed and committed it. After the Modify the row keeps its own SystemId and
//   SystemCreatedAt and gets a new SystemModifiedAt and SystemRowVersion.
// BC versions: 27, 28, 29

table 84884 "LT CN TF Row"
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

table 84885 "LT CN TF Other"
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

codeunit 84886 "LT CN TF Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prep(var R1: Record "LT CN TF Row")
    var
        Other: Record "LT CN TF Other";
    begin
        R1.DeleteAll();
        Other.DeleteAll();
        R1.Init();
        R1.Id := 1;
        R1.Name := 'first';
        R1.Qty := 1;
        R1.Insert();
        Commit();
    end;

    local procedure NameInDb(): Text
    var
        R: Record "LT CN TF Row";
    begin
        R.Get(1);
        exit(R.Name + '/' + Format(R.Qty));
    end;

    [Test]
    procedure TF_InMemorySource_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Init();
        R2.Id := 1;
        R2.Name := 'mem';
        R2.Qty := 2;
        R1.TransferFields(R2);
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'mem/2');
        Observer.Verify();
    end;

    [Test]
    procedure TF_SourceReadFromDb_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R1.TransferFields(R2);
        R1.Name := 'changed';
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'changed/1');
        Observer.Verify();
    end;

    [Test]
    procedure Control_StaleModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.Name := 'stale';
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure TF_FromNewerCopy_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.TransferFields(R2);
        R1.Qty := 9;
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'second/9');
        Observer.Verify();
    end;

    [Test]
    procedure TF_NoKey_FromNewerCopy_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.TransferFields(R2, false);
        R1.Qty := 9;
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_FromNewerCopy_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R2: Record "LT CN TF Row";
    begin
        Prep(R1);
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
        R1.Copy(R2);
        R1.Qty := 9;
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'second/9');
        Observer.Verify();
    end;

    [Test]
    procedure TF_OtherTable_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        O.Init();
        O.Id := 1;
        O.Name := 'other';
        O.Qty := 3;
        O.Insert();
        Commit();
        O.Get(1);
        R1.TransferFields(O);
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'other/3');
        Observer.Verify();
    end;

    // ── Added by writer QE (2026-10-20): TransferFields from ANOTHER table into a buffer that is stale, current but newer
    // than the source row, or never read, then Modify; and the system fields of the target row after such a Modify.
    // A stale buffer here means: another variable modified the row and committed after this buffer read it.

    local procedure QeInsertOther()
    var
        O: Record "LT CN TF Other";
    begin
        O.Init();
        O.Id := 1;
        O.Name := 'other';
        O.Qty := 3;
        O.Insert();
        Commit();
    end;

    local procedure QeModifyElsewhere()
    var
        R2: Record "LT CN TF Row";
    begin
        R2.Get(1);
        R2.Name := 'second';
        R2.Modify();
        Commit();
    end;

    [Test]
    procedure QE_TF_Other_StaleBuffer_SourceOlder()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        QeInsertOther();
        QeModifyElsewhere();
        O.Get(1);
        R1.TransferFields(O);
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_StaleBuffer_SourceNewer()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        QeModifyElsewhere();
        QeInsertOther();
        O.Get(1);
        R1.TransferFields(O);
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_StaleBuffer_SourceInMemory()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        QeModifyElsewhere();
        O.Init();
        O.Id := 1;
        O.Name := 'mem';
        O.Qty := 4;
        R1.TransferFields(O);
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_NoKey_StaleBuffer_SourceNewer()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        QeModifyElsewhere();
        QeInsertOther();
        O.Get(1);
        R1.TransferFields(O, false);
        asserterror R1.Modify();
        Observer.ObserveError('modify');
        Observer.Observe('db', NameInDb());
        Observer.Expect('modify|text', 'The changes to the LT CN TF Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Expect('db', 'second/1');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_CurrentBuffer_SourceOlder()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        QeInsertOther();
        R1.Get(1);
        R1.Name := 'own';
        R1.Modify();
        Commit();
        O.Get(1);
        R1.TransferFields(O);
        R1.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'other/3');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_TargetNeverRead_SourceFromDb()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R3: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        QeInsertOther();
        O.Get(1);
        R3.TransferFields(O);
        R3.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'other/3');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_TargetNeverRead_SourceInMemory()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R3: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        O.Init();
        O.Id := 1;
        O.Name := 'mem';
        O.Qty := 4;
        R3.TransferFields(O);
        R3.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'mem/4');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_TargetNeverRead_StaleRow_SourceFromDb()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R3: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
    begin
        Prep(R1);
        QeInsertOther();
        QeModifyElsewhere();
        O.Get(1);
        R3.TransferFields(O);
        R3.Modify();
        Observer.Observe('db', NameInDb());
        Observer.Expect('db', 'other/3');
        Observer.Verify();
    end;

    [Test]
    procedure QE_TF_Other_SystemFields_AfterModify()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R4: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
        OwnId: Guid;
        OwnVersion: BigInteger;
        OwnModified: DateTime;
        OwnCreated: DateTime;
    begin
        Prep(R1);
        Sleep(50);
        QeInsertOther();
        R1.Get(1);
        OwnId := R1.SystemId;
        OwnVersion := R1.SystemRowVersion;
        OwnModified := R1.SystemModifiedAt;
        OwnCreated := R1.SystemCreatedAt;
        O.Get(1);
        Observer.Observe('other newer than own (setup)', Format(O.SystemRowVersion > OwnVersion));
        R1.TransferFields(O);
        Observer.Observe('buffer systemid = own', Format(R1.SystemId = OwnId));
        Observer.Observe('buffer systemid = other', Format(R1.SystemId = O.SystemId));
        Observer.Observe('buffer rowversion = own', Format(R1.SystemRowVersion = OwnVersion));
        Observer.Observe('buffer rowversion = other', Format(R1.SystemRowVersion = O.SystemRowVersion));
        Observer.Observe('buffer modifiedat = own', Format(R1.SystemModifiedAt = OwnModified));
        Observer.Observe('buffer modifiedat = other', Format(R1.SystemModifiedAt = O.SystemModifiedAt));
        Observer.Observe('buffer createdat = own', Format(R1.SystemCreatedAt = OwnCreated));
        Observer.Observe('buffer createdat = other', Format(R1.SystemCreatedAt = O.SystemCreatedAt));
        Sleep(50);
        R1.Modify();
        Observer.Observe('after modify buffer rowversion > other', Format(R1.SystemRowVersion > O.SystemRowVersion));
        Observer.Observe('after modify buffer systemid = own', Format(R1.SystemId = OwnId));
        R4.Get(1);
        Observer.Observe('db systemid = own', Format(R4.SystemId = OwnId));
        Observer.Observe('db rowversion > own', Format(R4.SystemRowVersion > OwnVersion));
        Observer.Observe('db rowversion > other', Format(R4.SystemRowVersion > O.SystemRowVersion));
        Observer.Observe('db rowversion = buffer', Format(R4.SystemRowVersion = R1.SystemRowVersion));
        Observer.Observe('db modifiedat > own', Format(R4.SystemModifiedAt > OwnModified));
        Observer.Observe('db modifiedat > other', Format(R4.SystemModifiedAt > O.SystemModifiedAt));
        Observer.Observe('db createdat = own', Format(R4.SystemCreatedAt = OwnCreated));
        Observer.Observe('db createdat = other', Format(R4.SystemCreatedAt = O.SystemCreatedAt));
        Observer.Observe('db', NameInDb());
        Observer.Expect('other newer than own (setup)', 'Yes');
        Observer.Expect('buffer systemid = own', 'Yes');
        Observer.Expect('buffer systemid = other', 'No');
        Observer.Expect('buffer rowversion = own', 'Yes');
        Observer.Expect('buffer rowversion = other', 'No');
        Observer.Expect('buffer modifiedat = own', 'No');
        Observer.Expect('buffer modifiedat = other', 'Yes');
        Observer.Expect('buffer createdat = own', 'No');
        Observer.Expect('buffer createdat = other', 'Yes');
        Observer.Expect('after modify buffer rowversion > other', 'Yes');
        Observer.Expect('after modify buffer systemid = own', 'Yes');
        Observer.Expect('db systemid = own', 'Yes');
        Observer.Expect('db rowversion > own', 'Yes');
        Observer.Expect('db rowversion > other', 'Yes');
        Observer.Expect('db rowversion = buffer', 'Yes');
        Observer.Expect('db modifiedat > own', 'Yes');
        Observer.Expect('db modifiedat > other', 'Yes');
        Observer.Expect('db createdat = own', 'Yes');
        Observer.Expect('db createdat = other', 'No');
        Observer.Expect('db', 'other/3');
        Observer.Verify();
    end;

    // ── Added by writer QH (2026-10-21), al-runtime-rs PR 382 "needs probe": SystemCreatedBy and SystemModifiedBy after a TransferFields
    // from another table, and the four audit fields when the source row was built in memory or is a temporary row.
    // Measured on BC 27.5, 28.5 and 29.0: TransferFields from another table copies all four audit fields from the source as they are.
    // A source built in memory, and a temporary row after Insert, hold blank At fields and null By fields (a temporary Insert stamps
    // nothing), and the buffer gets those blanks. A temporary row filled from a database row keeps that row's stamps. Modify then stamps
    // SystemModifiedAt/By on the buffer and in the database; SystemCreatedAt/By stay blank on the buffer but the database keeps its own.
    local procedure QhAudit(var Observer: Codeunit "Probe Observer"; Name: Text; CreatedAt: DateTime; ModifiedAt: DateTime; CreatedBy: Guid; ModifiedBy: Guid; OwnCreatedAt: DateTime; OwnModifiedAt: DateTime)
    begin
        Observer.Observe(Name + ' createdat blank', Format(CreatedAt = 0DT));
        Observer.Observe(Name + ' createdat = own', Format(CreatedAt = OwnCreatedAt));
        Observer.Observe(Name + ' modifiedat blank', Format(ModifiedAt = 0DT));
        Observer.Observe(Name + ' modifiedat = own', Format(ModifiedAt = OwnModifiedAt));
        Observer.Observe(Name + ' createdby null', Format(IsNullGuid(CreatedBy)));
        Observer.Observe(Name + ' createdby = user', Format(CreatedBy = UserSecurityId()));
        Observer.Observe(Name + ' modifiedby null', Format(IsNullGuid(ModifiedBy)));
        Observer.Observe(Name + ' modifiedby = user', Format(ModifiedBy = UserSecurityId()));
        Observer.Observe(Name + ' createdby = modifiedby', Format(CreatedBy = ModifiedBy));
    end;

    [Test]
    procedure QH_TF_Other_ByFields_SourceFromDb()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
        OwnCreatedBy: Guid;
        OwnModifiedBy: Guid;
    begin
        Prep(R1);
        QeInsertOther();
        R1.Get(1);
        OwnCreatedBy := R1.SystemCreatedBy;
        OwnModifiedBy := R1.SystemModifiedBy;
        O.Get(1);
        // the source and the own row are stamped in the same test, maybe in the same millisecond: the own timestamps are not compared here
        QhAudit(Observer, 'source', O.SystemCreatedAt, O.SystemModifiedAt, O.SystemCreatedBy, O.SystemModifiedBy, 0DT, 0DT);
        R1.TransferFields(O);
        Observer.Observe('buffer createdby = own', Format(R1.SystemCreatedBy = OwnCreatedBy));
        Observer.Observe('buffer createdby = other', Format(R1.SystemCreatedBy = O.SystemCreatedBy));
        Observer.Observe('buffer modifiedby = own', Format(R1.SystemModifiedBy = OwnModifiedBy));
        Observer.Observe('buffer modifiedby = other', Format(R1.SystemModifiedBy = O.SystemModifiedBy));
        Observer.Observe('buffer createdby null', Format(IsNullGuid(R1.SystemCreatedBy)));
        Observer.Observe('buffer modifiedby null', Format(IsNullGuid(R1.SystemModifiedBy)));
        Observer.Expect('source createdat blank', 'No');
        Observer.Expect('source createdat = own', 'No');
        Observer.Expect('source modifiedat blank', 'No');
        Observer.Expect('source modifiedat = own', 'No');
        Observer.Expect('source createdby null', 'No');
        Observer.Expect('source createdby = user', 'Yes');
        Observer.Expect('source modifiedby null', 'No');
        Observer.Expect('source modifiedby = user', 'Yes');
        Observer.Expect('source createdby = modifiedby', 'Yes');
        Observer.Expect('buffer createdby = own', 'Yes');
        Observer.Expect('buffer createdby = other', 'Yes');
        Observer.Expect('buffer modifiedby = own', 'Yes');
        Observer.Expect('buffer modifiedby = other', 'Yes');
        Observer.Expect('buffer createdby null', 'No');
        Observer.Expect('buffer modifiedby null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QH_TF_Other_SourceInMemory_AuditFields()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R4: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
        OwnCreatedAt: DateTime;
        OwnModifiedAt: DateTime;
    begin
        Prep(R1);
        R1.Get(1);
        OwnCreatedAt := R1.SystemCreatedAt;
        OwnModifiedAt := R1.SystemModifiedAt;
        O.Init();
        O.Id := 1;
        O.Name := 'mem';
        O.Qty := 4;
        QhAudit(Observer, 'source', O.SystemCreatedAt, O.SystemModifiedAt, O.SystemCreatedBy, O.SystemModifiedBy, OwnCreatedAt, OwnModifiedAt);
        R1.TransferFields(O);
        QhAudit(Observer, 'buffer', R1.SystemCreatedAt, R1.SystemModifiedAt, R1.SystemCreatedBy, R1.SystemModifiedBy, OwnCreatedAt, OwnModifiedAt);
        Sleep(50);
        R1.Modify();
        QhAudit(Observer, 'buffer after modify', R1.SystemCreatedAt, R1.SystemModifiedAt, R1.SystemCreatedBy, R1.SystemModifiedBy, OwnCreatedAt, OwnModifiedAt);
        R4.Get(1);
        QhAudit(Observer, 'db', R4.SystemCreatedAt, R4.SystemModifiedAt, R4.SystemCreatedBy, R4.SystemModifiedBy, OwnCreatedAt, OwnModifiedAt);
        Observer.Observe('db modifiedat > own', Format(R4.SystemModifiedAt > OwnModifiedAt));
        Observer.Observe('db', NameInDb());
        Observer.Expect('source createdat blank', 'Yes');
        Observer.Expect('source createdat = own', 'No');
        Observer.Expect('source modifiedat blank', 'Yes');
        Observer.Expect('source modifiedat = own', 'No');
        Observer.Expect('source createdby null', 'Yes');
        Observer.Expect('source createdby = user', 'No');
        Observer.Expect('source modifiedby null', 'Yes');
        Observer.Expect('source modifiedby = user', 'No');
        Observer.Expect('source createdby = modifiedby', 'Yes');
        Observer.Expect('buffer createdat blank', 'Yes');
        Observer.Expect('buffer createdat = own', 'No');
        Observer.Expect('buffer modifiedat blank', 'Yes');
        Observer.Expect('buffer modifiedat = own', 'No');
        Observer.Expect('buffer createdby null', 'Yes');
        Observer.Expect('buffer createdby = user', 'No');
        Observer.Expect('buffer modifiedby null', 'Yes');
        Observer.Expect('buffer modifiedby = user', 'No');
        Observer.Expect('buffer createdby = modifiedby', 'Yes');
        Observer.Expect('buffer after modify createdat blank', 'Yes');
        Observer.Expect('buffer after modify createdat = own', 'No');
        Observer.Expect('buffer after modify modifiedat blank', 'No');
        Observer.Expect('buffer after modify modifiedat = own', 'No');
        Observer.Expect('buffer after modify createdby null', 'Yes');
        Observer.Expect('buffer after modify createdby = user', 'No');
        Observer.Expect('buffer after modify modifiedby null', 'No');
        Observer.Expect('buffer after modify modifiedby = user', 'Yes');
        Observer.Expect('buffer after modify createdby = modifiedby', 'No');
        Observer.Expect('db createdat blank', 'No');
        Observer.Expect('db createdat = own', 'Yes');
        Observer.Expect('db modifiedat blank', 'No');
        Observer.Expect('db modifiedat = own', 'No');
        Observer.Expect('db createdby null', 'No');
        Observer.Expect('db createdby = user', 'Yes');
        Observer.Expect('db modifiedby null', 'No');
        Observer.Expect('db modifiedby = user', 'Yes');
        Observer.Expect('db createdby = modifiedby', 'Yes');
        Observer.Expect('db modifiedat > own', 'Yes');
        Observer.Expect('db', 'mem/4');
        Observer.Verify();
    end;

    [Test]
    procedure QH_TF_Other_SourceTemporary_AuditFields()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        R4: Record "LT CN TF Row";
        TempO: Record "LT CN TF Other" temporary;
        OwnCreatedAt: DateTime;
        OwnModifiedAt: DateTime;
    begin
        Prep(R1);
        R1.Get(1);
        OwnCreatedAt := R1.SystemCreatedAt;
        OwnModifiedAt := R1.SystemModifiedAt;
        TempO.Init();
        TempO.Id := 1;
        TempO.Name := 'temp';
        TempO.Qty := 5;
        TempO.Insert();
        QhAudit(Observer, 'source', TempO.SystemCreatedAt, TempO.SystemModifiedAt, TempO.SystemCreatedBy, TempO.SystemModifiedBy, OwnCreatedAt, OwnModifiedAt);
        R1.TransferFields(TempO);
        QhAudit(Observer, 'buffer', R1.SystemCreatedAt, R1.SystemModifiedAt, R1.SystemCreatedBy, R1.SystemModifiedBy, OwnCreatedAt, OwnModifiedAt);
        Sleep(50);
        R1.Modify();
        R4.Get(1);
        QhAudit(Observer, 'db', R4.SystemCreatedAt, R4.SystemModifiedAt, R4.SystemCreatedBy, R4.SystemModifiedBy, OwnCreatedAt, OwnModifiedAt);
        Observer.Observe('db', NameInDb());
        Observer.Expect('source createdat blank', 'Yes');
        Observer.Expect('source createdat = own', 'No');
        Observer.Expect('source modifiedat blank', 'Yes');
        Observer.Expect('source modifiedat = own', 'No');
        Observer.Expect('source createdby null', 'Yes');
        Observer.Expect('source createdby = user', 'No');
        Observer.Expect('source modifiedby null', 'Yes');
        Observer.Expect('source modifiedby = user', 'No');
        Observer.Expect('source createdby = modifiedby', 'Yes');
        Observer.Expect('buffer createdat blank', 'Yes');
        Observer.Expect('buffer createdat = own', 'No');
        Observer.Expect('buffer modifiedat blank', 'Yes');
        Observer.Expect('buffer modifiedat = own', 'No');
        Observer.Expect('buffer createdby null', 'Yes');
        Observer.Expect('buffer createdby = user', 'No');
        Observer.Expect('buffer modifiedby null', 'Yes');
        Observer.Expect('buffer modifiedby = user', 'No');
        Observer.Expect('buffer createdby = modifiedby', 'Yes');
        Observer.Expect('db createdat blank', 'No');
        Observer.Expect('db createdat = own', 'Yes');
        Observer.Expect('db modifiedat blank', 'No');
        Observer.Expect('db modifiedat = own', 'No');
        Observer.Expect('db createdby null', 'No');
        Observer.Expect('db createdby = user', 'Yes');
        Observer.Expect('db modifiedby null', 'No');
        Observer.Expect('db modifiedby = user', 'Yes');
        Observer.Expect('db createdby = modifiedby', 'Yes');
        Observer.Expect('db', 'temp/5');
        Observer.Verify();
    end;

    [Test]
    procedure QH_TF_Other_SourceTemporaryCopiedFromDb_AuditFields()
    var
        Observer: Codeunit "Probe Observer";
        R1: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
        TempO: Record "LT CN TF Other" temporary;
    begin
        Prep(R1);
        QeInsertOther();
        O.Get(1);
        TempO := O;
        TempO.Insert();
        R1.Get(1);
        Observer.Observe('temp createdat = db source', Format(TempO.SystemCreatedAt = O.SystemCreatedAt));
        Observer.Observe('temp modifiedat = db source', Format(TempO.SystemModifiedAt = O.SystemModifiedAt));
        // the source and the own row are stamped in the same test, maybe in the same millisecond: the own timestamps are not compared here
        QhAudit(Observer, 'source', TempO.SystemCreatedAt, TempO.SystemModifiedAt, TempO.SystemCreatedBy, TempO.SystemModifiedBy, 0DT, 0DT);
        R1.TransferFields(TempO);
        Observer.Observe('buffer createdat = db source', Format(R1.SystemCreatedAt = O.SystemCreatedAt));
        Observer.Observe('buffer modifiedat = db source', Format(R1.SystemModifiedAt = O.SystemModifiedAt));
        QhAudit(Observer, 'buffer', R1.SystemCreatedAt, R1.SystemModifiedAt, R1.SystemCreatedBy, R1.SystemModifiedBy, 0DT, 0DT);
        Observer.Expect('temp createdat = db source', 'Yes');
        Observer.Expect('temp modifiedat = db source', 'Yes');
        Observer.Expect('source createdat blank', 'No');
        Observer.Expect('source createdat = own', 'No');
        Observer.Expect('source modifiedat blank', 'No');
        Observer.Expect('source modifiedat = own', 'No');
        Observer.Expect('source createdby null', 'No');
        Observer.Expect('source createdby = user', 'Yes');
        Observer.Expect('source modifiedby null', 'No');
        Observer.Expect('source modifiedby = user', 'Yes');
        Observer.Expect('source createdby = modifiedby', 'Yes');
        Observer.Expect('buffer createdat = db source', 'Yes');
        Observer.Expect('buffer modifiedat = db source', 'Yes');
        Observer.Expect('buffer createdat blank', 'No');
        Observer.Expect('buffer createdat = own', 'No');
        Observer.Expect('buffer modifiedat blank', 'No');
        Observer.Expect('buffer modifiedat = own', 'No');
        Observer.Expect('buffer createdby null', 'No');
        Observer.Expect('buffer createdby = user', 'Yes');
        Observer.Expect('buffer modifiedby null', 'No');
        Observer.Expect('buffer modifiedby = user', 'Yes');
        Observer.Expect('buffer createdby = modifiedby', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QH_TF_Other_TargetInMemory_SourceInMemory_AuditFields()
    var
        Observer: Codeunit "Probe Observer";
        R3: Record "LT CN TF Row";
        O: Record "LT CN TF Other";
        Blank: DateTime;
    begin
        O.Init();
        O.Id := 7;
        R3.TransferFields(O);
        QhAudit(Observer, 'buffer', R3.SystemCreatedAt, R3.SystemModifiedAt, R3.SystemCreatedBy, R3.SystemModifiedBy, Blank, Blank);
        Observer.Expect('buffer createdat blank', 'Yes');
        Observer.Expect('buffer createdat = own', 'Yes');
        Observer.Expect('buffer modifiedat blank', 'Yes');
        Observer.Expect('buffer modifiedat = own', 'Yes');
        Observer.Expect('buffer createdby null', 'Yes');
        Observer.Expect('buffer createdby = user', 'No');
        Observer.Expect('buffer modifiedby null', 'Yes');
        Observer.Expect('buffer modifiedby = user', 'No');
        Observer.Expect('buffer createdby = modifiedby', 'Yes');
        Observer.Verify();
    end;
}
