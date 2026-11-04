// Fixture objects of the AZ event probes (corpus issue 651, writer AZ); the tests are in AzEventTests.al.

// Collects the calls of triggers and subscribers; one owner: codeunit "LT AZ Event Tests".
codeunit 80700 "LT AZ Ev Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Active: Boolean;

    procedure Start()
    begin
        Entries := '';
        Active := true;
    end;

    procedure Add(Entry: Text)
    begin
        if Active then
            Entries += Entry + ';';
    end;

    procedure Stop(): Text
    begin
        Active := false;
        exit(Entries);
    end;
}

table 80701 "LT AZ Ev Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 80702 "LT AZ Ev Global Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Log: Codeunit "LT AZ Ev Log";
    begin
        if TableId <> Database::"LT AZ Ev Row" then
            exit;
        Log.Add('setup company=' + CompanyName());
        OnDatabaseInsert := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    var
        Log: Codeunit "LT AZ Ev Log";
    begin
        if RecRef.Number <> Database::"LT AZ Ev Row" then
            exit;
        Log.Add('oninsert id=' + Format(RecRef.Field(1).Value) + ' recrefcompany=' + RecRef.CurrentCompany() + ' company=' + CompanyName());
    end;
}

table 80703 "LT AZ Ev Page Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; FieldX; Text[30]) { }
        field(3; FieldY; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 80710 "LT AZ Ev Page One"
{
    PageType = Card;
    SourceTable = "LT AZ Ev Page Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CtlX; Rec.FieldX) { ApplicationArea = All; }
            field(CtlY; Rec.FieldY) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
                action(ActX) { ApplicationArea = All; trigger OnAction() begin end; }
                action(ActY) { ApplicationArea = All; trigger OnAction() begin end; }
        }
    }
}

page 80711 "LT AZ Ev Page Two"
{
    PageType = Card;
    SourceTable = "LT AZ Ev Page Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CtlX; Rec.FieldX) { ApplicationArea = All; }
            field(CtlY; Rec.FieldY) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
                action(ActX) { ApplicationArea = All; trigger OnAction() begin end; }
                action(ActY) { ApplicationArea = All; trigger OnAction() begin end; }
        }
    }
}

page 80712 "LT AZ Ev Page Three"
{
    PageType = Card;
    SourceTable = "LT AZ Ev Page Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CtlY; Rec.FieldY) { ApplicationArea = All; }
            field(CtlX; Rec.FieldX) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
                action(ActY) { ApplicationArea = All; trigger OnAction() begin end; }
                action(ActX) { ApplicationArea = All; trigger OnAction() begin end; }
        }
    }
}

codeunit 80713 "LT AZ Ev Page Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page One", 'OnAfterActionEvent', 'ActX', false, false)]
    local procedure OneActX(var Rec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page One", 'OnAfterActionEvent', 'ActY', false, false)]
    local procedure OneActY(var Rec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page One", 'OnAfterValidateEvent', 'CtlX', false, false)]
    local procedure OneValX(var Rec: Record "LT AZ Ev Page Row"; var xRec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page One", 'OnAfterValidateEvent', 'CtlY', false, false)]
    local procedure OneValY(var Rec: Record "LT AZ Ev Page Row"; var xRec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Two", 'OnAfterActionEvent', 'ActX', false, false)]
    local procedure TwoActX(var Rec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Two", 'OnAfterActionEvent', 'ActY', false, false)]
    local procedure TwoActY(var Rec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Two", 'OnAfterValidateEvent', 'CtlX', false, false)]
    local procedure TwoValX(var Rec: Record "LT AZ Ev Page Row"; var xRec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Two", 'OnAfterValidateEvent', 'CtlY', false, false)]
    local procedure TwoValY(var Rec: Record "LT AZ Ev Page Row"; var xRec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Three", 'OnAfterActionEvent', 'ActX', false, false)]
    local procedure ThreeActX(var Rec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Three", 'OnAfterActionEvent', 'ActY', false, false)]
    local procedure ThreeActY(var Rec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Three", 'OnAfterValidateEvent', 'CtlX', false, false)]
    local procedure ThreeValX(var Rec: Record "LT AZ Ev Page Row"; var xRec: Record "LT AZ Ev Page Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT AZ Ev Page Three", 'OnAfterValidateEvent', 'CtlY', false, false)]
    local procedure ThreeValY(var Rec: Record "LT AZ Ev Page Row"; var xRec: Record "LT AZ Ev Page Row")
    begin
    end;
}

report 80706 "LT AZ Ev Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT AZ Ev Row") { }
    }

    var
        Mark: Text;

    procedure SetMark(NewMark: Text)
    begin
        Mark := NewMark;
    end;

    procedure GetMark(): Text
    begin
        exit(Mark);
    end;
}

reportextension 80707 "LT AZ Ev RepExt" extends "LT AZ Ev Report"
{
    trigger OnPreReport()
    begin
        OnAzRepEvent(7);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAzRepEvent(N: Integer)
    begin
    end;
}

codeunit 80708 "LT AZ Ev Report Subs"
{
    [EventSubscriber(ObjectType::Report, Report::"LT AZ Ev Report", 'OnAzRepEvent', '', false, false)]
    local procedure NoSender(N: Integer)
    var
        Log: Codeunit "LT AZ Ev Log";
    begin
        Log.Add('nosender N=' + Format(N));
    end;

    [EventSubscriber(ObjectType::Report, Report::"LT AZ Ev Report", 'OnAzRepEvent', '', false, false)]
    local procedure WithSender(sender: Report "LT AZ Ev Report"; N: Integer)
    var
        Log: Codeunit "LT AZ Ev Log";
    begin
        Log.Add('withsender N=' + Format(N) + ' mark=' + sender.GetMark());
    end;
}
