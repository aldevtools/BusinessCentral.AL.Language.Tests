// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51762 "PAG DocumentOpenNewMu Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestPage_OpenNew_VariableControlCanModifyDocument()
    var
        Row: Record "Document Repro Row 51760";
        Document: TestPage "Document Repro Page 51761";
    begin
        Initialize();

        Document.OpenNew();
        if Document.Id.Value = '-1' then
            Error('Unexpected initial key.');
        Document.Scan.Value('SCANNED');
        Row.Get(10);
        if Row.Payload <> 'SCANNED' then
            Error('Expected stored payload SCANNED. Got %1.', Row.Payload);
        Document.Close();
    end;

    [Test]
    procedure OpenNewDocumentWithLinkedListAndCardPartsInsertsBeforeScan()
    var
        Row: Record "Document Repro Row 51760";
        Document: TestPage "Document Repro With Part 51763";
    begin
        Initialize();

        Document.OpenNew();
        if Document.Id.Value = '-1' then
            Error('Unexpected initial key.');
        Document.Scan.Value('SCANNED');
        Row.Get(10);
        if Row.Payload <> 'SCANNED' then
            Error('Expected stored payload SCANNED. Got %1.', Row.Payload);
        Document.Close();
    end;

    local procedure InitializeFixture()
    var
        Row: Record "Document Repro Row 51760";
    begin
        Row.DeleteAll();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Document Repro Row 51760";
        ProbeTable2: Record "Document Repro Line 51764";
    begin
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
        InitializeFixture();
    end;
}
