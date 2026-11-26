// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope. exit(FieldRef.Value()) and exit of a Variant from procedures that return Text, Text[3], Code[10] and Integer, for Option fields with and without OptionCaption, an Enum, Integer, Boolean, Date, Decimal and Code field; the assignment form and Format for comparison.
// Fixtures used: Probe Observer (codeunit 69160); own objects 77805-77807 (FC Opt Row, FC Opt Kind, FieldRef Value Exit Text)
// Probe: from al-runner issue 8096 (exit(FieldRef.Value()) of an Option field from a Text procedure). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: exit(FieldRef.Value()) from procedures returning Text, Text[3], Code[10] and Integer for Option, Enum and other field types: the returned text (caption or member name) or the error, as asserted.
// BC versions: 27, 28, 29

table 77805 "FC Opt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option)
        {
            OptionMembers = Alpha,Beta;
            OptionCaption = 'Alpha caption,Beta caption';
        }
        field(3; Plain; Option)
        {
            OptionMembers = Red,Green;
        }
        field(4; EKind; Enum "FC Opt Kind") { }
        field(5; Num; Integer) { }
        field(6; Flag; Boolean) { }
        field(7; Dt; Date) { }
        field(8; Amt; Decimal) { }
        field(9; Cd; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 77806 "FC Opt Kind"
{
    Extensible = false;

    value(0; One) { Caption = 'One caption'; }
    value(1; Two) { Caption = 'Two caption'; }
}

codeunit 77807 "FieldRef Value Exit Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ExitText(Fld: FieldRef): Text
    begin
        exit(Fld.Value());
    end;

    local procedure ExitText3(Fld: FieldRef): Text[3]
    begin
        exit(Fld.Value());
    end;

    local procedure ExitCode10(Fld: FieldRef): Code[10]
    begin
        exit(Fld.Value());
    end;

    local procedure ExitInteger(Fld: FieldRef): Integer
    begin
        exit(Fld.Value());
    end;

    local procedure ExitVariantText(V: Variant): Text
    begin
        exit(V);
    end;

    [TryFunction]
    local procedure TryVariant(V: Variant; var Result: Text)
    begin
        Result := ExitVariantText(V);
    end;

    local procedure VariantForm(V: Variant): Text
    var
        Result: Text;
    begin
        if TryVariant(V, Result) then
            exit(Result);
        exit('error: ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryForm(Fld: FieldRef; Form: Integer; var Result: Text)
    var
        Assigned: Text;
    begin
        case Form of
            1:
                Result := ExitText(Fld);
            2:
                Result := ExitText3(Fld);
            3:
                Result := ExitCode10(Fld);
            4:
                Result := Format(ExitInteger(Fld));
            5:
                begin
                    Assigned := Fld.Value();
                    Result := Assigned;
                end;
            6:
                Result := Format(Fld.Value());
            7:
                Result := ExitVariantText(Fld.Value());
        end;
    end;

    local procedure AllForms(Fld: FieldRef): Text
    var
        Form: Integer;
        One: Text;
        Result: Text;
    begin
        for Form := 1 to 7 do begin
            One := '';
            if TryForm(Fld, Form, One) then
                Result += Format(Form) + '=' + One + ';'
            else
                Result += Format(Form) + '=error: ' + GetLastErrorText() + ';';
        end;
        exit(Result);
    end;

    local procedure OpenRow(var RecRef: RecordRef)
    var
        Row: Record "FC Opt Row";
    begin
        Row.Init();
        Row.Id := 1;
        Row.Kind := Row.Kind::Beta;
        Row.Plain := Row.Plain::Green;
        Row.EKind := "FC Opt Kind"::Two;
        Row.Num := 42;
        Row.Flag := true;
        Row.Dt := DMY2Date(15, 3, 2024);
        Row.Amt := 1234.5;
        Row.Cd := 'ABCDEFGH';
        RecRef.GetTable(Row);
    end;

    [Test]
    procedure ExitFieldRefValue_OptionAndEnum()
    var
        Row: Record "FC Opt Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        OpenRow(RecRef);
        Observer.Observe('optionCaption', AllForms(RecRef.Field(Row.FieldNo(Kind))));
        Observer.Observe('optionPlain', AllForms(RecRef.Field(Row.FieldNo(Plain))));
        Observer.Observe('enum', AllForms(RecRef.Field(Row.FieldNo(EKind))));
        Observer.Expect('optionCaption', '1=Beta caption;2=error: The length of the string is 12, but it must be less than or equal to 3 characters. Value: Beta caption;3=error: The length of the string is 12, but it must be less than or equal to 10 characters. Value: Beta caption;4=1;5=Beta caption;6=Beta caption;7=error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.;');
        Observer.Expect('optionPlain', '1=Green;2=error: The length of the string is 5, but it must be less than or equal to 3 characters. Value: Green;3=GREEN;4=1;5=Green;6=Green;7=error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.;');
        Observer.Expect('enum', '1=Two caption;2=error: The length of the string is 11, but it must be less than or equal to 3 characters. Value: Two caption;3=error: The length of the string is 11, but it must be less than or equal to 10 characters. Value: Two caption;4=1;5=Two caption;6=Two caption;7=error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.;');
        Observer.Verify();
    end;

    [Test]
    procedure ExitFieldRefValue_OtherTypes()
    var
        Row: Record "FC Opt Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        OpenRow(RecRef);
        Observer.Observe('integer', AllForms(RecRef.Field(Row.FieldNo(Num))));
        Observer.Observe('boolean', AllForms(RecRef.Field(Row.FieldNo(Flag))));
        Observer.Observe('date', AllForms(RecRef.Field(Row.FieldNo(Dt))));
        Observer.Observe('decimal', AllForms(RecRef.Field(Row.FieldNo(Amt))));
        Observer.Observe('code', AllForms(RecRef.Field(Row.FieldNo(Cd))));
        Observer.Expect('integer', '1=42;2=42;3=42;4=42;5=42;6=42;7=error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.;');
        Observer.Expect('boolean', '1=Yes;2=Yes;3=YES;4=1;5=Yes;6=Yes;7=error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.;');
        Observer.Expect('date', '1=03/15/24;2=error: The length of the string is 8, but it must be less than or equal to 3 characters. Value: 03/15/24;3=03/15/24;4=error: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDate to System.Int32.;5=03/15/24;6=03/15/24;7=error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.;');
        Observer.Expect('decimal', '1=1,234.5;2=error: The length of the string is 7, but it must be less than or equal to 3 characters. Value: 1,234.5;3=1,234.5;4=error: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1234.5 to System.Int32.;5=1,234.5;6=1,234.5;7=error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.;');
        Observer.Expect('code', '1=ABCDEFGH;2=error: The length of the string is 8, but it must be less than or equal to 3 characters. Value: ABCDEFGH;3=ABCDEFGH;4=error: Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavCode to System.Int32.;5=ABCDEFGH;6=ABCDEFGH;7=ABCDEFGH;');
        Observer.Verify();
    end;

    [Test]
    procedure ExitVariant_HoldingOption()
    var
        Row: Record "FC Opt Row";
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        Row.Kind := Row.Kind::Beta;
        V := Row.Kind;
        Observer.Observe('variantOptionField', VariantForm(V));
        V := "FC Opt Kind"::Two;
        Observer.Observe('variantEnum', VariantForm(V));
        V := 42;
        Observer.Observe('variantInteger', VariantForm(V));
        Observer.Expect('variantOptionField', 'error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('variantEnum', 'error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('variantInteger', 'error: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Verify();
    end;
}
