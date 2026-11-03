// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72270 is used only by test codeunit 72272; RISKY: the ShowOutput(Boolean) call form
// Facts: Report.ShowOutput(Boolean) set inside a report (OnPreDataItem, OnAfterGetRecord) and read back with ShowOutput(); initial value; set back to true

codeunit 72270 "LT P105 ShowLog"
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

report 72271 "LT P105 ShowRep"
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
                L.Add('pre initial=' + Format(CurrReport.ShowOutput()));
                case Mode of
                    1:
                        CurrReport.ShowOutput(false);
                    2:
                        CurrReport.ShowOutput(true);
                end;
                L.Add('pre after=' + Format(CurrReport.ShowOutput()));
            end;

            trigger OnAfterGetRecord()
            begin
                if Mode = 3 then
                    if Id = 2 then
                        CurrReport.ShowOutput(false);
                L.Add('row ' + Format(Id) + ' show=' + Format(CurrReport.ShowOutput()));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post show=' + Format(CurrReport.ShowOutput()));
            end;
        }
    }

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    var
        Mode: Integer;
        L: Codeunit "LT P105 ShowLog";
}

codeunit 72272 "LT P105 Show Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 ShowLog";
        Helper: Codeunit "LT P105 Helper";

    local procedure RunMode(Mode: Integer): Text
    var
        Rpt: Report "LT P105 ShowRep";
    begin
        Helper.Seed();
        L.Take();
        Rpt.SetMode(Mode);
        Rpt.RunModal();
        exit(L.Take());
    end;

    [Test]
    procedure P105_ShowOutput_Untouched()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(0));
        Observer.Expect('log', 'pre initial=No;pre after=No;row 1 show=No;row 2 show=No;row 3 show=No;row 4 show=No;post show=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_ShowOutput_SetFalseInPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(1));
        Observer.Expect('log', 'pre initial=No;pre after=No;row 1 show=No;row 2 show=No;row 3 show=No;row 4 show=No;post show=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_ShowOutput_SetTrueInPreDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(2));
        Observer.Expect('log', 'pre initial=No;pre after=No;row 1 show=No;row 2 show=No;row 3 show=No;row 4 show=No;post show=No;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_ShowOutput_SetFalseInSecondRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(3));
        Observer.Expect('log', 'pre initial=No;pre after=No;row 1 show=No;row 2 show=No;row 3 show=No;row 4 show=No;post show=No;');
        Observer.Verify();
    end;
}
