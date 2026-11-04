// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71544, log 71545, publisher 71546, report 71547, reportextension 71548, subscriber 71549, test 71550
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a reportextension adds global variables and public procedures to the report; the subscriber calls the extension's procedures on the received base report parameter and reads the added global; `this` passed from OnPreReport, OnAfterGetRecord, OnPostReport. RISKY: calling extension procedures on a base report variable may not compile
// Known compile facts (not written): `this` to a var parameter gives AL0130; a Page parameter receiving `this` from a page gives AL0133.
// BC versions: 29 (27 and 28 by CI)

table 71544 "LT P141 X Row"
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

codeunit 71545 "LT P141 X Log"
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

codeunit 71546 "LT P141 X Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnX(Rpt: Report "LT P141 X Rpt"; Where: Text)
    begin
    end;
}

report 71547 "LT P141 X Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P141 X Row")
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
        Pub: Codeunit "LT P141 X Pub";
        Log: Codeunit "LT P141 X Log";

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure SetMarker(Value: Text)
    begin
        Marker := Value;
    end;

    trigger OnPreReport()
    begin
        Marker := 'init';
        Pub.OnX(this, 'pre');
        Log.Add('report after pre marker=' + Marker);
    end;

    trigger OnPostReport()
    begin
        Pub.OnX(this, 'post');
        Log.Add('report after post marker=' + Marker);
    end;
}

reportextension 71548 "LT P141 X Ext" extends "LT P141 X Rpt"
{
    var
        ExtText: Text;
        ExtNumber: Integer;

    procedure GetExtText(): Text
    begin
        exit(ExtText);
    end;

    procedure SetExtText(Value: Text)
    begin
        ExtText := Value;
    end;

    procedure BumpExt(): Integer
    begin
        ExtNumber += 1;
        exit(ExtNumber);
    end;

    procedure ReadBoth(): Text
    begin
        exit(GetMarker() + '/' + ExtText + '/' + Format(ExtNumber));
    end;

    trigger OnPreReport()
    begin
        ExtText := 'ext-init';
        Log.Add('ext OnPreReport marker=' + GetMarker());
    end;

    var
        Log: Codeunit "LT P141 X Log";
}

codeunit 71549 "LT P141 X Sub"
{
    var
        Log: Codeunit "LT P141 X Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P141 X Pub", 'OnX', '', false, false)]
    local procedure OnPubX(Rpt: Report "LT P141 X Rpt"; Where: Text)
    begin
        Log.Add('sub ' + Where + ' base marker=' + Rpt.GetMarker() + ' ext text=' + Rpt.GetExtText());
        Rpt.SetExtText('ext-set-by-' + Where);
        Rpt.SetMarker('marker-set-by-' + Where);
        Log.Add('sub ' + Where + ' bump=' + Format(Rpt.BumpExt()) + ' both=' + Rpt.ReadBoth());
    end;
}

codeunit 71550 "LT P141 X Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT P141 X Row";
        Log: Codeunit "LT P141 X Log";
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
    procedure P141_ExtensionMembers_ThroughEventParameter()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 X Log";
        Rpt: Report "LT P141 X Rpt";
    begin
        Seed(2);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Observe('ext text after run', Rpt.GetExtText());
        Observer.Observe('both after run', Rpt.ReadBoth());
        Observer.Expect('log', 'sub pre base marker=init ext text= | sub pre bump=1 both=marker-set-by-pre/ext-set-by-pre/1 | report after pre marker=marker-set-by-pre | ext OnPreReport marker=marker-set-by-pre | sub row1 base marker=marker-set-by-pre ext text=ext-init | sub row1 bump=2 both=marker-set-by-row1/ext-set-by-row1/2 | report after row1 marker=marker-set-by-row1 | sub row2 base marker=marker-set-by-row1 ext text=ext-set-by-row1 | sub row2 bump=3 both=marker-set-by-row2/ext-set-by-row2/3 | report after row2 marker=marker-set-by-row2 | sub post base marker=marker-set-by-row2 ext text=ext-set-by-row2 | sub post bump=4 both=marker-set-by-post/ext-set-by-post/4 | report after post marker=marker-set-by-post');
        Observer.Expect('marker after run', '');
        Observer.Expect('ext text after run', '');
        Observer.Expect('both after run', '//0');
        Observer.Verify();
    end;

    [Test]
    procedure P141_ExtensionMembers_StaticRun()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 X Log";
    begin
        Seed(1);
        Report.Run(Report::"LT P141 X Rpt", false);
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log', 'sub pre base marker=init ext text= | sub pre bump=1 both=marker-set-by-pre/ext-set-by-pre/1 | report after pre marker=marker-set-by-pre | ext OnPreReport marker=marker-set-by-pre | sub row1 base marker=marker-set-by-pre ext text=ext-init | sub row1 bump=2 both=marker-set-by-row1/ext-set-by-row1/2 | report after row1 marker=marker-set-by-row1 | sub post base marker=marker-set-by-row1 ext text=ext-set-by-row1 | sub post bump=3 both=marker-set-by-post/ext-set-by-post/3 | report after post marker=marker-set-by-post');
        Observer.Verify();
    end;

    [Test]
    procedure P141_ExtensionMembers_BeforeAnyRun()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P141 X Rpt";
    begin
        Observer.Observe('ext text initial', Rpt.GetExtText());
        Observer.Observe('bump', Format(Rpt.BumpExt()));
        Rpt.SetExtText('abc');
        Observer.Observe('both', Rpt.ReadBoth());
        Observer.Expect('ext text initial', '');
        Observer.Expect('bump', '1');
        Observer.Expect('both', '/abc/1');
        Observer.Verify();
    end;
}
