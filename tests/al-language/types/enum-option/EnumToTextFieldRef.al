// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 71434, table 71435, test codeunit 71436
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: an Enum field read through FieldRef.Value and written into a Text or Code field (FieldRef or Record), into a Text[5] (truncation), through Format (default, format 9, format 0) vs the Evaluate of the stored text; enum captions differ from names, ordinals have gaps (0, 10, 25, 100); setting the Enum field from an Integer ordinal and from the Text through FieldRef.Value.
// BC versions: 29 (27 and 28 by CI)

enum 71434 "LT EnTxt Kind A"
{
    Extensible = true;

    value(0; Zero)
    {
        Caption = 'Zero Caption';
    }
    value(10; Ten)
    {
        Caption = 'Tenth Caption';
    }
    value(25; "Two Words")
    {
        Caption = 'Two Words Caption';
    }
    value(100; Hundred)
    {
        Caption = 'Hundred Caption';
    }
}

table 71435 "LT EnTxt Row A"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT EnTxt Kind A") { }
        field(3; TextVal; Text[50]) { }
        field(4; CodeVal; Code[50]) { }
        field(5; ShortText; Text[5]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71436 "LT Enum To Text FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Kind: Enum "LT EnTxt Kind A")
    var
        R: Record "LT EnTxt Row A";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Kind := Kind;
        R.Insert();
    end;

    [Test]
    procedure FieldRefValue_EnumToTextField_PerMember()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT EnTxt Row A";
        RR: RecordRef;
        KindFr: FieldRef;
        TextFr: FieldRef;
    begin
        Seed(Enum::"LT EnTxt Kind A"::Ten);
        R.Get(1);
        RR.GetTable(R);
        KindFr := RR.Field(R.FieldNo(Kind));
        TextFr := RR.Field(R.FieldNo(TextVal));
        TextFr.Value := KindFr.Value;
        Observer.Observe('Ten -> Text field', Format(TextFr.Value));
        KindFr.Value := Enum::"LT EnTxt Kind A"::"Two Words";
        TextFr.Value := KindFr.Value;
        Observer.Observe('Two Words -> Text field', Format(TextFr.Value));
        KindFr.Value := Enum::"LT EnTxt Kind A"::Hundred;
        TextFr.Value := KindFr.Value;
        Observer.Observe('Hundred -> Text field', Format(TextFr.Value));
        KindFr.Value := Enum::"LT EnTxt Kind A"::Zero;
        TextFr.Value := KindFr.Value;
        Observer.Observe('Zero -> Text field', Format(TextFr.Value));
        Observer.Expect('Ten -> Text field', 'Tenth Caption');
        Observer.Expect('Two Words -> Text field', 'Two Words Caption');
        Observer.Expect('Hundred -> Text field', 'Hundred Caption');
        Observer.Expect('Zero -> Text field', 'Zero Caption');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefValue_EnumToCodeField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT EnTxt Row A";
        RR: RecordRef;
        KindFr: FieldRef;
        CodeFr: FieldRef;
    begin
        Seed(Enum::"LT EnTxt Kind A"::"Two Words");
        R.Get(1);
        RR.GetTable(R);
        KindFr := RR.Field(R.FieldNo(Kind));
        CodeFr := RR.Field(R.FieldNo(CodeVal));
        CodeFr.Value := KindFr.Value;
        Observer.Observe('Two Words -> Code field', Format(CodeFr.Value));
        KindFr.Value := Enum::"LT EnTxt Kind A"::Ten;
        CodeFr.Value := KindFr.Value;
        Observer.Observe('Ten -> Code field', Format(CodeFr.Value));
        Observer.Expect('Two Words -> Code field', 'TWO WORDS CAPTION');
        Observer.Expect('Ten -> Code field', 'TENTH CAPTION');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefValue_EnumToText_VariableAssignment()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT EnTxt Row A";
        RR: RecordRef;
        KindFr: FieldRef;
        Txt: Text;
        V: Variant;
    begin
        Seed(Enum::"LT EnTxt Kind A"::Ten);
        R.Get(1);
        RR.GetTable(R);
        KindFr := RR.Field(R.FieldNo(Kind));
        Txt := Format(KindFr.Value);
        Observer.Observe('Format(FieldRef.Value)', Txt);
        V := KindFr.Value;
        Observer.Observe('Format(Variant)', Format(V));
        Observer.Observe('Variant is Integer', Format(V.IsInteger()));
        Observer.Observe('Variant is Option', Format(V.IsOption()));
        Observer.Observe('Variant is Text', Format(V.IsText()));
        Observer.Observe('Format(FieldRef)', Format(KindFr));
        Observer.Observe('Format(FieldRef, 0, 9)', Format(KindFr, 0, 9));
        Observer.Observe('Format(FieldRef, 0, 1)', Format(KindFr, 0, 1));
        Observer.Observe('FieldRef.Type', Format(KindFr.Type()));
        Observer.Expect('Format(FieldRef.Value)', 'Tenth Caption');
        Observer.Expect('Format(Variant)', 'Tenth Caption');
        Observer.Expect('Variant is Integer', 'No');
        Observer.Expect('Variant is Option', 'Yes');
        Observer.Expect('Variant is Text', 'No');
        Observer.Expect('Format(FieldRef)', 'Tenth Caption');
        Observer.Expect('Format(FieldRef, 0, 9)', '10');
        Observer.Expect('Format(FieldRef, 0, 1)', 'Tenth Caption');
        Observer.Expect('FieldRef.Type', 'Option');
        Observer.Verify();
    end;

    [Test]
    procedure FormatVsEnumAssignmentToText()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT EnTxt Row A";
    begin
        Seed(Enum::"LT EnTxt Kind A"::"Two Words");
        R.Get(1);
        R.TextVal := Format(R.Kind);
        Observer.Observe('Format default', R.TextVal);
        R.TextVal := Format(R.Kind, 0, 9);
        Observer.Observe('Format 9', R.TextVal);
        R.TextVal := Format(R.Kind, 0, 0);
        Observer.Observe('Format 0', R.TextVal);
        R.TextVal := Format(R.Kind, 0, 1);
        Observer.Observe('Format 1', R.TextVal);
        R.TextVal := Format(R.Kind, 0, '<Text,5>');
        Observer.Observe('Format custom text,5', R.TextVal);
        R.TextVal := Format(R.Kind.AsInteger());
        Observer.Observe('Format AsInteger', R.TextVal);
        R.CodeVal := Format(R.Kind);
        Observer.Observe('Code := Format', R.CodeVal);
        Observer.Expect('Format default', 'Two Words Caption');
        Observer.Expect('Format 9', '25');
        Observer.Expect('Format 0', 'Two Words Caption');
        Observer.Expect('Format 1', 'Two Words Caption');
        Observer.Expect('Format custom text,5', 'Two W');
        Observer.Expect('Format AsInteger', '25');
        Observer.Expect('Code := Format', 'TWO WORDS CAPTION');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefValue_SetEnumFromOrdinalAndText()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT EnTxt Row A";
        RR: RecordRef;
        KindFr: FieldRef;
    begin
        Seed(Enum::"LT EnTxt Kind A"::Zero);
        R.Get(1);
        RR.GetTable(R);
        KindFr := RR.Field(R.FieldNo(Kind));
        KindFr.Value := 25;
        Observer.Observe('Integer 25 -> Format', Format(KindFr.Value));
        Observer.Observe('Integer 25 -> AsInteger', Format(R.Kind.AsInteger()));
        RR.SetTable(R);
        Observer.Observe('record after SetTable', Format(R.Kind));
        Observer.Expect('Integer 25 -> Format', 'Two Words Caption');
        Observer.Expect('Integer 25 -> AsInteger', '0');
        Observer.Expect('record after SetTable', 'Two Words Caption');
        Observer.Verify();
    end;
}
