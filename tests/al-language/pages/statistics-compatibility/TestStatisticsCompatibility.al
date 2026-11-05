// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: Cloud-compatible. Fixtures: ALT Universal and Sales Order List. BC versions: 27.5+.
// local object: the versioned Statistics action used as an extension anchor is under test.
pageextension 69057 "PAG Statistics Anchor"
    extends "Sales Order List"
{
    actions
    {
#if BC29PLUS // Legacy Statistics is absent in BC29; use its public replacement.
        addafter(SalesOrderStatistics)
#else
        addafter(Statistics)
#endif
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
codeunit 69058 "PAG Statistics Compat Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    [Test]
    procedure PageExtension_AddAfterVersionedStatistics_InvokesAddedAction()
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
    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
    begin
        Cleanup.Initialize();
    end;
}
