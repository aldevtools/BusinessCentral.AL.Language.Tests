// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/diagnostics/diagnostic-al685
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus #664 items 8 and 10 (the runtime half; compile results from AL 30 beta, runtime 16.1 to 18.0):
// - item 8: a CalcFormula filter Integer field = field(BigInteger) gives warning AL0662 ("may overflow at runtime") with AL 30; a
//   filter BigInteger field = field(Integer) gives none. Publishing to BC 27.5 and 28.5 fails on that field: the server's compile gives
//   error AL0204 "Field type Integer is not convertible to field type BigInteger." (CI run 39242281578), so the field and its checks
//   are BC 29 only. This records CalcFields on BC 29 when the BigInteger value is above 2147483647.
// - item 10: a Lookup FlowField Text[10] over a Text[30] source gives warning AL0685 ("could result in a runtime error"). This records
//   CalcFields when the source value is longer than 10 characters.
// BC versions: 29 (27 and 28 by CI)
table 81957 "LT BM FF Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Int; Integer) { }
        field(3; Big; BigInteger) { }
        field(4; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 81958 "LT BM FF Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
#if BC29PLUS
        field(3; "Count Int By Big"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BM FF Source" where(Int = field(Big)));
        }
#endif
        field(4; "Count Big By Id"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BM FF Source" where(Big = field(Id)));
        }
        field(5; "Short Lookup"; Text[10])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT BM FF Source".Txt where(Id = field(Id)));
        }
        field(6; "Long Lookup"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT BM FF Source".Txt where(Id = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 81959 "LT BM FlowField Conversions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Src: Record "LT BM FF Source";
    begin
        Src.DeleteAll();
        AddSource(1, 5, 1, 'short');
        AddSource(2, 5, BigOf(3000, 0), 'ABCDEFGHIJ');
        AddSource(3, 7, BigOf(3000, 0), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123');
        AddSource(4, -1, 2, '');
    end;

    local procedure AddSource(NewId: Integer; NewInt: Integer; NewBig: BigInteger; NewTxt: Text[30])
    var
        Src: Record "LT BM FF Source";
    begin
        Src.Id := NewId;
        Src.Int := NewInt;
        Src.Big := NewBig;
        Src.Txt := NewTxt;
        Src.Insert();
    end;

#if BC29PLUS
    local procedure CountIntByBig(Big: BigInteger): Text
    var
        Host: Record "LT BM FF Host";
    begin
        Host.Id := 1;
        Host.Big := Big;
        ClearLastError();
        if TryCalc(Host, 3) then
            exit(Format(Host."Count Int By Big"));
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;
#endif

    local procedure Lookup(HostId: Integer; FieldNo: Integer): Text
    var
        Host: Record "LT BM FF Host";
    begin
        Host.Id := HostId;
        ClearLastError();
        if TryCalc(Host, FieldNo) then begin
            if FieldNo = 5 then
                exit('[' + Host."Short Lookup" + '] len ' + Format(StrLen(Host."Short Lookup")));
            exit('[' + Host."Long Lookup" + '] len ' + Format(StrLen(Host."Long Lookup")));
        end;
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCalc(var Host: Record "LT BM FF Host"; FieldNo: Integer)
    begin
        case FieldNo of
#if BC29PLUS
            3:
                Host.CalcFields("Count Int By Big");
#endif
            4:
                Host.CalcFields("Count Big By Id");
            5:
                Host.CalcFields("Short Lookup");
            6:
                Host.CalcFields("Long Lookup");
        end;
    end;

    [Test]
    procedure BM_CalcFormula_IntegerFilterFromBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Host: Record "LT BM FF Host";
    begin
        Seed();
#if BC29PLUS
        Observer.Observe('big_5', CountIntByBig(5));
        Observer.Observe('big_minus_1', CountIntByBig(-1));
        Observer.Observe('big_int_max', CountIntByBig(2147483647));
        Observer.Observe('big_3e9', CountIntByBig(BigOf(3000, 0)));
        Observer.Observe('big_2pow32_plus_5', CountIntByBig(BigOf(4294, 967301)));
        Observer.Observe('big_2pow32_minus_1', CountIntByBig(BigOf(4294, 967295)));
#endif
#if BC29PLUS
        Observer.Expect('big_5', '2');
        Observer.Expect('big_minus_1', '1');
        Observer.Expect('big_int_max', '0');
        Observer.Expect('big_3e9', 'error|Overflow under conversion of System.Int64 value 3000000000 to System.Int32.|ConversionCast');
        Observer.Expect('big_2pow32_plus_5', 'error|Overflow under conversion of System.Int64 value 4294967301 to System.Int32.|ConversionCast');
        Observer.Expect('big_2pow32_minus_1', 'error|Overflow under conversion of System.Int64 value 4294967295 to System.Int32.|ConversionCast');
#endif
        Observer.Verify();
    end;

    // The other direction, a BigInteger field = field(Integer), gives no compile diagnostic. On BC 28.5 CalcFields then raised
    // "The following fields must have the same type: ... Type: BigInteger <-- Integer" (also on BC 27.5, CI run 39257493772); BC 29.0 counts.
    [Test]
    procedure BM_CalcFormula_BigIntegerFilterFromInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('id_1', CountBigById(1));
        Observer.Observe('id_none', CountBigById(3000000));
#if BC29PLUS
        Observer.Expect('id_1', '1');
#else
        Observer.Expect('id_1', 'error|The following fields must have the same type:\\Field: Big <-- Id\Table: LT BM FF Source <-- LT BM FF Host\Type: BigInteger <-- Integer|DB:TypeMisMatch');
#endif
#if BC29PLUS
        Observer.Expect('id_none', '0');
#else
        Observer.Expect('id_none', 'error|The following fields must have the same type:\\Field: Big <-- Id\Table: LT BM FF Source <-- LT BM FF Host\Type: BigInteger <-- Integer|DB:TypeMisMatch');
#endif
        Observer.Verify();
    end;

    local procedure CountBigById(HostId: Integer): Text
    var
        Host: Record "LT BM FF Host";
    begin
        Host.Id := HostId;
        ClearLastError();
        if TryCalc(Host, 4) then
            exit(Format(Host."Count Big By Id"));
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure BM_LookupFlowField_ShorterThanSource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('short_5_chars', Lookup(1, 5));
        Observer.Observe('short_10_chars', Lookup(2, 5));
        Observer.Observe('short_30_chars', Lookup(3, 5));
        Observer.Observe('short_empty', Lookup(4, 5));
        Observer.Observe('short_no_row', Lookup(99, 5));
        Observer.Observe('long_30_chars', Lookup(3, 6));
        Observer.Expect('short_5_chars', '[short] len 5');
        Observer.Expect('short_10_chars', '[ABCDEFGHIJ] len 10');
        Observer.Expect('short_30_chars', '[ABCDEFGHIJKLMNOPQRSTUVWXYZ0123] len 30');
        Observer.Expect('short_empty', '[] len 0');
        Observer.Expect('short_no_row', '[] len 0');
        Observer.Expect('long_30_chars', '[ABCDEFGHIJKLMNOPQRSTUVWXYZ0123] len 30');
        Observer.Verify();
    end;

    local procedure BigOf(Millions: Integer; Rest: Integer): BigInteger
    var
        R: BigInteger;
    begin
        // A literal above 2147483647 is AL0103 even where a BigInteger is expected, so large values are built at run time.
        R := Millions;
        exit(R * 1000000 + Rest);
    end;

    // Writer PX (PR 331): Code[5] lookup over Code[30], Min/Max into Text[5] and Code[5] (objects in PxFlowFieldShorter.al).
    local procedure PxSeed()
    var
        Src: Record "LT PX FF Src";
    begin
        Src.DeleteAll();
        PxAdd(1, 1, 'ABC', 'abc');
        PxAdd(2, 2, 'ABCDEFGHIJ', 'abcdefghij');
        PxAdd(3, 2, 'ZZZZZZZZZZZZ', 'zzzzzzzzzzzz');
        PxAdd(4, 3, 'ABCDE', 'abcde');
    end;

    local procedure PxAdd(NewId: Integer; NewGrp: Integer; NewCd: Code[30]; NewTxt: Text[30])
    var
        Src: Record "LT PX FF Src";
    begin
        Src.Id := NewId;
        Src.Grp := NewGrp;
        Src.Cd := NewCd;
        Src.Txt := NewTxt;
        Src.Insert();
    end;

    local procedure PxCalc(HostId: Integer; FieldNo: Integer): Text
    var
        Host: Record "LT PX FF Host";
        V: Text;
    begin
        Host.Id := HostId;
        ClearLastError();
        if not PxTryCalc(Host, FieldNo) then
            exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        case FieldNo of
            2:
                V := Host."Code Lookup";
            3:
                V := Host."Text Min";
            4:
                V := Host."Text Max";
            5:
                V := Host."Code Min";
            6:
                V := Host."Code Max";
        end;
        exit('[' + V + '] len ' + Format(StrLen(V)));
    end;

    [TryFunction]
    local procedure PxTryCalc(var Host: Record "LT PX FF Host"; FieldNo: Integer)
    begin
        case FieldNo of
            2:
                Host.CalcFields("Code Lookup");
            3:
                Host.CalcFields("Text Min");
            4:
                Host.CalcFields("Text Max");
            5:
                Host.CalcFields("Code Min");
            6:
                Host.CalcFields("Code Max");
        end;
    end;

    [Test]
    procedure PX_CodeLookup_ShorterThanSource()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PxSeed();
        Observer.Observe('lookup_3_chars', PxCalc(1, 2));
        Observer.Observe('lookup_10_chars', PxCalc(2, 2));
        Observer.Observe('lookup_12_chars', PxCalc(3, 2));
        Observer.Observe('lookup_5_chars', PxCalc(4, 2));
        Observer.Observe('lookup_no_row', PxCalc(99, 2));
        Observer.Expect('lookup_3_chars', '[ABC] len 3');
        Observer.Expect('lookup_10_chars', '[ABCDEFGHIJ] len 10');
        Observer.Expect('lookup_12_chars', '[ZZZZZZZZZZZZ] len 12');
        Observer.Expect('lookup_5_chars', '[ABCDE] len 5');
        Observer.Expect('lookup_no_row', '[] len 0');
        Observer.Verify();
    end;

    [Test]
    // BC 29 raises StringLengthExceeded for a Min/Max value longer than the target; BC 27.5 and 28.5 return the whole value (CI run 39354581861).
    procedure PX_MinMax_IntoShorterTextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        F: Integer;
    begin
        PxSeed();
        for F := 3 to 6 do begin
            Observer.Observe(Format(F) + '_grp1_short', PxCalc(1, F));
            Observer.Observe(Format(F) + '_grp2_long', PxCalc(2, F));
            Observer.Observe(Format(F) + '_grp3_exact', PxCalc(3, F));
            Observer.Observe(Format(F) + '_grp_none', PxCalc(9, F));
        end;
        Observer.Expect('3_grp1_short', '[abc] len 3');
#if BC29PLUS
        Observer.Expect('3_grp2_long', 'error|The length of the string is 10, but it must be less than or equal to 5 characters. Value: abcdefghij|StringLengthExceeded');
#else
        Observer.Expect('3_grp2_long', '[abcdefghij] len 10');
#endif
        Observer.Expect('3_grp3_exact', '[abcde] len 5');
        Observer.Expect('3_grp_none', '[] len 0');
        Observer.Expect('4_grp1_short', '[abc] len 3');
#if BC29PLUS
        Observer.Expect('4_grp2_long', 'error|The length of the string is 12, but it must be less than or equal to 5 characters. Value: zzzzzzzzzzzz|StringLengthExceeded');
#else
        Observer.Expect('4_grp2_long', '[zzzzzzzzzzzz] len 12');
#endif
        Observer.Expect('4_grp3_exact', '[abcde] len 5');
        Observer.Expect('4_grp_none', '[] len 0');
        Observer.Expect('5_grp1_short', '[ABC] len 3');
#if BC29PLUS
        Observer.Expect('5_grp2_long', 'error|The length of the string is 10, but it must be less than or equal to 5 characters. Value: ABCDEFGHIJ|StringLengthExceeded');
#else
        Observer.Expect('5_grp2_long', '[ABCDEFGHIJ] len 10');
#endif
        Observer.Expect('5_grp3_exact', '[ABCDE] len 5');
        Observer.Expect('5_grp_none', '[] len 0');
        Observer.Expect('6_grp1_short', '[ABC] len 3');
#if BC29PLUS
        Observer.Expect('6_grp2_long', 'error|The length of the string is 12, but it must be less than or equal to 5 characters. Value: ZZZZZZZZZZZZ|StringLengthExceeded');
#else
        Observer.Expect('6_grp2_long', '[ZZZZZZZZZZZZ] len 12');
#endif
        Observer.Expect('6_grp3_exact', '[ABCDE] len 5');
        Observer.Expect('6_grp_none', '[] len 0');
        Observer.Verify();
    end;

}
