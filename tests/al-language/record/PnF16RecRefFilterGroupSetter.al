// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73897, codeunit 73898
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "RecRef.FilterGroup := n" (Tests-SCM round 2)
// Facts: RecordRef.FilterGroup := n as the setter form and RecordRef.FilterGroup(n) as the call form: the group read back, which filters GetFilters shows in each group, Record.FilterGroup := n for comparison
// BC versions: 29 (27 and 28 by CI)

table 73897 "LT PnF RFG Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73898 "LT PnF RecRef FilterGroup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnF RFG Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 6 do begin
            Row.Id := i;
            Row.Grp := i mod 3;
            Row.Insert();
        end;
    end;

    [Test]
    procedure RecRef_FilterGroup_Setter()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT PnF RFG Row");
        RecRef.Field(1).SetRange(1, 4);
        Observer.Observe('group_initial', Format(RecRef.FilterGroup()));
        RecRef.FilterGroup := 2;
        Observer.Observe('group_after_setter', Format(RecRef.FilterGroup()));
        Observer.Observe('filters_in_g2', RecRef.GetFilters());
        RecRef.Field(2).SetRange(1);
        Observer.Observe('filters_g2_set', RecRef.GetFilters());
        Observer.Observe('count_g2', Format(RecRef.Count()));
        RecRef.FilterGroup := 0;
        Observer.Observe('group_back', Format(RecRef.FilterGroup()));
        Observer.Observe('filters_g0', RecRef.GetFilters());
        Observer.Observe('count_g0', Format(RecRef.Count()));
        RecRef.Close();
        Observer.Expect('group_initial', '0');
        Observer.Expect('group_after_setter', '2');
        Observer.Expect('filters_in_g2', '');
        Observer.Expect('filters_g2_set', 'Grp: 1');
        Observer.Expect('count_g2', '2');
        Observer.Expect('group_back', '0');
        Observer.Expect('filters_g0', 'Id: 1..4');
        Observer.Expect('count_g0', '2');
        Observer.Verify();
    end;

    [Test]
    procedure RecRef_FilterGroup_CallForm()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT PnF RFG Row");
        RecRef.Field(1).SetRange(1, 4);
        Observer.Observe('previous_returned', Format(RecRef.FilterGroup(2)));
        Observer.Observe('group_after_call', Format(RecRef.FilterGroup()));
        RecRef.Field(2).SetRange(1);
        Observer.Observe('count_g2', Format(RecRef.Count()));
        Observer.Observe('previous_returned_back', Format(RecRef.FilterGroup(0)));
        Observer.Observe('count_g0', Format(RecRef.Count()));
        RecRef.Close();
        Observer.Expect('previous_returned', '2');
        Observer.Expect('group_after_call', '2');
        Observer.Expect('count_g2', '2');
        Observer.Expect('previous_returned_back', '0');
        Observer.Expect('count_g0', '2');
        Observer.Verify();
    end;

    [Test]
    procedure RecRef_FilterGroup_SetterValues()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        g: Integer;
    begin
        Seed();
        RecRef.Open(Database::"LT PnF RFG Row");
        for g := 0 to 4 do begin
            RecRef.FilterGroup := g;
            Observer.Observe('set_' + Format(g), Format(RecRef.FilterGroup()));
        end;
        RecRef.FilterGroup := 0;
        RecRef.Close();
        Observer.Expect('set_0', '0');
        Observer.Expect('set_1', '1');
        Observer.Expect('set_2', '2');
        Observer.Expect('set_3', '3');
        Observer.Expect('set_4', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Record_FilterGroup_Setter_Comparison()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF RFG Row";
    begin
        Seed();
        Row.SetRange(Id, 1, 4);
        Row.FilterGroup := 2;
        Observer.Observe('group', Format(Row.FilterGroup()));
        Row.SetRange(Grp, 1);
        Observer.Observe('count_g2', Format(Row.Count()));
        Row.FilterGroup := 0;
        Observer.Observe('count_g0', Format(Row.Count()));
        Observer.Observe('filters_g0', Row.GetFilters());
        Observer.Expect('group', '2');
        Observer.Expect('count_g2', '2');
        Observer.Expect('count_g0', '2');
        Observer.Expect('filters_g0', 'Id: 1..4');
        Observer.Verify();
    end;
}
