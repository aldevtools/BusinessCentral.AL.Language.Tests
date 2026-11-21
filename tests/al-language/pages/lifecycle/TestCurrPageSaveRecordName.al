// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51746 "PAG CurrPageSaveRecor Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('HandleDocument')]
    procedure SaveRecordPublishesAutoSplitKeyToBoundSubscriber()
    var
        Host: Record "Probe Host";
        Line: Record "Probe Line";
        Shadow: Record "Probe Shadow" temporary;
        Document: Page "Probe Auto Split Document";
    begin
        Initialize();
        Host.DeleteAll();
        Line.DeleteAll();
        Host.Id := 'P';
        Host.Insert();
        Host.FilterGroup(7);
        Host.SetRecFilter();
        Host.FilterGroup(0);
        Document.Initialize(Shadow);
        Commit();
        Document.SetTableView(Host);
        Document.RunModal();
        if not Shadow.Get(10000) then
            Error('The shared shadow row was not stored.');
        if not Line.Get('P', 10000) then
            Error('The first line was not stored with key 10000.');
        if Line.ItemNo <> 'ITEM' then
            Error('The stored item number was %1.', Line.ItemNo);
    end;

    [ModalPageHandler]
    procedure HandleDocument(var Document: TestPage "Probe Auto Split Document")
    begin
        Document.Lines.ItemNo.SetValue('ITEM');
        Document.OK().Invoke();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Probe Host";
        ProbeTable2: Record "Probe Line";
        ProbeTable3: Record "Probe Shadow";
    begin
        ProbeTable3.DeleteAll();
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
    end;
}
