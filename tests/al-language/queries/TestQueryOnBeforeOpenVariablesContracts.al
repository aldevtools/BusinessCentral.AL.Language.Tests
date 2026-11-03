// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/query/devenv-onbeforeopen-query-trigger
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68450, codeunit 68451 (log), query 68452,
//                codeunit 68453 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins for a query with global variables and an OnBeforeOpen trigger:
//  - OnBeforeOpen runs inside Open, after the filters set so far (CurrQuery.GetFilters shows them);
//    a filter it sets replaces the caller's filter on the same column and applies to that read.
//  - The variables live as long as the query variable: Close and Open keep them (the open count goes
//    1, 2, 3), the filters stay as OnBeforeOpen left them, and Clear starts again at 1 with no filters.
//  - A procedure of the query reads the variables.
// BC versions: 27.5

table 68450 "Probe Query Open Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68451 "Probe Query Open Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

query 68452 "Probe Query Open"
{
    QueryType = Normal;

    elements
    {
        dataitem(T; "Probe Query Open Table")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }
        }
    }

    var
        OpenCount: Integer;

    trigger OnBeforeOpen()
    var
        OpenLog: Codeunit "Probe Query Open Log";
    begin
        OpenCount += 1;
        OpenLog.Add('OnBeforeOpen#' + Format(OpenCount) + ' filters=[' + CurrQuery.GetFilters() + ']');
        if OpenCount = 2 then
            CurrQuery.SetRange(Id, 3);
    end;

    procedure Opens(): Integer
    begin
        exit(OpenCount);
    end;
}

codeunit 68453 "Probe Query Open Variables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Rows(var OpenQuery: Query "Probe Query Open"): Text
    var
        Result: Text;
    begin
        OpenQuery.Open();
        while OpenQuery.Read() do
            Result += Format(OpenQuery.Id) + ' ';
        exit(Result);
    end;

    [Test]
    procedure OnBeforeOpen_SeesTheFilters_CanChangeThem_AndKeepsItsVariables()
    var
        OpenRec: Record "Probe Query Open Table";
        OpenLog: Codeunit "Probe Query Open Log";
        OpenQuery: Query "Probe Query Open";
    begin
        OpenRec.DeleteAll();
        OpenRec.Id := 1;
        OpenRec.Txt := 'a';
        OpenRec.Insert();
        OpenRec.Id := 2;
        OpenRec.Txt := 'b';
        OpenRec.Insert();
        OpenRec.Id := 3;
        OpenRec.Txt := 'c';
        OpenRec.Insert();
        Commit();
        OpenLog.Take();

        OpenQuery.SetFilter(Id, '>=2');
        Assert.AreEqual('2 3 ', Rows(OpenQuery), 'first open');
        Assert.AreEqual('OnBeforeOpen#1 filters=[Id: >=2];', OpenLog.Take(), 'first open log');
        Assert.AreEqual(1, OpenQuery.Opens(), 'first open count');
        OpenQuery.Close();

        Assert.AreEqual('3 ', Rows(OpenQuery), 'second open: the trigger set Id = 3');
        Assert.AreEqual('OnBeforeOpen#2 filters=[Id: >=2];', OpenLog.Take(), 'second open log: the filters it saw');
        OpenQuery.Close();
        Assert.AreEqual('Id: 3', OpenQuery.GetFilters(), 'the filter the trigger set stays');

        Assert.AreEqual('3 ', Rows(OpenQuery), 'third open');
        Assert.AreEqual('OnBeforeOpen#3 filters=[Id: 3];', OpenLog.Take(), 'third open log');
        Assert.AreEqual(3, OpenQuery.Opens(), 'third open count');
        OpenQuery.Close();

        Clear(OpenQuery);
        OpenQuery.Open();
        Assert.AreEqual('OnBeforeOpen#1 filters=[];', OpenLog.Take(), 'after Clear: counting from 1, no filters');
        Assert.AreEqual(1, OpenQuery.Opens(), 'after Clear count');
    end;
}
