// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-trigger-events
// Scope: in-scope
// Fixtures used: none (this file holds them); table "LT AB Row" (77000), codeunit "LT AB Flags" (77001)
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: fixtures for the page event probes (issue 628 items 19 to 25): a log, a list page with logging page triggers, and three subscriber sets
// (codeunit A holds two subscribers per event, declared in reverse alphabetical order, codeunit B holds one).

codeunit 77050 "LT AB Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Dump(): Text
    var
        Entry: Text;
        Result: Text;
    begin
        foreach Entry in Entries do begin
            if Result <> '' then
                Result += ' | ';
            Result += Entry;
        end;
        exit(Result);
    end;

    procedure DumpRange(FromIndex: Integer; Count: Integer): Text
    var
        Index: Integer;
        Result: Text;
    begin
        for Index := FromIndex to FromIndex + Count - 1 do
            if Index <= Entries.Count() then begin
                if Result <> '' then
                    Result += ' | ';
                Result += Entries.Get(Index);
            end;
        exit(Result);
    end;

    var
        Entries: List of [Text];
}

page 77060 "LT AB Event Rows"
{
    PageType = List;
    SourceTable = "LT AB Row";
    UsageCategory = None;
    InsertAllowed = true;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('page OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('page OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('page OnQueryClosePage ' + Format(CloseAction));
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('page OnAfterGetCurrRecord ' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('page OnNewRecord ' + Format(BelowxRec));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('page OnInsertRecord ' + Format(Rec.Id) + ' ' + Rec.Name);
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('page OnModifyRecord ' + Rec.Name + ' was ' + xRec.Name);
        exit(true);
    end;

    var
        Log: Codeunit "LT AB Log";
}

codeunit 77051 "LT AB Event Subs A"
{

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnOpenPageEvent', '', false, false)]
    local procedure ZFirstOnOpenPage(var Rec: Record "LT AB Row")
    begin
        Log.Add('A1 OnOpenPageEvent ' + Format(Rec.Count));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnOpenPageEvent', '', false, false)]
    local procedure AAfterOnOpenPage(var Rec: Record "LT AB Row")
    begin
        Log.Add('A2 OnOpenPageEvent ' + Format(Rec.Count));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnClosePageEvent', '', false, false)]
    local procedure ZFirstOnClosePage(var Rec: Record "LT AB Row")
    begin
        Log.Add('A1 OnClosePageEvent ' + Format(Rec.Count));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnClosePageEvent', '', false, false)]
    local procedure AAfterOnClosePage(var Rec: Record "LT AB Row")
    begin
        Log.Add('A2 OnClosePageEvent ' + Format(Rec.Count));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure ZFirstOnAfterGetCurrRecord(var Rec: Record "LT AB Row")
    begin
        Log.Add('A1 OnAfterGetCurrRecordEvent ' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure AAfterOnAfterGetCurrRecord(var Rec: Record "LT AB Row")
    begin
        Log.Add('A2 OnAfterGetCurrRecordEvent ' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnNewRecordEvent', '', false, false)]
    local procedure ZFirstOnNewRecord(var Rec: Record "LT AB Row"; BelowxRec: Boolean; var xRec: Record "LT AB Row")
    begin
        Log.Add('A1 OnNewRecordEvent ' + Format(Rec.Id) + ' ' + Format(BelowxRec));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnNewRecordEvent', '', false, false)]
    local procedure AAfterOnNewRecord(var Rec: Record "LT AB Row"; BelowxRec: Boolean; var xRec: Record "LT AB Row")
    begin
        Log.Add('A2 OnNewRecordEvent ' + Format(Rec.Id) + ' ' + Format(BelowxRec));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnInsertRecordEvent', '', false, false)]
    local procedure ZFirstOnInsertRecord(var Rec: Record "LT AB Row"; BelowxRec: Boolean; var xRec: Record "LT AB Row"; var AllowInsert: Boolean)
    begin
        Log.Add('A1 OnInsertRecordEvent ' + Format(Rec.Id) + ' ' + Format(Rec.Name) + ' ' + Format(xRec.Id) + ' ' + Format(BelowxRec) + ' ' + Format(AllowInsert));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnInsertRecordEvent', '', false, false)]
    local procedure AAfterOnInsertRecord(var Rec: Record "LT AB Row"; BelowxRec: Boolean; var xRec: Record "LT AB Row"; var AllowInsert: Boolean)
    begin
        Log.Add('A2 OnInsertRecordEvent ' + Format(Rec.Id) + ' ' + Format(Rec.Name) + ' ' + Format(xRec.Id) + ' ' + Format(BelowxRec) + ' ' + Format(AllowInsert));
        if Flags.Veto() then
            AllowInsert := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnModifyRecordEvent', '', false, false)]
    local procedure ZFirstOnModifyRecord(var Rec: Record "LT AB Row"; var xRec: Record "LT AB Row"; var AllowModify: Boolean)
    begin
        Log.Add('A1 OnModifyRecordEvent ' + Format(Rec.Name) + ' ' + Format(xRec.Name) + ' ' + Format(AllowModify));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnModifyRecordEvent', '', false, false)]
    local procedure AAfterOnModifyRecord(var Rec: Record "LT AB Row"; var xRec: Record "LT AB Row"; var AllowModify: Boolean)
    begin
        Log.Add('A2 OnModifyRecordEvent ' + Format(Rec.Name) + ' ' + Format(xRec.Name) + ' ' + Format(AllowModify));
        if Flags.Veto() then
            AllowModify := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnQueryClosePageEvent', '', false, false)]
    local procedure ZFirstOnQueryClosePage(var Rec: Record "LT AB Row"; var AllowClose: Boolean)
    begin
        Log.Add('A1 OnQueryClosePageEvent ' + Format(Rec.Count) + ' ' + Format(AllowClose));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnQueryClosePageEvent', '', false, false)]
    local procedure AAfterOnQueryClosePage(var Rec: Record "LT AB Row"; var AllowClose: Boolean)
    begin
        Log.Add('A2 OnQueryClosePageEvent ' + Format(Rec.Count) + ' ' + Format(AllowClose));
        if Flags.Veto() then
            AllowClose := false;
    end;

    var
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
}

codeunit 77052 "LT AB Event Subs B"
{

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnOpenPageEvent', '', false, false)]
    local procedure OnlyOnOpenPage(var Rec: Record "LT AB Row")
    begin
        Log.Add('B OnOpenPageEvent ' + Format(Rec.Count));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnClosePageEvent', '', false, false)]
    local procedure OnlyOnClosePage(var Rec: Record "LT AB Row")
    begin
        Log.Add('B OnClosePageEvent ' + Format(Rec.Count));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnlyOnAfterGetCurrRecord(var Rec: Record "LT AB Row")
    begin
        Log.Add('B OnAfterGetCurrRecordEvent ' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnNewRecordEvent', '', false, false)]
    local procedure OnlyOnNewRecord(var Rec: Record "LT AB Row"; BelowxRec: Boolean; var xRec: Record "LT AB Row")
    begin
        Log.Add('B OnNewRecordEvent ' + Format(Rec.Id) + ' ' + Format(BelowxRec));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnlyOnInsertRecord(var Rec: Record "LT AB Row"; BelowxRec: Boolean; var xRec: Record "LT AB Row"; var AllowInsert: Boolean)
    begin
        Log.Add('B OnInsertRecordEvent ' + Format(Rec.Id) + ' ' + Format(Rec.Name) + ' ' + Format(xRec.Id) + ' ' + Format(BelowxRec) + ' ' + Format(AllowInsert));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnlyOnModifyRecord(var Rec: Record "LT AB Row"; var xRec: Record "LT AB Row"; var AllowModify: Boolean)
    begin
        Log.Add('B OnModifyRecordEvent ' + Format(Rec.Name) + ' ' + Format(xRec.Name) + ' ' + Format(AllowModify));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AB Event Rows", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnlyOnQueryClosePage(var Rec: Record "LT AB Row"; var AllowClose: Boolean)
    begin
        Log.Add('B OnQueryClosePageEvent ' + Format(Rec.Count) + ' ' + Format(AllowClose));
    end;

    var
        Log: Codeunit "LT AB Log";
        Flags: Codeunit "LT AB Flags";
}
