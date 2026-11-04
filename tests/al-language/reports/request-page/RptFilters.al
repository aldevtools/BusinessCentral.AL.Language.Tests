// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-dataitem-properties
// Scope: in-scope
// Fixtures used: tables and helper of RptFixtures.al; SingleInstance log 73830 is used only by test codeunit 73838; reports 84654-84655 (writer CJ, corpus issue 667 item 154)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Data item filters: DataItemTableView (where, sorting), SetTableView, RequestFilterFields on the request page, DataItemLink,
// ReqFilterFields observed through GetFilter and the parameters text, PrintOnlyIfDetail seen in the dataset of SaveAs Xml.
// Writer QP (al-runtime-rs ask, Microsoft's Customer "Currency Filter" shape): report 87147 links its child to a FlowFilter field of the
//   parent, DataItemLink = "Currency Code" = field("Currency Filter") (tables 87145, 87146). The parent has no filter on the FlowFilter,
//   a single value, a range and an or-filter (set through SetTableView); the log shows the child's filter in OnPreDataItem and the child rows
//   read in OnAfterGetRecord. QP_ tests in codeunit 73838.
// BC versions: 29 (27 and 28 by CI)

codeunit 73830 "LT RpT Filter Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 73831 "LT RpT TableView"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            DataItemTableView = sorting(Grp, Id) order(descending) where(Grp = filter(1 | 2));

            trigger OnPreDataItem()
            begin
                L.Add('pre filter=[' + Row.GetFilters() + '] key=[' + Row.CurrentKey() + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('get ' + Format(Row.Id));
            end;
        }
    }

    var
        L: Codeunit "LT RpT Filter Log";
}

report 73832 "LT RpT ReqFilters"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            RequestFilterFields = Grp, Id;
            RequestFilterHeading = 'Rows';
            DataItemTableView = sorting(Id);

            trigger OnPreDataItem()
            begin
                L.Add('pre filters=[' + Row.GetFilters() + '] grp=[' + Row.GetFilter(Grp) + '] id=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('get ' + Format(Row.Id));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; NoteVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        NoteVal: Text[30];
        L: Codeunit "LT RpT Filter Log";
}

report 73833 "LT RpT PrintOnlyIfDetail"
{
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            PrintOnlyIfDetail = true;

            column(RowId; Row.Id) { }

            dataitem(Child; "LT RpT Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ChildId; Child.Id) { }
            }
        }
    }
}

report 73834 "LT RpT NoPrintOnlyIfDetail"
{
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            column(RowId; Row.Id) { }

            dataitem(Child; "LT RpT Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ChildId; Child.Id) { }
            }
        }
    }
}

report 73835 "LT RpT Link"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            dataitem(Child; "LT RpT Child")
            {
                DataItemLink = ParentId = field(Id);
                DataItemTableView = sorting(Id) order(descending);

                trigger OnPreDataItem()
                begin
                    L.Add('child pre filter=[' + Child.GetFilter(ParentId) + '] of ' + Format(Row.Id));
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('child ' + Format(Child.Id));
                end;
            }
        }
    }

    var
        L: Codeunit "LT RpT Filter Log";
}

report 73836 "LT RpT Bare"
{
    ProcessingOnly = true;
    UseRequestPage = false;
}

report 84654 "LT CJ RpT Leaf PrintOnly"
{
    // Corpus issue 667, item 154: PrintOnlyIfDetail on a data item that has no child data item.
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            PrintOnlyIfDetail = true;

            column(RowId; Row.Id) { }
        }
    }
}

report 84655 "LT CJ RpT Leaf Child PrintOnly"
{
    // Corpus issue 667, item 154: PrintOnlyIfDetail on the leaf (child) data item of a parent/child dataset.
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT RpT Row")
        {
            column(RowId; Row.Id) { }

            dataitem(Child; "LT RpT Child")
            {
                DataItemLink = ParentId = field(Id);
                PrintOnlyIfDetail = true;

                column(ChildId; Child.Id) { }
            }
        }
    }
}

table 87145 "LT QP RpT FF Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Currency Filter"; Code[10]) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 87146 "LT QP RpT FF Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Currency Code"; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 87147 "LT QP RpT FF Link"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Head; "LT QP RpT FF Head")
        {
            dataitem(Line; "LT QP RpT FF Line")
            {
                DataItemLink = "Currency Code" = field("Currency Filter");

                trigger OnPreDataItem()
                begin
                    L.Add('line pre filter=[' + Line.GetFilter("Currency Code") + ']');
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('line ' + Format(Line.Id) + ' ' + Line."Currency Code");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                L.Add('head ' + Format(Head.Id) + ' ff=[' + Head.GetFilter("Currency Filter") + '] value=[' + Head."Currency Filter" + ']');
            end;
        }
    }

    var
        L: Codeunit "LT RpT Filter Log";
}

codeunit 73838 "LT RpT Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT RpT Filter Log";
        Helper: Codeunit "LT RpT Helper";

    local procedure Seed()
    var
        Row: Record "LT RpT Row";
        Child: Record "LT RpT Child";
        I: Integer;
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        L.Take();
        for I := 1 to 4 do begin
            Row.Id := I;
            Row.Grp := (I + 1) div 2;
            Row.Name := 'Row' + Format(I);
            Row.Insert();
        end;
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Insert();
        Child.Id := 11;
        Child.ParentId := 1;
        Child.Insert();
        Child.Id := 12;
        Child.ParentId := 3;
        Child.Insert();
        Commit();
    end;

    [Test]
    procedure DataItemTableView_WhereAndSorting()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT TableView");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre filter=[] key=[Grp,Id];get 4;get 3;get 2;get 1;');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_AddsToDataItemTableView()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT TableView";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Id, 2, 4);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre filter=[Id: 2..4] key=[Grp,Id];get 4;get 3;get 2;');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_SameFieldAsTableView()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT TableView";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Grp, 2);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre filter=[Grp: 2] key=[Grp,Id];get 4;get 3;');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_OtherKey()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT TableView";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetCurrentKey(Name);
        Row.SetRange(Id, 1, 3);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre filter=[Id: 1..3] key=[Grp,Id];get 3;get 2;get 1;');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_CalledTwice_LastWins()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT TableView";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Id, 1);
        Rpt.SetTableView(Row);
        Row.SetRange(Id, 2);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre filter=[Id: 2] key=[Grp,Id];get 2;');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_WrongTable_Error()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT TableView";
        Child: Record "LT RpT Child";
    begin
        Seed();
        asserterror Rpt.SetTableView(Child);
        Observer.ObserveError('wrong table');
        Observer.Expect('wrong table|text', 'The LT RpT TableView report does not have a DataItem that uses the table (Table 73807 LT RpT Child) specified in the function SetTableView.');
        Observer.Expect('wrong table|code', 'ReportNoDataItem');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableView_NoDataItemInReport()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Bare";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Id, 1);
        asserterror Rpt.SetTableView(Row);
        Observer.ObserveError('no data item');
        Observer.Expect('no data item|text', 'The LT RpT Bare report does not have a DataItem that uses the table (Table 73806 LT RpT Row) specified in the function SetTableView.');
        Observer.Expect('no data item|code', 'ReportNoDataItem');
        Observer.Verify();
    end;

    [Test]
    procedure DataItemLink_ChildFilterAndOrder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Link");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'child pre filter=[] of 1;child 11;child 10;child pre filter=[] of 2;child pre filter=[] of 3;child 12;child pre filter=[] of 4;');
        Observer.Verify();
    end;

    [Test]
    procedure PrintOnlyIfDetail_Dataset()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Helper.Save(Report::"LT RpT PrintOnlyIfDetail", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('RowId', Helper.Values(Xml, 'RowId'));
        Observer.Observe('ChildId', Helper.Values(Xml, 'ChildId'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('RowId', '1,3,');
        Observer.Expect('ChildId', '10,11,12,');
        Observer.Verify();
    end;

    [Test]
    procedure NoPrintOnlyIfDetail_Dataset()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Helper.Save(Report::"LT RpT NoPrintOnlyIfDetail", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('RowId', Helper.Values(Xml, 'RowId'));
        Observer.Observe('ChildId', Helper.Values(Xml, 'ChildId'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('RowId', '1,2,3,4,');
        Observer.Expect('ChildId', '10,11,12,');
        Observer.Verify();
    end;

    [Test]
    procedure PrintOnlyIfDetail_NoChildren_EmptyDataset()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT RpT Child";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Child.DeleteAll();
        Commit();
        Ok := Helper.Save(Report::"LT RpT PrintOnlyIfDetail", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('RowId', Helper.Values(Xml, 'RowId'));
        Observer.Observe('ChildId', Helper.Values(Xml, 'ChildId'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('RowId', '');
        Observer.Expect('ChildId', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReqFiltersOk')]
    procedure RequestFilterFields_Handler_SetsFilters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT ReqFilters");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'handler grp=[] id=[];handler after grp=[2] id=[>=3];pre filters=[Id: >=3, Grp: 2] grp=[2] id=[>=3];get 3;get 4;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ReqFiltersOk(var RP: TestRequestPage "LT RpT ReqFilters")
    begin
        L.Add('handler grp=[' + RP.Row.GetFilter(Grp) + '] id=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Grp, '2');
        RP.Row.SetFilter(Id, '>=3');
        L.Add('handler after grp=[' + RP.Row.GetFilter(Grp) + '] id=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ReqFiltersNone')]
    procedure RequestFilterFields_Handler_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT ReqFilters");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre filters=[] grp=[] id=[];get 1;get 2;get 3;get 4;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ReqFiltersNone(var RP: TestRequestPage "LT RpT ReqFilters")
    begin
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ReqFiltersRunRequestPage')]
    procedure RequestFilterFields_ParametersText()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT RpT ReqFilters");
        Observer.Observe('dataitems', Helper.Between(Params, '<DataItems>', '</DataItems>'));
        Observer.Observe('options', Helper.Between(Params, '<Options>', '</Options>'));
        Observer.Observe('log', L.Take());
        Observer.Expect('dataitems', '<DataItem name="Row">VERSION(1) SORTING(Field1) WHERE(Field2=1(1..2))</DataItem>');
        Observer.Expect('options', '<Field name="NoteVal">abc</Field>');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ReqFiltersRunRequestPage(var RP: TestRequestPage "LT RpT ReqFilters")
    begin
        RP.Row.SetFilter(Grp, '1..2');
        RP.NoteCtl.SetValue('abc');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ReqFiltersRunRequestPage')]
    procedure RequestFilterFields_ParametersText_ThenExecute()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT RpT ReqFilters");
        L.Take();
        Report.Execute(Report::"LT RpT ReqFilters", Params);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre filters=[Grp: 1..2] grp=[1..2] id=[];get 1;get 2;get 3;get 4;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReqFiltersOk')]
    procedure SetTableView_AndRequestFilter_Combined()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT ReqFilters";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Id, 1, 3);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'handler grp=[] id=[1..3];handler after grp=[2] id=[1..3];pre filters=[Id: >=3, Grp: 2] grp=[2] id=[>=3];get 3;get 4;');
        Observer.Verify();
    end;

    [Test]
    procedure CJ_PrintOnlyIfDetail_LeafDataItem_Dataset()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Helper.Save(Report::"LT CJ RpT Leaf PrintOnly", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('RowId', Helper.Values(Xml, 'RowId'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('RowId', '');
        Observer.Verify();
    end;

    [Test]
    procedure CJ_PrintOnlyIfDetail_LeafChildDataItem_Dataset()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Helper.Save(Report::"LT CJ RpT Leaf Child PrintOnly", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('RowId', Helper.Values(Xml, 'RowId'));
        Observer.Observe('ChildId', Helper.Values(Xml, 'ChildId'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('RowId', '1,2,3,4,');
        Observer.Expect('ChildId', '');
        Observer.Verify();
    end;

    local procedure QP_SeedFlowFilterLink()
    var
        Head: Record "LT QP RpT FF Head";
        Line: Record "LT QP RpT FF Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        L.Take();
        Head.Id := 1;
        Head.Insert();
        Line.Id := 1;
        Line."Currency Code" := '';
        Line.Insert();
        Line.Id := 2;
        Line."Currency Code" := 'EUR';
        Line.Insert();
        Line.Id := 3;
        Line."Currency Code" := 'USD';
        Line.Insert();
        Line.Id := 4;
        Line."Currency Code" := 'GBP';
        Line.Insert();
        Commit();
    end;

    local procedure QP_RunFlowFilterLink(FilterText: Text; SetIt: Boolean): Text
    var
        Head: Record "LT QP RpT FF Head";
        Rpt: Report "LT QP RpT FF Link";
    begin
        QP_SeedFlowFilterLink();
        if SetIt then
            Head.SetFilter("Currency Filter", FilterText);
        Rpt.SetTableView(Head);
        Rpt.Run();
        exit(L.Take());
    end;

    [Test]
    procedure QP_DataItemLink_FlowFilter_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', QP_RunFlowFilterLink('', false));
        Observer.Expect('log', 'head 1 ff=[] value=[];line pre filter=[];line 1 ;line 2 EUR;line 3 USD;line 4 GBP;');
        Observer.Verify();
    end;

    [Test]
    procedure QP_DataItemLink_FlowFilter_SingleValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', QP_RunFlowFilterLink('EUR', true));
        Observer.Expect('log', 'head 1 ff=[EUR] value=[];line pre filter=[];line 2 EUR;');
        Observer.Verify();
    end;

    [Test]
    procedure QP_DataItemLink_FlowFilter_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', QP_RunFlowFilterLink('E..G', true));
        Observer.Expect('log', 'head 1 ff=[E..G] value=[];line pre filter=[];line 2 EUR;');
        Observer.Verify();
    end;

    [Test]
    procedure QP_DataItemLink_FlowFilter_OrFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', QP_RunFlowFilterLink('EUR|USD', true));
        Observer.Expect('log', 'head 1 ff=[EUR|USD] value=[];line pre filter=[];line 2 EUR;line 3 USD;');
        Observer.Verify();
    end;

    [Test]
    procedure QP_DataItemLink_FlowFilter_ReportRunPlain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QP_SeedFlowFilterLink();
        Report.Run(Report::"LT QP RpT FF Link");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'head 1 ff=[] value=[];line pre filter=[];line 1 ;line 2 EUR;line 3 USD;line 4 GBP;');
        Observer.Verify();
    end;
}
