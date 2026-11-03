// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-retention-policies
// Scope: in-scope
// Fixtures used: Assert (60021)
//
// Runner-gap test (see CONTRIBUTING.md). Proves what a real BC tenant answers for the
// retention-policy allowed-table list an installed application registers for ITS OWN tables.
//
// Base Application's codeunit 3999 "Reten. Pol. Install - BaseApp" adds table 405
// "Change Log Entry" to that list — from its own install trigger and again from its
// OnBeforeOnRun subscriber on codeunit 2 "Company-Initialize". System Application's
// "Reten. Pol. Allowed Tbl. Impl.".ModuleOwnsTable gates that add on the CALLING module
// owning the table, comparing AllObj."App Runtime Package ID" against the caller's
// Published Application."Runtime Package ID", so the entry only appears when the platform
// attributes the call to Base Application.
//
// That is the behaviour AlRunner#3054 got wrong: it loaded Base Application's five
// ReadyToRun DLL chunks but gave only the first one an app identity, so a call out of any
// other chunk was attributed to System Application, the ownership check correctly refused,
// and codeunit 2 "Company-Initialize" then aborted with
// "Table 405 Change Log Entry is not in the list of allowed tables".
//
// Table ids are written as literals rather than Database::"..." so this file needs no
// dependency on the Base Application namespaces the two tables live in; the names are in
// the assertion messages.
//
// NOTE: deliberately no Initialize()/DeleteAll() — this codeunit owns no tables and reads
// state established at install/company-initialisation time. Clearing anything would defeat
// the test's purpose, and the list is read through a Public System Application API rather
// than by touching the internal "Retention Policy Allowed Table" table directly.

using System.DataAdministration;

codeunit 60293 "Test Reten Pol Allowed Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";

    trigger OnRun()
    begin
    end;

    [Test]
    procedure RetenPolAllowedTables_IsAllowedTable_BaseAppRegisteredChangeLogEntry_IsTrue()
    // CLAIM: table 405 "Change Log Entry" is in the retention-policy allowed-table list,
    // because Base Application — which owns it — registered it.
    begin
        Assert.IsTrue(
            RetenPolAllowedTables.IsAllowedTable(405),
            'Table 405 "Change Log Entry" must be in the retention-policy allowed-table list; Base Application registers it for its own table');
    end;

    [Test]
    procedure RetenPolAllowedTables_GetDefaultDateFieldNo_ChangeLogEntry_IsSystemCreatedAt()
    // CLAIM: the registration carries the concrete date field Base Application registered it
    // with — field 2000000001 SystemCreatedAt — not merely "some entry exists".
    begin
        Assert.AreEqual(
            2000000001,
            RetenPolAllowedTables.GetDefaultDateFieldNo(405),
            'Table 405 "Change Log Entry" must be registered against SystemCreatedAt (2000000001)');
    end;

    [Test]
    procedure RetenPolAllowedTables_IsAllowedTable_UnregisteredTable_IsFalse()
    // CLAIM: the list is not "everything" — a Base Application table nobody registers a
    // retention policy for is absent. Without this, an implementation answering true for
    // every table id would satisfy the two tests above.
    begin
        Assert.IsFalse(
            RetenPolAllowedTables.IsAllowedTable(18),
            'Table 18 "Customer" must NOT be in the retention-policy allowed-table list');
    end;
}
