// Probe writer-c, round 2: "Temporary records and Global Triggers" (docs/probes-needed.md). The corpus pins Insert on a temporary
// record (session/TestEnvironmentUserTenantContracts.al:414-444). Open here: Modify, Delete, Rename, ModifyAll, DeleteAll and
// a RecordRef on a temporary record, with the corpus fixture subscriber (ALTGlobalTriggerSubscriber.al, table "ALT Triggered",
// log "ALT Trigger Log") that enables all four database triggers and raises OnGlobal* events. Observe-only.
// Fixtures: codeunit 69772.

codeunit 69772 "PW Global Triggers Temp Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ClearLog()
    var
        TrigLog: Record "ALT Trigger Log";
    begin
        TrigLog.DeleteAll();
    end;

    local procedure LogNames(): Text
    var
        TrigLog: Record "ALT Trigger Log";
        Result: Text;
    begin
        if TrigLog.FindSet() then
            repeat
                Result += TrigLog.TriggerName + '(' + Format(TrigLog.SourceEntryNo) + ') ';
            until TrigLog.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure TempRecord_InsertModifyDeleteRename_NoEvents()
    var
        Tmp: Record "ALT Triggered" temporary;
    begin
        ClearLog();
        Tmp."Entry No." := 1;
        Tmp.Insert(true);
        Observer.Observe('after_insert', LogNames());
        Tmp.Value := 5;
        Tmp.Modify(true);
        Observer.Observe('after_modify', LogNames());
        Tmp.Rename(2);
        Observer.Observe('after_rename', LogNames());
        Tmp.Delete(true);
        Observer.Observe('after_delete', LogNames());
        Observer.Expect('after_insert', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) ');
        Observer.Expect('after_modify', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) ');
        Observer.Expect('after_rename', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) TABLEONBEFORERENAME(2) TABLEEXTONBEFORERENAME(2) ONRENAME(2) TABLEEXTONRENAME(2) TABLEEXTONAFTERRENAME(2) TABLEONAFTERRENAME(2) ');
        Observer.Expect('after_delete', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) TABLEONBEFORERENAME(2) TABLEEXTONBEFORERENAME(2) ONRENAME(2) TABLEEXTONRENAME(2) TABLEEXTONAFTERRENAME(2) TABLEONAFTERRENAME(2) TABLEONBEFOREDELETE(2) TABLEEXTONBEFOREDELETE(2) ONDELETE(2) TABLEEXTONDELETE(2) TABLEEXTONAFTERDELETE(2) TABLEONAFTERDELETE(2) ');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_ModifyAllDeleteAll_NoEvents()
    var
        Tmp: Record "ALT Triggered" temporary;
    begin
        ClearLog();
        Tmp."Entry No." := 1;
        Tmp.Insert();
        Tmp."Entry No." := 2;
        Tmp.Insert();
        Tmp.ModifyAll(Value, 3, true);
        Observer.Observe('after_modifyall', LogNames());
        Tmp.DeleteAll(true);
        Observer.Observe('after_deleteall', LogNames());
        Observer.Expect('after_modifyall', 'TABLEONBEFOREINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREINSERT(2) TABLEONAFTERINSERT(2) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) TABLEONBEFOREMODIFY(2) TABLEEXTONBEFOREMODIFY(2) ONMODIFY(2) TABLEEXTONMODIFY(2) TABLEEXTONAFTERMODIFY(2) TABLEONAFTERMODIFY(2) ');
        Observer.Expect('after_deleteall', 'TABLEONBEFOREINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREINSERT(2) TABLEONAFTERINSERT(2) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) TABLEONBEFOREMODIFY(2) TABLEEXTONBEFOREMODIFY(2) ONMODIFY(2) TABLEEXTONMODIFY(2) TABLEEXTONAFTERMODIFY(2) TABLEONAFTERMODIFY(2) TABLEONBEFOREDELETE(1) TABLEEXTONBEFOREDELETE(1) ONDELETE(1) TABLEEXTONDELETE(1) TABLEEXTONAFTERDELETE(1) TABLEONAFTERDELETE(1) TABLEONBEFOREDELETE(2) TABLEEXTONBEFOREDELETE(2) ONDELETE(2) TABLEEXTONDELETE(2) TABLEEXTONAFTERDELETE(2) TABLEONAFTERDELETE(2) ');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_ThroughRecordRef_NoEvents()
    var
        Tmp: Record "ALT Triggered" temporary;
        RecRef: RecordRef;
    begin
        ClearLog();
        RecRef.Open(Database::"ALT Triggered", true);
        RecRef.Field(Tmp.FieldNo("Entry No.")).Value := 1;
        RecRef.Insert(true);
        Observer.Observe('after_recref_insert', LogNames());
        RecRef.Field(Tmp.FieldNo(Value)).Value := 4;
        RecRef.Modify(true);
        Observer.Observe('after_recref_modify', LogNames());
        RecRef.Delete(true);
        Observer.Observe('after_recref_delete', LogNames());
        Observer.Expect('after_recref_insert', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) ');
        Observer.Expect('after_recref_modify', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) ');
        Observer.Expect('after_recref_delete', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) TABLEONBEFOREDELETE(1) TABLEEXTONBEFOREDELETE(1) ONDELETE(1) TABLEEXTONDELETE(1) TABLEEXTONAFTERDELETE(1) TABLEONAFTERDELETE(1) ');
        Observer.Verify();
    end;

    [Test]
    procedure RealRecord_AfterTemporaryOnes_StillRaisesEvents()
    var
        Tmp: Record "ALT Triggered" temporary;
        Real: Record "ALT Triggered";
    begin
        ClearLog();
        Tmp."Entry No." := 1;
        Tmp.Insert(true);
        Tmp.Value := 1;
        Tmp.Modify(true);
        Real."Entry No." := 90001;
        Real.Insert(true);
        Real.Value := 2;
        Real.Modify(true);
        Real.Delete(true);
        Observer.Observe('log_after_temp_then_real', LogNames());
        Observer.Expect('log_after_temp_then_real', 'TABLEONBEFOREINSERT(1) TABLEEXTONBEFOREINSERT(1) ONINSERT(1) TABLEEXTONINSERT(1) TABLEEXTONAFTERINSERT(1) TABLEONAFTERINSERT(1) TABLEONBEFOREMODIFY(1) TABLEEXTONBEFOREMODIFY(1) ONMODIFY(1) TABLEEXTONMODIFY(1) TABLEEXTONAFTERMODIFY(1) TABLEONAFTERMODIFY(1) TABLEONBEFOREINSERT(90001) TABLEEXTONBEFOREINSERT(90001) ONINSERT(90001) TABLEEXTONINSERT(90001) ONDATABASEINSERT(90001) TABLEEXTONAFTERINSERT(90001) TABLEONAFTERINSERT(90001) TABLEONBEFOREMODIFY(90001) TABLEEXTONBEFOREMODIFY(90001) ONMODIFY(90001) TABLEEXTONMODIFY(90001) ONDATABASEMODIFY(90001) TABLEEXTONAFTERMODIFY(90001) TABLEONAFTERMODIFY(90001) TABLEONBEFOREDELETE(90001) TABLEEXTONBEFOREDELETE(90001) ONDELETE(90001) TABLEEXTONDELETE(90001) ONDATABASEDELETE(90001) TABLEEXTONAFTERDELETE(90001) TABLEONAFTERDELETE(90001) ');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_CopiedFromReal_ThenWritten()
    var
        Tmp: Record "ALT Triggered" temporary;
        Real: Record "ALT Triggered";
    begin
        ClearLog();
        Real."Entry No." := 90002;
        Real.Insert(false);
        Tmp := Real;
        Tmp.Insert(true);
        Tmp.Value := 9;
        Tmp.Modify(true);
        Observer.Observe('log_temp_copy_of_real', LogNames());
        Real.Delete(false);
        Observer.Expect('log_temp_copy_of_real', 'TABLEONBEFOREINSERT(90002) ONDATABASEINSERT(90002) TABLEONAFTERINSERT(90002) TABLEONBEFOREINSERT(90002) TABLEEXTONBEFOREINSERT(90002) ONINSERT(90002) TABLEEXTONINSERT(90002) TABLEEXTONAFTERINSERT(90002) TABLEONAFTERINSERT(90002) TABLEONBEFOREMODIFY(90002) TABLEEXTONBEFOREMODIFY(90002) ONMODIFY(90002) TABLEEXTONMODIFY(90002) TABLEEXTONAFTERMODIFY(90002) TABLEONAFTERMODIFY(90002) ');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_ShareTable_OfARealRecord_Error()
    var
        Tmp: Record "ALT Triggered" temporary;
        Real: Record "ALT Triggered";
    begin
        asserterror Tmp.Copy(Real, true);
        Observer.ObserveError('copy_share_table');
        Observer.Expect('copy_share_table|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('copy_share_table|code', 'Argument');
        Observer.Verify();
    end;
}
