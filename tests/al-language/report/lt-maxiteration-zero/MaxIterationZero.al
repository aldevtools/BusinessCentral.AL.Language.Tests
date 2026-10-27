// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-maxiteration-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71405, reports 71406 and 71407, log codeunit 71404
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: MaxIteration = 0 on a table data item with three rows and on an Integer item bounded by a filter (the filter bounds the run, so it cannot hang); whether 0 means unlimited or none.
// BC versions: 29 (27 and 28 by CI)

codeunit 71404 "LT MaxIterZero Log"
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

table 71405 "LT MaxIterZero Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 71406 "LT MaxIterZero Rep Table"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT MaxIterZero Row")
        {
            DataItemTableView = sorting(Id);
            MaxIteration = 0;

            trigger OnAfterGetRecord()
            begin
                L.Add('row ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post');
            end;
        }
    }

    var
        L: Codeunit "LT MaxIterZero Log";
}

report 71407 "LT MaxIterZero Rep Integer"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            MaxIteration = 0;

            trigger OnAfterGetRecord()
            begin
                L.Add('num ' + Format(Num.Number));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('post');
            end;
        }
    }

    var
        L: Codeunit "LT MaxIterZero Log";
}

codeunit 71408 "LT MaxIter Zero"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT MaxIterZero Log";

    [Test]
    procedure MaxIterationZero_TableItem_ThreeRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT MaxIterZero Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Id := i;
            Row.Insert();
        end;
        L.Take();
        Report.Run(Report::"LT MaxIterZero Rep Table");
        Observer.Observe('table item max 0', L.Take());
        Observer.Expect('table item max 0', 'row 1;row 2;row 3;post;');
        Observer.Verify();
    end;

    [Test]
    procedure MaxIterationZero_IntegerItem_FilteredToThree()
    var
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        Report.Run(Report::"LT MaxIterZero Rep Integer");
        Observer.Observe('integer item max 0', L.Take());
        Observer.Expect('integer item max 0', 'num 1;num 2;num 3;post;');
        Observer.Verify();
    end;

    // ---- Writer SG (2026-10-27): MaxIteration > 0 on a table data item (reports 89366-89369 in SgMaxIterationTable.al), five rows. ----

    local procedure SgFiveRows()
    var
        Row: Record "LT MaxIterZero Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 5 do begin
            Row.Id := i;
            Row.Insert();
        end;
        L.Take();
    end;

    [Test]
    procedure SG_MaxIterationTwo_TableItem_FiveRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgFiveRows();
        Report.Run(Report::"LT SG MaxIter Table Two");
        Observer.Observe('max 2 of 5', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SG_MaxIterationTwo_TableItem_SkipFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgFiveRows();
        Report.Run(Report::"LT SG MaxIter Table Skip");
        Observer.Observe('max 2, skip row 1', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SG_MaxIteration_TableItem_FewerRowsAndDescending()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgFiveRows();
        Report.Run(Report::"LT SG MaxIter Table Few Desc");
        Observer.Observe('max 10 of 2, then max 2 descending', L.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SG_MaxIteration_TableItem_WithChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgFiveRows();
        Report.Run(Report::"LT SG MaxIter Table Child");
        Observer.Observe('parent max 2, child max 1', L.Take());
        Observer.Finish();
    end;
}
