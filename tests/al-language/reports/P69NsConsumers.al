// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), see P69NsTable.al (table 71165), report 71166, query 71167, codeunits 71168 (log) and 71169
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): a dataitem whose table name is namespace qualified
// Facts: report dataitem and query dataitem on a namespaced table, Record variable by using and by qualified name
// BC versions: 29 (27 and 28 by CI)

namespace LT.P69.Consumers;

using LT.P69.Data;

codeunit 71168 "LT P69 Ns Log"
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

report 71166 "LT P69 Ns Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT P69 Ns Row")
        {
            DataItemTableView = sorting(Id);

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT P69 Ns Log";
            begin
                Log.Add('pre:' + Row.TableName() + ':' + Format(Row.Count()));
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT P69 Ns Log";
            begin
                Log.Add(Format(Row.Id) + '=' + Row.Name);
            end;

            trigger OnPostDataItem()
            var
                Log: Codeunit "LT P69 Ns Log";
            begin
                Log.Add('post');
            end;
        }
    }
}

query 71167 "LT P69 Ns Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT P69 Ns Row")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

codeunit 71169 "LT P69 Namespaced Dataitem"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P69 Ns Row";
    begin
        Row.DeleteAll();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Insert();
    end;

    [Test]
    procedure Namespaced_RecordVariable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Ns Row";
        Qualified: Record LT.P69.Data."LT P69 Ns Row";
        RecRef: RecordRef;
    begin
        Seed();
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('tablename', Row.TableName());
        Observer.Observe('tablecaption', Row.TableCaption());
        Qualified.FindFirst();
        Observer.Observe('qualified_first', Qualified.Name);
        RecRef.Open(Database::"LT P69 Ns Row");
        Observer.Observe('recref_name', RecRef.Name());
        Observer.Observe('recref_count', Format(RecRef.Count()));
        Observer.Observe('same_number', Format(Row.RecordId().TableNo() = Database::"LT P69 Ns Row"));
        Observer.Expect('count', '3');
        Observer.Expect('tablename', 'LT P69 Ns Row');
        Observer.Expect('tablecaption', 'LT P69 Ns Row');
        Observer.Expect('qualified_first', 'one');
        Observer.Expect('recref_name', 'LT P69 Ns Row');
        Observer.Expect('recref_count', '3');
        Observer.Expect('same_number', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Namespaced_ReportDataitem()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P69 Ns Log";
        Row: Record "LT P69 Ns Row";
    begin
        Seed();
        Log.Take();
        Row.SetFilter(Id, '>=2');
        Report.Run(Report::"LT P69 Ns Report", false, false, Row);
        Observer.Observe('filtered', Log.Take());
        Report.Run(Report::"LT P69 Ns Report", false, false);
        Observer.Observe('unfiltered', Log.Take());
        Observer.Expect('filtered', 'pre:LT P69 Ns Row:2;2=two;3=three;post;');
        Observer.Expect('unfiltered', 'pre:LT P69 Ns Row:3;1=one;2=two;3=three;post;');
        Observer.Verify();
    end;

    [Test]
    procedure Namespaced_QueryDataitem()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P69 Ns Query";
        Rows: Text;
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.Id) + '=' + Q.Name + ';';
        Q.Close();
        Observer.Observe('rows', Rows);
        Q.SetRange(Id, 1, 2);
        Q.Open();
        Rows := '';
        while Q.Read() do
            Rows += Format(Q.Id) + ';';
        Observer.Observe('filtered', Rows);
        Observer.Expect('rows', '1=one;2=two;3=three;');
        Observer.Expect('filtered', '1;2;');
        Observer.Verify();
    end;

    // Corpus issue 672 item 29 (blog "What's new in BC 27 for developers"): Format of the RecordId of a table declared in a namespace
    // (LT.P69.Data) with no format number and formats 0, 1, 2 and 9; Evaluate of each text back into a RecordId (result | equal),
    // and of the text with the namespace in front of the table name.
    [Test]
    procedure BT_Namespaced_RecordId_Format()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P69 Ns Row";
        RecId: RecordId;
        Back: RecordId;
        Ok: Boolean;
        Standard: Integer;
        Standards: List of [Integer];
    begin
        Seed();
        Standards.AddRange(0, 1, 2, 9);
        Row.Get(2);
        RecId := Row.RecordId();
        Observer.Observe('none', Format(RecId));
        foreach Standard in Standards do begin
            Observer.Observe(Format(Standard), Format(RecId, 0, Standard));
            Clear(Back);
            Ok := Evaluate(Back, Format(RecId, 0, Standard));
            Observer.Observe('evaluate ' + Format(Standard), Format(Ok) + '|' + Format(Back = RecId));
        end;
        Clear(Back);
        Ok := Evaluate(Back, 'LT.P69.Data.LT P69 Ns Row: 2');
        Observer.Observe('evaluate qualified', Format(Ok) + '|' + Format(Back = RecId));
        Clear(Back);
        Ok := Evaluate(Back, 'LT P69 Ns Row: 2');
        Observer.Observe('evaluate plain', Format(Ok) + '|' + Format(Back = RecId));
        Observer.Expect('none', 'LT P69 Ns Row: 2');
        Observer.Expect('0', 'LT P69 Ns Row: 2');
        Observer.Expect('evaluate 0', 'Yes|Yes');
        Observer.Expect('1', 'LT P69 Ns Row: 2');
        Observer.Expect('evaluate 1', 'Yes|Yes');
        Observer.Expect('2', 'LT P69 Ns Row: 2');
        Observer.Expect('evaluate 2', 'Yes|Yes');
        Observer.Expect('9', '[LT.P69.Data.LT P69 Ns Row]: 2');
        Observer.Expect('evaluate 9', 'Yes|Yes');
        Observer.Expect('evaluate qualified', 'No|No');
        Observer.Expect('evaluate plain', 'Yes|Yes');
        Observer.Verify();
    end;
}
