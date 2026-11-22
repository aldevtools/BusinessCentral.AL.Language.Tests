// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-boolean-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51775 "REC TenantMediaZeroGu Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DirectTenantMediaInsertKeepsExplicitZeroGuid()
    var
        MediaRow: Record "Tenant Media";
        Id: Guid;
    begin
        Initialize();
        if MediaRow.Get(Id) then
            Error('The synthetic tenant already contains a zero GUID media row.');
        MediaRow.Init();
        MediaRow.ID := Id;
        MediaRow.Description := 'Synthetic placeholder';
        MediaRow.Insert(false);
        if MediaRow.ID <> Id then
            Error('Insert replaced the zero GUID.');
        Clear(MediaRow);
        MediaRow.Get(Id);
        MediaRow.TestField(Description, 'Synthetic placeholder');
        if MediaRow.Insert(false) then
            Error('A second zero GUID Insert unexpectedly succeeded.');
        MediaRow.Delete();
    end;

    local procedure Initialize()
    begin
        // This test uses its own uniquely identified synthetic row.
    end;
}
