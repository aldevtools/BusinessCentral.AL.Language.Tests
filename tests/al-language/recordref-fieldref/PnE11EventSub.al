// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72591, page 72592, table 72593, subscriber codeunit 72594
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: "RecordRef.FilterGroup, Option to Enum (issue 23) / NP Retail blockers - Event Subscription row of a page control validate event"
// and (Probe fixes) "Event Subscription - The row BC lists for a page field event subscriber"
// Facts: rows of the Event Subscription virtual table for a subscriber to a page field OnAfterValidateEvent and to a table field event
// BC versions: 29 (27 and 28 by CI)

table 72593 "LT PnE Evt Rec"
{
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

page 72592 "LT PnE Evt Card"
{
    PageType = Card;
    SourceTable = "LT PnE Evt Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 72594 "LT PnE Evt Subs"
{
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Page, Page::"LT PnE Evt Card", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure OnPageNameValidate(var Rec: Record "LT PnE Evt Rec"; var xRec: Record "LT PnE Evt Rec")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT PnE Evt Rec", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure OnTableNameValidate(var Rec: Record "LT PnE Evt Rec"; var xRec: Record "LT PnE Evt Rec"; CurrFieldNo: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PnE Evt Card", 'OnOpenPageEvent', '', false, false)]
    local procedure OnPageOpen(var Rec: Record "LT PnE Evt Rec")
    begin
    end;
}

codeunit 72591 "LT PnE Event Sub Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        R: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            R += FR.Name + '=' + Format(FR.Value) + ';';
        end;
        exit(R);
    end;

    [Test]
    procedure EventSubscription_PageFieldSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
        RR: RecordRef;
        N: Integer;
        S: Text;
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT PnE Evt Subs");
        Sub.SetRange("Subscriber Function", 'OnPageNameValidate');
        N := Sub.Count();
        Observer.Observe('pageFieldCount', Format(N));
        if Sub.FindFirst() then begin
            RR.GetTable(Sub);
            S := Dump(RR);
        end;
        Observer.Observe('pageFieldRow', S);
        Observer.Expect('pageFieldCount', '1');
        Observer.Expect('pageFieldRow', 'Subscriber Codeunit ID=72594;Subscriber Function=OnPageNameValidate;Event Type=Trigger;Publisher Object Type=Page;Publisher Object ID=72592;Published Function=OnAfterValidateEvent - 39733007;Active=Yes;Number of Calls=0;Error Information=;Originating Package ID={x};Originating App Name=AL Language Coverage Tests;Subscriber Instance=Static-Automatic;Active Manual Instances=0;');
        Observer.Verify();
    end;

    [Test]
    procedure EventSubscription_TableFieldAndPageOpenSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
        RR: RecordRef;
        S: Text;
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT PnE Evt Subs");
        Sub.SetRange("Subscriber Function", 'OnTableNameValidate');
        Observer.Observe('tableFieldCount', Format(Sub.Count()));
        if Sub.FindFirst() then begin
            RR.GetTable(Sub);
            S := Dump(RR);
        end;
        Observer.Observe('tableFieldRow', S);
        S := '';
        Sub.SetRange("Subscriber Function", 'OnPageOpen');
        Observer.Observe('pageOpenCount', Format(Sub.Count()));
        if Sub.FindFirst() then begin
            RR.GetTable(Sub);
            S := Dump(RR);
        end;
        Observer.Observe('pageOpenRow', S);
        Observer.Expect('tableFieldCount', '1');
        Observer.Expect('tableFieldRow', 'Subscriber Codeunit ID=72594;Subscriber Function=OnTableNameValidate;Event Type=Trigger;Publisher Object Type=Table;Publisher Object ID=72593;Published Function=OnAfterValidateEvent - Name;Active=Yes;Number of Calls=0;Error Information=;Originating Package ID={x};Originating App Name=AL Language Coverage Tests;Subscriber Instance=Static-Automatic;Active Manual Instances=0;');
        Observer.Expect('pageOpenCount', '1');
        Observer.Expect('pageOpenRow', 'Subscriber Codeunit ID=72594;Subscriber Function=OnPageOpen;Event Type=Trigger;Publisher Object Type=Page;Publisher Object ID=72592;Published Function=OnOpenPageEvent;Active=Yes;Number of Calls=0;Error Information=;Originating Package ID={x};Originating App Name=AL Language Coverage Tests;Subscriber Instance=Static-Automatic;Active Manual Instances=0;');
        Observer.Verify();
    end;
}
