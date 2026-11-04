// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page Enum Field Grade (60688), Test Page Enum Field Row (60689), LT BO Sparse Enum/Row/Card (82350-82352), Probe Observer (69160),
//   Test Page Enum Field Card (60690)
//
// A TestPage drives an option-typed field by its member NAME — Field.SetValue('High'),
// Field.Value() returning 'High'. That works for both AL spellings of an option: Option with
// OptionMembers on the field, and Enum, whose members live on a separate object the field only
// references by id.
//
// Only the second spelling can go wrong on its own, so every Enum test here is paired with the
// Option test that would still pass — the pairing is what turns "SetValue is broken" into
// "enum member metadata never reaches the field".

codeunit 60691 "Test Page Enum Field Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "Test Page Enum Field Row";
    begin
        Row.DeleteAll();
    end;

    local procedure Seed(No: Code[20]) Row: Record "Test Page Enum Field Row"
    begin
        Row.Init();
        Row."No." := No;
        Row.Insert();
    end;

    [Test]
    procedure SetValue_OnAPlainTextFieldPersistsToTheRow()
    var
        Row: Record "Test Page Enum Field Row";
        Card: TestPage "Test Page Enum Field Card";
    begin
        Initialize();
        Seed('T-1');

        Card.OpenEdit();
        Card.First();
        Card.Note.SetValue('edited');
        Card.Close();

        // The outermost control in the suite: no option is involved, so if this fails the defect
        // is that edits to an existing row never reach the table, and every option assertion here
        // is failing for a reason that has nothing to do with option members.
        Row.Get('T-1');
        if Row.Note <> 'edited' then
            Error('Note was <%1>, expected <edited> — the edit never reached the row.', Row.Note);
    end;

    [Test]
    procedure SetValue_ResolvesAnEnumMemberByName()
    var
        Row: Record "Test Page Enum Field Row";
        Card: TestPage "Test Page Enum Field Card";
    begin
        Initialize();
        Seed('E-1');

        Card.OpenEdit();
        // OpenEdit does not position the page; the suite is about option values, not about
        // where a freshly opened card lands.
        Card.First();
        Card.Grade.SetValue('High');
        Card.Close();

        Row.Get('E-1');
        // High is 2, so neither the field default nor a failed evaluate landing on 0 can produce
        // this. That is the point of never targeting the first member.
        if Row.Grade <> Row.Grade::High then
            Error('Grade was %1, expected High.', Format(Row.Grade));
    end;

    [Test]
    procedure SetValue_ResolvesAnOptionMemberByName()
    var
        Row: Record "Test Page Enum Field Row";
        Card: TestPage "Test Page Enum Field Card";
    begin
        Initialize();
        Seed('O-1');

        Card.OpenEdit();
        // OpenEdit does not position the page; the suite is about option values, not about
        // where a freshly opened card lands.
        Card.First();
        Card.Kind.SetValue('Gamma');
        Card.Close();

        // The control for the test above. If this fails too, the defect is in SetValue itself and
        // has nothing to do with where an option keeps its members.
        Row.Get('O-1');
        if Row.Kind <> Row.Kind::Gamma then
            Error('Kind was %1, expected Gamma.', Format(Row.Kind));
    end;

    [Test]
    procedure Value_ReadsBackAnEnumMemberByName()
    var
        Row: Record "Test Page Enum Field Row";
        Card: TestPage "Test Page Enum Field Card";
    begin
        Initialize();
        Row := Seed('E-2');
        Row.Grade := Row.Grade::Mid;
        Row.Modify();

        Card.OpenEdit();
        Card.First();
        // The read direction needs the same member table as the write direction, and a runner can
        // get one working while the other still answers with the ordinal.
        if Card.Grade.Value() <> 'Mid' then
            Error('Grade read back as <%1>, expected <Mid>.', Card.Grade.Value());
        Card.Close();
    end;

    [Test]
    procedure SetValue_RejectsAStringThatIsNotAnEnumMember()
    var
        Row: Record "Test Page Enum Field Row";
        Card: TestPage "Test Page Enum Field Card";
    begin
        Initialize();
        Seed('E-3');
        // asserterror suppresses test failure but NOT the database rollback the error still
        // triggers — without this Commit, the Seed insert above rolls back along with the
        // rejected SetValue, and the Get below fails with "row does not exist".
        Commit();

        Card.OpenEdit();
        Card.First();
        asserterror Card.Grade.SetValue('Enormous');

        // The load-bearing negative: a runner that "fixes" the evaluate by falling back to 0 for
        // anything it cannot resolve passes all three tests above and fails here. The error must
        // still name the value that could not be resolved.
        if StrPos(GetLastErrorText(), 'Enormous') = 0 then
            Error('Expected the error to name the unresolvable value, but got: %1', GetLastErrorText());

        Row.Get('E-3');
        if Row.Grade <> Row.Grade::Low then
            Error('A rejected SetValue still changed the field to %1.', Format(Row.Grade));
    end;

    [Test]
    procedure SetValue_AcceptsTheOrdinalOfAnEnumMember()
    var
        Row: Record "Test Page Enum Field Row";
        Card: TestPage "Test Page Enum Field Card";
    begin
        Initialize();
        Seed('E-4');

        Card.OpenEdit();
        Card.First();
        // AL code in the wild sets option fields both ways; the ordinal path does not need the
        // member table at all, so it should already work and must keep working after the fix.
        Card.Grade.SetValue(2);
        Card.Close();

        Row.Get('E-4');
        if Row.Grade <> Row.Grade::High then
            Error('Grade was %1, expected High.', Format(Row.Grade));
    end;

    // Corpus issue #664 item 77: a page field on an enum with sparse ordinals (0, 1, 4, 5) sets OptionCaption = ' ,c1,,,c4,c5'
    // (AL0600 is a warning, so it compiles). Which caption does the TestPage field show, and which text does SetValue accept?
    // Fixtures: misc/lt-bo2-odd-leads/BoSparseEnumFixtures.al (enum 82350 captions cap1/cap4/cap5, table 82351, page 82352).
    [Test]
    procedure Enum_SparseOrdinals_PageOptionCaption()
    var
        Row: Record "LT BO Sparse Row";
        Card: TestPage "LT BO Sparse Card";
        Observer: Codeunit "Probe Observer";
        Ordinal: Integer;
    begin
        SeedSparse();

        foreach Ordinal in Row.E.Ordinals() do begin
            Row.Get(OrdinalRowId(Ordinal));
            Observer.Observe('format ' + Format(Ordinal), Format(Row.E));
        end;

        Card.OpenEdit();
        foreach Ordinal in Row.E.Ordinals() do begin
            Row.Get(OrdinalRowId(Ordinal));
            Card.GoToRecord(Row);
            Observer.Observe('page value ' + Format(Ordinal), Card.E.Value());
        end;

        Card.Close();
        // The page shows the OptionCaption entry only for ordinals 0 and 1; ordinals 4 and 5 show as their number, not as c4/c5.
        Observer.Expect('format 0', ' ');
        Observer.Expect('format 1', 'cap1');
        Observer.Expect('format 4', 'cap4');
        Observer.Expect('format 5', 'cap5');
        Observer.Expect('page value 0', ' ');
        Observer.Expect('page value 1', 'c1');
        Observer.Expect('page value 4', '4');
        Observer.Expect('page value 5', '5');
        Observer.Verify();
    end;

    // Item 77, second half: SetValue on that field, each attempt on a freshly opened page; the row starts at value5 (ordinal 5).
    [Test]
    procedure Enum_SparseOrdinals_PageOptionCaption_SetValue()
    var
        Row: Record "LT BO Sparse Row";
        Card: TestPage "LT BO Sparse Card";
        Observer: Codeunit "Probe Observer";
        Attempt: Text;
    begin
        SeedSparse();
        foreach Attempt in 'c1|cap1|value1|c4|cap4|value4|4|c5| '.Split('|') do begin
            Row.Get(1);
            Row.E := Row.E::value5;
            Row.Modify();
            Card.OpenEdit();
            Card.GoToRecord(Row);
            if TrySetSparse(Card, Attempt) then begin
                Observer.Observe('[' + Attempt + '] page', Card.E.Value());
                Card.Close();
                Row.Get(1);
                Observer.Observe('[' + Attempt + '] stored', Format(Row.E.AsInteger()));
            end else begin
                Observer.Observe('[' + Attempt + '] error', GetLastErrorText());
                Card.Close();
            end;
        end;
        // Only the OptionCaption entries at positions 0 and 1 (' ' and c1) are accepted; enum captions, names, c4/c5 and the ordinal 4 are refused.
        Observer.Expect('[c1] page', 'c1');
        Observer.Expect('[c1] stored', '1');
        Observer.Expect('[cap1] error', 'Validation error for Field: E,  Message = ''Your entry of ''cap1'' is not an acceptable value for ''E''. (Select Refresh to discard errors)''');
        Observer.Expect('[value1] error', 'Validation error for Field: E,  Message = ''Your entry of ''value1'' is not an acceptable value for ''E''. (Select Refresh to discard errors)''');
        Observer.Expect('[c4] error', 'Validation error for Field: E,  Message = ''Your entry of ''c4'' is not an acceptable value for ''E''. (Select Refresh to discard errors)''');
        Observer.Expect('[cap4] error', 'Validation error for Field: E,  Message = ''Your entry of ''cap4'' is not an acceptable value for ''E''. (Select Refresh to discard errors)''');
        Observer.Expect('[value4] error', 'Validation error for Field: E,  Message = ''Your entry of ''value4'' is not an acceptable value for ''E''. (Select Refresh to discard errors)''');
        Observer.Expect('[4] error', 'Validation error for Field: E,  Message = ''Your entry of ''4'' is not an acceptable value for ''E''. (Select Refresh to discard errors)''');
        Observer.Expect('[c5] error', 'Validation error for Field: E,  Message = ''Your entry of ''c5'' is not an acceptable value for ''E''. (Select Refresh to discard errors)''');
        Observer.Expect('[ ] page', ' ');
        Observer.Expect('[ ] stored', '0');
        Observer.Verify();
    end;

    local procedure SeedSparse()
    var
        Row: Record "LT BO Sparse Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.E := Row.E::value1;
        Row.Insert();
        Row.Id := 4;
        Row.E := Row.E::value4;
        Row.Insert();
        Row.Id := 5;
        Row.E := Row.E::value5;
        Row.Insert();
        Row.Id := 9;
        Row.E := Row.E::" ";
        Row.Insert();
        Commit();
    end;

    local procedure OrdinalRowId(Ordinal: Integer): Integer
    begin
        if Ordinal = 0 then
            exit(9);
        exit(Ordinal);
    end;

    [TryFunction]
    local procedure TrySetSparse(var Card: TestPage "LT BO Sparse Card"; Value: Text)
    begin
        Card.E.SetValue(Value);
    end;
}
