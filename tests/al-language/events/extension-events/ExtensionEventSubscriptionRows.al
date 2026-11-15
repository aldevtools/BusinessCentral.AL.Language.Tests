// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 61500, page 61501, report 61502, extensions 61500-61503,
//   subscribers 61503-61508, test codeunit 61509
// Probe (outside issue al-runner 8060): the Event Subscription row of a subscriber to an event that a table, page or report
// extension declares, bound to the base object (ObjectType::Table / Page / Report). Every column is read: Event Type, Publisher
// Object Type and ID, Published Function, Active, Error Information, Subscriber Instance; and how many rows a filter on the
// subscriber codeunit alone counts. Cells: integration event of a table extension (same app), of a page extension (same app),
// of a report extension (same app); a business event and an IncludeSender integration event of a table extension; a manual
// subscriber; SkipOnMissingLicense/SkipOnMissingPermission true; a table extension of a System Application table (another app).
// Observe form: the first CI run records what BC did; the assertions follow.
// BC versions: 27, 28, 29

table 61500 "LT EER Rec"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 61501 "LT EER Card"
{
    PageType = Card;
    SourceTable = "LT EER Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

report 61502 "LT EER Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(I; Integer) { }
    }
}

tableextension 61500 "LT EER Rec Ext" extends "LT EER Rec"
{
    [IntegrationEvent(false, false)]
    local procedure OnTableExtIntegration(Id: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnTableExtSender(Id: Integer)
    begin
    end;

    [BusinessEvent(false)]
    local procedure OnTableExtBusiness(Id: Integer)
    begin
    end;
}

pageextension 61501 "LT EER Card Ext" extends "LT EER Card"
{
    [IntegrationEvent(false, false)]
    local procedure OnPageExtIntegration(Id: Integer)
    begin
    end;
}

reportextension 61502 "LT EER Report Ext" extends "LT EER Report"
{
    [IntegrationEvent(false, false)]
    local procedure OnReportExtIntegration(Id: Integer)
    begin
    end;
}

// A table extension of a System Application table: the base table is in another app (the reporter's shape).
tableextension 61503 "LT EER Ret Pol Ext" extends "Retention Policy Setup"
{
    [IntegrationEvent(false, false)]
    local procedure OnOtherAppTableExtIntegration(Id: Integer)
    begin
    end;
}

codeunit 61503 "LT EER Table Sub"
{
    [EventSubscriber(ObjectType::Table, Database::"LT EER Rec", 'OnTableExtIntegration', '', false, false)]
    local procedure OnTableExtIntegrationSub(Id: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT EER Rec", 'OnTableExtSender', '', false, false)]
    local procedure OnTableExtSenderSub(var Sender: Record "LT EER Rec"; Id: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT EER Rec", 'OnTableExtBusiness', '', false, false)]
    local procedure OnTableExtBusinessSub(Id: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT EER Rec", 'OnTableExtIntegration', '', true, true)]
    local procedure OnTableExtSkipFlagsSub(Id: Integer)
    begin
    end;
}

codeunit 61504 "LT EER Page Sub"
{
    [EventSubscriber(ObjectType::Page, Page::"LT EER Card", 'OnPageExtIntegration', '', false, false)]
    local procedure OnPageExtIntegrationSub(Id: Integer)
    begin
    end;
}

codeunit 61505 "LT EER Report Sub"
{
    [EventSubscriber(ObjectType::Report, Report::"LT EER Report", 'OnReportExtIntegration', '', false, false)]
    local procedure OnReportExtIntegrationSub(Id: Integer)
    begin
    end;
}

codeunit 61506 "LT EER Manual Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT EER Rec", 'OnTableExtIntegration', '', false, false)]
    local procedure OnTableExtIntegrationManual(Id: Integer)
    begin
    end;
}

codeunit 61507 "LT EER Other App Sub"
{
    [EventSubscriber(ObjectType::Table, Database::"Retention Policy Setup", 'OnOtherAppTableExtIntegration', '', false, false)]
    local procedure OnOtherAppTableExtIntegrationSub(Id: Integer)
    begin
    end;
}

codeunit 61509 "LT EER Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Every column but the package id, or `none` when no row has the key.
    local procedure Dump(SubscriberId: Integer; Fn: Text): Text
    var
        E: Record "Event Subscription";
    begin
        if not E.Get(SubscriberId, Fn) then
            exit('none');
        exit(StrSubstNo('Event Type=%1;Publisher Object Type=%2;Publisher Object ID=%3;Published Function=%4;Active=%5;Error Information=%6;Subscriber Instance=%7;Active Manual Instances=%8;Originating App Name=%9',
            E."Event Type", E."Publisher Object Type", E."Publisher Object ID", E."Published Function", E.Active, E."Error Information",
            E."Subscriber Instance", E."Active Manual Instances", E."Originating App Name"));
    end;

    local procedure CountOf(SubscriberId: Integer): Integer
    var
        E: Record "Event Subscription";
    begin
        E.SetRange("Subscriber Codeunit ID", SubscriberId);
        exit(E.Count());
    end;

    [Test]
    procedure EER_TableExtIntegration_SameApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Table Sub", 'OnTableExtIntegrationSub'));
        Observer.Observe('count', Format(CountOf(Codeunit::"LT EER Table Sub")));
        Observer.Finish();
    end;

    [Test]
    procedure EER_TableExtSender_SameApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Table Sub", 'OnTableExtSenderSub'));
        Observer.Finish();
    end;

    [Test]
    procedure EER_TableExtBusiness_SameApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Table Sub", 'OnTableExtBusinessSub'));
        Observer.Finish();
    end;

    [Test]
    procedure EER_TableExtSkipFlags_SameApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Table Sub", 'OnTableExtSkipFlagsSub'));
        Observer.Finish();
    end;

    [Test]
    procedure EER_PageExtIntegration_SameApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Page Sub", 'OnPageExtIntegrationSub'));
        Observer.Observe('count', Format(CountOf(Codeunit::"LT EER Page Sub")));
        Observer.Finish();
    end;

    [Test]
    procedure EER_ReportExtIntegration_SameApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Report Sub", 'OnReportExtIntegrationSub'));
        Observer.Observe('count', Format(CountOf(Codeunit::"LT EER Report Sub")));
        Observer.Finish();
    end;

    [Test]
    procedure EER_TableExtIntegration_ManualSubscriber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Manual Sub", 'OnTableExtIntegrationManual'));
        Observer.Finish();
    end;

    [Test]
    procedure EER_TableExtIntegration_BaseTableInOtherApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('row', Dump(Codeunit::"LT EER Other App Sub", 'OnOtherAppTableExtIntegrationSub'));
        Observer.Observe('count', Format(CountOf(Codeunit::"LT EER Other App Sub")));
        Observer.Finish();
    end;

    [Test]
    procedure EER_InactiveAndErrorFilters()
    var
        E: Record "Event Subscription";
        Observer: Codeunit "Probe Observer";
    begin
        E.SetRange("Subscriber Codeunit ID", Codeunit::"LT EER Table Sub", Codeunit::"LT EER Other App Sub");
        E.SetRange(Active, false);
        Observer.Observe('inactive', Format(E.Count()));
        E.SetRange(Active);
        E.SetFilter("Error Information", '<>%1', '');
        Observer.Observe('withError', Format(E.Count()));
        Observer.Finish();
    end;
}
