// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96960 and 96961, codeunits 96960 to 96962
// Probe: al-runner issue 6924 (reporter waldo). Companion of Y27StaleOtherVarTests.al (same shape, own table so the OnModify subscriber
// below cannot touch the Y27 tests). Row A is inserted through the test's own record variable and the buffer is kept. Between the
// Insert and the end of the test other record variables (the helper codeunit) read or write the row, other rows or another table,
// and Commit is called one to three times. At the end the stale buffer validates Description and
// calls Modify. Every scenario is written twice: _Ok expects the write to be accepted, _Err expects an error; only the one that matches
// what BC does is kept. The test records the buffer, the stored row (Description|Remaining Quantity|Validate Count|Modify Count|
// xRec Remaining Quantity|xRec Description|Hook) and the counts of rows and log rows.
// Names: <commits since the Insert>C_<what the other variables did>. BWrote = the helper modified the row (Get, Modify).
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
        procedure Y27B_2C_BWroteTx2_NothingAfter_W1_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
        Commit();
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteTx2_NothingAfter_W1_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteNewTx_W1_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteNewTx_W1_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_W1_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_W1_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteTx2_EmptyTx3_Ok()
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
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteTx2_EmptyTx3_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_EmptyTx2_BWroteTx3_Ok()
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
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_EmptyTx2_BWroteTx3_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteInNone_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteInNone_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Commit();
        Commit();
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_GetOnly_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.GetOnly('A');
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_GetOnly_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.GetOnly('A');
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_GetOnly_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_GetOnly_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.GetOnly('A');
        Commit();
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteInSameTxAsInsert_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Helper.Post('A', 5);
        Commit();
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteInSameTxAsInsert_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Helper.Post('A', 5);
        Commit();
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteInSameTxAsInsert_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Helper.Post('A', 5);
        Commit();
        Commit();
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteInSameTxAsInsert_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteInSameTxAsInsert_Ok()
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
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteInSameTxAsInsert_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteAndInsertsOtherRow_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteAndInsertsOtherRow_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
        Helper.InsertOther('B');
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteAndModifiesOtherRow_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteAndModifiesOtherRow_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteAndInsertsOtherRow_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteAndInsertsOtherRow_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteAndModifiesOtherRow_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteAndModifiesOtherRow_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_OnlyInsertsOtherRow_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.InsertOther('B');
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_OnlyInsertsOtherRow_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.InsertOther('B');
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_OnlyModifiesOtherRow_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_OnlyModifiesOtherRow_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteAndLogInserted_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteAndLogInserted_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
        Helper.InsertLog('Helper');
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteAndLogInserted_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteAndLogInserted_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_OnlyLogInserted_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.InsertLog('Helper');
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_OnlyLogInserted_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.InsertLog('Helper');
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_OnlyLogInserted_Ok()
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
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_OnlyLogInserted_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteTwice_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteTwice_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
        Helper.Post('A', 1);
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteTwiceInNewTx_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_3C_BWroteTwiceInNewTx_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteWithOnModifySubscriberWritingLog_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.PostHook('A', 5);
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWroteWithOnModifySubscriberWritingLog_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.PostHook('A', 5);
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteWithOnModifySubscriberWritingLog_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWroteWithOnModifySubscriberWritingLog_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_SubscriberLogInTx2_NothingAfter_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.PostHook('A', 5);
        Commit();
            Y27BWriteOk(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_SubscriberLogInTx2_NothingAfter_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_ModifyFalse_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteOk(Row, 2, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_ModifyFalse_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteError(Row, 2, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_ModifyFalse_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
        Commit();
            Y27BWriteOk(Row, 2, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_ModifyFalse_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWrote_ModifyFalse_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
            Y27BWriteOk(Row, 2, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWrote_ModifyFalse_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
            Y27BWriteError(Row, 2, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWrote_SameValue_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
            Y27BWriteOk(Row, 3, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWrote_SameValue_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
            Y27BWriteError(Row, 3, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWrote_SameValue_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWrote_SameValue_Err()
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
            Y27BWriteError(Row, 3, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_SameValue_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteOk(Row, 3, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_SameValue_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteError(Row, 3, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_SameValue_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
        Commit();
            Y27BWriteOk(Row, 3, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_SameValue_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWrote_NoAssign_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
            Y27BWriteOk(Row, 4, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_BWrote_NoAssign_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
            Y27BWriteError(Row, 4, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_NoAssign_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteOk(Row, 4, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_NoAssign_Err()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
            Y27BWriteError(Row, 4, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_NoAssign_Ok()
        var
            Row: Record "LT Y27B Row";
            Observer: Codeunit "Probe Observer";
        begin
            Y27BCleanup();
        Y27BInsert(Row);
            Commit();
        Helper.Post('A', 5);
        Commit();
            Y27BWriteOk(Row, 4, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_NoAssign_Err()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_AssignedFromFreshGet_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_AssignedFromFreshGet_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_AssignedFromFreshGet_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_AssignedFromFreshGet_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWrote_AssignedFromFreshGet_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWrote_AssignedFromFreshGet_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_TransferFieldsFromFreshGet_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_1C_Nothing_TransferFieldsFromFreshGet_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_TransferFieldsFromFreshGet_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_Nothing_TransferFieldsFromFreshGet_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWrote_TransferFieldsFromFreshGet_Ok()
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
            Observer.Finish();
        end;
    
        [Test]
        procedure Y27B_2C_BWrote_TransferFieldsFromFreshGet_Err()
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
            Y27BWriteError(Row, 1, Observer);
            Observer.Finish();
        end;
    }
