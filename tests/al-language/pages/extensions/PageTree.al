// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72330, page 72331, codeunit 72332
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72330 "LT P123 Tree"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Indent; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 72331 "LT P123 Tree List"
{
    PageType = List;
    SourceTable = "LT P123 Tree";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Indent;
                ShowAsTree = true;
                TreeInitialState = CollapseAll;

                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Indent; Rec.Indent) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 72332 "LT P123 Tree Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_ShowAsTreeRows()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 Tree";
        P: TestPage "LT P123 Tree List";
        Names: Text;
        Count: Integer;
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1; T.Name := 'Root'; T.Indent := 0; T.Insert();
        T.Init(); T.Id := 2; T.Name := 'Child A'; T.Indent := 1; T.Insert();
        T.Init(); T.Id := 3; T.Name := 'Grandchild'; T.Indent := 2; T.Insert();
        T.Init(); T.Id := 4; T.Name := 'Child B'; T.Indent := 1; T.Insert();
        T.Init(); T.Id := 5; T.Name := 'Root 2'; T.Indent := 0; T.Insert();
        P.OpenView();
        if P.First() then
            repeat
                Count += 1;
                Names += P.Name.Value() + '/' + P.Indent.Value() + ',';
            until not P.Next();
        Observer.Observe('rows', Format(Count));
        Observer.Observe('names', Names);
        Observer.Expect('rows', '2');
        Observer.Expect('names', 'Root/0,Root 2/0,');
        Observer.Verify();
    end;
}
