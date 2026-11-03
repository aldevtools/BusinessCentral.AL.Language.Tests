// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against BC 29 (observation only; the literals are measured later). Tag P91 (GitHub issue 91).
// BC versions: 29
// Fixtures used: tables and helper of P91Fix.al; SingleInstance log 71599 is used only by test codeunit 71612
// Facts: Report.Run / RunModal / Execute static and on a variable: ids 0 and unknown, Execute with empty, garbage and XML parameters, Run twice, UseRequestPage

codeunit 71599 "LT P91 Run Log"
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

report 71600 "LT P91 RunRep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P91 Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('row pre filter=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;
        }
    }

    trigger OnPreReport()
    begin
        L.Add('pre');
    end;

    trigger OnPostReport()
    begin
        L.Add('post');
    end;

    var
        L: Codeunit "LT P91 Run Log";
}

codeunit 71612 "LT P91 Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P91 Run Log";
        Helper: Codeunit "LT P91 Helper";
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Run_Static_Instance_Modal()
    var
        Rpt: Report "LT P91 RunRep";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P91 RunRep");
        Observer.Observe('static run', L.Take());
        Report.RunModal(Report::"LT P91 RunRep");
        Observer.Observe('static runmodal', L.Take());
        Rpt.Run();
        Observer.Observe('instance run', L.Take());
        Rpt.RunModal();
        Observer.Observe('instance runmodal', L.Take());
        Observer.Expect('static run', 'pre;row pre filter=[];row 1;row 2;row 3;row 4;post;');
        Observer.Expect('static runmodal', 'pre;row pre filter=[];row 1;row 2;row 3;row 4;post;');
        Observer.Expect('instance run', 'pre;row pre filter=[];row 1;row 2;row 3;row 4;post;');
        Observer.Expect('instance runmodal', 'pre;row pre filter=[];row 1;row 2;row 3;row 4;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_WithRecordFilter()
    var
        Row: Record "LT P91 Row";
    begin
        Helper.Seed();
        Row.SetFilter(Id, '2..3');
        L.Take();
        Report.Run(Report::"LT P91 RunRep", false, false, Row);
        Observer.Observe('run filtered', L.Take());
        Report.RunModal(Report::"LT P91 RunRep", false, false, Row);
        Observer.Observe('runmodal filtered', L.Take());
        Observer.Expect('run filtered', 'pre;row pre filter=[2..3];row 2;row 3;post;');
        Observer.Expect('runmodal filtered', 'pre;row pre filter=[2..3];row 2;row 3;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_InvalidIds()
    begin
        asserterror Report.Run(0);
        Observer.ObserveError('run 0');
        asserterror Report.Run(71999);
        Observer.ObserveError('run unknown');
        asserterror Report.Run(-1);
        Observer.ObserveError('run negative');
        asserterror Report.RunModal(0);
        Observer.ObserveError('runmodal 0');
        asserterror Report.RunModal(71999);
        Observer.ObserveError('runmodal unknown');
        Observer.Expect('run 0|text', 'You tried to invoke the Report object with the ID 0 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run 0|code', 'AL:MetadataNotFound');
        Observer.Expect('run unknown|text', 'You tried to invoke the Report object with the ID 71999 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run unknown|code', 'AL:MetadataNotFound');
        Observer.Expect('run negative|text', 'You tried to invoke the Report object with the ID -1 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run negative|code', 'AL:MetadataNotFound');
        Observer.Expect('runmodal 0|text', 'You tried to invoke the Report object with the ID 0 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('runmodal 0|code', 'AL:MetadataNotFound');
        Observer.Expect('runmodal unknown|text', 'You tried to invoke the Report object with the ID 71999 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('runmodal unknown|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_Parameters()
    begin
        Helper.Seed();
        L.Take();
        Report.Execute(Report::"LT P91 RunRep", '');
        Observer.Observe('empty', L.Take());
        Observer.Expect('empty', 'pre;row pre filter=[];row 1;row 2;row 3;row 4;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_InvalidIds()
    begin
        asserterror Report.Execute(0, '');
        Observer.ObserveError('execute 0');
        asserterror Report.Execute(71999, '');
        Observer.ObserveError('execute unknown');
        Observer.Expect('execute 0|text', 'You tried to invoke the Report object with the ID 0 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('execute 0|code', 'AL:MetadataNotFound');
        Observer.Expect('execute unknown|text', 'You tried to invoke the Report object with the ID 71999 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('execute unknown|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_WithRecord()
    var
        Row: Record "LT P91 Row";
    begin
        Helper.Seed();
        Row.SetRange(Grp, 1);
        L.Take();
        Report.Execute(Report::"LT P91 RunRep", '', Row);
        Observer.Observe('with row', L.Take());
        Observer.Expect('with row', 'pre;row pre filter=[];row 1;row 2;post;');
        Observer.Verify();
    end;

    [Test]
    procedure RunRequestPage_NoRequestPage()
    var
        Rpt: Report "LT P91 RunRep";
        Params: Text;
    begin
        Helper.Seed();
        asserterror Params := Rpt.RunRequestPage();
        Observer.ObserveError('af183');
        Observer.Observe('params blank', Format(Params = ''));
        Observer.Expect('af183|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('af183|code', 'DB:Ok');
        Observer.Expect('params blank', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UseRequestPage_Defaults()
    var
        Rpt: Report "LT P91 RunRep";
    begin
        Observer.Observe('default', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(true);
        Observer.Observe('set true', Format(Rpt.UseRequestPage()));
        Rpt.UseRequestPage(false);
        Observer.Observe('set false', Format(Rpt.UseRequestPage()));
        Observer.Expect('default', 'No');
        Observer.Expect('set true', 'Yes');
        Observer.Expect('set false', 'No');
        Observer.Verify();
    end;
}
