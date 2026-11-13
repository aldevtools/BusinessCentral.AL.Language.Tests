// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51728 "PAG CardPartAssistEdi Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AssistEditUsesTheLinkedPrimaryKey()
    var
        Detail: Record "Linked Part Detail Row";
        Host: TestPage "Linked Part Host";
    begin
        Initialize();
        OpenHost(Host, 1, 'DETAIL-A');
        Host.Detail.Code.AssistEdit();
        Detail.Get('DETAIL-A');
        Detail.TestField("Before Assist", 'DETAIL-A');
        Detail.TestField(Marker, 1);
        Host.Close();
    end;

    [Test]
    procedure UpdateAfterAssistEditShowsInsertedDetail()
    var
        Detail: Record "Linked Part Detail Row";
        Host: TestPage "Linked Part Host";
    begin
        Initialize();
        OpenHost(Host, 2, 'DETAIL-B');
        Host.Detail.Code.AssistEdit();
        Host.Detail.Marker.AssistEdit();
        Host.Detail.Marker.AssertEquals(2);
        Detail.Get('DETAIL-B');
        Detail.TestField(Marker, 2);
        Host.Close();
    end;

    local procedure OpenHost(var Host: TestPage "Linked Part Host"; Id: Integer; DetailCode: Code[20])
    var
        Header: Record "Linked Part Host Row";
    begin
        Header.Id := Id;
        Header.Insert();
        Host.OpenEdit();
        Host.GoToRecord(Header);
        Host."Detail Code".SetValue(DetailCode);
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Linked Part Host Row";
        ProbeTable2: Record "Linked Part Detail Row";
    begin
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
    end;
}
