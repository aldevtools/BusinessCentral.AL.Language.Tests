// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67169 "LT SV Caption"
// Probe: SetView and GetView where a field's Caption differs from its name. Field "Line No." has the caption 'Primary Key'; field Alpha has the caption 'Beta'
// and field Beta has the caption 'Gamma' (a caption equal to another field's name). SetView(GetView()) after SetRange, SetView with the caption in WHERE and
// SORTING, GetView(false), and which field a name that is also a caption selects. Settles: set-view-field-by-caption. Object ids 67169 - 67170.

table 67169 "LT SV Caption"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { Caption = 'Primary Key'; }
        field(2; Alpha; Integer) { Caption = 'Beta'; }
        field(3; Beta; Integer) { Caption = 'Gamma'; }
        field(4; Note; Code[10]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
        key(ByAlpha; Alpha) { }
    }
}

codeunit 67170 "LT SV Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT SV Caption";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 4 do begin
            Row.Init();
            Row."Line No." := Index;
            Row.Alpha := Index * 10;
            Row.Beta := 5 - Index;
            Row.Note := 'N' + Format(Index);
            Row.Insert();
        end;
    end;

    local procedure Ids(var Row: Record "LT SV Caption"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row."Line No.") + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetView(var Row: Record "LT SV Caption"; View: Text)
    begin
        Row.SetView(View);
    end;

    local procedure ViewOutcome(View: Text): Text
    var
        Row: Record "LT SV Caption";
    begin
        ClearLastError();
        if not TrySetView(Row, View) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok:view=' + Row.GetView() + '|plain=' + Row.GetView(false) + '|filters=' + Row.GetFilters() + '|ids=' + Ids(Row));
    end;

    [Test]
    procedure GetView_UsesCaptionsOrNames()
    var
        Row: Record "LT SV Caption";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange("Line No.", 2);
        Observer.Observe('line_no_view', Row.GetView());
        Observer.Observe('line_no_view_plain', Row.GetView(false));
        Observer.Observe('line_no_filters', Row.GetFilters());
        Row.Reset();
        Row.SetRange(Alpha, 20);
        Observer.Observe('alpha_view', Row.GetView());
        Observer.Observe('alpha_view_plain', Row.GetView(false));
        Row.Reset();
        Row.SetRange(Beta, 3);
        Observer.Observe('beta_view', Row.GetView());
        Observer.Observe('beta_view_plain', Row.GetView(false));
        Row.Reset();
        Row.SetCurrentKey(Alpha);
        Observer.Observe('sorting_view', Row.GetView());
        Observer.Observe('sorting_view_plain', Row.GetView(false));
        Observer.Expect('line_no_view', 'VERSION(1) SORTING(Primary Key) WHERE(Primary Key=FILTER(2))');
        Observer.Expect('line_no_view_plain', 'VERSION(1) SORTING(Field1) WHERE(Field1=1(2))');
        Observer.Expect('line_no_filters', 'Primary Key: 2');
        Observer.Expect('alpha_view', 'VERSION(1) SORTING(Primary Key) WHERE(Beta=FILTER(20))');
        Observer.Expect('alpha_view_plain', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(20))');
        Observer.Expect('beta_view', 'VERSION(1) SORTING(Primary Key) WHERE(Gamma=FILTER(3))');
        Observer.Expect('beta_view_plain', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(3))');
        Observer.Expect('sorting_view', 'VERSION(1) SORTING(Beta)');
        Observer.Expect('sorting_view_plain', 'VERSION(1) SORTING(Field2)');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_RoundTripOfGetView()
    var
        Row: Record "LT SV Caption";
        Other: Record "LT SV Caption";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetRange("Line No.", 2, 3);
        Row.SetRange(Beta, 2, 3);
        Other.SetView(Row.GetView());
        Observer.Observe('round_trip_view', Other.GetView());
        Observer.Observe('round_trip_ids', Ids(Other));
        Other.Reset();
        Other.SetView(Row.GetView(false));
        Observer.Observe('round_trip_plain_view', Other.GetView());
        Observer.Observe('round_trip_plain_ids', Ids(Other));
        Observer.Expect('round_trip_view', 'VERSION(1) SORTING(Primary Key) WHERE(Primary Key=FILTER(2..3),Gamma=FILTER(2..3))');
        Observer.Expect('round_trip_ids', '2,3,');
        Observer.Expect('round_trip_plain_view', 'VERSION(1) SORTING(Primary Key) WHERE(Primary Key=FILTER(2..3),Gamma=FILTER(2..3))');
        Observer.Expect('round_trip_plain_ids', '2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_CaptionInWhere()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('name_line_no', ViewOutcome('WHERE("Line No."=FILTER(2))'));
        Observer.Observe('caption_primary_key', ViewOutcome('WHERE(Primary Key=FILTER(2))'));
        Observer.Observe('caption_primary_key_quoted', ViewOutcome('WHERE("Primary Key"=FILTER(2))'));
        Observer.Observe('caption_gamma', ViewOutcome('WHERE(Gamma=FILTER(3))'));
        Observer.Observe('name_alpha', ViewOutcome('WHERE(Alpha=FILTER(20))'));
        Observer.Observe('name_beta_is_also_a_caption', ViewOutcome('WHERE(Beta=FILTER(20))'));
        Observer.Observe('name_beta_value_3', ViewOutcome('WHERE(Beta=FILTER(3))'));
        Observer.Expect('name_line_no', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Primary Key=FILTER(2))|plain=VERSION(1) SORTING(Field1) WHERE(Field1=1(2))|filters=Primary Key: 2|ids=2,');
        Observer.Expect('caption_primary_key', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Primary Key=FILTER(2))|plain=VERSION(1) SORTING(Field1) WHERE(Field1=1(2))|filters=Primary Key: 2|ids=2,');
        Observer.Expect('caption_primary_key_quoted', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Primary Key=FILTER(2))|plain=VERSION(1) SORTING(Field1) WHERE(Field1=1(2))|filters=Primary Key: 2|ids=2,');
        Observer.Expect('caption_gamma', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Gamma=FILTER(3))|plain=VERSION(1) SORTING(Field1) WHERE(Field3=1(3))|filters=Gamma: 3|ids=2,');
        Observer.Expect('name_alpha', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Beta=FILTER(20))|plain=VERSION(1) SORTING(Field1) WHERE(Field2=1(20))|filters=Beta: 20|ids=2,');
        Observer.Expect('name_beta_is_also_a_caption', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Gamma=FILTER(20))|plain=VERSION(1) SORTING(Field1) WHERE(Field3=1(20))|filters=Gamma: 20|ids=');
        Observer.Expect('name_beta_value_3', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Gamma=FILTER(3))|plain=VERSION(1) SORTING(Field1) WHERE(Field3=1(3))|filters=Gamma: 3|ids=2,');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_CaptionInSorting()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('sorting_name', ViewOutcome('SORTING(Alpha)'));
        Observer.Observe('sorting_caption_of_alpha', ViewOutcome('SORTING(Beta)'));
        Observer.Observe('sorting_caption_primary_key', ViewOutcome('SORTING(Primary Key)'));
        Observer.Observe('sorting_and_where_caption', ViewOutcome('SORTING(Primary Key) WHERE(Primary Key=FILTER(2..3))'));
        Observer.Expect('sorting_name', 'ok:view=VERSION(1) SORTING(Beta)|plain=VERSION(1) SORTING(Field2)|filters=|ids=1,2,3,4,');
        Observer.Expect('sorting_caption_of_alpha', 'ok:view=VERSION(1) SORTING(Gamma)|plain=VERSION(1) SORTING(Field3)|filters=|ids=4,3,2,1,');
        Observer.Expect('sorting_caption_primary_key', 'ok:view=VERSION(1) SORTING(Primary Key)|plain=VERSION(1) SORTING(Field1)|filters=|ids=1,2,3,4,');
        Observer.Expect('sorting_and_where_caption', 'ok:view=VERSION(1) SORTING(Primary Key) WHERE(Primary Key=FILTER(2..3))|plain=VERSION(1) SORTING(Field1) WHERE(Field1=1(2..3))|filters=Primary Key: 2..3|ids=2,3,');
        Observer.Verify();
    end;
}
