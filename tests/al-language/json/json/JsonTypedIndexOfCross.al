// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/json/json-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 71877
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IndexOf with a stored number of another numeric type
// BC versions: 29 (27 and 28 by CI)

codeunit 71877 "LT JsonTyped IndexOf Cross"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P192_IndexOf_IntegerStored_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ig: Integer;
        De: Decimal;
        By: Byte;
        Bi: BigInteger;
        Tx: Text;
    begin
        Ig := 7;
        A.Add(Ig);
        De := 7;
        Observer.Observe('dec_7', Format(A.IndexOf(De)));
        By := 7;
        Observer.Observe('byte_7', Format(A.IndexOf(By)));
        Bi := 7;
        Observer.Observe('big_7', Format(A.IndexOf(Bi)));
        Tx := '7';
        Observer.Observe('text_7', Format(A.IndexOf(Tx)));
        De := 7.5;
        Observer.Observe('dec_7_5', Format(A.IndexOf(De)));
        Observer.Expect('dec_7', '-1');
        Observer.Expect('byte_7', '0');
        Observer.Expect('big_7', '0');
        Observer.Expect('text_7', '-1');
        Observer.Expect('dec_7_5', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P192_IndexOf_DecimalStored_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ig: Integer;
        De: Decimal;
        By: Byte;
        Bi: BigInteger;
    begin
        De := 3;
        A.Add(De);
        De := 3.5;
        A.Add(De);
        Ig := 3;
        Observer.Observe('int_3', Format(A.IndexOf(Ig)));
        By := 3;
        Observer.Observe('byte_3', Format(A.IndexOf(By)));
        Bi := 3;
        Observer.Observe('big_3', Format(A.IndexOf(Bi)));
        De := 3.50;
        Observer.Observe('dec_3_50', Format(A.IndexOf(De)));
        De := 3.0;
        Observer.Observe('dec_3_0', Format(A.IndexOf(De)));
        Observer.Expect('int_3', '-1');
        Observer.Expect('byte_3', '-1');
        Observer.Expect('big_3', '-1');
        Observer.Expect('dec_3_50', '1');
        Observer.Expect('dec_3_0', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P192_IndexOf_ByteAndInteger_Mixed()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ig: Integer;
        By: Byte;
    begin
        By := 255;
        A.Add(By);
        Ig := 0;
        A.Add(Ig);
        By := 0;
        A.Add(By);
        Ig := 255;
        Observer.Observe('int_255', Format(A.IndexOf(Ig)));
        Ig := 0;
        Observer.Observe('int_0', Format(A.IndexOf(Ig)));
        By := 0;
        Observer.Observe('byte_0', Format(A.IndexOf(By)));
        By := 1;
        Observer.Observe('byte_1_missing', Format(A.IndexOf(By)));
        Observer.Expect('int_255', '0');
        Observer.Expect('int_0', '1');
        Observer.Expect('byte_0', '1');
        Observer.Expect('byte_1_missing', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P192_IndexOf_DateTime_Stored()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Dt: DateTime;
        Dt2: DateTime;
        Tx: Text;
    begin
        Dt := CreateDateTime(20240229D, 123456T);
        A.Add(Dt);
        Dt2 := 0DT;
        A.Add(Dt2);
        Observer.Observe('present', Format(A.IndexOf(Dt)));
        Observer.Observe('zero', Format(A.IndexOf(Dt2)));
        Dt2 := CreateDateTime(20240229D, 123457T);
        Observer.Observe('missing', Format(A.IndexOf(Dt2)));
        Tx := '2024-02-29T12:34:56.0000000Z';
        Observer.Observe('as_text', Format(A.IndexOf(Tx)));
        A.Add(Dt);
        Observer.Observe('twice_first', Format(A.IndexOf(Dt)));
        Observer.Expect('present', '0');
        Observer.Expect('zero', '1');
        Observer.Expect('missing', '-1');
        Observer.Expect('as_text', '0');
        Observer.Expect('twice_first', '0');
        Observer.Verify();
    end;
}
