// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72254 is used only by test codeunit 72256; RISKY: array overload
// Facts: Report.CreateTotals(array of Decimal) inside a report

codeunit 72254 "LT P105 TotArrLog"
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

report 72255 "LT P105 TotArrRep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            DataItemTableView = sorting(Id);

            trigger OnPreDataItem()
            begin
                CurrReport.CreateTotals(Sums);
                L.Add('pre');
            end;

            trigger OnAfterGetRecord()
            begin
                Sums[1] += Amount;
                Sums[2] += 1;
                L.Add('row ' + Format(Id) + ' s1=' + Format(Sums[1]) + ' s2=' + Format(Sums[2]) + ' causedby=' + Format(CurrReport.TotalsCausedBy()));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post s1=' + Format(Sums[1]) + ' s2=' + Format(Sums[2]));
            end;
        }
    }

    var
        Sums: array[2] of Decimal;
        L: Codeunit "LT P105 TotArrLog";
}

codeunit 72256 "LT P105 TotArr Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 TotArrLog";
        Helper: Codeunit "LT P105 Helper";

    [Test]
    procedure P105_CreateTotals_Array()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 TotArrRep";
    begin
        Helper.Seed();
        L.Take();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'pre;row 1 s1=10.5 s2=1 causedby=0;row 2 s1=30.5 s2=2 causedby=0;row 3 s1=60.75 s2=3 causedby=0;row 4 s1=55.75 s2=4 causedby=0;post s1=55.75 s2=4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_CreateTotals_Array_RunTwice()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 TotArrRep";
    begin
        Helper.Seed();
        L.Take();
        Rpt.RunModal();
        Observer.Observe('first', L.Take());
        asserterror Rpt.RunModal();
        Observer.ObserveError('af98');
        Observer.Observe('second', L.Take());
        Observer.Expect('first', 'pre;row 1 s1=10.5 s2=1 causedby=0;row 2 s1=30.5 s2=2 causedby=0;row 3 s1=60.75 s2=3 causedby=0;row 4 s1=55.75 s2=4 causedby=0;post s1=55.75 s2=4;');
        Observer.Expect('af98|text', 'The object has been run. Use the function CLEAR(Report).');
        Observer.Expect('af98|code', 'ObjectHasAlreadyBeenRun');
        Observer.Expect('second', '');
        Observer.Verify();
    end;
}
