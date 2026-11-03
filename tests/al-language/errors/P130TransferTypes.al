// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-transferfields-method
// Scope: in-scope
// Fixtures used: own tables 73553-73562, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TransferFields between tables whose fields share a field NUMBER but have another NAME and another TYPE or length (Code to Text, Text to Code, Integer to Text,
//   Boolean to Integer, Date to DateTime, Guid to Code, Decimal to Text, Text[100] to Text[10]) and one control of the same type under another name: the outcome, the error text and code,
//   and what the target field holds afterwards, with ordinary values and with values that do not fit
// Settles issue 130 reason 37 (TransferFields across fields of different types: error text; field No. 2 of Item and field Description of Item Templ.)
// BC versions: 29 (27 and 28 by CI)

table 73553 "LT P130 Tf Src"
{
    fields
    {
        field(1; Id; Integer) { }
        field(10; CodeF; Code[20]) { }
        field(11; TextF; Text[50]) { }
        field(12; IntF; Integer) { }
        field(13; BoolF; Boolean) { }
        field(14; DateF; Date) { }
        field(15; GuidF; Guid) { }
        field(16; DecF; Decimal) { }
        field(19; TextLong; Text[100]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73554 "LT P130 Tf Dst1"
{
    fields
    {
        field(1; Id; Integer) { }
        field(10; Description; Text[100]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73555 "LT P130 Tf Dst2"
{
    fields
    {
        field(1; Id; Integer) { }
        field(11; "No 2"; Code[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73556 "LT P130 Tf Dst3"
{
    fields
    {
        field(1; Id; Integer) { }
        field(12; Label; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73557 "LT P130 Tf Dst4"
{
    fields
    {
        field(1; Id; Integer) { }
        field(13; Qty; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73558 "LT P130 Tf Dst5"
{
    fields
    {
        field(1; Id; Integer) { }
        field(14; Stamp; DateTime) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73559 "LT P130 Tf Dst6"
{
    fields
    {
        field(1; Id; Integer) { }
        field(15; Ref; Code[40]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73560 "LT P130 Tf Dst7"
{
    fields
    {
        field(1; Id; Integer) { }
        field(16; Words; Text[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73561 "LT P130 Tf Dst8"
{
    fields
    {
        field(1; Id; Integer) { }
        field(19; Short; Text[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73562 "LT P130 Tf Dst9"
{
    fields
    {
        field(1; Id; Integer) { }
        field(10; "Other Name"; Code[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73563 "LT P130 Transfer Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill(var Src: Record "LT P130 Tf Src"; Tricky: Boolean)
    begin
        Src.Init();
        Src.Id := 1;
        if Tricky then begin
            Src.CodeF := 'ABCDEFGHIJKLMNOPQRST';
            Src.TextF := 'this text is longer than twenty chars';
            Src.IntF := -2147483647;
            Src.BoolF := false;
            Src.DateF := 0D;
            Src.GuidF := '{00000000-0000-0000-0000-000000000000}';
            Src.DecF := -0.000001;
            Src.TextLong := 'abcdefghijklmnopqrstuvwxyz';
        end else begin
            Src.CodeF := 'abc';
            Src.TextF := 'text value';
            Src.IntF := 42;
            Src.BoolF := true;
            Src.DateF := 20240305D;
            Src.GuidF := '{11111111-2222-3333-4444-555555555555}';
            Src.DecF := 12.5;
            Src.TextLong := 'abcdefghijklmnop';
        end;
    end;

    local procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure Try1(var Dst: Record "LT P130 Tf Dst1"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run1(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst1";
    begin
        Fill(Src, Tricky);
        if Try1(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst.Description))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst.Description));
    end;

    [TryFunction]
    local procedure Try2(var Dst: Record "LT P130 Tf Dst2"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run2(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst2";
    begin
        Fill(Src, Tricky);
        if Try2(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst."No 2"))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst."No 2"));
    end;

    [TryFunction]
    local procedure Try3(var Dst: Record "LT P130 Tf Dst3"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run3(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst3";
    begin
        Fill(Src, Tricky);
        if Try3(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst.Label))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst.Label));
    end;

    [TryFunction]
    local procedure Try4(var Dst: Record "LT P130 Tf Dst4"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run4(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst4";
    begin
        Fill(Src, Tricky);
        if Try4(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst.Qty))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst.Qty));
    end;

    [TryFunction]
    local procedure Try5(var Dst: Record "LT P130 Tf Dst5"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run5(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst5";
    begin
        Fill(Src, Tricky);
        if Try5(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst.Stamp))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst.Stamp));
    end;

    [TryFunction]
    local procedure Try6(var Dst: Record "LT P130 Tf Dst6"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run6(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst6";
    begin
        Fill(Src, Tricky);
        if Try6(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst.Ref))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst.Ref));
    end;

    [TryFunction]
    local procedure Try7(var Dst: Record "LT P130 Tf Dst7"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run7(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst7";
    begin
        Fill(Src, Tricky);
        if Try7(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst.Words))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst.Words));
    end;

    [TryFunction]
    local procedure Try8(var Dst: Record "LT P130 Tf Dst8"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run8(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst8";
    begin
        Fill(Src, Tricky);
        if Try8(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst.Short))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst.Short));
    end;

    [TryFunction]
    local procedure Try9(var Dst: Record "LT P130 Tf Dst9"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src);
    end;

    local procedure Run9(var Observer: Codeunit "Probe Observer"; Name: Text; Tricky: Boolean)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst9";
    begin
        Fill(Src, Tricky);
        if Try9(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Format(Dst."Other Name"))
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Format(Dst."Other Name"));
    end;

    [Test]
    procedure P130_Transfer_DifferentNameAndType_OrdinaryValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run1(Observer, 'code20_to_text100', false);
        Run2(Observer, 'text50_to_code20', false);
        Run3(Observer, 'integer_to_text30', false);
        Run4(Observer, 'boolean_to_integer', false);
        Run5(Observer, 'date_to_datetime', false);
        Run6(Observer, 'guid_to_code40', false);
        Run7(Observer, 'decimal_to_text20', false);
        Run8(Observer, 'text100_to_text10', false);
        Run9(Observer, 'code20_to_code20_other_name', false);
        Observer.Expect('code20_to_text100', 'ok id=1 value=ABC');
        Observer.Expect('text50_to_code20', 'ok id=1 value=TEXT VALUE');
        Observer.Expect('integer_to_text30', 'error:The following fields must have the same type:\\Field: Label <-- IntF\Table: LT P130 Tf Dst3 <-- LT P130 Tf Src\Type: Text <-- Integer|DB:TypeMisMatch id=1 value=');
        Observer.Expect('boolean_to_integer', 'error:The following fields must have the same type:\\Field: Qty <-- BoolF\Table: LT P130 Tf Dst4 <-- LT P130 Tf Src\Type: Integer <-- Boolean|DB:TypeMisMatch id=1 value=0');
        Observer.Expect('date_to_datetime', 'error:The following fields must have the same type:\\Field: Stamp <-- DateF\Table: LT P130 Tf Dst5 <-- LT P130 Tf Src\Type: DateTime <-- Date|DB:TypeMisMatch id=1 value=');
        Observer.Expect('guid_to_code40', 'error:The following fields must have the same type:\\Field: Ref <-- GuidF\Table: LT P130 Tf Dst6 <-- LT P130 Tf Src\Type: Code <-- GUID|DB:TypeMisMatch id=1 value=');
        Observer.Expect('decimal_to_text20', 'error:The following fields must have the same type:\\Field: Words <-- DecF\Table: LT P130 Tf Dst7 <-- LT P130 Tf Src\Type: Text <-- Decimal|DB:TypeMisMatch id=1 value=');
        Observer.Expect('text100_to_text10', 'error:The contents of the TextLong field cannot be copied to the Short field because the size of the Short field is too small.\\Type: Text10 <-- Text100\Field: Short <-- TextLong\Table: LT P130 Tf Dst8 <-- LT P130 Tf Src|DB:TypeMisMatch id=1 value=');
        Observer.Expect('code20_to_code20_other_name', 'ok id=1 value=ABC');
        Observer.Verify();
    end;

    [Test]
    procedure P130_Transfer_DifferentNameAndType_ValuesThatDoNotFit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run1(Observer, 'code20_to_text100', true);
        Run2(Observer, 'text50_to_code20', true);
        Run3(Observer, 'integer_to_text30', true);
        Run4(Observer, 'boolean_to_integer', true);
        Run5(Observer, 'date_to_datetime', true);
        Run6(Observer, 'guid_to_code40', true);
        Run7(Observer, 'decimal_to_text20', true);
        Run8(Observer, 'text100_to_text10', true);
        Run9(Observer, 'code20_to_code20_other_name', true);
        Observer.Expect('code20_to_text100', 'ok id=1 value=ABCDEFGHIJKLMNOPQRST');
        Observer.Expect('text50_to_code20', 'error:The contents of the TextF field cannot be copied to the No 2 field because the size of the No 2 field is too small.\\Type: Code20 <-- Text50\Field: No 2 <-- TextF\Table: LT P130 Tf Dst2 <-- LT P130 Tf Src|DB:TypeMisMatch id=1 value=');
        Observer.Expect('integer_to_text30', 'error:The following fields must have the same type:\\Field: Label <-- IntF\Table: LT P130 Tf Dst3 <-- LT P130 Tf Src\Type: Text <-- Integer|DB:TypeMisMatch id=1 value=');
        Observer.Expect('boolean_to_integer', 'error:The following fields must have the same type:\\Field: Qty <-- BoolF\Table: LT P130 Tf Dst4 <-- LT P130 Tf Src\Type: Integer <-- Boolean|DB:TypeMisMatch id=1 value=0');
        Observer.Expect('date_to_datetime', 'error:The following fields must have the same type:\\Field: Stamp <-- DateF\Table: LT P130 Tf Dst5 <-- LT P130 Tf Src\Type: DateTime <-- Date|DB:TypeMisMatch id=1 value=');
        Observer.Expect('guid_to_code40', 'error:The following fields must have the same type:\\Field: Ref <-- GuidF\Table: LT P130 Tf Dst6 <-- LT P130 Tf Src\Type: Code <-- GUID|DB:TypeMisMatch id=1 value=');
        Observer.Expect('decimal_to_text20', 'error:The following fields must have the same type:\\Field: Words <-- DecF\Table: LT P130 Tf Dst7 <-- LT P130 Tf Src\Type: Text <-- Decimal|DB:TypeMisMatch id=1 value=');
        Observer.Expect('text100_to_text10', 'error:The contents of the TextLong field cannot be copied to the Short field because the size of the Short field is too small.\\Type: Text10 <-- Text100\Field: Short <-- TextLong\Table: LT P130 Tf Dst8 <-- LT P130 Tf Src|DB:TypeMisMatch id=1 value=');
        Observer.Expect('code20_to_code20_other_name', 'ok id=1 value=ABCDEFGHIJKLMNOPQRST');
        Observer.Verify();
    end;

    // Writer RN (al-runner issue 5773): Text[100] into Text[10] by the length of the value (empty, 5, 10, 11 and 20
    // characters), the target's earlier value after a failure, TransferFields(Src, false), and the asserterror form.
    // Measured (BC 29.0; 27.5 and 28.5 by CI): up to 10 characters copy; 11 and more raise DB:TypeMisMatch with the size text, the
    // target field keeps its earlier value, the key is copied before the failure (TransferFields(Src, false) keeps the target key).
    local procedure RnRun8(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst8";
    begin
        Src.Init();
        Src.Id := 1;
        Src.TextLong := CopyStr(Value, 1, MaxStrLen(Src.TextLong));
        Dst.Id := 5;
        Dst.Short := 'old';
        if Try8(Dst, Src) then
            Observer.Observe(Name, 'ok id=' + Format(Dst.Id) + ' value=' + Dst.Short)
        else
            Observer.Observe(Name, Failed() + ' id=' + Format(Dst.Id) + ' value=' + Dst.Short);
    end;

    [TryFunction]
    local procedure RnTry8NoKey(var Dst: Record "LT P130 Tf Dst8"; var Src: Record "LT P130 Tf Src")
    begin
        Dst.TransferFields(Src, false);
    end;

    [Test]
    procedure RN_Transfer_Text100ToText10_ByValueLength()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT P130 Tf Src";
        Dst: Record "LT P130 Tf Dst8";
    begin
        RnRun8(Observer, 'len0', '');
        RnRun8(Observer, 'len5', 'abcde');
        RnRun8(Observer, 'len10', 'abcdefghij');
        RnRun8(Observer, 'len11', 'abcdefghijk');
        RnRun8(Observer, 'len20', 'abcdefghijklmnopqrst');
        Src.Init();
        Src.Id := 1;
        Src.TextLong := 'abcdefghijk';
        Dst.Id := 5;
        Dst.Short := 'old';
        if RnTry8NoKey(Dst, Src) then
            Observer.Observe('nokey_len11', 'ok id=' + Format(Dst.Id) + ' value=' + Dst.Short)
        else
            Observer.Observe('nokey_len11', Failed() + ' id=' + Format(Dst.Id) + ' value=' + Dst.Short);
        Clear(Dst);
        asserterror Dst.TransferFields(Src);
        Observer.ObserveError('asserterror_len11');
        Observer.Expect('len0', 'ok id=1 value=');
        Observer.Expect('len5', 'ok id=1 value=abcde');
        Observer.Expect('len10', 'ok id=1 value=abcdefghij');
        Observer.Expect('len11', 'error:The contents of the TextLong field cannot be copied to the Short field because the size of the Short field is too small.\\Type: Text10 <-- Text100\Field: Short <-- TextLong\Table: LT P130 Tf Dst8 <-- LT P130 Tf Src|DB:TypeMisMatch id=1 value=old');
        Observer.Expect('len20', 'error:The contents of the TextLong field cannot be copied to the Short field because the size of the Short field is too small.\\Type: Text10 <-- Text100\Field: Short <-- TextLong\Table: LT P130 Tf Dst8 <-- LT P130 Tf Src|DB:TypeMisMatch id=1 value=old');
        Observer.Expect('nokey_len11', 'error:The contents of the TextLong field cannot be copied to the Short field because the size of the Short field is too small.\\Type: Text10 <-- Text100\Field: Short <-- TextLong\Table: LT P130 Tf Dst8 <-- LT P130 Tf Src|DB:TypeMisMatch id=5 value=old');
        Observer.Expect('asserterror_len11|text', 'The contents of the TextLong field cannot be copied to the Short field because the size of the Short field is too small.\\Type: Text10 <-- Text100\Field: Short <-- TextLong\Table: LT P130 Tf Dst8 <-- LT P130 Tf Src');
        Observer.Expect('asserterror_len11|code', 'DB:TypeMisMatch');
        Observer.Verify();
    end;
}
