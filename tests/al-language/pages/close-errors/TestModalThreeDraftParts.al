// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51771 "PAG ModalThreeDraftPa Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('InvokeFailure')]
    procedure ThreeDraftListPartsCloseAndKeepValidationError()
    var
        Row: Record "Three Part Probe Row";
        Document: Page "Three Part Probe Document";
        Trace: Codeunit "Three Part Probe Trace";
    begin
        Initialize();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Trace.Reset();
        Document.SetRecord(Row);

        asserterror Document.RunModal();

        if StrPos(GetLastErrorText(), 'Repro part validation failed.') = 0 then
            Error('Unexpected error: %1', GetLastErrorText());
        if Trace.Read() <> 'Part:None|Part:None|Part:None|Document:OK|' then
            Error('Unexpected close trace: %1', Trace.Read());
    end;

    [ModalPageHandler]
    procedure InvokeFailure(var Document: TestPage "Three Part Probe Document")
    begin
        Document.Lines.New();
        Document.OtherLines.New();
        Document.ThirdLines.New();
        Document.Lines.Payload.SetValue('INPUT');
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Three Part Probe Row";
    begin
        ProbeTable1.DeleteAll();
    end;
}
