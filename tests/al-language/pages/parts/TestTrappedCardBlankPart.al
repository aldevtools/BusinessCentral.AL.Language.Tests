// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51705 "PAG TrappedCardBlankP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SetValueOnNewCardWithBlankLinkedRows()
    var
        Header: Record "Draft Probe Card Header";
        Detail: Record "Draft Probe Detail";
        Card: TestPage "Draft Probe Card";
    begin
        Initialize();
        Header.DeleteAll();
        Detail.DeleteAll();
        Header.Code := 'EXISTING';
        Header.Insert();
        Detail."Header Code" := '';
        Detail."Line No." := 10000;
        Detail.Insert();
        Card.Trap();
        Page.Run(Page::"Draft Probe Card", Header);
        Card.New();
        Card.Category.SetValue('CATEGORY');
        if Card.Category.Value() <> 'CATEGORY' then
            Error('Expected the new category to be shown.');
        Card.Close();
        Header.Get('NEW');
        Header.TestField(Category, 'CATEGORY');
        Detail.Get('', 10000);
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Draft Probe Detail";
        ProbeTable2: Record "Draft Probe Card Header";
    begin
        ProbeTable2.DeleteAll();
        ProbeTable1.DeleteAll();
    end;
}
