// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: ONPL Header (60868), ONPL Card (60868), ONPL Lines (60869), TPDL Line (60997);
//                shared Assert (60021)
//
/// <summary>
/// Pins that a linked lines part follows a header opened with OpenNew() once that header has
/// been inserted -- the shape of Microsoft's document tests:
///
///     PurchaseInvoice.OpenNew();
///     PurchaseInvoice."Buy-from Vendor Name".SetValue(...);   // inserts the header, No. assigned
///     PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(...);
///
/// When the page opens, the new header has no row and no number, so the part's
/// SubPageLink has nothing to link to. A line typed into the part after the header's first
/// field write must carry the number the header got at insert, and the line's own OnValidate
/// must already see it ("Header Seen By Validate" is the witness; codeunit 60996 "TPDL Tests"
/// pins the same claims for a header opened with OpenEdit()).
///
/// The negative is in the data: a second, pre-existing header carries its own line, and the
/// part must neither show it nor write through it.
/// </summary>
codeunit 60868 "ONPL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "ONPL Header";
        Line: Record "TPDL Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();

        Header.Init();
        Header."No." := 'OTHER';
        Header.Insert();

        Line.Init();
        Line."Header No." := 'OTHER';
        Line."Line No." := 10000;
        Line.Descr := 'foreign';
        Line.Insert();
    end;

    local procedure LineCountFor(HeaderNo: Code[20]): Integer
    var
        Line: Record "TPDL Line";
    begin
        Line.SetRange("Header No.", HeaderNo);
        exit(Line.Count());
    end;

    local procedure AssertOneLineWrittenFor(HeaderNo: Code[20]; Typed: Text[50])
    var
        Line: Record "TPDL Line";
    begin
        Assert.AreEqual(1, LineCountFor(HeaderNo),
            'the line typed into the part must be inserted for the header opened with OpenNew');
        Assert.AreEqual(1, LineCountFor('OTHER'), 'the other header''s line must be untouched');
        Assert.AreEqual(0, LineCountFor(''), 'no line may be inserted without a header number');

        Line.SetRange("Header No.", HeaderNo);
        Line.FindFirst();
        Assert.AreEqual(Typed, Line.Descr, 'the typed value must reach the backing table');
        Assert.AreEqual(HeaderNo, Line."Header Seen By Validate",
            'the header number must already be on the line when the typed field''s OnValidate runs');
        Assert.AreEqual('NEWREC', Line."Set By OnNewRecord",
            'the line must be started through the part page''s OnNewRecord');
    end;

    // The Purchase Invoice shape: the header's number comes from its own OnInsert, triggered by
    // the first field the test writes on the new card.
    [Test]
    procedure OpenNew_NumberAssignedOnInsert_PartWriteCarriesTheNumber()
    var
        Header: Record "ONPL Header";
        Card: TestPage "ONPL Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Descr.SetValue('typed header');
        Assert.AreEqual('AUTO1', Card."No.".Value(),
            'writing the first field of the new card must insert the header and run its OnInsert');

        Card.Lines.Descr.SetValue('typed line');
        Card.Close();

        Assert.IsTrue(Header.Get('AUTO1'), 'the header must exist under the number OnInsert assigned');
        AssertOneLineWrittenFor('AUTO1', 'typed line');
    end;

    // The same claim when the test types the number itself.
    [Test]
    procedure OpenNew_NumberTyped_PartWriteCarriesTheNumber()
    var
        Card: TestPage "ONPL Card";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('TYPED');
        Card.Lines.Descr.SetValue('typed line');
        Card.Close();

        AssertOneLineWrittenFor('TYPED', 'typed line');
    end;

    // With the part positioned by First() before the write: the new header has no lines, so
    // First() finds nothing, and the write lands on the draft line.
    [Test]
    procedure OpenNew_NumberAssignedOnInsert_FirstThenWriteCarriesTheNumber()
    var
        Card: TestPage "ONPL Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Descr.SetValue('typed header');
        Assert.IsFalse(Card.Lines.First(), 'the new header has no lines, so First() must return false');
        Card.Lines.Descr.SetValue('typed line');
        Card.Close();

        AssertOneLineWrittenFor('AUTO1', 'typed line');
    end;

    // Explicit navigation positions the part for good: once the header is inserted and has
    // lines, Last() puts the part on the last line, and a write that follows lands there rather
    // than on the first line or on a new one.
    [Test]
    procedure OpenNew_LinesInsertedInCode_LastThenWriteLandsOnTheLastLine()
    var
        Line: Record "TPDL Line";
        Card: TestPage "ONPL Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Descr.SetValue('typed header');
        Assert.AreEqual('AUTO1', Card."No.".Value(), 'writing the first field must insert the header');

        Line.Init();
        Line."Header No." := 'AUTO1';
        Line."Line No." := 10000;
        Line.Descr := 'first';
        Line.Insert();
        Line.Init();
        Line."Header No." := 'AUTO1';
        Line."Line No." := 20000;
        Line.Descr := 'second';
        Line.Insert();

        Assert.IsTrue(Card.Lines.Last(), 'the header has two lines, so Last() must return true');
        Card.Lines.Descr.SetValue('typed on last');
        Card.Close();

        Assert.AreEqual(2, LineCountFor('AUTO1'), 'the write must modify a line, not insert one');
        Line.Get('AUTO1', 20000);
        Assert.AreEqual('typed on last', Line.Descr, 'the write after Last() must land on the last line');
        Line.Get('AUTO1', 10000);
        Assert.AreEqual('first', Line.Descr, 'the first line must be untouched');
        Assert.AreEqual(1, LineCountFor('OTHER'), 'the other header''s line must be untouched');
    end;

    // The Purchase Invoice subform's first control is bound to a page variable whose OnValidate
    // writes Rec. That write must also see the header number: the line's own Descr OnValidate
    // tests "Header No." and copies it into "Header Seen By Validate", read back through the part.
    [Test]
    procedure OpenNew_NumberAssignedOnInsert_PageVariableWriteSeesTheNumber()
    var
        Card: TestPage "ONPL Card";
    begin
        Initialize();

        Card.OpenNew();
        Card.Descr.SetValue('typed header');
        Card.Lines.ViaGlobal.SetValue('via global');

        Assert.AreEqual('AUTO1', Card.Lines.HeaderSeen.Value(),
            'the page-variable control''s OnValidate must write a line that already carries the header number');
        Assert.AreEqual('AUTO1', Card.Lines.HeaderNo.Value(),
            'the line the page-variable control wrote must be linked to the new header');
        Assert.AreEqual('via global', Card.Lines.Descr.Value(),
            'the page-variable control''s OnValidate must have written the line');
        Card.Close();
    end;

    // The part must not show the other header's line while the new header has no row.
    [Test]
    procedure OpenNew_BeforeAnyWrite_PartShowsNoForeignLine()
    var
        Card: TestPage "ONPL Card";
    begin
        Initialize();

        Card.OpenNew();
        Assert.AreNotEqual('foreign', Card.Lines.Descr.Value(),
            'the part of a header with no row must not show another header''s line');
        Card.Close();

        Assert.AreEqual(1, LineCountFor('OTHER'), 'the other header''s line must be untouched');
        Assert.AreEqual(0, LineCountFor(''), 'reading the part must not insert a line');
    end;
}
