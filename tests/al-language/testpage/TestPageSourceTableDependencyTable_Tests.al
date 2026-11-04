// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: none — declares its own page over a dependency table, see
//   TestPageSourceTableDependencyTable_Page.al
//
// Pins TestPage behaviour on a page COMPILED BY THIS TEST APP whose SourceTable names a
// table declared by a DEPENDENCY, Base Application's "Location" (table 14) — not a page
// that ships precompiled itself (that shape is "TP GoToRecord Precompiled", 60736) and not
// a page over this app's own fixture table (every other TestPage suite here). A source-
// compiled page's SourceTable can name any table BC's own compiler can resolve, in-app or
// in a dependency, and TestPage must build a real, positionable record over it either way.
//
// AL Runner issue: https://github.com/StefanMaron/BusinessCentral.AL.Runner/issues/2452

codeunit 60909 "TP SourceTable Dep Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Loc: Record Location;
    begin
        Loc.SetFilter(Code, 'ALTSTD-*');
        Loc.DeleteAll();
    end;

    // CLAIM: a TestPage over a page whose SourceTable names a dependency's table persists a
    // field written through TestPage.<Field>.SetValue into a REAL row of that table — read
    // back through a completely separate Record variable after the TestPage closes, which a
    // page that merely looked live (Rec unbound, values silently discarded) could not pass.
    [Test]
    procedure SourceTable_DependencyTable_SetValueThenGet_PersistsRow()
    var
        Loc: Record Location;
        Card: TestPage "TP Dep Table Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Code.SetValue('ALTSTD-A');
        Card.Name.SetValue('AL Test Dependency SourceTable');
        Card.Close();

        Assert.IsTrue(Loc.Get('ALTSTD-A'),
            'a row written through the TestPage must exist in the dependency table afterwards');
        Assert.AreEqual('AL Test Dependency SourceTable', Loc.Name,
            'the persisted row must carry the value written through the TestPage field');
    end;

    // CLAIM: TestPage.GoToRecord positions the cursor on a page whose SourceTable names a
    // dependency's table, and a field read afterwards reflects the row GoToRecord moved to
    // — not always the first row, and not a stale copy.
    [Test]
    procedure SourceTable_DependencyTable_GoToRecord_PositionsCursor()
    var
        LocA: Record Location;
        LocB: Record Location;
        Card: TestPage "TP Dep Table Card";
    begin
        Initialize();

        LocA.Init();
        LocA.Code := 'ALTSTD-A';
        LocA.Name := 'AL Test Location A';
        LocA.Insert();
        LocB.Init();
        LocB.Code := 'ALTSTD-B';
        LocB.Name := 'AL Test Location B';
        LocB.Insert();

        Card.OpenEdit();
        Assert.IsTrue(Card.GoToRecord(LocB), 'GoToRecord must find the second row');
        Assert.AreEqual('AL Test Location B', Card.Name.Value,
            'the field read after GoToRecord must reflect the row it positioned on');

        Assert.IsTrue(Card.GoToRecord(LocA), 'GoToRecord must find the first row from the second');
        Assert.AreEqual('AL Test Location A', Card.Name.Value,
            'a second GoToRecord must move the cursor, not repeat the first row');
        Card.Close();
    end;
}
