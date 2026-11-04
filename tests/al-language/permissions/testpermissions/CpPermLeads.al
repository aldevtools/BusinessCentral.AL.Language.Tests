// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); CpPermObjects.al (85000-85016); Permissions Mock (131006) from the dependency.
// Probe: corpus issue 669 (odd AL behavior leads, part D), items 76 to 89. Each test lowers the effective permissions with
//   Permissions Mock.Set (the named set plus "All Objects") and observes what BC does:
//   76 FieldRef.CalcField / Record.CalcFields without read permission on the CalcFormula table (if, TryFunction),
//   78 RecordRef.Open on the system table Table Information from a Cloud app,
//   80 a codeunit Permissions property with only indirect grants in the user's set, and a direct write next to it,
//   81 a subscriber with a Permissions property that calls a codeunit without one (the read deeper in the call stack),
//   82 the InherentPermissions attribute: inside the method, after it returns, in nested calls,
//   86 ExcludedPermissionSets at run time under the mock.
//   Seen on every leg: a read of a table that has no rows raises no permission error (the *_EmptyTable tests).
//   Not here: `if Codeunit.Run` around the CalcFields. The seed is a write, and `if Codeunit.Run` inside a write transaction is refused
//   first (codeunit/TestCodeunitRunWriteTransaction.al), so the permission error cannot be reached that way.
//   Not here: Permissions Mock.IsStarted() on entry to a test (item 84): it read Yes in one local run and No in the next, so it is no oracle.
// BC versions: 27, 28, 29

codeunit 85018 "LT CP Permission Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Each test: seed the tables (or empty them), lower the permissions with Permissions Mock.Set, run ONE operation inside asserterror
    // through Op(), observe, restore. Op ends with the error 'LT CP ok <value>' when the operation raised nothing, so each observation is
    // either that marker or BC's own error. One operation per test, because asserterror rolls back every write of the test, the seed too.
    // Items: 76 CalcField_*, 80 Indirect_*, 81 Subscriber_*, 82 Inherent_*, 86 Excluded_*.

    [Test]
    procedure CalcField_FieldRefIf_NoRead()
    begin
        RunOp('Empty', true, 1, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger IndirectRead: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure CalcField_RecordIf_NoRead()
    begin
        RunOp('Empty', true, 2, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger IndirectRead: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure CalcField_TryFunction_NoRead()
    begin
        RunOp('Empty', true, 3, 'LT CP ok false: Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger IndirectRead: AL Language Coverage Tests)', 'Dialog');
    end;

    [Test]
    procedure CalcField_RecordIf_NoRead_EmptyTable()
    begin
        RunOp('Empty', false, 2, 'LT CP ok true 0', 'Dialog');
    end;

    [Test]
    procedure CalcField_IndirectRead()
    begin
        RunOp('Indirect', true, 5, 'LT CP ok 2 5', 'Dialog');
    end;

    [Test]
    procedure CalcField_NoMock()
    begin
        RunOp('', true, 5, 'LT CP ok 2 5', 'Dialog');
    end;

    [Test]
    procedure Indirect_WriterInsert()
    begin
        RunOp('Indirect', true, 10, 'LT CP ok 3', 'Dialog');
    end;

    [Test]
    procedure Indirect_WriterModify()
    begin
        RunOp('Indirect', true, 11, 'LT CP ok modified', 'Dialog');
    end;

    [Test]
    procedure Indirect_WriterCount()
    begin
        RunOp('Indirect', true, 12, 'LT CP ok 2', 'Dialog');
    end;

    [Test]
    procedure Indirect_ReadOnlyWriterInsert()
    begin
        RunOp('Indirect', true, 13, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger Insert: AL Language Coverage Tests)', 'DB:ClientInsertDenied');
    end;

    [Test]
    procedure Indirect_DirectInsert()
    begin
        RunOp('Indirect', true, 14, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger Insert: AL Language Coverage Tests)', 'DB:ClientInsertDenied');
    end;

    [Test]
    procedure Indirect_DirectModify()
    begin
        RunOp('Indirect', true, 15, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger Modify: AL Language Coverage Tests)', 'DB:ClientModifyDenied');
    end;

    [Test]
    procedure Indirect_DirectCount()
    begin
        RunOp('Indirect', true, 6, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger Read: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure Indirect_DirectCount_EmptyTable()
    begin
        RunOp('Indirect', false, 6, 'LT CP ok 0', 'Dialog');
    end;

    [Test]
    procedure Indirect_EmptySet_WriterInsert()
    begin
        RunOp('Empty', true, 10, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger IndirectInsert: AL Language Coverage Tests)', 'DB:ClientInsertDenied');
    end;

    [Test]
    procedure Subscriber_ReadInSubscriber()
    begin
        RunOp('Indirect', true, 21, 'LT CP ok mode 1', 'Dialog');
    end;

    [Test]
    procedure Subscriber_ReadInCodeunitWithoutPermissions()
    begin
        RunOp('Indirect', true, 22, 'Sorry, the current permissions prevented the action. (TableData 85003 LT CP Ext Read: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure Subscriber_ReadInCodeunitWithPermissions()
    begin
        RunOp('Indirect', true, 23, 'LT CP ok mode 3', 'Dialog');
    end;

    [Test]
    procedure Subscriber_ReadInInherentPermissionsMethod()
    begin
        RunOp('Indirect', true, 24, 'LT CP ok mode 4', 'Dialog');
    end;

    [Test]
    procedure Subscriber_EmptySet_ReadInSubscriber()
    begin
        RunOp('Empty', true, 21, 'Sorry, the current permissions prevented the action. (TableData 85003 LT CP Ext IndirectRead: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure Subscriber_ReaderCalledDirectly()
    begin
        RunOp('Indirect', true, 25, 'Sorry, the current permissions prevented the action. (TableData 85003 LT CP Ext Read: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure Inherent_PlainMethod()
    begin
        RunOp('Empty', true, 31, 'Sorry, the current permissions prevented the action. (TableData 85004 LT CP Secret Read: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure Inherent_PlainMethod_EmptyTable()
    begin
        RunOp('Empty', false, 31, 'LT CP ok 0', 'Dialog');
    end;

    [Test]
    procedure Inherent_AttributeMethod()
    begin
        RunOp('Empty', true, 32, 'LT CP ok 2', 'Dialog');
    end;

    [Test]
    procedure Inherent_AttributeThenPlain()
    begin
        RunOp('Empty', true, 33, 'Sorry, the current permissions prevented the action. (TableData 85004 LT CP Secret Read: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure Inherent_NestedSameCodeunit()
    begin
        RunOp('Empty', true, 34, 'LT CP ok 2', 'Dialog');
    end;

    [Test]
    procedure Inherent_NestedOtherCodeunit()
    begin
        RunOp('Empty', true, 35, 'LT CP ok 2', 'Dialog');
    end;

    [Test]
    procedure Excluded_FullSetCount()
    begin
        RunOp('Full', true, 6, 'LT CP ok 2', 'Dialog');
    end;

    [Test]
    procedure Excluded_ExclSetCount()
    begin
        RunOp('Excl', true, 6, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger Read: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    [Test]
    procedure Excluded_ExclSetInsert()
    begin
        RunOp('Excl', true, 14, 'LT CP ok ', 'Dialog');
    end;

    [Test]
    procedure Excluded_EmptySetCount()
    begin
        RunOp('Empty', true, 6, 'Sorry, the current permissions prevented the action. (TableData 85000 LT CP Ledger Read: AL Language Coverage Tests)', 'DB:ClientReadDenied');
    end;

    // ---- item 78: Table Information through a RecordRef from a Cloud app ----

    [Test]
    procedure RecordRefOpen_TableInformation()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        asserterror RecRef.Open(2000000028);
        Observer.ObserveError('open_2000000028');
        Observer.Expect('open_2000000028|text', 'You cannot open record 2000000028 from a RecordRef data type when you are using target Cloud.');
        Observer.Expect('open_2000000028|code', 'NotAllowedForCompilationTarget');
        Observer.Verify();
    end;

    local procedure RunOp(SetName: Text; WithRows: Boolean; Which: Integer; ExpectedText: Text; ExpectedCode: Text)
    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        WasStarted: Boolean;
    begin
        Seed(WithRows);
        WasStarted := StartMock(Mock);
        if SetName <> '' then
            Mock.Set(CopyStr('LT CP ' + SetName, 1, 20));
        asserterror Op(Which);
        Observer.ObserveError('op');
        RestoreMock(Mock, WasStarted);
        Observer.Expect('op|text', ExpectedText);
        Observer.Expect('op|code', ExpectedCode);
        Observer.Verify();
    end;

    local procedure Seed(WithRows: Boolean)
    var
        Ledger: Record "LT CP Ledger";
        Item: Record "LT CP Item";
        Ext: Record "LT CP Ext";
        Secret: Record "LT CP Secret";
    begin
        Ledger.DeleteAll();
        Item.DeleteAll();
        Ext.DeleteAll();
        Secret.DeleteAll();
        if not WithRows then
            exit;
        Ledger."Entry No." := 1;
        Ledger.Amount := 2;
        Ledger.Insert();
        Ledger."Entry No." := 2;
        Ledger.Amount := 3;
        Ledger.Insert();
        Item."Entry No." := 1;
        Item.Insert();
        Ext."Entry No." := 1;
        Ext.Insert();
        Secret."Entry No." := 1;
        Secret.Insert();
        Secret."Entry No." := 2;
        Secret.Insert();
    end;

    local procedure Op(Which: Integer)
    var
        Ledger: Record "LT CP Ledger";
        Host: Record "LT CP Flow Host";
        Item: Record "LT CP Item";
        Writer: Codeunit "LT CP Writer";
        ReadOnlyWriter: Codeunit "LT CP Writer Read Only";
        Reader: Codeunit "LT CP Reader";
        Inherent: Codeunit "LT CP Inherent";
        RecRef: RecordRef;
        FRef: FieldRef;
        Result: Text;
    begin
        case Which of
            1:
                begin
                    RecRef.Open(Database::"LT CP Flow Host");
                    FRef := RecRef.Field(2);
                    if FRef.CalcField() then
                        Result := 'true ' + Format(FRef.Value())
                    else
                        Result := 'false';
                end;
            2:
                if Host.CalcFields("Ledger Count") then
                    Result := 'true ' + Format(Host."Ledger Count")
                else
                    Result := 'false';
            3:
                if TryCalcFields(Host) then
                    Result := 'true ' + Format(Host."Ledger Count")
                else
                    Result := 'false: ' + GetLastErrorText();
            4:
                Result := Format(Host.Count());
            5:
                begin
                    Host.CalcFields("Ledger Count", "Ledger Sum");
                    Result := Format(Host."Ledger Count") + ' ' + Format(Host."Ledger Sum");
                end;
            6:
                Result := Format(Ledger.Count());
            10:
                begin
                    Writer.InsertRow(10);
                    Result := Format(Writer.CountRows());
                end;
            11:
                begin
                    Writer.ModifyRow(1, 9);
                    Result := 'modified';
                end;
            12:
                Result := Format(Writer.CountRows());
            13:
                ReadOnlyWriter.InsertRow(13);
            14:
                begin
                    Ledger."Entry No." := 14;
                    Ledger.Insert();
                end;
            15:
                begin
                    Ledger."Entry No." := 1;
                    Ledger.Amount := 15;
                    Ledger.Modify();
                end;
            21, 22, 23, 24:
                begin
                    Item.Get(1);
                    Item.Mode := Which - 20;
                    Item.Modify();
                    Result := 'mode ' + Format(Item.Mode);
                end;
            25:
                Reader.ReadExt();
            31, 33:
                begin
                    if Which = 33 then
                        Result := Format(Inherent.CountInherent()) + ' then ';
                    Result += Format(Inherent.CountPlain());
                end;
            32:
                Result := Format(Inherent.CountInherent());
            34:
                Result := Format(Inherent.CountNested());
            35:
                Result := Format(Inherent.CountViaOther());
            36:
                Result := Format(Inherent.CountPlain());
        end;
        Error('LT CP ok %1', Result);
    end;

    [TryFunction]
    local procedure TryCalcFields(var Host: Record "LT CP Flow Host")
    begin
        Host.CalcFields("Ledger Count");
    end;

    local procedure StartMock(var Mock: Codeunit "Permissions Mock") WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(var Mock: Codeunit "Permissions Mock"; WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
