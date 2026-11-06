// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96960 and 96961, codeunits 96960 to 96968
// Probe: al-runner issue 6924 (reporter waldo). Companion of Y27StaleOtherVarTests.al (same shape, own table so the OnModify subscriber
// below cannot touch the Y27 tests). Row A is inserted through the test's own record variable and the buffer is kept. Between the
// Insert and the end of the test other record variables (the helper codeunit) read or write the row, other rows or another table,
// and Commit is called one to three times (directly or inside Codeunit.Run). At the end the stale buffer validates Description and
// calls Modify. The final write runs inside Codeunit.Run, so the test records whether it was accepted, or the text and code of the
// error, then the buffer, the stored row (Description|Remaining Quantity|Validate Count|Modify Count|xRec Remaining Quantity|
// xRec Description|Hook) and the counts of rows and log rows.
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

codeunit 96962 "LT Y27B Commit Runner"
{
    trigger OnRun()
    begin
        Commit();
    end;
}

// The final write of the stale buffer. W1: Validate(Description, 'Changed') and Modify(true).
codeunit 96963 "LT Y27B Write Validate True"
{
    TableNo = "LT Y27B Row";

    trigger OnRun()
    begin
        Rec.Validate(Description, 'Changed');
        Rec.Modify(true);
    end;
}

// W2: Description := 'Changed' and Modify(false).
codeunit 96964 "LT Y27B Write Plain False"
{
    TableNo = "LT Y27B Row";

    trigger OnRun()
    begin
        Rec.Description := 'Changed';
        Rec.Modify(false);
    end;
}

// W3: Validate(Description, <the value the row already holds>) and Modify(true).
codeunit 96965 "LT Y27B Write Same Value"
{
    TableNo = "LT Y27B Row";

    trigger OnRun()
    begin
        Rec.Validate(Description, 'Original');
        Rec.Modify(true);
    end;
}

// W4: nothing assigned, Modify(true).
codeunit 96966 "LT Y27B Write No Assign"
{
    TableNo = "LT Y27B Row";

    trigger OnRun()
    begin
        Rec.Modify(true);
    end;
}

codeunit 96967 "LT Y27B Stale Insert More"
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

    local procedure Y27BCommitRun(var Observer: Codeunit "Probe Observer"; LabelName: Text)
    begin
        Observer.Observe(LabelName, Format(Codeunit.Run(Codeunit::"LT Y27B Commit Runner")));
    end;

    local procedure Y27BWrite(var Row: Record "LT Y27B Row"; Writer: Integer; var Observer: Codeunit "Probe Observer")
    var
        Stored: Record "LT Y27B Row";
        Log: Record "LT Y27B Log";
        Ran: Boolean;
    begin
        case Writer of
            1:
                Ran := Codeunit.Run(Codeunit::"LT Y27B Write Validate True", Row);
            2:
                Ran := Codeunit.Run(Codeunit::"LT Y27B Write Plain False", Row);
            3:
                Ran := Codeunit.Run(Codeunit::"LT Y27B Write Same Value", Row);
            4:
                Ran := Codeunit.Run(Codeunit::"LT Y27B Write No Assign", Row);
        end;
        if Ran then
            Observer.Observe('write', 'ok')
        else
            Observer.ObserveError('write');
        Observer.Observe('buffer', Y27BFields(Row));
        if Stored.Get('A') then
            Observer.Observe('stored', Y27BFields(Stored))
        else
            Observer.Observe('stored', 'missing');
        Observer.Observe('rows', Format(Stored.Count()));
        Observer.Observe('log', Format(Log.Count()));
        Y27BCleanup();
    end;

    [Test]
    procedure Y27B_2C_BWroteTx2_NothingAfter_W1()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWroteNewTx_W1()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_Nothing_W1()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_3C_BWroteTx2_EmptyTx3()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_3C_EmptyTx2_BWroteTx3()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_3C_BWroteInNone()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Commit();
        Commit();
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_GetOnly()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.GetOnly('A');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_GetOnly()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.GetOnly('A');
        Commit();
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWroteInSameTxAsInsert()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Helper.Post('A', 5);
        Commit();
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWroteInSameTxAsInsert()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Helper.Post('A', 5);
        Commit();
        Commit();
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_3C_BWroteInSameTxAsInsert()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWroteAndInsertsOtherRow()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Helper.InsertOther('B');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWroteAndModifiesOtherRow()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWroteAndInsertsOtherRow()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWroteAndModifiesOtherRow()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_OnlyInsertsOtherRow()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.InsertOther('B');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_OnlyModifiesOtherRow()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWroteAndLogInserted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Helper.InsertLog('Helper');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWroteAndLogInserted()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_OnlyLogInserted()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.InsertLog('Helper');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_OnlyLogInserted()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWroteTwice()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Helper.Post('A', 1);
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_3C_BWroteTwiceInNewTx()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWroteWithOnModifySubscriberWritingLog()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.PostHook('A', 5);
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWroteWithOnModifySubscriberWritingLog()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_SubscriberLogInTx2_NothingAfter()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.PostHook('A', 5);
        Commit();
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_Nothing_ModifyFalse()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWrite(Row, 2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_Nothing_ModifyFalse()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWrite(Row, 2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWrote_ModifyFalse()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Y27BWrite(Row, 2, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWrote_SameValue()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Y27BWrite(Row, 3, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWrote_SameValue()
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
        Y27BWrite(Row, 3, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_Nothing_SameValue()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWrite(Row, 3, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_Nothing_SameValue()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWrite(Row, 3, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_BWrote_NoAssign()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Y27BWrite(Row, 4, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_Nothing_NoAssign()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Y27BWrite(Row, 4, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_Nothing_NoAssign()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Commit();
        Helper.Post('A', 5);
        Commit();
        Y27BWrite(Row, 4, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_Nothing_AssignedFromFreshGet()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_Nothing_AssignedFromFreshGet()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWrote_AssignedFromFreshGet()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_Nothing_TransferFieldsFromFreshGet()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_Nothing_TransferFieldsFromFreshGet()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWrote_TransferFieldsFromFreshGet()
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
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_Nothing_CommitInCodeunitRun()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Y27BCommitRun(Observer, 'commitRun1');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_1C_GetOnly_CommitInCodeunitRun()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Y27BCommitRun(Observer, 'commitRun1');
        Helper.GetOnly('A');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_GetOnly_CommitsInCodeunitRun()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Y27BCommitRun(Observer, 'commitRun1');
        Helper.GetOnly('A');
        Y27BCommitRun(Observer, 'commitRun2');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_Nothing_CommitsInCodeunitRun()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Y27BCommitRun(Observer, 'commitRun1');
        Helper.Post('A', 5);
        Y27BCommitRun(Observer, 'commitRun2');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_3C_BWroteInNone_CommitsInCodeunitRun()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Y27BCommitRun(Observer, 'commitRun1');
        Y27BCommitRun(Observer, 'commitRun2');
        Y27BCommitRun(Observer, 'commitRun3');
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Y27B_2C_BWroteNewTx_CommitsInCodeunitRun()
    var
        Row: Record "LT Y27B Row";
        Observer: Codeunit "Probe Observer";
    begin
        Y27BCleanup();
        Y27BInsert(Row);
        Y27BCommitRun(Observer, 'commitRun1');
        Helper.Post('A', 5);
        Y27BCommitRun(Observer, 'commitRun2');
        Helper.Post('A', 5);
        Y27BWrite(Row, 1, Observer);
        Observer.Finish();
    end;
}
