// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope. SetFilter on an Option field and an Enum field with a value that is no member (and with members, captions and numbers as controls), under GlobalLanguage 1033 and 1030.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75404-75406 (LT GL NM Color, LT GL NM Row, LT GL Filter NonMember)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
// BC versions: 27, 28, 29

enum 75404 "LT GL NM Color"
{
    Extensible = true;
    value(0; Red) { }
    value(1; Green) { Caption = 'Verde'; }
    value(2; Blue) { }
}

table 75405 "LT GL NM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Kind; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(3; Color; Enum "LT GL NM Color") { }
        field(4; Size; Option) { OptionMembers = S,M,L; OptionCaption = 'Small,Medium,Large'; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 75406 "LT GL Filter NonMember"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetFilter(var Row: Record "LT GL NM Row"; FieldNo: Integer; Filter: Text)
    begin
        case FieldNo of
            2:
                Row.SetFilter(Kind, Filter);
            3:
                Row.SetFilter(Color, Filter);
            4:
                Row.SetFilter(Size, Filter);
        end;
    end;

    local procedure Seed()
    var
        Row: Record "LT GL NM Row";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Kind := Row.Kind::Alpha;
        Row.Color := Row.Color::Red;
        Row.Size := Row.Size::S;
        Row.Insert();
        Row."Code" := 'B';
        Row.Kind := Row.Kind::Beta;
        Row.Color := Row.Color::Green;
        Row.Size := Row.Size::M;
        Row.Insert();
        Row."Code" := 'C';
        Row.Kind := Row.Kind::Gamma;
        Row.Color := Row.Color::Blue;
        Row.Size := Row.Size::L;
        Row.Insert();
    end;

    // ok|GetFilter|count, or the error text and code
    local procedure Probe(FieldNo: Integer; Filter: Text): Text
    var
        Row: Record "LT GL NM Row";
    begin
        ClearLastError();
        if not TrySetFilter(Row, FieldNo, Filter) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok|' + Row.GetFilters() + '|count=' + Format(Row.Count()));
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Lang: Integer; FieldNo: Integer; Filters: List of [Text])
    var
        Results: List of [Text];
        F: Text;
        I: Integer;
    begin
        Seed();
        GlobalLanguage(Lang);
        foreach F in Filters do
            Results.Add(Probe(FieldNo, F));
        GlobalLanguage(1033);
        for I := 1 to Filters.Count() do
            Observer.Observe('[' + Filters.Get(I) + ']', Results.Get(I));
    end;

    local procedure OptionNonMember(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('Delta', 'Alpha|Delta', 'Delta..Gamma', '<>Delta', 'beta', '7', '-1', '1');
        Run(Observer, Lang, 2, Filters);
    end;

    local procedure OptionCaptionNonMember(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('XL', 'Small', 'M', 'Medium|L', 'Huge..Large');
        Run(Observer, Lang, 4, Filters);
    end;

    local procedure EnumNonMember(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Filters: List of [Text];
    begin
        Filters.AddRange('Purple', 'Red|Purple', '<>Purple', 'Verde', 'Green', 'blue', '9', '2');
        Run(Observer, Lang, 3, Filters);
    end;

    [Test]
    procedure Option_NonMember_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OptionNonMember(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure Option_NonMember_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OptionNonMember(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure OptionCaption_NonMember_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OptionCaptionNonMember(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure OptionCaption_NonMember_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OptionCaptionNonMember(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure Enum_NonMember_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EnumNonMember(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure Enum_NonMember_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EnumNonMember(Observer, 1030);
        Observer.Finish();
    end;
}
