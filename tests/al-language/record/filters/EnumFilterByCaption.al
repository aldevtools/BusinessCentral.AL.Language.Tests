// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter on an Enum field by caption and by name, case-insensitively, a caption equal to another member's name, GetFilter shown text and the SetFilter(F, GetFilter(F)) round trip (assumption enum-filter-by-caption).
// BC versions: 29 (27 and 28 by CI)

enum 70828 "LT EFCap Kind"
{
    Extensible = true;
    value(0; Plain) { Caption = 'Plain'; }
    value(1; First) { Caption = 'Primary Item'; }
    value(2; Second) { Caption = 'Third'; }
    value(3; Third) { Caption = 'Fourth Item'; }
}

table 70651 "LT EFCap Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Kind; Enum "LT EFCap Kind") { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70652 "LT EFCap Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT EFCap Row";
    begin
        Row.DeleteAll();
        Add(1, Row.Kind::Plain);
        Add(2, Row.Kind::First);
        Add(3, Row.Kind::Second);
        Add(4, Row.Kind::Third);
    end;

    local procedure Add(No: Integer; K: Enum "LT EFCap Kind")
    var
        Row: Record "LT EFCap Row";
    begin
        Row."No." := No;
        Row.Kind := K;
        Row.Insert();
    end;

    local procedure FilterCount(var Observer: Codeunit "Probe Observer"; Name: Text; Expr: Text)
    var
        Row: Record "LT EFCap Row";
    begin
        Row.SetFilter(Kind, Expr);
        Observer.Observe(Name + '_count', Format(Row.Count()));
        Observer.Observe(Name + '_getfilter', Row.GetFilter(Kind));
    end;

    local procedure ApplyAndCount(var Row: Record "LT EFCap Row"; Expr: Text)
    begin
        Row.SetFilter(Row.Kind, Expr);
        if Row.Count() < 0 then
            exit;
    end;

    [Test]
    procedure SetFilter_ByName_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT EFCap Row";
    begin
        Seed();
        FilterCount(Observer, 'name_first', 'First');
        FilterCount(Observer, 'name_first_lower', 'first');
        FilterCount(Observer, 'name_first_upper', 'FIRST');
        FilterCount(Observer, 'format_member', Format(Row.Kind::First));
        FilterCount(Observer, 'name_or', 'First|Plain');
        Observer.Expect('name_first_count', '1');
        Observer.Expect('name_first_getfilter', 'Primary Item');
        Observer.Expect('name_first_lower_count', '1');
        Observer.Expect('name_first_lower_getfilter', 'Primary Item');
        Observer.Expect('name_first_upper_count', '1');
        Observer.Expect('name_first_upper_getfilter', 'Primary Item');
        Observer.Expect('format_member_count', '1');
        Observer.Expect('format_member_getfilter', 'Primary Item');
        Observer.Expect('name_or_count', '2');
        Observer.Expect('name_or_getfilter', 'Primary Item|Plain');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_ByCaption_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT EFCap Row";
        AnyHit: Boolean;
    begin
        Seed();
        Row.SetFilter(Kind, 'Primary Item');
        AnyHit := Row.FindFirst();
        Observer.Observe('caption_primary_found', Format(AnyHit));
        FilterCount(Observer, 'caption_primary_lower', 'primary item');
        FilterCount(Observer, 'caption_primary_upper', 'PRIMARY ITEM');
        FilterCount(Observer, 'caption_fourth', 'Fourth Item');
        Observer.Expect('caption_primary_found', 'Yes');
        Observer.Expect('caption_primary_lower_count', '1');
        Observer.Expect('caption_primary_lower_getfilter', 'Primary Item');
        Observer.Expect('caption_primary_upper_count', '1');
        Observer.Expect('caption_primary_upper_getfilter', 'Primary Item');
        Observer.Expect('caption_fourth_count', '1');
        Observer.Expect('caption_fourth_getfilter', 'Fourth Item');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_CaptionEqualsOtherName_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT EFCap Row";
    begin
        Seed();
        FilterCount(Observer, 'third', 'Third');
        Row.SetFilter(Kind, 'Third');
        Row.FindFirst();
        Observer.Observe('third_first_no', Format(Row."No."));
        FilterCount(Observer, 'second', 'Second');
        Observer.Expect('third_count', '1');
        Observer.Expect('third_getfilter', 'Third');
        Observer.Expect('third_first_no', '3');
        Observer.Expect('second_count', '1');
        Observer.Expect('second_getfilter', 'Third');
        Observer.Verify();
    end;

    [Test]
    procedure GetFilter_RoundTrip_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT EFCap Row";
        Copy: Record "LT EFCap Row";
    begin
        Seed();
        Row.SetRange(Kind, Row.Kind::First);
        Observer.Observe('range_getfilter', Row.GetFilter(Kind));
        Copy.SetFilter(Kind, Row.GetFilter(Kind));
        Observer.Observe('roundtrip_count', Format(Copy.Count()));
        Observer.Observe('roundtrip_getfilter', Copy.GetFilter(Kind));
        Copy.Reset();
        Row.SetFilter(Kind, 'First|Second');
        Copy.SetFilter(Kind, Row.GetFilter(Kind));
        Observer.Observe('or_roundtrip_count', Format(Copy.Count()));
        Observer.Observe('or_getfilter', Row.GetFilter(Kind));
        Copy.Reset();
        Row.Reset();
        Row.SetFilter(Kind, '<>Plain');
        Copy.SetFilter(Kind, Row.GetFilter(Kind));
        Observer.Observe('not_plain_roundtrip_count', Format(Copy.Count()));
        Observer.Expect('range_getfilter', 'Primary Item');
        Observer.Expect('roundtrip_count', '1');
        Observer.Expect('roundtrip_getfilter', 'Primary Item');
        Observer.Expect('or_roundtrip_count', '2');
        Observer.Expect('or_getfilter', 'Primary Item|Third');
        Observer.Expect('not_plain_roundtrip_count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_UnknownText_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT EFCap Row";
    begin
        Seed();
        asserterror ApplyAndCount(Row, 'Nonexistent Caption');
        Observer.ObserveError('unknown_text');
        asserterror ApplyAndCount(Row, 'Primary');
        Observer.ObserveError('partial_caption');
        Observer.Expect('unknown_text|text', 'The filter "Nonexistent Caption" is not valid for the Kind field on the LT EFCap Row table. ''Nonexistent Caption'' is not an option. The existing options are: Plain,Primary Item,Third,Fourth Item');
        Observer.Expect('unknown_text|code', 'Filter:CSide');
        Observer.Expect('partial_caption|text', 'The filter "Primary" is not valid for the Kind field on the LT EFCap Row table. ''Primary'' is not an option. The existing options are: Plain,Primary Item,Third,Fourth Item');
        Observer.Expect('partial_caption|code', 'Filter:CSide');
        Observer.Verify();
    end;

    local procedure EvalFromFilter(var Observer: Codeunit "Probe Observer"; Prefix: Text; K: Enum "LT EFCap Kind")
    var
        Row: Record "LT EFCap Row";
        Target: Record "LT EFCap Row";
        Ok: Boolean;
    begin
        Row.SetRange(Kind, K);
        Target.Kind := Target.Kind::Plain;
        Ok := Evaluate(Target.Kind, Row.GetFilter(Kind));
        Observer.Observe(Prefix + ' ' + Format(K.AsInteger()), Row.GetFilter(Kind) + '|' + Format(Ok) + '|' + Format(Target.Kind.AsInteger()));
    end;

    // Corpus issue 672 item 19 (AL issue 4948): Evaluate(EnumField, Other.GetFilter(EnumField)) for a one-value SetRange of each
    // member (GetFilter | Evaluate result | ordinal read back), in the session language and after GlobalLanguage(1031). This app has
    // no translation file, so the captions are the same in both languages.
    [Test]
    procedure BT_Evaluate_FromGetFilter_Language()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
        Ordinal: Integer;
    begin
        Saved := GlobalLanguage();
        foreach Ordinal in "LT EFCap Kind".Ordinals() do
            EvalFromFilter(Observer, '1033', "LT EFCap Kind".FromInteger(Ordinal));
        GlobalLanguage(1031);
        foreach Ordinal in "LT EFCap Kind".Ordinals() do
            EvalFromFilter(Observer, '1031', "LT EFCap Kind".FromInteger(Ordinal));
        GlobalLanguage(Saved);
        Observer.Expect('1033 0', 'Plain|Yes|0');
        Observer.Expect('1033 1', 'Primary Item|Yes|1');
        Observer.Expect('1033 2', 'Third|Yes|2');
        Observer.Expect('1033 3', 'Fourth Item|Yes|3');
        Observer.Expect('1031 0', 'Plain|Ja|0');
        Observer.Expect('1031 1', 'Primary Item|Ja|1');
        Observer.Expect('1031 2', 'Third|Ja|2');
        Observer.Expect('1031 3', 'Fourth Item|Ja|3');
        Observer.Verify();
    end;
}
