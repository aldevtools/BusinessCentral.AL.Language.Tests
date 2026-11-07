// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96960 and 96961, codeunits 96960 to 96962
// Probe: al-runner issue 6924 (reporter waldo). Companion of Y27StaleOtherVarTests.al (same shape, own table so the OnModify subscriber
// below cannot touch the Y27 tests). Row A is inserted through the test's own record variable and the buffer is kept. Between the
// Insert and the end of the test other record variables (the helper codeunit) read or write the row, other rows or another table,
// and Commit is called one to three times. At the end the stale buffer validates Description and
// calls Modify. Each test records the buffer, the stored row (Description|Remaining Quantity|Validate Count|Modify Count|
// xRec Remaining Quantity|xRec Description|Hook) and the counts of rows and log rows. _Accepted tests: the write goes through.
// _Refused tests: it fails with DB:RecordChanged.
// Measured (BC 29.0, stale Modify; the OnModify trigger runs once in both outcomes, the other variable's Hook flag and quantity are
// overwritten when the write is accepted): ACCEPTED when nothing wrote row A after the Insert (nothing, or the helper only read it with
// Get, after one, two or three Commits), when the helper wrote row A in the transaction after the last Commit (once or twice, with
// Modify() or with Modify(true) and an OnModify subscriber that inserts a log row, also together with inserting or modifying another row
// of the table or inserting a log row), and when the helper only inserted or modified another row or a log row after one Commit.
// REFUSED with DB:RecordChanged when the helper wrote row A in a transaction that a Commit closed and wrote nothing to row A in the new one
// (also when the new transaction inserted a log row), and when the helper wrote row A in the same transaction as the Insert. Neither a
// log row nor another row of the table counts as touching row A. The final write may be Modify(true), Modify(false), Modify(true)
// after assigning the value the row already holds, or Modify(true) with nothing assigned: all follow the same rule. A buffer that was
// assigned from a fresh Get (Row := Fresh, or TransferFields) is never refused and writes the fresh row's Remaining Quantity back.
// Names: <Commits since the Insert>C_<what the helper did>_Accepted or _Refused. BWrote = the helper modified the row (Get, Modify).
// BC versions: 27+

table 96960 "LT Y27B Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50])
        {
            trigger OnValidate()
            begin
                "Validate Count" += 1;
            end;
        }
        field(3; "Remaining Quantity"; Decimal) { }
        field(4; "Validate Count"; Integer) { }
        field(5; "Modify Count"; Integer) { }
        field(6; "xRec Remaining Quantity"; Decimal) { }
        field(7; "xRec Description"; Text[50]) { }
        field(8; Hook; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    begin
        "Modify Count" += 1;
        "xRec Remaining Quantity" := xRec."Remaining Quantity";
        "xRec Description" := xRec.Description;
    end;
}

table 96961 "LT Y27B Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Source; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// Every write of the "other variable" goes through a record variable of this codeunit.
codeunit 96960 "LT Y27B Helper"
{
    procedure Post(No: Code[20]; Quantity: Decimal)
    var
        Other: Record "LT Y27B Row";
    begin
        Other.Get(No);
        Other."Remaining Quantity" -= Quantity;
        Other.Modify();
    end;

    // Modify(true) with Hook set: the subscriber in codeunit 96961 inserts a log row.
    procedure PostHook(No: Code[20]; Quantity: Decimal)
    var
        Other: Record "LT Y27B Row";
    begin
        Other.Get(No);
        Other."Remaining Quantity" -= Quantity;
        Other.Hook := true;
        Other.Modify(true);
    end;

    procedure GetOnly(No: Code[20])
    var
        Other: Record "LT Y27B Row";
    begin
        Other.Get(No);
    end;

    procedure InsertOther(No: Code[20])
    var
        Other: Record "LT Y27B Row";
    begin
        Other."No." := No;
        Other.Description := 'Another row';
        Other."Remaining Quantity" := 1;
        Other.Insert();
    end;

    procedure ModifyOther(No: Code[20])
    var
        Other: Record "LT Y27B Row";
    begin
        Other.Get(No);
        Other."Remaining Quantity" += 1;
        Other.Modify();
    end;

    procedure InsertLog(Source: Text[30])
    var
        Log: Record "LT Y27B Log";
    begin
        Log.Source := Source;
        Log.Insert();
    end;
}

codeunit 96961 "LT Y27B Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"LT Y27B Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyRow(var Rec: Record "LT Y27B Row"; var xRec: Record "LT Y27B Row"; RunTrigger: Boolean)
    var
        Log: Record "LT Y27B Log";
    begin
        if Rec.Hook then begin
            Log.Source := 'OnAfterModify';
            Log.Insert();
        end;
    end;
}

codeunit 96962 "LT Y27B Stale Insert More"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y27B Helper";

    local procedure Y27BInsert(var Row: Record "LT Y27B Row")
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Description := 'Original';
        Row."Remaining Quantity" := 100;
        Row.Insert(true);
    end;

    local procedure Y27BCleanup()
    var
        Rows: Record "LT Y27B Row";
        Log: Record "LT Y27B Log";
    begin
        Rows.DeleteAll();
        Log.DeleteAll();
        Commit();
    end;

    local procedure Y27BFields(Row: Record "LT Y27B Row"): Text
    begin
        exit(Row.Description + '|' + Format(Row."Remaining Quantity") + '|' + Format(Row."Validate Count") + '|' +
            Format(Row."Modify Count") + '|' + Format(Row."xRec Remaining Quantity") + '|' + Row."xRec Description" + '|' + Format(Row.Hook));
    end;

    // The final write of the stale buffer. 1: Validate(Description, 'Changed') and Modify(true). 2: Description := 'Changed' and Modify(false).
    // 3: Validate(Description, <the value the row already holds>) and Modify(true). 4: nothing assigned, Modify(true).
    local procedure Y27BDo(var Row: Record "LT Y27B Row"; Writer: Integer)
    begin
        case Writer of
            1:
                begin
                    Row.Validate(Description, 'Changed');
                    Row.Modify(true);
                end;
            2:
                begin
                    Row.Description := 'Changed';
                    Row.Modify(false);
                end;
            3:
                begin
                    Row.Validate(Description, 'Original');
                    Row.Modify(true);
                end;
            4:
                Row.Modify(true);
        end;
    end;

    local procedure Y27BAfter(var Row: Record "LT Y27B Row"; var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "LT Y27B Row";
        Log: Record "LT Y27B Log";
    begin
        Observer.Observe('buffer', Y27BFields(Row));
        if Stored.Get('A') then
            Observer.Observe('stored', Y27BFields(Stored))
        else
            Observer.Observe('stored', 'missing');
        Observer.Observe('rows', Format(Stored.Count()));
        Observer.Observe('log', Format(Log.Count()));
        Y27BCleanup();
    end;

    local procedure Y27BWriteOk(var Row: Record "LT Y27B Row"; Writer: Integer; var Observer: Codeunit "Probe Observer")
    begin
        Y27BDo(Row, Writer);
        Observer.Observe('write', 'ok');
        Y27BAfter(Row, Observer);
    end;

    local procedure Y27BWriteError(var Row: Record "LT Y27B Row"; Writer: Integer; var Observer: Codeunit "Probe Observer")
    begin
        asserterror Y27BDo(Row, Writer);
        Observer.ObserveError('write');
        Y27BAfter(Row, Observer);
    end;

    [Test]
    procedure Y27B_2C_BWroteTx2_NothingAfter_W1_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWroteNewTx_W1_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.Post('A', 5);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_Nothing_W1_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_3C_BWroteTx2_EmptyTx3_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Commit();
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_3C_EmptyTx2_BWroteTx3_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_3C_BWroteInNone_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Commit();
        Commit();
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_GetOnly_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.GetOnly('A');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_GetOnly_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.GetOnly('A');
        Commit();
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWroteInSameTxAsInsert_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Helper.Post('A', 5);
        Commit();
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWroteInSameTxAsInsert_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Helper.Post('A', 5);
        Commit();
        Commit();
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_3C_BWroteInSameTxAsInsert_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Helper.Post('A', 5);
        Commit();
        Commit();
        Commit();
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWroteAndInsertsOtherRow_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Helper.InsertOther('B');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '2');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWroteAndModifiesOtherRow_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Helper.InsertOther('B');
        Commit();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Helper.ModifyOther('B');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '2');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWroteAndInsertsOtherRow_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.Post('A', 5);
        Helper.InsertOther('B');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '2');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWroteAndModifiesOtherRow_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Helper.InsertOther('B');
        Commit();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.Post('A', 5);
        Helper.ModifyOther('B');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '2');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_OnlyInsertsOtherRow_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.InsertOther('B');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '2');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_OnlyModifiesOtherRow_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Helper.InsertOther('B');
        Commit();
        Y27BInsert(Row);
        Commit();
        Helper.ModifyOther('B');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '2');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWroteAndLogInserted_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Helper.InsertLog('Helper');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWroteAndLogInserted_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.Post('A', 5);
        Helper.InsertLog('Helper');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_OnlyLogInserted_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.InsertLog('Helper');
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_OnlyLogInserted_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.InsertLog('Helper');
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWroteTwice_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Helper.Post('A', 1);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_3C_BWroteTwiceInNewTx_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Commit();
        Commit();
        Helper.Post('A', 5);
        Helper.Post('A', 1);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWroteWithOnModifySubscriberWritingLog_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.PostHook('A', 5);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWroteWithOnModifySubscriberWritingLog_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.PostHook('A', 5);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_SubscriberLogInTx2_NothingAfter_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.PostHook('A', 5);
        Commit();
        Y27BWriteError(Row, 1, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Original|95|0|1|95|Original|Yes');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_Nothing_ModifyFalse_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWriteOk(Row, 2, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|0|0|0||No');
        Observer.Expect('stored', 'Changed|100|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_Nothing_ModifyFalse_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWriteError(Row, 2, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Changed|100|0|0|0||No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWrote_ModifyFalse_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Y27BWriteOk(Row, 2, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|0|0|0||No');
        Observer.Expect('stored', 'Changed|100|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWrote_SameValue_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Y27BWriteOk(Row, 3, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Original|100|1|1|100|Original|No');
        Observer.Expect('stored', 'Original|100|1|1|100|Original|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWrote_SameValue_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.Post('A', 5);
        Y27BWriteOk(Row, 3, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Original|100|1|1|100|Original|No');
        Observer.Expect('stored', 'Original|100|1|1|100|Original|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_Nothing_SameValue_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWriteOk(Row, 3, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Original|100|1|1|100|Original|No');
        Observer.Expect('stored', 'Original|100|1|1|100|Original|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_Nothing_SameValue_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWriteError(Row, 3, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Original|100|1|1|100|Original|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_BWrote_NoAssign_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Y27BWriteOk(Row, 4, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Original|100|0|1|100|Original|No');
        Observer.Expect('stored', 'Original|100|0|1|100|Original|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_Nothing_NoAssign_Accepted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWriteOk(Row, 4, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Original|100|0|1|100|Original|No');
        Observer.Expect('stored', 'Original|100|0|1|100|Original|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_Nothing_NoAssign_Refused()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWriteError(Row, 4, Observer);
        Observer.Expect('write|text', 'The changes to the LT Y27B Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\No.=''A''');
        Observer.Expect('write|code', 'DB:RecordChanged');
        Observer.Expect('buffer', 'Original|100|0|1|100|Original|No');
        Observer.Expect('stored', 'Original|95|0|0|0||No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_Nothing_AssignedFromFreshGet_Accepted()
    var
        Row: Record "LT Y27B Row";
        Fresh: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Fresh.Get('A');
        Row := Fresh;
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_Nothing_AssignedFromFreshGet_Accepted()
    var
        Row: Record "LT Y27B Row";
        Fresh: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Fresh.Get('A');
        Row := Fresh;
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|95|1|1|95|Changed|No');
        Observer.Expect('stored', 'Changed|95|1|1|95|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWrote_AssignedFromFreshGet_Accepted()
    var
        Row: Record "LT Y27B Row";
        Fresh: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.Post('A', 5);
        Fresh.Get('A');
        Row := Fresh;
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|90|1|1|90|Changed|No');
        Observer.Expect('stored', 'Changed|90|1|1|90|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_1C_Nothing_TransferFieldsFromFreshGet_Accepted()
    var
        Row: Record "LT Y27B Row";
        Fresh: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Fresh.Get('A');
        Row.TransferFields(Fresh);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('stored', 'Changed|100|1|1|100|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_Nothing_TransferFieldsFromFreshGet_Accepted()
    var
        Row: Record "LT Y27B Row";
        Fresh: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Fresh.Get('A');
        Row.TransferFields(Fresh);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|95|1|1|95|Changed|No');
        Observer.Expect('stored', 'Changed|95|1|1|95|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y27B_2C_BWrote_TransferFieldsFromFreshGet_Accepted()
    var
        Row: Record "LT Y27B Row";
        Fresh: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Helper.Post('A', 5);
        Fresh.Get('A');
        Row.TransferFields(Fresh);
        Y27BWriteOk(Row, 1, Observer);
        Observer.Expect('write', 'ok');
        Observer.Expect('buffer', 'Changed|90|1|1|90|Changed|No');
        Observer.Expect('stored', 'Changed|90|1|1|90|Changed|No');
        Observer.Expect('rows', '1');
        Observer.Expect('log', '0');
        Observer.Verify();
    end;

    // Waldo run 2 (al-runner issue 6924): the exact sequence of the reporter, own table 97250 below.
    //   A: Insert(true), Modify(true) (field Note), no Commit.   B: Get, then an explicit Commit.
    //   Codeunit.Run(97250): Gets the row into its own variable, assigns F1, Modify(true); Codeunit.Run commits at its end.
    //   C: SetRange + FindFirst, assigns F2, Modify(true), no Commit.   A: assigns F3 (or F1), Modify(true) (or Modify(false)).
    // Names: <variant>_Accepted (the final write goes through) and <variant>_Refused (it raises); WA_Sequence has the parameters.
    local procedure WA_Fields(Row: Record "LT WA Stale Row"): Text
    begin
        exit(Row.Note + '|' + Row.F1 + '|' + Row.F2 + '|' + Row.F3);
    end;

    // Everything up to (not including) the final write of A. RunWrites: the Run codeunit assigns F1 and modifies. CWrites: C assigns F2 and modifies.
    local procedure WA_Prepare(var A: Record "LT WA Stale Row"; RunWrites: Boolean; CWrites: Boolean; InitialModify: Boolean)
    var
        B: Record "LT WA Stale Row";
        C: Record "LT WA Stale Row";
        Stored: Record "LT WA Stale Row";
        KeyRow: Record "LT WA Stale Row";
    begin
        Stored.DeleteAll();
        Commit();
        A.Init();
        A."No." := 'A';
        A.Note := 'Orig';
        A.F1 := 'Orig';
        A.F2 := 'Orig';
        A.F3 := 'Orig';
        A.Insert(true);
        if InitialModify then begin
            A.Note := 'AFirst';
            A.Modify(true);
        end;
        B.Get('A');
        Commit();
        KeyRow."No." := 'A';
        KeyRow.Flag := RunWrites;
        Codeunit.Run(Codeunit::"LT WA Stale Run", KeyRow);
        C.SetRange("No.", 'A');
        C.FindFirst();
        if CWrites then begin
            C.F2 := 'FromC';
            C.Modify(true);
        end;
    end;

    // The final write. Final 1: F3 and Modify(true). 2: F1 and Modify(true). 3: F3 and Modify(false).
    local procedure WA_Final(var A: Record "LT WA Stale Row"; Final: Integer)
    begin
        case Final of
            1:
                begin
                    A.F3 := 'FromA';
                    A.Modify(true);
                end;
            2:
                begin
                    A.F1 := 'FromA';
                    A.Modify(true);
                end;
            3:
                begin
                    A.F3 := 'FromA';
                    A.Modify(false);
                end;
        end;
    end;

    local procedure WA_After(var Observer: Codeunit "Probe Observer"; var A: Record "LT WA Stale Row")
    var
        Stored: Record "LT WA Stale Row";
    begin
        Observer.Observe('buffer', WA_Fields(A));
        if Stored.Get('A') then
            Observer.Observe('stored', WA_Fields(Stored))
        else
            Observer.Observe('stored', 'missing');
        Observer.Observe('rows', Format(Stored.Count()));
        Stored.DeleteAll();
        Commit();
    end;

    [Test]
    procedure WA_Stale_Waldo_Full_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, true);
        WA_Final(A, 1);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_Full_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, true);
        asserterror WA_Final(A, 1);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoCWrite_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, true);
        WA_Final(A, 1);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoCWrite_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, true);
        asserterror WA_Final(A, 1);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoRunWrite_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, false, true, true);
        WA_Final(A, 1);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoRunWrite_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, false, true, true);
        asserterror WA_Final(A, 1);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoRunWriteNoCWrite_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, false, false, true);
        WA_Final(A, 1);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoRunWriteNoCWrite_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, false, false, true);
        asserterror WA_Final(A, 1);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoInitialModify_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, false);
        WA_Final(A, 1);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoInitialModify_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, false);
        asserterror WA_Final(A, 1);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoInitialModify_NoCWrite_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, false);
        WA_Final(A, 1);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_NoInitialModify_NoCWrite_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, false);
        asserterror WA_Final(A, 1);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalSameFieldAsRun_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, true);
        WA_Final(A, 2);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalSameFieldAsRun_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, true);
        asserterror WA_Final(A, 2);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalSameFieldAsRun_NoCWrite_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, true);
        WA_Final(A, 2);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalSameFieldAsRun_NoCWrite_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, true);
        asserterror WA_Final(A, 2);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalModifyFalse_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, true);
        WA_Final(A, 3);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalModifyFalse_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, true, true);
        asserterror WA_Final(A, 3);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalModifyFalse_NoCWrite_Accepted()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, true);
        WA_Final(A, 3);
        Observer.Observe('write', 'ok');
        WA_After(Observer, A);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Stale_Waldo_FinalModifyFalse_NoCWrite_Refused()
    var
        A: Record "LT WA Stale Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_Prepare(A, true, false, true);
        asserterror WA_Final(A, 3);
        Observer.ObserveError('write');
        WA_After(Observer, A);
        Observer.Finish();
    end;
}

// local objects of the WA_Stale_Waldo tests (al-runner issue 6924, waldo run 2).
table 97250 "LT WA Stale Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Note; Text[30]) { }
        field(3; F1; Text[30]) { }
        field(4; F2; Text[30]) { }
        field(5; F3; Text[30]) { }
        field(6; Flag; Boolean) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

// Gets the row into its own variable and, when Rec.Flag is set, assigns F1 and calls Modify(true).
codeunit 97250 "LT WA Stale Run"
{
    TableNo = "LT WA Stale Row";

    trigger OnRun()
    var
        Own: Record "LT WA Stale Row";
    begin
        Own.Get(Rec."No.");
        if Rec.Flag then begin
            Own.F1 := 'FromRun';
            Own.Modify(true);
        end;
    end;
}
