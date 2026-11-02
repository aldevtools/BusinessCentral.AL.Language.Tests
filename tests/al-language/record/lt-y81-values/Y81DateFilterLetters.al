// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94250, test codeunit 94251
// Probe (writer Y81): the date filter letters Y and T-1D (and the neighbours T, T+1D, W, Q, M, D, with and without ranges) set with Record.SetFilter, each
// under work dates in, before and after the year of Today(). The answer is the filter text and the range ends, with Today() and the work date kept
// out of the literals: every expectation is computed from Today() and the work date in the test.
// Pinned elsewhere: record/lt-date-filter-letters-workdates/DateFilterLettersWorkDates.al (evaluates Y and T-1D but ignores their values).
// BC versions: 27, 28, 29

table 94250 "LT Y81 DF"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; D; Date) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 94251 "LT Y81 Date Filter Letters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryFilter(var Row: Record "LT Y81 DF"; Txt: Text)
    begin
        Row.SetFilter(D, Txt);
    end;

    local procedure Apply(Txt: Text): Text
    var
        Row: Record "LT Y81 DF";
    begin
        ClearLastError();
        if TryFilter(Row, Txt) then
            exit('ok|' + Row.GetFilter(D) + '|' + Format(Row.GetRangeMin(D), 0, 9) + '|' + Format(Row.GetRangeMax(D), 0, 9));
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Letters(WorkDay: Date; Part: Integer)
    var
        Saved: Date;
        Prefix: Text;
        Texts: List of [Text];
        Txt: Text;
    begin
        Saved := WorkDate();
        WorkDate(WorkDay);
        Prefix := Format(WorkDay, 0, 9) + ' ';
        case Part of
            1:
                begin
                    Texts.Add('Y');
                    Texts.Add('T-1D');
                    Texts.Add('T');
                    Texts.Add('T+1D');
                end;
            2:
                begin
                    Texts.Add('Y..');
                    Texts.Add('..Y');
                    Texts.Add('T-1D..T');
                    Texts.Add('..T-1D');
                    Texts.Add('T-1D..');
                end;
            3:
                begin
                    Texts.Add('W');
                    Texts.Add('Q');
                    Texts.Add('M');
                    Texts.Add('D');
                    Texts.Add('-1Y');
                    Texts.Add('1Y');
                end;
        end;
        foreach Txt in Texts do
            Observer.Observe(Prefix + Txt, Apply(Txt));
        WorkDate(Saved);
    end;

    [Test]
    procedure Y81_Letters_Today()
    begin
        Observer.Observe('today', Format(Today(), 0, 9));
        Observer.Observe('workdate', Format(WorkDate(), 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_Part1_Wd2024()
    begin
        Letters(20240615D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_Part1_Wd2025()
    begin
        Letters(20251231D, 1);
        Letters(20260101D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_Part1_Wd2026()
    begin
        Letters(20260615D, 1);
        Letters(20261231D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_Part1_Wd2027()
    begin
        Letters(20270101D, 1);
        Letters(20270615D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_Part1_WdLater()
    begin
        Letters(20280229D, 1);
        Letters(20300515D, 1);
        Letters(20310101D, 1);
        Letters(20991231D, 1);
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_Part2_Ranges()
    begin
        Letters(20240615D, 2);
        Letters(20260615D, 2);
        Letters(20300515D, 2);
        Observer.Finish();
    end;

    [Test]
    procedure Y81_Letters_Part3_Others()
    begin
        Letters(20240615D, 3);
        Letters(20260615D, 3);
        Letters(20300515D, 3);
        Observer.Finish();
    end;
}
