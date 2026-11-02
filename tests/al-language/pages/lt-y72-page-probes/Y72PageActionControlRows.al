// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-actions-overview
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 93864-93865, pages 93868-93870, page extension 93868, test codeunit 93859
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: the rows of the system tables "Page Action" and "Page Control Field" for (a) a page whose actions are listed in the Processing
//   area and referenced from the Promoted area by actionref (also inside a group of the Promoted area), and the same page with a page
//   extension that adds an action and an actionref to it; (b) a card page whose controls are fields of a page-global record variable
//   (Contact."Phone No." with a quoted, spaced field name) with and without Editable and ExtendedDatatype.
//   Row text: Action ID | Parent Action ID | Indentation | Action Type | Name | Caption | RunObjectType | RunObjectID;
//   control: TableNo | FieldNo | SourceExpression | Editable | Visible | Enabled | OptionString | Sequence.
// Neighbours: record/TestPageActionVirtualTable.al, record/QzPageActionCaption.al, misc/W2PageMetadata.al:324-331,
//   record/PageControlFieldSourceFormsSM.al.
// BC versions: all (CI)

table 93864 "LT Y72 Ctl Contact"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Phone No."; Text[30]) { }
        field(3; Plain; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 93865 "LT Y72 Ctl Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 93868 "LT Y72 Act List"
{
    PageType = List;
    SourceTable = "LT Y72 Ctl Src";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Tools)
            {
                ApplicationArea = All;
                Caption = 'Tools';
                RunObject = page "LT Y72 Link Target";
            }
            action(Other)
            {
                ApplicationArea = All;
                Caption = 'Other';
            }
        }
        area(Promoted)
        {
            actionref(Tools_Promoted; Tools) { }
            group(Category_Process)
            {
                Caption = 'Task';
                actionref(Other_Promoted; Other) { }
            }
        }
    }
}

pageextension 93868 "LT Y72 Act List Ext" extends "LT Y72 Act List"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtAct)
            {
                ApplicationArea = All;
                Caption = 'Ext action';
                RunObject = page "LT Y72 Mask Card";
            }
        }
        addlast(Promoted)
        {
            actionref(ExtAct_Promoted; ExtAct) { }
        }
    }
}

page 93869 "LT Y72 Ctl Card"
{
    PageType = Card;
    SourceTable = "LT Y72 Ctl Src";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(ContactPhone; Contact."Phone No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ExtendedDatatype = PhoneNo;
                }
                field(ContactPhone2; Contact."Phone No.") { ApplicationArea = All; }
                field(ContactPlain; Contact.Plain) { ApplicationArea = All; }
                field(ContactQuotedPlain; Contact."Plain") { ApplicationArea = All; }
                field(ContactNo; Contact."No.") { ApplicationArea = All; }
            }
        }
    }

    var
        Contact: Record "LT Y72 Ctl Contact";
}

codeunit 93859 "LT Y72 Action Control Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    // Name of the parent row, or (<type>) when the parent has no name (an action container).
    local procedure ParentName(PageId: Integer; ParentActionId: Integer): Text
    var
        Parent: Record "Page Action";
    begin
        Parent.SetRange("Page ID", PageId);
        Parent.SetRange("Action ID", ParentActionId);
        if not Parent.FindFirst() then
            exit('(none)');
        if Parent.Name = '' then
            exit('(' + Format(Parent."Action Type") + ')');
        exit(Parent.Name);
    end;

    local procedure ActionRow(PageId: Integer; var PageAction: Record "Page Action"): Text
    begin
        exit(StrSubstNo('parent=%1|indent=%2|type=%3|name=%4|caption=%5|rot=%6|roi=%7', ParentName(PageId, PageAction."Parent Action ID"), PageAction.Indentation, PageAction."Action Type", PageAction.Name, PageAction.Caption, PageAction.RunObjectType, PageAction.RunObjectID));
    end;

    local procedure ControlRow(PageId: Integer; ControlName: Text): Text
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, PageId);
        PageControlField.SetRange(ControlName, ControlName);
        if not PageControlField.FindFirst() then
            exit('no row');
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8', PageControlField.TableNo, PageControlField.FieldNo, PageControlField.SourceExpression, PageControlField.Editable, PageControlField.Visible, PageControlField.Enabled, PageControlField.OptionString, PageControlField.Sequence));
    end;

    local procedure NameRow(PageId: Integer; ActionName: Text): Text
    var
        PageAction: Record "Page Action";
    begin
        PageAction.SetRange("Page ID", PageId);
        PageAction.SetRange(Name, ActionName);
        if PageAction.IsEmpty() then
            exit('empty');
        PageAction.FindFirst();
        exit(Format(PageAction.Count()) + '|' + ActionRow(PageId, PageAction));
    end;

    [Test]
    procedure PageAction_ActionRef_Rows()
    var
        PageAction: Record "Page Action";
    begin
        Observer.Discard();
        PageAction.SetRange("Page ID", Page::"LT Y72 Act List");
        PageAction.SetRange("Action Type", PageAction."Action Type"::Action);
        if PageAction.FindSet() then
            repeat
                Observer.Observe('action ' + PageAction.Name, ActionRow(Page::"LT Y72 Act List", PageAction));
            until PageAction.Next() = 0;
        Observer.Observe('action rows', Format(PageAction.Count()));
        PageAction.SetRange("Action Type", PageAction."Action Type"::ActionGroup);
        PageAction.SetRange(Name, 'Category_Process');
        Observer.Observe('group Category_Process rows', Format(PageAction.Count()));
        PageAction.SetRange(Name);
        PageAction.SetFilter(Name, '*_Promoted');
        PageAction.SetRange("Action Type");
        Observer.Observe('rows named *_Promoted', Format(PageAction.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageAction_ActionRef_Rows_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_ActionRef_Rows_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_ActionRef_Rows_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_FilterByName_ActionRef()
    begin
        Observer.Discard();
        Observer.Observe('Tools', NameRow(Page::"LT Y72 Act List", 'Tools'));
        Observer.Observe('Tools_Promoted', NameRow(Page::"LT Y72 Act List", 'Tools_Promoted'));
        Observer.Observe('Other_Promoted', NameRow(Page::"LT Y72 Act List", 'Other_Promoted'));
        Observer.Observe('Category_Process', NameRow(Page::"LT Y72 Act List", 'Category_Process'));
        Observer.Observe('ExtAct', NameRow(Page::"LT Y72 Act List", 'ExtAct'));
        Observer.Observe('ExtAct_Promoted', NameRow(Page::"LT Y72 Act List", 'ExtAct_Promoted'));
        Observer.Observe('Promoted', NameRow(Page::"LT Y72 Act List", 'Promoted'));
        Observer.Finish();
    end;

    [Test]
    procedure PageAction_FilterByName_ActionRef_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_FilterByName_ActionRef_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_FilterByName_ActionRef_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_ActionRef_RunObjectColumns()
    var
        PageAction: Record "Page Action";
    begin
        Observer.Discard();
        PageAction.SetRange("Page ID", Page::"LT Y72 Act List");
        PageAction.SetRange(RunObjectType, PageAction.RunObjectType::Page);
        Observer.Observe('run object page rows', Format(PageAction.Count()));
        PageAction.SetRange(RunObjectID, Page::"LT Y72 Link Target");
        Observer.Observe('target rows', Format(PageAction.Count()));
        PageAction.SetRange(RunObjectID, Page::"LT Y72 Mask Card");
        Observer.Observe('extension target rows', Format(PageAction.Count()));
        PageAction.Reset();
        PageAction.SetRange("Page ID", Page::"LT Y72 Act List");
        PageAction.SetFilter(Name, '*_Promoted');
        Observer.Observe('promoted rows', Format(PageAction.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageAction_ActionRef_RunObjectColumns_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_ActionRef_RunObjectColumns_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageAction_ActionRef_RunObjectColumns_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageControl_RecVarQuotedSpacedField()
    begin
        Observer.Discard();
        Observer.Observe('ContactPhone', ControlRow(Page::"LT Y72 Ctl Card", 'ContactPhone'));
        Observer.Observe('ContactPhone2', ControlRow(Page::"LT Y72 Ctl Card", 'ContactPhone2'));
        Observer.Observe('ContactPlain', ControlRow(Page::"LT Y72 Ctl Card", 'ContactPlain'));
        Observer.Observe('ContactQuotedPlain', ControlRow(Page::"LT Y72 Ctl Card", 'ContactQuotedPlain'));
        Observer.Observe('ContactNo', ControlRow(Page::"LT Y72 Ctl Card", 'ContactNo'));
        Observer.Observe('NoCtl', ControlRow(Page::"LT Y72 Ctl Card", 'NoCtl'));
        Observer.Finish();
    end;

    [Test]
    procedure PageControl_RecVarQuotedSpacedField_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageControl_RecVarQuotedSpacedField_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageControl_RecVarQuotedSpacedField_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageControl_FilterByFieldNo_WithRecVarControl()
    var
        PageControlField: Record "Page Control Field";
    begin
        Observer.Discard();
        PageControlField.SetRange(TableNo, Database::"LT Y72 Ctl Src");
        PageControlField.SetRange(PageNo, Page::"LT Y72 Ctl Card");
        PageControlField.SetRange(FieldNo, 1);
        Observer.Observe('field 1 empty', Format(PageControlField.IsEmpty()));
        Observer.Observe('field 1 count', Format(PageControlField.Count()));
        PageControlField.SetRange(FieldNo, 2);
        Observer.Observe('field 2 empty', Format(PageControlField.IsEmpty()));
        Observer.Observe('field 2 count', Format(PageControlField.Count()));
        PageControlField.SetRange(FieldNo);
        Observer.Observe('all count', Format(PageControlField.Count()));
        PageControlField.SetRange(TableNo, Database::"LT Y72 Ctl Contact");
        Observer.Observe('contact table count', Format(PageControlField.Count()));
        PageControlField.Reset();
        PageControlField.SetRange(PageNo, Page::"LT Y72 Ctl Card");
        PageControlField.SetRange(FieldNo, 0);
        Observer.Observe('field 0 count', Format(PageControlField.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure PageControl_FilterByFieldNo_WithRecVarControl_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageControl_FilterByFieldNo_WithRecVarControl_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure PageControl_FilterByFieldNo_WithRecVarControl_More3()
    begin
        Observer.More();
    end;
}
