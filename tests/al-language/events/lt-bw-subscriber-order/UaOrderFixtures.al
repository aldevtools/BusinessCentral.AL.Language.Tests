// Cross-app subscriber order probe (writer UA, al-runner NP Retail install refusal on OnAfterGetDatabaseTableTriggerSetup): a platform
// table event (Company OnBeforeModifyEvent) with two subscribers in each of six apps, among them apps that do not depend on each other.
// Each subscriber appends its tag to "Display Name" of a temporary Company record named 'LT UA ORDER' and does nothing for any
// other record. Tests: tests/al-language/events/lt-bw-subscriber-order/BwSubscriberOrderTests.al (writer UA).

codeunit 90240 "LT UA M Subs 1"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT UA ORDER' then
            exit;
        Rec."Display Name" += 'M1;';
    end;
}

codeunit 90241 "LT UA M Subs 2"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT UA ORDER' then
            exit;
        Rec."Display Name" += 'M2;';
    end;
}

// Raises the event once from this app's install routine (per company) and keeps the order for the test.
table 90240 "LT UA Install Order"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Order"; Text[250]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 90242 "LT UA Order Raiser"
{
    procedure Raise(): Text
    var
        TempCompany: Record Company temporary;
    begin
        TempCompany.Init();
        TempCompany.Name := 'LT UA ORDER';
        TempCompany.Insert();
        TempCompany."Display Name" := '';
        TempCompany.Modify();
        exit(TempCompany."Display Name");
    end;
}

// Runs in this app's install session: a subscriber of "Extension Triggers".OnInstallAppPerCompany (no Install codeunit, see
// .github/scripts/check-install-triggers.py). It cannot raise: the raise runs in a TryFunction and the row is written with `if Insert() then;`.
codeunit 90243 "LT UA Install"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        Row: Record "LT UA Install Order";
        Order: Text;
    begin
        if not TryRaise(Order) then
            Order := 'error';
        Row."Entry No." := 1;
        Row."Order" := CopyStr(Order, 1, MaxStrLen(Row."Order"));
        if Row.Insert() then;
    end;

    [TryFunction]
    local procedure TryRaise(var Order: Text)
    var
        Raiser: Codeunit "LT UA Order Raiser";
    begin
        Order := Raiser.Raise();
    end;
}
