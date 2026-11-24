// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 8945; tests: tests/al-language/events/platform-triggers/LsLoginSubscriberTests.al): two
//   "System Initialization".OnAfterLogin subscribers of XApp B (ids 98531 and 98534, interleaved with the ids of XApp A's and XApp C's
//   subscribers) that change the SingleInstance codeunits of XApp A (tests/al-language-xapp-a/LsXaLoginSubscribers.al). B1 also
//   changes "LT LS XA State Many" and writes a row into this app's table 98515, whose database events XApp A's "Global Triggers"
//   subscribers watch. The subscribers never fail; the row is written only when GuiAllowed() is true (AutoIncrement key).
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

table 98515 "LT LS XB Write"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 98531 "LT LS XB First Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
        Many: Codeunit "LT LS XA State Many";
        Row: Record "LT LS XB Write";
    begin
        Hub.Enter('B1');
        Many.Touch('B1', 2);
        if not Hub.CanWrite() then
            exit;
        Row.Init();
        Row.Tag := 'B1';
        Row.Insert(true);
    end;
}

codeunit 98534 "LT LS XB Second Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        Hub.Enter('B2');
    end;
}
