// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setrecord-method
// Scope: in-scope
// Fixtures used: TSR Row (60845), TSR Card (60846), TSR Host (60847)
//
// Migrated from AL Runner tests/runner-extras/testpage-setrecord (TsrTests.Codeunit.al).
//
/// <summary>
/// <c>SetRecord</c> then <c>RunModal</c> is how AL hands a page the record it must show. The
/// caller has already located the row; the page is not supposed to go looking for one.
///
/// A runner that drops it opens the page on whatever the source table yields first, which is a
/// real row with plausible values — so the handler reads the wrong record rather than an obviously
/// empty one, and the failure looks like the page is bound to the wrong thing.
///
/// The two tests pick DIFFERENT rows, neither of them first. That pairing is what makes a green
/// result mean "the page opened on the record it was given" and not "the page happened to open
/// on the row this test wanted".
/// </summary>
codeunit 60848 "TSR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SeenNo: Code[20];

    local procedure Initialize()
    var
        Row: Record "TSR Row";
    begin
        Row.DeleteAll();
        Insert1('A', 'first-row');
        Insert1('B', 'the-b-row');
        Insert1('C', 'the-c-row');
        SeenNo := '';
    end;

    local procedure Insert1(No: Code[20]; Note: Text[30])
    var
        Row: Record "TSR Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Note := Note;
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure RunModal_OpensOnTheRecordSetByTheCaller()
    var
        Host: TestPage "TSR Host";
    begin
        Initialize();

        Host.OpenEdit();
        Host.First();
        Host.OpenB.Invoke();
        Host.Close();

        // 'A' is what the table yields first, so a runner that ignored SetRecord lands there.
        if SeenNo <> 'B' then
            Error('The modal page opened on <%1>, expected <B> — SetRecord was not honoured.', SeenNo);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure RunModal_OpensOnADifferentRecordWhenTheCallerSetsADifferentOne()
    var
        Host: TestPage "TSR Host";
    begin
        Initialize();

        Host.OpenEdit();
        Host.First();
        Host.OpenC.Invoke();
        Host.Close();

        // The discriminator: same page, same handler, different record. Only actually reading the
        // caller's record can produce both this answer and the one above.
        if SeenNo <> 'C' then
            Error('The modal page opened on <%1>, expected <C> — SetRecord was not honoured.', SeenNo);
    end;

    [ModalPageHandler]
    procedure CardHandler(var Card: TestPage "TSR Card")
    begin
        SeenNo := Card."No.".Value();
        // Read a second field off the same row: a runner could conceivably answer the key from
        // the caller's record while the rest of the page still sits on another row.
        if Card.Note.Value() <> 'the-' + LowerCase(SeenNo) + '-row' then
            Error('The page''s key says %1 but its Note says <%2> — the page is on two rows at once.',
                SeenNo, Card.Note.Value());
        Card.OK().Invoke();
    end;
}
