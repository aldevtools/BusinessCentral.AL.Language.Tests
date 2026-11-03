// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpageview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 94060 - 94067
// Probe (writer Y76, al-runtime-rs assumption view-blank-date-filter): a view whose condition is where(D = filter('')) on a Date field, in every
// place AL allows a view: the RunPageView of an action, the SubPageView of a part, the DataItemTableView of a report, the SourceTableView of an
// XMLport table element and the DataItemTableFilter of a query data item. A top-level page's SourceTableView is pinned by
// pages/lt-cd-testpage-leads/CdTestPageLeads.al SH_SourceTableView_DateFilterBlank_Rows. Rows: 1 and 3 hold a blank date, 2 and 4 a date.
// BC versions: 27, 28, 29

table 94060 "LT Y76 VB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 94061 "LT Y76 VB List"
{
    PageType = List;
    SourceTable = "LT Y76 VB Row";
    ApplicationArea = All;
    Caption = 'Y76 VB List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(DCtl; Rec.D) { ApplicationArea = All; }
                field(InfoCtl; Rec.Info) { ApplicationArea = All; }
            }
        }
    }
}

page 94062 "LT Y76 VB Host"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Y76 VB Host';

    layout
    {
        area(Content)
        {
            part(BlankPart; "LT Y76 VB List")
            {
                ApplicationArea = All;
                SubPageView = where(D = filter(''));
            }
            part(NotBlankPart; "LT Y76 VB List")
            {
                ApplicationArea = All;
                SubPageView = where(D = filter(<> ''));
            }
            part(ConstPart; "LT Y76 VB List")
            {
                ApplicationArea = All;
                SubPageView = where(D = const(0D));
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenBlank)
            {
                ApplicationArea = All;
                RunObject = page "LT Y76 VB List";
                RunPageView = where(D = filter(''));
            }
            action(OpenNotBlank)
            {
                ApplicationArea = All;
                RunObject = page "LT Y76 VB List";
                RunPageView = where(D = filter(<> ''));
            }
            action(OpenConst)
            {
                ApplicationArea = All;
                RunObject = page "LT Y76 VB List";
                RunPageView = where(D = const(0D));
            }
        }
    }
}

codeunit 94066 "LT Y76 VB Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Clear()
    begin
        Text := '';
    end;

    procedure Add(Value: Text)
    begin
        Text += Value + ',';
    end;

    procedure Get(): Text
    begin
        exit(Text);
    end;
}

report 94063 "LT Y76 VB Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT Y76 VB Row")
        {
            DataItemTableView = where(D = filter(''));

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT Y76 VB Log";
            begin
                Log.Add(Rows.Info);
            end;
        }
    }
}

report 94064 "LT Y76 VB Report Not Blank"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT Y76 VB Row")
        {
            DataItemTableView = where(D = filter(<> ''));

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT Y76 VB Log";
            begin
                Log.Add(Rows.Info);
            end;
        }
    }
}

xmlport 94065 "LT Y76 VB Xmlport"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Rows; "LT Y76 VB Row")
            {
                SourceTableView = where(D = filter(''));

                fieldelement(Info; Rows.Info) { }
            }
        }
    }
}

query 94067 "LT Y76 VB Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Rows; "LT Y76 VB Row")
        {
            DataItemTableFilter = D = filter('');

            column(Info; Info) { }
        }
    }
}

codeunit 94068 "LT Y76 VB Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y76 VB Row";
    begin
        Row.DeleteAll();
        AddRow(1, 0D, 'blank1');
        AddRow(2, DMY2Date(1, 2, 2024), 'dated2');
        AddRow(3, 0D, 'blank3');
        AddRow(4, DMY2Date(1, 3, 2024), 'dated4');
    end;

    local procedure AddRow(NewId: Integer; NewD: Date; NewInfo: Text[30])
    var
        Row: Record "LT Y76 VB Row";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.D := NewD;
        Row.Info := NewInfo;
        Row.Insert();
    end;

    local procedure ListRows(var List: TestPage "LT Y76 VB List"): Text
    var
        Result: Text;
    begin
        if List.First() then
            repeat
                if List.InfoCtl.Value() <> '' then
                    Result += List.InfoCtl.Value() + ',';
            until not List.Next();
        exit(Result);
    end;

    [PageHandler]
    procedure ListHandler(var List: TestPage "LT Y76 VB List")
    begin
        Observer.Observe('opened', ListRows(List));
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y76_Action_RunPageView_Blank()
    var
        Host: TestPage "LT Y76 VB Host";
    begin
        Seed();
        Host.OpenView();
        Host.OpenBlank.Invoke();
        Host.Close();
        Observer.Expect('opened', 'blank1,blank3,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y76_Action_RunPageView_NotBlank()
    var
        Host: TestPage "LT Y76 VB Host";
    begin
        Seed();
        Host.OpenView();
        Host.OpenNotBlank.Invoke();
        Host.Close();
        Observer.Expect('opened', 'dated2,dated4,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Y76_Action_RunPageView_Const0D()
    var
        Host: TestPage "LT Y76 VB Host";
    begin
        Seed();
        Host.OpenView();
        Host.OpenConst.Invoke();
        Host.Close();
        Observer.Expect('opened', 'blank1,blank3,');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_Part_SubPageView()
    var
        Host: TestPage "LT Y76 VB Host";
        Result: Text;
    begin
        Seed();
        Host.OpenView();
        if Host.BlankPart.First() then
            repeat
                Result += Host.BlankPart.InfoCtl.Value() + ',';
            until not Host.BlankPart.Next();
        Observer.Observe('blank part', Result);
        Result := '';
        if Host.NotBlankPart.First() then
            repeat
                Result += Host.NotBlankPart.InfoCtl.Value() + ',';
            until not Host.NotBlankPart.Next();
        Observer.Observe('not blank part', Result);
        Result := '';
        if Host.ConstPart.First() then
            repeat
                Result += Host.ConstPart.InfoCtl.Value() + ',';
            until not Host.ConstPart.Next();
        Observer.Observe('const part', Result);
        Host.Close();
        Observer.Expect('blank part', 'blank1,blank3,');
        Observer.Expect('not blank part', 'dated2,dated4,');
        Observer.Expect('const part', 'blank1,blank3,');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_Report_DataItemTableView()
    var
        Log: Codeunit "LT Y76 VB Log";
        BlankReport: Report "LT Y76 VB Report";
        NotBlankReport: Report "LT Y76 VB Report Not Blank";
    begin
        Seed();
        Log.Clear();
        BlankReport.UseRequestPage(false);
        BlankReport.Run();
        Observer.Observe('blank', Log.Get());
        Log.Clear();
        NotBlankReport.UseRequestPage(false);
        NotBlankReport.Run();
        Observer.Observe('not blank', Log.Get());
        Observer.Expect('blank', 'blank1,blank3,');
        Observer.Expect('not blank', 'dated2,dated4,');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_Xmlport_SourceTableView()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
        Line: Text;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT Y76 VB Xmlport", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        Observer.Observe('xml', Xml);
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>|<Root>|  <Rows>|    <Info>blank1</Info>|  </Rows>|  <Rows>|    <Info>blank3</Info>|  </Rows>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure Y76_Query_DataItemTableFilter()
    var
        Q: Query "LT Y76 VB Query";
        Result: Text;
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Result += Q.Info + ',';
        Q.Close();
        Observer.Observe('query', Result);
        Observer.Expect('query', 'blank1,blank3,');
        Observer.Verify();
    end;
}
