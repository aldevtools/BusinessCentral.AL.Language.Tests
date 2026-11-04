// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P99 Row, LT P99 Setup, LT P99 List, LT P99 Card from P99Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: the field value of a new row on a list / card whose page sets a filter on F in filter group 0 and / or 2 in OnOpenPage

codeunit 70411 "LT P99 NewRow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup(G0: Code[10]; G2: Code[10])
    var
        Row: Record "LT P99 Row";
        Cfg: Record "LT P99 Setup";
    begin
        Row.DeleteAll();
        Cfg.DeleteAll();
        Cfg.K := 'S';
        Cfg.G0 := G0;
        Cfg.G2 := G2;
        Cfg.Insert();
        Row.Id := 'R1';
        Row.F := 'A';
        Row.Insert();
        Row.Id := 'R2';
        Row.F := 'B';
        Row.Insert();
    end;

    local procedure ListCase(var Observer: Codeunit "Probe Observer"; Tag: Text; G0: Code[10]; G2: Code[10])
    var
        List: TestPage "LT P99 List";
        Row: Record "LT P99 Row";
    begin
        Setup(G0, G2);
        List.OpenEdit();
        List.New();
        Observer.Observe(Tag + '-list-new-F', '[' + List.FCtl.Value() + ']');
        List.IdCtl.SetValue('NEW');
        Observer.Observe(Tag + '-list-new-F-afterid', '[' + List.FCtl.Value() + ']');
        List.Close();
        if Row.Get('NEW') then
            Observer.Observe(Tag + '-list-db-F', '[' + Row.F + ']')
        else
            Observer.Observe(Tag + '-list-db-F', 'no row');
    end;

    local procedure CardCase(var Observer: Codeunit "Probe Observer"; Tag: Text; G0: Code[10]; G2: Code[10])
    var
        Card: TestPage "LT P99 Card";
        Row: Record "LT P99 Row";
    begin
        Setup(G0, G2);
        Card.OpenNew();
        Observer.Observe(Tag + '-card-new-F', '[' + Card.FCtl.Value() + ']');
        Card.IdCtl.SetValue('NEW');
        Observer.Observe(Tag + '-card-new-F-afterid', '[' + Card.FCtl.Value() + ']');
        Card.Close();
        if Row.Get('NEW') then
            Observer.Observe(Tag + '-card-db-F', '[' + Row.F + ']')
        else
            Observer.Observe(Tag + '-card-db-F', 'no row');
    end;

    [Test]
    procedure P99_List_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListCase(Observer, 'none', '', '');
        ListCase(Observer, 'g0A', 'A', '');
        ListCase(Observer, 'g2A', '', 'A');
        Observer.Expect('none-list-new-F', '[]');
        Observer.Expect('none-list-new-F-afterid', '[]');
        Observer.Expect('none-list-db-F', '[]');
        Observer.Expect('g0A-list-new-F', '[]');
        Observer.Expect('g0A-list-new-F-afterid', '[]');
        Observer.Expect('g0A-list-db-F', '[]');
        Observer.Expect('g2A-list-new-F', '[]');
        Observer.Expect('g2A-list-new-F-afterid', '[]');
        Observer.Expect('g2A-list-db-F', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_List_BothGroups()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListCase(Observer, 'g0A-g2A', 'A', 'A');
        ListCase(Observer, 'g0A-g2B', 'A', 'B');
        ListCase(Observer, 'g0B-g2A', 'B', 'A');
        Observer.Expect('g0A-g2A-list-new-F', '[]');
        Observer.Expect('g0A-g2A-list-new-F-afterid', '[]');
        Observer.Expect('g0A-g2A-list-db-F', '[]');
        Observer.Expect('g0A-g2B-list-new-F', '[]');
        Observer.Expect('g0A-g2B-list-new-F-afterid', '[]');
        Observer.Expect('g0A-g2B-list-db-F', '[]');
        Observer.Expect('g0B-g2A-list-new-F', '[]');
        Observer.Expect('g0B-g2A-list-new-F-afterid', '[]');
        Observer.Expect('g0B-g2A-list-db-F', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_Card_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardCase(Observer, 'none', '', '');
        CardCase(Observer, 'g0A', 'A', '');
        CardCase(Observer, 'g2A', '', 'A');
        Observer.Expect('none-card-new-F', '[]');
        Observer.Expect('none-card-new-F-afterid', '[]');
        Observer.Expect('none-card-db-F', '[]');
        Observer.Expect('g0A-card-new-F', '[]');
        Observer.Expect('g0A-card-new-F-afterid', '[]');
        Observer.Expect('g0A-card-db-F', '[]');
        Observer.Expect('g2A-card-new-F', '[]');
        Observer.Expect('g2A-card-new-F-afterid', '[]');
        Observer.Expect('g2A-card-db-F', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_Card_BothGroups()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardCase(Observer, 'g0A-g2A', 'A', 'A');
        CardCase(Observer, 'g0A-g2B', 'A', 'B');
        CardCase(Observer, 'g0B-g2A', 'B', 'A');
        Observer.Expect('g0A-g2A-card-new-F', '[]');
        Observer.Expect('g0A-g2A-card-new-F-afterid', '[]');
        Observer.Expect('g0A-g2A-card-db-F', '[]');
        Observer.Expect('g0A-g2B-card-new-F', '[]');
        Observer.Expect('g0A-g2B-card-new-F-afterid', '[]');
        Observer.Expect('g0A-g2B-card-db-F', '[]');
        Observer.Expect('g0B-g2A-card-new-F', '[]');
        Observer.Expect('g0B-g2A-card-new-F-afterid', '[]');
        Observer.Expect('g0B-g2A-card-db-F', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_List_OpenNewAndFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P99 List";
    begin
        Setup('', 'A');
        List.OpenNew();
        Observer.Observe('opennew-F', '[' + List.FCtl.Value() + ']');
        Observer.Observe('opennew-Id', '[' + List.IdCtl.Value() + ']');
        List.Close();
        Setup('A', '');
        List.OpenNew();
        Observer.Observe('g0-opennew-F', '[' + List.FCtl.Value() + ']');
        List.Close();
        Setup('A', 'B');
        List.OpenView();
        Observer.Observe('g0A-g2B-view-first', Format(List.First()));
        Observer.Observe('g0A-g2B-view-id', '[' + List.IdCtl.Value() + ']');
        List.Close();
        Setup('', 'A');
        List.OpenView();
        Observer.Observe('g2A-view-first', Format(List.First()));
        Observer.Observe('g2A-view-id', List.IdCtl.Value());
        Observer.Observe('g2A-view-next', Format(List.Next()));
        List.Close();
        Observer.Expect('opennew-F', '[]');
        Observer.Expect('opennew-Id', '[]');
        Observer.Expect('g0-opennew-F', '[]');
        Observer.Expect('g0A-g2B-view-first', 'No');
        Observer.Expect('g0A-g2B-view-id', '[]');
        Observer.Expect('g2A-view-first', 'Yes');
        Observer.Expect('g2A-view-id', 'R1');
        Observer.Expect('g2A-view-next', 'No');
        Observer.Verify();
    end;
}
