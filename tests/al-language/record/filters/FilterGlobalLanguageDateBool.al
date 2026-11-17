// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope. SetFilter on a Date field with date texts, and on a Boolean field with Yes/No words, under GlobalLanguage 1030, 1036, 1044 and 1053 (the session region stays en-US).
// Fixtures used: Probe Observer (codeunit 69160); own objects 75407-75408 (LT GL LF Row, LT GL Filter Language)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
// BC versions: 27, 28, 29

table 75407 "LT GL LF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Doc Date"; Date) { }
        field(3; Active; Boolean) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 75408 "LT GL Filter Language"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetFilter(var Row: Record "LT GL LF Row"; FieldNo: Integer; Filter: Text)
    begin
        if FieldNo = 2 then
            Row.SetFilter("Doc Date", Filter)
        else
            Row.SetFilter(Active, Filter);
    end;

    local procedure Add(var Row: Record "LT GL LF Row"; RowCode: Code[20]; D: Date; IsActive: Boolean)
    begin
        Row."Code" := RowCode;
        Row."Doc Date" := D;
        Row.Active := IsActive;
        Row.Insert();
    end;

    // Rows: A001 2024-03-15 true, A002 2024-03-16 true, B001 2023-12-31 false, B002 closing 2023-12-31 true, C001 2024-03-14 false.
    local procedure Seed()
    var
        Row: Record "LT GL LF Row";
    begin
        Row.DeleteAll();
        Add(Row, 'A001', DMY2Date(15, 3, 2024), true);
        Add(Row, 'A002', DMY2Date(16, 3, 2024), true);
        Add(Row, 'B001', DMY2Date(31, 12, 2023), false);
        Add(Row, 'B002', ClosingDate(DMY2Date(31, 12, 2023)), true);
        Add(Row, 'C001', DMY2Date(14, 3, 2024), false);
    end;

    // ok|GetFilter|the codes the filter selects, or the error text and code
    local procedure Probe(FieldNo: Integer; Filter: Text): Text
    var
        Row: Record "LT GL LF Row";
        Codes: Text;
        Shown: Text;
    begin
        ClearLastError();
        if not TrySetFilter(Row, FieldNo, Filter) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        if FieldNo = 2 then
            Shown := Row.GetFilter("Doc Date")
        else
            Shown := Row.GetFilter(Active);
        if Row.FindSet() then
            repeat
                Codes += Row."Code" + ',';
            until Row.Next() = 0;
        exit('ok|' + Shown + '|' + Codes);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Lang: Integer; FieldNo: Integer; Filters: List of [Text])
    var
        Results: List of [Text];
        F: Text;
        I: Integer;
    begin
        Seed();
        GlobalLanguage(Lang);
        foreach F in Filters do
            Results.Add(Probe(FieldNo, F));
        GlobalLanguage(1033);
        for I := 1 to Filters.Count() do
            Observer.Observe('[' + Filters.Get(I) + ']', Results.Get(I));
    end;

    local procedure DateLocalForms(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('15.03.2024', '15-03-2024..', '150324');
        Run(Observer, Lang, 2, Filters);
    end;

    local procedure DateRegionForms(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('2024-03-15', '03/15/24', '031524', '03152024', '03/14/24..03/15/24', 'C12/31/23', '12/31/23');
        Run(Observer, Lang, 2, Filters);
    end;

    local procedure DateClosingLetters(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('U12/31/23', 'S12/31/23');
        Run(Observer, Lang, 2, Filters);
    end;

    local procedure BooleanWords(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('Ja', 'ja', 'Nej', 'Nei', 'true', 'False', '1', '0', 'Ja|Nej');
        Run(Observer, Lang, 3, Filters);
    end;

    local procedure BooleanForeignWords(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('Yes', 'No', 'Oui', 'Sand');
        Run(Observer, Lang, 3, Filters);
    end;

    local procedure BooleanRoundTrip(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Row: Record "LT GL LF Row";
        FalseText: Text;
        TrueText: Text;
        Back: Text;
        BackTrue: Text;
    begin
        Seed();
        GlobalLanguage(Lang);
        Row.SetRange(Active, false);
        FalseText := Row.GetFilter(Active);
        Row.SetRange(Active, true);
        TrueText := Row.GetFilter(Active);
        Back := Probe(3, FalseText);
        BackTrue := Probe(3, TrueText);
        GlobalLanguage(1033);
        Observer.Observe('GetFilter of SetRange false', FalseText);
        Observer.Observe('GetFilter of SetRange true', TrueText);
        Observer.Observe('SetFilter of the false text', Back);
        Observer.Observe('SetFilter of the true text', BackTrue);
    end;

    [Test]
    procedure DateFilter_LocalForms_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_LocalForms_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_LocalForms_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_LocalForms_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_LocalForms_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateLocalForms(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_RegionForms_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_RegionForms_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_RegionForms_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_RegionForms_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_RegionForms_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateRegionForms(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure DateFilter_ClosingLetters_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DateClosingLetters(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_Words_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanWords(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_Words_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanWords(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_Words_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanWords(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_ForeignWords_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanForeignWords(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_ForeignWords_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanForeignWords(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_ForeignWords_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanForeignWords(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_RoundTrip_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanRoundTrip(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_RoundTrip_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanRoundTrip(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure BoolFilter_RoundTrip_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        BooleanRoundTrip(Observer, 1053);
        Observer.Finish();
    end;
}
