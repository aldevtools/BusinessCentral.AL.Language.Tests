// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (tables 79906, 79908, 79900, enum 79907, helper 79913)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, items 9, 10 and 11).
// Facts: the FieldRef.TestField error text for a Byte value of 10 and 200 against an Integer field (Record.TestField with a Byte does not compile:
//   must-not-compile case 1141), an Enum value with a caption, a Guid against a Code
//   field (item 9); ModifyAll on a primary key field whose caption differs from its name, with zero rows and with one row (item 10);
//   SetFilter on a Date field with a two-digit year from 29 to 50: the year read and GetFilter (item 11).
// BC versions: 27-29

codeunit 79926 "LT AS TestField Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT AS Helper";

    local procedure Seed(var Row: Record "LT AS TF Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Num := 7;
        Row.Kind := Row.Kind::None;
        Row.Cd := 'ABC';
        Row.Insert();
    end;

    [Test]
    procedure Byte10()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        B: Byte;
    begin
        Seed(Row);
        B := 10;
        asserterror NumRef(Row).TestField(B);
        Observer.Observe('byte10', Helper.LastError());
#if BC28PLUS
        Observer.Expect('byte10', 'Num Cap must be equal to ''\n''  in AS TF Caption: Id Cap=1. Current value is ''7''.|TestField');
#else
        Observer.Expect('byte10', 'Num Cap must be equal to ''10''  in AS TF Caption: Id Cap=1. Current value is ''7''.|TestField');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Byte200()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        B: Byte;
    begin
        Seed(Row);
        B := 200;
        asserterror NumRef(Row).TestField(B);
        Observer.Observe('byte200', Helper.LastError());
#if BC28PLUS
        // BC 28+ writes Byte 200 as one character, U+02DC (small tilde); confirmed on Windows BC (windows check 3), same as the Linux tiers.
        Observer.Expect('byte200', 'Num Cap must be equal to ''˜''  in AS TF Caption: Id Cap=1. Current value is ''7''.|TestField');
#else
        Observer.Expect('byte200', 'Num Cap must be equal to ''200''  in AS TF Caption: Id Cap=1. Current value is ''7''.|TestField');
#endif
        Observer.Verify();
    end;

    // Writer PX (runtime probes-needed "TestField typed value texts", PR 331): the FieldRef.TestField text for Byte values other than 10 and 200,
    // against an Integer field that holds 250 (so every value differs, 7 included; 1000 raises "Overflow when converting to a byte.").
    [Test]
    procedure PX_ByteValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PxObserveBytes(Observer, '0,1,2,3,4,5,7,9,11,13,31,32,65');
#if BC28PLUS
        Observer.Expect('byte0', 'Num Cap must be equal to ''\u0000''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte1', 'Num Cap must be equal to ''\u0001''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte2', 'Num Cap must be equal to ''\u0002''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte3', 'Num Cap must be equal to ''\u0003''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte4', 'Num Cap must be equal to ''\u0004''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte5', 'Num Cap must be equal to ''\u0005''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte7', 'Num Cap must be equal to ''\u0007''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte9', 'Num Cap must be equal to ''\t''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte11', 'Num Cap must be equal to ''\u000B''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte13', 'Num Cap must be equal to ''\r''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte31', 'Num Cap must be equal to ''\u001F''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte32', 'Num Cap must be equal to '' ''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte65', 'Num Cap must be equal to ''A''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
#else
        Observer.Expect('byte0', 'Num Cap must be equal to ''0''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte1', 'Num Cap must be equal to ''1''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte2', 'Num Cap must be equal to ''2''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte3', 'Num Cap must be equal to ''3''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte4', 'Num Cap must be equal to ''4''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte5', 'Num Cap must be equal to ''5''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte7', 'Num Cap must be equal to ''7''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte9', 'Num Cap must be equal to ''9''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte11', 'Num Cap must be equal to ''11''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte13', 'Num Cap must be equal to ''13''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte31', 'Num Cap must be equal to ''31''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte32', 'Num Cap must be equal to ''32''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte65', 'Num Cap must be equal to ''65''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure PX_ByteValues_High()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PxObserveBytes(Observer, '127,128,129,159,160,200,255');
#if BC28PLUS
        Observer.Expect('byte127', 'Num Cap must be equal to ''<U+007F>''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte128', 'Num Cap must be equal to ''Ç''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte129', 'Num Cap must be equal to ''ü''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte159', 'Num Cap must be equal to ''ƒ''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte160', 'Num Cap must be equal to ''á''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte200', 'Num Cap must be equal to ''˜''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte255', 'Num Cap must be equal to ''<U+00A0>''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
#else
        Observer.Expect('byte127', 'Num Cap must be equal to ''127''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte128', 'Num Cap must be equal to ''128''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte129', 'Num Cap must be equal to ''129''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte159', 'Num Cap must be equal to ''159''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte160', 'Num Cap must be equal to ''160''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte200', 'Num Cap must be equal to ''200''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
        Observer.Expect('byte255', 'Num Cap must be equal to ''255''  in AS TF Caption: Id Cap=1. Current value is ''250''.|TestField');
#endif
        Observer.Verify();
    end;

    // U+007F (Byte 127) and U+00A0 (Byte 255) are shown as <U+007F> and <U+00A0> so the asserted literals have no invisible character.
    local procedure PxObserveBytes(var Observer: Codeunit "Probe Observer"; List: Text)
    var
        Row: Record "LT AS TF Row";
        B: Byte;
        Item: Text;
        V: Integer;
        Del: Text[1];
        Nbsp: Text[1];
    begin
        Del[1] := 127;
        Nbsp[1] := 160;
        Seed(Row);
        Row.Num := 250;
        Row.Modify();
        foreach Item in List.Split(',') do begin
            Evaluate(V, Item);
            B := V;
            asserterror NumRef(Row).TestField(B);
            Observer.Observe('byte' + Format(V), Helper.LastError().Replace(Del, '<U+007F>').Replace(Nbsp, '<U+00A0>'));
        end;
    end;

    [Test]
    procedure Byte7Equal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        B: Byte;
    begin
        Seed(Row);
        B := 7;
        ClearLastError();
        if TryTestNum(Row, B) then
            Observer.Observe('byte7', 'ok')
        else
            Observer.Observe('byte7', Helper.LastError());
        Observer.Expect('byte7', 'ok');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryTestNum(var Row: Record "LT AS TF Row"; B: Byte)
    begin
        NumRef(Row).TestField(B);
    end;

    // Record.TestField(Num, ByteVariable) does not compile (AL0196, ambiguous between the Integer and BigInteger overloads: must-not-compile
    // case 1141), so the Byte value goes through FieldRef.TestField.
    local procedure NumRef(var Row: Record "LT AS TF Row"): FieldRef
    var
        Ref: RecordRef;
    begin
        Ref.GetTable(Row);
        exit(Ref.Field(Row.FieldNo(Num)));
    end;

    [Test]
    procedure EnumWithCaption()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
    begin
        Seed(Row);
        asserterror Row.TestField(Kind, Row.Kind::Alpha);
        Observer.Observe('enum', Helper.LastError());
        Observer.Expect('enum', 'Kind Cap must be equal to ''Alpha Cap''  in AS TF Caption: Id Cap=1. Current value is ''Nothing Cap''.|TestField');
        Observer.Verify();
    end;

    [Test]
    procedure EnumBlankTestField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
    begin
        Seed(Row);
        asserterror Row.TestField(Kind);
        Observer.Observe('enum_blank', Helper.LastError());
        Observer.Expect('enum_blank', 'Kind Cap must not be Nothing Cap in AS TF Caption: Id Cap=1|TestField');
        Observer.Verify();
    end;

    [Test]
    procedure GuidOnCode()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        G: Guid;
    begin
        Seed(Row);
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        asserterror Row.TestField(Cd, G);
        Observer.Observe('guid', Helper.LastError());
#if BC28PLUS
        Observer.Expect('guid', 'Cd Cap must be equal to ''{11111111-2222-3333-4444-555555555555}''  in AS TF Caption: Id Cap=1. Current value is ''ABC''.|TestField');
#else
        Observer.Expect('guid', 'Cd Cap must be equal to ''11111111-2222-3333-4444-555555555555''  in AS TF Caption: Id Cap=1. Current value is ''ABC''.|TestField');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure GuidOnCodeSameText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AS TF Row";
        G: Guid;
    begin
        Seed(Row);
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        Row.Cd := Format(G);
        ClearLastError();
        if TryTestCd(Row, G) then
            Observer.Observe('guid_same', 'ok')
        else
            Observer.Observe('guid_same', Helper.LastError());
#if BC28PLUS
        Observer.Expect('guid_same', 'Cd Cap must be equal to ''{11111111-2222-3333-4444-555555555555}''  in AS TF Caption: Id Cap=1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
#else
        Observer.Expect('guid_same', 'Cd Cap must be equal to ''11111111-2222-3333-4444-555555555555''  in AS TF Caption: Id Cap=1. Current value is ''{11111111-2222-3333-4444-555555555555}''.|TestField');
#endif
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryTestCd(var Row: Record "LT AS TF Row"; G: Guid)
    begin
        Row.TestField(Cd, G);
    end;

    [Test]
    procedure ModifyAll_PK_ZeroRows()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT AS Caption PK";
    begin
        P.DeleteAll();
        // ModifyAll is not allowed inside a TryFunction (an error of its own), so asserterror catches it.
        asserterror P.ModifyAll("Key Code", 'K2');
        Observer.Observe('zero', Helper.LastError());
        Observer.Expect('zero', 'The MODIFYALL function cannot be used on the Key Caption field in the AS PK Table Cap table because it is part of the primary key.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_PK_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT AS Caption PK";
    begin
        P.DeleteAll();
        P."Key Code" := 'K1';
        P.Insert();
        asserterror P.ModifyAll("Key Code", 'K2');
        Observer.Observe('one', Helper.LastError());
        Observer.Expect('one', 'The MODIFYALL function cannot be used on the Key Caption field in the AS PK Table Cap table because it is part of the primary key.|DB:Ok');
        Observer.Verify();
    end;

    local procedure DateFilter(Text: Text): Text
    var
        I: Record "LT AS Int Key";
    begin
        I.SetFilter(D, Text);
        exit(Format(Date2DMY(I.GetRangeMin(D), 3)) + '-' + Format(Date2DMY(I.GetRangeMax(D), 3)) + ' ' + I.GetFilter(D));
    end;

    [Test]
    procedure DateFilter_TwoDigitYear_29To39()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('y29', DateFilter('01/02/29'));
        Observer.Observe('y30', DateFilter('01/02/30'));
        Observer.Observe('y39', DateFilter('01/02/39'));
        Observer.Expect('y29', '2029-2029 01/02/29');
        Observer.Expect('y30', '2030-2030 01/02/30');
        Observer.Expect('y39', '2039-2039 01/02/39');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_TwoDigitYear_40To50()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('y45', DateFilter('01/02/45'));
        Observer.Observe('y49', DateFilter('01/02/49'));
        Observer.Observe('y50', DateFilter('01/02/50'));
        Observer.Expect('y45', '2045-2045 01/02/45');
        Observer.Expect('y49', '2049-2049 01/02/49');
        Observer.Expect('y50', '1950-1950 01/02/50');
        Observer.Verify();
    end;

    [Test]
    procedure DateFilter_TwoDigitYear_Range()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('r39_49', DateFilter('01/02/39..12/30/49'));
        Observer.Observe('digits', DateFilter('010239'));
        Observer.Expect('r39_49', '2039-2049 01/02/39..12/30/49');
        Observer.Expect('digits', '2039-2039 01/02/39');
        Observer.Verify();
    end;
}
