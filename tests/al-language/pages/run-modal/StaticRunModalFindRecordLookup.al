// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-integer-table-fieldref-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 95662, list page 95663 (its LookupPageId), SingleInstance log 95664 (used only by test
//   codeunit 95665)
// Probe (al-runner issue 6992): the static Page.RunModal(0, Rec) and Page.RunModal(Page::"..", Rec) of a list page that serves its rows
//   from OnFindRecord/OnNextRecord (the shape of Base Application's "Item Variants"), with a record that is filtered (FilterGroup 2) but not
//   positioned, and with one positioned on a row. A ModalPageHandler goes to the first row and presses OK (or Cancel). Logged: the Which and
//   result of each OnFindRecord (F:), the Steps of each OnNextRecord (N:), each OnAfterGetRecord (R:), the handler (H:); then the action
//   RunModal returns and the record's row afterwards.
// local object: the list page's OnFindRecord trigger is under test; the log must be owned by one test codeunit
// BC versions: 27-29

table 95662 "LT SRF Row"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT SRF List";

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Grp; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 95663 "LT SRF List"
{
    PageType = List;
    SourceTable = "LT SRF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT SRF Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT SRF Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT SRF Log";
    begin
        Log.Add('R:' + Rec.Code);
    end;
}

codeunit 95664 "LT SRF Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Dump(): Text
    begin
        exit(Lines);
    end;
}

codeunit 95665 "LT SRF Tests"
{
    Subtype = Test;

    var
        Log: Codeunit "LT SRF Log";

    local procedure Start()
    var
        Row: Record "LT SRF Row";
    begin
        Row.DeleteAll();
        AddRow('V1', 'X');
        AddRow('V2', 'G');
        AddRow('V3', 'G');
        AddRow('V4', 'G');
        Log.Reset();
    end;

    local procedure AddRow(Code: Code[10]; Grp: Code[10])
    var
        Row: Record "LT SRF Row";
    begin
        Row.Code := Code;
        Row.Grp := Grp;
        Row.Insert();
    end;

    local procedure Filtered(var Row: Record "LT SRF Row")
    begin
        Row.FilterGroup(2);
        Row.SetRange(Grp, 'G');
        Row.FilterGroup(0);
    end;

    [Test]
    [HandlerFunctions('FirstOkHandler')]
    procedure StaticRunModalZero_FilteredNotPositioned_FirstThenOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SRF Row";
    begin
        Start();
        Filtered(Row);
        Observer.Observe('action', Format(Page.RunModal(0, Row)));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('selected', Row.Code);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('FirstOkHandler')]
    procedure StaticRunModalPageId_FilteredNotPositioned_FirstThenOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SRF Row";
    begin
        Start();
        Filtered(Row);
        Observer.Observe('action', Format(Page.RunModal(Page::"LT SRF List", Row)));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('selected', Row.Code);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('FirstOkHandler')]
    procedure StaticRunModalZero_FilteredOnRow_FirstThenOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SRF Row";
    begin
        Start();
        Filtered(Row);
        Row.Get('V3');
        Observer.Observe('action', Format(Page.RunModal(0, Row)));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('selected', Row.Code);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('FirstOkHandler')]
    procedure StaticRunModalZero_NoFilterNotPositioned_FirstThenOK()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SRF Row";
    begin
        Start();
        Observer.Observe('action', Format(Page.RunModal(0, Row)));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('selected', Row.Code);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure StaticRunModalZero_FilteredNotPositioned_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SRF Row";
    begin
        Start();
        Filtered(Row);
        Observer.Observe('action', Format(Page.RunModal(0, Row)));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('selected', Row.Code);
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure FirstOkHandler(var P: TestPage "LT SRF List")
    begin
        Log.Add('H:opened=' + P.CodeCtl.Value());
        P.First();
        Log.Add('H:first=' + P.CodeCtl.Value());
        P.OK().Invoke();
        Log.Add('H:ok');
    end;

    [ModalPageHandler]
    procedure CancelHandler(var P: TestPage "LT SRF List")
    begin
        Log.Add('H:opened=' + P.CodeCtl.Value());
        P.Cancel().Invoke();
        Log.Add('H:cancel');
    end;
}
