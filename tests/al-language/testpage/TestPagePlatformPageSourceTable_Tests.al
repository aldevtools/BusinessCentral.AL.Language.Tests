// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-findfirstfield-method
// Scope: in-scope
// Fixtures used: Assert (60021), Base Application page 5 "Currencies" over table 4 Currency
//
// Every other TestPage suite in this corpus drives a page THIS app declares. This one drives
// a page it does not: Base Application page 5 "Currencies", a List over table 4 Currency,
// reached purely through the app.json dependency. Nothing about the claim is special to
// Currency — it is the ordinary FindFirstField contract — but pinning it on a page the test
// app does not itself declare is the point, because that is the only way to state that a
// TestPage resolves its SourceTable from the page's own declaration wherever the page came
// from.
//
// The claim: TestPage.FindFirstField positions the page on the first row whose named control
// carries the given value, and the row it lands on is readable — so the primary key the
// platform used to do the positioning was resolved from page 5's declared SourceTable.
//
// The gating is in the arms. An implementation that positioned on the FIRST row regardless
// fails PositionsOnTheNamedRow (the seeded rows are inserted A-then-B and the arm asks for
// B). One that positioned correctly but read fields off a different row fails
// ReadsTheWholePositionedRow, which checks a second, non-key control on the same row. One
// that answered "found" for anything at all fails MissingValueRaisesRowDoesNotExist, whose
// expected text is BC's own — not a substring, the whole message.

using Microsoft.Finance.Currency;

codeunit 60810 "Test Page Platform Src Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Codes deliberately outside anything a demo company ships, so the suite neither depends
    // on nor disturbs existing Currency rows.
    local procedure Initialize()
    var
        Currency: Record Currency;
    begin
        Currency.SetFilter(Code, 'ZZ*');
        Currency.DeleteAll();
    end;

    local procedure SeedCurrency(NewCode: Code[10]; NewDescription: Text[30])
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.Code := NewCode;
        Currency.Description := NewDescription;
        Currency.Insert();
    end;

    // THE CLAIM. Two rows are seeded A-then-B; the arm asks for the SECOND one, so an
    // implementation that just took the first row on the page cannot pass.
    [Test]
    procedure PositionsOnTheNamedRow()
    var
        CurrenciesPage: TestPage Currencies;
    begin
        Initialize();
        SeedCurrency('ZZA', 'Alpha');
        SeedCurrency('ZZB', 'Beta');

        CurrenciesPage.OpenView();
        CurrenciesPage.FindFirstField(Code, 'ZZB');

        Assert.AreEqual('ZZB', CurrenciesPage.Code.Value(),
            'FindFirstField must position on the row whose Code control carries the value');
        CurrenciesPage.Close();
    end;

    // The positioned row must be readable as a WHOLE row, not just in the control that was
    // searched — a second, non-key control on the same row proves the cursor really moved
    // rather than the searched control alone being answered.
    [Test]
    procedure ReadsTheWholePositionedRow()
    var
        CurrenciesPage: TestPage Currencies;
    begin
        Initialize();
        SeedCurrency('ZZA', 'Alpha');
        SeedCurrency('ZZB', 'Beta');

        CurrenciesPage.OpenView();
        CurrenciesPage.FindFirstField(Code, 'ZZB');

        Assert.AreEqual('Beta', CurrenciesPage.Description.Value(),
            'the non-key control on the positioned row must read that row''s own value');
        CurrenciesPage.Close();
    end;

    // Positioning backwards over the same rowset: asking for the FIRST-inserted row after
    // the page has opened must land on it, so the arm above is not passing by landing on
    // "the last row" either.
    [Test]
    procedure PositionsOnTheEarlierRowToo()
    var
        CurrenciesPage: TestPage Currencies;
    begin
        Initialize();
        SeedCurrency('ZZA', 'Alpha');
        SeedCurrency('ZZB', 'Beta');

        CurrenciesPage.OpenView();
        CurrenciesPage.FindFirstField(Code, 'ZZA');

        Assert.AreEqual('ZZA', CurrenciesPage.Code.Value(),
            'FindFirstField must position on the earlier row when that is the one asked for');
        Assert.AreEqual('Alpha', CurrenciesPage.Description.Value(),
            'the earlier row''s non-key control must read its own value');
        CurrenciesPage.Close();
    end;

    // THE NEGATIVE. A value no row carries raises BC's own row-not-found error. Pinned as the
    // whole message, so an implementation that answered "found" for anything — or raised some
    // other error on the way — cannot pass.
    [Test]
    procedure MissingValueRaisesRowDoesNotExist()
    var
        CurrenciesPage: TestPage Currencies;
    begin
        Initialize();
        SeedCurrency('ZZA', 'Alpha');

        CurrenciesPage.OpenView();
        asserterror CurrenciesPage.FindFirstField(Code, 'ZZQ');

        Assert.ExpectedError('The row does not exist on the TestPage.');
        CurrenciesPage.Close();
    end;
}
