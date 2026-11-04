// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72251 is used only by test codeunit 72253
// Facts: Report.CreateTotals(var Decimal, ...) with one, two and a record field argument inside a report; TotalsCausedBy and the running sums seen in OnAfterGetRecord / OnPostDataItem

codeunit 72251 "LT P105 TotLog"
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

report 72252 "LT P105 TotRep"
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
                case Mode of
                    1:
                        CurrReport.CreateTotals(Sum1);
                    2:
                        CurrReport.CreateTotals(Sum1, Sum2);
                    3:
                        CurrReport.CreateTotals(Row.Amount);
                    4:
                        CurrReport.CreateTotals(Row.Amount, Sum1, Sum2);
                end;
                L.Add('pre mode=' + Format(Mode));
            end;

            trigger OnAfterGetRecord()
            begin
                Sum1 += Amount;
                Sum2 += 1;
                L.Add('row ' + Format(Id) + ' sum1=' + Format(Sum1) + ' sum2=' + Format(Sum2) + ' causedby=' + Format(CurrReport.TotalsCausedBy()));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post sum1=' + Format(Sum1) + ' sum2=' + Format(Sum2));
            end;
        }
    }

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        Sum1 := 0;
        Sum2 := 0;
    end;

    var
        Mode: Integer;
        Sum1: Decimal;
        Sum2: Decimal;
        L: Codeunit "LT P105 TotLog";
}

codeunit 72253 "LT P105 Tot Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 TotLog";
        Helper: Codeunit "LT P105 Helper";

    local procedure RunMode(Mode: Integer): Text
    var
        Rpt: Report "LT P105 TotRep";
    begin
        Helper.Seed();
        L.Take();
        Rpt.SetMode(Mode);
        Rpt.RunModal();
        exit(L.Take());
    end;

    [Test]
    procedure P105_CreateTotals_NoCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(0));
        Observer.Expect('log', 'pre mode=0;row 1 sum1=10.5 sum2=1 causedby=0;row 2 sum1=30.5 sum2=2 causedby=0;row 3 sum1=60.75 sum2=3 causedby=0;row 4 sum1=55.75 sum2=4 causedby=0;post sum1=55.75 sum2=4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_CreateTotals_OneVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(1));
        Observer.Expect('log', 'pre mode=1;row 1 sum1=10.5 sum2=1 causedby=0;row 2 sum1=30.5 sum2=2 causedby=0;row 3 sum1=60.75 sum2=3 causedby=0;row 4 sum1=55.75 sum2=4 causedby=0;post sum1=55.75 sum2=4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_CreateTotals_TwoVariables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(2));
        Observer.Expect('log', 'pre mode=2;row 1 sum1=10.5 sum2=1 causedby=0;row 2 sum1=30.5 sum2=2 causedby=0;row 3 sum1=60.75 sum2=3 causedby=0;row 4 sum1=55.75 sum2=4 causedby=0;post sum1=55.75 sum2=4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_CreateTotals_RecordField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(3));
        Observer.Expect('log', 'pre mode=3;row 1 sum1=10.5 sum2=1 causedby=0;row 2 sum1=30.5 sum2=2 causedby=0;row 3 sum1=60.75 sum2=3 causedby=0;row 4 sum1=55.75 sum2=4 causedby=0;post sum1=55.75 sum2=4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_CreateTotals_FieldAndVariables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(4));
        Observer.Expect('log', 'pre mode=4;row 1 sum1=10.5 sum2=1 causedby=0;row 2 sum1=30.5 sum2=2 causedby=0;row 3 sum1=60.75 sum2=3 causedby=0;row 4 sum1=55.75 sum2=4 causedby=0;post sum1=55.75 sum2=4;');
        Observer.Verify();
    end;
}
