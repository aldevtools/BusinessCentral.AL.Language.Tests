// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-trigger-events
// Scope: in-scope
// Fixtures used: none (this file holds them); table "LT PNS Row" (97601) for the cue part only
// Probe: fixtures of NoSourcePageEvents.al (al-runner issue 7430), written against a BC service tier.
// local object: pages of every page type WITHOUT a SourceTable, and one subscriber codeunit per page, are what is under test.
// Facts: one page per page type without SourceTable (Card, List, Worksheet, ListPlus, StandardDialog, NavigatePage, CardPart, ListPart,
//   RoleCenter), each logs its page triggers as '<page>.page.<trigger>' and has one subscriber codeunit that logs each of the nine page
//   trigger events as '<page>.<event>' (no parameters; a Rec parameter does not compile, must-not-compile cases 3132 and 3133).
// BC versions: 27 to 29 (CI matrix)

codeunit 97600 "LT PNS Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        ModeText: Text;
        FailAt: Text;

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do
            Result += Line + ';';
        exit(Result);
    end;

    procedure SetMode(NewMode: Text)
    begin
        ModeText := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(ModeText);
    end;

    procedure SetFailAt(Where: Text)
    begin
        FailAt := Where;
    end;

    procedure MaybeFail(Where: Text)
    begin
        if FailAt = Where then
            Error('PNS boom at %1', Where);
    end;

    procedure ClearAll()
    begin
        Clear(Lines);
        ModeText := '';
        FailAt := '';
    end;
}

table 97601 "LT PNS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 97610 "LT PNS Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('Card.field.OnValidate');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateTrue) { ApplicationArea = All; trigger OnAction() begin Log.Add('Card.action.UpdateTrue'); CurrPage.Update(true); Log.Add('Card.action.UpdateTrue done'); end; }
            action(UpdateFalse) { ApplicationArea = All; trigger OnAction() begin Log.Add('Card.action.UpdateFalse'); CurrPage.Update(false); Log.Add('Card.action.UpdateFalse done'); end; }
            action(CloseSelf) { ApplicationArea = All; trigger OnAction() begin Log.Add('Card.action.CloseSelf'); CurrPage.Close(); Log.Add('Card.action.CloseSelf done'); end; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Card.page.OnOpenPage');
        if Log.Mode() = 'CloseInOpen' then CurrPage.Close();
        if Log.Mode() = 'UpdateTrueInOpen' then CurrPage.Update(true);
        if Log.Mode() = 'UpdateFalseInOpen' then CurrPage.Update(false);
    end;

    trigger OnClosePage()
    begin
        Log.Add('Card.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Card.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('Card.page.OnAfterGetCurrRecord');
        if Log.Mode() = 'CloseInAgcr' then CurrPage.Close();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('Card.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('Card.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('Card.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('Card.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('Card.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97611 "LT PNS List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('List.field.OnValidate');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateTrue) { ApplicationArea = All; trigger OnAction() begin Log.Add('List.action.UpdateTrue'); CurrPage.Update(true); Log.Add('List.action.UpdateTrue done'); end; }
            action(UpdateFalse) { ApplicationArea = All; trigger OnAction() begin Log.Add('List.action.UpdateFalse'); CurrPage.Update(false); Log.Add('List.action.UpdateFalse done'); end; }
            action(CloseSelf) { ApplicationArea = All; trigger OnAction() begin Log.Add('List.action.CloseSelf'); CurrPage.Close(); Log.Add('List.action.CloseSelf done'); end; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('List.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('List.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('List.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('List.page.OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('List.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('List.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('List.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('List.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('List.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97612 "LT PNS Worksheet"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('Worksheet.field.OnValidate');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateTrue) { ApplicationArea = All; trigger OnAction() begin Log.Add('Worksheet.action.UpdateTrue'); CurrPage.Update(true); Log.Add('Worksheet.action.UpdateTrue done'); end; }
            action(UpdateFalse) { ApplicationArea = All; trigger OnAction() begin Log.Add('Worksheet.action.UpdateFalse'); CurrPage.Update(false); Log.Add('Worksheet.action.UpdateFalse done'); end; }
            action(CloseSelf) { ApplicationArea = All; trigger OnAction() begin Log.Add('Worksheet.action.CloseSelf'); CurrPage.Close(); Log.Add('Worksheet.action.CloseSelf done'); end; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Worksheet.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('Worksheet.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Worksheet.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('Worksheet.page.OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('Worksheet.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('Worksheet.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('Worksheet.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('Worksheet.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('Worksheet.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97613 "LT PNS ListPlus"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('ListPlus.field.OnValidate');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateTrue) { ApplicationArea = All; trigger OnAction() begin Log.Add('ListPlus.action.UpdateTrue'); CurrPage.Update(true); Log.Add('ListPlus.action.UpdateTrue done'); end; }
            action(UpdateFalse) { ApplicationArea = All; trigger OnAction() begin Log.Add('ListPlus.action.UpdateFalse'); CurrPage.Update(false); Log.Add('ListPlus.action.UpdateFalse done'); end; }
            action(CloseSelf) { ApplicationArea = All; trigger OnAction() begin Log.Add('ListPlus.action.CloseSelf'); CurrPage.Close(); Log.Add('ListPlus.action.CloseSelf done'); end; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('ListPlus.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('ListPlus.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('ListPlus.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('ListPlus.page.OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('ListPlus.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('ListPlus.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('ListPlus.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('ListPlus.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('ListPlus.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97614 "LT PNS StdDialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('StdDialog.field.OnValidate');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateTrue) { ApplicationArea = All; trigger OnAction() begin Log.Add('StdDialog.action.UpdateTrue'); CurrPage.Update(true); Log.Add('StdDialog.action.UpdateTrue done'); end; }
            action(UpdateFalse) { ApplicationArea = All; trigger OnAction() begin Log.Add('StdDialog.action.UpdateFalse'); CurrPage.Update(false); Log.Add('StdDialog.action.UpdateFalse done'); end; }
            action(CloseSelf) { ApplicationArea = All; trigger OnAction() begin Log.Add('StdDialog.action.CloseSelf'); CurrPage.Close(); Log.Add('StdDialog.action.CloseSelf done'); end; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('StdDialog.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('StdDialog.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('StdDialog.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('StdDialog.page.OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('StdDialog.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('StdDialog.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('StdDialog.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('StdDialog.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('StdDialog.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97615 "LT PNS NavPage"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('NavPage.field.OnValidate');
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateTrue) { ApplicationArea = All; trigger OnAction() begin Log.Add('NavPage.action.UpdateTrue'); CurrPage.Update(true); Log.Add('NavPage.action.UpdateTrue done'); end; }
            action(UpdateFalse) { ApplicationArea = All; trigger OnAction() begin Log.Add('NavPage.action.UpdateFalse'); CurrPage.Update(false); Log.Add('NavPage.action.UpdateFalse done'); end; }
            action(CloseSelf) { ApplicationArea = All; trigger OnAction() begin Log.Add('NavPage.action.CloseSelf'); CurrPage.Close(); Log.Add('NavPage.action.CloseSelf done'); end; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('NavPage.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('NavPage.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('NavPage.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('NavPage.page.OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('NavPage.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('NavPage.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('NavPage.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('NavPage.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('NavPage.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97616 "LT PNS CardPart"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('CardPart.field.OnValidate');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('CardPart.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('CardPart.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('CardPart.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('CardPart.page.OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('CardPart.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('CardPart.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('CardPart.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('CardPart.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('CardPart.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97617 "LT PNS ListPart"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(TxtF; Txt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add('ListPart.field.OnValidate');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('ListPart.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('ListPart.page.OnClosePage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('ListPart.page.OnQueryClosePage');
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('ListPart.page.OnAfterGetCurrRecord');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('ListPart.page.OnAfterGetRecord');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('ListPart.page.OnNewRecord');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('ListPart.page.OnInsertRecord');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('ListPart.page.OnModifyRecord');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.Add('ListPart.page.OnDeleteRecord');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97618 "LT PNS RoleCenter"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(RoleCenter)
        {
            part(CP; "LT PNS CardPart") { ApplicationArea = All; }
            part(CueP; "LT PNS Cue Part") { ApplicationArea = All; }
        }
    }

    var
        Log: Codeunit "LT PNS Log";
}

page 97621 "LT PNS Cue Part"
{
    PageType = CardPart;
    SourceTable = "LT PNS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            cuegroup(CueG)
            {
                field(CueId; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Cue.page.OnOpenPage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('Cue.page.OnAfterGetCurrRecord ' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT PNS Log";
}

page 97619 "LT PNS HostCard"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            part(CP; "LT PNS CardPart") { ApplicationArea = All; }
            part(LP; "LT PNS ListPart") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('Host.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('Host.page.OnClosePage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('Host.page.OnAfterGetCurrRecord');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

page 97620 "LT PNS ExtBase"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(BaseF; Txt) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('ExtBase.page.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('ExtBase.page.OnClosePage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('ExtBase.page.OnAfterGetCurrRecord');
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

page 97623 "LT PNS ArgsCard"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(ArgsF; Txt) { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('ArgsCard.page.OnQueryClosePage');
        exit(true);
    end;

    var
        Txt: Text;
        Log: Codeunit "LT PNS Log";
}

pageextension 97625 "LT PNS ExtBase Ext" extends "LT PNS ExtBase"
{
    layout
    {
        addlast(Content)
        {
            field(ExtF; ExtTxt) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('ExtBase.ext.OnOpenPage');
    end;

    trigger OnClosePage()
    begin
        Log.Add('ExtBase.ext.OnClosePage');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('ExtBase.ext.OnAfterGetCurrRecord');
    end;

    var
        ExtTxt: Text;
        Log: Codeunit "LT PNS Log";
}

codeunit 97630 "LT PNS Subs Card"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('Card.OnOpenPageEvent');
        Log.MaybeFail('Card.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('Card.OnClosePageEvent');
        Log.MaybeFail('Card.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('Card.OnQueryClosePageEvent');
        Log.MaybeFail('Card.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('Card.OnAfterGetRecordEvent');
        Log.MaybeFail('Card.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('Card.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('Card.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('Card.OnNewRecordEvent');
        Log.MaybeFail('Card.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('Card.OnInsertRecordEvent');
        Log.MaybeFail('Card.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('Card.OnModifyRecordEvent');
        Log.MaybeFail('Card.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('Card.OnDeleteRecordEvent');
        Log.MaybeFail('Card.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97631 "LT PNS Subs List"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('List.OnOpenPageEvent');
        Log.MaybeFail('List.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('List.OnClosePageEvent');
        Log.MaybeFail('List.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('List.OnQueryClosePageEvent');
        Log.MaybeFail('List.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('List.OnAfterGetRecordEvent');
        Log.MaybeFail('List.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('List.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('List.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('List.OnNewRecordEvent');
        Log.MaybeFail('List.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('List.OnInsertRecordEvent');
        Log.MaybeFail('List.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('List.OnModifyRecordEvent');
        Log.MaybeFail('List.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS List", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('List.OnDeleteRecordEvent');
        Log.MaybeFail('List.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97632 "LT PNS Subs Worksheet"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('Worksheet.OnOpenPageEvent');
        Log.MaybeFail('Worksheet.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('Worksheet.OnClosePageEvent');
        Log.MaybeFail('Worksheet.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('Worksheet.OnQueryClosePageEvent');
        Log.MaybeFail('Worksheet.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('Worksheet.OnAfterGetRecordEvent');
        Log.MaybeFail('Worksheet.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('Worksheet.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('Worksheet.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('Worksheet.OnNewRecordEvent');
        Log.MaybeFail('Worksheet.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('Worksheet.OnInsertRecordEvent');
        Log.MaybeFail('Worksheet.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('Worksheet.OnModifyRecordEvent');
        Log.MaybeFail('Worksheet.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Worksheet", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('Worksheet.OnDeleteRecordEvent');
        Log.MaybeFail('Worksheet.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97633 "LT PNS Subs ListPlus"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('ListPlus.OnOpenPageEvent');
        Log.MaybeFail('ListPlus.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('ListPlus.OnClosePageEvent');
        Log.MaybeFail('ListPlus.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('ListPlus.OnQueryClosePageEvent');
        Log.MaybeFail('ListPlus.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('ListPlus.OnAfterGetRecordEvent');
        Log.MaybeFail('ListPlus.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('ListPlus.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('ListPlus.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('ListPlus.OnNewRecordEvent');
        Log.MaybeFail('ListPlus.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('ListPlus.OnInsertRecordEvent');
        Log.MaybeFail('ListPlus.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('ListPlus.OnModifyRecordEvent');
        Log.MaybeFail('ListPlus.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPlus", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('ListPlus.OnDeleteRecordEvent');
        Log.MaybeFail('ListPlus.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97634 "LT PNS Subs StdDialog"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('StdDialog.OnOpenPageEvent');
        Log.MaybeFail('StdDialog.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('StdDialog.OnClosePageEvent');
        Log.MaybeFail('StdDialog.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('StdDialog.OnQueryClosePageEvent');
        Log.MaybeFail('StdDialog.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('StdDialog.OnAfterGetRecordEvent');
        Log.MaybeFail('StdDialog.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('StdDialog.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('StdDialog.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('StdDialog.OnNewRecordEvent');
        Log.MaybeFail('StdDialog.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('StdDialog.OnInsertRecordEvent');
        Log.MaybeFail('StdDialog.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('StdDialog.OnModifyRecordEvent');
        Log.MaybeFail('StdDialog.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS StdDialog", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('StdDialog.OnDeleteRecordEvent');
        Log.MaybeFail('StdDialog.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97635 "LT PNS Subs NavPage"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('NavPage.OnOpenPageEvent');
        Log.MaybeFail('NavPage.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('NavPage.OnClosePageEvent');
        Log.MaybeFail('NavPage.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('NavPage.OnQueryClosePageEvent');
        Log.MaybeFail('NavPage.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('NavPage.OnAfterGetRecordEvent');
        Log.MaybeFail('NavPage.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('NavPage.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('NavPage.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('NavPage.OnNewRecordEvent');
        Log.MaybeFail('NavPage.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('NavPage.OnInsertRecordEvent');
        Log.MaybeFail('NavPage.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('NavPage.OnModifyRecordEvent');
        Log.MaybeFail('NavPage.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS NavPage", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('NavPage.OnDeleteRecordEvent');
        Log.MaybeFail('NavPage.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97636 "LT PNS Subs CardPart"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('CardPart.OnOpenPageEvent');
        Log.MaybeFail('CardPart.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('CardPart.OnClosePageEvent');
        Log.MaybeFail('CardPart.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('CardPart.OnQueryClosePageEvent');
        Log.MaybeFail('CardPart.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('CardPart.OnAfterGetRecordEvent');
        Log.MaybeFail('CardPart.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('CardPart.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('CardPart.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('CardPart.OnNewRecordEvent');
        Log.MaybeFail('CardPart.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('CardPart.OnInsertRecordEvent');
        Log.MaybeFail('CardPart.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('CardPart.OnModifyRecordEvent');
        Log.MaybeFail('CardPart.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS CardPart", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('CardPart.OnDeleteRecordEvent');
        Log.MaybeFail('CardPart.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97637 "LT PNS Subs ListPart"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('ListPart.OnOpenPageEvent');
        Log.MaybeFail('ListPart.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('ListPart.OnClosePageEvent');
        Log.MaybeFail('ListPart.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('ListPart.OnQueryClosePageEvent');
        Log.MaybeFail('ListPart.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('ListPart.OnAfterGetRecordEvent');
        Log.MaybeFail('ListPart.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('ListPart.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('ListPart.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('ListPart.OnNewRecordEvent');
        Log.MaybeFail('ListPart.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('ListPart.OnInsertRecordEvent');
        Log.MaybeFail('ListPart.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('ListPart.OnModifyRecordEvent');
        Log.MaybeFail('ListPart.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ListPart", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('ListPart.OnDeleteRecordEvent');
        Log.MaybeFail('ListPart.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97638 "LT PNS Subs RoleCenter"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('RoleCenter.OnOpenPageEvent');
        Log.MaybeFail('RoleCenter.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('RoleCenter.OnClosePageEvent');
        Log.MaybeFail('RoleCenter.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('RoleCenter.OnQueryClosePageEvent');
        Log.MaybeFail('RoleCenter.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('RoleCenter.OnAfterGetRecordEvent');
        Log.MaybeFail('RoleCenter.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('RoleCenter.OnAfterGetCurrRecordEvent');
        Log.MaybeFail('RoleCenter.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('RoleCenter.OnNewRecordEvent');
        Log.MaybeFail('RoleCenter.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('RoleCenter.OnInsertRecordEvent');
        Log.MaybeFail('RoleCenter.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('RoleCenter.OnModifyRecordEvent');
        Log.MaybeFail('RoleCenter.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS RoleCenter", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('RoleCenter.OnDeleteRecordEvent');
        Log.MaybeFail('RoleCenter.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97640 "LT PNS Subs ExtBase"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('ExtBase.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('ExtBase.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('ExtBase.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('ExtBase.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('ExtBase.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('ExtBase.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('ExtBase.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('ExtBase.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ExtBase", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('ExtBase.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97641 "LT PNS Subs Host"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('Host.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('Host.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('Host.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('Host.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('Host.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('Host.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('Host.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('Host.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS HostCard", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('Host.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97642 "LT PNS Subs Cue"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS Cue Part", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent(var Rec: Record "LT PNS Row")
    begin
        Log.Add('Cue.OnOpenPageEvent ' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Cue Part", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent(var Rec: Record "LT PNS Row")
    begin
        Log.Add('Cue.OnClosePageEvent ' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Cue Part", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent(var Rec: Record "LT PNS Row")
    begin
        Log.Add('Cue.OnAfterGetCurrRecordEvent ' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Cue Part", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent(var Rec: Record "LT PNS Row")
    begin
        Log.Add('Cue.OnAfterGetRecordEvent ' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97643 "LT PNS Subs CardArgs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PNS ArgsCard", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent(var AllowClose: Boolean)
    begin
        Log.Add('CardArgs.' + 'OnQueryClosePageEvent ' + Format(AllowClose));
        if Log.Mode() = 'DenyClose' then
            AllowClose := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ArgsCard", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent(BelowxRec: Boolean)
    begin
        Log.Add('CardArgs.OnNewRecordEvent ' + Format(BelowxRec));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS ArgsCard", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent(BelowxRec: Boolean; var AllowInsert: Boolean)
    begin
        Log.Add('CardArgs.OnInsertRecordEvent ' + Format(BelowxRec) + ' ' + Format(AllowInsert));
    end;

    var
        Log: Codeunit "LT PNS Log";
}

codeunit 97650 "LT PNS Subs Manual"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPageEvent()
    begin
        Log.Add('CardManual.OnOpenPageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePageEvent()
    begin
        Log.Add('CardManual.OnClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClosePageEvent()
    begin
        Log.Add('CardManual.OnQueryClosePageEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecordEvent()
    begin
        Log.Add('CardManual.OnAfterGetRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordEvent()
    begin
        Log.Add('CardManual.OnAfterGetCurrRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNewRecordEvent()
    begin
        Log.Add('CardManual.OnNewRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEvent()
    begin
        Log.Add('CardManual.OnInsertRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEvent()
    begin
        Log.Add('CardManual.OnModifyRecordEvent');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PNS Card", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEvent()
    begin
        Log.Add('CardManual.OnDeleteRecordEvent');
    end;

    var
        Log: Codeunit "LT PNS Log";
}
