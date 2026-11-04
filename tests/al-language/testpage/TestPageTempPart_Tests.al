// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: TP SrcTemp Part Row (60804), TP SrcTemp Part (60805), TP SrcTemp Host
//   (60806), Assert (60021)
//
// Issue #2201 (AL Runner): TestPage.<part> and the host's OWN CurrPage.<part>.Page must be
// ONE part page instance, not two. Codeunit 60803 pins this for a part bound to page
// globals; this codeunit pins the sharper form — a part declaring SourceTableTemporary,
// whose rowset only exists on whichever instance the host wrote through. A TestPage that
// reads a second, disconnected instance here sees an EMPTY table, not merely a stale value.
//
// DeleteRowRemovesThePositionedRow additionally pins that the row the TestPage navigated to
// (Host.Lines.First()) is the SAME row the part's own OnAction (Rec.Delete()) is positioned
// on — only true if TestPage navigation and the part's own Rec share one cursor.

codeunit 60807 "TP SrcTemp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DirectOpen_HostSeedsTempPart_PartShowsTheRow()
    var
        Host: TestPage "TP SrcTemp Host";
    begin
        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.First(), 'the part must show the row the host inserted from OnOpenPage');
        Assert.AreEqual('A', Host.Lines.Name.Value(), 'the row value must be what the host''s OnOpenPage set');

        Host.Close();
    end;

    [Test]
    procedure DirectOpen_HostSeedsTempPart_DeleteRowRemovesThePositionedRow()
    var
        Host: TestPage "TP SrcTemp Host";
    begin
        Host.OpenEdit();
        Host.Lines.First();

        Host.Lines.DeleteRow.Invoke();

        Assert.IsFalse(Host.Lines.First(), 'the row must be gone after the part''s own DeleteRow action ran');
        Host.Close();
    end;

    [Test]
    [HandlerFunctions('TempPartHostHandler')]
    procedure Modal_HostSeedsTempPart_HandlerSeesTheRowAndCanDeleteIt()
    var
        Host: Page "TP SrcTemp Host";
        Result: Action;
    begin
        Result := Host.RunModal();

        Assert.IsTrue(Result = Action::OK, 'the handler invoked OK, so RunModal must return OK');
    end;

    [ModalPageHandler]
    procedure TempPartHostHandler(var Dlg: TestPage "TP SrcTemp Host")
    begin
        Assert.IsTrue(Dlg.Lines.First(), 'the part must show the host-seeded row under a handler too');
        Assert.AreEqual('A', Dlg.Lines.Name.Value(), 'the row value under a handler too');

        Dlg.Lines.DeleteRow.Invoke();

        Assert.IsFalse(Dlg.Lines.First(), 'the row must be gone after DeleteRow under a handler too');
        Dlg.OK().Invoke();
    end;
}
