// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: PKFL Header (60641), PKFL Line (60642), PKFL Keyed Line (60643),
//                PKFL Lines (60644), PKFL Populate Lines (60645), PKFL Keyed Lines (60646),
//                PKFL Card (60647); shared Assert (60021)
//
/// <summary>
/// Pins what New() through a subpage part puts on the new row when the part is linked by
/// field(...) -- specifically when the linked field on the part's table is NOT part of that
/// table's primary key, which nothing measured before.
///
/// The rule BC applies lives in RecordImplementation.InitRecordFromFilters: it copies a
/// field's filter onto the new record only when the combined filter on that field is a single
/// value AND one of three things holds -- the field is part of the primary key, the page sets
/// PopulateAllFields, or the caller names the filter's group. NavForm.NewRecordAsync(bool)
/// passes Array.Empty&lt;int&gt;() for the groups, so on an ordinary page it comes down to key
/// membership or PopulateAllFields. Nothing in that method looks at the SubPageLink's KIND,
/// which is why the same gate is expected to apply to field(...) exactly as it does to
/// const(...) and filter(...).
///
/// "Expected" is the reason this file exists. The const(...) and filter(...) halves are
/// measured (TestPageSubpagePartConstFilter.al), and so is field(...) onto a field that IS in
/// the key -- but field(...) onto a NON-key field is not, and a field(...) SubPageLink on a
/// non-key field is a common Base Application shape. If it turns out BC stamps it, the rule is
/// not kind-neutral after all.
///
/// The claims, each in its own test:
///   - a field(...) link on a non-key field still FILTERS the part (the gate is about what
///     New() stamps, never about what the part shows);
///   - New() through that part does not stamp the linked value;
///   - a const(...) link on the SAME non-key field of the SAME table is not stamped either,
///     so link kind is not what decides it;
///   - New() through a part whose linked field IS in the key does stamp it;
///   - PopulateAllFields = true on the part page stamps it even though the field is not in
///     the key -- the second escape the rule names, and the test that makes the "not stamped"
///     assertion above mean something, since it shows the value is stampable on that very
///     table through that very link;
///   - a row New() started and nothing touched is discarded when the card closes.
///
/// The three parts of "PKFL Card" carry the SAME link, so key membership and PopulateAllFields
/// are the only variables. The tests read the row where New() left it rather than saving it:
/// a row whose link value was not stamped is outside the part's own filter, and saving one
/// makes BC report "The view is filtered, and the entry is outside the filter" instead of
/// letting the test see the row.
///
/// The negatives are in the data: a second header carries a line that every part must NOT
/// show, so a part that ignored the link, or applied it to the wrong side, surfaces a row the
/// assertions reject by name.
/// </summary>
codeunit 60648 "PKFL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure AddLine(LineNo: Integer; HeaderNo: Code[20]; Name: Text[50])
    var
        Line: Record "PKFL Line";
    begin
        Line.Init();
        Line."Line No." := LineNo;
        Line."Header No." := HeaderNo;
        Line.Name := Name;
        Line.Insert();
    end;

    local procedure AddKeyedLine(HeaderNo: Code[20]; LineNo: Integer; Name: Text[50])
    var
        KeyedLine: Record "PKFL Keyed Line";
    begin
        KeyedLine.Init();
        KeyedLine."Header No." := HeaderNo;
        KeyedLine."Line No." := LineNo;
        KeyedLine.Name := Name;
        KeyedLine.Insert();
    end;

    local procedure Initialize()
    var
        Header: Record "PKFL Header";
        Line: Record "PKFL Line";
        KeyedLine: Record "PKFL Keyed Line";
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        KeyedLine.DeleteAll();

        Header.Init();
        Header."No." := 'H1';
        Header.Descr := 'First';
        Header.Insert();

        Header.Init();
        Header."No." := 'H2';
        Header.Descr := 'Second';
        Header.Insert();

        // Two rows under H1 and one under H2. The H2 row is the negative: it is only hidden
        // if the link is actually applied to the part.
        AddLine(1, 'H1', 'L-One');
        AddLine(2, 'H1', 'L-Two');
        AddLine(3, 'H2', 'L-Foreign');

        AddKeyedLine('H1', 1, 'K-One');
        AddKeyedLine('H2', 2, 'K-Foreign');
    end;

    local procedure OpenCardOn(HeaderNo: Code[20]; var Card: TestPage "PKFL Card")
    var
        Header: Record "PKFL Header";
    begin
        Header.Get(HeaderNo);
        Card.OpenEdit();
        Card.GoToRecord(Header);
    end;

    // Walks the part and returns the Names it shows, in order, as 'A;B;'. A TestPage part
    // cannot be passed as a var parameter, so this is one helper per part rather than one
    // shared helper.
    local procedure LinesNames(var Card: TestPage "PKFL Card") Names: Text
    begin
        if not Card.Lines.First() then
            exit('');
        repeat
            // An insertable part enumerates one extra synthetic row past the real data --
            // "Line No." 0 with every field blank, the template row New() would fill in --
            // which is not a persisted line and is not counted.
            if Card.Lines."Line No.".Value <> '0' then
                Names += Card.Lines.Name.Value + ';';
        until not Card.Lines.Next();
    end;

    [Test]
    procedure FieldLink_OnANonKeyField_FiltersThePart()
    // CLAIM: a field(...) SubPageLink filters the part exactly the same way when the linked
    // field is not part of the part table's primary key. Key membership governs what New()
    // stamps, never what the part shows -- and the two New() tests below are only meaningful
    // if the link reaches the part at all, which is what this establishes.
    var
        Card: TestPage "PKFL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('L-One;L-Two;', LinesNames(Card),
            'a field(...) link on a non-key field must still filter the part to the host row''s lines, and must not show H2''s line');
        Card.Close();
    end;

    [Test]
    procedure FieldLink_OnANonKeyField_NewDoesNotStampTheLinkedValue()
    // CLAIM: New() through a part linked by field(...) onto a field that is NOT part of the
    // part table's primary key leaves that field at its Init() value. This is the assertion
    // this whole file exists to settle; PopulateAllFields_NewStampsANonKeyFieldLink below
    // stamps 'H1' onto the same field of the same table through the same link, so a blank
    // here is a decision by the platform rather than a value that could never arrive.
    var
        Card: TestPage "PKFL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.Lines.New();

        Assert.AreEqual('', Card.Lines."Header No.".Value,
            '"Header No." is not part of "PKFL Line"''s primary key, so New() must leave it blank rather than stamping the link''s value');
        Card.Close();
    end;

    [Test]
    procedure ConstLink_OnTheSameNonKeyField_NewDoesNotStampTheLinkedValue()
    // CLAIM: the gate does not depend on the SubPageLink's KIND. This is the same table, the
    // same non-key field and the same value as
    // FieldLink_OnANonKeyField_NewDoesNotStampTheLinkedValue -- written const('H1') instead of
    // field("No."). Link kind is the only variable between the two, so if they disagree, the
    // rule is kind-dependent and InitRecordFromFilters is not the whole story.
    var
        Card: TestPage "PKFL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.ConstLines.New();

        Assert.AreEqual('', Card.ConstLines."Header No.".Value,
            'a const(...) link on a non-key field must not be stamped by New() either -- the gate is about key membership, not about the link kind');
        Card.Close();
    end;

    [Test]
    procedure FieldLink_OnAKeyField_NewStampsTheLinkedValue()
    // CLAIM: the same link, the same host row, the same link kind -- and the linked field IS
    // part of the primary key this time, so New() stamps it. Asserts the concrete 'H1', so an
    // implementation that stamped nothing at all fails here.
    var
        Card: TestPage "PKFL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.KeyedLines.New();

        Assert.AreEqual('H1', Card.KeyedLines."Header No.".Value,
            '"Header No." is part of "PKFL Keyed Line"''s primary key, so New() must stamp the link''s value onto the new row');
        Card.Close();
    end;

    [Test]
    procedure PopulateAllFields_NewStampsANonKeyFieldLink()
    // CLAIM: PopulateAllFields = true on the part page lifts the primary-key gate, so New()
    // stamps the link's value onto a field that is not part of the key. Same table and same
    // link as FieldLink_OnANonKeyField_NewDoesNotStampTheLinkedValue -- only the page property
    // differs -- so the pair isolates the property's effect from every other variable.
    var
        Card: TestPage "PKFL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.PopLines.New();

        Assert.AreEqual('H1', Card.PopLines."Header No.".Value,
            'PopulateAllFields = true must stamp the link''s value even though "Header No." is not part of the primary key');
        Card.Close();
    end;

    [Test]
    procedure New_NothingTouched_IsDiscardedWhenTheCardCloses()
    // CLAIM: a row New() started and nothing wrote to is not persisted when the card closes.
    // Counts the rows rather than looking for a specific one, so a draft saved under ANY key
    // fails the assertion.
    var
        KeyedLine: Record "PKFL Keyed Line";
        Card: TestPage "PKFL Card";
        Before: Integer;
    begin
        Initialize();
        Before := KeyedLine.Count();
        OpenCardOn('H1', Card);

        Card.KeyedLines.New();
        Card.Close();

        Assert.AreEqual(Before, KeyedLine.Count(),
            'a row New() started and never wrote to must not survive the card closing');
    end;
}
