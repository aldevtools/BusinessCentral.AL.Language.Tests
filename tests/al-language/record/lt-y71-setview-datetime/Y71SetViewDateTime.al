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
        Obs.Expect('dt_gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_gt_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_gt_empty_to|filters', 'Dt: >''''&..11/01/25 11:59:59 PM');
        Obs.Expect('dt_gt_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_gt_empty_to|ids', '2');
        Obs.Expect('dt_ge_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_ge_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_ge_empty_to|filters', 'Dt: >=''''&..11/01/25 11:59:59 PM');
        Obs.Expect('dt_ge_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_ge_empty_to|ids', '1,2');
        Obs.Expect('dt_gt_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_gt_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_gt_empty_from|filters', 'Dt: >''''&11/01/25 12:00 AM..');
        Obs.Expect('dt_gt_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_gt_empty_from|ids', '3');
        Obs.Expect('dt_ge_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_ge_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_ge_empty_from|filters', 'Dt: >=''''&11/01/25 12:00 AM..');
        Obs.Expect('dt_ge_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_ge_empty_from|ids', '3');
        Obs.Expect('dt_empty_or|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_empty_or|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_empty_or|filters', 'Dt: ''''..''''|11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('dt_empty_or|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_empty_or|ids', '1');
        Obs.Expect('dt_plain|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_plain|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_plain|filters', 'Dt: 11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('dt_plain|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_plain|ids', '');
        Obs.Verify();
    end;




    [Test]
    procedure SetView_EmptyConstantAnd_DateTime_IsoDateText()
    begin
        Seed();
        Forms('3', 'dt_iso', '2025-11-01');
        Obs.Expect('dt_iso_gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_gt_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_gt_empty_to|filters', 'Dt: >''''&..11/01/25 11:59:59 PM');
        Obs.Expect('dt_iso_gt_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_iso_gt_empty_to|ids', '2');
        Obs.Expect('dt_iso_ge_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_ge_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_ge_empty_to|filters', 'Dt: >=''''&..11/01/25 11:59:59 PM');
        Obs.Expect('dt_iso_ge_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_iso_ge_empty_to|ids', '1,2');
        Obs.Expect('dt_iso_gt_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_iso_gt_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_iso_gt_empty_from|filters', 'Dt: >''''&11/01/25 12:00 AM..');
        Obs.Expect('dt_iso_gt_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_iso_gt_empty_from|ids', '3');
        Obs.Expect('dt_iso_ge_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_iso_ge_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('dt_iso_ge_empty_from|filters', 'Dt: >=''''&11/01/25 12:00 AM..');
        Obs.Expect('dt_iso_ge_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_iso_ge_empty_from|ids', '3');
        Obs.Expect('dt_iso_empty_or|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_empty_or|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_empty_or|filters', 'Dt: ''''..''''|11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('dt_iso_empty_or|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_iso_empty_or|ids', '1');
        Obs.Expect('dt_iso_plain|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_plain|view_caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('dt_iso_plain|filters', 'Dt: 11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('dt_iso_plain|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('dt_iso_plain|ids', '');
        Obs.Verify();
    end;




    [Test]
    procedure SetView_EmptyConstantAnd_SystemCreatedAt()
    begin
        Seed();
        Forms('2000000001', 'sca', '11/01/25');
        Obs.Expect('sca_gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_gt_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_gt_empty_to|filters', 'Created At: >''''&..11/01/25 11:59:59 PM');
        Obs.Expect('sca_gt_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_gt_empty_to|ids', '');
        Obs.Expect('sca_ge_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_ge_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_ge_empty_to|filters', 'Created At: >=''''&..11/01/25 11:59:59 PM');
        Obs.Expect('sca_ge_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_ge_empty_to|ids', '');
        Obs.Expect('sca_gt_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_gt_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_gt_empty_from|filters', 'Created At: >''''&11/01/25 12:00 AM..');
        Obs.Expect('sca_gt_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_gt_empty_from|ids', '1,2,3');
        Obs.Expect('sca_ge_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_ge_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_ge_empty_from|filters', 'Created At: >=''''&11/01/25 12:00 AM..');
        Obs.Expect('sca_ge_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_ge_empty_from|ids', '1,2,3');
        Obs.Expect('sca_empty_or|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_empty_or|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_empty_or|filters', 'Created At: ''''..''''|11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('sca_empty_or|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_empty_or|ids', '');
        Obs.Expect('sca_plain|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_plain|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_plain|filters', 'Created At: 11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('sca_plain|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_plain|ids', '');
        Obs.Verify();
    end;




    [Test]
    procedure SetView_EmptyConstantAnd_SystemCreatedAt_IsoDateText()
    begin
        Seed();
        Forms('2000000001', 'sca_iso', '2025-11-01');
        Obs.Expect('sca_iso_gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_gt_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_gt_empty_to|filters', 'Created At: >''''&..11/01/25 11:59:59 PM');
        Obs.Expect('sca_iso_gt_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_iso_gt_empty_to|ids', '');
        Obs.Expect('sca_iso_ge_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_ge_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>=''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_ge_empty_to|filters', 'Created At: >=''''&..11/01/25 11:59:59 PM');
        Obs.Expect('sca_iso_ge_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_iso_ge_empty_to|ids', '');
        Obs.Expect('sca_iso_gt_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_iso_gt_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_iso_gt_empty_from|filters', 'Created At: >''''&11/01/25 12:00 AM..');
        Obs.Expect('sca_iso_gt_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_iso_gt_empty_from|ids', '1,2,3');
        Obs.Expect('sca_iso_ge_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_iso_ge_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('sca_iso_ge_empty_from|filters', 'Created At: >=''''&11/01/25 12:00 AM..');
        Obs.Expect('sca_iso_ge_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_iso_ge_empty_from|ids', '1,2,3');
        Obs.Expect('sca_iso_empty_or|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_empty_or|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(''''..''''|2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_empty_or|filters', 'Created At: ''''..''''|11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('sca_iso_empty_or|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_iso_empty_or|ids', '');
        Obs.Expect('sca_iso_plain|view', 'VERSION(1) SORTING(Field1) WHERE(Field2000000001=1(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_plain|view_caption', 'VERSION(1) SORTING(Id) WHERE(Created At=FILTER(2025-11-01T00:00:00Z..2025-11-01T23:59:59Z))');
        Obs.Expect('sca_iso_plain|filters', 'Created At: 11/01/25 12:00 AM..11/01/25 11:59:59 PM');
        Obs.Expect('sca_iso_plain|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('sca_iso_plain|ids', '');
        Obs.Verify();
    end;




    [Test]
    procedure SetView_EmptyConstantAnd_DateField()
    begin
        Seed();
        Forms('2', 'date', '11/01/25');
        Obs.Expect('date_gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>''''&..2025-11-01))');
        Obs.Expect('date_gt_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>''''&..2025-11-01))');
        Obs.Expect('date_gt_empty_to|filters', 'D: >''''&..11/01/25');
        Obs.Expect('date_gt_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_gt_empty_to|ids', '2');
        Obs.Expect('date_ge_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>=''''&..2025-11-01))');
        Obs.Expect('date_ge_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>=''''&..2025-11-01))');
        Obs.Expect('date_ge_empty_to|filters', 'D: >=''''&..11/01/25');
        Obs.Expect('date_ge_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_ge_empty_to|ids', '1,2');
        Obs.Expect('date_gt_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>''''&2025-11-01..))');
        Obs.Expect('date_gt_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>''''&2025-11-01..))');
        Obs.Expect('date_gt_empty_from|filters', 'D: >''''&11/01/25..');
        Obs.Expect('date_gt_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_gt_empty_from|ids', '3');
        Obs.Expect('date_ge_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>=''''&2025-11-01..))');
        Obs.Expect('date_ge_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>=''''&2025-11-01..))');
        Obs.Expect('date_ge_empty_from|filters', 'D: >=''''&11/01/25..');
        Obs.Expect('date_ge_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_ge_empty_from|ids', '3');
        Obs.Expect('date_empty_or|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(''''|2025-11-01))');
        Obs.Expect('date_empty_or|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(''''|2025-11-01))');
        Obs.Expect('date_empty_or|filters', 'D: ''''|11/01/25');
        Obs.Expect('date_empty_or|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_empty_or|ids', '1');
        Obs.Expect('date_plain|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(2025-11-01))');
        Obs.Expect('date_plain|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(2025-11-01))');
        Obs.Expect('date_plain|filters', 'D: 11/01/25');
        Obs.Expect('date_plain|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_plain|ids', '');
        Obs.Verify();
    end;




    [Test]
    procedure SetView_EmptyConstantAnd_DateField_IsoDateText()
    begin
        Seed();
        Forms('2', 'date_iso', '2025-11-01');
        Obs.Expect('date_iso_gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>''''&..2025-11-01))');
        Obs.Expect('date_iso_gt_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>''''&..2025-11-01))');
        Obs.Expect('date_iso_gt_empty_to|filters', 'D: >''''&..11/01/25');
        Obs.Expect('date_iso_gt_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_iso_gt_empty_to|ids', '2');
        Obs.Expect('date_iso_ge_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>=''''&..2025-11-01))');
        Obs.Expect('date_iso_ge_empty_to|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>=''''&..2025-11-01))');
        Obs.Expect('date_iso_ge_empty_to|filters', 'D: >=''''&..11/01/25');
        Obs.Expect('date_iso_ge_empty_to|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_iso_ge_empty_to|ids', '1,2');
        Obs.Expect('date_iso_gt_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>''''&2025-11-01..))');
        Obs.Expect('date_iso_gt_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>''''&2025-11-01..))');
        Obs.Expect('date_iso_gt_empty_from|filters', 'D: >''''&11/01/25..');
        Obs.Expect('date_iso_gt_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_iso_gt_empty_from|ids', '3');
        Obs.Expect('date_iso_ge_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>=''''&2025-11-01..))');
        Obs.Expect('date_iso_ge_empty_from|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(>=''''&2025-11-01..))');
        Obs.Expect('date_iso_ge_empty_from|filters', 'D: >=''''&11/01/25..');
        Obs.Expect('date_iso_ge_empty_from|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_iso_ge_empty_from|ids', '3');
        Obs.Expect('date_iso_empty_or|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(''''|2025-11-01))');
        Obs.Expect('date_iso_empty_or|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(''''|2025-11-01))');
        Obs.Expect('date_iso_empty_or|filters', 'D: ''''|11/01/25');
        Obs.Expect('date_iso_empty_or|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_iso_empty_or|ids', '1');
        Obs.Expect('date_iso_plain|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(2025-11-01))');
        Obs.Expect('date_iso_plain|view_caption', 'VERSION(1) SORTING(Id) WHERE(D=FILTER(2025-11-01))');
        Obs.Expect('date_iso_plain|filters', 'D: 11/01/25');
        Obs.Expect('date_iso_plain|group0', 'VERSION(1) SORTING(Field1)');
        Obs.Expect('date_iso_plain|ids', '');
        Obs.Verify();
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
        Obs.Expect('gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('gt_empty_to|caption', 'VERSION(1) SORTING(Id) WHERE(Dt=FILTER(>''''&..2025-11-01T23:59:59Z))');
        Obs.Expect('gt_empty_to|count', '1');
        Obs.Expect('ge_empty_from|view', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(>=''''&2025-11-01T00:00:00Z..))');
        Obs.Expect('ge_empty_from|count', '1');
        Obs.Expect('date_gt_empty_to|view', 'VERSION(1) SORTING(Field1) WHERE(Field2=1(>''''&..2025-11-01))');
        Obs.Expect('date_gt_empty_to|count', '1');
        Obs.Verify();
    end;
}
