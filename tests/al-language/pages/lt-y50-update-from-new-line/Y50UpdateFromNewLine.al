// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 92966, pages 92974 - 92976, codeunits 92968 - 92969 (writer Y50)
// Probe: written against the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 5, gap G5-20: switching the batch of a journal worksheet when the page stands on the NEW LINE of an empty batch
//   (Y17JournalBatchSwitch.al pins the switch from a stored row only). The Y17 shape: a Worksheet with AutoSplitKey and DelayedInsert over a
//   line table keyed (Batch Name, Line No.); a global batch control whose OnValidate runs CurrPage.SaveRecord(), sets the batch filter in
//   filter group 2, calls Rec.Find('-') (switchable off), then CurrPage.Update(false) (Update(true) in one variant). OnOpenPage opens on the
//   batch a SingleInstance setting names (B3, empty), as SelectJournal opens on the default batch. Variants: the same page with
//   InsertAllowed = false, and as PageType List. Rows: B1 10000 A, 20000 C, 30000 E; B2 10000 B, 20000 D; B3 none.
//   Log: V:start/V:done <Line No.> around the OnValidate, R: OnAfterGetRecord, C: OnAfterGetCurrRecord, N: OnNewRecord, M:, I:, L.*: table.
// BC versions: 27, 28, 29

table 92966 "LT Y50 NL Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Batch Name"; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; "No."; Code[20]) { }
        field(4; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "Batch Name", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        Log.Add('L.OnInsert:' + "Batch Name" + '/' + Format("Line No."));
    end;

    trigger OnModify()
    begin
        Log.Add('L.OnModify:' + "Batch Name" + '/' + Format("Line No."));
    end;

    var
        Log: Codeunit "LT Y50 NL Log";
}

codeunit 92968 "LT Y50 NL Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        NoFind: Boolean;
        UpdateTrue: Boolean;
        Start: Code[10];

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure SetVariant(NewStart: Code[10]; NewNoFind: Boolean; NewUpdateTrue: Boolean)
    begin
        Start := NewStart;
        NoFind := NewNoFind;
        UpdateTrue := NewUpdateTrue;
    end;

    procedure StartBatch(): Code[10]
    begin
        exit(Start);
    end;

    procedure SkipFind(): Boolean
    begin
        exit(NoFind);
    end;

    procedure UseUpdateTrue(): Boolean
    begin
        exit(UpdateTrue);
    end;
}

page 92974 "LT Y50 NL Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y50 NL Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(CurrentBatch; CurrentBatch)
                {
                    ApplicationArea = All;
                    Caption = 'Batch';

                    trigger OnValidate()
                    begin
                        Log.Add('V:start ' + Format(Rec."Line No."));
                        CurrPage.SaveRecord();
                        SetBatch();
                        if Log.UseUpdateTrue() then
                            CurrPage.Update(true)
                        else
                            CurrPage.Update(false);
                        Log.Add('V:done ' + Format(Rec."Line No."));
                    end;
                }
            }
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentBatch := Log.StartBatch();
        SetBatch();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec."Batch Name" + '/' + Format(Rec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    // The SetName shape: the batch filter in filter group 2, then Find('-') in code (switchable off).
    local procedure SetBatch()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Batch Name", CurrentBatch);
        Rec.FilterGroup := 0;
        if not Log.SkipFind() then
            if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT Y50 NL Log";
        CurrentBatch: Code[10];
}

page 92975 "LT Y50 NL Worksheet NoIns"
{
    PageType = Worksheet;
    SourceTable = "LT Y50 NL Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(CurrentBatch; CurrentBatch)
                {
                    ApplicationArea = All;
                    Caption = 'Batch';

                    trigger OnValidate()
                    begin
                        Log.Add('V:start ' + Format(Rec."Line No."));
                        CurrPage.SaveRecord();
                        SetBatch();
                        if Log.UseUpdateTrue() then
                            CurrPage.Update(true)
                        else
                            CurrPage.Update(false);
                        Log.Add('V:done ' + Format(Rec."Line No."));
                    end;
                }
            }
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentBatch := Log.StartBatch();
        SetBatch();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec."Batch Name" + '/' + Format(Rec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    // The SetName shape: the batch filter in filter group 2, then Find('-') in code (switchable off).
    local procedure SetBatch()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Batch Name", CurrentBatch);
        Rec.FilterGroup := 0;
        if not Log.SkipFind() then
            if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT Y50 NL Log";
        CurrentBatch: Code[10];
}

page 92976 "LT Y50 NL List"
{
    PageType = List;
    SourceTable = "LT Y50 NL Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(CurrentBatch; CurrentBatch)
                {
                    ApplicationArea = All;
                    Caption = 'Batch';

                    trigger OnValidate()
                    begin
                        Log.Add('V:start ' + Format(Rec."Line No."));
                        CurrPage.SaveRecord();
                        SetBatch();
                        if Log.UseUpdateTrue() then
                            CurrPage.Update(true)
                        else
                            CurrPage.Update(false);
                        Log.Add('V:done ' + Format(Rec."Line No."));
                    end;
                }
            }
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentBatch := Log.StartBatch();
        SetBatch();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec."Batch Name" + '/' + Format(Rec."Line No.") + ' below=' + Format(BelowxRec));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
        exit(true);
    end;

    // The SetName shape: the batch filter in filter group 2, then Find('-') in code (switchable off).
    local procedure SetBatch()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Batch Name", CurrentBatch);
        Rec.FilterGroup := 0;
        if not Log.SkipFind() then
            if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT Y50 NL Log";
        CurrentBatch: Code[10];
}

codeunit 92969 "LT Y50 NL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y50 NL Log";

    local procedure Seed(NoFind: Boolean; UpdateTrue: Boolean)
    var
        Line: Record "LT Y50 NL Line";
    begin
        Line.DeleteAll();
        AddLine('B1', 10000, 'A');
        AddLine('B1', 20000, 'C');
        AddLine('B1', 30000, 'E');
        AddLine('B2', 10000, 'B');
        AddLine('B2', 20000, 'D');
        Log.SetVariant('B3', NoFind, UpdateTrue);
        Log.Take();
    end;

    local procedure AddLine(Batch: Code[10]; LineNo: Integer; No: Code[20])
    var
        Line: Record "LT Y50 NL Line";
    begin
        Line."Batch Name" := Batch;
        Line."Line No." := LineNo;
        Line."No." := No;
        Line.Description := 'd' + No;
        Line.Insert();
    end;

    local procedure StoredLines(): Text
    var
        Line: Record "LT Y50 NL Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Batch Name" + '/' + Format(Line."Line No.") + '/' + Line."No." + '/' + Line.Description + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetBatch(var W: TestPage "LT Y50 NL Worksheet"; Batch: Text)
    begin
        W.CurrentBatch.SetValue(Batch);
    end;

    local procedure Switch(NewBatch: Text; NoFind: Boolean; UpdateTrue: Boolean; ThenLast: Boolean)
    var
        W: TestPage "LT Y50 NL Worksheet";
        i: Integer;
        Rows: Text;
        Ok: Boolean;
    begin
        Seed(NoFind, UpdateTrue);
        W.OpenEdit();
        Observer.Observe('open', W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        Ok := TrySetBatch(W, NewBatch);
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W."Line No.".Value() + '/' + W."No.".Value() + '/' + W.Description.Value());
        Observer.Observe('batch', W.CurrentBatch.Value());
        Observer.Observe('read log', Log.Take());
        if ThenLast then
            Observer.Observe('last', Format(W.Last()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take())
        else
            Observer.Observe('next', Format(W.Next()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        if W.First() then
            repeat
                Rows += W."Line No.".Value() + '/' + W."No.".Value() + ',';
                i += 1;
            until (not W.Next()) or (i >= 8);
        Observer.Observe('rows', Rows);
        Log.Take();
        W.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredLines());
    end;

    [TryFunction]
    local procedure TrySetBatchNoIns(var W: TestPage "LT Y50 NL Worksheet NoIns"; Batch: Text)
    begin
        W.CurrentBatch.SetValue(Batch);
    end;

    local procedure SwitchNoIns(NewBatch: Text; NoFind: Boolean; UpdateTrue: Boolean; ThenLast: Boolean)
    var
        W: TestPage "LT Y50 NL Worksheet NoIns";
        i: Integer;
        Rows: Text;
        Ok: Boolean;
    begin
        Seed(NoFind, UpdateTrue);
        W.OpenEdit();
        Observer.Observe('open', W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        Ok := TrySetBatchNoIns(W, NewBatch);
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W."Line No.".Value() + '/' + W."No.".Value() + '/' + W.Description.Value());
        Observer.Observe('batch', W.CurrentBatch.Value());
        Observer.Observe('read log', Log.Take());
        if ThenLast then
            Observer.Observe('last', Format(W.Last()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take())
        else
            Observer.Observe('next', Format(W.Next()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        if W.First() then
            repeat
                Rows += W."Line No.".Value() + '/' + W."No.".Value() + ',';
                i += 1;
            until (not W.Next()) or (i >= 8);
        Observer.Observe('rows', Rows);
        Log.Take();
        W.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredLines());
    end;

    [TryFunction]
    local procedure TrySetBatchList(var W: TestPage "LT Y50 NL List"; Batch: Text)
    begin
        W.CurrentBatch.SetValue(Batch);
    end;

    local procedure SwitchList(NewBatch: Text; NoFind: Boolean; UpdateTrue: Boolean; ThenLast: Boolean)
    var
        W: TestPage "LT Y50 NL List";
        i: Integer;
        Rows: Text;
        Ok: Boolean;
    begin
        Seed(NoFind, UpdateTrue);
        W.OpenEdit();
        Observer.Observe('open', W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        Ok := TrySetBatchList(W, NewBatch);
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W."Line No.".Value() + '/' + W."No.".Value() + '/' + W.Description.Value());
        Observer.Observe('batch', W.CurrentBatch.Value());
        Observer.Observe('read log', Log.Take());
        if ThenLast then
            Observer.Observe('last', Format(W.Last()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take())
        else
            Observer.Observe('next', Format(W.Next()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        if W.First() then
            repeat
                Rows += W."Line No.".Value() + '/' + W."No.".Value() + ',';
                i += 1;
            until (not W.Next()) or (i >= 8);
        Observer.Observe('rows', Rows);
        Log.Take();
        W.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', StoredLines());
    end;

    // T1, the blocked shape: from the new line of B3 to B2, Find('-') in code.
    [Test]
    procedure G520_FromNewLine_ToBatchWithRows()
    begin
        Switch('B2', false, false, false);
        Observer.Finish();
    end;

    // T2: as T1 without Find in code (Rec stays the blank new-line buffer).
    [Test]
    procedure G520_FromNewLine_ToBatchWithRows_NoFind()
    begin
        Switch('B2', true, false, false);
        Observer.Finish();
    end;

    // T3, the Base App shape: B3 -> B1, then Last().
    [Test]
    procedure G520_FromNewLine_ToBatchWithRows_ThenLast()
    begin
        Switch('B1', false, false, true);
        Observer.Finish();
    end;

    // T4: as T1 with CurrPage.Update(true) in the OnValidate.
    [Test]
    procedure G520_FromNewLine_ToBatchWithRows_UpdateTrue()
    begin
        Switch('B2', false, true, false);
        Observer.Finish();
    end;

    // T5: the page with InsertAllowed = false (empty view without a new line), B3 -> B2.
    [Test]
    procedure G520_NoNewLine_EmptyView_ToBatchWithRows()
    begin
        SwitchNoIns('B2', false, false, false);
        Observer.Finish();
    end;

    // T6: the same as PageType List, B3 -> B2.
    [Test]
    procedure G520_List_FromNewLine_ToBatchWithRows()
    begin
        SwitchList('B2', false, false, false);
        Observer.Finish();
    end;
}
