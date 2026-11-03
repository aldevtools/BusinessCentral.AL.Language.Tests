// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: TSPL Header (60320), TSPL Line (60321), TSPL Lines (60322), TSPL Card (60323),
//                TSPL Keyed Line (60325), TSPL Keyed Lines (60326); shared Assert (60021)
//
/// <summary>
/// Pins what a subpage part shows when its SubPageLink uses const(...) or filter(...),
/// alone or next to a field(...) link, and what New() through such a part puts on the row --
/// the FactBox / typed-lines shape (e.g. Base Application's "Approval Comment Sub Form"
/// hosted with "Table ID" = const(Database::...)).
///
/// The claims, each in its own test:
///   - const(option member) pins the part's field to that member.
///   - filter(expression) restricts the part to rows inside the expression.
///   - const(Database::table) pins an Integer field to that table's id.
///   - const('text') pins a Code field to that literal.
///   - a const(...)-only link (no field(...) at all) still filters the part.
///   - New() through a part stamps a link's value onto the new row when, and only when,
///     that field is part of the part table's PRIMARY KEY.
///
/// That last one is the rule BC's own new-record path applies, and the two directions are
/// pinned separately because a runner that stamped nothing, or stamped everything, would
/// satisfy only one of them. RecordImplementation.InitRecordFromFilters copies a filter onto
/// a new record only when the combined filter on that field is a single value AND either the
/// field is part of the primary key, the page sets PopulateAllFields, or the caller names the
/// filter's group -- and NavForm.NewRecord passes no groups. So on "TSPL Line", whose primary
/// key is ("Header No.", "Line No."), the field("No.") half of a link is stamped and the
/// const(...) on Kind is not; on "TSPL Keyed Line", whose primary key contains Kind, the same
/// const(...) is stamped. Those tests read the row New() started rather than saving it,
/// because a row that is outside the part's own filter is exactly what a non-stamped const
/// produces, and saving one makes BC report "The view is filtered, and the entry is outside
/// the filter" instead of letting the test see the row.
///
/// The negatives are in the data: every header carries a row each part must NOT show
/// (wrong Kind, wrong Status, wrong Table ID) and a second header carries a row that would
/// pass the const/filter alone, so a part that applied only the field(...) link, or only
/// the const/filter, or nothing, surfaces a row the assertions reject by name.
/// </summary>
codeunit 60324 "TSPL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure AddLine(HeaderNo: Code[20]; LineNo: Integer; Kind: Option Comment,Attachment; Status: Option "None",Open,Released,Closed; Name: Text[50]; TableId: Integer; Category: Code[10])
    var
        Line: Record "TSPL Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Kind := Kind;
        Line.Status := Status;
        Line.Name := Name;
        Line."Table ID" := TableId;
        Line.Category := Category;
        Line.Insert();
    end;

    local procedure AddKeyedLine(HeaderNo: Code[20]; Kind: Option Comment,Attachment; LineNo: Integer; Name: Text[50])
    var
        KeyedLine: Record "TSPL Keyed Line";
    begin
        KeyedLine.Init();
        KeyedLine."Header No." := HeaderNo;
        KeyedLine.Kind := Kind;
        KeyedLine."Line No." := LineNo;
        KeyedLine.Name := Name;
        KeyedLine.Insert();
    end;

    local procedure Initialize()
    var
        Header: Record "TSPL Header";
        Line: Record "TSPL Line";
        KeyedLine: Record "TSPL Keyed Line";
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

        // H1: one row per combination the parts have to tell apart.
        AddLine('H1', 1, Line.Kind::Comment, Line.Status::Open, 'C-Open', 0, '');
        AddLine('H1', 2, Line.Kind::Attachment, Line.Status::Open, 'A-Open', Database::"TSPL Header", 'SPECIAL');
        AddLine('H1', 3, Line.Kind::Attachment, Line.Status::Closed, 'A-Closed', 0, 'SPECIAL');
        AddLine('H1', 4, Line.Kind::Comment, Line.Status::Released, 'C-Rel', Database::"TSPL Header", '');
        // H2: passes every const/filter on its own, so it only stays hidden if the
        // field("No.") half of the link is applied too.
        AddLine('H2', 1, Line.Kind::Attachment, Line.Status::Open, 'Foreign', Database::"TSPL Header", 'SPECIAL');

        // The keyed variant, same idea: one row the const(Attachment) link must show, one it
        // must not, and one under the other header.
        AddKeyedLine('H1', KeyedLine.Kind::Comment, 1, 'K-Comment');
        AddKeyedLine('H1', KeyedLine.Kind::Attachment, 2, 'K-Attach');
        AddKeyedLine('H2', KeyedLine.Kind::Attachment, 3, 'K-Foreign');
    end;

    local procedure OpenCardOn(HeaderNo: Code[20]; var Card: TestPage "TSPL Card")
    var
        Header: Record "TSPL Header";
    begin
        Header.Get(HeaderNo);
        Card.OpenEdit();
        Card.GoToRecord(Header);
    end;

    // Each helper walks one part of the card and returns the Names it shows, in order, as
    // 'A;B;C;'. One helper per part because a TestPage part cannot be passed as a var
    // TestPage parameter. An insertable part enumerates one extra synthetic row past the
    // real data -- "Line No." 0 with every field blank, the template row New() would fill
    // in -- which is not a persisted line and is not counted.
    local procedure ConstLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstLines.First() then
            exit('');
        repeat
            if Card.ConstLines."Line No.".Value <> '0' then
                Names += Card.ConstLines.Name.Value + ';';
        until not Card.ConstLines.Next();
    end;

    local procedure FilterLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.FilterLines.First() then
            exit('');
        repeat
            if Card.FilterLines."Line No.".Value <> '0' then
                Names += Card.FilterLines.Name.Value + ';';
        until not Card.FilterLines.Next();
    end;

    local procedure ConstTableLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstTableLines.First() then
            exit('');
        repeat
            if Card.ConstTableLines."Line No.".Value <> '0' then
                Names += Card.ConstTableLines.Name.Value + ';';
        until not Card.ConstTableLines.Next();
    end;

    local procedure ConstCodeLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstCodeLines.First() then
            exit('');
        repeat
            if Card.ConstCodeLines."Line No.".Value <> '0' then
                Names += Card.ConstCodeLines.Name.Value + ';';
        until not Card.ConstCodeLines.Next();
    end;

    local procedure ConstOnlyLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstOnlyLines.First() then
            exit('');
        repeat
            if Card.ConstOnlyLines."Line No.".Value <> '0' then
                Names += Card.ConstOnlyLines.Name.Value + ';';
        until not Card.ConstOnlyLines.Next();
    end;

    local procedure ConstKeyLinesNames(var Card: TestPage "TSPL Card") Names: Text
    begin
        if not Card.ConstKeyLines.First() then
            exit('');
        repeat
            if Card.ConstKeyLines."Line No.".Value <> '0' then
                Names += Card.ConstKeyLines.Name.Value + ';';
        until not Card.ConstKeyLines.Next();
    end;

    // CLAIM: Kind = const(Attachment) next to a field(...) link shows exactly the current
    // header's Attachment rows -- not its Comment rows, not another header's Attachment.
    [Test]
    procedure ConstLink_ShowsOnlyTheHeadersRowsMatchingTheConstant()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('A-Open;A-Closed;', ConstLinesNames(Card),
            'a const(Attachment) link must show exactly header H1''s two Attachment rows');
        Card.Close();
    end;

    // CLAIM: Status = filter(Open | Released) next to a field(...) link shows exactly the
    // current header's rows whose Status is inside the expression.
    [Test]
    procedure FilterLink_ShowsOnlyTheHeadersRowsInsideTheExpression()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('C-Open;A-Open;C-Rel;', FilterLinesNames(Card),
            'a filter(Open | Released) link must show exactly header H1''s Open and Released rows');
        Card.Close();
    end;

    // CLAIM: "Table ID" = const(Database::"TSPL Header") pins the Integer field to that
    // table's object id.
    [Test]
    procedure ConstDatabaseLink_PinsTheFieldToTheTableId()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('A-Open;C-Rel;', ConstTableLinesNames(Card),
            'a const(Database::"TSPL Header") link must show exactly header H1''s rows carrying that table id');
        Card.Close();
    end;

    // CLAIM: Category = const('SPECIAL') pins a Code field to the quoted literal.
    [Test]
    procedure ConstTextLink_PinsTheCodeFieldToTheLiteral()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('A-Open;A-Closed;', ConstCodeLinesNames(Card),
            'a const(''SPECIAL'') link must show exactly header H1''s rows whose Category is SPECIAL');
        Card.Close();
    end;

    // CLAIM: a SubPageLink made of a single const(...) entry, with no field(...) at all,
    // still filters the part -- to every header's Comment rows, since nothing ties it to
    // the current header.
    [Test]
    procedure ConstOnlyLink_FiltersWithoutAnyFieldLink()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('C-Open;C-Rel;', ConstOnlyLinesNames(Card),
            'a const(Comment)-only link must show exactly the Comment rows, across headers');
        Card.Close();
    end;

    // CLAIM: a const(...) on a field that is part of the part table's PRIMARY KEY filters
    // the part exactly as it does on a non-key field. Key membership changes what New()
    // stamps, not what the part shows, and the two New() tests below are only meaningful
    // if this holds.
    [Test]
    procedure ConstLink_OnAKeyField_FiltersTheSameWayAsOnANonKeyField()
    var
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Assert.AreEqual('K-Attach;', ConstKeyLinesNames(Card),
            'a const(Attachment) link on a key field must show exactly header H1''s Attachment row');
        Card.Close();
    end;

    // ---------------------------------------------------------------------------------
    // THE RULE THE THREE TESTS BELOW PIN, so nobody has to re-derive it from the failures.
    //
    // BC copies a SubPageLink onto the row New() starts only when the linked field is part
    // of the PART TABLE's PRIMARY KEY. Not "because it is a field(...) link" and not
    // "because the value is a constant" -- BC does not look at the link kind at all.
    //
    // The gate is RecordImplementation.InitRecordFromFilters (Ncl 28.1, decompiled). A
    // page's SubPageLink lands on the part's record as ordinary filters; that method walks
    // them and copies one onto the new record only when the combined filter on the field is
    // FilterExpressionType.Equal -- exactly one value -- AND one of:
    //
    //   * the field is part of the primary key (NCLMetaField.FieldIsPartOfPrimaryKey), or
    //   * the page sets PopulateAllFields, which is the includeNonPrimaryKeyFields argument
    //     NavForm.NewRecordAsync reads from MasterPage.PageProperties.SourceObject, or
    //   * the caller names the field's filter group in
    //     includeNonPrimaryKeyFieldsForFilterGroups.
    //
    // NavForm.NewRecordAsync(bool) and NavForm.NewRecord(bool) both pass
    // Array.Empty<int>() for that last one, and the params int[] overload has no caller
    // inside Ncl, so through a TestPage the third route never opens and it comes down to
    // key membership.
    //
    // The visible consequence, if you meet it before you meet this comment: a New() through
    // a part whose const(...) names a NON-key field produces a row outside that part's own
    // filter, and saving it makes BC report "The view is filtered, and the entry is outside
    // the filter. Some actions may not work." That message is Lang.RowOutsideFilter, raised
    // by NavBindingManager.HandleOutsideOfFilter in Microsoft.Dynamics.Nav.Client.UI.dll on
    // DataAccessOperation.Insert / Modify / Rename only -- OnNewRecord and CloseForm are
    // explicitly excluded -- so seeing it means the row really was inserted and really was
    // outside the filter, not that New() itself was rejected. It is why these three tests
    // read the row where New() left it instead of saving it.
    // ---------------------------------------------------------------------------------

    // CLAIM: New() through a part stamps the field(...) half of the link -- a primary-key
    // field -- onto the new row, and leaves a const(...) on a NON-key field untouched, so
    // Kind stays at its Init() value of Comment rather than the linked Attachment. The row
    // is read where New() left it and never saved: not stamping Kind is exactly what puts
    // the row outside the part's own const(Attachment) filter, and saving it makes BC
    // report that instead of letting the test see the row.
    [Test]
    procedure ConstLink_NewStampsTheFieldLinkButNotANonKeyConstant()
    var
        Line: Record "TSPL Line";
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.ConstLines.New();

        Assert.AreEqual('H1', Card.ConstLines."Header No.".Value,
            'the field("No.") half of the link is a primary-key field, so New() must have stamped it');
        Assert.AreEqual(Format(Line.Kind::Comment), Card.ConstLines.Kind.Value,
            'Kind is not part of "TSPL Line"''s primary key, so the const(Attachment) link must NOT have stamped it');
        Card.Close();
    end;

    // CLAIM: the same const(...) on a field that IS part of the part table's primary key IS
    // stamped by New(). Same link kind, same value, same host row as the test above -- only
    // key membership differs, which is what makes the pair pin the rule rather than one
    // observation of it.
    [Test]
    procedure ConstLink_NewStampsAKeyConstantOntoTheNewRow()
    var
        KeyedLine: Record "TSPL Keyed Line";
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.ConstKeyLines.New();

        Assert.AreEqual('H1', Card.ConstKeyLines."Header No.".Value,
            'the field("No.") half of the link must have stamped the header key');
        Assert.AreEqual(Format(KeyedLine.Kind::Attachment), Card.ConstKeyLines.Kind.Value,
            'Kind IS part of "TSPL Keyed Line"''s primary key, so the const(Attachment) link must have stamped it');
        Card.Close();
    end;

    // CLAIM: New() through a part linked by a multi-value filter(...) stamps nothing into
    // that field -- there is no single value to stamp, whether or not the field is part of
    // the key. Status stays at its Init() value, which the fixture deliberately keeps
    // OUTSIDE the filter (member "None") so an accidental stamp of the first selected
    // member is distinguishable from no stamp at all.
    [Test]
    procedure FilterLink_NewDoesNotStampAMultiValueExpression()
    var
        Line: Record "TSPL Line";
        Card: TestPage "TSPL Card";
    begin
        Initialize();
        OpenCardOn('H1', Card);

        Card.FilterLines.New();

        Assert.AreEqual('H1', Card.FilterLines."Header No.".Value,
            'the field("No.") half of the link must still have stamped the header key');
        Assert.AreEqual(Format(Line.Status::"None"), Card.FilterLines.Status.Value,
            'a filter(Open | Released) link has no single value to stamp, so Status must stay at its Init() value');
        Card.Close();
    end;
}
