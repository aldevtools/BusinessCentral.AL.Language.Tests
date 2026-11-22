// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51718 "PAG CardAssistEditSav Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AssistEditRefreshesAfterSyncStoredTheEditedRow()
    var
        Trace: Codeunit "Next Refresh Trace";
        Header: Record "Next Refresh Header";
        Card: TestPage "Next Refresh Card";
    begin
        Initialize();
        Seed(1);
        Card.OpenEdit();
        Card.GoToKey(1);
        Card.Reference.SetValue('New reference');
        Trace.Reset();
        Card.Reference.AssistEdit();
        Trace.CheckNoRead();
        Card.Id.AssertEquals(1);
        Card.Reference.AssertEquals('New reference');
        Card.Refresh.AssertEquals('Mapped');
        Card.ObservedResult.AssertEquals('');
        Card.Lines.Detail.AssertEquals('New detail');
        Header.Get(1);
        Header.TestField(Reference, 'New reference');
        Header.TestField(Result, 'Mapped');
        Card.Close();
    end;

    local procedure Seed(Id: Integer)
    var
        Header: Record "Next Refresh Header";
    begin
        Header.Id := Id;
        Header.Reference := 'Original';
        Header.Active := true;
        Header.Insert();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Next Refresh Header";
        ProbeTable2: Record "Next Refresh Line";
    begin
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
    end;
}
