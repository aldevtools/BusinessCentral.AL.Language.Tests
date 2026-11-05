// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: Cloud-compatible. Fixtures used: Probe Observer (69160), ALT TableFilter Holder (67020); own enums 95980 and 95981,
// table 95982, test codeunit 95983; Base Application page "Table Filter" and table "Table Filter".
// Probe: (al-runner issue 7132) Evaluate of a text into a TableFilter field whose filter is a quoted blank: `''` and `<>''` on a
// Code, a Text, an Enum with a blank member, an Enum without one and an Option with a blank member. What Evaluate returns, what
// Format of the field gives back and the last error. Then, for the forms that evaluate, what the Base Application page
// "Table Filter" lists for them (SetSourceTable, GetFilterFieldsList) and which seeded rows those filters select when set on a
// RecordRef with FieldRef.SetFilter.
// BC versions: 27.5+

enum 95980 "LT R7132 Blank Choice"
{
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; Marked) { Caption = 'Marked Cap'; }
}

enum 95981 "LT R7132 Plain Choice"
{
    Extensible = false;

    value(0; First) { }
    value(1; Second) { }
}

table 95982 "LT R7132 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { DataClassification = SystemMetadata; }
        field(2; Choice; Enum "LT R7132 Blank Choice") { DataClassification = SystemMetadata; }
        field(3; Plain; Enum "LT R7132 Plain Choice") { DataClassification = SystemMetadata; }
        field(4; Opt; Option) { DataClassification = SystemMetadata; OptionMembers = " ",Open,Closed; }
        field(5; Note; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 95983 "LT R7132 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEval(var Holder: Record "ALT TableFilter Holder"; Value: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(Holder."Filter Value", Value);
    end;

    // '<return>|[<Format of the field>]|<last error up to its first backslash>', or 'throws:<text>|<code>'.
    local procedure Eval(Value: Text): Text
    var
        Holder: Record "ALT TableFilter Holder";
        Ok: Boolean;
        Result: Text;
    begin
        ClearLastError();
        if not TryEval(Holder, Value, Ok) then
            Result := 'throws:' + ErrorHead(GetLastErrorText()) + '|' + GetLastErrorCode()
        else
            Result := Format(Ok) + '|[' + Format(Holder."Filter Value") + ']|' + ErrorHead(GetLastErrorText());
        ClearLastError();
        exit(Result);
    end;

    local procedure ErrorHead(Value: Text): Text
    begin
        if StrPos(Value, '\') > 0 then
            Value := CopyStr(Value, 1, StrPos(Value, '\') - 1);
        exit(DelChr(Value, '>', ' '));
    end;

    [Test]
    procedure TableFilterEvaluate_QuotedBlankForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('code_blank', Eval('LT R7132 Row: Code='''''));
        Observer.Observe('code_not_blank', Eval('LT R7132 Row: Code=<>'''''));
        Observer.Observe('text_blank', Eval('LT R7132 Row: Note='''''));
        Observer.Observe('text_not_blank', Eval('LT R7132 Row: Note=<>'''''));
        Observer.Observe('enum_blank', Eval('LT R7132 Row: Choice='''''));
        Observer.Observe('enum_not_blank', Eval('LT R7132 Row: Choice=<>'''''));
        Observer.Observe('enum_no_blank_member', Eval('LT R7132 Row: Plain='''''));
        Observer.Observe('option_blank', Eval('LT R7132 Row: Opt='''''));
        Observer.Observe('option_not_blank', Eval('LT R7132 Row: Opt=<>'''''));
        Observer.Observe('two_conditions', Eval('LT R7132 Row: Code=<>'''',Choice='''''));
        Observer.Finish();
    end;

    // What the "Table Filter" page lists for the field's text, and the codes of the seeded rows its lines select.
    local procedure Applied(Value: Text): Text
    var
        Holder: Record "ALT TableFilter Holder";
        Row: Record "LT R7132 Row";
        Fields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        Ref: RecordRef;
        Fld: FieldRef;
        Listed: Text;
        Codes: Text;
    begin
        Evaluate(Holder."Filter Value", Value);
        FilterPage.SetSourceTable(Format(Holder."Filter Value"), Database::"LT R7132 Row", Row.TableCaption());
        FilterPage.GetFilterFieldsList(Fields);
        Ref.Open(Database::"LT R7132 Row");
        if Fields.FindSet() then
            repeat
                Listed += Format(Fields."Field Number") + '=' + Fields."Field Filter" + ';';
                Fld := Ref.Field(Fields."Field Number");
                Fld.SetFilter(Fields."Field Filter");
            until Fields.Next() = 0;
        if Ref.FindSet() then
            repeat
                Fld := Ref.Field(1);
                Codes += '<' + Format(Fld.Value()) + '>';
            until Ref.Next() = 0;
        Ref.Close();
        exit('[' + Listed + '] ' + Codes);
    end;

    local procedure Seed()
    var
        Row: Record "LT R7132 Row";
    begin
        Row.DeleteAll(false);
        Row.Init();
        Row.Code := '';
        Row.Choice := Row.Choice::Marked;
        Row.Opt := Row.Opt::Open;
        Row.Note := 'X';
        Row.Insert(false);
        Row.Init();
        Row.Code := 'BLANKS';
        Row.Insert(false);
        Row.Init();
        Row.Code := 'MARKED';
        Row.Choice := Row.Choice::Marked;
        Row.Opt := Row.Opt::Closed;
        Row.Note := 'Y';
        Row.Insert(false);
    end;

    [Test]
    procedure TableFilterPage_QuotedBlankForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('code_blank', Applied('LT R7132 Row: Code='''''));
        Observer.Observe('code_not_blank', Applied('LT R7132 Row: Code=<>'''''));
        Observer.Observe('enum_blank', Applied('LT R7132 Row: Choice='''''));
        Observer.Observe('enum_not_blank', Applied('LT R7132 Row: Choice=<>'''''));
        Observer.Finish();
    end;
}
