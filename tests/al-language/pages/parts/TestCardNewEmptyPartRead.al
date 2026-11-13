// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51749 "PAG CardNewEmptyPartR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure HostNewWithEmptyPartTrace()
    var
        Document: TestPage "Document Repro With Part";
        Row: Record "Document Repro Row";
        Trace: Codeunit "Probe Part Trace";
        Calls: Integer;
    begin
        Initialize();
        Row.Id := 1;
        Row.Insert();
        Document.OpenEdit();
        Trace.Reset();
        Document.New();
        Calls := Trace.Count();
        Document.Close();
        if Calls <> 0 then
            Error('Host New current-record observation: %1', Calls);
    end;

    local procedure InitializeFixture()
    var
        Row: Record "Document Repro Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Document Repro Row";
        ProbeTable2: Record "Document Repro Line";
    begin
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
        InitializeFixture();
    end;
}
