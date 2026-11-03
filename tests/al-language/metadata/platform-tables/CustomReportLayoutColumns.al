// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 74799
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: the columns of the Base Application table Custom Report Layout (9650) through RecordRef/FieldRef: number, name, type, length and field class of each column, and
//   (rows are not read: they depend on the database). Extension Logo: the symbols of BC 27 hold no table of that name (Extension Logo Part is a page), so there is nothing to read.
//   Report Metadata and Windows Language are pinned in metadata/lt-report-metadata-columns and record/TestWindowsLanguageTable.al.
// BC versions: all (CI)

codeunit 74799 "LT CRL Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Columns_Schema()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
    begin
        RR.Open(Database::"Custom Report Layout");
        Observer.Observe('fieldCount', Format(RR.FieldCount()));
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Observer.Observe('f' + Format(FR.Number()), FR.Name() + ':' + Format(FR.Type()) + ':' + Format(FR.Length()) + ':' + Format(FR.Class()));
        end;
        Observer.Observe('primaryKey', Format(RR.KeyCount() > 0));
        Observer.Expect('fieldCount', '14');
        Observer.Expect('f1', 'Code:Code:20:Normal');
        Observer.Expect('f2', 'Report ID:Integer:4:Normal');
        Observer.Expect('f4', 'Company Name:Text:30:Normal');
        Observer.Expect('f6', 'Type:Option:4:Normal');
        Observer.Expect('f7', 'Layout:BLOB:8:Normal');
        Observer.Expect('f8', 'Last Modified:DateTime:8:Normal');
        Observer.Expect('f9', 'Last Modified by User:Code:50:Normal');
        Observer.Expect('f10', 'File Extension:Text:30:Normal');
        Observer.Expect('f11', 'Description:Text:250:Normal');
        Observer.Expect('f12', 'Custom XML Part:BLOB:8:Normal');
        Observer.Expect('f13', 'App ID:GUID:16:Normal');
        Observer.Expect('f14', 'Built-In:Boolean:4:Normal');
        Observer.Expect('f15', 'Layout Last Updated:DateTime:8:Normal');
        Observer.Expect('f3', 'Report Name:Text:250:FlowField');
        Observer.Expect('primaryKey', 'Yes');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Values and builtins" (documentation-only assumption): RecordRef.FieldIndex over a table with FlowFilter
    // fields between normal fields and a FlowField (Columns_Schema above pins only FlowFields after the others).
    [Test]
    procedure PW_FieldIndex_FlowFilterAmongNormalFields()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Order: Text;
    begin
        RR.Open(Database::"LT PW FI Row");
        Observer.Observe('fieldCount', Format(RR.FieldCount()));
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Order += Format(FR.Number()) + ':' + Format(FR.Class()) + ';';
        end;
        Observer.Observe('order', Order);
        Observer.Expect('fieldCount', '9');
        Observer.Expect('order', '1:Normal;3:Normal;5:Normal;7:Normal;20:Normal;2:FlowFilter;6:FlowFilter;4:FlowField;8:FlowField;');
        Observer.Verify();
    end;
}

// Writer PW: fields in id order: normal, FlowFilter, normal, FlowField, normal, FlowFilter, Blob, FlowField.
table 86148 "LT PW FI Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; FilterA; Integer) { FieldClass = FlowFilter; }
        field(3; Name; Text[20]) { }
        field(4; CntA; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FI Row"); }
        field(5; Amt; Decimal) { }
        field(6; FilterB; Date) { FieldClass = FlowFilter; }
        field(7; Data; Blob) { }
        field(8; CntB; Integer) { FieldClass = FlowField; CalcFormula = count("LT PW FI Row" where(Id = field(FilterA))); }
        field(20; Late; Code[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
