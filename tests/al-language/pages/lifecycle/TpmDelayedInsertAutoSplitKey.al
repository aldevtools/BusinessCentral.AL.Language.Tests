// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// local object: the page properties DelayedInsert and AutoSplitKey, the logging triggers and a table with a line number key are what is under test; the log is a SingleInstance codeunit
// Fixtures used: Probe Observer (codeunit 69160); own objects 97420-97427, test codeunit 97427
// Area (TestPage lifecycle matrix, shapes "DelayedInsert list" and "AutoSplitKey list"): OpenEdit, OpenNew, New, First, Last, Next, GoToKey,
//   SetValue of the key and of a field, Close and the close at the end of a test. Each cell Observes the row the page shows, whether a row
//   was inserted, the order of page and table triggers (OnNewRecord, OnInsertRecord, Rec OnInsert) and the error text.
//   AutoSplitKey: the line number a new line gets at the end, between two lines, and before the first line.
// BC versions: 27, 28, 29

table 97420 "TPM DI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('T-I:' + "Code");
    end;

    trigger OnModify()
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('T-M:' + "Code");
    end;
}

table 97421 "TPM ASK Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('T-I:' + Format("Line No."));
    end;
}

page 97422 "TPM Delayed List"
{
    PageType = List;
    SourceTable = "TPM DI Row";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-NEW:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-INS:' + Rec."Code");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-MOD:' + Rec."Code");
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-QC:' + Format(CloseAction));
        exit(true);
    end;
}

page 97423 "TPM Immediate List"
{
    PageType = List;
    SourceTable = "TPM DI Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-NEW:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-INS:' + Rec."Code");
        exit(true);
    end;
}

page 97424 "TPM ASK List"
{
    PageType = List;
    SourceTable = "TPM ASK Line";
    SourceTableView = where("Doc No." = const('D1'));
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-NEW:' + Format(Rec."Line No.") + ' below=' + Format(BelowxRec));
        Rec."Doc No." := 'D1';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "TPM DI Log";
    begin
        Log.Add('P-INS:' + Format(Rec."Line No."));
        exit(true);
    end;
}

page 97425 "TPM ASK List DI"
{
    PageType = List;
    SourceTable = "TPM ASK Line";
    SourceTableView = where("Doc No." = const('D1'));
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Doc No." := 'D1';
    end;
}

codeunit 97426 "TPM DI Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries.TrimEnd();
        Entries := '';
    end;
}

codeunit 97427 "TPM DI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "TPM DI Log";

    local procedure Seed(Count: Integer)
    var
        Row: Record "TPM DI Row";
        i: Integer;
    begin
        Row.DeleteAll(false);
        for i := 1 to Count do begin
            Row.Init();
            Row."Code" := 'R' + Format(i);
            Row.Name := 'name' + Format(i);
            Row.Insert(false);
        end;
        Log.Take();
    end;

    local procedure SeedLines(Count: Integer)
    var
        Line: Record "TPM ASK Line";
        i: Integer;
    begin
        Line.DeleteAll(false);
        for i := 1 to Count do begin
            Line.Init();
            Line."Doc No." := 'D1';
            Line."Line No." := i * 10000;
            Line.Name := 'line' + Format(i);
            Line.Insert(false);
        end;
        Log.Take();
    end;

    local procedure Rows(): Text
    var
        Row: Record "TPM DI Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
        exit(Result.TrimEnd());
    end;

    local procedure Lines(): Text
    var
        Line: Record "TPM ASK Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Doc No." + '/' + Format(Line."Line No.") + '=' + Line.Name + ' ';
            until Line.Next() = 0;
        exit(Result.TrimEnd());
    end;

    [TryFunction]
    local procedure TryDelayedCode(var P: TestPage "TPM Delayed List"; Value: Text)
    begin
        P."Code".SetValue(Value);
    end;

    [TryFunction]
    local procedure TryDelayedName(var P: TestPage "TPM Delayed List"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryImmediateCode(var P: TestPage "TPM Immediate List"; Value: Text)
    begin
        P."Code".SetValue(Value);
    end;

    [TryFunction]
    local procedure TryImmediateName(var P: TestPage "TPM Immediate List"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryAskName(var P: TestPage "TPM ASK List"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TryAskNew(var P: TestPage "TPM ASK List")
    begin
        P.New();
    end;

    [TryFunction]
    local procedure TryAskPrevious(var P: TestPage "TPM ASK List"; var Moved: Boolean)
    begin
        Moved := P.Previous();
    end;

    [TryFunction]
    local procedure TryAskDiName(var P: TestPage "TPM ASK List DI"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    // DelayedInsert and the same list without it, side by side

    [Test]
    procedure TPM_Delayed_OpenNew_KeyThenName_RowInsertedWhenLeft()
    var
        P: TestPage "TPM Delayed List";
    begin
        Seed(2);
        P.OpenNew();
        Observer.Observe('log after OpenNew', Log.Take());
        Observer.Observe('Code ok', Format(TryDelayedCode(P, 'X1')));
        Observer.Observe('log after Code', Log.Take());
        Observer.Observe('rows after Code', Rows());
        Observer.Observe('Name ok', Format(TryDelayedName(P, 'nx')));
        Observer.Observe('log after Name', Log.Take());
        Observer.Observe('rows after Name', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('rows after Close', Rows());
        Observer.Expect('log after OpenNew', 'P-NEW:');
        Observer.Expect('Code ok', 'Yes');
        Observer.Expect('log after Code', '');
        Observer.Expect('rows after Code', 'R1=name1 R2=name2');
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log after Name', '');
        Observer.Expect('rows after Name', 'R1=name1 R2=name2');
        Observer.Expect('log after Close', 'P-INS:X1 T-I:X1 P-QC:OK');
        Observer.Expect('rows after Close', 'R1=name1 R2=name2 X1=nx');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_Immediate_OpenNew_KeyThenName_RowInsertedAtOnce()
    var
        P: TestPage "TPM Immediate List";
    begin
        Seed(2);
        P.OpenNew();
        Observer.Observe('log after OpenNew', Log.Take());
        Observer.Observe('Code ok', Format(TryImmediateCode(P, 'X1')));
        Observer.Observe('log after Code', Log.Take());
        Observer.Observe('rows after Code', Rows());
        Observer.Observe('Name ok', Format(TryImmediateName(P, 'nx')));
        Observer.Observe('log after Name', Log.Take());
        Observer.Observe('rows after Name', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('rows after Close', Rows());
        Observer.Expect('log after OpenNew', 'P-NEW:');
        Observer.Expect('Code ok', 'Yes');
        Observer.Expect('log after Code', '');
        Observer.Expect('rows after Code', 'R1=name1 R2=name2');
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log after Name', 'P-INS:X1 T-I:X1');
        Observer.Expect('rows after Name', 'R1=name1 R2=name2 X1=');
        Observer.Expect('log after Close', 'T-M:X1');
        Observer.Expect('rows after Close', 'R1=name1 R2=name2 X1=nx');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_Delayed_OpenEdit_NewKeyNameThenFirst_RowInsertedAtLeave()
    var
        P: TestPage "TPM Delayed List";
    begin
        Seed(2);
        P.OpenEdit();
        Log.Take();
        P.New();
        Observer.Observe('log after New', Log.Take());
        Observer.Observe('Code ok', Format(TryDelayedCode(P, 'X1')));
        Observer.Observe('Name ok', Format(TryDelayedName(P, 'nx')));
        Observer.Observe('log before leaving', Log.Take());
        Observer.Observe('rows before leaving', Rows());
        Observer.Observe('First', Format(P.First()));
        Observer.Observe('log after First', Log.Take());
        Observer.Observe('rows after First', Rows());
        Observer.Observe('shown', P."Code".Value());
        Observer.Observe('GoToKey X1', Format(P.GoToKey('X1')));
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Expect('log after New', 'P-NEW:');
        Observer.Expect('Code ok', 'Yes');
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log before leaving', '');
        Observer.Expect('rows before leaving', 'R1=name1 R2=name2');
        Observer.Expect('First', 'Yes');
        Observer.Expect('log after First', 'P-INS:X1 T-I:X1');
        Observer.Expect('rows after First', 'R1=name1 R2=name2 X1=nx');
        Observer.Expect('shown', 'R1');
        Observer.Expect('GoToKey X1', 'Yes');
        Observer.Expect('log after Close', 'P-QC:OK');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_Delayed_OpenEdit_NewNameOnlyThenNext_ErrorTextAndRows()
    var
        P: TestPage "TPM Delayed List";
    begin
        Seed(2);
        P.OpenEdit();
        P.New();
        Log.Take();
        Observer.Observe('Name ok', Format(TryDelayedName(P, 'nokey')));
        Observer.Observe('log after Name', Log.Take());
        if not P.First() then
            Observer.ObserveError('First leaving a row with a blank key');
        Observer.Observe('log after First', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log after Name', '');
        Observer.Expect('log after First', 'P-INS: T-I:');
        Observer.Expect('rows', '=nokey R1=name1 R2=name2');
        Observer.Expect('log after Close', 'P-QC:OK');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_Delayed_OpenEdit_NewThenClose_RowInsertedAtClose()
    var
        P: TestPage "TPM Delayed List";
    begin
        Seed(2);
        P.OpenEdit();
        P.New();
        Log.Take();
        TryDelayedCode(P, 'X2');
        Log.Take();
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Expect('log after Close', 'P-INS:X2 T-I:X2 P-QC:OK');
        Observer.Expect('rows', 'R1=name1 R2=name2 X2=');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_Delayed_OpenEdit_KeyOfExistingRowThenLeave_ErrorText()
    var
        P: TestPage "TPM Delayed List";
    begin
        Seed(2);
        P.OpenEdit();
        P.New();
        Log.Take();
        Observer.Observe('Code R1 ok', Format(TryDelayedCode(P, 'R1')));
        Observer.Observe('log after Code', Log.Take());
        if not P.First() then
            Observer.ObserveError('First leaving the duplicate key');
        Observer.Observe('log after First', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Expect('Code R1 ok', 'Yes');
        Observer.Expect('log after Code', '');
        Observer.Expect('First leaving the duplicate key|text', 'The record in table TPM DI Row already exists. Identification fields and values: Code=''R1''');
        Observer.Expect('First leaving the duplicate key|code', 'DB:RecordExists');
        Observer.Expect('log after First', 'P-INS:R1 T-I:R1');
        Observer.Expect('rows', 'R1=name1 R2=name2');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_Delayed_OpenEdit_SetValueOnExistingRow_ModifyAtOnce()
    var
        P: TestPage "TPM Delayed List";
    begin
        Seed(2);
        P.OpenEdit();
        P.GoToKey('R2');
        Log.Take();
        Observer.Observe('Name ok', Format(TryDelayedName(P, 'changed')));
        Observer.Observe('log after Name', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log after Name', 'P-INS:R1 T-I:R1');
        Observer.Expect('rows', 'R1=name1 R2=name2');
        Observer.Expect('log after Close', 'P-MOD:R2 T-M:R2 P-QC:OK');
        Observer.Verify();
    end;

    // The list stays open when this test ends with a new row not yet inserted; the next test reads the table.
    [Test]
    procedure TPM_Delayed_EndOfTest_NewRowWithKeyLeftOpen_Write()
    var
        P: TestPage "TPM Delayed List";
    begin
        Seed(2);
        P.OpenEdit();
        P.New();
        TryDelayedCode(P, 'X9');
        TryDelayedName(P, 'left open');
        Log.Take();
    end;

    [Test]
    procedure TPM_Delayed_EndOfTest_NewRowWithKeyLeftOpen_Read()
    begin
        Observer.Observe('rows', Rows());
        Observer.Observe('log', Log.Take());
        Observer.Expect('rows', 'R1=name1 R2=name2 X9=left open');
        Observer.Expect('log', 'P-INS:X9 T-I:X9 P-QC:OK');
        Observer.Verify();
    end;

    // AutoSplitKey

    [Test]
    procedure TPM_AutoSplitKey_OpenNew_FirstLineGetsNumber()
    var
        P: TestPage "TPM ASK List";
    begin
        SeedLines(0);
        P.OpenNew();
        Observer.Observe('log after OpenNew', Log.Take());
        Observer.Observe('Line No. shown', P."Line No.".Value());
        Observer.Observe('Name ok', Format(TryAskName(P, 'first')));
        Observer.Observe('log after Name', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('lines', Lines());
        Observer.Expect('log after OpenNew', 'P-NEW:0 below=Yes');
        Observer.Expect('Line No. shown', '0');
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log after Name', 'P-INS:10000 T-I:10000');
        Observer.Expect('log after Close', '');
        Observer.Expect('lines', 'D1/10000=first');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_AutoSplitKey_New_AtEnd_LineNumberAfterLast()
    var
        P: TestPage "TPM ASK List";
    begin
        SeedLines(2);
        P.OpenEdit();
        P.Last();
        Log.Take();
        P.New();
        Observer.Observe('log after New', Log.Take());
        Observer.Observe('Line No. shown', P."Line No.".Value());
        Observer.Observe('Name ok', Format(TryAskName(P, 'end')));
        Observer.Observe('log after Name', Log.Take());
        P.Close();
        Observer.Observe('lines', Lines());
        Observer.Expect('log after New', 'P-NEW:0 below=Yes');
        Observer.Expect('Line No. shown', '0');
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log after Name', '');
        Observer.Expect('lines', 'D1/10000=line1 D1/20000=line2 D1/30000=end');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_AutoSplitKey_New_BetweenTwoLines_KeySplitsTheGap()
    var
        P: TestPage "TPM ASK List";
    begin
        SeedLines(2);
        P.OpenEdit();
        P.First();
        Log.Take();
        P.New();
        Observer.Observe('log after New', Log.Take());
        Observer.Observe('Line No. shown', P."Line No.".Value());
        Observer.Observe('Name ok', Format(TryAskName(P, 'middle')));
        Observer.Observe('log after Name', Log.Take());
        Observer.Observe('Previous', Format(P.Previous()));
        Observer.Observe('shown after Previous', P."Line No.".Value());
        Observer.Observe('Next', Format(P.Next()));
        Observer.Observe('shown after Next', P."Line No.".Value());
        P.Close();
        Observer.Observe('lines', Lines());
        Observer.Expect('log after New', 'P-NEW:0 below=Yes');
        Observer.Expect('Line No. shown', '0');
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('log after Name', '');
        Observer.Expect('Previous', 'Yes');
        Observer.Expect('shown after Previous', '10000');
        Observer.Expect('Next', 'Yes');
        Observer.Expect('shown after Next', '15000');
        Observer.Expect('lines', 'D1/10000=line1 D1/15000=middle D1/20000=line2');
        Observer.Verify();
    end;

    [Test]
    procedure TPM_AutoSplitKey_New_BetweenManyTimes_GapRunsOut()
    var
        P: TestPage "TPM ASK List";
        i: Integer;
        Stopped: Boolean;
        Moved: Boolean;
    begin
        SeedLines(2);
        P.OpenEdit();
        P.First();
        // New and Previous run in TryFunctions: the first observation run raised "The line cannot be split." in this loop.
        // The loop stops at the first error and records at which step it came.
        for i := 1 to 16 do
            if not Stopped then begin
                if not TryAskNew(P) then begin
                    Observer.ObserveError('New ' + Format(i));
                    Stopped := true;
                end;
                if not Stopped then
                    if not TryAskName(P, 'n' + Format(i)) then begin
                        Observer.ObserveError('SetValue ' + Format(i));
                        Stopped := true;
                    end;
                if not Stopped then
                    if not TryAskPrevious(P, Moved) then begin
                        Observer.ObserveError('Previous ' + Format(i));
                        Stopped := true;
                    end else
                        if not Moved then
                            Observer.Observe('Previous ' + Format(i), 'No');
            end;
        Observer.Observe('log', Log.Take());
        Observer.Observe('lines', Lines());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_AutoSplitKey_Delayed_NewBetweenTwoLines_KeyAssignedWhenLeft()
    var
        P: TestPage "TPM ASK List DI";
    begin
        SeedLines(2);
        P.OpenEdit();
        P.First();
        Log.Take();
        P.New();
        Observer.Observe('Line No. shown', P."Line No.".Value());
        Observer.Observe('Name ok', Format(TryAskDiName(P, 'middle')));
        Observer.Observe('Line No. shown after Name', P."Line No.".Value());
        Observer.Observe('log before leaving', Log.Take());
        Observer.Observe('lines before leaving', Lines());
        Observer.Observe('Next', Format(P.Next()));
        Observer.Observe('log after Next', Log.Take());
        Observer.Observe('lines after Next', Lines());
        P.Close();
        Observer.Expect('Line No. shown', '0');
        Observer.Expect('Name ok', 'Yes');
        Observer.Expect('Line No. shown after Name', '0');
        Observer.Expect('log before leaving', '');
        Observer.Expect('lines before leaving', 'D1/10000=line1 D1/20000=line2');
        Observer.Expect('Next', 'Yes');
        Observer.Expect('log after Next', 'T-I:15000');
        Observer.Expect('lines after Next', 'D1/10000=line1 D1/15000=middle D1/20000=line2');
        Observer.Verify();
    end;
}
