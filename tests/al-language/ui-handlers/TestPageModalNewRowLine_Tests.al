// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-next-method
// Scope: in-scope
// Fixtures used: Test Modal NRL Row (60297), Test Modal NRL Plain Row (60306),
//   Test Modal NRL ReEditable (60298), Test Modal NRL Plain (60299),
//   Test Modal NRL NotEditable (60302), Test Modal NRL Plain Lookup (60307)
//
// Does a list page handed to a [ModalPageHandler] carry the blank new-row line that codeunit
// 60743 pins for an editable, insert-allowed list the test opens with OpenEdit?
//
// Two inputs could decide it, and this suite separates them:
//
//   * lookup mode: Page.RunModal(0, Rec) and Page.LookupMode(true) + RunModal();
//   * the declared Editable property, with and without CurrPage.Editable := true in OnOpenPage.
//
// Every arm seeds four rows (A, B, C, D), filters out B, and walks the page from First() until
// Next() answers false, recording each "No." value. '[A][C][D]' means no new-row line; a
// trailing '[]' is the blank new-row line.
//
// The "plain page, not lookup" arm is the control: it shows that a page reached through a
// handler can carry a new-row line at all, so the arms answering without one are measuring
// the input they vary.
//
// Measured on BC 27.0 and 28.2: the declared Editable = false hides the new-row line whatever
// OnOpenPage does with CurrPage.Editable, and TestPage.Editable() stays false; LookupMode(true)
// hides it on a page with no Editable property; Page.RunModal(0, Rec) and Page.RunModal(id, Rec)
// do not.
//
// Seen on Microsoft's own tests: Base Application page 5123 "Opportunity List" declares
// Editable = false and sets CurrPage.Editable := true in OnOpenPage; codeunit 136215 opens it
// with PAGE.RunModal(0, Opportunity) and counts its rows with no blank row.

codeunit 60309 "Test Modal New Row Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Seen: Text;

    local procedure Seed()
    var
        Row: Record "Test Modal NRL Row";
    begin
        Seen := '';
        Row.DeleteAll();
        AddRow('A', false);
        AddRow('B', true);
        AddRow('C', false);
        AddRow('D', false);
    end;

    local procedure AddRow(No: Code[20]; IsClosed: Boolean)
    var
        Row: Record "Test Modal NRL Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Closed := IsClosed;
        Row.Insert();
    end;

    local procedure SeedPlain()
    var
        Row: Record "Test Modal NRL Plain Row";
    begin
        Seen := '';
        Row.DeleteAll();
        AddPlainRow('A', false);
        AddPlainRow('B', true);
        AddPlainRow('C', false);
        AddPlainRow('D', false);
    end;

    local procedure AddPlainRow(No: Code[20]; IsClosed: Boolean)
    var
        Row: Record "Test Modal NRL Plain Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Closed := IsClosed;
        Row.Insert();
    end;

    // ---- Declared Editable = false, CurrPage.Editable := true in OnOpenPage ----------------

    [Test]
    [HandlerFunctions('ReEditableHandler')]
    procedure ReEditable_RunModalZero_HasNoNewRowLine()
    var
        Row: Record "Test Modal NRL Row";
    begin
        Seed();
        Row.SetRange(Closed, false);
        Page.RunModal(0, Row);
        Assert.AreEqual('[A][C][D]', Seen,
            'Page.RunModal(0, Rec) on a re-enabled Editable = false list: rows walked by the handler');
    end;

    [Test]
    [HandlerFunctions('ReEditableHandler')]
    procedure ReEditable_LookupModeTrue_HasNoNewRowLine()
    var
        Row: Record "Test Modal NRL Row";
        ListPage: Page "Test Modal NRL ReEditable";
    begin
        Seed();
        Row.SetRange(Closed, false);
        ListPage.SetTableView(Row);
        ListPage.LookupMode(true);
        ListPage.RunModal();
        Assert.AreEqual('[A][C][D]', Seen,
            'LookupMode(true) + RunModal() on a re-enabled Editable = false list: rows walked by the handler');
    end;

    [Test]
    [HandlerFunctions('ReEditableHandler')]
    procedure ReEditable_RunModalById_HasNoNewRowLine()
    var
        Row: Record "Test Modal NRL Row";
    begin
        Seed();
        Row.SetRange(Closed, false);
        Page.RunModal(Page::"Test Modal NRL ReEditable", Row);
        Assert.AreEqual('[A][C][D]', Seen,
            'Page.RunModal(id, Rec), not lookup mode, on a re-enabled Editable = false list: rows walked by the handler');
    end;

    [Test]
    procedure ReEditable_OpenEdit_HasNoNewRowLine()
    var
        TP: TestPage "Test Modal NRL ReEditable";
    begin
        Seed();
        TP.OpenEdit();
        TP.Filter.SetFilter(Closed, Format(false));
        if TP.First() then
            repeat
                Seen += '[' + TP.RowNo.Value() + ']';
            until not TP.Next();
        TP.Close();
        Assert.AreEqual('[A][C][D]', Seen,
            'OpenEdit on a re-enabled Editable = false list: rows walked by the test');
    end;

    // What TestPage.Editable() answers inside the handler for the same page, not lookup mode.
    [Test]
    [HandlerFunctions('ReEditableEditableHandler')]
    procedure ReEditable_RunModalById_EditableAnswer()
    var
        Row: Record "Test Modal NRL Row";
    begin
        Seed();
        Row.SetRange(Closed, false);
        Page.RunModal(Page::"Test Modal NRL ReEditable", Row);
        Assert.AreEqual(Format(false), Seen,
            'TestPage.Editable() in a handler for a re-enabled Editable = false list opened with Page.RunModal(id, Rec)');
    end;

    // ---- Declared Editable = false, nothing re-enables it -------------------------------------

    [Test]
    [HandlerFunctions('NotEditableHandler')]
    procedure NotEditable_RunModalById_HasNoNewRowLine()
    var
        Row: Record "Test Modal NRL Row";
    begin
        Seed();
        Row.SetRange(Closed, false);
        Page.RunModal(Page::"Test Modal NRL NotEditable", Row);
        Assert.AreEqual('[A][C][D]', Seen,
            'Page.RunModal(id, Rec) on an Editable = false list: rows walked by the handler');
    end;

    // ---- No Editable property ------------------------------------------------------------------

    // The control arm: not lookup mode, nothing declared read-only.
    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Plain_RunModalById_HasTheNewRowLine()
    var
        Row: Record "Test Modal NRL Row";
    begin
        Seed();
        Row.SetRange(Closed, false);
        Page.RunModal(Page::"Test Modal NRL Plain", Row);
        Assert.AreEqual('[A][C][D][]', Seen,
            'Page.RunModal(id, Rec), not lookup mode, on a list with no Editable property: rows walked by the handler');
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Plain_LookupModeFalse_HasTheNewRowLine()
    var
        Row: Record "Test Modal NRL Row";
        ListPage: Page "Test Modal NRL Plain";
    begin
        Seed();
        Row.SetRange(Closed, false);
        ListPage.SetTableView(Row);
        ListPage.LookupMode(false);
        ListPage.RunModal();
        Assert.AreEqual('[A][C][D][]', Seen,
            'LookupMode(false) + RunModal() on a list with no Editable property: rows walked by the handler');
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Plain_LookupModeTrue_HasNoNewRowLine()
    var
        Row: Record "Test Modal NRL Row";
        ListPage: Page "Test Modal NRL Plain";
    begin
        Seed();
        Row.SetRange(Closed, false);
        ListPage.SetTableView(Row);
        ListPage.LookupMode(true);
        ListPage.RunModal();
        Assert.AreEqual('[A][C][D]', Seen,
            'LookupMode(true) + RunModal() on a list with no Editable property: rows walked by the handler');
    end;

    // Page.RunModal(0, Rec) is not the same as LookupMode(true) here: the page it opens keeps
    // its new-row line. So on page 5123 it is the declared Editable = false that hides it.
    [Test]
    [HandlerFunctions('PlainLookupHandler')]
    procedure Plain_RunModalZero_HasTheNewRowLine()
    var
        Row: Record "Test Modal NRL Plain Row";
    begin
        SeedPlain();
        Row.SetRange(Closed, false);
        Page.RunModal(0, Row);
        Assert.AreEqual('[A][C][D][]', Seen,
            'Page.RunModal(0, Rec) on a list with no Editable property: rows walked by the handler');
    end;

    // What TestPage.Editable() answers inside the handler for a page with no Editable property
    // opened in lookup mode.
    [Test]
    [HandlerFunctions('PlainEditableHandler')]
    procedure Plain_LookupModeTrue_EditableAnswer()
    var
        Row: Record "Test Modal NRL Row";
        ListPage: Page "Test Modal NRL Plain";
    begin
        Seed();
        Row.SetRange(Closed, false);
        ListPage.SetTableView(Row);
        ListPage.LookupMode(true);
        ListPage.RunModal();
        Assert.AreEqual(Format(false), Seen,
            'TestPage.Editable() in a handler for a list with no Editable property opened with LookupMode(true)');
    end;

    // ---- Handlers ------------------------------------------------------------------------------

    [ModalPageHandler]
    procedure ReEditableHandler(var TP: TestPage "Test Modal NRL ReEditable")
    begin
        if TP.First() then
            repeat
                Seen += '[' + TP.RowNo.Value() + ']';
            until not TP.Next();
    end;

    [ModalPageHandler]
    procedure ReEditableEditableHandler(var TP: TestPage "Test Modal NRL ReEditable")
    begin
        Seen := Format(TP.Editable());
    end;

    [ModalPageHandler]
    procedure NotEditableHandler(var TP: TestPage "Test Modal NRL NotEditable")
    begin
        if TP.First() then
            repeat
                Seen += '[' + TP.RowNo.Value() + ']';
            until not TP.Next();
    end;

    [ModalPageHandler]
    procedure PlainHandler(var TP: TestPage "Test Modal NRL Plain")
    begin
        if TP.First() then
            repeat
                Seen += '[' + TP.RowNo.Value() + ']';
            until not TP.Next();
    end;

    [ModalPageHandler]
    procedure PlainEditableHandler(var TP: TestPage "Test Modal NRL Plain")
    begin
        Seen := Format(TP.Editable());
    end;

    [ModalPageHandler]
    procedure PlainLookupHandler(var TP: TestPage "Test Modal NRL Plain Lookup")
    begin
        if TP.First() then
            repeat
                Seen += '[' + TP.RowNo.Value() + ']';
            until not TP.Next();
    end;
}
