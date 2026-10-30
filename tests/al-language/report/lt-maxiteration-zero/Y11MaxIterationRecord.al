// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxiteration-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 91530 and 91531, reports 91532-91538, test codeunit 91539
// Probe: observe probe (writer Y11, 2026-10-30, al-runner issue 6412); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: MaxIteration on a data item over a record table, run through Report.SaveAs(Xml) on a report instance: how many rows OnAfterGetRecord
//   sees (and which, in key order) and how many dataset rows the Xml holds, for MaxIteration 1 and 3 of five rows, 10 (more than the rows),
//   2 with a DataItemTableView filter, 2 with a SetFilter in OnPreDataItem, 2 with CurrReport.Skip on every odd row, and a parent with
//   MaxIteration 2 over a linked child with MaxIteration 1 (three lines per parent). Writer SG's ProcessingOnly cases (2 of 5, skip, fewer
//   rows, descending, unlinked child) are in SgMaxIterationTable.al and MaxIterationZero.al.
// Result (SaaS BC 29): MaxIteration caps the rows the data item reads after its filters (DataItemTableView and OnPreDataItem SetFilter);
//   a row skipped with CurrReport.Skip still counts; a linked child with MaxIteration 1 reads one line per parent; the dataset holds one
//   row per row read and not skipped. A second SaveAs on the same report instance fails with ObjectHasAlreadyBeenRun.
// BC versions: 27, 28, 29

table 91530 "LT Y11 MI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Integer) { }
        field(2; Grp; Code[10]) { }
    }
    keys
    {
        key(PK; No) { Clustered = true; }
    }
}

table 91531 "LT Y11 MI Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DocNo; Integer) { }
        field(2; LineNo; Integer) { }
    }
    keys
    {
        key(PK; DocNo, LineNo) { Clustered = true; }
    }
}

report 91532 "LT Y11 MI One"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(R; "LT Y11 MI Row")
        {
            MaxIteration = 1;
            column(No; No) { }

            trigger OnAfterGetRecord()
            begin
                Seen += Format(R.No) + ',';
            end;
        }
    }

    var
        Seen: Text;

    procedure Result(): Text
    begin
        exit(Seen);
    end;
}

report 91533 "LT Y11 MI Three"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(R; "LT Y11 MI Row")
        {
            MaxIteration = 3;
            column(No; No) { }

            trigger OnAfterGetRecord()
            begin
                Seen += Format(R.No) + ',';
            end;
        }
    }

    var
        Seen: Text;

    procedure Result(): Text
    begin
        exit(Seen);
    end;
}

report 91534 "LT Y11 MI Ten"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(R; "LT Y11 MI Row")
        {
            MaxIteration = 10;
            column(No; No) { }

            trigger OnAfterGetRecord()
            begin
                Seen += Format(R.No) + ',';
            end;
        }
    }

    var
        Seen: Text;

    procedure Result(): Text
    begin
        exit(Seen);
    end;
}

report 91535 "LT Y11 MI View"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(R; "LT Y11 MI Row")
        {
            DataItemTableView = sorting(No) where(Grp = const('B'));
            MaxIteration = 2;
            column(No; No) { }

            trigger OnAfterGetRecord()
            begin
                Seen += Format(R.No) + ',';
            end;
        }
    }

    var
        Seen: Text;

    procedure Result(): Text
    begin
        exit(Seen);
    end;
}

report 91536 "LT Y11 MI PreFilter"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(R; "LT Y11 MI Row")
        {
            MaxIteration = 2;
            column(No; No) { }

            trigger OnPreDataItem()
            begin
                R.SetFilter(No, '>=3');
            end;

            trigger OnAfterGetRecord()
            begin
                Seen += Format(R.No) + ',';
            end;
        }
    }

    var
        Seen: Text;

    procedure Result(): Text
    begin
        exit(Seen);
    end;
}

report 91537 "LT Y11 MI Skip"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(R; "LT Y11 MI Row")
        {
            MaxIteration = 2;
            column(No; No) { }

            trigger OnAfterGetRecord()
            begin
                Seen += Format(R.No) + ',';
                if R.No mod 2 = 1 then
                    CurrReport.Skip();
            end;
        }
    }

    var
        Seen: Text;

    procedure Result(): Text
    begin
        exit(Seen);
    end;
}

report 91538 "LT Y11 MI Nested"
{
    UseRequestPage = false;

    dataset
    {
        dataitem(R; "LT Y11 MI Row")
        {
            MaxIteration = 2;
            column(No; No) { }

            dataitem(L; "LT Y11 MI Line")
            {
                DataItemLink = DocNo = field(No);
                MaxIteration = 1;
                column(LineNo; LineNo) { }

                trigger OnAfterGetRecord()
                begin
                    Seen += 'L' + Format(L.DocNo) + '.' + Format(L.LineNo) + ',';
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Seen += 'R' + Format(R.No) + ',';
            end;
        }
    }

    var
        Seen: Text;

    procedure Result(): Text
    begin
        exit(Seen);
    end;
}

codeunit 91539 "LT Y11 MI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y11 MI Row";
        Line: Record "LT Y11 MI Line";
        i: Integer;
        j: Integer;
    begin
        Row.DeleteAll();
        Line.DeleteAll();
        for i := 1 to 5 do begin
            Row.No := i;
            if i in [2, 4, 5] then
                Row.Grp := 'B'
            else
                Row.Grp := 'A';
            Row.Insert();
            for j := 1 to 3 do begin
                Line.DocNo := i;
                Line.LineNo := j * 10;
                Line.Insert();
            end;
        end;
    end;

    // One text per <Columns> block of the Xml dataset: the column values joined by '/'.
    local procedure DatasetRows(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Rest: Text;
        Current: Text;
        Result: Text;
        Rows: Integer;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Line := Line.Trim();
            if Line = '<Columns>' then
                Current := '';
            if Line = '</Columns>' then begin
                Rows += 1;
                Result += Current + ';';
            end;
            if Line.StartsWith('<Column name="') then begin
                Rest := Line.Substring(Line.IndexOf('>') + 1);
                Current += Rest.Replace('</Column>', '') + '/';
            end;
        end;
        exit(Format(Rows) + ' rows: ' + Result);
    end;

    [Test]
    procedure MaxIterationRecord_One()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI One";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read', Rep.Result());
        Observer.Observe('dataset', DatasetRows(TempBlob));
        Observer.Expect('read', '1,');
        Observer.Expect('dataset', '1 rows: 1/;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationRecord_Three()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI Three";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read', Rep.Result());
        Observer.Observe('dataset', DatasetRows(TempBlob));
        Observer.Expect('read', '1,2,3,');
        Observer.Expect('dataset', '3 rows: 1/;2/;3/;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationRecord_TenOfFive()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI Ten";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read', Rep.Result());
        Observer.Observe('dataset', DatasetRows(TempBlob));
        Observer.Expect('read', '1,2,3,4,5,');
        Observer.Expect('dataset', '5 rows: 1/;2/;3/;4/;5/;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationRecord_TwoWithTableView()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI View";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read', Rep.Result());
        Observer.Observe('dataset', DatasetRows(TempBlob));
        Observer.Expect('read', '2,4,');
        Observer.Expect('dataset', '2 rows: 2/;4/;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationRecord_TwoWithPreDataItemFilter()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI PreFilter";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read', Rep.Result());
        Observer.Observe('dataset', DatasetRows(TempBlob));
        Observer.Expect('read', '3,4,');
        Observer.Expect('dataset', '2 rows: 3/;4/;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationRecord_TwoWithSkip()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI Skip";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read', Rep.Result());
        Observer.Observe('dataset', DatasetRows(TempBlob));
        Observer.Expect('read', '1,2,');
        Observer.Expect('dataset', '1 rows: 2/;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationRecord_NestedLinkedChild()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI Nested";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read', Rep.Result());
        Observer.Observe('dataset', DatasetRows(TempBlob));
        Observer.Expect('read', 'R1,L1.10,R2,L2.10,');
        Observer.Expect('dataset', '4 rows: 1/;10/;2/;10/;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationRecord_RunTwiceSameInstance()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y11 MI Three";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.Observe('read after first run', Rep.Result());
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        asserterror Rep.SaveAs('', ReportFormat::Xml, OutS);
        Observer.ObserveError('second SaveAs on the same instance');
        Observer.Observe('read after the failed second run', Rep.Result());
        Observer.Expect('read after first run', '1,2,3,');
        Observer.Expect('second SaveAs on the same instance|text', 'The object has been run. Use the function CLEAR(Report).');
        Observer.Expect('second SaveAs on the same instance|code', 'ObjectHasAlreadyBeenRun');
        Observer.Expect('read after the failed second run', '1,2,3,');
        Observer.Verify();
    end;
}
