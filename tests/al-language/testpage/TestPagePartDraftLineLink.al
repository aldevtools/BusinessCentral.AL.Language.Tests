// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: TPDL Header (60996), TPDL Line (60997), TPDL Lines (60997), TPDL Card (60998);
//                shared Assert (60021)
//
/// <summary>
/// Pins what happens when a test types into the implicit DRAFT LINE of a subpage part that
/// carries a SubPageLink -- the blank row an editable, insert-allowed repeater always shows
/// past its data.
///
/// Two suites already surround this and neither answers it. Codeunit 60743 ("Test Page New
/// Row Line Tests") measured the draft line itself: Next() past the last data row lands on
/// it, it reads blank, walking onto it and leaving it alone writes nothing, and typing into
/// an empty editable list with no New() and no First() still inserts a row -- all on a
/// STANDALONE page with no link. Codeunit 60648 ("PKFL Tests") measured what New() stamps
/// through a linked part, and pinned the primary-key gate BC applies there.
///
/// The gap is the intersection: a part that is BOTH linked AND written through its draft
/// line. That is the single commonest shape in Microsoft's own test code --
///
///     SalesQuote.OpenNew();
///     SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
///     SalesQuote.SalesLines.First();                    // no lines yet
///     SalesQuote.SalesLines."No.".SetValue(Item."No."); // types into the draft line
///
/// -- and the line table's first OnValidate immediately reads the document key it was linked
/// on. If the draft line does not carry that key by the time the trigger runs, the write
/// fails on the key rather than on anything the test is about.
///
/// THE CLAIMS
///   * Reading the draft line answers with the SubPageLink's value in the linked column, and
///     blank elsewhere. This is the one claim in the file that a service tier corrected: it was
///     written as "blank in the linked column too" and all 8 BC legs answered 'H1'
///     (run 33995429394). The linked field is the first field of the line table's primary key,
///     which is exactly the set RecordImplementation.InitRecordFromFilters copies a filter
///     onto -- so the client fills the blank line's key from the part's own filter. Codeunit
///     60648 "PKFL Tests" shows the other side: a link on a NON-key field leaves it blank
///     there.
///   * Writing to it does go through that step: the row that appears carries the link's
///     value, and the typed field's OnValidate ALREADY SEES it. "Header Seen By Validate" is
///     what separates those two -- a row whose key were stamped after the validate would
///     still finish with the right "Header No." while that field stayed blank.
///   * The same holds when the draft line was reached by walking off the end of existing
///     data (First() then Next()), not only when the part opened empty, and when nothing
///     positioned the part at all.
///   * The step that creates it is the platform's own new-record step, not a bare insert: the
///     part page's OnNewRecord trigger runs for a row started on the draft line exactly as it
///     does for New(). "Set By OnNewRecord" is the witness -- and it fires as soon as the blank
///     line becomes CURRENT, before anyone types, which is the second thing a service tier
///     corrected here (run 33997895349 answered 'NEWREC' where this file expected blank).
///     "Line No." staying 0 is what keeps that from meaning the row has also been numbered:
///     the client runs NavForm.NewRecord for the draft line and stops short of the save.
///   * A promoted draft line does not collide with the rows already there: AutoSplitKey runs
///     for it, so its "Line No." lands past the last existing line rather than at 0.
///   * Walking onto the draft line of a linked part and leaving it untouched still writes
///     nothing -- the linked case of what codeunit 60743 pins unlinked.
///
/// The negative is in the data: a second header carries its own line, so a part that ignores
/// the link, or writes through the wrong one, shows or touches a row the assertions name.
/// </summary>
codeunit 60996 "TPDL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "TPDL Header";
        Line: Record "TPDL Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();

        AddHeader('H1', 'First');
        AddHeader('H2', 'Second');
    end;

    local procedure AddHeader(No: Code[20]; Descr: Text[50])
    var
        Header: Record "TPDL Header";
    begin
        Header.Init();
        Header."No." := No;
        Header.Descr := Descr;
        Header.Insert();
    end;

    // Assignment, not Validate: a seeded line must NOT run Descr's OnValidate, so
    // "Header Seen By Validate" stays blank on it and only a row written through the page can
    // make that field non-blank.
    local procedure AddLine(HeaderNo: Code[20]; LineNo: Integer; Descr: Text[50])
    var
        Line: Record "TPDL Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure OpenCardOn(HeaderNo: Code[20]; var Card: TestPage "TPDL Card")
    var
        Header: Record "TPDL Header";
    begin
        Header.Get(HeaderNo);
        Card.OpenEdit();
        Card.GoToRecord(Header);
    end;

    local procedure LineCountFor(HeaderNo: Code[20]): Integer
    var
        Line: Record "TPDL Line";
    begin
        Line.SetRange("Header No.", HeaderNo);
        exit(Line.Count());
    end;

    // Positions a card on H1 and walks its part onto the draft line, so the four read tests
    // below differ only in the column they then read. Each is its own [Test] on purpose: a
    // single procedure stops at its first failing assertion, so one wrong expectation hides
    // whatever the remaining columns would have said. That cost a whole CI cycle the first
    // time this file ran (all 8 legs reported only the linked column and nothing else).
    local procedure OpenH1AndStandOnTheDraftLine(var Card: TestPage "TPDL Card")
    begin
        OpenCardOn('H1', Card);
        Assert.IsTrue(Card.Lines.First(), 'the part must land on H1''s seeded line');
        Assert.AreEqual('H1', Card.Lines.HeaderNo.Value(),
            'the seeded data row must read the header it belongs to');
        Assert.AreEqual('seeded', Card.Lines.Descr.Value(),
            'the seeded data row must read its own description');
        Assert.IsTrue(Card.Lines.Next(),
            'Next() past the part''s last data row must land on the part''s draft line');
    end;

    // MEASURED, and it corrected this file's first expectation. The draft line does NOT read
    // blank in the linked column: it reads the SubPageLink's value. Measured on all 8 BC legs
    // (run 33995429394 reported Expected:<> Actual:<H1> against the original "must read blank"
    // wording), so the client fills the blank line's key from the part's own filter before
    // anyone types into it.
    //
    // That matches the rule BC applies to a row New() starts --
    // RecordImplementation.InitRecordFromFilters copies a single-valued filter onto a field
    // only when the field is part of the primary key -- and "Header No." is the first field of
    // "TPDL Line"'s key. Codeunit 60648 "PKFL Tests" is the other side of it: there the linked
    // field is NOT in the key, and the part's draft row shows it blank.
    [Test]
    procedure LinkedPart_DraftLine_ReadsTheLinkValueInTheLinkedKeyColumn()
    var
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenH1AndStandOnTheDraftLine(Card);

        Assert.AreEqual('H1', Card.Lines.HeaderNo.Value(),
            'the draft line must read the SubPageLink''s value in the linked primary-key column');

        Assert.IsFalse(Card.Lines.Next(), 'Next() from the draft line must end the part''s rowset');
        Card.Close();
    end;

    // The other half of the same claim, and what stops the one above from being read as "the
    // draft line shows the row you would get". A column the link does not constrain is blank.
    [Test]
    procedure LinkedPart_DraftLine_ReadsBlankInAnUnlinkedColumn()
    var
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenH1AndStandOnTheDraftLine(Card);

        Assert.AreEqual('', Card.Lines.Descr.Value(),
            'the draft line must read blank in a column the SubPageLink does not constrain');

        Assert.IsFalse(Card.Lines.Next(), 'Next() from the draft line must end the part''s rowset');
        Card.Close();
    end;

    // MEASURED, and it corrected this file's second expectation. Standing on the draft line
    // DOES run the page's OnNewRecord: this arm was written as "must not run" and all 8 BC legs
    // answered 'NEWREC' (run 33997895349).
    //
    // Together with the arm below -- "Line No." still 0 -- that says the client runs
    // NavForm.NewRecord when the blank line becomes current, and stops there. NewRecord is
    // ALInit, copy the single-valued filters onto the primary key, raise OnNewRecord. What it
    // is NOT is a save: AutoSplitKey numbers the row in NavForm.SaveRecord, and nothing is
    // written until someone types (LinkedPart_DraftLineLeftUntouched_InsertsNothing).
    [Test]
    procedure LinkedPart_DraftLine_HasRunTheOnNewRecordTrigger()
    var
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenH1AndStandOnTheDraftLine(Card);

        Assert.AreEqual('NEWREC', Card.Lines.SetByOnNewRecord.Value(),
            'standing on the draft line must run the page''s OnNewRecord trigger -- the client starts the record when the blank line becomes current, it just does not save it');

        Assert.IsFalse(Card.Lines.Next(), 'Next() from the draft line must end the part''s rowset');
        Card.Close();
    end;

    // MEASURED, and the companion to the one above -- it is what stops "OnNewRecord has run"
    // from being read as "the row has been started and numbered". AutoSplitKey belongs to
    // saving the row, so the draft line still shows 0. Codeunit 60648's part walk reads
    // "Line No." 0 on its own draft row too, but that part does not set AutoSplitKey, so it
    // could not answer this on its own. "TPDL Lines" does.
    [Test]
    procedure LinkedPart_DraftLine_ReadsZeroInTheAutoSplitKeyColumn()
    var
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenH1AndStandOnTheDraftLine(Card);

        Assert.AreEqual('0', Card.Lines.LineNo.Value(),
            'the draft line must show 0 in the AutoSplitKey column -- the number is assigned when the row is saved, not when the blank line is shown');

        Assert.IsFalse(Card.Lines.Next(), 'Next() from the draft line must end the part''s rowset');
        Card.Close();
    end;

    // THE CLAIM THIS FILE EXISTS FOR: typing into the draft line of an EMPTY linked part
    // creates a row that already carries the link's value -- and carries it early enough that
    // the typed field's own OnValidate sees it.
    [Test]
    procedure EmptyLinkedPart_FirstThenWrite_ValidateSeesTheLinkedKey()
    var
        Line: Record "TPDL Line";
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);

        Assert.IsFalse(Card.Lines.First(),
            'H1 has no lines, so First() on the part must return false');

        Card.Lines.Descr.SetValue('typed into the draft line');
        Card.Close();

        Assert.AreEqual(1, LineCountFor('H1'),
            'typing into the draft line of an empty linked part must insert exactly one line for H1');
        Assert.AreEqual(1, LineCountFor('H2'),
            'H2''s own line must be untouched -- the write must go through H1''s link, not past it');

        Line.SetRange("Header No.", 'H1');
        Line.FindFirst();
        Assert.AreEqual('typed into the draft line', Line.Descr,
            'the typed value must reach the backing table');
        Assert.AreEqual('H1', Line."Header No.",
            'the row started on the draft line must carry the SubPageLink''s value');
        Assert.AreEqual('H1', Line."Header Seen By Validate",
            'the link''s value must already be on the row when the typed field''s OnValidate runs, not stamped afterwards');
        Assert.AreEqual('NEWREC', Line."Set By OnNewRecord",
            'a row started by typing into the draft line must go through the page''s OnNewRecord, the same step New() runs');
    end;

    // The same claim with NOTHING positioning the part first -- no New(), no First(). This is
    // how a lot of Microsoft AL writes a fresh document line, and it is the linked twin of
    // codeunit 60743's EmptyEditableList_SetValueWithoutNewOrFirst_InsertsARow.
    [Test]
    procedure EmptyLinkedPart_WriteWithoutFirst_ValidateSeesTheLinkedKey()
    var
        Line: Record "TPDL Line";
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);

        Card.Lines.Descr.SetValue('typed with no First');
        Card.Close();

        Assert.AreEqual(1, LineCountFor('H1'),
            'typing into an empty linked part without First() must still insert one line for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');

        Line.SetRange("Header No.", 'H1');
        Line.FindFirst();
        Assert.AreEqual('typed with no First', Line.Descr, 'the typed value must reach the backing table');
        Assert.AreEqual('H1', Line."Header No.",
            'the row started on the draft line must carry the SubPageLink''s value');
        Assert.AreEqual('H1', Line."Header Seen By Validate",
            'the link''s value must already be on the row when the typed field''s OnValidate runs');
        Assert.AreEqual('NEWREC', Line."Set By OnNewRecord",
            'a row started by typing into the draft line must go through the page''s OnNewRecord');
    end;

    // The draft line reached by WALKING off the end of existing data, not by opening empty.
    // The promoted row must not collide with the line already there: AutoSplitKey runs for it,
    // so its "Line No." lands past the seeded one rather than at 0.
    [Test]
    procedure LinkedPart_NextPastLastLineThenWrite_ValidateSeesTheLinkedKey()
    var
        Line: Record "TPDL Line";
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);

        Assert.IsTrue(Card.Lines.First(), 'the part must land on H1''s seeded line');
        Assert.IsTrue(Card.Lines.Next(), 'Next() must land on the part''s draft line');

        Card.Lines.Descr.SetValue('typed after walking to the end');
        Card.Close();

        Assert.AreEqual(2, LineCountFor('H1'),
            'typing into the draft line reached by Next() must add a second line for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');

        Line.SetRange("Header No.", 'H1');
        Line.SetRange(Descr, 'typed after walking to the end');
        Assert.AreEqual(1, Line.Count(), 'exactly one line must carry the typed description');
        Line.FindFirst();
        Assert.AreEqual('H1', Line."Header No.",
            'the row started on the draft line must carry the SubPageLink''s value');
        Assert.AreEqual('H1', Line."Header Seen By Validate",
            'the link''s value must already be on the row when the typed field''s OnValidate runs');
        Assert.AreEqual('NEWREC', Line."Set By OnNewRecord",
            'a row started by typing into the draft line must go through the page''s OnNewRecord');
        Assert.IsTrue(Line."Line No." > 10000,
            'AutoSplitKey must number the promoted draft line past the line already there, not at 0');

        // The seeded line is untouched, and still shows that only a page write fills in
        // "Header Seen By Validate".
        Line.Reset();
        Line.Get('H1', 10000);
        Assert.AreEqual('seeded', Line.Descr, 'the seeded line must keep its own description');
        Assert.AreEqual('', Line."Header Seen By Validate",
            'the seeded line was never written through the page, so its witness field must stay blank');
        Assert.AreEqual('', Line."Set By OnNewRecord",
            'the seeded line was never started through the page, so OnNewRecord must not have touched it');
    end;

    // The linked case of codeunit 60743's NewRowLine_LeftUntouched_InsertsNothing: walking
    // onto a linked part's draft line and typing nothing must write nothing.
    [Test]
    procedure LinkedPart_DraftLineLeftUntouched_InsertsNothing()
    var
        Line: Record "TPDL Line";
        Card: TestPage "TPDL Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);

        Assert.IsTrue(Card.Lines.First(), 'the part must land on H1''s seeded line');
        Assert.IsTrue(Card.Lines.Next(), 'Next() must land on the part''s draft line');
        Assert.IsFalse(Card.Lines.Next(), 'Next() from the draft line must end the part''s rowset');
        Card.Close();

        Assert.AreEqual(1, LineCountFor('H1'),
            'walking onto a linked part''s draft line without typing must not insert a line');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
        Line.Get('H1', 10000);
        Assert.AreEqual('seeded', Line.Descr, 'the seeded line must be unchanged');
    end;
}
