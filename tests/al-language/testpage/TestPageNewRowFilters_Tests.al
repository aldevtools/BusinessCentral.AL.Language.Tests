// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-new-method
// Scope: in-scope
// Fixtures used: Test Page New Row Flt Parent (60707), Test Page New Row Flt Child (60708),
//   Test Page New Row Filters List (60709)
//
// A filtered page is showing one parent's rows, so a row created on it belongs to that parent —
// BC fills the linking fields in from the page's filters before the user types anything. Every
// subpage in every application depends on this; it is why Lines.New() on a sales order produces
// a line already attached to that order.
//
// A runner that starts from a bare Init() produces a row with blank keys. The damage shows up
// one step downstream: an OnValidate that looks up its parent silently finds nothing, and the
// test fails naming a derived field instead of the key that was never set.

codeunit 60710 "Test Page New Row Flt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Parent: Record "Test Page New Row Flt Parent";
        Child: Record "Test Page New Row Flt Child";
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
    end;

    local procedure Reset()
    var
        Parent: Record "Test Page New Row Flt Parent";
    begin
        Parent.Init();
        Parent."Code" := 'P1';
        Parent.Label := 'first';
        Parent.Insert();

        Parent.Init();
        Parent."Code" := 'P2';
        Parent.Label := 'second';
        Parent.Insert();
    end;

    [Test]
    procedure New_CarriesASingleValueFilterOntoTheNewRow()
    var
        Lines: TestPage "Test Page New Row Filters List";
    begin
        Initialize();
        Reset();

        Lines.OpenEdit();
        Lines.Filter.SetFilter(ParentCode, 'P2');
        Lines.New();
        Lines.LineNo.SetValue(10000);

        // P2, not P1: the value has to come from the filter, and a runner that defaulted to
        // "the first parent" or to blank both fail here.
        if Lines.ParentCode.Value() <> 'P2' then
            Error('ParentCode on the new row was <%1>, expected <P2>.', Lines.ParentCode.Value());

        Lines.Close();
    end;

    [Test]
    procedure New_LeavesFieldsWithNoFilterAlone()
    var
        Child: Record "Test Page New Row Flt Child";
        Lines: TestPage "Test Page New Row Filters List";
    begin
        Initialize();
        Reset();

        Lines.OpenEdit();
        Lines.Filter.SetFilter(ParentCode, 'P1');
        Lines.New();
        Lines.LineNo.SetValue(10000);
        Lines.Close();

        // The load-bearing negative. Category is filtered by nothing, so it must stay empty —
        // a runner that copied every filter it could find, or smeared one field's filter across
        // the row, passes the test above and fails this one.
        Child.Get('P1', 10000);
        if Child.Category <> '' then
            Error('Category was <%1> on a row whose page filtered nothing onto it.', Child.Category);
    end;

    [Test]
    procedure New_GivesOnInsertAParentItCanActuallyResolve()
    var
        Child: Record "Test Page New Row Flt Child";
        Lines: TestPage "Test Page New Row Filters List";
    begin
        Initialize();
        Reset();

        Lines.OpenEdit();
        Lines.Filter.SetFilter(ParentCode, 'P2');
        Lines.New();
        Lines.LineNo.SetValue(20000);
        Lines.Close();

        // The consequence that matters, and the shape the real failure took: the row's trigger
        // looks its parent up by the key the filter was supposed to supply. With a blank key the
        // lookup just misses, no error is raised, and the derived field is quietly empty.
        Child.Get('P2', 20000);
        if Child.Derived <> 'belongs-to-second' then
            Error('Derived was <%1>, expected <belongs-to-second> — the new row never knew its parent.',
                Child.Derived);
    end;
}
