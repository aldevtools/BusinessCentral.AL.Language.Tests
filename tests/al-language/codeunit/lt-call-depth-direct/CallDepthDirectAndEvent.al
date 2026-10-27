// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own codeunits 72884 and 72885
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the depth reached by unbounded recursion through a plain procedure and through a publisher/subscriber pair, the error text and code at the ceiling
// BC versions: 29 (27 and 28 by CI)

codeunit 72884 "LT CallDepth Worker"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Reset()
    begin
        Counter := 0;
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure Direct()
    begin
        Counter += 1;
        Direct();
    end;

    procedure ViaEvent()
    begin
        Counter += 1;
        OnDeeper();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeeper()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CallDepth Worker", 'OnDeeper', '', false, false)]
    local procedure HandleDeeper()
    begin
        ViaEvent();
    end;
}


// Writer SH, al-runner issue 5944: the error code and text when recursion through events is stopped (an integration event whose
// subscriber raises it again, and an OnAfterModifyEvent subscriber that modifies the row again without a guard), next to plain
// recursion. The depth reached is not asserted (it differed between BC versions).
table 89422 "LT SH Recursion Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Qty; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 89423 "LT SH Modify Recursor"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT SH Recursion Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyRecursionRow(var Rec: Record "LT SH Recursion Row"; var xRec: Record "LT SH Recursion Row"; RunTrigger: Boolean)
    begin
        Rec.Qty += 1;
        Rec.Modify(true);
    end;
}

codeunit 89424 "LT SH Event Recursion Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Recursion_PlainProcedure_ErrorCodeAndText()
    var
        Worker: Codeunit "LT CallDepth Worker";
        Observer: Codeunit "Probe Observer";
    begin
        Worker.Reset();
        asserterror Worker.Direct();
        Observer.ObserveError('direct');
        Observer.Expect('direct|text', 'There is insufficient memory to execute this function. This can be caused by recursive function calls. Contact your system administrator.');
        Observer.Expect('direct|code', 'StackOverflow');
        Observer.Verify();
    end;

    [Test]
    procedure Recursion_ThroughAnIntegrationEvent_ErrorCodeAndText()
    var
        Worker: Codeunit "LT CallDepth Worker";
        Observer: Codeunit "Probe Observer";
    begin
        Worker.Reset();
        asserterror Worker.ViaEvent();
        Observer.ObserveError('viaEvent');
        Observer.Expect('viaEvent|text', 'Excessive recursion has been detected in event subscriber function HandleDeeper for event None that is raised in CodeUnit 72884.');
        Observer.Expect('viaEvent|code', 'RecursiveEventCall:StackOverflow');
        Observer.Verify();
    end;

    [Test]
    procedure Recursion_ModifyInOnAfterModifyEvent_ErrorCodeAndText()
    var
        Row: Record "LT SH Recursion Row";
        Stored: Record "LT SH Recursion Row";
        Recursor: Codeunit "LT SH Modify Recursor";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Code := 'R1';
        Row.Insert();
        Commit();
        BindSubscription(Recursor);
        Row.Qty := 1;
        asserterror Row.Modify(true);
        UnbindSubscription(Recursor);
        Observer.ObserveError('modify');
        Stored.Get('R1');
        Observer.Observe('stored qty', Format(Stored.Qty));
        Stored.DeleteAll();
        Commit();
        Observer.Expect('modify|text', 'Excessive recursion has been detected in event subscriber function OnAfterModifyRecursionRow for event OnAfterModifyEvent that is raised in Table 89422.');
        Observer.Expect('modify|code', 'RecursiveEventCall:StackOverflow');
        Observer.Expect('stored qty', '0');
        Observer.Verify();
    end;
}
