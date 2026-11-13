// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
codeunit 51714 "Next Refresh Sync"
{
    procedure RunSync(var Header: Record "Next Refresh Header")
    var
        Stored: Record "Next Refresh Header";
        Line: Record "Next Refresh Line";
    begin
        Stored.Get(Header.Id);
        Stored.Reference := Header.Reference;
        Stored.Result := 'Mapped';
        Stored.Modify();
        Header.Get(Stored.Id);
        Line."Header Id" := Header.Id;
        Line.Text := 'New detail';
        Line.Insert();
    end;
}
