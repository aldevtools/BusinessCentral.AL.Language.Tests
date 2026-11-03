// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained enum 73875, tables 73876 to 73879, codeunit 73880
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "TransferFields between an Enum field and an Option field of the same field number" (Tests-SCM round 2)
// Facts: TransferFields from an Enum field to an Option field and back, with ordinals both sides have and with an ordinal the target lacks; the error of a Boolean field and a Text field of the same number
// BC versions: 29 (27 and 28 by CI)

enum 73875 "LT PnF TF Enum"
{
    Extensible = false;

    value(0; Alpha) { }
    value(1; Beta) { }
    value(2; Gamma) { }
    value(10; Far) { }
}

table 73876 "LT PnF TF Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT PnF TF Enum") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 73877 "LT PnF TF Option Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = Alpha,Beta; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 73878 "LT PnF TF Bool Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 73879 "LT PnF TF Text Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73880 "LT PnF Transfer Enum Opt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEnumToOption(var Dst: Record "LT PnF TF Option Row"; Src: Record "LT PnF TF Enum Row")
    begin
        Dst.TransferFields(Src);
    end;

    [TryFunction]
    local procedure TryOptionToEnum(var Dst: Record "LT PnF TF Enum Row"; Src: Record "LT PnF TF Option Row")
    begin
        Dst.TransferFields(Src);
    end;

    [TryFunction]
    local procedure TryBoolToText(var Dst: Record "LT PnF TF Text Row"; Src: Record "LT PnF TF Bool Row")
    begin
        Dst.TransferFields(Src);
    end;

    [TryFunction]
    local procedure TryTextToBool(var Dst: Record "LT PnF TF Bool Row"; Src: Record "LT PnF TF Text Row")
    begin
        Dst.TransferFields(Src);
    end;

    [Test]
    procedure Transfer_EnumToOption()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT PnF TF Enum Row";
        O: Record "LT PnF TF Option Row";
    begin
        E.Id := 5;
        E.Kind := E.Kind::Beta;
        if TryEnumToOption(O, E) then
            Observer.Observe('beta', Format(O.Id) + '|' + Format(O.Kind) + '|' + Format(O.Kind, 0, 2))
        else
            Observer.ObserveError('beta');
        Clear(O);
        E.Kind := E.Kind::Alpha;
        if TryEnumToOption(O, E) then
            Observer.Observe('alpha', Format(O.Kind) + '|' + Format(O.Kind, 0, 2))
        else
            Observer.ObserveError('alpha');
        Clear(O);
        E.Kind := E.Kind::Gamma;
        if TryEnumToOption(O, E) then
            Observer.Observe('gamma_lacking', Format(O.Kind, 0, 2))
        else
            Observer.ObserveError('gamma_lacking');
        Clear(O);
        E.Kind := E.Kind::Far;
        if TryEnumToOption(O, E) then
            Observer.Observe('far_lacking', Format(O.Kind, 0, 2))
        else
            Observer.ObserveError('far_lacking');
        Observer.Expect('beta', '5|Beta|1');
        Observer.Expect('alpha', 'Alpha|0');
        Observer.Expect('gamma_lacking', '2');
        Observer.Expect('far_lacking', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_OptionToEnum()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "LT PnF TF Enum Row";
        O: Record "LT PnF TF Option Row";
    begin
        O.Id := 6;
        O.Kind := O.Kind::Beta;
        if TryOptionToEnum(E, O) then
            Observer.Observe('beta', Format(E.Id) + '|' + Format(E.Kind) + '|' + Format(E.Kind.AsInteger()))
        else
            Observer.ObserveError('beta');
        Clear(E);
        O.Kind := O.Kind::Alpha;
        if TryOptionToEnum(E, O) then
            Observer.Observe('alpha', Format(E.Kind) + '|' + Format(E.Kind.AsInteger()))
        else
            Observer.ObserveError('alpha');
        Clear(E);
        O.Kind := 1;
        if TryOptionToEnum(E, O) then
            Observer.Observe('one', Format(E.Kind))
        else
            Observer.ObserveError('one');
        Observer.Expect('beta', '6|Beta|1');
        Observer.Expect('alpha', 'Alpha|0');
        Observer.Expect('one', 'Beta');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_EnumToEnum_SameType()
    var
        Observer: Codeunit "Probe Observer";
        E1: Record "LT PnF TF Enum Row";
        E2: Record "LT PnF TF Enum Row";
    begin
        E1.Id := 1;
        E1.Kind := E1.Kind::Far;
        E2.TransferFields(E1);
        Observer.Observe('far', Format(E2.Kind) + '|' + Format(E2.Kind.AsInteger()));
        Observer.Expect('far', 'Far|10');
        Observer.Verify();
    end;

    [Test]
    procedure Transfer_BooleanAndText()
    var
        Observer: Codeunit "Probe Observer";
        B: Record "LT PnF TF Bool Row";
        T: Record "LT PnF TF Text Row";
    begin
        B.Flag := true;
        if TryBoolToText(T, B) then
            Observer.Observe('bool_to_text', T.Flag)
        else
            Observer.ObserveError('bool_to_text');
        T.Flag := 'Yes';
        if TryTextToBool(B, T) then
            Observer.Observe('text_to_bool', Format(B.Flag))
        else
            Observer.ObserveError('text_to_bool');
        Observer.Expect('bool_to_text|text', 'The following fields must have the same type:\\Field: Flag <-- Flag\Table: LT PnF TF Text Row <-- LT PnF TF Bool Row\Type: Text <-- Boolean');
        Observer.Expect('bool_to_text|code', 'DB:TypeMisMatch');
        Observer.Expect('text_to_bool|text', 'The following fields must have the same type:\\Field: Flag <-- Flag\Table: LT PnF TF Bool Row <-- LT PnF TF Text Row\Type: Boolean <-- Text');
        Observer.Expect('text_to_bool|code', 'DB:TypeMisMatch');
        Observer.Verify();
    end;
}
