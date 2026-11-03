// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures used: tables and helper of RptFixtures.al; SingleInstance log 73810 is used only by test codeunit 73813
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Order of the report and data item triggers (OnInitReport, OnPreReport, OnPreDataItem, OnAfterGetRecord, OnPostDataItem, OnPostReport),
// nested and sibling data items, empty tables, and Report.Execute / Report.SaveAs / Report.Run with UseRequestPage = false.
// BC versions: 29 (27 and 28 by CI)

codeunit 73810 "LT RpT Order Log"
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

report 73811 "LT RpT Order"
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

                trigger OnPreDataItem()
                begin
                    L.Add('Child pre of ' + Format(Row.Id));
                end;

                trigger OnAfterGetRecord()
                begin
                    L.Add('Child get ' + Format(Child.Id));
                end;

                trigger OnPostDataItem()
                begin
                    L.Add('Child post of ' + Format(Row.Id));
                end;
            }

            trigger OnPreDataItem()
            begin
                L.Add('Row pre count=' + Format(Row.Count()));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('Row get ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('Row post');
            end;

        }
    }

    trigger OnInitReport()
    begin
        L.Add('InitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('PreReport');
    end;

    trigger OnPostReport()
    begin
        L.Add('PostReport');
    end;

    var
        L: Codeunit "LT RpT Order Log";
}

report 73812 "LT RpT Siblings"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(First; "LT RpT Row")
        {
            DataItemTableView = where(Grp = const(1));

            trigger OnPreDataItem()
            begin
                L.Add('First pre');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('First get ' + Format(First.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('First post');
            end;
        }
        dataitem(Second; "LT RpT Row")
        {
            DataItemTableView = where(Grp = const(2));

            trigger OnPreDataItem()
            begin
                L.Add('Second pre');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('Second get ' + Format(Second.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('Second post');
            end;
        }
    }

    trigger OnInitReport()
    begin
        L.Add('InitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('PreReport');
    end;

    trigger OnPostReport()
    begin
        L.Add('PostReport');
    end;

    var
        L: Codeunit "LT RpT Order Log";
}

report 73814 "LT RpT NoItems"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnInitReport()
    begin
        L.Add('InitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('PreReport');
    end;

    trigger OnPostReport()
    begin
        L.Add('PostReport');
    end;

    var
        L: Codeunit "LT RpT Order Log";
}

codeunit 73813 "LT RpT Trigger Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT RpT Order Log";
        Helper: Codeunit "LT RpT Helper";

    local procedure Seed()
    var
        Row: Record "LT RpT Row";
        Child: Record "LT RpT Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        L.Take();
        Row.Id := 1;
        Row.Grp := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Grp := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Grp := 1;
        Row.Insert();
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

    local procedure ClearAll()
    var
        Row: Record "LT RpT Row";
        Child: Record "LT RpT Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        L.Take();
        Commit();
    end;

    [Test]
    procedure Run_NestedItems_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Order");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;Row pre count=3;Row get 1;Child pre of 1;Child get 10;Child get 11;Child post of 1;Row get 2;Child pre of 2;Child post of 2;Row get 3;Child pre of 3;Child get 12;Child post of 3;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_EmptyTables_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearAll();
        Report.Run(Report::"LT RpT Order");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;Row pre count=0;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_Siblings_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT Siblings");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;First pre;First get 1;First get 3;First post;Second pre;Second get 2;Second post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_NoDataItems_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"LT RpT NoItems");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_NestedItems_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Execute(Report::"LT RpT Order", '');
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;Row pre count=3;Row get 1;Child pre of 1;Child get 10;Child get 11;Child post of 1;Row get 2;Child pre of 2;Child post of 2;Row get 3;Child pre of 3;Child get 12;Child post of 3;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NestedItems_Order()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Helper.Save(Report::"LT RpT Order", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'No');
        Observer.Expect('log', 'InitReport;');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Siblings_Order()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Helper.Save(Report::"LT RpT Siblings", '', Xml);
        Observer.Observe('saved', Format(Ok));
        Observer.Observe('log', L.Take());
        Observer.Expect('saved', 'No');
        Observer.Expect('log', 'InitReport;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableRun_Order()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Order";
    begin
        Seed();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;Row pre count=3;Row get 1;Child pre of 1;Child get 10;Child get 11;Child post of 1;Row get 2;Child pre of 2;Child post of 2;Row get 3;Child pre of 3;Child get 12;Child post of 3;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableRun_Twice_InitReportEachTime()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Siblings";
    begin
        Seed();
        Rpt.Run();
        Observer.Observe('first', L.Take());
        Rpt.Run();
        Observer.Observe('second', L.Take());
        Observer.Expect('first', 'InitReport;PreReport;First pre;First get 1;First get 3;First post;Second pre;Second get 2;Second post;PostReport;');
        Observer.Expect('second', 'InitReport;PreReport;First pre;First get 1;First get 3;First post;Second pre;Second get 2;Second post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableRunModal_UseRequestPageFalse_Order()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Siblings";
    begin
        Seed();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;First pre;First get 1;First get 3;First post;Second pre;Second get 2;Second post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure VariableExecute_Order()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Siblings";
    begin
        Seed();
        Rpt.Execute('');
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;First pre;First get 1;First get 3;First post;Second pre;Second get 2;Second post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure RunRequestPage_UseRequestPageFalse_NoPage()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Order";
        Params: Text;
    begin
        Seed();
        asserterror Params := Rpt.RunRequestPage();
        Observer.ObserveError('af377');
        Observer.Observe('log', L.Take());
        Observer.Observe('params empty', Format(Params = ''));
        Observer.Observe('has options', Format(Params.Contains('<Options>')));
        Observer.Observe('has dataitems', Format(Params.Contains('<DataItems>')));
        Observer.Expect('af377|text', 'Unhandled UI: RequestPage 73811');
        Observer.Expect('af377|code', 'MissingUIHandler');
        Observer.Expect('log', 'InitReport;');
        Observer.Expect('params empty', 'Yes');
        Observer.Expect('has options', 'No');
        Observer.Expect('has dataitems', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Run_SetTableView_Order()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Order";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Grp, 1);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;Row pre count=2;Row get 1;Child pre of 1;Child get 10;Child get 11;Child post of 1;Row get 3;Child pre of 3;Child get 12;Child post of 3;Row post;PostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_SetTableView_NoMatch_Order()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT RpT Order";
        Row: Record "LT RpT Row";
    begin
        Seed();
        Row.SetRange(Grp, 99);
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'InitReport;PreReport;Row pre count=0;Row post;PostReport;');
        Observer.Verify();
    end;
}
