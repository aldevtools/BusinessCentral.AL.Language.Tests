// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91774 - 91782 (writer Y17a)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: gap cycle 1, gap G16: switching the batch of a journal worksheet (the General Journal CurrentJnlBatchName shape). A Worksheet
//   with AutoSplitKey and DelayedInsert (inserts allowed) over a line table keyed (Batch Name, Line No.). A global batch control's
//   OnValidate runs CurrPage.SaveRecord(), sets the batch filter in filter group 2 and calls Rec.Find('-') (GenJnlManagement.SetName),
//   then CurrPage.Update(false). Variants: no Find('-') in code (J5), the filter in group 0 (J7), the page with a FactBox (J6).
//   Rows: B1 10000 A, 20000 C, 30000 E; B2 10000 B, 20000 D; B3 none. Log: V:start/V:done <Line No.> around the OnValidate,
//   R: OnAfterGetRecord, C: OnAfterGetCurrRecord, N: OnNewRecord, M: OnModifyRecord, I: OnInsertRecord, L.*: table triggers.
// BC versions: 27, 28, 29

table 91774 "LT Y17 JB Batch"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT Y17 JB Batches";

    fields
    {
        field(1; Name; Code[10]) { }
    }
    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

page 91777 "LT Y17 JB Batches"
{
    PageType = List;
    SourceTable = "LT Y17 JB Batch";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

table 91775 "LT Y17 JB Line"
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
        Log: Codeunit "LT Y17 JB Log";
}

page 91779 "LT Y17 JB Fact"
{
    PageType = CardPart;
    SourceTable = "LT Y17 JB Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Description; Rec.Description)
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('F:' + Rec."Batch Name" + '/' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT Y17 JB Log";
}

codeunit 91781 "LT Y17 JB Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        NoFind: Boolean;
        Group0: Boolean;

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

    procedure SetVariant(NewNoFind: Boolean; NewGroup0: Boolean)
    begin
        NoFind := NewNoFind;
        Group0 := NewGroup0;
    end;

    procedure SkipFind(): Boolean
    begin
        exit(NoFind);
    end;

    procedure UseGroup0(): Boolean
    begin
        exit(Group0);
    end;
}

page 91776 "LT Y17 JB Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT Y17 JB Line";
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
                    TableRelation = "LT Y17 JB Batch";

                    trigger OnValidate()
                    begin
                        Log.Add('V:start ' + Format(Rec."Line No."));
                        CurrPage.SaveRecord();
                        SetBatch();
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
        CurrentBatch := 'B1';
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

    // The GenJnlManagement.SetName shape: the batch filter in filter group 2, then Find('-') in code.
    local procedure SetBatch()
    begin
        if Log.UseGroup0() then
            Rec.SetRange("Batch Name", CurrentBatch)
        else begin
            Rec.FilterGroup := 2;
            Rec.SetRange("Batch Name", CurrentBatch);
            Rec.FilterGroup := 0;
        end;
        if not Log.SkipFind() then
            if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT Y17 JB Log";
        CurrentBatch: Code[10];
}

page 91778 "LT Y17 JB Worksheet Fb"
{
    PageType = Worksheet;
    SourceTable = "LT Y17 JB Line";
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
                    TableRelation = "LT Y17 JB Batch";

                    trigger OnValidate()
                    begin
                        Log.Add('V:start ' + Format(Rec."Line No."));
                        CurrPage.SaveRecord();
                        SetBatch();
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
        area(FactBoxes)
        {
            part(Fact; "LT Y17 JB Fact")
            {
                ApplicationArea = All;
                SubPageLink = "Batch Name" = field("Batch Name"), "Line No." = field("Line No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentBatch := 'B1';
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

    // The GenJnlManagement.SetName shape: the batch filter in filter group 2, then Find('-') in code.
    local procedure SetBatch()
    begin
        if Log.UseGroup0() then
            Rec.SetRange("Batch Name", CurrentBatch)
        else begin
            Rec.FilterGroup := 2;
            Rec.SetRange("Batch Name", CurrentBatch);
            Rec.FilterGroup := 0;
        end;
        if not Log.SkipFind() then
            if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT Y17 JB Log";
        CurrentBatch: Code[10];
}

codeunit 91782 "LT Y17 JB Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y17 JB Log";

    local procedure Seed(NoFind: Boolean; Group0: Boolean)
    var
        Batch: Record "LT Y17 JB Batch";
        Line: Record "LT Y17 JB Line";
    begin
        Line.DeleteAll();
        Batch.DeleteAll();
        AddBatch('B1');
        AddBatch('B2');
        AddBatch('B3');
        AddLine('B1', 10000, 'A');
        AddLine('B1', 20000, 'C');
        AddLine('B1', 30000, 'E');
        AddLine('B2', 10000, 'B');
        AddLine('B2', 20000, 'D');
        Log.SetVariant(NoFind, Group0);
        Log.Take();
    end;

    local procedure AddBatch(Name: Code[10])
    var
        Batch: Record "LT Y17 JB Batch";
    begin
        Batch.Name := Name;
        Batch.Insert();
    end;

    local procedure AddLine(Batch: Code[10]; LineNo: Integer; No: Code[20])
    var
        Line: Record "LT Y17 JB Line";
    begin
        Line."Batch Name" := Batch;
        Line."Line No." := LineNo;
        Line."No." := No;
        Line.Description := 'd' + No;
        Line.Insert();
    end;

    local procedure StoredLines(): Text
    var
        Line: Record "LT Y17 JB Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Batch Name" + '/' + Format(Line."Line No.") + '/' + Line."No." + '/' + Line.Description + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetBatch(var W: TestPage "LT Y17 JB Worksheet"; Batch: Text)
    begin
        W.CurrentBatch.SetValue(Batch);
    end;

    [TryFunction]
    local procedure TrySetBatchFb(var W: TestPage "LT Y17 JB Worksheet Fb"; Batch: Text)
    begin
        W.CurrentBatch.SetValue(Batch);
    end;

    local procedure Switch(GoToLine: Integer; NewBatch: Text; Edit: Boolean; NoFind: Boolean; Group0: Boolean)
    var
        W: TestPage "LT Y17 JB Worksheet";
        i: Integer;
        Rows: Text;
        Ok: Boolean;
    begin
        Seed(NoFind, Group0);
        W.OpenEdit();
        Observer.Observe('open', W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        if GoToLine <> 0 then
            Observer.Observe('goto', Format(W.GoToKey('B1', GoToLine)) + '/' + W."Line No.".Value() + ':' + Log.Take());
        if Edit then begin
            W.Description.SetValue('edited');
            Observer.Observe('edit log', Log.Take());
        end;
        Ok := TrySetBatch(W, NewBatch);
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W."Line No.".Value() + '/' + W."No.".Value() + '/' + W.Description.Value());
        Observer.Observe('batch', W.CurrentBatch.Value());
        Observer.Observe('read log', Log.Take());
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

    // J1, the blocked path (payroll shape): from B1/20000 to a batch with rows.
    [Test]
    procedure UpdWs_BatchSwitch_ToBatchWithRows()
    begin
        Switch(20000, 'B2', false, false, false);
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000');
        Observer.Expect('goto', 'Yes/20000:R:B1/20000;R:B1/20000;C:B1/20000');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 20000;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB');
        Observer.Expect('batch', 'B2');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('rows', '10000/B,20000/D,0/,');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/dC;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // J2: to a batch without lines (blank row or new line?).
    [Test]
    procedure UpdWs_BatchSwitch_ToEmptyBatch()
    begin
        Switch(20000, 'B3', false, false, false);
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000');
        Observer.Expect('goto', 'Yes/20000:R:B1/20000;R:B1/20000;C:B1/20000');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 20000;V:done 20000;N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('current', '0//');
        Observer.Expect('batch', 'B3');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'No/0/:');
        Observer.Expect('rows', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/dC;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // J3: from the first row (no GoToKey).
    [Test]
    procedure UpdWs_BatchSwitch_FromFirstRow()
    begin
        Switch(0, 'B2', false, false, false);
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 10000;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB');
        Observer.Expect('batch', 'B2');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('rows', '10000/B,20000/D,0/,');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/dC;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // J4: the row was edited before the switch (SaveRecord with a dirty row).
    [Test]
    procedure UpdWs_BatchSwitch_AfterEdit()
    begin
        Switch(20000, 'B2', true, false, false);
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000');
        Observer.Expect('goto', 'Yes/20000:R:B1/20000;R:B1/20000;C:B1/20000');
        Observer.Expect('edit log', '');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 20000;M:B1/20000;L.OnModify:B1/20000;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB');
        Observer.Expect('batch', 'B2');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('rows', '10000/B,20000/D,0/,');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/edited;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // J5: no Find('-') in code.
    [Test]
    procedure UpdWs_BatchSwitch_NoFindInCode()
    begin
        Switch(20000, 'B2', false, true, false);
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000');
        Observer.Expect('goto', 'Yes/20000:R:B1/20000;R:B1/20000;C:B1/20000');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 20000;V:done 20000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB');
        Observer.Expect('batch', 'B2');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('rows', '10000/B,20000/D,0/,');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/dC;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // J5b: no Find('-') in code, to the empty batch.
    [Test]
    procedure UpdWs_BatchSwitch_NoFindInCode_ToEmptyBatch()
    begin
        Switch(20000, 'B3', false, true, false);
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000');
        Observer.Expect('goto', 'Yes/20000:R:B1/20000;R:B1/20000;C:B1/20000');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 20000;V:done 20000;N:B3/0 below=Yes;C:B3/0;N:B3/0 below=Yes;C:B3/0');
        Observer.Expect('current', '0//');
        Observer.Expect('batch', 'B3');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'No/0/:');
        Observer.Expect('rows', '');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/dC;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // J7: the filter in filter group 0.
    [Test]
    procedure UpdWs_BatchSwitch_FilterGroup0()
    begin
        Switch(20000, 'B2', false, false, true);
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000');
        Observer.Expect('goto', 'Yes/20000:R:B1/20000;R:B1/20000;C:B1/20000');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 20000;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000');
        Observer.Expect('current', '10000/B/dB');
        Observer.Expect('batch', 'B2');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000');
        Observer.Expect('rows', '10000/B,20000/D,0/,');
        Observer.Expect('close log', '');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/dC;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    // J6: the page with a FactBox linked to the current line.
    [Test]
    procedure UpdWs_BatchSwitch_WithFactBox()
    var
        W: TestPage "LT Y17 JB Worksheet Fb";
        Ok: Boolean;
    begin
        Seed(false, false);
        W.OpenEdit();
        Observer.Observe('open', W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        Observer.Observe('goto', Format(W.GoToKey('B1', 20000)) + '/' + W."Line No.".Value() + ':' + Log.Take());
        Ok := TrySetBatchFb(W, 'B2');
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W."Line No.".Value() + '/' + W."No.".Value() + '/' + W.Fact.Description.Value());
        Observer.Observe('read log', Log.Take());
        Observer.Observe('next', Format(W.Next()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        W.Close();
        Observer.Observe('stored', StoredLines());
        Observer.Expect('open', '10000/A:R:B1/10000;R:B1/20000;R:B1/30000;R:B1/10000;R:B1/10000;C:B1/10000;F:B1/10000');
        Observer.Expect('goto', 'Yes/20000:R:B1/20000;R:B1/20000;C:B1/20000;F:B1/20000');
        Observer.Expect('setvalue', 'Yes');
        Observer.Expect('validate log', 'V:start 20000;V:done 10000;R:B2/10000;R:B2/20000;R:B2/10000;R:B2/10000;C:B2/10000;F:B2/10000');
        Observer.Expect('current', '10000/B/dB');
        Observer.Expect('read log', '');
        Observer.Expect('next', 'Yes/20000/D:R:B2/20000;R:B2/20000;C:B2/20000;F:B2/20000');
        Observer.Expect('stored', 'B1/10000/A/dA;B1/20000/C/dC;B1/30000/E/dE;B2/10000/B/dB;B2/20000/D/dD;');
        Observer.Verify();
    end;

    local procedure SwitchBack(NoFind: Boolean)
    var
        W: TestPage "LT Y17 JB Worksheet";
        Ok: Boolean;
    begin
        Seed(NoFind, false);
        W.OpenEdit();
        W.CurrentBatch.SetValue('B2');
        Observer.Observe('goto', Format(W.GoToKey('B2', 20000)) + '/' + W."Line No.".Value() + '/' + W."No.".Value());
        Log.Take();
        Ok := TrySetBatch(W, 'B1');
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W."Line No.".Value() + '/' + W."No.".Value());
        Observer.Observe('next', Format(W.Next()) + '/' + W."Line No.".Value() + '/' + W."No.".Value() + ':' + Log.Take());
        W.Close();
        Observer.Observe('stored', StoredLines());
    end;

    // J8: from B2/20000 back to B1, whose rows all sort before the old key: Find('-') in code gives B1/10000, the next-after-old-key
    //   rule of a refresh would give the previous row B1/30000.
    [Test]
    procedure UpdWs_BatchSwitch_BackToEarlierBatch()
    begin
        SwitchBack(false);
        Observer.Finish();
    end;

    // J8 without Find('-') in code.
    [Test]
    procedure UpdWs_BatchSwitch_BackToEarlierBatch_NoFind()
    begin
        SwitchBack(true);
        Observer.Finish();
    end;
}
