// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal PartList (60731),
//   Test Page Modal Part NoSrc (60732), Test Page Modal Part Bound (60733), Assert (60021)
//
// The direct-open half of the subpage-part shape codeunit 60734 pins for a modal host.
// 60734 drives both hosts through `Page.RunModal()` + a [ModalPageHandler]; this codeunit
// drives the SAME two hosts through `TestPage.OpenEdit()`, which is how a test reaches a
// Worksheet-style dialog when it does not want a handler.
//
// The claim is that how the host was opened is not a property of the part: a ListPart over
// its own source table, with no SubPageLink, answers the same rowset either way. Nothing
// about a part's rowset depends on the host having a SourceTable — a FIELD SubPageLink is
// the only thing that could make it, and neither host declares one.
//
// The gating is in the arms, not in the first assertion. An implementation that answered
// "there are rows" unconditionally passes the seeded arm and fails EmptyPartStaysEmpty; one
// that answered from the first row only fails PartWalksBothDataRows; one that stood the host
// up as an inert shell (a control tree that reads defaults) fails
// HeaderFieldPushesIntoThePartPage, which requires the host's own AL to run and reach into
// the part page. The bound-host arm is the control: a change aimed at the no-SourceTable
// host must leave the host WITH a SourceTable answering exactly as it did.

codeunit 60763 "Test Page Direct Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Modal Handler Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(No: Code[20]; Descr: Text[50])
    var
        Row: Record "Test Page Modal Handler Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Descr := Descr;
        Row.Insert();
    end;

    // THE CLAIM. A part on a host with NO SourceTable finds its own rows under a directly
    // opened TestPage, exactly as codeunit 60734 pins it does under RunModal + a handler.
    [Test]
    procedure DirectOpenHost_WithoutSourceTable_PartReadsTheSeededRow()
    var
        Host: TestPage "Test Page Modal Part NoSrc";
    begin
        Initialize();
        SeedRow('A', 'Alpha');

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.First(),
            'the part must land on the seeded row of its own source table under a directly-opened host');
        Assert.AreEqual('A', Host.Lines.RowNo.Value(),
            'the part''s key control must read the seeded row');
        Assert.AreEqual('Alpha', Host.Lines.Descr.Value(),
            'the part''s Rec-bound control must read the seeded row');
        Host.Close();
    end;

    // The other edge, and the arm that refuses a "there are always rows" shortcut: with the
    // part's table empty, First() answers false. An editable insert-allowed repeater carries
    // a trailing blank new-row line (codeunit 60743), but First() does not land on it, so an
    // empty part is still empty.
    [Test]
    procedure DirectOpenHost_WithoutSourceTable_EmptyPartStaysEmpty()
    var
        Host: TestPage "Test Page Modal Part NoSrc";
    begin
        Initialize();

        Host.OpenEdit();

        Assert.IsFalse(Host.Lines.First(),
            'the part''s source table is empty, so First() must answer false rather than a blank row');
        Host.Close();
    end;

    // Two data rows in key order. Separates "the part is driven over its real rowset" from
    // "the part answers its first row for every position".
    [Test]
    procedure DirectOpenHost_WithoutSourceTable_PartWalksBothDataRows()
    var
        Host: TestPage "Test Page Modal Part NoSrc";
    begin
        Initialize();
        SeedRow('A', 'Alpha');
        SeedRow('B', 'Beta');

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.First(), 'First() must land on the first row of the part');
        Assert.AreEqual('Alpha', Host.Lines.Descr.Value(), 'the first row must read Alpha');

        Assert.IsTrue(Host.Lines.Next(), 'Next() must reach the second data row of the part');
        Assert.AreEqual('Beta', Host.Lines.Descr.Value(), 'the second row must read Beta');
        Host.Close();
    end;

    // The host's own AL must run under a direct open too: writing the header field fires its
    // OnValidate, which calls a procedure on the PART PAGE (the Worksheet header-drives-lines
    // pattern). The write-through to the table is the durable proof that both the host's
    // globals and the part page object are live, not a shell answering defaults.
    [Test]
    procedure DirectOpenHost_WithoutSourceTable_HeaderFieldPushesIntoThePartPage()
    var
        Echo: Record "Test Page Modal Handler Row";
        Host: TestPage "Test Page Modal Part NoSrc";
    begin
        Initialize();
        SeedRow('A', 'Alpha');

        Host.OpenEdit();
        Host.Mode.SetValue('FROM-DIRECT');
        Host.Close();

        Assert.IsTrue(Echo.Get('PART-TAG'),
            'the header field''s OnValidate must have reached the part page''s procedure');
        Assert.AreEqual('FROM-DIRECT', Echo.Descr,
            'the part page procedure must see the value written to the header field');
    end;

    // Control: the identical part read on a host that DOES have a SourceTable, opened the
    // same direct way. A change aimed at the no-SourceTable host must not disturb this one.
    [Test]
    procedure DirectOpenHost_WithSourceTable_PartReadsTheSeededRow()
    var
        Host: TestPage "Test Page Modal Part Bound";
    begin
        Initialize();
        SeedRow('A', 'Alpha');

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.First(),
            'the part must land on the seeded row of its own source table on a bound host too');
        Assert.AreEqual('Alpha', Host.Lines.Descr.Value(),
            'the part''s Rec-bound control must read the seeded row on a bound host too');
        Host.Close();
    end;
}
