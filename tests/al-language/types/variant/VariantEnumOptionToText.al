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
}
