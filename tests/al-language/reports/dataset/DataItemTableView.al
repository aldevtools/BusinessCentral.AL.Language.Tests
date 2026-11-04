// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74473, log 74474, reports 74475 and 74476, test codeunit 74477
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a data item with DataItemTableView where(F = filter(1..2)) run after SetTableView on the report variable with F in 2..3 and with a filter on another field: the filters the item holds in OnPreDataItem (GetFilters), the rows it reads, and the same without a DataItemTableView or without SetTableView.
// BC versions: 29 (27 and 28 by CI)

table 74473 "LT DV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F; Integer) { }
        field(3; G; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74474 "LT DV Log"
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

report 74475 "LT DV With View"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; "LT DV Row")
        {
            DataItemTableView = where(F = filter(1 .. 2));

            trigger OnPreDataItem()
            var
                L: Codeunit "LT DV Log";
            begin
                L.Add('pre filters=[' + Item.GetFilters() + '] count=' + Format(Item.Count()));
            end;

            trigger OnAfterGetRecord()
            var
                L: Codeunit "LT DV Log";
            begin
                L.Add('row ' + Format(Item.Id));
            end;
        }
    }
}

report 74476 "LT DV Without View"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; "LT DV Row")
        {
            trigger OnPreDataItem()
            var
                L: Codeunit "LT DV Log";
            begin
                L.Add('pre filters=[' + Item.GetFilters() + '] count=' + Format(Item.Count()));
            end;

            trigger OnAfterGetRecord()
            var
                L: Codeunit "LT DV Log";
            begin
                L.Add('row ' + Format(Item.Id));
            end;
        }
    }
}

codeunit 74477 "LT DataItem View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT DV Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 4 do begin
            Row.Id := i;
            Row.F := i;
            Row.G := i mod 2;
            Row.Insert();
        end;
    end;

    [Test]
    procedure DataItemTableView_ThenSetTableViewOnOtherRange()
    var
        Row: Record "LT DV Row";
        Rpt: Report "LT DV With View";
        L: Codeunit "LT DV Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        L.Take();
        Row.SetRange(F, 2, 3);
        Rpt.SetTableView(Row);
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('trace', L.Take());
        Observer.Expect('trace', 'pre filters=[F: 2..3] count=1;row 2;');
        Observer.Verify();
    end;

    [Test]
    procedure DataItemTableView_ThenSetTableViewOnOtherField()
    var
        Row: Record "LT DV Row";
        Rpt: Report "LT DV With View";
        L: Codeunit "LT DV Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        L.Take();
        Row.SetRange(G, 0);
        Rpt.SetTableView(Row);
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('trace', L.Take());
        Observer.Expect('trace', 'pre filters=[G: 0] count=1;row 2;');
        Observer.Verify();
    end;

    [Test]
    procedure DataItemTableView_ThenSetTableViewOnBothFields()
    var
        Row: Record "LT DV Row";
        Rpt: Report "LT DV With View";
        L: Codeunit "LT DV Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        L.Take();
        Row.SetRange(F, 2, 3);
        Row.SetRange(G, 0);
        Rpt.SetTableView(Row);
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('trace', L.Take());
        Observer.Expect('trace', 'pre filters=[F: 2..3, G: 0] count=1;row 2;');
        Observer.Verify();
    end;

    [Test]
    procedure DataItemTableView_WithoutSetTableView()
    var
        Rpt: Report "LT DV With View";
        L: Codeunit "LT DV Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        L.Take();
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('trace', L.Take());
        Observer.Expect('trace', 'pre filters=[] count=2;row 1;row 2;');
        Observer.Verify();
    end;

    [Test]
    procedure NoDataItemTableView_SetTableView()
    var
        Row: Record "LT DV Row";
        Rpt: Report "LT DV Without View";
        L: Codeunit "LT DV Log";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        L.Take();
        Row.SetRange(F, 2, 3);
        Rpt.SetTableView(Row);
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('trace', L.Take());
        Observer.Expect('trace', 'pre filters=[F: 2..3] count=2;row 2;row 3;');
        Observer.Verify();
    end;
}
