// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72267 is used only by test codeunit 72269; RISKY: PaperSource may not compile on the Cloud target
// Facts: Report.PaperSource(bin) and PaperSource(bin, page) called inside a report (they only matter for printing: observed is that the report keeps running)

codeunit 72267 "LT P105 PaperLog"
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

report 72268 "LT P105 PaperRep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            trigger OnPreDataItem()
            begin
                case Mode of
                    1:
                        CurrReport.PaperSource(1);
                    2:
                        CurrReport.PaperSource(2, 1);
                    3:
                        CurrReport.PaperSource(0);
                    4:
                        CurrReport.PaperSource(-1);
                end;
                L.Add('pre mode=' + Format(Mode));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Id));
            end;
        }
    }

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    var
        Mode: Integer;
        L: Codeunit "LT P105 PaperLog";
}

codeunit 72269 "LT P105 Paper Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 PaperLog";
        Helper: Codeunit "LT P105 Helper";

    local procedure RunMode(Mode: Integer): Text
    var
        Rpt: Report "LT P105 PaperRep";
    begin
        Helper.Seed();
        L.Take();
        Rpt.SetMode(Mode);
        Rpt.RunModal();
        exit(L.Take());
    end;

    [Test]
    procedure P105_PaperSource_BinOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(1));
        Observer.Expect('log', 'pre mode=1;row 1;row 2;row 3;row 4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_PaperSource_BinAndPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(2));
        Observer.Expect('log', 'pre mode=2;row 1;row 2;row 3;row 4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_PaperSource_Zero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(3));
        Observer.Expect('log', 'pre mode=3;row 1;row 2;row 3;row 4;');
        Observer.Verify();
    end;

    [Test]
    procedure P105_PaperSource_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log', RunMode(4));
        Observer.Expect('log', 'pre mode=4;row 1;row 2;row 3;row 4;');
        Observer.Verify();
    end;
}
