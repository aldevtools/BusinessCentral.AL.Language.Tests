// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90796-90799
// Probe: written against al-runner issue 6363. A lookup opened with Page.RunModal(Page, Rec) on a list that sorts descending on a key other than the primary key
//        and declares OnAfterGetRecord and OnAfterGetCurrRecord (the shape of Posted Sales Invoices): what a ModalPageHandler sees after GoToKey (result, current
//        row, trigger log) and what Rec holds after OK. The same list ascending is the comparison. R:<no> = OnAfterGetRecord, C:<no> = OnAfterGetCurrRecord.
//        The _Desc<N>_ tests (al-runner issue 8172) seed 31 to 100 rows, more rows above the 21 the list holds than _Last, and log the reads
//        of a GoToKey to the first row of the view, the row above the rows held, a row inside them, and a key the view does not have.
// BC versions: 27, 28, 29

table 90796 "LT WD Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Posting Date"; Date) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByDate; "Posting Date") { }
    }
}

codeunit 90797 "LT WD Doc Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ',';
        Lines += Line;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

page 90796 "LT WD Docs Desc"
{
    PageType = List;
    SourceTable = "LT WD Doc";
    SourceTableView = sorting("Posting Date") order(descending);
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(No; Rec."No.") { }
                field(PostingDate; Rec."Posting Date") { }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WD Doc Log";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT WD Doc Log";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

page 90798 "LT WD Docs Asc"
{
    PageType = List;
    SourceTable = "LT WD Doc";
    SourceTableView = sorting("Posting Date") order(ascending);
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(No; Rec."No.") { }
                field(PostingDate; Rec."Posting Date") { }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT WD Doc Log";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT WD Doc Log";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

codeunit 90799 "LT WD Modal GoToKey Desc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        WantedNo: Code[20];
        Observer: Codeunit "Probe Observer";

    local procedure Seed(Rows: Integer)
    var
        Doc: Record "LT WD Doc";
        i: Integer;
    begin
        Doc.DeleteAll();
        for i := 1 to Rows do begin
            Doc."No." := 'D' + Format(i, 2, '<Integer,2><Filler Character,0>');
            Doc."Posting Date" := 20260101D + i;
            Doc.Insert();
        end;
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Descending_Last()
    var
        Doc: Record "LT WD Doc";
    begin
        Seed(30);
        WantedNo := 'D01';
        Observer.Observe('RunModal', Format(Page.RunModal(Page::"LT WD Docs Desc", Doc)));
        Observer.Observe('picked', Doc."No.");
        Observer.Expect('opening log', 'R:D01,R:D02,R:D03,R:D04,R:D05,R:D06,R:D07,R:D08,R:D09,R:D10,R:D11,R:D12,R:D13,R:D14,R:D15,R:D16,R:D17,R:D18,R:D19,R:D20,R:D21,R:D01,R:D01,R:D01,C:D01');
        Observer.Expect('GoToKey', 'Yes');
        Observer.Expect('GoToKey log', 'R:D21,R:D22,R:D23,R:D24,R:D25,R:D26,R:D27,R:D28,R:D29,R:D30,R:D30,R:D30,C:D30,R:D29,R:D29,R:D29,C:D29,R:D28,R:D28,R:D28,C:D28,R:D27,R:D27,R:D27,C:D27,R:D26,R:D26,R:D26,C:D26,R:D25,R:D25,R:D25,C:D25,R:D24,R:D24,R:D24,C:D24,R:D23,R:D23,R:D23,C:D23,R:D22,R:D22,R:D22,C:D22,R:D21,R:D21,R:D21,C:D21,R:D20,R:D20,R:D20,C:D20,R:D19,R:D19,R:D19,C:D19,R:D18,R:D18,R:D18,C:D18,R:D17,R:D17,R:D17,C:D17,R:D16,R:D16,R:D16,C:D16,R:D15,R:D15,R:D15,C:D15,R:D14,R:D14,R:D14,C:D14,R:D13,R:D13,R:D13,C:D13,R:D12,R:D12,R:D12,C:D12,R:D11,R:D11,R:D11,C:D11,R:D10,R:D10,R:D10,C:D10,R:D09,R:D09,R:D09,C:D09,R:D08,R:D08,R:D08,C:D08,R:D07,R:D07,R:D07,C:D07,R:D06,R:D06,R:D06,C:D06,R:D05,R:D05,R:D05,C:D05,R:D04,R:D04,R:D04,C:D04,R:D03,R:D03,R:D03,C:D03,R:D02,R:D02,R:D02,C:D02,R:D01,R:D01,R:D01,C:D01');
        Observer.Expect('current', 'D01');
        Observer.Expect('RunModal', 'LookupOK');
        Observer.Expect('picked', 'D01');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Descending_First()
    var
        Doc: Record "LT WD Doc";
    begin
        Seed(30);
        WantedNo := 'D30';
        Observer.Observe('RunModal', Format(Page.RunModal(Page::"LT WD Docs Desc", Doc)));
        Observer.Observe('picked', Doc."No.");
        Observer.Expect('opening log', 'R:D01,R:D02,R:D03,R:D04,R:D05,R:D06,R:D07,R:D08,R:D09,R:D10,R:D11,R:D12,R:D13,R:D14,R:D15,R:D16,R:D17,R:D18,R:D19,R:D20,R:D21,R:D01,R:D01,R:D01,C:D01');
        Observer.Expect('GoToKey', 'Yes');
        Observer.Expect('GoToKey log', 'R:D21,R:D22,R:D23,R:D24,R:D25,R:D26,R:D27,R:D28,R:D29,R:D30,R:D30,R:D30,C:D30');
        Observer.Expect('current', 'D30');
        Observer.Expect('RunModal', 'LookupOK');
        Observer.Expect('picked', 'D30');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Descending_FiveRows()
    var
        Doc: Record "LT WD Doc";
    begin
        Seed(5);
        WantedNo := 'D02';
        Observer.Observe('RunModal', Format(Page.RunModal(Page::"LT WD Docs Desc", Doc)));
        Observer.Observe('picked', Doc."No.");
        Observer.Expect('opening log', 'R:D01,R:D02,R:D03,R:D04,R:D05,R:D01,R:D01,R:D01,C:D01');
        Observer.Expect('GoToKey', 'Yes');
        Observer.Expect('GoToKey log', 'R:D05,R:D05,R:D05,C:D05,R:D04,R:D04,R:D04,C:D04,R:D03,R:D03,R:D03,C:D03,R:D02,R:D02,R:D02,C:D02');
        Observer.Expect('current', 'D02');
        Observer.Expect('RunModal', 'LookupOK');
        Observer.Expect('picked', 'D02');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickAscHandler')]
    procedure WD_ModalGoToKey_Ascending()
    var
        Doc: Record "LT WD Doc";
    begin
        Seed(30);
        WantedNo := 'D01';
        Observer.Observe('RunModal', Format(Page.RunModal(Page::"LT WD Docs Asc", Doc)));
        Observer.Observe('picked', Doc."No.");
        Observer.Expect('opening log', 'R:D01,R:D02,R:D03,R:D04,R:D05,R:D06,R:D07,R:D08,R:D09,R:D10,R:D11,R:D12,R:D13,R:D14,R:D15,R:D16,R:D17,R:D18,R:D19,R:D20,R:D01,R:D01,R:D01,C:D01');
        Observer.Expect('GoToKey', 'Yes');
        Observer.Expect('GoToKey log', '');
        Observer.Expect('current', 'D01');
        Observer.Expect('RunModal', 'LookupOK');
        Observer.Expect('picked', 'D01');
        Observer.Verify();
    end;

    // Like Seed, with three digits so 100 rows keep their numbers: D001, D002, ...
    local procedure SeedWide(Rows: Integer)
    var
        Doc: Record "LT WD Doc";
        i: Integer;
    begin
        Doc.DeleteAll();
        for i := 1 to Rows do begin
            Doc."No." := 'D' + Format(i, 3, '<Integer,3><Filler Character,0>');
            Doc."Posting Date" := 20260101D + i;
            Doc.Insert();
        end;
    end;

    // al-runner issue 8172: the reads after GoToKey with more rows above the 21 the list holds than the 9 of _Last. The open reads
    // the last 21 rows of the view (D001..D021); Wanted is the first row of the view, the row just above the rows held (D022), a
    // row inside them (D010), or a key the view does not have.
    local procedure RunWide(Rows: Integer; Wanted: Code[20])
    var
        Doc: Record "LT WD Doc";
    begin
        SeedWide(Rows);
        WantedNo := Wanted;
        Observer.Observe('RunModal', Format(Page.RunModal(Page::"LT WD Docs Desc", Doc)));
        Observer.Observe('picked', Doc."No.");
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc31_First()
    begin
        RunWide(31, 'D031');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc31_Above()
    begin
        RunWide(31, 'D022');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc31_Held()
    begin
        RunWide(31, 'D010');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc31_Missing()
    begin
        RunWide(31, 'X999');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc35_First()
    begin
        RunWide(35, 'D035');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc35_Above()
    begin
        RunWide(35, 'D022');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc35_Held()
    begin
        RunWide(35, 'D010');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc35_Missing()
    begin
        RunWide(35, 'X999');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc41_First()
    begin
        RunWide(41, 'D041');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc41_Above()
    begin
        RunWide(41, 'D022');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc41_Held()
    begin
        RunWide(41, 'D010');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc41_Missing()
    begin
        RunWide(41, 'X999');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc42_First()
    begin
        RunWide(42, 'D042');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc42_Above()
    begin
        RunWide(42, 'D022');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc42_Held()
    begin
        RunWide(42, 'D010');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc42_Missing()
    begin
        RunWide(42, 'X999');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc60_First()
    begin
        RunWide(60, 'D060');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc60_Above()
    begin
        RunWide(60, 'D022');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc60_Held()
    begin
        RunWide(60, 'D010');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc60_Missing()
    begin
        RunWide(60, 'X999');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc100_First()
    begin
        RunWide(100, 'D100');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc100_Above()
    begin
        RunWide(100, 'D022');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc100_Held()
    begin
        RunWide(100, 'D010');
    end;

    [Test]
    [HandlerFunctions('PickDescHandler')]
    procedure WD_ModalGoToKey_Desc100_Missing()
    begin
        RunWide(100, 'X999');
    end;

    [ModalPageHandler]
    procedure PickDescHandler(var Docs: TestPage "LT WD Docs Desc")
    var
        Log: Codeunit "LT WD Doc Log";
    begin
        Observer.Observe('opening log', Log.Take());
        Observer.Observe('GoToKey', Format(Docs.GoToKey(WantedNo)));
        Observer.Observe('GoToKey log', Log.Take());
        Observer.Observe('current', Docs.No.Value());
        Docs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickAscHandler(var Docs: TestPage "LT WD Docs Asc")
    var
        Log: Codeunit "LT WD Doc Log";
    begin
        Observer.Observe('opening log', Log.Take());
        Observer.Observe('GoToKey', Format(Docs.GoToKey(WantedNo)));
        Observer.Observe('GoToKey log', Log.Take());
        Observer.Observe('current', Docs.No.Value());
        Docs.OK().Invoke();
    end;
}
