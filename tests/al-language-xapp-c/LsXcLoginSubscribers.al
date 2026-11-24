// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 8945; tests: tests/al-language/events/platform-triggers/LsLoginSubscriberTests.al): two
//   "System Initialization".OnAfterLogin subscribers of XApp C (ids 98532 and 98535, interleaved with the ids of XApp A's and XApp B's
//   subscribers) that change the SingleInstance codeunits of XApp A (tests/al-language-xapp-a/LsXaLoginSubscribers.al). C1 also
//   changes "LT LS XA State Many" and writes a row into this app's table 98520, whose database events XApp A's "Global Triggers"
//   subscribers watch. The subscribers never fail; the row is written only when GuiAllowed() is true (AutoIncrement key).
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

table 98520 "LT LS XC Write"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 98532 "LT LS XC First Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
        Many: Codeunit "LT LS XA State Many";
        Row: Record "LT LS XC Write";
    begin
        Hub.Enter('C1');
        Many.Touch('C1', 3);
        if not Hub.CanWrite() then
            exit;
        Row.Init();
        Row.Tag := 'C1';
        Row.Insert(true);
    end;
}

codeunit 98535 "LT LS XC Second Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        Hub.Enter('C2');
    end;
}
