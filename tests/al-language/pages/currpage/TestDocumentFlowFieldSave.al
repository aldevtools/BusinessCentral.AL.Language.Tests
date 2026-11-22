// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51723 "PAG DocumentFlowField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CalculatedFieldDoesNotSaveStaleDocument()
    var
        Header: Record "Action Header Row";
        Document: TestPage "Action Header Document";
    begin
        Initialize();
        Seed(Header, 1);
        Document.OpenView();
        Document.GoToRecord(Header);
        Document.CalculateAndWrite.Invoke();
        Header.Get(1);
        Header.TestField(Description, 'Written by action');
        Document.Description.AssertEquals('Written by action');
        Document.Close();
    end;

    local procedure Seed(var Header: Record "Action Header Row"; Id: Integer)
    var
        Link: Record "Action Link Row";
    begin
        Header.Id := Id;
        Header.Description := 'Original';
        Header.Insert();
        Link.Id := Id;
        Link.Code := 'RELATED';
        Link.Insert();
        Commit();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Action Header Row";
        ProbeTable2: Record "Action Link Row";
    begin
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
    end;
}
