// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71533, log 71534, publisher 71535, report 71536, manual subscriber 71537, test 71538
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: as P141ThisEvent.al but the subscriber codeunit is EventSubscriberInstance = Manual, bound with BindSubscription; without binding no subscriber runs
// Known compile facts (not written): `this` to a var parameter gives AL0130; a Page parameter receiving `this` from a page gives AL0133.
// BC versions: 29 (27 and 28 by CI)

table 71533 "LT P141 M Row"
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

codeunit 71534 "LT P141 M Log"
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

codeunit 71535 "LT P141 M Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnX(Rpt: Report "LT P141 M Rpt"; Where: Text)
    begin
    end;
}

report 71536 "LT P141 M Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P141 M Row")
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
        Pub: Codeunit "LT P141 M Pub";
        Log: Codeunit "LT P141 M Log";

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

codeunit 71537 "LT P141 M Sub"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT P141 M Log";
        Calls: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P141 M Pub", 'OnX', '', false, false)]
    local procedure OnPubX(Rpt: Report "LT P141 M Rpt"; Where: Text)
    begin
        Calls += 1;
        Log.Add('sub#' + Format(Calls) + ' ' + Where + ' sees marker=' + Rpt.GetMarker());
        Rpt.SetMarker('set-by-' + Where + '#' + Format(Calls));
        Log.Add('sub#' + Format(Calls) + ' ' + Where + ' reads back marker=' + Rpt.GetMarker());
    end;

    procedure GetCalls(): Integer
    begin
        exit(Calls);
    end;
}

codeunit 71538 "LT P141 M Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT P141 M Row";
        Log: Codeunit "LT P141 M Log";
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
    procedure P141_Bound_ReportRunsWithSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 M Log";
        Sub: Codeunit "LT P141 M Sub";
        Rpt: Report "LT P141 M Rpt";
    begin
        Seed(2);
        BindSubscription(Sub);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        UnbindSubscription(Sub);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('calls', Format(Sub.GetCalls()));
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Expect('log', 'sub#1 pre sees marker=init | sub#1 pre reads back marker=set-by-pre#1 | report after pre marker=set-by-pre#1 | sub#2 row1 sees marker=set-by-pre#1 | sub#2 row1 reads back marker=set-by-row1#2 | report after row1 marker=set-by-row1#2 | sub#3 row2 sees marker=set-by-row1#2 | sub#3 row2 reads back marker=set-by-row2#3 | report after row2 marker=set-by-row2#3 | sub#4 post sees marker=set-by-row2#3 | sub#4 post reads back marker=set-by-post#4 | report after post marker=set-by-post#4');
        Observer.Expect('calls', '4');
        Observer.Expect('marker after run', '');
        Observer.Verify();
    end;

    [Test]
    procedure P141_NotBound_NoSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 M Log";
        Sub: Codeunit "LT P141 M Sub";
        Rpt: Report "LT P141 M Rpt";
    begin
        Seed(1);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('calls', Format(Sub.GetCalls()));
        Observer.Observe('marker after run', Rpt.GetMarker());
        Observer.Expect('log', 'report after pre marker=init | report after row1 marker=init | report after post marker=init');
        Observer.Expect('calls', '0');
        Observer.Expect('marker after run', '');
        Observer.Verify();
    end;

    [Test]
    procedure P141_BoundThenUnbound_SecondRun()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 M Log";
        Sub: Codeunit "LT P141 M Sub";
        Rpt: Report "LT P141 M Rpt";
    begin
        Seed(1);
        BindSubscription(Sub);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        UnbindSubscription(Sub);
        Observer.Observe('calls after first run', Format(Sub.GetCalls()));
        Observer.Observe('marker after first run', Rpt.GetMarker());
        Rpt.Run();
        Observer.Observe('calls after second run', Format(Sub.GetCalls()));
        Observer.Observe('marker after second run', Rpt.GetMarker());
        Observer.Observe('log', Log.Joined());
        Observer.Expect('calls after first run', '3');
        Observer.Expect('marker after first run', '');
        Observer.Expect('calls after second run', '3');
        Observer.Expect('marker after second run', '');
        Observer.Expect('log', 'sub#1 pre sees marker=init | sub#1 pre reads back marker=set-by-pre#1 | report after pre marker=set-by-pre#1 | sub#2 row1 sees marker=set-by-pre#1 | sub#2 row1 reads back marker=set-by-row1#2 | report after row1 marker=set-by-row1#2 | sub#3 post sees marker=set-by-row1#2 | sub#3 post reads back marker=set-by-post#3 | report after post marker=set-by-post#3 | report after pre marker=init | report after row1 marker=init | report after post marker=init');
        Observer.Verify();
    end;
}
