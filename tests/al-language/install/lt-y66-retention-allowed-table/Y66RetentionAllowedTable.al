// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-retention-policies
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93405, test codeunit 93411
// Probe (al-runner issue 6665, writer Y66): what BC does with the step the reporter's install routine runs last: an app registers its own
// table with "Reten. Pol. Allowed Tables".AddAllowedTable, and a test validates and inserts a "Retention Policy Setup" row for it. Here the
// registration runs in the test (no install codeunit), so each state is observed: the table before it is registered (IsAllowedTable, the
// Validate error text and code), AddAllowedTable twice, Validate + Insert(true) after it, RemoveAllowedTable, and a Base Application table
// nobody registers (18). On BC the reporter's install runs to its end, so the reporter's test passes.
// Pinned elsewhere: Base Application's own registration of table 405 (install/TestRetenPolAllowedTables_Tests.al).
// BC versions: 27, 28, 29

using System.DataAdministration;

table 93405 "LT Y66 RP Buffer"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93411 "LT Y66 Retention Allowed Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";

    [Test]
    procedure Y66_RetentionAllowedTable_States()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        Cleanup();
        Observer.Observe('allowed before', Format(RetenPolAllowedTables.IsAllowedTable(Database::"LT Y66 RP Buffer")));
        Observer.Observe('validate before', TryValidate(Database::"LT Y66 RP Buffer"));
        Observer.Observe('validate customer', TryValidate(18));
        Observer.Observe('insert before', TryValidateInsert(Database::"LT Y66 RP Buffer"));
        Observer.Observe('add', Format(RetenPolAllowedTables.AddAllowedTable(Database::"LT Y66 RP Buffer")));
        Observer.Observe('add again', Format(RetenPolAllowedTables.AddAllowedTable(Database::"LT Y66 RP Buffer")));
        Observer.Observe('allowed after', Format(RetenPolAllowedTables.IsAllowedTable(Database::"LT Y66 RP Buffer")));
        Observer.Observe('date field', Format(RetenPolAllowedTables.GetDefaultDateFieldNo(Database::"LT Y66 RP Buffer")));
        Observer.Observe('insert after', TryInsert(Database::"LT Y66 RP Buffer"));
        RetentionPolicySetup.SetRange("Table Id", Database::"LT Y66 RP Buffer");
        Observer.Observe('setup rows', Format(RetentionPolicySetup.Count()));
        Observer.Observe('remove with setup row', Format(RetenPolAllowedTables.RemoveAllowedTable(Database::"LT Y66 RP Buffer")));
        Observer.Observe('allowed after remove', Format(RetenPolAllowedTables.IsAllowedTable(Database::"LT Y66 RP Buffer")));
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y66_RetentionAllowedTable_ReporterShape()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        Cleanup();
        RetenPolAllowedTables.AddAllowedTable(Database::"LT Y66 RP Buffer");
        RetentionPolicySetup.Validate("Table Id", Database::"LT Y66 RP Buffer");
        RetentionPolicySetup.Insert(true);
        Observer.Observe('table name', RetentionPolicySetup."Table Name");
        Observer.Observe('enabled', Format(RetentionPolicySetup.Enabled));
        Cleanup();
        Observer.Finish();
    end;

    local procedure Cleanup()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(Database::"LT Y66 RP Buffer") then
            RetentionPolicySetup.Delete(true);
        RetenPolAllowedTables.RemoveAllowedTable(Database::"LT Y66 RP Buffer");
    end;

    local procedure TryValidate(TableId: Integer): Text
    begin
        ClearLastError();
        if DoValidate(TableId) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoValidate(TableId: Integer)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        RetentionPolicySetup.Validate("Table Id", TableId);
    end;

    local procedure TryInsert(TableId: Integer): Text
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        // No database write inside a TryFunction: only the Validate is caught.
        ClearLastError();
        if not DoValidateInto(RetentionPolicySetup, TableId) then
            exit(GetLastErrorText() + '|' + GetLastErrorCode());
        RetentionPolicySetup.Insert(true);
        exit('ok');
    end;

    [TryFunction]
    local procedure DoValidateInto(var RetentionPolicySetup: Record "Retention Policy Setup"; TableId: Integer)
    begin
        RetentionPolicySetup.Validate("Table Id", TableId);
    end;

    local procedure TryValidateInsert(TableId: Integer): Text
    begin
        ClearLastError();
        if DoValidateInsert(TableId) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoValidateInsert(TableId: Integer)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Insert(true);
    end;
}
