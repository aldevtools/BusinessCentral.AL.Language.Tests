// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: Cloud-compatible public page metadata. Fixtures: ALT Universal and public Microsoft pages. BC 27.5+.
// local object: the availability of a named action as an extension anchor is under test.
#if not BC29PLUS // The obsolete Statistics action is absent in the BC29 source; measure replacements there.
pageextension 69057 "PAG Legacy Statistics Anchor" extends "Sales Order List"
{
    actions
    {
        addafter(Statistics)
        {
            action(NeutralMarker)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "ALT Universal";
                begin
                    Row."Entry No." := 7742;
                    Row."Text Field" := 'statistics-anchor-42';
                    Row.Insert(false);
                end;
            }
        }
    }
}
#endif
codeunit 69058 "PAG Statistics Compat Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    [Test]
    procedure TestPage_StatisticsAction_VersionedName_IsEnabledForSeededDocument()
    var
        View: TestPage "Sales Invoice";
        Header: Record "Sales Header";
    begin
        Initialize();
        Header.Get(Header."Document Type"::Invoice, 'NEUTRAL42');
        View.OpenView();
        if not View.GoToRecord(Header) then
            Error('Expected the seeded invoice.');
#if BC29PLUS // The replacement is the public SalesStatistics action on BC29.
        if not View.SalesStatistics.Enabled() then
#else
        if not View.Statistics.Enabled() then
#endif
            Error('Expected the Statistics action enabled for NEUTRAL42.');
        View.Close();
    end;
#if not BC29PLUS // The legacy extension anchor is only exercised where it exists.
    [Test]
    procedure PageExtension_AddAfterLegacyStatistics_InvokesAddedAction()
    var
        View: TestPage "Sales Order List";
        Row: Record "ALT Universal";
    begin
        Initialize();
        View.OpenView();
        View.NeutralMarker.Invoke();
        View.Close();
        Row.Get(7742);
        if Row."Text Field" <> 'statistics-anchor-42' then
            Error('Expected statistics-anchor-42, actual %1.', Row."Text Field");
    end;
#endif
    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        Header: Record "Sales Header";
    begin
        Cleanup.Initialize();
        Header.DeleteAll(false);
        Header."Document Type" := Header."Document Type"::Invoice;
        Header."No." := 'NEUTRAL42';
        Header.Insert(false);
    end;
}
