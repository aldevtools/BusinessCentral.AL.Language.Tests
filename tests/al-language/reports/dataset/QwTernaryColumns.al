// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 87500, reports 87501, 87510-87519, 87521, 87523, 87525, report extensions 87520, 87522, 87524,
// test codeunit 87503
// Probe (corpus issue 685 section 1, from a user report): a ternary expression as the source of a report dataset column, with a Label, an
// empty literal or a field as a branch, and ternary columns of Decimal, Integer, Date, Boolean, Option and Enum, also in a report extension.
// Each column has a report of its own, because the service tier compiles each report to C# when it first runs, and a failure there fails
// every column of that report. Each test saves the dataset as XML (Report.SaveAs, ReportFormat::Xml) for one row with Flag = true and one
// with Flag = false and reads every Column line. IncludeCaption on a ternary column does not compile (AL0385, tests/must-not-compile/cases/0015).
// BC versions: 27.5+

table 87500 "LT QW Tern Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
        field(3; Name; Text[30]) { }
        field(4; Amount; Decimal) { }
        field(5; Qty; Integer) { }
        field(6; D; Date) { }
        field(7; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(8; E; Enum "Sales Document Type") { }
        field(9; Flag2; Boolean) { }
        field(10; Name2; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 87501 "LT QW Tern EmptyOrLbl"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(EmptyOrLbl; Row.Flag ? '' : LblA) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}
#if LTQW_LABEL_EMPTY_COLUMN_PROBE
// `column(LblOrEmpty; Row.Flag ? LblA : '')` (a Label true branch and an empty literal false branch) compiles and publishes, but the first
// run of the report fails in the service tier's C# compile with an uncatchable exception (corpus CI run 39748741686, BC 29.0):
// "C# compilation has failed for the application object Report_87510 ... error CS0029: Cannot implicitly convert type 'string' to
// 'Microsoft.Dynamics.Nav.Runtime.NavValue'". `Row.Flag ? '' : LblA` (report 87501) and the same ternary in code
// (QW_Ternary_LabelBranches in tests/al-language/types/TestTernaryContracts.al) work. Queued for a Windows check; compiled only with
// LTQW_LABEL_EMPTY_COLUMN_PROBE.

report 87510 "LT QW Tern LblOrEmpty"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(LblOrEmpty; Row.Flag ? LblA : '') { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}
#endif

report 87511 "LT QW Tern LblOrLbl"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(LblOrLbl; Row.Flag ? LblA : LblB) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87512 "LT QW Tern LblOrField"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(LblOrField; Row.Flag ? LblA : Row.Name) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87513 "LT QW Tern FieldOrLbl"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(FieldOrLbl; Row.Flag ? Row.Name : LblA) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87514 "LT QW Tern FieldOrEmpty"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(FieldOrEmpty; Row.Flag ? Row.Name : '') { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87515 "LT QW Tern TwoLiterals"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(TwoLiterals; Row.Flag ? 'yes' : 'no') { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87516 "LT QW Tern FieldOrField"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(FieldOrField; Row.Flag ? Row.Name : Row.Name2) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87517 "LT QW Tern Numbers"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(DecCol; Row.Flag ? Row.Amount : 0) { }
            column(IntCol; Row.Flag ? Row.Qty : 7) { }
            column(DateCol; Row.Flag ? Row.D : 0D) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87525 "LT QW Tern IntOrDec"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(IntOrDec; Row.Flag ? 7 : Row.Amount) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87518 "LT QW Tern BoolOptEnum"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
            column(BoolCol; Row.Flag ? Row.Flag2 : true) { }
            column(OptCol; Row.Flag ? Row.Opt : Row.Opt::Gamma) { }
            column(EnumCol; Row.Flag ? Row.E : Row.E::Order) { }
        }
    }

    var
        LblA: Label 'Label A';
        LblB: Label 'Label B';
}

report 87519 "LT QW Tern Base ExtEmptyOrLbl"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
        }
    }
}

reportextension 87520 "LT QW Tern Ext ExtEmptyOrLbl" extends "LT QW Tern Base ExtEmptyOrLbl"
{
    dataset
    {
        add(Row)
        {
            column(ExtEmptyOrLbl; Row.Flag ? '' : ExtLbl) { }
        }
    }

    var
        ExtLbl: Label 'Ext label';
}

report 87521 "LT QW Tern Base ExtLblOrField"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
        }
    }
}

reportextension 87522 "LT QW Tern Ext ExtLblOrField" extends "LT QW Tern Base ExtLblOrField"
{
    dataset
    {
        add(Row)
        {
            column(ExtLblOrField; Row.Flag ? ExtLbl : Row.Name) { }
        }
    }

    var
        ExtLbl: Label 'Ext label';
}

report 87523 "LT QW Tern Base ExtNumbers"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT QW Tern Row")
        {
            column(Id; Row.Id) { }
        }
    }
}

reportextension 87524 "LT QW Tern Ext ExtNumbers" extends "LT QW Tern Base ExtNumbers"
{
    dataset
    {
        add(Row)
        {
            column(ExtDec; Row.Flag ? Row.Amount : 1) { }
            column(ExtEnum; Row.Flag ? Row.E : Row.E::Quote) { }
        }
    }

    var
        ExtLbl: Label 'Ext label';
}

codeunit 87503 "LT QW Tern Column Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT QW Tern Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Flag := true;
        Row.Name := 'Field name';
        Row.Name2 := 'Other field';
        Row.Amount := 12.5;
        Row.Qty := 3;
        Row.D := DMY2Date(15, 3, 2024);
        Row.Opt := Row.Opt::Beta;
        Row.E := Row.E::Invoice;
        Row.Flag2 := false;
        Row.Insert();
        Row.Id := 2;
        Row.Flag := false;
        Row.Insert();
    end;

    // Every Column line of the XML dataset except Id, trimmed, in dataset order (row 1 has Flag = true, row 2 Flag = false).
    [TryFunction]
    local procedure TryColumns(ReportId: Integer; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
    begin
        Result := '';
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<Column ') and not Line.StartsWith('<Column name="Id"') then
                Result += '[' + Line + ']';
        end;
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Result: Text;
    begin
        Seed();
        if TryColumns(ReportId, Result) then
            Observer.Observe('columns', Result)
        else
            Observer.ObserveError('columns');
    end;

    [Test]
    procedure QW_TernaryColumn_EmptyOrLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern EmptyOrLbl");
        Observer.Expect('columns', '[<Column name="EmptyOrLbl"></Column>][<Column name="EmptyOrLbl">Label A</Column>]');
        Observer.Verify();
    end;
#if LTQW_LABEL_EMPTY_COLUMN_PROBE

    [Test]
    procedure QW_TernaryColumn_LabelOrEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern LblOrEmpty");
        Observer.Finish();
    end;
#endif

    [Test]
    procedure QW_TernaryColumn_LabelOrLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern LblOrLbl");
        Observer.Expect('columns', '[<Column name="LblOrLbl">Label A</Column>][<Column name="LblOrLbl">Label B</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_LabelOrField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern LblOrField");
        Observer.Expect('columns', '[<Column name="LblOrField">Label A</Column>][<Column name="LblOrField">Field name</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_FieldOrLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern FieldOrLbl");
        Observer.Expect('columns', '[<Column name="FieldOrLbl">Field name</Column>][<Column name="FieldOrLbl">Label A</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_FieldOrEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern FieldOrEmpty");
        Observer.Expect('columns', '[<Column name="FieldOrEmpty">Field name</Column>][<Column name="FieldOrEmpty"></Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_TwoLiterals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern TwoLiterals");
        Observer.Expect('columns', '[<Column name="TwoLiterals">yes</Column>][<Column name="TwoLiterals">no</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_FieldOrField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern FieldOrField");
        Observer.Expect('columns', '[<Column name="FieldOrField">Field name</Column>][<Column name="FieldOrField">Other field</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_DecimalIntegerDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern Numbers");
        Observer.Expect('columns', '[<Column name="DecCol" decimalformatter="#,##0.00">12.5</Column>][<Column name="IntCol">3</Column>][<Column name="DateCol">3/15/2024</Column>][<Column name="DecCol" decimalformatter="#,##0.00">0</Column>][<Column name="IntCol">7</Column>][<Column name="DateCol"></Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_IntegerOrDecimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern IntOrDec");
        Observer.Expect('columns|text', 'The SourceExpr for report control ''IntOrDec'' is not valid. The following error occurred: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 12.5 to System.Int32.');
        Observer.Expect('columns|code', 'ReportSourceExpression');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_BooleanOptionEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern BoolOptEnum");
        Observer.Expect('columns', '[<Column name="BoolCol">False</Column>][<Column name="OptCol">Beta</Column>][<Column name="EnumCol">Invoice</Column>][<Column name="BoolCol">True</Column>][<Column name="OptCol">Gamma</Column>][<Column name="EnumCol">Order</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_ExtEmptyOrLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern Base ExtEmptyOrLbl");
        Observer.Expect('columns', '[<Column name="ExtEmptyOrLbl"></Column>][<Column name="ExtEmptyOrLbl">Ext label</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_ExtLabelOrField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern Base ExtLblOrField");
        Observer.Expect('columns', '[<Column name="ExtLblOrField">Ext label</Column>][<Column name="ExtLblOrField">Field name</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure QW_TernaryColumn_ExtDecimalEnum()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, Report::"LT QW Tern Base ExtNumbers");
        Observer.Expect('columns', '[<Column name="ExtDec" decimalformatter="#,##0.00">12.5</Column>][<Column name="ExtEnum">Invoice</Column>][<Column name="ExtDec" decimalformatter="#,##0.00">1</Column>][<Column name="ExtEnum">Quote</Column>]');
        Observer.Verify();
    end;
}
