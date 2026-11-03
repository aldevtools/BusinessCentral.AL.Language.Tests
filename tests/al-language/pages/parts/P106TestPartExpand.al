// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P106 Item/Group/Log tables, LT P106 Log codeunit, pages LT P106 Card / List / Group List / Sub / Host from P106Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPart.Expand(true) and TestPart.IsExpanded on a flat list part (the existing corpus note says collapsing raises a raw CLR exception that asserterror cannot trap: only Expand(true) with the cursor on a data row is called, never Expand(false))
// BC versions: 29 (27 and 28 by CI)

codeunit 72415 "LT P106 TestPart Expand"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P106 Log";

    [Test]
    procedure P106_PartExpand_True()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P106 Host";
    begin
        Log.Seed();
        Host.OpenEdit();
        Host.GoToKey('G1');
        Observer.Observe('first', Format(Host.SubPart.First()));
        Host.SubPart.Expand(true);
        Observer.Observe('after_expand_row', Host.SubPart.NoCtl.Value());
        Observer.Observe('is_expanded', Format(Host.SubPart.IsExpanded()));
        Host.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('after_expand_row', 'A');
        Observer.Expect('is_expanded', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P106_PartExpand_Twice_And_Move()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P106 Host";
    begin
        Log.Seed();
        Host.OpenEdit();
        Host.GoToKey('G1');
        Host.SubPart.First();
        Host.SubPart.Expand(true);
        Host.SubPart.Expand(true);
        Observer.Observe('is_expanded_twice', Format(Host.SubPart.IsExpanded()));
        Observer.Observe('next', Format(Host.SubPart.Next()));
        Observer.Observe('row2', Host.SubPart.NoCtl.Value());
        Observer.Observe('is_expanded_row2', Format(Host.SubPart.IsExpanded()));
        Observer.Observe('prev', Format(Host.SubPart.Previous()));
        Observer.Observe('is_expanded_row1', Format(Host.SubPart.IsExpanded()));
        Host.Close();
        Observer.Expect('is_expanded_twice', 'No');
        Observer.Expect('next', 'Yes');
        Observer.Expect('row2', 'B');
        Observer.Expect('is_expanded_row2', 'No');
        Observer.Expect('prev', 'Yes');
        Observer.Expect('is_expanded_row1', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P106_PartIsExpanded_Fresh()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT P106 Host";
    begin
        Log.Seed();
        Host.OpenEdit();
        Host.GoToKey('G2');
        Host.SubPart.First();
        Observer.Observe('is_expanded_fresh', Format(Host.SubPart.IsExpanded()));
        Host.Close();
        Observer.Expect('is_expanded_fresh', 'No');
        Observer.Verify();
    end;
}
