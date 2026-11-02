// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93810, codeunits 93811-93813 (writer Y71, gap cycle 7 spec G7-03)
// Probe: `if not R.Insert() then R.Modify();` when the row was already written, in the shapes Microsoft code uses for request records:
//        a buffer read before and the row changed through a second variable (with and without a Commit between), a fresh buffer that was
//        never read, Insert(true) and Modify(true) (which triggers run), a ModifyAll in place of the second variable's Modify, a
//        row deleted through the second variable, and a temporary table with both variables on the same buffer. Each scenario runs inside a helper codeunit started with Codeunit.Run, so a
//        Modify that raises is observed (a TryFunction may not write). Per scenario: the Insert result, whether the Modify raised (text and
//        code), the stored row, the trigger and event log, the buffer's Qty after the Modify.

table 93810 "LT Y71 MI Tab"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT Y71 MI Log";
    begin
        Log.Add('OnInsert');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT Y71 MI Log";
    begin
        Log.Add('OnModify');
    end;
}

table 93838 "LT Y71 MI Blob Tab"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Data; Blob) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 93811 "LT Y71 MI Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ',';
        Lines += Line;
    end;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Text(): Text
    begin
        exit(Lines);
    end;
}

codeunit 93812 "LT Y71 MI Helper"
{
    EventSubscriberInstance = Manual;

    var
        Mode: Integer;
        Notes: Text;
        CommitAtEnd: Boolean;

    procedure SetMode(NewMode: Integer; WithCommit: Boolean)
    begin
        Mode := NewMode;
        Notes := '';
        CommitAtEnd := WithCommit;
    end;

    procedure GetNotes(): Text
    begin
        exit(Notes);
    end;

    local procedure Note(Line: Text)
    begin
        if Notes <> '' then
            Notes += ',';
        Notes += Line;
    end;

    local procedure YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('Yes');
        exit('No');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y71 MI Tab", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "LT Y71 MI Tab"; var xRec: Record "LT Y71 MI Tab"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT Y71 MI Log";
    begin
        Log.Add('BeforeModify:' + YesNo(RunTrigger));
    end;

    trigger OnRun()
    var
        R: Record "LT Y71 MI Tab";
        R2: Record "LT Y71 MI Tab";
        RB: Record "LT Y71 MI Blob Tab";
        RB2: Record "LT Y71 MI Blob Tab";
        Done: Boolean;
    begin
        case Mode of
            21:
                begin
                    // the table with a BLOB field: read before, row changed elsewhere
                    RB.Get('A');
                    RB2.Get('A');
                    RB2.Qty := 2;
                    RB2.Modify();
                    RB.Name := 'x';
                    RB.Qty := 5;
                    Done := RB.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        RB.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(RB.Qty));
                end;
            23:
                begin
                    // the table with a BLOB field: a buffer that was never read
                    RB2.Get('A');
                    RB2.Qty := 2;
                    RB2.Modify();
                    RB.Init();
                    RB."No." := 'A';
                    RB.Name := 'x';
                    RB.Qty := 5;
                    Done := RB.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        RB.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(RB.Qty));
                end;
            1:
                begin
                    // read before, row changed elsewhere, committed before the read
                    R.Get('A');
                    R2.Get('A');
                    R2.Qty := 2;
                    R2.Modify();
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        R.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
            2:
                begin
                    // a Commit between the other variable's Modify and the Insert
                    R.Get('A');
                    R2.Get('A');
                    R2.Qty := 2;
                    R2.Modify();
                    Commit();
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        R.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
            3:
                begin
                    // a buffer that was never read
                    R2.Get('A');
                    R2.Qty := 2;
                    R2.Modify();
                    R.Init();
                    R."No." := 'A';
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        R.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
            4:
                begin
                    R.Get('A');
                    R2.Get('A');
                    R2.Qty := 2;
                    R2.Modify();
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert(true);
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        R.Modify(true);
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
            5:
                begin
                    // ModifyAll in place of the second variable's Modify
                    R.Get('A');
                    R2.ModifyAll(Qty, 9);
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        R.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
            7:
                begin
                    // nothing changed elsewhere: the plain upsert on a read buffer
                    R.Get('A');
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        R.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
            8:
                begin
                    // the failed Insert twice, then Modify
                    R.Get('A');
                    R2.Get('A');
                    R2.Qty := 2;
                    R2.Modify();
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert();
                    Note('insert1=' + YesNo(Done));
                    Done := R.Insert();
                    Note('insert2=' + YesNo(Done));
                    R.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
            9:
                begin
                    // the second variable deleted the row: Insert now succeeds
                    R.Get('A');
                    R2.Get('A');
                    R2.Delete();
                    R.Name := 'x';
                    R.Qty := 5;
                    Done := R.Insert();
                    Note('insert=' + YesNo(Done));
                    if not Done then
                        R.Modify();
                    Note('modify done');
                    Note('buffer qty=' + Format(R.Qty));
                end;
        end;
        if CommitAtEnd then begin
            Commit();
            Note('committed');
        end;
    end;
}

codeunit 93813 "LT Y71 Failed Insert Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y71 MI Log";

    local procedure Seed(WithCommit: Boolean)
    var
        Row: Record "LT Y71 MI Tab";
        RowB: Record "LT Y71 MI Blob Tab";
    begin
        Row.DeleteAll();
        Row."No." := 'A';
        Row.Name := 'orig';
        Row.Qty := 1;
        Row.Insert();
        RowB.DeleteAll();
        RowB."No." := 'A';
        RowB.Name := 'orig';
        RowB.Qty := 1;
        RowB.Insert();
        if WithCommit then
            Commit();
        Log.Reset();
    end;

    local procedure Scenario(Name: Text; Mode: Integer; WithCommitAtEnd: Boolean; ReadStored: Boolean)
    var
        Helper: Codeunit "LT Y71 MI Helper";
        Row: Record "LT Y71 MI Tab";
        RowB: Record "LT Y71 MI Blob Tab";
    begin
        Helper.SetMode(Mode, WithCommitAtEnd);
        BindSubscription(Helper);
        Log.Reset();
        if Helper.Run() then
            Obs.Observe(Name, 'ok')
        else begin
            Obs.Observe(Name, 'raised');
            Obs.ObserveError(Name);
        end;
        UnbindSubscription(Helper);
        Obs.Observe(Name + '|notes', Helper.GetNotes());
        Obs.Observe(Name + '|log', Log.Text());
        if not ReadStored then begin
            // the row was inserted in this same transaction: the next database access answers the stopped transaction
            asserterror Row.Get('A');
            Obs.ObserveError(Name + '|read_after');
            exit;
        end;
        if Mode > 20 then begin
            if RowB.Get('A') then
                Obs.Observe(Name + '|stored', StrSubstNo('%1/%2', RowB.Name, RowB.Qty))
            else
                Obs.Observe(Name + '|stored', 'no row');
        end else
            if Row.Get('A') then
                Obs.Observe(Name + '|stored', StrSubstNo('%1/%2', Row.Name, Row.Qty))
            else
                Obs.Observe(Name + '|stored', 'no row');
    end;

    [Test]
    procedure FailedInsert_ThenModify_BufferReadBefore_RowChangedElsewhere()
    begin
        Seed(true);
        Scenario('committed', 1, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_BufferReadBefore_RowChangedElsewhere_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsert_ThenModify_BufferReadBefore_Uncommitted()
    begin
        Seed(false);
        Scenario('uncommitted', 1, true, false);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_BufferReadBefore_Uncommitted_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsert_ThenModify_CommitBetween()
    begin
        Seed(true);
        Scenario('commit_between', 2, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_CommitBetween_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsert_ThenModify_FreshBuffer()
    begin
        Seed(true);
        Scenario('committed', 3, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_FreshBuffer_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsert_ThenModify_FreshBuffer_Uncommitted()
    begin
        Seed(false);
        Scenario('uncommitted', 3, true, false);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_FreshBuffer_Uncommitted_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsertTrue_ThenModifyTrue()
    begin
        Seed(true);
        Scenario('committed', 4, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsertTrue_ThenModifyTrue_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsert_ThenModify_AfterModifyAll()
    begin
        Seed(true);
        Scenario('committed', 5, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_AfterModifyAll_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsert_ThenModify_NothingChangedElsewhere()
    begin
        Seed(true);
        Scenario('committed', 7, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_NothingChangedElsewhere_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsertTwice_ThenModify()
    begin
        Seed(true);
        Scenario('committed', 8, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsertTwice_ThenModify_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure Insert_AfterRowDeletedElsewhere()
    begin
        Seed(true);
        Scenario('committed', 9, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure Insert_AfterRowDeletedElsewhere_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure BlobTable_FailedInsert_ThenModify_BufferReadBefore()
    begin
        Seed(true);
        Scenario('blob_committed', 21, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure BlobTable_FailedInsert_ThenModify_BufferReadBefore_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure BlobTable_FailedInsert_ThenModify_FreshBuffer()
    begin
        Seed(true);
        Scenario('blob_committed', 23, true, true);
        Obs.Finish();
    end;

    [Test]
    procedure BlobTable_FailedInsert_ThenModify_FreshBuffer_More1()
    begin
        Obs.More();
    end;

    [Test]
    procedure FailedInsert_ThenModify_Temporary()
    var
        Temp: Record "LT Y71 MI Tab" temporary;
        R: Record "LT Y71 MI Tab" temporary;
        R2: Record "LT Y71 MI Tab" temporary;
        Done: Boolean;
    begin
        Temp."No." := 'A';
        Temp.Name := 'orig';
        Temp.Qty := 1;
        Temp.Insert();
        R.Copy(Temp, true);
        R2.Copy(Temp, true);
        R.Get('A');
        R2.Get('A');
        R2.Qty := 2;
        R2.Modify();
        R.Name := 'x';
        R.Qty := 5;
        Done := R.Insert();
        Obs.Observe('insert', Format(Done));
        if not Done then
            R.Modify();
        Obs.Observe('buffer_qty', Format(R.Qty));
        Temp.Get('A');
        Obs.Observe('stored', StrSubstNo('%1/%2', Temp.Name, Temp.Qty));
        Obs.Finish();
    end;

    [Test]
    procedure FailedInsert_ThenModify_Temporary_More1()
    begin
        Obs.More();
    end;
}
