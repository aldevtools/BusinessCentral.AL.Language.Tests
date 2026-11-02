// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93814, test codeunit 93815 (writer Y71, gap cycle 7 spec G7-04)
// Probe: SetView with an empty text constant ('') as an operand inside an `&` expression and next to `|`, on a DateTime field, on the system field
//        SystemCreatedAt and on a Date field: `>''&..<date>`, `>=''&..<date>`, `>''&<date>..`, `>=''&<date>..`, `''|<date>` and `<date>`, the date given as
//        the default text (11/01/25) and as ISO (2025-11-01). Per view: ok or the error text and code, GetView(false) and GetView(true) in filter group
//        10, GetView(false) in filter group 0, GetFilters in group 10 and the ids FindSet visits. The Record form uses the field name.
//        Already pinned nearby: record/lt-y51-setview-shapes/Y51SetViewShapes.al (`<>''` on a Date field, Date values printed as ISO).

table 93814 "LT Y71 SV Tab"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; Dt; DateTime) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93815 "LT Y71 SetView DateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y71 SV Tab";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.D := 20251031D;
        Row.Dt := CreateDateTime(20251031D, 120000T);
        Row.Insert();
        Row.Id := 3;
        Row.D := 20251102D;
        Row.Dt := CreateDateTime(20251102D, 080000T);
        Row.Insert();
    end;

    [TryFunction]
    local procedure TrySetView(var RR: RecordRef; View: Text)
    begin
        RR.FilterGroup := 10;
        RR.SetView(View);
    end;

    local procedure Ids(var RR: RecordRef) Result: Text
    begin
        if RR.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(RR.Field(1).Value);
            until RR.Next() = 0;
    end;

    local procedure SV(Name: Text; View: Text)
    var
        RR: RecordRef;
    begin
        RR.Open(Database::"LT Y71 SV Tab");
        if TrySetView(RR, View) then begin
            RR.FilterGroup := 10;
            Obs.Observe(Name + '|view', RR.GetView(false));
            Obs.Observe(Name + '|view_caption', RR.GetView(true));
            Obs.Observe(Name + '|filters', RR.GetFilters());
            RR.FilterGroup := 0;
            Obs.Observe(Name + '|group0', RR.GetView(false));
            RR.FilterGroup := 10;
            Obs.Observe(Name + '|ids', Ids(RR));
        end else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
        RR.Close();
    end;

    local procedure Forms(FieldNo: Text; Prefix: Text; DateText: Text)
    begin
        SV(Prefix + '_gt_empty_to', StrSubstNo('WHERE(Field%1=1(>''''&..%2))', FieldNo, DateText));
        SV(Prefix + '_ge_empty_to', StrSubstNo('WHERE(Field%1=1(>=''''&..%2))', FieldNo, DateText));
        SV(Prefix + '_gt_empty_from', StrSubstNo('WHERE(Field%1=1(>''''&%2..))', FieldNo, DateText));
        SV(Prefix + '_ge_empty_from', StrSubstNo('WHERE(Field%1=1(>=''''&%2..))', FieldNo, DateText));
        SV(Prefix + '_empty_or', StrSubstNo('WHERE(Field%1=1(''''|%2))', FieldNo, DateText));
        SV(Prefix + '_plain', StrSubstNo('WHERE(Field%1=1(%2))', FieldNo, DateText));
    end;

    [Test]
    procedure SetView_EmptyConstantAnd_DateTime_DefaultDateText()
    begin
        Seed();
        Forms('3', 'dt', '11/01/25');
        Obs.Finish();
    end;

    [Test]
    procedure SetView_EmptyConstantAnd_DateTime_IsoDateText()
    begin
        Seed();
        Forms('3', 'dt_iso', '2025-11-01');
        Obs.Finish();
    end;

    [Test]
    procedure SetView_EmptyConstantAnd_SystemCreatedAt()
    begin
        Seed();
        Forms('2000000001', 'sca', '11/01/25');
        Obs.Finish();
    end;

    [Test]
    procedure SetView_EmptyConstantAnd_SystemCreatedAt_IsoDateText()
    begin
        Seed();
        Forms('2000000001', 'sca_iso', '2025-11-01');
        Obs.Finish();
    end;

    [Test]
    procedure SetView_EmptyConstantAnd_DateField()
    begin
        Seed();
        Forms('2', 'date', '11/01/25');
        Obs.Finish();
    end;

    [Test]
    procedure SetView_EmptyConstantAnd_DateField_IsoDateText()
    begin
        Seed();
        Forms('2', 'date_iso', '2025-11-01');
        Obs.Finish();
    end;

    [Test]
    procedure SetView_RecordForm_FieldName()
    var
        R: Record "LT Y71 SV Tab";
    begin
        Seed();
        R.FilterGroup(10);
        R.SetView('WHERE(Dt=1(>''''&..11/01/25))');
        Obs.Observe('gt_empty_to|view', R.GetView(false));
        Obs.Observe('gt_empty_to|caption', R.GetView(true));
        Obs.Observe('gt_empty_to|count', Format(R.Count()));
        R.Reset();
        R.FilterGroup(10);
        R.SetView('WHERE(Dt=1(>=''''&11/01/25..))');
        Obs.Observe('ge_empty_from|view', R.GetView(false));
        Obs.Observe('ge_empty_from|count', Format(R.Count()));
        R.Reset();
        R.FilterGroup(10);
        R.SetView('WHERE(D=1(>''''&..11/01/25))');
        Obs.Observe('date_gt_empty_to|view', R.GetView(false));
        Obs.Observe('date_gt_empty_to|count', Format(R.Count()));
        Obs.Finish();
    end;
}
