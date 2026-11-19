// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

enum 74934 "LT VarNum Kind"
{
    Extensible = true;

    value(0; Zero)
    {
        Caption = 'Zero Caption';
    }
    value(10; "Ten Name")
    {
        Caption = 'Ten Caption';
    }
}

table 74935 "LT VarNum Opt Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; "Text Value"; Text[50]) { }
        field(3; "Code Value"; Code[50]) { }
        field(4; Choice; Option)
        {
            OptionMembers = " ",First,"Second Item";
            OptionCaption = ' ,First Caption,Second Caption';
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 74936 "LT VarNum Enum Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryText(V: Variant; var Row: Record "LT VarNum Opt Row")
    begin
        Row."Text Value" := V;
    end;

    [TryFunction]
    local procedure TryCode(V: Variant; var Row: Record "LT VarNum Opt Row")
    begin
        Row."Code Value" := V;
    end;

    [TryFunction]
    local procedure TryVar(V: Variant; var T: Text)
    begin
        T := V;
    end;

    local procedure ToTextField(V: Variant): Text
    var
        Row: Record "LT VarNum Opt Row";
    begin
        if TryText(V, Row) then
            exit('ok:' + Row."Text Value");
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure ToCodeField(V: Variant): Text
    var
        Row: Record "LT VarNum Opt Row";
    begin
        if TryCode(V, Row) then
            exit('ok:' + Row."Code Value");
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure ToTextVar(V: Variant): Text
    var
        T: Text;
    begin
        if TryVar(V, T) then
            exit('ok:' + T);
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure TextField_FromVariantEnum_Result()
    var
        Observer: Codeunit "Probe Observer";
        Kind: Enum "LT VarNum Kind";
    begin
        Kind := Kind::"Ten Name";
        Observer.Observe('text field', ToTextField(Kind));
        Observer.Observe('code field', ToCodeField(Kind));
        Observer.Observe('text variable', ToTextVar(Kind));
        Observer.Observe('format', Format(Kind));
        Kind := Kind::Zero;
        Observer.Observe('zero text field', ToTextField(Kind));
        Observer.Observe('zero text variable', ToTextVar(Kind));
        Observer.Expect('text field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('code field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('text variable', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('format', 'Ten Caption');
        Observer.Expect('zero text field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('zero text variable', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_FromVariantOption_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum Opt Row";
        Opt: Option " ",First,"Second Item";
    begin
        Opt := Opt::"Second Item";
        Observer.Observe('text field', ToTextField(Opt));
        Observer.Observe('code field', ToCodeField(Opt));
        Observer.Observe('text variable', ToTextVar(Opt));
        Observer.Observe('format', Format(Opt));
        Opt := Opt::" ";
        Observer.Observe('blank text field', ToTextField(Opt));
        Row.Choice := Row.Choice::First;
        Observer.Observe('table option text field', ToTextField(Row.Choice));
        Observer.Observe('table option format', Format(Row.Choice));
        Observer.Expect('text field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('code field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('text variable', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('format', 'Second Item');
        Observer.Expect('blank text field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('table option text field', 'error:TypeConversion:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('table option format', 'First Caption');
        Observer.Verify();
    end;

    // Measured on BC 27.5.46862.58266, 28.5.54976.58543 and 29.1.57326.58275.
    [Test]
    procedure FieldRef_Value_OptionToTextAndCode_UsesCaption()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT VarNum Opt Row" temporary;
        Target: Record "LT VarNum Opt Row" temporary;
        Ref: RecordRef;
        Field: FieldRef;
        TextValue: Text[50];
        CodeValue: Code[50];
    begin
        Initialize();
        Source.Choice := Source.Choice::First;
        Ref.GetTable(Source);
        Field := Ref.Field(4);
        Target."Text Value" := Field.Value();
        Target."Code Value" := Field.Value();
        TextValue := Field.Value();
        CodeValue := Field.Value();
        Observer.Observe('text field', Target."Text Value");
        Observer.Observe('code field', Target."Code Value");
        Observer.Observe('text variable', TextValue);
        Observer.Observe('code variable', CodeValue);
        Source.Choice := Source.Choice::" ";
        Ref.GetTable(Source);
        Field := Ref.Field(4);
        Target."Text Value" := Field.Value();
        Target."Code Value" := Field.Value();
        TextValue := Field.Value();
        CodeValue := Field.Value();
        Observer.Observe('blank text field', Target."Text Value");
        Observer.Observe('blank code field', Target."Code Value");
        Observer.Observe('blank text variable', TextValue);
        Observer.Observe('blank code variable', CodeValue);
        Observer.Expect('text field', 'First Caption');
        Observer.Expect('code field', 'FIRST CAPTION');
        Observer.Expect('text variable', 'First Caption');
        Observer.Expect('code variable', 'FIRST CAPTION');
        Observer.Expect('blank text field', ' ');
        Observer.Expect('blank code field', '');
        Observer.Expect('blank text variable', ' ');
        Observer.Expect('blank code variable', '');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_OptionToTextAndCode_DirectAssignmentErrors()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT VarNum Opt Row" temporary;
        Target: Record "LT VarNum Opt Row" temporary;
        Ref: RecordRef;
        Field: FieldRef;
        V: Variant;
        I: Integer;
    begin
        Initialize();
        for I := 0 to 1 do begin
            Source.Choice := I;
            Ref.GetTable(Source);
            Field := Ref.Field(4);
            V := Field.Value();
            ObserveVariantErrors(Observer, Target, V, Format(I) + ' fieldref');
            V := Source.Choice;
            ObserveVariantErrors(Observer, Target, V, Format(I) + ' option');
            if TryReturnedText(Target, Field) then
                Error('Text assignment unexpectedly succeeded');
            Observer.Observe(Format(I) + ' return text', GetLastErrorText());
            if TryReturnedCode(Target, Field) then
                Error('Code assignment unexpectedly succeeded');
            Observer.Observe(Format(I) + ' return code', GetLastErrorText());
            if TryReturnedOptionText(Target, Source) then
                Error('Text assignment unexpectedly succeeded');
            Observer.Observe(Format(I) + ' option return text', GetLastErrorText());
            if TryReturnedOptionCode(Target, Source) then
                Error('Code assignment unexpectedly succeeded');
            Observer.Observe(Format(I) + ' option return code', GetLastErrorText());
        end;
        ExpectVariantErrors(Observer, '0 fieldref');
        ExpectVariantErrors(Observer, '0 option');
        ExpectVariantErrors(Observer, '0 return');
        ExpectVariantErrors(Observer, '0 option return');
        ExpectVariantErrors(Observer, '1 fieldref');
        ExpectVariantErrors(Observer, '1 option');
        ExpectVariantErrors(Observer, '1 return');
        ExpectVariantErrors(Observer, '1 option return');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRef_Value_VariantOptionToTextAndCode_UsesCaption()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT VarNum Opt Row" temporary;
        Target: Record "LT VarNum Opt Row" temporary;
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        Field: FieldRef;
        TargetField: FieldRef;
        V: Variant;
        I: Integer;
    begin
        Initialize();
        for I := 0 to 1 do begin
            Source.Choice := I;
            SourceRef.GetTable(Source);
            Field := SourceRef.Field(4);
            TargetRef.GetTable(Target);
            TargetField := TargetRef.Field(2);
            V := Field.Value();
            TargetField.Value := V;
            Observer.Observe(Format(I) + ' variant text', Format(TargetField.Value));
            TargetField.Value := ReturnedField(Field);
            Observer.Observe(Format(I) + ' return text', Format(TargetField.Value));
            TargetField.Value := Field.Value();
            Observer.Observe(Format(I) + ' direct text', Format(TargetField.Value));
            TargetField.Value := ReturnedOption(Source);
            Observer.Observe(Format(I) + ' option return text', Format(TargetField.Value));
            TargetField := TargetRef.Field(3);
            TargetField.Value := V;
            Observer.Observe(Format(I) + ' variant code', Format(TargetField.Value));
            TargetField.Value := ReturnedField(Field);
            Observer.Observe(Format(I) + ' return code', Format(TargetField.Value));
            TargetField.Value := Field.Value();
            Observer.Observe(Format(I) + ' direct code', Format(TargetField.Value));
            TargetField.Value := ReturnedOption(Source);
            Observer.Observe(Format(I) + ' option return code', Format(TargetField.Value));
        end;
        Observer.Expect('0 variant text', ' ');
        Observer.Expect('0 return text', ' ');
        Observer.Expect('0 direct text', ' ');
        Observer.Expect('0 option return text', ' ');
        Observer.Expect('0 variant code', '');
        Observer.Expect('0 return code', '');
        Observer.Expect('0 direct code', '');
        Observer.Expect('0 option return code', '');
        Observer.Expect('1 variant text', 'First Caption');
        Observer.Expect('1 return text', 'First Caption');
        Observer.Expect('1 direct text', 'First Caption');
        Observer.Expect('1 option return text', 'First Caption');
        Observer.Expect('1 variant code', 'FIRST CAPTION');
        Observer.Expect('1 return code', 'FIRST CAPTION');
        Observer.Expect('1 direct code', 'FIRST CAPTION');
        Observer.Expect('1 option return code', 'FIRST CAPTION');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        Row: Record "LT VarNum Opt Row" temporary;
    begin
        Row.DeleteAll();
    end;

    local procedure ObserveVariantErrors(var Observer: Codeunit "Probe Observer"; var Target: Record "LT VarNum Opt Row"; V: Variant; Name: Text)
    begin
        if TryText(V, Target) then
            Error('Text assignment unexpectedly succeeded');
        Observer.Observe(Name + ' text', GetLastErrorText());
        if TryCode(V, Target) then
            Error('Code assignment unexpectedly succeeded');
        Observer.Observe(Name + ' code', GetLastErrorText());
    end;

    local procedure ExpectVariantErrors(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Expect(Name + ' text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect(Name + ' code', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
    end;

    [TryFunction]
    local procedure TryReturnedText(var Target: Record "LT VarNum Opt Row"; Field: FieldRef)
    begin
        Target."Text Value" := ReturnedField(Field);
    end;

    [TryFunction]
    local procedure TryReturnedCode(var Target: Record "LT VarNum Opt Row"; Field: FieldRef)
    begin
        Target."Code Value" := ReturnedField(Field);
    end;

    local procedure ReturnedField(Field: FieldRef): Variant
    begin
        exit(Field.Value());
    end;

    [TryFunction]
    local procedure TryReturnedOptionText(var Target: Record "LT VarNum Opt Row"; Source: Record "LT VarNum Opt Row")
    begin
        Target."Text Value" := ReturnedOption(Source);
    end;

    [TryFunction]
    local procedure TryReturnedOptionCode(var Target: Record "LT VarNum Opt Row"; Source: Record "LT VarNum Opt Row")
    begin
        Target."Code Value" := ReturnedOption(Source);
    end;

    local procedure ReturnedOption(Source: Record "LT VarNum Opt Row"): Variant
    begin
        exit(Source.Choice);
    end;
}
