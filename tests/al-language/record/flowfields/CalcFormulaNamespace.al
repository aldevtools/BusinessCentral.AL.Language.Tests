// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 67184 to 67186, codeunit 67187
// Probe: CalcFormula (Sum, Count, Exist) over a source table that lives in a namespace, written with the namespace in front of the table name and, from a file
// that imports the namespace with `using`, without it. The FlowField value after CalcFields.

namespace LTCalcNs.Owner;

using LTCalcNs.Source;

table 67185 "LT CN Header Qualified"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum(LTCalcNs.Source."LT CN Detail".Amount where("Doc No." = field("No.")));
        }
        field(3; Lines; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count(LTCalcNs.Source."LT CN Detail" where("Doc No." = field("No.")));
        }
        field(4; AnyLine; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist(LTCalcNs.Source."LT CN Detail" where("Doc No." = field("No.")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 67186 "LT CN Header Imported"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT CN Detail".Amount where("Doc No." = field("No.")));
        }
        field(3; Lines; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CN Detail" where("Doc No." = field("No.")));
        }
        field(4; AnyLine; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT CN Detail" where("Doc No." = field("No.")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 67187 "LT CN Calc Formula Namespace"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Detail: Record "LT CN Detail";
        Qualified: Record "LT CN Header Qualified";
        Imported: Record "LT CN Header Imported";
    begin
        Detail.DeleteAll();
        Qualified.DeleteAll();
        Imported.DeleteAll();
        Detail.Init();
        Detail."Entry No." := 1;
        Detail."Doc No." := 'D1';
        Detail.Amount := 10;
        Detail.Insert();
        Detail.Init();
        Detail."Entry No." := 2;
        Detail."Doc No." := 'D1';
        Detail.Amount := 32.5;
        Detail.Insert();
        Detail.Init();
        Detail."Entry No." := 3;
        Detail."Doc No." := 'D2';
        Detail.Amount := 7;
        Detail.Insert();
        Qualified."No." := 'D1';
        Qualified.Insert();
        Qualified."No." := 'D2';
        Qualified.Insert();
        Qualified."No." := 'D3';
        Qualified.Insert();
        Imported."No." := 'D1';
        Imported.Insert();
        Imported."No." := 'D2';
        Imported.Insert();
        Imported."No." := 'D3';
        Imported.Insert();
    end;

    [Test]
    procedure Qualified_Sum_Count_Exist()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT CN Header Qualified";
    begin
        Seed();
        Header.SetAutoCalcFields();
        Header.Get('D1');
        Header.CalcFields(Total, Lines, AnyLine);
        Observer.Observe('d1', Format(Header.Total) + '|' + Format(Header.Lines) + '|' + Format(Header.AnyLine));
        Header.Get('D2');
        Header.CalcFields(Total, Lines, AnyLine);
        Observer.Observe('d2', Format(Header.Total) + '|' + Format(Header.Lines) + '|' + Format(Header.AnyLine));
        Header.Get('D3');
        Header.CalcFields(Total, Lines, AnyLine);
        Observer.Observe('d3', Format(Header.Total) + '|' + Format(Header.Lines) + '|' + Format(Header.AnyLine));
        Observer.Expect('d1', '42.5|2|Yes');
        Observer.Expect('d2', '7|1|Yes');
        Observer.Expect('d3', '0|0|No');
        Observer.Verify();
    end;

    [Test]
    procedure Imported_Sum_Count_Exist()
    var
        Observer: Codeunit "Probe Observer";
        Header: Record "LT CN Header Imported";
    begin
        Seed();
        Header.Get('D1');
        Header.CalcFields(Total, Lines, AnyLine);
        Observer.Observe('d1', Format(Header.Total) + '|' + Format(Header.Lines) + '|' + Format(Header.AnyLine));
        Header.Get('D3');
        Header.CalcFields(Total, Lines, AnyLine);
        Observer.Observe('d3', Format(Header.Total) + '|' + Format(Header.Lines) + '|' + Format(Header.AnyLine));
        Observer.Expect('d1', '42.5|2|Yes');
        Observer.Expect('d3', '0|0|No');
        Observer.Verify();
    end;
}
