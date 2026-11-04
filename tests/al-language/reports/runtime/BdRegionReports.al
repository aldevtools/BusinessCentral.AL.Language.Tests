// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatregion-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 81050-81070 (BdRegionFixtures.al, this file, BdRegionTests.al)
// Probe: corpus issue 657 (report FormatRegion). One report per FormatRegion property value with the same dataset and the same Format() calls in every
// trigger: a Decimal above and below zero, a date with a two-digit and with a one-digit day, the long date format 4, a DateTime before and after 10:00,
// a Time before and after 10:00 and a negative Integer.
// BC versions: 27-29

report 81052 "BD Region De"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'de-DE';
    DefaultRenderingLayout = BdLay;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    rendering
    {
        layout(BdLay)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/BdRegionDe.rdlc';
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81053 "BD Region Gb"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'en-GB';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81054 "BD Region Fr"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'fr-FR';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81055 "BD Region Jp"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'ja-JP';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81056 "BD Region Zz"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'zz-ZZ';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81057 "BD Region Dk"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'da-DK';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81058 "BD Region Us"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'en-US';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81059 "BD Region Nl"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'nl-NL';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81060 "BD Region Ch"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'de-CH';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81061 "BD Region It"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'it-IT';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81062 "BD Region Es"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'es-ES';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81063 "BD Region Se"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'sv-SE';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81064 "BD Region No"
{
    UsageCategory = None;
    UseRequestPage = false;
    FormatRegion = 'nb-NO';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81065 "BD Region Empty"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81066 "BD Region De Proc"
{
    UsageCategory = None;
    UseRequestPage = false;
    ProcessingOnly = true;
    FormatRegion = 'de-DE';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}

report 81067 "BD Region De Req"
{
    UsageCategory = None;
    UseRequestPage = true;
    FormatRegion = 'de-DE';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(AmtCol; Amt) { }
            column(NegCol; Neg) { }
            column(D1Col; D1) { }
            column(D2Col; D2) { }
            column(DT1Col; DT1) { }
            column(DT2Col; DT2) { }
            column(T1Col; T1) { }
            column(T2Col; T2) { }
            column(IntCol; IntV) { }
            column(TextsCol; Texts) { }

            trigger OnAfterGetRecord()
            begin
                Texts := Fmt();
                Log.Add('get', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqAmt; Amt) { ApplicationArea = All; Caption = 'Amount'; }
            }
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        Neg := -1234.5;
        D1 := DMY2Date(31, 1, 2025);
        D2 := DMY2Date(5, 3, 2024);
        T1 := 143015T;
        T2 := 090507T;
        DT1 := CreateDateTime(D1, T1);
        DT2 := CreateDateTime(D2, T2);
        IntV := -1234567;
        Log.Add('init', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPreReport()
    begin
        Log.Add('pre', Fmt() + ' region=[' + CurrReport.FormatRegion() + ']');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post', Fmt());
    end;

    local procedure Fmt(): Text
    begin
        exit(Format(Amt) + '#' + Format(Neg) + '#' + Format(D1) + '#' + Format(D2) + '#' + Format(D2, 0, 4) + '#' + Format(DT1) + '#' + Format(DT2) + '#' + Format(T1) + '#' + Format(T2) + '#' + Format(IntV));
    end;

    var
        Log: Codeunit "BD Region Log";
        Amt: Decimal;
        Neg: Decimal;
        D1: Date;
        D2: Date;
        DT1: DateTime;
        DT2: DateTime;
        T1: Time;
        T2: Time;
        IntV: Integer;
        Texts: Text;
}
