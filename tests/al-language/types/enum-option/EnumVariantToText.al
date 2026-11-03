// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 71437, table 71438, test codeunit 71439
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a Variant that holds an Enum value (taken from a FieldRef or from the Enum itself) assigned to a Text and a Code variable, and an Enum assigned to a Variant and formatted; the text or the error text and code.
// BC versions: 29 (27 and 28 by CI)

enum 71437 "LT EnTxt Kind B"
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

table 71438 "LT EnTxt Row B"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT EnTxt Kind B") { }
        field(3; TextVal; Text[50]) { }
        field(4; CodeVal; Code[50]) { }
        field(5; ShortText; Text[5]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71439 "LT Enum Variant To Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryVariantToText(V: Variant; var Result: Text)
    begin
        Result := V;
    end;

    [TryFunction]
    local procedure TryVariantToCode(V: Variant; var Result: Code[50])
    begin
        Result := V;
    end;

    [Test]
    procedure Variant_HoldingEnum_ToText()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT EnTxt Kind B";
        V: Variant;
        Txt: Text;
        Ok: Boolean;
    begin
        K := K::Ten;
        V := K;
        Observer.Observe('Format(Variant)', Format(V));
        Observer.Observe('is Text', Format(V.IsText()));
        Observer.Observe('is Integer', Format(V.IsInteger()));
        Ok := TryVariantToText(V, Txt);
        Observer.Observe('Text := Variant ok', Format(Ok));
        Observer.Observe('Text := Variant', Txt);
        Observer.ObserveError('Text := Variant');
        Observer.Expect('Format(Variant)', 'Tenth Caption');
        Observer.Expect('is Text', 'No');
        Observer.Expect('is Integer', 'No');
        Observer.Expect('Text := Variant ok', 'No');
        Observer.Expect('Text := Variant', '');
        Observer.Expect('Text := Variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('Text := Variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_HoldingEnum_ToCode()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT EnTxt Kind B";
        V: Variant;
        C: Code[50];
        Ok: Boolean;
    begin
        K := K::"Two Words";
        V := K;
        Ok := TryVariantToCode(V, C);
        Observer.Observe('Code := Variant ok', Format(Ok));
        Observer.Observe('Code := Variant', C);
        Observer.ObserveError('Code := Variant');
        Observer.Expect('Code := Variant ok', 'No');
        Observer.Expect('Code := Variant', '');
        Observer.Expect('Code := Variant|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('Code := Variant|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_FromFieldRef_ToText()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT EnTxt Row B";
        RR: RecordRef;
        KindFr: FieldRef;
        Txt: Text;
        Ok: Boolean;
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Kind := Enum::"LT EnTxt Kind B"::Hundred;
        R.Insert();
        RR.GetTable(R);
        KindFr := RR.Field(R.FieldNo(Kind));
        Ok := TryVariantToText(KindFr.Value, Txt);
        Observer.Observe('Text := FieldRef.Value ok', Format(Ok));
        Observer.Observe('Text := FieldRef.Value', Txt);
        Observer.ObserveError('Text := FieldRef.Value');
        Observer.Expect('Text := FieldRef.Value ok', 'No');
        Observer.Expect('Text := FieldRef.Value', '');
        Observer.Expect('Text := FieldRef.Value|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('Text := FieldRef.Value|code', 'TypeConversion');
        Observer.Verify();
    end;
}
