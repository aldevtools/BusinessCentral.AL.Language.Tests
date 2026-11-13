// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51711 "PAG WorksheetDraftClo Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CloseStoresWorksheetRowWithoutReadingEmptyPart()
    var
        Header: Record "Draft Probe Header";
        Trace: Codeunit "Draft Probe Trace";
        Worksheet: TestPage "Draft Probe Worksheet";
    begin
        Initialize();
        Header.DeleteAll();
        Worksheet.OpenEdit();
        Worksheet.Item.SetValue('ITEM');
        Worksheet.Quantity.SetValue(1);
        Trace.Reset();
        Worksheet.Close();
        if Trace.Read() <> '' then
            Error('Closing read the empty part: %1', Trace.Read());
        Header.Get('PLAN', 10000);
        Header.TestField(Item, 'ITEM');
        Header.TestField(Quantity, 1);
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Draft Probe Header";
        ProbeTable2: Record "Draft Probe Detail";
    begin
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
    end;
}
