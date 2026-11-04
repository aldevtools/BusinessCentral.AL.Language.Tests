// Fixtures for TestExtensionDeclaredEvents.al: one base object per extension kind
// (table, page, report), an extension of each that DECLARES and RAISES its own events, the
// subscribers bound to them, and a SingleInstance sink the subscribers report into.
//
// Every event here is declared on the EXTENSION object, never on the base object. The
// subscribers bind through the BASE object (ObjectType::Table / Page / Report and the base
// object's id), which is how AL names an event an extension publishes.
//
// Nothing outside TestExtensionDeclaredEvents.al raises these events, so the sink's counts
// cannot be inflated by an unrelated test.

table 68500 "ALT ExtEvt Pub"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[30])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; PK)
        {
            Clustered = true;
        }
    }
}

tableextension 68501 "ALT ExtEvt Pub Ext" extends "ALT ExtEvt Pub"
{
    procedure RaiseExtIntegration(Value: Integer)
    begin
        OnExtIntegrationEvent(Value);
    end;

    procedure RaiseExtBusiness(Value: Text[30])
    begin
        OnExtBusinessEvent(Value);
    end;

    procedure RaiseExtWithSender()
    begin
        OnExtSenderEvent();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExtIntegrationEvent(Value: Integer)
    begin
    end;

    [BusinessEvent(false)]
    local procedure OnExtBusinessEvent(Value: Text[30])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnExtSenderEvent()
    begin
    end;
}

page 68502 "ALT ExtEvt Page"
{
    PageType = Card;
    SourceTable = "ALT ExtEvt Pub";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(PK; Rec.PK)
            {
                ApplicationArea = All;
            }
        }
    }
}

pageextension 68503 "ALT ExtEvt Page Ext" extends "ALT ExtEvt Page"
{
    procedure RaisePageExt(Value: Integer)
    begin
        OnPageExtEvent(Value);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPageExtEvent(Value: Integer)
    begin
    end;
}

report 68504 "ALT ExtEvt Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Pub; "ALT ExtEvt Pub")
        {
        }
    }
}

reportextension 68505 "ALT ExtEvt Report Ext" extends "ALT ExtEvt Report"
{
    procedure RaiseReportExt(Value: Integer)
    begin
        OnReportExtEvent(Value);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReportExtEvent(Value: Integer)
    begin
    end;
}

codeunit 68506 "ALT ExtEvt Sink"
{
    SingleInstance = true;

    var
        Counts: Dictionary of [Text, Integer];
        LastValues: Dictionary of [Text, Text];

    procedure Reset()
    begin
        Clear(Counts);
        Clear(LastValues);
    end;

    procedure Note(Channel: Text; Value: Text)
    var
        Current: Integer;
    begin
        if Counts.Get(Channel, Current) then;
        Counts.Set(Channel, Current + 1);
        LastValues.Set(Channel, Value);
    end;

    procedure CountOf(Channel: Text): Integer
    var
        Current: Integer;
    begin
        if Counts.Get(Channel, Current) then
            exit(Current);
        exit(0);
    end;

    procedure LastValueOf(Channel: Text): Text
    var
        Value: Text;
    begin
        if LastValues.Get(Channel, Value) then
            exit(Value);
        exit('');
    end;
}

codeunit 68507 "ALT ExtEvt Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"ALT ExtEvt Pub", 'OnExtIntegrationEvent', '', false, false)]
    local procedure OnTableExtIntegration(Value: Integer)
    var
        Sink: Codeunit "ALT ExtEvt Sink";
    begin
        if Value < 0 then
            Error('ExtEvt table subscriber refused %1', Value);
        Sink.Note('table-integration', Format(Value));
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT ExtEvt Pub", 'OnExtBusinessEvent', '', false, false)]
    local procedure OnTableExtBusiness(Value: Text[30])
    var
        Sink: Codeunit "ALT ExtEvt Sink";
    begin
        Sink.Note('table-business', Value);
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT ExtEvt Pub", 'OnExtSenderEvent', '', false, false)]
    local procedure OnTableExtSender(var Sender: Record "ALT ExtEvt Pub")
    var
        Sink: Codeunit "ALT ExtEvt Sink";
    begin
        Sink.Note('table-sender', Sender.Name);
    end;

    [EventSubscriber(ObjectType::Page, Page::"ALT ExtEvt Page", 'OnPageExtEvent', '', false, false)]
    local procedure OnPageExt(Value: Integer)
    var
        Sink: Codeunit "ALT ExtEvt Sink";
    begin
        Sink.Note('page', Format(Value));
    end;

    [EventSubscriber(ObjectType::Report, Report::"ALT ExtEvt Report", 'OnReportExtEvent', '', false, false)]
    local procedure OnReportExt(Value: Integer)
    var
        Sink: Codeunit "ALT ExtEvt Sink";
    begin
        Sink.Note('report', Format(Value));
    end;
}
