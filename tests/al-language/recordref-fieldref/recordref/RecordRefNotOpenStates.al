// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-integer-table-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 73480 and 73481, pages 73480 and 73481, helper codeunit 73480, test codeunits 73481 and 73482
// Probe (AL Runner issue 8254): RecordRef members on a RecordRef that is not open, by the way it came to be not open, and Page.Run with
//   a RecordRef as the record.
//   States (each cell builds its own RecordRef in the state): Fresh (never opened); OpenZero (after Open(0)); GetEmpty (after
//   Get(RecordId) of an empty RecordId); GetMissing (after Get(RecordId) of a RecordId of the row table whose row does not exist);
//   Closed (opened on the row table, then Close()); GetFound (control: after Get(RecordId) of a row that exists).
//   Members: Duplicate (and the Number of the duplicate), ClearMarks, FindFirst, SetLoadFields(1), AddLoadFields(1), SetRecFilter,
//   FilterGroup (read), FilterGroup(2) (set), MarkedOnly, Mark, HasFilter, GetView, Count, FieldCount, ReadPermission and Number.
//   Each cell runs in a TryFunction and records "ok: <result>" (ok alone when the member returns nothing) or "E: <GetLastErrorText> |
//   <GetLastErrorCode>". A test is State_<State>; it starts with state = what building the state returned (Get's result) and
//   number = the RecordRef's Number after it.
//   Page.Run tests (codeunit 73482): Page.Run(<card or list page>, V) and Page.RunModal(<card>, V), V a Variant holding RecRef, with RecRef open on the page's table
//   (positioned on a row, not positioned, on an empty table), Page.Run(0, V) (the table's LookupPageId is the list page), and
//   RecRef not open (never opened, after Open(0), closed, after Get of an empty RecordId and of a missing row) or open on another
//   table. The handlers record which row the page shows. The
//   RecordRef goes in through a Variant (V := RecRef; Page.Run(Id, V)); a control passes a Variant holding a Record.
//   Not probed: Page.Run(Id, RecRef) with the RecordRef itself does not compile (AL0666 under runtime 16, AL0133 "cannot convert
//   from 'RecordRef' to 'Table'" under runtime 18).
//   Already pinned elsewhere, kept here only as part of a state's row: the Fresh and Closed answers of FindFirst, SetLoadFields,
//   SetRecFilter, Count, FieldCount, ReadPermission and Number (UhUnopenedRecordRef.al), and Number, FieldCount and Count after
//   Open(0) (RfTOpen.al). CePageRun.al pins Page.Run and Page.RunModal with a Variant holding a positioned RecordRef, and that the
//   RecordRef form does not compile (must-not-compile cases 1633 and 1634); W4RecordRefGetUnopened.al pins Get of a missing
//   RecordId on a never-opened RecordRef.
//   Measured on BC 29.0 (Linux, W1, en-US session) with an invented app holding these objects, through the dev endpoint's
//   TestRunnerHub (the member tests also through a codeunit run request: the same readings); the values are that run's readings,
//   turned into Expect and Verify by convert.py verbatim. This pull request's CI gave the same values on 27.5, 28.5 and 29.0. The
//   review cells Card_Closed, Card_AfterGetEmpty and Card_AfterGetMissing were measured on a local BC 29.0.54011.57673 on
//   2026-11-28 and are asserted on BC 28 and later; on BC 27.5 they are an observe round, red on purpose (#else ends with Finish()).
//   Facts (BC 27.5, 28.5 and 29.0):
//   - Every member above but Number fails with 'The record is not open.' (RecordNotOpened) in every state that is not open: Fresh,
//     OpenZero, GetEmpty, GetMissing and Closed, Duplicate and ClearMarks included. Number is 0 in all of them.
//   - Open(0) raises nothing. Get of an empty RecordId and of a RecordId whose row does not exist both return No and leave the
//     RecordRef not open (Number 0): Get does not open the table of the RecordId when the row is missing.
//   - GetFound (control): every member works; Duplicate gives a RecordRef on the same table.
//   - Page.Run(Id, V) with V holding an open RecordRef opens the page on the RecordRef's current row (B after FindLast; the first
//     row A when not positioned; an empty card on an empty table). The list page and Page.Run(0, V) (the LookupPageId list) do the
//     same; Page.RunModal returns LookupOK. The same as a Variant holding a Record.
//   - V holding a RecordRef never opened or after Open(0): 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to
//     Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.' (Conversion); open on another table: 'The table IDs do not match.'
//     (TableIdMismatch). The page does not open.
// BC versions: 27, 28, 29 by CI
table 73480 "LT RUO Row"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT RUO List";
    DrillDownPageId = "LT RUO List";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 73481 "LT RUO Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73480 "LT RUO Card"
{
    PageType = Card;
    SourceTable = "LT RUO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

page 73481 "LT RUO List"
{
    PageType = List;
    SourceTable = "LT RUO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 73480 "LT RUO Probe"
{
    // Rows A and B in the row table, nothing in the other table.
    procedure Seed()
    var
        Row: Record "LT RUO Row";
        Other: Record "LT RUO Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row."No." := 'A';
        Row.Name := 'Alpha';
        Row.Insert();
        Row."No." := 'B';
        Row.Name := 'Beta';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryOpenZero(var R: RecordRef)
    begin
        R.Open(0);
    end;

    // Puts R into the state; returns what building it returned.
    procedure MakeState(var R: RecordRef; State: Text): Text
    var
        Row: Record "LT RUO Row";
        Empty: RecordId;
        Id: RecordId;
    begin
        case State of
            'Fresh':
                exit('ok');
            'OpenZero':
                begin
                    if TryOpenZero(R) then
                        exit('ok');
                    exit('E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
                end;
            'GetEmpty':
                exit(Format(R.Get(Empty)));
            'GetMissing':
                begin
                    Row."No." := 'GONE';
                    Id := Row.RecordId();
                    exit(Format(R.Get(Id)));
                end;
            'Closed':
                begin
                    R.Open(Database::"LT RUO Row");
                    R.Close();
                    exit('ok');
                end;
            'GetFound':
                begin
                    Row.Get('B');
                    Id := Row.RecordId();
                    exit(Format(R.Get(Id)));
                end;
        end;
    end;

    [TryFunction]
    local procedure TryMember(var R: RecordRef; Member: Text; var Result: Text)
    var
        R2: RecordRef;
    begin
        case Member of
            'Duplicate':
                begin
                    R2 := R.Duplicate();
                    Result := Format(R2.Number());
                end;
            'ClearMarks':
                R.ClearMarks();
            'FindFirst':
                Result := Format(R.FindFirst());
            'SetLoadFields':
                R.SetLoadFields(1);
            'AddLoadFields':
                R.AddLoadFields(1);
            'SetRecFilter':
                R.SetRecFilter();
            'FilterGroupGet':
                Result := Format(R.FilterGroup());
            'FilterGroupSet':
                R.FilterGroup(2);
            'MarkedOnly':
                Result := Format(R.MarkedOnly());
            'Mark':
                Result := Format(R.Mark());
            'HasFilter':
                Result := Format(R.HasFilter());
            'GetView':
                Result := R.GetView();
            'Count':
                Result := Format(R.Count());
            'FieldCount':
                Result := Format(R.FieldCount());
            'ReadPermission':
                Result := Format(R.ReadPermission());
            'Number':
                Result := Format(R.Number());
        end;
    end;

    procedure Outcome(Ok: Boolean; Result: Text): Text
    var
        T: Text;
    begin
        if Ok then begin
            if Result = '' then
                exit('ok');
            exit('ok: ' + Result);
        end;
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    // One cell: a new RecordRef in the state, then the member.
    procedure Cell(var Observer: Codeunit "Probe Observer"; State: Text; Member: Text)
    var
        R: RecordRef;
        Result: Text;
        Ok: Boolean;
    begin
        MakeState(R, State);
        ClearLastError();
        Ok := TryMember(R, Member, Result);
        Observer.Observe(Member, Outcome(Ok, Result));
    end;

    [TryFunction]
    local procedure TryNumber(var R: RecordRef; var Result: Text)
    begin
        Result := Format(R.Number());
    end;

    // The state's row: what building it returned, the Number after it, then every member.
    procedure Row(var Observer: Codeunit "Probe Observer"; State: Text)
    var
        R: RecordRef;
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Observer.Observe('state', MakeState(R, State));
        Ok := TryNumber(R, Result);
        Observer.Observe('number', Outcome(Ok, Result));
        Cell(Observer, State, 'Duplicate');
        Cell(Observer, State, 'ClearMarks');
        Cell(Observer, State, 'FindFirst');
        Cell(Observer, State, 'SetLoadFields');
        Cell(Observer, State, 'AddLoadFields');
        Cell(Observer, State, 'SetRecFilter');
        Cell(Observer, State, 'FilterGroupGet');
        Cell(Observer, State, 'FilterGroupSet');
        Cell(Observer, State, 'MarkedOnly');
        Cell(Observer, State, 'Mark');
        Cell(Observer, State, 'HasFilter');
        Cell(Observer, State, 'GetView');
        Cell(Observer, State, 'Count');
        Cell(Observer, State, 'FieldCount');
        Cell(Observer, State, 'ReadPermission');
        Cell(Observer, State, 'Number');
    end;
}

codeunit 73481 "LT RUO Not Open Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure State_Fresh()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'Fresh');
        Observer.Expect('state', 'ok');
        Observer.Expect('number', 'ok: 0');
        Observer.Expect('Duplicate', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ClearMarks', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FindFirst', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('AddLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetRecFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupGet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupSet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('MarkedOnly', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Mark', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('HasFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('GetView', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Count', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FieldCount', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ReadPermission', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Number', 'ok: 0');
        Observer.Verify();
    end;

    [Test]
    procedure State_OpenZero()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'OpenZero');
        Observer.Expect('state', 'ok');
        Observer.Expect('number', 'ok: 0');
        Observer.Expect('Duplicate', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ClearMarks', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FindFirst', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('AddLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetRecFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupGet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupSet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('MarkedOnly', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Mark', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('HasFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('GetView', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Count', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FieldCount', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ReadPermission', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Number', 'ok: 0');
        Observer.Verify();
    end;

    [Test]
    procedure State_GetEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'GetEmpty');
        Observer.Expect('state', 'No');
        Observer.Expect('number', 'ok: 0');
        Observer.Expect('Duplicate', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ClearMarks', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FindFirst', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('AddLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetRecFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupGet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupSet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('MarkedOnly', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Mark', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('HasFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('GetView', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Count', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FieldCount', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ReadPermission', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Number', 'ok: 0');
        Observer.Verify();
    end;

    [Test]
    procedure State_GetMissing()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'GetMissing');
        Observer.Expect('state', 'No');
        Observer.Expect('number', 'ok: 0');
        Observer.Expect('Duplicate', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ClearMarks', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FindFirst', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('AddLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetRecFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupGet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupSet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('MarkedOnly', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Mark', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('HasFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('GetView', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Count', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FieldCount', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ReadPermission', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Number', 'ok: 0');
        Observer.Verify();
    end;

    [Test]
    procedure State_Closed()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'Closed');
        Observer.Expect('state', 'ok');
        Observer.Expect('number', 'ok: 0');
        Observer.Expect('Duplicate', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ClearMarks', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FindFirst', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('AddLoadFields', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('SetRecFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupGet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FilterGroupSet', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('MarkedOnly', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Mark', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('HasFilter', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('GetView', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Count', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('FieldCount', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('ReadPermission', 'E: The record is not open. | RecordNotOpened');
        Observer.Expect('Number', 'ok: 0');
        Observer.Verify();
    end;

    [Test]
    procedure State_GetFound()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'GetFound');
        Observer.Expect('state', 'Yes');
        Observer.Expect('number', 'ok: 73480');
        Observer.Expect('Duplicate', 'ok: 73480');
        Observer.Expect('ClearMarks', 'ok');
        Observer.Expect('FindFirst', 'ok: Yes');
        Observer.Expect('SetLoadFields', 'ok');
        Observer.Expect('AddLoadFields', 'ok');
        Observer.Expect('SetRecFilter', 'ok');
        Observer.Expect('FilterGroupGet', 'ok: 0');
        Observer.Expect('FilterGroupSet', 'ok');
        Observer.Expect('MarkedOnly', 'ok: No');
        Observer.Expect('Mark', 'ok: No');
        Observer.Expect('HasFilter', 'ok: No');
        Observer.Expect('GetView', 'ok: VERSION(1) SORTING(No.)');
        Observer.Expect('Count', 'ok: 2');
        Observer.Expect('FieldCount', 'ok: 2');
        Observer.Expect('ReadPermission', 'ok: Yes');
        Observer.Expect('Number', 'ok: 73480');
        Observer.Verify();
    end;
}

codeunit 73482 "LT RUO Page Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "LT RUO Card")
    begin
        Seen += 'card:' + Card."No.".Value() + ';';
    end;

    [PageHandler]
    procedure ListHandler(var List: TestPage "LT RUO List")
    begin
        Seen += 'list:' + List."No.".Value() + ';';
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var Card: TestPage "LT RUO Card")
    begin
        Seen += 'modal card:' + Card."No.".Value() + ';';
        Card.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryRun(PageId: Integer; var V: Variant)
    begin
        Page.Run(PageId, V);
    end;

    // Page.Run(PageId, V), V a Variant holding R.
    local procedure RunCell(var Observer: Codeunit "Probe Observer"; PageId: Integer; var R: RecordRef)
    var
        V: Variant;
    begin
        V := R;
        RunVariantCell(Observer, PageId, V);
    end;

    local procedure RunVariantCell(var Observer: Codeunit "Probe Observer"; PageId: Integer; var V: Variant)
    var
        Probe: Codeunit "LT RUO Probe";
        Ok: Boolean;
    begin
        Seen := '';
        ClearLastError();
        Ok := TryRun(PageId, V);
        Observer.Observe('run', Probe.Outcome(Ok, ''));
        Observer.Observe('seen', Seen);
    end;

    // Open on the row table and positioned on row B (FindLast), the card page.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_OpenPositioned()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        R.Open(Database::"LT RUO Row");
        R.FindLast();
        RunCell(Observer, Page::"LT RUO Card", R);
        Observer.Expect('run', 'ok');
        Observer.Expect('seen', 'card:B;');
        Observer.Verify();
    end;

    // Open on the row table, no Find: the card page.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_OpenNotPositioned()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        R.Open(Database::"LT RUO Row");
        RunCell(Observer, Page::"LT RUO Card", R);
        Observer.Expect('run', 'ok');
        Observer.Expect('seen', 'card:A;');
        Observer.Verify();
    end;

    // Open on the row table with no rows: the card page.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_OpenEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        Row: Record "LT RUO Row";
        R: RecordRef;
    begin
        Probe.Seed();
        Row.DeleteAll();
        R.Open(Database::"LT RUO Row");
        RunCell(Observer, Page::"LT RUO Card", R);
        Observer.Expect('run', 'ok');
        Observer.Expect('seen', 'card:;');
        Observer.Verify();
    end;

    // Open on the row table and positioned on row B: the list page.
    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_OpenPositioned()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        R.Open(Database::"LT RUO Row");
        R.FindLast();
        RunCell(Observer, Page::"LT RUO List", R);
        Observer.Expect('run', 'ok');
        Observer.Expect('seen', 'list:B;');
        Observer.Verify();
    end;

    // Page.Run(0, V), V a Variant holding the RecordRef: the table's LookupPageId is the list page.
    [Test]
    [HandlerFunctions('ListHandler')]
    procedure PageZero_OpenPositioned()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        R.Open(Database::"LT RUO Row");
        R.FindLast();
        RunCell(Observer, 0, R);
        Observer.Expect('run', 'ok');
        Observer.Expect('seen', 'list:B;');
        Observer.Verify();
    end;

    // Page.RunModal with a RecordRef positioned on row B: the card page; also the action it returns.
    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure CardModal_OpenPositioned()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
        V: Variant;
        Result: Action;
    begin
        Probe.Seed();
        R.Open(Database::"LT RUO Row");
        R.FindLast();
        V := R;
        Seen := '';
        Result := Page.RunModal(Page::"LT RUO Card", V);
        Observer.Observe('action', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('seen', 'modal card:B;');
        Observer.Verify();
    end;

    // Control: a Variant holding a Record positioned on row B, the card page.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_VariantRecord()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        Row: Record "LT RUO Row";
        V: Variant;
    begin
        Probe.Seed();
        Row.FindLast();
        V := Row;
        RunVariantCell(Observer, Page::"LT RUO Card", V);
        Observer.Expect('run', 'ok');
        Observer.Expect('seen', 'card:B;');
        Observer.Verify();
    end;

    // A RecordRef never opened: the card page (no handler: the page is not expected to open).
    [Test]
    procedure Card_NeverOpened()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        RunCell(Observer, Page::"LT RUO Card", R);
        Observer.Expect('run', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle. | Conversion');
        Observer.Expect('seen', '');
        Observer.Verify();
    end;

    // A RecordRef after Open(0): the card page (no handler).
    [Test]
    procedure Card_AfterOpenZero()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        R.Open(0);
        RunCell(Observer, Page::"LT RUO Card", R);
        Observer.Expect('run', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle. | Conversion');
        Observer.Expect('seen', '');
        Observer.Verify();
    end;

    // A RecordRef open on another table than the page's: the card page (no handler).
    [Test]
    procedure Card_OtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        R.Open(Database::"LT RUO Other");
        RunCell(Observer, Page::"LT RUO Card", R);
        Observer.Expect('run', 'E: The table IDs do not match. | TableIdMismatch');
        Observer.Expect('seen', '');
        Observer.Verify();
    end;

    // A RecordRef in the state State (closed, after Get of an empty RecordId, after Get of a missing row): the card page, no handler.
    local procedure StateCell(var Observer: Codeunit "Probe Observer"; State: Text)
    var
        Probe: Codeunit "LT RUO Probe";
        R: RecordRef;
    begin
        Probe.Seed();
        Observer.Observe('state', Probe.MakeState(R, State));
        RunCell(Observer, Page::"LT RUO Card", R);
    end;

    [Test]
    procedure Card_Closed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StateCell(Observer, 'Closed');
#if BC28PLUS
        Observer.Expect('state', 'ok');
        Observer.Expect('run', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle. | Conversion');
        Observer.Expect('seen', '');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Card_AfterGetEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StateCell(Observer, 'GetEmpty');
#if BC28PLUS
        Observer.Expect('state', 'No');
        Observer.Expect('run', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle. | Conversion');
        Observer.Expect('seen', '');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    [Test]
    procedure Card_AfterGetMissing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StateCell(Observer, 'GetMissing');
#if BC28PLUS
        Observer.Expect('state', 'No');
        Observer.Expect('run', 'E: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle. | Conversion');
        Observer.Expect('seen', '');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;
}
