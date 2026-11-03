// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71527, log 71528, publisher 71529, report 71530, subscriber 71531, test 71532
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a report passes `this` from OnPreReport, OnAfterGetRecord, OnPostReport to a publisher codeunit event and to its own local event; static subscribers read and change a global through public procedures; same instance?
// Known compile facts (not written): `this` to a var parameter gives AL0130; a Page parameter receiving `this` from a page gives AL0133.
// BC versions: 29 (27 and 28 by CI)

table 71527 "LT P141 E Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71528 "LT P141 E Log"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += ' | ';
            Result += Item;
        end;
        exit(Result);
    end;
}

codeunit 71529 "LT P141 E Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnX(Rpt: Report "LT P141 E Rpt"; Where: Text)
    begin
    end;
}

report 71530 "LT P141 E Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P141 E Row")
        {
            DataItemTableView = sorting(Id);

            trigger OnAfterGetRecord()
            begin
                Pub.OnX(this, 'row' + Format(Row.Id));
                Log.Add('report after row' + Format(Row.Id) + ' marker=' + Marker);
            end;
        }
    }

    var
        Marker: Text;
        Pub: Codeunit "LT P141 E Pub";
        Log: Codeunit "LT P141 E Log";

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure SetMarker(Value: Text)
    begin
        Marker := Value;
    end;

    procedure SetCount(Value: Integer)
    begin
        Hits := Value;
    end;

    procedure GetCount(): Integer
    begin
        exit(Hits);
    end;

    trigger OnPreReport()
    begin
        Marker := 'init';
        Pub.OnX(this, 'pre');
        Log.Add('report after pre marker=' + Marker + ' count=' + Format(Hits));
        OnLocal(this, 'localpre');
        Log.Add('report after localpre marker=' + Marker);
    end;

    trigger OnPostReport()
    begin
        Pub.OnX(this, 'post');
        Log.Add('report after post marker=' + Marker + ' count=' + Format(Hits));
        OnLocal(this, 'localpost');
        Log.Add('report after localpost marker=' + Marker);
    end;

    var
        Hits: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnLocal(Rpt: Report "LT P141 E Rpt"; Where: Text)
    begin
    end;
}

codeunit 71531 "LT P141 E Sub"
{
    var
        Log: Codeunit "LT P141 E Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P141 E Pub", 'OnX', '', false, false)]
    local procedure OnPubX(Rpt: Report "LT P141 E Rpt"; Where: Text)
    begin
        Log.Add('sub pub ' + Where + ' sees marker=' + Rpt.GetMarker() + ' count=' + Format(Rpt.GetCount()));
        Rpt.SetMarker('set-by-' + Where);
        Rpt.SetCount(Rpt.GetCount() + 1);
        Log.Add('sub pub ' + Where + ' reads back marker=' + Rpt.GetMarker() + ' count=' + Format(Rpt.GetCount()));
    end;

    [EventSubscriber(ObjectType::Report, Report::"LT P141 E Rpt", 'OnLocal', '', false, false)]
    local procedure OnReportLocal(Rpt: Report "LT P141 E Rpt"; Where: Text)
    begin
        Log.Add('sub local ' + Where + ' sees marker=' + Rpt.GetMarker() + ' count=' + Format(Rpt.GetCount()));
        Rpt.SetMarker('local-set-by-' + Where);
        Log.Add('sub local ' + Where + ' reads back marker=' + Rpt.GetMarker());
    end;
}

codeunit 71532 "LT P141 E Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT P141 E Row";
        Log: Codeunit "LT P141 E Log";
        i: Integer;
    begin
        Row.DeleteAll();
        Log.Reset();
        for i := 1 to Count do begin
            Row.Id := i;
            Row.Insert();
        end;
    end;

    [Test]
    procedure P141_NoRows_PreAndPost()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 E Log";
        Rpt: Report "LT P141 E Rpt";
    begin
        Seed(0);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Observe('count after run', Format(Rpt.GetCount()));
        Observer.Expect('log', 'sub pub pre sees marker=init count=0 | sub pub pre reads back marker=set-by-pre count=1 | report after pre marker=set-by-pre count=1 | sub local localpre sees marker=set-by-pre count=1 | sub local localpre reads back marker=local-set-by-localpre | report after localpre marker=local-set-by-localpre | sub pub post sees marker=local-set-by-localpre count=1 | sub pub post reads back marker=set-by-post count=2 | report after post marker=set-by-post count=2 | sub local localpost sees marker=set-by-post count=2 | sub local localpost reads back marker=local-set-by-localpost | report after localpost marker=local-set-by-localpost');
        Observer.Expect('marker after run', '');
        Observer.Expect('count after run', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P141_TwoRows_AllPoints()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 E Log";
        Rpt: Report "LT P141 E Rpt";
    begin
        Seed(2);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Observe('count after run', Format(Rpt.GetCount()));
        Observer.Expect('log', 'sub pub pre sees marker=init count=0 | sub pub pre reads back marker=set-by-pre count=1 | report after pre marker=set-by-pre count=1 | sub local localpre sees marker=set-by-pre count=1 | sub local localpre reads back marker=local-set-by-localpre | report after localpre marker=local-set-by-localpre | sub pub row1 sees marker=local-set-by-localpre count=1 | sub pub row1 reads back marker=set-by-row1 count=2 | report after row1 marker=set-by-row1 | sub pub row2 sees marker=set-by-row1 count=2 | sub pub row2 reads back marker=set-by-row2 count=3 | report after row2 marker=set-by-row2 | sub pub post sees marker=set-by-row2 count=3 | sub pub post reads back marker=set-by-post count=4 | report after post marker=set-by-post count=4 | sub local localpost sees marker=set-by-post count=4 | sub local localpost reads back marker=local-set-by-localpost | report after localpost marker=local-set-by-localpost');
        Observer.Expect('marker after run', '');
        Observer.Expect('count after run', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P141_StaticRun_Log()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 E Log";
    begin
        Seed(1);
        Report.Run(Report::"LT P141 E Rpt", false);
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log', 'sub pub pre sees marker=init count=0 | sub pub pre reads back marker=set-by-pre count=1 | report after pre marker=set-by-pre count=1 | sub local localpre sees marker=set-by-pre count=1 | sub local localpre reads back marker=local-set-by-localpre | report after localpre marker=local-set-by-localpre | sub pub row1 sees marker=local-set-by-localpre count=1 | sub pub row1 reads back marker=set-by-row1 count=2 | report after row1 marker=set-by-row1 | sub pub post sees marker=set-by-row1 count=2 | sub pub post reads back marker=set-by-post count=3 | report after post marker=set-by-post count=3 | sub local localpost sees marker=set-by-post count=3 | sub local localpost reads back marker=local-set-by-localpost | report after localpost marker=local-set-by-localpost');
        Observer.Verify();
    end;

    [Test]
    procedure P141_RunModal_Log()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 E Log";
        Rpt: Report "LT P141 E Rpt";
    begin
        Seed(1);
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Expect('log', 'sub pub pre sees marker=init count=0 | sub pub pre reads back marker=set-by-pre count=1 | report after pre marker=set-by-pre count=1 | sub local localpre sees marker=set-by-pre count=1 | sub local localpre reads back marker=local-set-by-localpre | report after localpre marker=local-set-by-localpre | sub pub row1 sees marker=local-set-by-localpre count=1 | sub pub row1 reads back marker=set-by-row1 count=2 | report after row1 marker=set-by-row1 | sub pub post sees marker=set-by-row1 count=2 | sub pub post reads back marker=set-by-post count=3 | report after post marker=set-by-post count=3 | sub local localpost sees marker=set-by-post count=3 | sub local localpost reads back marker=local-set-by-localpost | report after localpost marker=local-set-by-localpost');
        Observer.Expect('marker after run', 'local-set-by-localpost');
        Observer.Verify();
    end;

    [Test]
    procedure P141_SecondRun_SameVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 E Log";
        Rpt: Report "LT P141 E Rpt";
    begin
        Seed(1);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('count after first run', Format(Rpt.GetCount()));
        Rpt.Run();
        Observer.Observe('count after second run', Format(Rpt.GetCount()));
        Observer.Observe('marker after second run', Rpt.GetMarker());
        Observer.Observe('log', Log.Joined());
        Observer.Expect('count after first run', '0');
        Observer.Expect('count after second run', '0');
        Observer.Expect('marker after second run', '');
        Observer.Ignore('log'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure P141_PresetState_SeenBySubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 E Log";
        Rpt: Report "LT P141 E Rpt";
    begin
        Seed(1);
        Rpt.SetCount(40);
        Rpt.SetMarker('preset');
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('count after run', Format(Rpt.GetCount()));
        Observer.Expect('log', 'sub pub pre sees marker=init count=40 | sub pub pre reads back marker=set-by-pre count=41 | report after pre marker=set-by-pre count=41 | sub local localpre sees marker=set-by-pre count=41 | sub local localpre reads back marker=local-set-by-localpre | report after localpre marker=local-set-by-localpre | sub pub row1 sees marker=local-set-by-localpre count=41 | sub pub row1 reads back marker=set-by-row1 count=42 | report after row1 marker=set-by-row1 | sub pub post sees marker=set-by-row1 count=42 | sub pub post reads back marker=set-by-post count=43 | report after post marker=set-by-post count=43 | sub local localpost sees marker=set-by-post count=43 | sub local localpost reads back marker=local-set-by-localpost | report after localpost marker=local-set-by-localpost');
        Observer.Expect('count after run', '0');
        Observer.Verify();
    end;
}
