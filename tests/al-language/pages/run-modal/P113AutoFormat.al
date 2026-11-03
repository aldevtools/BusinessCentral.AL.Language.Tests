// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (P113 AF)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: AutoFormatType 0,1,2,10 and AutoFormatExpression on table fields, page controls and report columns: what a TestPage control shows for the same Decimal value, which declaration wins (page over table), and that a ProcessingOnly report with declared columns runs; only own formats, no currency expressions
// BC versions: 29 (27 and 28 by CI)

table 73086 "LT P113 AF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Amt0; Decimal) { AutoFormatType = 0; }
        field(3; Amt1; Decimal) { AutoFormatType = 1; AutoFormatExpression = ''; }
        field(4; Amt2; Decimal) { AutoFormatType = 2; AutoFormatExpression = ''; }
        field(5; Amt10; Decimal) { AutoFormatType = 10; AutoFormatExpression = '<Precision,3:3><Standard Format,0>'; }
        field(6; Amt10b; Decimal) { AutoFormatType = 10; AutoFormatExpression = '<Precision,2:2><Standard Format,0>'; }
        field(7; AmtNone; Decimal) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 73089 "LT P113 AF Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Entry; Text[250]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 73087 "LT P113 AF Card"
{
    PageType = Card;
    SourceTable = "LT P113 AF Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(T0; Rec.Amt0) { ApplicationArea = All; }
                field(T1; Rec.Amt1) { ApplicationArea = All; }
                field(T2; Rec.Amt2) { ApplicationArea = All; }
                field(T10; Rec.Amt10) { ApplicationArea = All; }
                field(T10b; Rec.Amt10b) { ApplicationArea = All; }
                field(TNone; Rec.AmtNone) { ApplicationArea = All; }
                field(P0; Rec.AmtNone) { ApplicationArea = All; AutoFormatType = 0; }
                field(P1; Rec.AmtNone) { ApplicationArea = All; AutoFormatType = 1; AutoFormatExpression = ''; }
                field(P2; Rec.AmtNone) { ApplicationArea = All; AutoFormatType = 2; AutoFormatExpression = ''; }
                field(P10a; Rec.AmtNone) { ApplicationArea = All; AutoFormatType = 10; AutoFormatExpression = '<Precision,2:2><Standard Format,0>'; }
                field(P10z; Rec.AmtNone) { ApplicationArea = All; AutoFormatType = 10; AutoFormatExpression = '<Precision,0:0><Standard Format,0>'; }
                field(P10r; Rec.AmtNone) { ApplicationArea = All; AutoFormatType = 10; AutoFormatExpression = '<Precision,1:5><Standard Format,0>'; }
                field(PovT10; Rec.Amt10) { ApplicationArea = All; AutoFormatType = 10; AutoFormatExpression = '<Precision,4:4><Standard Format,0>'; }
                field(PovT0; Rec.Amt10) { ApplicationArea = All; AutoFormatType = 0; }
                field(PDec; Rec.Amt10) { ApplicationArea = All; DecimalPlaces = 1 : 1; }
            }
        }
    }
}

report 73088 "LT P113 AF Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P113 AF Row")
        {
            column(Amt0Col; Amt0) { AutoFormatType = 0; }
            column(Amt1Col; Amt1) { AutoFormatType = 1; AutoFormatExpression = ''; }
            column(Amt2Col; Amt2) { AutoFormatType = 2; AutoFormatExpression = ''; }
            column(Amt10Col; Amt10) { AutoFormatType = 10; AutoFormatExpression = '<Precision,3:3><Standard Format,0>'; }

            trigger OnAfterGetRecord()
            var
                Log: Record "LT P113 AF Log";
                NextNo: Integer;
            begin
                if Log.FindLast() then
                    NextNo := Log."Entry No.";
                Log.Init();
                Log."Entry No." := NextNo + 1;
                Log.Entry := CopyStr(Row."Code" + '|' + Format(Row.Amt0) + '|' + Format(Row.Amt10) + '|' + Format(Row.Amt2), 1, 250);
                Log.Insert();
            end;
        }
    }
}

codeunit 73090 "LT P113 AutoFormat"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Value: Decimal)
    var
        Row: Record "LT P113 AF Row";
        Log: Record "LT P113 AF Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Row.Init();
        Row."Code" := 'R1';
        Row.Amt0 := Value;
        Row.Amt1 := Value;
        Row.Amt2 := Value;
        Row.Amt10 := Value;
        Row.Amt10b := Value;
        Row.AmtNone := Value;
        Row.Insert();
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; var Card: TestPage "LT P113 AF Card")
    begin
        Observer.Observe('T0', Card.T0.Value());
        Observer.Observe('T1', Card.T1.Value());
        Observer.Observe('T2', Card.T2.Value());
        Observer.Observe('T10', Card.T10.Value());
        Observer.Observe('T10b', Card.T10b.Value());
        Observer.Observe('TNone', Card.TNone.Value());
        Observer.Observe('P0', Card.P0.Value());
        Observer.Observe('P1', Card.P1.Value());
        Observer.Observe('P2', Card.P2.Value());
        Observer.Observe('P10a', Card.P10a.Value());
        Observer.Observe('P10z', Card.P10z.Value());
        Observer.Observe('P10r', Card.P10r.Value());
        Observer.Observe('PovT10', Card.PovT10.Value());
        Observer.Observe('PovT0', Card.PovT0.Value());
        Observer.Observe('PDec', Card.PDec.Value());
    end;

    [Test]
    procedure P113_AF_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 AF Card";
    begin
        Seed(1234.5);
        Card.OpenView();
        ObserveAll(Observer, Card);
        Card.Close();
        Observer.Expect('T0', '1,234.50');
        Observer.Expect('T1', '1,234.50');
        Observer.Expect('T2', '1,234.50');
        Observer.Expect('T10', '1,234.500');
        Observer.Expect('T10b', '1,234.50');
        Observer.Expect('TNone', '1,234.50');
        Observer.Expect('P0', '1,234.50');
        Observer.Expect('P1', '1,234.50');
        Observer.Expect('P2', '1,234.50');
        Observer.Expect('P10a', '1,234.50');
        Observer.Expect('P10z', '1,235');
        Observer.Expect('P10r', '1,234.5');
        Observer.Expect('PovT10', '1,234.5000');
        Observer.Expect('PovT0', '1,234.500');
        Observer.Expect('PDec', '1,234.500');
        Observer.Verify();
    end;

    [Test]
    procedure P113_AF_Zero()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 AF Card";
    begin
        Seed(0);
        Card.OpenView();
        ObserveAll(Observer, Card);
        Card.Close();
        Observer.Expect('T0', '0.00');
        Observer.Expect('T1', '0.00');
        Observer.Expect('T2', '0.00');
        Observer.Expect('T10', '0.000');
        Observer.Expect('T10b', '0.00');
        Observer.Expect('TNone', '0.00');
        Observer.Expect('P0', '0.00');
        Observer.Expect('P1', '0.00');
        Observer.Expect('P2', '0.00');
        Observer.Expect('P10a', '0.00');
        Observer.Expect('P10z', '0');
        Observer.Expect('P10r', '0.0');
        Observer.Expect('PovT10', '0.0000');
        Observer.Expect('PovT0', '0.000');
        Observer.Expect('PDec', '0.000');
        Observer.Verify();
    end;

    [Test]
    procedure P113_AF_Large()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 AF Card";
    begin
        Seed(1000000);
        Card.OpenView();
        ObserveAll(Observer, Card);
        Card.Close();
        Observer.Expect('T0', '1,000,000.00');
        Observer.Expect('T1', '1,000,000.00');
        Observer.Expect('T2', '1,000,000.00');
        Observer.Expect('T10', '1,000,000.000');
        Observer.Expect('T10b', '1,000,000.00');
        Observer.Expect('TNone', '1,000,000.00');
        Observer.Expect('P0', '1,000,000.00');
        Observer.Expect('P1', '1,000,000.00');
        Observer.Expect('P2', '1,000,000.00');
        Observer.Expect('P10a', '1,000,000.00');
        Observer.Expect('P10z', '1,000,000');
        Observer.Expect('P10r', '1,000,000.0');
        Observer.Expect('PovT10', '1,000,000.0000');
        Observer.Expect('PovT0', '1,000,000.000');
        Observer.Expect('PDec', '1,000,000.000');
        Observer.Verify();
    end;

    [Test]
    procedure P113_AF_Rounding()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 AF Card";
    begin
        Seed(2.5);
        Card.OpenView();
        ObserveAll(Observer, Card);
        Card.Close();
        Seed(0.005);
        Card.OpenView();
        Observer.Observe('small-P10a', Card.P10a.Value());
        Observer.Observe('small-P10z', Card.P10z.Value());
        Observer.Observe('small-T10', Card.T10.Value());
        Card.Close();
        Observer.Expect('T0', '2.50');
        Observer.Expect('T1', '2.50');
        Observer.Expect('T2', '2.50');
        Observer.Expect('T10', '2.500');
        Observer.Expect('T10b', '2.50');
        Observer.Expect('TNone', '2.50');
        Observer.Expect('P0', '2.50');
        Observer.Expect('P1', '2.50');
        Observer.Expect('P2', '2.50');
        Observer.Expect('P10a', '2.50');
        Observer.Expect('P10z', '3');
        Observer.Expect('P10r', '2.5');
        Observer.Expect('PovT10', '2.5000');
        Observer.Expect('PovT0', '2.500');
        Observer.Expect('PDec', '2.500');
        Observer.Expect('small-P10a', '0.01');
        Observer.Expect('small-P10z', '0');
        Observer.Expect('small-T10', '0.005');
        Observer.Verify();
    end;

    [Test]
    procedure P113_AF_SetValueStoresFullPrecision()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 AF Card";
        Row: Record "LT P113 AF Row";
    begin
        Seed(1);
        Card.OpenEdit();
        Card.P10a.SetValue(5.123456);
        Card.T10.SetValue(7.987654);
        Card.Close();
        Row.Get('R1');
        Observer.Observe('stored-AmtNone', Format(Row.AmtNone, 0, 9));
        Observer.Observe('stored-Amt10', Format(Row.Amt10, 0, 9));
        Card.OpenView();
        Observer.Observe('shown-P10a', Card.P10a.Value());
        Observer.Observe('shown-P10z', Card.P10z.Value());
        Observer.Observe('shown-T10', Card.T10.Value());
        Observer.Observe('shown-PovT10', Card.PovT10.Value());
        Card.Close();
        Observer.Expect('stored-AmtNone', '5.12');
        Observer.Expect('stored-Amt10', '7.988');
        Observer.Expect('shown-P10a', '5.12');
        Observer.Expect('shown-P10z', '5');
        Observer.Expect('shown-T10', '7.988');
        Observer.Expect('shown-PovT10', '7.9880');
        Observer.Verify();
    end;

    [Test]
    procedure P113_AF_TableFieldFormatIsPlain()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P113 AF Row";
    begin
        Seed(1234.5);
        Row.Get('R1');
        Observer.Observe('Amt0', Format(Row.Amt0));
        Observer.Observe('Amt1', Format(Row.Amt1));
        Observer.Observe('Amt2', Format(Row.Amt2));
        Observer.Observe('Amt10', Format(Row.Amt10));
        Observer.Observe('Amt10b', Format(Row.Amt10b));
        Observer.Observe('AmtNone', Format(Row.AmtNone));
        Observer.Observe('Amt10-9', Format(Row.Amt10, 0, 9));
        Observer.Observe('Amt10-1', Format(Row.Amt10, 0, 1));
        Observer.Observe('Amt10-0.0', Format(Row.Amt10, 0, '<Precision,1:1><Standard Format,0>'));
        Observer.Expect('Amt0', '1,234.5');
        Observer.Expect('Amt1', '1,234.50');
        Observer.Expect('Amt2', '1,234.50');
        Observer.Expect('Amt10', '1,234.500');
        Observer.Expect('Amt10b', '1,234.50');
        Observer.Expect('AmtNone', '1,234.5');
        Observer.Expect('Amt10-9', '1234.500');
        Observer.Expect('Amt10-1', '1234.500');
        Observer.Expect('Amt10-0.0', '1,234.5');
        Observer.Verify();
    end;

    [Test]
    procedure P113_AF_ReportRunsWithAutoFormatColumns()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT P113 AF Report";
        Log: Record "LT P113 AF Log";
    begin
        Seed(1234.5);
        Commit();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('rows', Format(Log.Count()));
        if Log.FindFirst() then
            Observer.Observe('entry', Log.Entry);
        Observer.Expect('rows', '1');
        Observer.Expect('entry', 'R1|1,234.5|1,234.500|1,234.50');
        Observer.Verify();
    end;
}
