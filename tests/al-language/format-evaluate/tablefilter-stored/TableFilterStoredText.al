// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), ALT TableFilter Holder; own enum 96900, table 96901, test codeunit 96902; Base Application page "Table Filter"
// Probe: (al-runner issues 7188 and 7190 follow-up) the text a TableFilter field stores for single conditions on Text, Decimal, Code, Boolean and
// Enum fields, and the rows each stored text selects when its lines are applied to a RecordRef through the page "Table Filter".
// Facts per condition: the text of Evaluate into the field (or the error), Format of the field, the field number and filter text of each line of
// the page, RecordRef.GetFilters after applying them, and the keys of the selected rows (or the error text).
// BC versions: 27.5, 28.5, 29.0
enum 96900 "LT TF Kind"
{
    Extensible = false;

    value(0; A) { }
    value(1; B) { }
    value(5; E) { }
}

table 96901 "LT TF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { DataClassification = SystemMetadata; }
        field(2; Txt; Text[50]) { DataClassification = SystemMetadata; }
        field(3; Dec; Decimal) { DataClassification = SystemMetadata; }
        field(4; Cod; Code[20]) { DataClassification = SystemMetadata; }
        field(5; Bool; Boolean) { DataClassification = SystemMetadata; }
        field(6; Kind; Enum "LT TF Kind") { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 96902 "LT TF Stored Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TableFilter_Text_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Txt=''''');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Text_NotEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Txt=<>''''');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Text_QuestionStar()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Txt=?*');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Text_PrefixStar()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Txt=x*');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Decimal_NotZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Dec=<>0');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Decimal_NotFive()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Dec=<>5');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Decimal_QuotedGE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Dec=">=100000"');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Decimal_PlainGE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Dec=>=100000');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Decimal_QuotedGroupedGE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Dec=">=100,000"');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Decimal_UnquotedGroupedGE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Dec=>=100,000');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Code_Prefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Cod=CORP*');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Code_NotPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Cod=<>CORP*');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Code_LowerPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Cod=corp*');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Boolean_Yes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Bool=Yes');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Boolean_NoCapital()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Bool=No');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Boolean_NoLower()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Bool=no');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Boolean_False()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Bool=false');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Boolean_True()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Bool=true');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Enum_NoMember7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Kind=7');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Enum_NoMember10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Kind=10');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Enum_NoMember2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Kind=2');
        Observer.Finish();
    end;

    [Test]
    procedure TableFilter_Enum_Member5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Probe(Observer, 'c', 'Kind=5');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryEvaluate(var Holder: Record "ALT TableFilter Holder"; Condition: Text)
    begin
        Evaluate(Holder."Filter Value", 'LT TF Row: ' + Condition);
    end;

    [TryFunction]
    local procedure TryApply(Stored: Text; var Lines: Text; var AppliedFilters: Text; var Keys: Text)
    var
        Row: Record "LT TF Row";
        Fields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        FilterPage.SetSourceTable(Stored, Database::"LT TF Row", Row.TableCaption());
        FilterPage.GetFilterFieldsList(Fields);
        Ref.Open(Database::"LT TF Row");
        if Fields.FindSet() then
            repeat
                if Lines <> '' then
                    Lines += ' | ';
                Lines += Format(Fields."Field Number") + '=' + Fields."Field Filter";
                Fld := Ref.Field(Fields."Field Number");
                Fld.SetFilter(Fields."Field Filter");
            until Fields.Next() = 0;
        AppliedFilters := Ref.GetFilters();
        if Ref.FindSet() then
            repeat
                if Keys <> '' then
                    Keys += ',';
                Keys += Format(Ref.Field(1).Value());
            until Ref.Next() = 0;
        Ref.Close();
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Condition: Text)
    var
        Holder: Record "ALT TableFilter Holder";
        Stored: Text;
        Lines: Text;
        AppliedFilters: Text;
        Keys: Text;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        if not TryEvaluate(Holder, Condition) then begin
            Observer.ObserveError(Name + ' evaluate');
            GlobalLanguage(PreviousLanguage);
            exit;
        end;
        Stored := Format(Holder."Filter Value");
        Observer.Observe(Name + ' stored', Stored);
        if not TryApply(Stored, Lines, AppliedFilters, Keys) then begin
            Observer.Observe(Name + ' lines before error', Lines);
            Observer.ObserveError(Name + ' apply');
            GlobalLanguage(PreviousLanguage);
            exit;
        end;
        Observer.Observe(Name + ' lines', Lines);
        Observer.Observe(Name + ' filters', AppliedFilters);
        Observer.Observe(Name + ' keys', Keys);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure Initialize()
    var
        Row: Record "LT TF Row";
    begin
        Row.DeleteAll(false);
        Row.Id := 1;
        Row.Txt := '';
        Row.Dec := 0;
        Row.Cod := 'OTHER';
        Row.Bool := false;
        Row.Kind := Row.Kind::A;
        Row.Insert(false);
        Row.Id := 2;
        Row.Txt := 'x1';
        Row.Dec := 5;
        Row.Cod := 'CORP01';
        Row.Bool := true;
        Row.Kind := Row.Kind::B;
        Row.Insert(false);
        Row.Id := 3;
        Row.Txt := 'xy';
        Row.Dec := 100000;
        Row.Cod := 'corp02';
        Row.Bool := true;
        Row.Kind := Row.Kind::E;
        Row.Insert(false);
        Row.Id := 4;
        Row.Txt := 'abc';
        Row.Dec := 100001;
        Row.Cod := 'CORP03';
        Row.Bool := false;
        Row.Kind := Row.Kind::A;
        Row.Insert(false);
        Row.Id := 5;
        Row.Txt := 'X';
        Row.Dec := 99999;
        Row.Cod := '';
        Row.Bool := true;
        Row.Kind := Row.Kind::B;
        Row.Insert(false);
    end;
}
