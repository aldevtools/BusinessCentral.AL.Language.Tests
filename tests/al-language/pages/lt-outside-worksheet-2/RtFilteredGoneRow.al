// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88610 - 88615 (writer RT)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: the filtered variant of pages/lt-outside-worksheet/RmWorksheetGoneRow.al. A Worksheet without the new-row line (InsertAllowed =
//   false, DelayedInsert = true) over a table with primary key ("User Security ID", "Entry No."), whose OnOpenPage sets a filter, shows its
//   only row; an action deletes that row through another record variable and calls CurrPage.Update(false). Which triggers run afterwards
//   and which field values the blank Rec holds (does it take the filter value?). Filters: SetRange on the first key field in FilterGroup 2
//   (the reporter's shape) and in FilterGroup 0, SetRange on a field outside the key in FilterGroup 2, SetRange on both key fields, SetFilter
//   with a range on the second key field; the same page with the new-row line, and a List without the new-row line.
//   Log: N:<user>:<entry>:<group> = OnNewRecord, C:<user>:<entry>:<group> = OnAfterGetCurrRecord, R:<entry> = OnAfterGetRecord;
//   <user> is Yes when Rec."User Security ID" = UserSecurityId(), No otherwise.
// Result (BC 27.5, 28.5, 29.0 alike): after the action the deleted row is read once more (R:5), then OnNewRecord and OnAfterGetCurrRecord
//   run once on a blank Rec (twice more with the new-row line, which then shows Entry No. 0). The blank Rec takes the value of a SetRange on a
//   key field, in FilterGroup 2 or 0 (User Security ID = Yes; with both key fields also Entry No. 5); it does not take a SetRange on a field
//   outside the key (Group stays blank, User Security ID No) nor a range filter on a key field (Entry No. 0). First answers No; the List
//   behaves as the Worksheet.
// Source: al-runner issue 5809.
// BC versions: 27, 28, 29

table 88610 "LT RT Uf Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "User Security ID"; Guid) { }
        field(2; "Entry No."; Integer) { }
        field(3; Group; Code[10]) { }
        field(4; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "User Security ID", "Entry No.") { Clustered = true; }
    }
}

codeunit 88613 "LT RT Uf Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Mode: Integer;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure Describe(Row: Record "LT RT Uf Row"): Text
    begin
        exit(Format(Row."User Security ID" = UserSecurityId()) + ':' + Format(Row."Entry No.") + ':' + Row.Group);
    end;

    // 1: FilterGroup 2, SetRange of the first key field (the reporter's page); 2: the same in FilterGroup 0; 3: FilterGroup 2, SetRange of
    // a field outside the key; 4: FilterGroup 2, SetRange of both key fields; 5: FilterGroup 2, SetFilter of a range on the second key field.
    procedure ApplyFilter(var Row: Record "LT RT Uf Row")
    begin
        case Mode of
            1:
                begin
                    Row.FilterGroup(2);
                    Row.SetRange("User Security ID", UserSecurityId());
                    Row.FilterGroup(0);
                end;
            2:
                Row.SetRange("User Security ID", UserSecurityId());
            3:
                begin
                    Row.FilterGroup(2);
                    Row.SetRange(Group, 'G1');
                    Row.FilterGroup(0);
                end;
            4:
                begin
                    Row.FilterGroup(2);
                    Row.SetRange("User Security ID", UserSecurityId());
                    Row.SetRange("Entry No.", 5);
                    Row.FilterGroup(0);
                end;
            5:
                begin
                    Row.FilterGroup(2);
                    Row.SetFilter("Entry No.", '4..6');
                    Row.FilterGroup(0);
                end;
        end;
    end;

    procedure DeleteAllRows()
    var
        Row: Record "LT RT Uf Row";
    begin
        Row.SetRange("User Security ID", UserSecurityId());
        Row.DeleteAll();
    end;
}

page 88611 "LT RT Uf Ws NoNew"
{
    PageType = Worksheet;
    SourceTable = "LT RT Uf Row";
    InsertAllowed = false;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNoCtl; Rec."Entry No.") { ApplicationArea = All; }
                field(GroupCtl; Rec.Group) { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                ApplicationArea = All;
                Caption = 'Apply';

                trigger OnAction()
                begin
                    Log.DeleteAllRows();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.ApplyFilter(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Entry No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Log.Describe(Rec));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Log.Describe(Rec));
    end;

    var
        Log: Codeunit "LT RT Uf Log";
}

page 88612 "LT RT Uf Ws WithNew"
{
    PageType = Worksheet;
    SourceTable = "LT RT Uf Row";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNoCtl; Rec."Entry No.") { ApplicationArea = All; }
                field(GroupCtl; Rec.Group) { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                ApplicationArea = All;
                Caption = 'Apply';

                trigger OnAction()
                begin
                    Log.DeleteAllRows();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.ApplyFilter(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Entry No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Log.Describe(Rec));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Log.Describe(Rec));
    end;

    var
        Log: Codeunit "LT RT Uf Log";
}

page 88614 "LT RT Uf List NoNew"
{
    PageType = List;
    SourceTable = "LT RT Uf Row";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNoCtl; Rec."Entry No.") { ApplicationArea = All; }
                field(GroupCtl; Rec.Group) { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Apply)
            {
                ApplicationArea = All;
                Caption = 'Apply';

                trigger OnAction()
                begin
                    Log.DeleteAllRows();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.ApplyFilter(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Entry No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Log.Describe(Rec));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Log.Describe(Rec));
    end;

    var
        Log: Codeunit "LT RT Uf Log";
}

codeunit 88615 "LT RT Uf Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RT Uf Log";

    local procedure InsertOnlyRow(Mode: Integer)
    var
        Row: Record "LT RT Uf Row";
    begin
        Row.DeleteAll();
        Row."User Security ID" := UserSecurityId();
        Row."Entry No." := 5;
        Row.Group := 'G1';
        Row.Description := 'Only row';
        Row.Insert();
        Log.SetMode(Mode);
    end;

    local procedure RowCount(): Text
    var
        Row: Record "LT RT Uf Row";
    begin
        exit(Format(Row.Count()));
    end;

    local procedure RunNoNew(Mode: Integer)
    var
        Ws: TestPage "LT RT Uf Ws NoNew";
    begin
        InsertOnlyRow(Mode);
        Ws.OpenEdit();
        Observer.Observe('open shown', Ws.EntryNoCtl.Value() + '|' + Ws.GroupCtl.Value());
        Observer.Observe('open log', Log.Take());
        Ws.Apply.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.EntryNoCtl.Value() + '|' + Ws.GroupCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', RowCount());
        Observer.Observe('first', Format(Ws.First()));
        Observer.Observe('first log', Log.Take());
        Ws.Apply.Invoke();
        Observer.Observe('second action log', Log.Take());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', RowCount());
    end;

    // The reporter's page: FilterGroup 2, SetRange of the first key field.
    [Test]
    procedure RT_UfWs_KeyFieldGroup2()
    begin
        RunNoNew(1);
        Observer.Expect('open shown', '5|G1');
        Observer.Expect('open log', 'R:5;R:5;C:Yes:5:G1;');
        Observer.Expect('action log', 'R:5;N:Yes:0:;C:Yes:0:;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('second action log', 'N:Yes:0:;C:Yes:0:;');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RT_UfWs_KeyFieldGroup0()
    begin
        RunNoNew(2);
        Observer.Expect('open shown', '5|G1');
        Observer.Expect('open log', 'R:5;R:5;C:Yes:5:G1;');
        Observer.Expect('action log', 'R:5;N:Yes:0:;C:Yes:0:;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('second action log', 'N:Yes:0:;C:Yes:0:;');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RT_UfWs_NonKeyFieldGroup2()
    begin
        RunNoNew(3);
        Observer.Expect('open shown', '5|G1');
        Observer.Expect('open log', 'R:5;R:5;C:Yes:5:G1;');
        Observer.Expect('action log', 'R:5;N:No:0:;C:No:0:;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('second action log', 'N:No:0:;C:No:0:;');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RT_UfWs_BothKeyFieldsGroup2()
    begin
        RunNoNew(4);
        Observer.Expect('open shown', '5|G1');
        Observer.Expect('open log', 'R:5;R:5;C:Yes:5:G1;');
        Observer.Expect('action log', 'R:5;N:Yes:5:;C:Yes:5:;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('second action log', 'N:Yes:5:;C:Yes:5:;');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RT_UfWs_RangeOnSecondKeyFieldGroup2()
    begin
        RunNoNew(5);
        Observer.Expect('open shown', '5|G1');
        Observer.Expect('open log', 'R:5;R:5;C:Yes:5:G1;');
        Observer.Expect('action log', 'R:5;N:No:0:;C:No:0:;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('second action log', 'N:No:0:;C:No:0:;');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RT_UfWsWithNew_KeyFieldGroup2()
    var
        Ws: TestPage "LT RT Uf Ws WithNew";
    begin
        InsertOnlyRow(1);
        Ws.OpenEdit();
        Observer.Observe('open shown', Ws.EntryNoCtl.Value() + '|' + Ws.GroupCtl.Value());
        Observer.Observe('open log', Log.Take());
        Ws.Apply.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.EntryNoCtl.Value() + '|' + Ws.GroupCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', RowCount());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', RowCount());
        Observer.Expect('open shown', '5|G1');
        Observer.Expect('open log', 'R:5;R:5;C:Yes:5:G1;');
        Observer.Expect('action log', 'R:5;N:Yes:0:;C:Yes:0:;N:Yes:0:;C:Yes:0:;N:Yes:0:;C:Yes:0:;');
        Observer.Expect('shown after action', '0||');
        Observer.Expect('count', '0');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RT_UfListNoNew_KeyFieldGroup2()
    var
        L: TestPage "LT RT Uf List NoNew";
    begin
        InsertOnlyRow(1);
        L.OpenEdit();
        Observer.Observe('open shown', L.EntryNoCtl.Value() + '|' + L.GroupCtl.Value());
        Observer.Observe('open log', Log.Take());
        L.Apply.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', L.EntryNoCtl.Value() + '|' + L.GroupCtl.Value() + '|' + L.DescriptionCtl.Value());
        Observer.Observe('count', RowCount());
        L.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open shown', '5|G1');
        Observer.Expect('open log', 'R:5;R:5;C:Yes:5:G1;');
        Observer.Expect('action log', 'R:5;N:Yes:0:;C:Yes:0:;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('close log', '');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5951: the filtered key field has a TableRelation ("Batch Name" of LT SH Rel Line, FilterGroup 2,
    // SetRange to B1). With the related batch row present (the reporter's shape, page 5510 "Production Journal") and without it.

    local procedure ShInsertOnlyRelLine(WithBatch: Boolean)
    var
        Batch: Record "LT SH Rel Batch";
        Line: Record "LT SH Rel Line";
    begin
        Batch.DeleteAll();
        Line.DeleteAll();
        if WithBatch then begin
            Batch.Name := 'B1';
            Batch.Insert();
        end;
        Line."Batch Name" := 'B1';
        Line."Line No." := 10000;
        Line.Description := 'Only line';
        Line.Insert();
        Log.SetMode(0);
    end;

    local procedure ShRunRelNoNew(WithBatch: Boolean)
    var
        Ws: TestPage "LT SH Rel Ws NoNew";
        Line: Record "LT SH Rel Line";
    begin
        ShInsertOnlyRelLine(WithBatch);
        Ws.OpenEdit();
        Observer.Observe('open shown', Ws.BatchCtl.Value() + '|' + Ws.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Ws.Post.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.BatchCtl.Value() + '|' + Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', Format(Line.Count()));
        Observer.Observe('first', Format(Ws.First()));
        Observer.Observe('first log', Log.Take());
        Ws.Post.Invoke();
        Observer.Observe('second action log', Log.Take());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', Format(Line.Count()));
    end;

    [Test]
    procedure SH_RelWs_KeyFieldWithTableRelationGroup2_BatchExists()
    begin
        ShRunRelNoNew(true);
        Observer.Expect('open shown', 'B1|10000');
        Observer.Expect('open log', 'R:10000;R:10000;C:B1:10000;');
        Observer.Expect('action log', 'R:10000;N:B1:0;C:B1:0;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('second action log', 'N:B1:0;C:B1:0;');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SH_RelWs_KeyFieldWithTableRelationGroup2_BatchMissing()
    begin
        ShRunRelNoNew(false);
        Observer.Expect('open shown', 'B1|10000');
        Observer.Expect('open log', 'R:10000;R:10000;C:B1:10000;');
        Observer.Expect('action log', 'R:10000;');
        Observer.Expect('shown after action', '||');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('second action log', '');
        Observer.Expect('close log', '');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;
}

table 89434 "LT SH Rel Batch"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Code[10]) { }
    }

    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

table 89435 "LT SH Rel Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Batch Name"; Code[10]) { TableRelation = "LT SH Rel Batch"; }
        field(2; "Line No."; Integer) { }
        field(3; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Batch Name", "Line No.") { Clustered = true; }
    }
}

page 89436 "LT SH Rel Ws NoNew"
{
    PageType = Worksheet;
    SourceTable = "LT SH Rel Line";
    InsertAllowed = false;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(BatchCtl; Rec."Batch Name") { ApplicationArea = All; }
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';

                trigger OnAction()
                var
                    Line: Record "LT SH Rel Line";
                begin
                    Line.SetRange("Batch Name", Rec."Batch Name");
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Batch Name", 'B1');
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec."Batch Name" + ':' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Batch Name" + ':' + Format(Rec."Line No."));
    end;

    var
        Log: Codeunit "LT RT Uf Log";
}
