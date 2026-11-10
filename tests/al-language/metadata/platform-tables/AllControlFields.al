// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (the table is Scope = Cloud)
// Fixtures used: Probe Observer (codeunit 69160); Base Application page "Customer Card" and table Customer; own tables 62680 62681,
//   pages 62682 62683, page extension 62684, report 62685, test codeunit 62686
// Probe: observe-only. Area: the virtual table "All Control Fields" (2000000202), which lists the controls of pages, report request
//   pages and XMLport request pages from the compiled metadata. TestPageControlFieldVirtualTable.al and its neighbours pin the
//   table "Page Control Field" (2000000192). Not pinned (al-runner issue 7415): which rows a page gives in "All Control Fields"
//   (a field over a record field with and without a TableRelation, over an option, over a variable, over an expression, a field in
//   a repeater, a field a page extension adds, a part, a group, an action), what "Related Table ID" and "Related Field ID" hold,
//   the rows of a ListPart page that is used as a part, the rows of a report request page, a page id that does not exist, and
//   the reported use: a filter on Object Type, Object ID and Related Field ID with IsEmpty, on an own page and on Customer Card.
// Observed: per row Control ID, Control Name, Data Type, Data Type Length, Related Table ID, Related Field ID, Source Expression,
//   Caption, Option String. The table numbers are observed too so that the ids can be read.
// local object: the test asserts the controls of these pages by name and id
// BC versions: 27, 28, 29

table 62680 "MD ACF Ref"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 62681 "MD ACF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Ref Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = "MD ACF Ref";
        }
        field(3; Kind; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = Small,"Very Large";
            OptionCaption = 'Small,Very Large';
        }
        field(4; Amount; Decimal) { DataClassification = SystemMetadata; }
        field(5; Note; Text[40])
        {
            DataClassification = SystemMetadata;
            Caption = 'Note Caption';
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 62682 "MD ACF Lines"
{
    PageType = ListPart;
    SourceTable = "MD ACF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineCode; Rec.Code) { ApplicationArea = All; }
                field(LineRef; Rec."Ref Code") { ApplicationArea = All; }
            }
        }
    }
}

page 62683 "MD ACF Card"
{
    PageType = Card;
    SourceTable = "MD ACF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field("Ref Code"; Rec."Ref Code") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(NoteCtl; Rec.Note)
                {
                    ApplicationArea = All;
                    Caption = 'Control Caption';
                }
                field(VarCtl; SomeText) { ApplicationArea = All; }
                field(ExprCtl; Rec.Amount * 2) { ApplicationArea = All; }
            }
            part(Lines; "MD ACF Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Ref Code" = field("Ref Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DoIt)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        SomeText: Text[20];
}

pageextension 62684 "MD ACF Card Ext" extends "MD ACF Card"
{
    layout
    {
        addlast(General)
        {
            field(ExtRef; Rec."Ref Code") { ApplicationArea = All; }
        }
    }
}

report 62685 "MD ACF Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqCode; ReqRow."Ref Code") { ApplicationArea = All; }
                field(ReqText; ReqText) { ApplicationArea = All; }
            }
        }
    }

    var
        ReqRow: Record "MD ACF Row";
        ReqText: Text[30];
}

codeunit 62686 "MD ACF All Control Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Rows(ObjectType: Option; ObjectId: Integer) Result: Text
    var
        Fields: Record "All Control Fields";
    begin
        Fields.SetRange("Object Type", ObjectType);
        Fields.SetRange("Object ID", ObjectId);
        if Fields.FindSet() then
            repeat
                Result += Format(Fields."Control ID") + ':' + Fields."Control Name" + ':' + Format(Fields."Data Type") + ':' + Format(Fields."Data Type Length") + ':' + Format(Fields."Related Table ID") + ':' + Format(Fields."Related Field ID") + ':' + Fields."Source Expression" + ':' + Fields.Caption + ':' + Fields."Option String" + ' | ';
            until Fields.Next() = 0;
        Result := Format(Fields.Count()) + ' [' + Result + ']';
    end;

    [Test]
    procedure TableNumbers_OfTheFixtures()
    begin
        Observer.Observe('ref table', Format(Database::"MD ACF Ref"));
        Observer.Observe('row table', Format(Database::"MD ACF Row"));
        Observer.Expect('ref table', '62680');
        Observer.Expect('row table', '62681');
        Observer.Verify();
    end;

    [Test]
    procedure Card_RowsOfEveryControl()
    var
        Fields: Record "All Control Fields";
    begin
        Observer.Observe('rows', Rows(Fields."Object Type"::Page, Page::"MD ACF Card"));
        Observer.Expect('rows', '8 [116922656:Amount:12799:0:62681:4:Amount:Amount: | 262320987:ExtRef:31489:10:62681:2:Ref Code:Ref Code: | 470346012:Kind:35583:0:62681:3:Kind:Kind:Small,Very Large | 782389256:ExprCtl:12799:0:0:0:Rec.Amount * 2:: | 991821727:Code:31489:10:62681:1:Code:Code: | 1013851928:Ref Code:31489:10:62681:2:Ref Code:Ref Code: | 1244585919:NoteCtl:31488:40:62681:5:Note:Control Caption: | 1791817698:VarCtl:31488:20:0:0:SomeText:: | ]');
        Observer.Verify();
    end;

    [Test]
    procedure ListPart_RowsOfThePartPage()
    var
        Fields: Record "All Control Fields";
    begin
        Observer.Observe('rows', Rows(Fields."Object Type"::Page, Page::"MD ACF Lines"));
        Observer.Expect('rows', '2 [242228290:LineRef:31489:10:62681:2:Ref Code:Ref Code: | 702177386:LineCode:31489:10:62681:1:Code:Code: | ]');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRequestPage_Rows()
    var
        Fields: Record "All Control Fields";
    begin
        Observer.Observe('as report', Rows(Fields."Object Type"::Report, Report::"MD ACF Report"));
        Observer.Observe('as page', Rows(Fields."Object Type"::Page, Report::"MD ACF Report"));
        Observer.Expect('as report', '10 [1050324297:ReqCode:31489:10:62681:2:ReqRow."Ref Code":Ref Code: | 1801718289:ReqText:31488:30:0:0:ReqText:: | 2000010021::31488:0:0:0:ParameterSet:: | 2000010031::31488:0:0:0:PrinterName:: | 2000010033::31488:0:0:0:ReportTimeout:: | 2000010034::31488:0:0:0:ReportMaxRows:: | 2000010035::31488:0:0:0:ReportMaxDocuments:: | 2000010036::31488:0:0:0:LayoutName:: | 2000010037::31488:0:0:0:ReportFormatRegion:: | 2000010038::31488:0:0:0:LanguageId:: | ]');
        Observer.Expect('as page', '0 []');
        Observer.Verify();
    end;

    [Test]
    procedure MissingPage_NoRows()
    var
        Fields: Record "All Control Fields";
    begin
        Fields.SetRange("Object Type", Fields."Object Type"::Page);
        Fields.SetRange("Object ID", 62699);
        Observer.Observe('empty', Format(Fields.IsEmpty()));
        Observer.Observe('count', Format(Fields.Count()));
        Observer.Observe('findfirst', Format(Fields.FindFirst()));
        Observer.Expect('empty', 'Yes');
        Observer.Expect('count', '0');
        Observer.Expect('findfirst', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RelatedFieldFilter_IsEmpty_OwnCard()
    var
        Fields: Record "All Control Fields";
        Row: Record "MD ACF Row";
        FieldNo: Integer;
        Result: Text;
    begin
        Fields.SetRange("Object Type", Fields."Object Type"::Page);
        Fields.SetRange("Object ID", Page::"MD ACF Card");
        for FieldNo := 1 to 6 do begin
            Fields.SetRange("Related Field ID", FieldNo);
            Result += Format(FieldNo) + '=' + Format(Fields.IsEmpty()) + '/' + Format(Fields.Count()) + ' ';
        end;
        Observer.Observe('empty per field no', Result);
        Fields.SetRange("Related Field ID");
        Fields.SetRange("Related Table ID", Database::"MD ACF Row");
        Observer.Observe('related table = row table', Format(Fields.Count()));
        Fields.SetRange("Related Table ID", Database::"MD ACF Ref");
        Observer.Observe('related table = ref table', Format(Fields.Count()));
        Fields.SetRange("Related Table ID");
        Fields.SetRange("Control Name", 'Kind');
        Observer.Observe('by control name', Format(Fields.Count()));
        Observer.Observe('row field no of Ref Code', Format(Row.FieldNo("Ref Code")));
        Observer.Expect('empty per field no', '1=No/1 2=No/2 3=No/1 4=No/1 5=No/1 6=Yes/0 ');
        Observer.Expect('related table = row table', '6');
        Observer.Expect('related table = ref table', '0');
        Observer.Expect('by control name', '1');
        Observer.Expect('row field no of Ref Code', '2');
        Observer.Verify();
    end;

    [Test]
    procedure RelatedFieldFilter_IsEmpty_CustomerCard()
    var
        Fields: Record "All Control Fields";
        Customer: Record Customer;
    begin
        Fields.SetRange("Object Type", Fields."Object Type"::Page);
        Fields.SetRange("Object ID", Page::"Customer Card");
        Observer.Observe('any row', Format(not Fields.IsEmpty()));
        Fields.SetRange("Related Field ID", Customer.FieldNo("Primary Contact No."));
        Observer.Observe('Primary Contact No. empty', Format(Fields.IsEmpty()));
        Fields.SetRange("Related Field ID", Customer.FieldNo("No."));
        Observer.Observe('No. empty', Format(Fields.IsEmpty()));
        Fields.SetRange("Related Field ID", 1999999);
        Observer.Observe('unknown field empty', Format(Fields.IsEmpty()));
        Observer.Expect('any row', 'Yes');
        Observer.Expect('Primary Contact No. empty', 'No');
        Observer.Expect('No. empty', 'No');
        Observer.Expect('unknown field empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Get_ByObjectAndControl()
    var
        Fields: Record "All Control Fields";
        First: Record "All Control Fields";
    begin
        First.SetRange("Object Type", First."Object Type"::Page);
        First.SetRange("Object ID", Page::"MD ACF Card");
        First.FindFirst();
        Observer.Observe('get', Format(Fields.Get(First."Object Type", First."Object ID", First."Control ID")));
        Observer.Observe('key', Fields.CurrentKey());
        Observer.Observe('position', Fields.GetPosition());
        Observer.Expect('get', 'Yes');
        Observer.Expect('key', 'Object Type,Object ID,Control ID');
        Observer.Expect('position', 'Object Type=CONST(Page),Object ID=CONST(62683),Control ID=CONST(116922656)');
        Observer.Verify();
    end;
}
