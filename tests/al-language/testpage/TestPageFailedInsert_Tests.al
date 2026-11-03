// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
// Scope: in-scope
// Fixtures used: IPF Row (60039), IPF Card (60027), IPF Delayed Card (60025), IPF Delayed List (60026), Assert (60021)
//
/// <summary>
/// What a test sees when the page's own insert of a new row FAILS, at each moment a TestPage
/// writes a started row: insert on focus, Close(), OK(), New() and Next().
///
/// The failure is the platform's duplicate-key refusal: a row "DUP" exists, and the test types
/// "DUP" into a new record. The fixture table has no triggers, so nothing but the insert itself
/// can fail.
///
/// The raising arms run their page calls inside one asserterror, recording the name of the call
/// they are about to make; the observation is 'step=<the call that raised>;error=<what it raised>'.
/// The silent arms record what happened to the line instead: the cursor's key after the move,
/// both fields' validation error counts, and the table afterwards.
///
/// Measured on real BC (corpus runs 36145940845 and 36148838859, all nine cloud legs): insert on
/// focus and Close() raise; OK().Invoke() raises nothing, and nothing is raised when the TestPage
/// variable goes out of scope either. On a DelayedInsert List, New(), Next() and Last() raise
/// nothing: the cursor stays on the refused line and the "No." control records one validation
/// error. Previous() and First() raise nothing either, but the duplicate-key error then surfaces
/// at the Close() that follows (corpus run 36159837227, all nine cloud legs).
///
/// Written for AL Runner#4624, where the runner's page-driven insert trapped the error and the
/// row, with every value typed into it, disappeared without one.
/// </summary>
codeunit 60045 "IPF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Step: Text;
        NoErrorRaisedTxt: Label 'NO-ERROR-RAISED', Locked = true;

    local procedure Initialize()
    var
        Row: Record "IPF Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'DUP';
        Row.Description := 'orig';
        Row.Insert();
        Step := '';
    end;

    local procedure Observe(): Text
    var
        ErrorText: Text;
    begin
        ErrorText := GetLastErrorText();
        if StrPos(ErrorText, 'already exists') > 0 then
            ErrorText := 'already exists';
        exit(StrSubstNo('step=%1;error=%2', Step, ErrorText));
    end;

    [Test]
    procedure Card_DuplicateKey_InsertOnFocus_RaisesAtTheNonKeyWrite()
    // CLAIM: on a DelayedInsert=false Card, the write to the first non-key control inserts the new
    // row (TPBK Tests 60576). When that insert fails, the SetValue that triggered it raises the
    // duplicate-key error.
    begin
        Initialize();

        asserterror DriveCardInsertOnFocus();

        Assert.AreEqual('step=Description.SetValue;error=already exists', Observe(),
            'which call raised, and what, when the insert-on-focus of a new Card row fails');
    end;

    [Test]
    procedure DelayedCard_DuplicateKey_Close_RaisesTheInsertError()
    // CLAIM: on a DelayedInsert Card, Close() inserts the new row; when that insert fails,
    // Close() raises the duplicate-key error.
    begin
        Initialize();

        asserterror DriveDelayedCard(false);

        Assert.AreEqual('step=Close;error=already exists', Observe(),
            'which call raised, and what, when Close() cannot insert the new Card row');
    end;

    [Test]
    procedure DelayedCard_DuplicateKey_OK_RaisesNothing()
    // MEASURED (corpus run 36148838859, all nine cloud legs): OK().Invoke() raises nothing when the
    // insert fails, and neither does the TestPage variable going out of scope when the drive
    // procedure returns. This arm also records that the existing row keeps its own value.
    var
        Row: Record "IPF Row";
    begin
        Initialize();

        DriveDelayedCardViaOK();

        Row.Get('DUP');
        Assert.AreEqual('step=completed;rows=1;dup=orig',
            StrSubstNo('step=%1;rows=%2;dup=%3', Step, Row.Count(), Row.Description),
            'what OK() leaves behind when it cannot insert the new Card row');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_New_RaisesNothing()
    // MEASURED (corpus run 36148838859, all nine cloud legs): on a DelayedInsert List, New() after
    // a started line whose insert fails raises no error, and neither does the Close() after it.
    // The cursor stays on the refused line, the "No." control holds one validation error, and the
    // existing row is untouched.
    begin
        Initialize();

        Assert.AreEqual('cur=DUP;noErr=1;descErr=0;rows=1;dup=orig', DriveDelayedListObserved('DUP', 'New'),
            'what New() does with a started line whose insert fails');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_Next_RaisesNothing()
    // MEASURED (corpus run 36148838859, all nine cloud legs): the same through Next().
    begin
        Initialize();

        Assert.AreEqual('cur=DUP;noErr=1;descErr=0;rows=1;dup=orig', DriveDelayedListObserved('DUP', 'Next'),
            'what Next() does with a started line whose insert fails');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_Previous_CloseRaisesTheInsertError()
    // MEASURED (corpus run 36148838859, all nine cloud legs): after Previous() leaves the line,
    // the TestPage raises "The record in table IPF Row already exists. Identification fields and
    // values: No.='DUP'". MEASURED (corpus run 36159837227, all nine cloud legs): Previous()
    // itself raises nothing; the error comes from the Close() after it.
    begin
        Initialize();

        asserterror DriveDelayedListRaising('Previous');

        Assert.AreEqual('step=Close;error=already exists', Observe(),
            'which call raised, and what, when Previous() leaves a line whose insert fails');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_First_CloseRaisesTheInsertError()
    // MEASURED (corpus runs 36148838859 and 36159837227, all nine cloud legs): the same through
    // First() -- First() raises nothing, and the Close() after it raises the insert error.
    begin
        Initialize();

        asserterror DriveDelayedListRaising('First');

        Assert.AreEqual('step=Close;error=already exists', Observe(),
            'which call raised, and what, when First() leaves a line whose insert fails');
    end;

    [Test]
    procedure DelayedList_DuplicateKey_Last_RaisesNothing()
    // MEASURED (corpus run 36148838859, all nine cloud legs): Last() raises nothing, the cursor
    // stays on the refused line and the "No." control holds one validation error.
    begin
        Initialize();

        Assert.AreEqual('cur=DUP;noErr=1;descErr=0;rows=1;dup=orig', DriveDelayedListObserved('DUP', 'Last'),
            'what Last() does with a started line whose insert fails');
    end;

    [Test]
    procedure DelayedList_NewKey_New_InsertsTheLine()
    // CLAIM (contrast): with a key that does not exist yet, New() inserts the started line with its
    // typed value, so the duplicate-key arms above differ only in the insert failing.
    var
        Row: Record "IPF Row";
    begin
        Initialize();

        Assert.AreEqual('cur=;noErr=0;descErr=0;rows=2;dup=orig', DriveDelayedListObserved('NEW1', 'New'),
            'what New() does with a started line whose insert succeeds');
        Assert.IsTrue(Row.Get('NEW1'), 'New() must insert the started line');
        Assert.AreEqual('typed', Row.Description, 'the inserted line''s Description');
    end;

    [Test]
    procedure DelayedCard_NewKey_Close_InsertsTheRow()
    // CLAIM (contrast): the same page calls with a key that does not exist yet raise nothing, and
    // Close() writes the row with its typed value while the existing row keeps its own.
    var
        Row: Record "IPF Row";
        Card: TestPage "IPF Delayed Card";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('NEW1');
        Card.Description.SetValue('typed');
        Card.Close();

        Assert.IsTrue(Row.Get('NEW1'), 'Close() must insert the new row');
        Assert.AreEqual('typed', Row.Description, 'the new row''s Description after Close()');
        Row.Get('DUP');
        Assert.AreEqual('orig', Row.Description, 'the existing row''s Description after Close()');
    end;

    local procedure DriveCardInsertOnFocus()
    var
        Card: TestPage "IPF Card";
    begin
        Step := 'OpenNew';
        Card.OpenNew();
        Step := 'No.SetValue';
        Card."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Card.Description.SetValue('typed');
        Step := 'Close';
        Card.Close();
        Step := 'completed';
        Error(NoErrorRaisedTxt);
    end;

    local procedure DriveDelayedCard(ViaOK: Boolean)
    var
        Card: TestPage "IPF Delayed Card";
    begin
        Step := 'OpenNew';
        Card.OpenNew();
        Step := 'No.SetValue';
        Card."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Card.Description.SetValue('typed');
        if ViaOK then begin
            Step := 'OK';
            Card.OK().Invoke();
        end else begin
            Step := 'Close';
            Card.Close();
        end;
        Step := 'completed';
        Error(NoErrorRaisedTxt);
    end;

    local procedure DriveDelayedCardViaOK()
    var
        Card: TestPage "IPF Delayed Card";
    begin
        Step := 'OpenNew';
        Card.OpenNew();
        Step := 'No.SetValue';
        Card."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Card.Description.SetValue('typed');
        Step := 'OK';
        Card.OK().Invoke();
        Step := 'completed';
    end;

    local procedure DriveDelayedListRaising(Move: Text)
    var
        Rows: TestPage "IPF Delayed List";
    begin
        Step := 'OpenNew';
        Rows.OpenNew();
        Step := 'No.SetValue';
        Rows."No.".SetValue('DUP');
        Step := 'Description.SetValue';
        Rows.Description.SetValue('typed');
        Step := Move;
        case Move of
            'Previous':
                Rows.Previous();
            'First':
                Rows.First();
        end;
        Step := 'Close';
        Rows.Close();
        Step := 'completed';
        Error(NoErrorRaisedTxt);
    end;

    local procedure DriveDelayedListObserved(NewKey: Code[20]; Move: Text): Text
    var
        Row: Record "IPF Row";
        Rows: TestPage "IPF Delayed List";
        Observed: Text;
    begin
        Rows.OpenNew();
        Rows."No.".SetValue(NewKey);
        Rows.Description.SetValue('typed');
        case Move of
            'New':
                Rows.New();
            'Next':
                Rows.Next();
            'Previous':
                Rows.Previous();
            'First':
                Rows.First();
            'Last':
                Rows.Last();
        end;
        Observed := StrSubstNo('cur=%1;noErr=%2;descErr=%3', Rows."No.".Value(),
            Rows."No.".ValidationErrorCount(), Rows.Description.ValidationErrorCount());
        Rows.Close();
        Row.Get('DUP');
        exit(StrSubstNo('%1;rows=%2;dup=%3', Observed, Row.Count(), Row.Description));
    end;
}
