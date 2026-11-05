// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-get-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 95980 - 95985 (TP R7138 *)
// local object: the list's OnOpenPage and OnAfterGetCurrRecord triggers and the card action's RunPageLink are what the test checks
// Probe: from al-runner issue 7138 (Purchase Order List's attachment FactBox: LoadDataFromRecord(Rec) -> MainRecordRef.Get(MainRecordRef.RecordId)).
//   A Card action opens a List (Editable = false) with RunObject, RunPageLink = "Project Code" = field(Code) and RunPageView =
//   sorting("Project Code"). The list logs in OnOpenPage (Rec's filters and Count) and in OnAfterGetCurrRecord, through a procedure that
//   takes Rec as a Variant: the filters and Count of a RecordRef.GetTable copy, its Get(RecordId) of the current row, its Get of the
//   RecordId of a row outside the link; and through a procedure that takes Rec by value: its filters, Get of the current and of an
//   outside row. Orders: O1, O2 of P1; O3, O4 of P2; the card stands on P2. Handlers: one that walks the list with First/Next, one that
//   reads the shown row only.
// BC versions: 27, 28, 29

table 95980 "TP R7138 Project"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 95981 "TP R7138 Order"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Project Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(ByProject; "Project Code") { }
    }
}

page 95982 "TP R7138 Project Card"
{
    PageType = Card;
    SourceTable = "TP R7138 Project";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Orders)
            {
                ApplicationArea = All;
                RunObject = page "TP R7138 Order List";
                RunPageLink = "Project Code" = field(Code);
                RunPageView = sorting("Project Code");
            }
        }
    }
}

page 95983 "TP R7138 Order List"
{
    PageType = List;
    SourceTable = "TP R7138 Order";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Project Code"; Rec."Project Code") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "TP R7138 Log";
    begin
        Log.Add('open[' + Rec.GetFilters() + '] n=' + Format(Rec.Count()) + ' rec=' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TP R7138 Log";
    begin
        Log.Add('agcr ' + Rec."No.");
        FromVariant(Rec);
        FromCopy(Rec);
    end;

    local procedure FromVariant(MainRecordVariant: Variant)
    var
        MainRecordRef: RecordRef;
        Outside: Record "TP R7138 Order";
        Log: Codeunit "TP R7138 Log";
    begin
        MainRecordRef.GetTable(MainRecordVariant);
        Log.Add('rr[' + MainRecordRef.GetFilters() + '] n=' + Format(MainRecordRef.Count()));
        if MainRecordRef.Get(MainRecordRef.RecordId) then
            Log.Add('rr.get own ' + Format(MainRecordRef.Field(1).Value))
        else
            Log.Add('rr.get own missing');
        Outside.Get('O1');
        if MainRecordRef.Get(Outside.RecordId) then
            Log.Add('rr.get O1 ' + Format(MainRecordRef.Field(1).Value))
        else
            Log.Add('rr.get O1 missing');
    end;

    local procedure FromCopy(Copy: Record "TP R7138 Order")
    var
        Own: Code[20];
        Log: Codeunit "TP R7138 Log";
    begin
        Own := Copy."No.";
        Log.Add('copy[' + Copy.GetFilters() + '] n=' + Format(Copy.Count()));
        if Copy.Get(Own) then
            Log.Add('copy.get own ' + Copy."No.")
        else
            Log.Add('copy.get own missing');
        if Copy.Get('O1') then
            Log.Add('copy.get O1 ' + Copy."No.")
        else
            Log.Add('copy.get O1 missing');
    end;
}

codeunit 95984 "TP R7138 Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Listed: Text;
        Walk: Boolean;

    local procedure Initialize()
    var
        Project: Record "TP R7138 Project";
        "Order": Record "TP R7138 Order";
        Log: Codeunit "TP R7138 Log";
    begin
        Project.DeleteAll();
        "Order".DeleteAll();
        Project.Code := 'P1';
        Project.Insert();
        Project.Code := 'P2';
        Project.Insert();
        InsertOrder('O1', 'P1');
        InsertOrder('O2', 'P1');
        InsertOrder('O3', 'P2');
        InsertOrder('O4', 'P2');
        Listed := '';
        Log.Reset();
    end;

    local procedure InsertOrder(No: Code[20]; ProjectCode: Code[20])
    var
        "Order": Record "TP R7138 Order";
    begin
        "Order"."No." := No;
        "Order"."Project Code" := ProjectCode;
        "Order".Insert();
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer")
    var
        Project: Record "TP R7138 Project";
        Card: TestPage "TP R7138 Project Card";
        Log: Codeunit "TP R7138 Log";
    begin
        Project.Get('P2');
        Card.OpenView();
        Card.GoToRecord(Project);
        Log.Reset();
        Card.Orders.Invoke();
        Observer.Observe('listed', Listed);
        Observer.Observe('log', Log.Get());
        Card.Close();
    end;

    [Test]
    [HandlerFunctions('OrderListHandler')]
    procedure TP7138_RunPageLinkList_WalkFirstNext_CopyGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Walk := true;
        Run(Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OrderListHandler')]
    procedure TP7138_RunPageLinkList_ShownRowOnly_CopyGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Walk := false;
        Run(Observer);
        Observer.Finish();
    end;

    [PageHandler]
    procedure OrderListHandler(var OrderList: TestPage "TP R7138 Order List")
    var
        Log: Codeunit "TP R7138 Log";
    begin
        Log.Add('handler');
        if not Walk then begin
            Listed := OrderList."No.".Value() + ';';
            exit;
        end;
        if OrderList.First() then
            repeat
                Listed += OrderList."No.".Value() + ';';
            until not OrderList.Next();
    end;
}

codeunit 95985 "TP R7138 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}
