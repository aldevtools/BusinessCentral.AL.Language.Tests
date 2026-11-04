// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71539, log 71540, helper 71541, report 71542, test 71543
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: `this` as a value parameter of the report type of a codeunit procedure, from OnPreReport, OnAfterGetRecord, OnPostReport and a local procedure of the report; the callee reads and changes a global through public procedures; the callee passes it on again and keeps it in its own global
// Known compile facts (not written): `this` to a var parameter gives AL0130; a Page parameter receiving `this` from a page gives AL0133.
// BC versions: 29 (27 and 28 by CI)

table 71539 "LT P141 V Row"
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

codeunit 71540 "LT P141 V Log"
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

codeunit 71541 "LT P141 V Helper"
{
    var
        Kept: Report "LT P141 V Rpt";
        Log: Codeunit "LT P141 V Log";

    procedure Read(Rpt: Report "LT P141 V Rpt"): Text
    begin
        exit(Rpt.GetMarker());
    end;

    procedure Change(Rpt: Report "LT P141 V Rpt"; Value: Text)
    begin
        Rpt.SetMarker(Value);
    end;

    procedure ChangeAndRead(Rpt: Report "LT P141 V Rpt"; Value: Text): Text
    var
        Before: Text;
    begin
        Before := Rpt.GetMarker();
        Rpt.SetMarker(Value);
        exit(Before + '->' + Rpt.GetMarker());
    end;

    procedure PassOn(Rpt: Report "LT P141 V Rpt"; Value: Text)
    begin
        Change(Rpt, Value + '-via-passon');
    end;

    procedure Keep(Rpt: Report "LT P141 V Rpt")
    begin
        Kept := Rpt;
    end;

    procedure ChangeKept(Value: Text)
    begin
        Kept.SetMarker(Value);
    end;

    procedure ReadKept(): Text
    begin
        exit(Kept.GetMarker());
    end;
}

report 71542 "LT P141 V Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P141 V Row")
        {
            DataItemTableView = sorting(Id);

            trigger OnAfterGetRecord()
            begin
                Log.Add('row' + Format(Row.Id) + ' helper sees=' + Helper.Read(this));
                Helper.Change(this, 'row' + Format(Row.Id));
                Log.Add('row' + Format(Row.Id) + ' report sees=' + Marker);
            end;
        }
    }

    var
        Marker: Text;
        Helper: Codeunit "LT P141 V Helper";
        Log: Codeunit "LT P141 V Log";

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure SetMarker(Value: Text)
    begin
        Marker := Value;
    end;

    local procedure TakeLocal(Rpt: Report "LT P141 V Rpt"; Value: Text)
    begin
        Rpt.SetMarker(Value);
    end;

    trigger OnPreReport()
    begin
        Marker := 'init';
        Log.Add('pre helper sees=' + Helper.Read(this));
        Log.Add('pre change: ' + Helper.ChangeAndRead(this, 'pre-set'));
        Log.Add('pre report sees=' + Marker);
        Helper.PassOn(this, 'pre');
        Log.Add('pre after passon report sees=' + Marker);
        TakeLocal(this, 'local-pre');
        Log.Add('pre after local procedure report sees=' + Marker);
        Helper.Keep(this);
        Helper.ChangeKept('changed-via-kept');
        Log.Add('pre after kept report sees=' + Marker);
    end;

    trigger OnPostReport()
    begin
        Log.Add('post helper sees=' + Helper.Read(this));
        Helper.Change(this, 'post-set');
        Log.Add('post report sees=' + Marker);
        Log.Add('post kept sees=' + Helper.ReadKept());
    end;
}

codeunit 71543 "LT P141 V Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT P141 V Row";
        Log: Codeunit "LT P141 V Log";
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
    procedure P141_ValueParameter_AllPoints()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 V Log";
        Rpt: Report "LT P141 V Rpt";
    begin
        Seed(2);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Expect('log', 'pre helper sees=init | pre change: init->pre-set | pre report sees=pre-set | pre after passon report sees=pre-via-passon | pre after local procedure report sees=local-pre | pre after kept report sees=changed-via-kept | row1 helper sees=changed-via-kept | row1 report sees=row1 | row2 helper sees=row1 | row2 report sees=row2 | post helper sees=row2 | post report sees=post-set | post kept sees=post-set');
        Observer.Expect('marker after run', '');
        Observer.Verify();
    end;

    [Test]
    procedure P141_ValueParameter_KeptByHelperAfterRun()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 V Log";
        Helper: Codeunit "LT P141 V Helper";
        Rpt: Report "LT P141 V Rpt";
    begin
        Seed(0);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('kept after run', Helper.ReadKept());
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Expect('log', 'pre helper sees=init | pre change: init->pre-set | pre report sees=pre-set | pre after passon report sees=pre-via-passon | pre after local procedure report sees=local-pre | pre after kept report sees=changed-via-kept | post helper sees=changed-via-kept | post report sees=post-set | post kept sees=post-set');
        Observer.Expect('kept after run', '');
        Observer.Expect('marker after run', '');
        Observer.Verify();
    end;

    [Test]
    procedure P141_ValueParameter_OutsideARun_TestVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 V Log";
        Helper: Codeunit "LT P141 V Helper";
        Rpt: Report "LT P141 V Rpt";
    begin
        Seed(0);
        Rpt.SetMarker('outside');
        Observer.Observe('helper read', Helper.Read(Rpt));
        Observer.Observe('helper change', Helper.ChangeAndRead(Rpt, 'changed'));
        Observer.Observe('marker after', Rpt.GetMarker());
        Helper.PassOn(Rpt, 'x');
        Observer.Observe('marker after passon', Rpt.GetMarker());
        Helper.Keep(Rpt);
        Helper.ChangeKept('via-kept');
        Observer.Observe('marker after kept change', Rpt.GetMarker());
        Observer.Observe('log', Log.Joined());
        Observer.Expect('helper read', 'outside');
        Observer.Expect('helper change', 'outside->changed');
        Observer.Expect('marker after', 'changed');
        Observer.Expect('marker after passon', 'x-via-passon');
        Observer.Expect('marker after kept change', 'via-kept');
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
