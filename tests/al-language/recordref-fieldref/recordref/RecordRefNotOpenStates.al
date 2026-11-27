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
//   (positioned on a row, not positioned, on an empty table), Page.Run(0, RecRef) (the table's LookupPageId is the list page), and
//   RecRef not open (never opened, after Open(0)) or open on another table. The handlers record which row the page shows. The
//   RecordRef goes in through a Variant (V := RecRef; Page.Run(Id, V)); a control passes a Variant holding a Record.
//   Not probed: Page.Run(Id, RecRef) with the RecordRef itself does not compile (AL0666 under runtime 16, AL0133 "cannot convert
//   from 'RecordRef' to 'Table'" under runtime 18).
//   Already pinned elsewhere, kept here only as part of a state's row: the Fresh and Closed answers of FindFirst, SetLoadFields,
//   SetRecFilter, Count, FieldCount, ReadPermission and Number (UhUnopenedRecordRef.al), and Number, FieldCount and Count after
//   Open(0) (RfTOpen.al).
//   Observe round: every test ends with Observer.Finish(), which fails the test with the readings (OBSERVE:...); nothing is asserted yet.
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
        Observer.Finish();
    end;

    [Test]
    procedure State_OpenZero()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'OpenZero');
        Observer.Finish();
    end;

    [Test]
    procedure State_GetEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'GetEmpty');
        Observer.Finish();
    end;

    [Test]
    procedure State_GetMissing()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'GetMissing');
        Observer.Finish();
    end;

    [Test]
    procedure State_Closed()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'Closed');
        Observer.Finish();
    end;

    [Test]
    procedure State_GetFound()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT RUO Probe";
    begin
        Probe.Row(Observer, 'GetFound');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    // Page.Run(0, RecRef): the table's LookupPageId is the list page.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
