// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90796-90799
// Probe: written against al-runner issue 6363. A lookup opened with Page.RunModal(Page, Rec) on a list that sorts descending on a key other than the primary key
//        and declares OnAfterGetRecord and OnAfterGetCurrRecord (the shape of Posted Sales Invoices): what a ModalPageHandler sees after GoToKey (result, current
//        row, trigger log) and what Rec holds after OK. The same list ascending is the comparison. R:<no> = OnAfterGetRecord, C:<no> = OnAfterGetCurrRecord.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
