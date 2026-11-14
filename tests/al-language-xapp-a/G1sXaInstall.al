// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Probe (al-runner issue 8071; tests: tests/al-language/install-upgrade/G1sInstallSessionTests.al): does a filter in filter group 1 (the
//   global group, which stays on every record of the table for the rest of the session: types/text-code-char/P145PageRunView.al:232-235)
//   reach another session? 98472 (install codeunit of XApp A) seeds two rows of 98470 (Qty 1 and 5), sets Qty >= 3 in filter group 1
//   through a local record and leaves it set, then counts the table with a new record (same session). XApp B's install code
//   (tests/al-language-xapp-b/G1sXbInstall.al), the main app's install code and the tests count it again with a new record.
//   Cell c (al-runner issue 7586 comment): 98473 subscribes to "System Initialization".OnAfterLogin and sets Qty >= 3 in filter group 1
//   on table 98474 in every session; XApp B's install code clears it (FilterGroup(1); SetRange(Qty)) and counts before and after.
// Install code must never fail (check-install-triggers.py): it writes only `if Insert() then;` into DataPerCompany = false tables.
// BC versions: 27 - 29

table 98470 "LT G1S Item"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 98471 "LT G1S Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Entry; Text[100]) { }
        field(2; Detail; Text[250]) { }
    }

    keys { key(PK; Entry) { Clustered = true; } }
}

table 98474 "LT G1S Login Item"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 98473 "LT G1S XA Log"
{
    procedure Log(Entry: Text; Detail: Text)
    var
        L: Record "LT G1S Log";
    begin
        L.Entry := CopyStr(Entry, 1, MaxStrLen(L.Entry));
        L.Detail := CopyStr(Detail, 1, MaxStrLen(L.Detail));
        if L.Insert() then;
    end;

    // The count and the group 1 filters a record of 98470 sees, as 'count=<n>;g1=<filters>'.
    procedure Seen(var Item: Record "LT G1S Item"): Text
    var
        G1: Text;
    begin
        Item.FilterGroup(1);
        G1 := Item.GetFilters();
        Item.FilterGroup(0);
        exit(StrSubstNo('count=%1;g1=%2', Item.Count(), G1));
    end;

    // The same for 98474.
    procedure SeenLogin(var Item: Record "LT G1S Login Item"): Text
    var
        G1: Text;
    begin
        Item.FilterGroup(1);
        G1 := Item.GetFilters();
        Item.FilterGroup(0);
        exit(StrSubstNo('count=%1;g1=%2', Item.Count(), G1));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Item: Record "LT G1S Login Item";
    begin
        Item.FilterGroup(1);
        Item.SetFilter(Qty, '>=3');
        Item.FilterGroup(0);
    end;
}

codeunit 98472 "LT G1S XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Item: Record "LT G1S Item";
        Fresh: Record "LT G1S Item";
        LoginItem: Record "LT G1S Login Item";
        Log: Codeunit "LT G1S XA Log";
    begin
        Seed('R1', 1);
        Seed('R2', 5);
        SeedLogin('L1', 1);
        SeedLogin('L2', 5);
        Log.Log('A login item', Log.SeenLogin(LoginItem));
        Item.FilterGroup(1);
        Item.SetFilter(Qty, '>=3');
        Item.FilterGroup(0);
        Log.Log('A same session', Log.Seen(Fresh));
    end;

    local procedure Seed(No: Code[20]; Qty: Integer)
    var
        Item: Record "LT G1S Item";
    begin
        Item."No." := No;
        Item.Qty := Qty;
        if Item.Insert() then;
    end;

    local procedure SeedLogin(No: Code[20]; Qty: Integer)
    var
        Item: Record "LT G1S Login Item";
    begin
        Item."No." := No;
        Item.Qty := Qty;
        if Item.Insert() then;
    end;
}
