// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT P163 RV Log (73247, SingleInstance, used by LT P163 Report View only)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Known pin: misc/lt-probes-needed-3/PnC05ReportRun.al:SetTableView_Forms (sorting-only, range, key plus filter)

table 73246 "LT P163 RV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K1; Txt) { }
    }
}

codeunit 73247 "LT P163 RV Log"
{
    SingleInstance = true;

    var
        Txt: Text;

    procedure Add(Entry: Text)
    begin
        if Txt <> '' then
            Txt += '|';
        Txt += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Txt);
    end;

    procedure Reset()
    begin
        Txt := '';
    end;
}

report 73248 "LT P163 RV Where"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT P163 RV Row")
        {
            DataItemTableView = where(Id = filter(2 .. 4));

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT P163 RV Log";
            begin
                Log.Add('pre:' + Rows.GetFilters() + ';key=' + Rows.CurrentKey());
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT P163 RV Log";
            begin
                Log.Add(Format(Rows.Id));
            end;
        }
    }
}

report 73249 "LT P163 RV Sorted"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT P163 RV Row")
        {
            DataItemTableView = sorting(Txt) order(descending);

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT P163 RV Log";
            begin
                Log.Add('pre:' + Rows.GetFilters() + ';key=' + Rows.CurrentKey());
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT P163 RV Log";
            begin
                Log.Add(Format(Rows.Id));
            end;
        }
    }
}

codeunit 73250 "LT P163 Report View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P163 RV Log";

    local procedure Seed()
    var
        Row: Record "LT P163 RV Row";
    begin
        Row.DeleteAll();
        Add(1, 'd');
        Add(2, 'c');
        Add(3, 'b');
        Add(4, 'a');
        Add(5, 'e');
        Log.Reset();
    end;

    local procedure Add(NewId: Integer; NewTxt: Text)
    var
        Row: Record "LT P163 RV Row";
    begin
        Row.Id := NewId;
        Row.Txt := CopyStr(NewTxt, 1, MaxStrLen(Row.Txt));
        Row.Insert();
    end;

    [Test]
    procedure P163_SetTableView_OverWhere_SameAndOtherField()
    var
        View: Record "LT P163 RV Row";
        Rpt: Report "LT P163 RV Where";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('no_set_table_view', Log.Get());

        Log.Reset();
        View.SetRange(Id, 3, 5);
        Clear(Rpt);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('same_field_3_to_5', Log.Get());

        Log.Reset();
        View.Reset();
        View.SetRange(Txt, 'b');
        Clear(Rpt);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('other_field_Txt_b', Log.Get());

        Log.Reset();
        View.Reset();
        Clear(Rpt);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('no_filter_view', Log.Get());

        Log.Reset();
        View.Reset();
        View.SetRange(Id, 1);
        View.SetFilter(Txt, '<>x');
        Clear(Rpt);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('two_fields_view_outside_where', Log.Get());
        Observer.Expect('no_set_table_view', 'pre:;key=Id|2|3|4');
        Observer.Expect('same_field_3_to_5', 'pre:Id: 3..5;key=Id|3|4');
        Observer.Expect('other_field_Txt_b', 'pre:Txt: b;key=Id|3');
        Observer.Expect('no_filter_view', 'pre:;key=Id|2|3|4');
        Observer.Expect('two_fields_view_outside_where', 'pre:Id: 1, Txt: <>x;key=Id');
        Observer.Verify();
    end;

    [Test]
    procedure P163_SetTableView_OverWhere_KeyOfTheView()
    var
        View: Record "LT P163 RV Row";
        Rpt: Report "LT P163 RV Where";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        View.SetCurrentKey(Txt);
        View.SetRange(Id, 1, 4);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('view_with_key_Txt', Log.Get());
        Observer.Expect('view_with_key_Txt', 'pre:Id: 1..4;key=Txt|4|3|2');
        Observer.Verify();
    end;

    [Test]
    procedure P163_SetTableView_OverSortingDescending()
    var
        View: Record "LT P163 RV Row";
        Rpt: Report "LT P163 RV Sorted";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('no_set_table_view', Log.Get());

        Log.Reset();
        View.SetRange(Id, 2, 4);
        Clear(Rpt);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('range_view', Log.Get());

        Log.Reset();
        View.Reset();
        View.SetCurrentKey(Id);
        View.SetRange(Id, 2, 4);
        Clear(Rpt);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('range_view_with_primary_key', Log.Get());

        Log.Reset();
        View.Reset();
        View.SetCurrentKey(Txt);
        View.SetAscending(Txt, true);
        Clear(Rpt);
        Rpt.SetTableView(View);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('view_key_Txt_ascending', Log.Get());
        Observer.Expect('no_set_table_view', 'pre:;key=Txt|5|1|2|3|4');
        Observer.Expect('range_view', 'pre:Id: 2..4;key=Txt|2|3|4');
        Observer.Expect('range_view_with_primary_key', 'pre:Id: 2..4;key=Txt|2|3|4');
        Observer.Expect('view_key_Txt_ascending', 'pre:;key=Txt|5|1|2|3|4');
        Observer.Verify();
    end;
}
