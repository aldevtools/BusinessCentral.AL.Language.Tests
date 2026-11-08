// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 95570 (Code key) and 95571 (Text key), test codeunit 95572
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced
//   (al-runner issue 6980: a temporary record read `TTS-HD.001` before `TTS.001`).
// Facts: the key order (FindSet, ascending) of Code[50] and Text[50] primary keys that hold one ASCII punctuation character or a space
//   at the start (`-B`), inside (`A-B`) and at the end (`A-`) of the value, next to plain neighbours (`A`, `AB`, `A0B`, `B`), on a normal
//   and on a temporary record. A Code value cannot start or end with a space, so the space is only placed inside for Code; the Text key
//   also has it at the start. The order is printed with a broken bar between the values. Then the values of the issue
//   (TTS.001, TTS-HD.001, TTSA, TTS-A, A-B, AB, A.B) ascending, descending and under range, compare and wildcard filters.
//   Asserted: the normal record (SQL Server order: a hyphen and an apostrophe do not count first, and the text with one follows the
//   text without, an apostrophe before a hyphen; every other punctuation character sorts before the digits in the order shown).
//   Also asserted: the temporary record, which sorts exactly like the normal record, in every test here: ascending, descending, ranges and
//   compare and wildcard filters. Windows evidence: BC 27.5 and 29.0 (official Microsoft containers, measured 2026-11-07 with this codeunit,
//   aldevtools/MsDyn365Bc.On.Linux#222). Before bc-linux PR 224 the Linux tiers sorted a temporary record in another order (the hyphen
//   counted, `TTS-HD.001` before `TTS.001`; al-runner issue 6980); bc-linux cf9d0239 maps the punctuation to the Windows order, and the
//   test passed on BC 27.5 with the Windows values (comment on #222). Letters, digits and non-ASCII text keep ICU's order (#114).
// BC versions: 27, 28, 29

table 95570 "LT R6 Code Key"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; K; Code[50]) { }
    }
    keys
    {
        key(PK; K) { Clustered = true; }
    }
}

table 95571 "LT R6 Text Key"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; K; Text[50]) { }
    }
    keys
    {
        key(PK; K) { Clustered = true; }
    }
}

codeunit 95572 "LT R6 Key Punctuation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Punct(): Text
    begin
        exit(' !"#$%&''()*+,-./:;<=>?@[\]^_`{|}~');
    end;

    local procedure Sep(): Text
    begin
        exit('¦');
    end;

    // The values of one shape, joined with the broken bar. Shape: 1 leading, 2 interior, 3 trailing, 4 the values of the issue.
    local procedure Values(Shape: Integer; ForCode: Boolean): List of [Text]
    var
        Result: List of [Text];
        P: Text;
        i: Integer;
    begin
        case Shape of
            1:
                begin
                    Result.Add('A');
                    Result.Add('B');
                    Result.Add('BB');
                    Result.Add('C');
                    Result.Add('0');
                    Result.Add('9');
                end;
            2:
                begin
                    Result.Add('A');
                    Result.Add('AA');
                    Result.Add('AAB');
                    Result.Add('AB');
                    Result.Add('ABB');
                    Result.Add('AC');
                    Result.Add('A0B');
                    Result.Add('A9B');
                    Result.Add('B');
                end;
            3:
                begin
                    Result.Add('A');
                    Result.Add('AA');
                    Result.Add('A0');
                    Result.Add('A9');
                    Result.Add('B');
                end;
            4:
                begin
                    Result.Add('TTS.001');
                    Result.Add('TTS-HD.001');
                    Result.Add('TTSA');
                    Result.Add('TTS-A');
                    Result.Add('A-B');
                    Result.Add('AB');
                    Result.Add('A.B');
                    exit(Result);
                end;
        end;
        for i := 1 to StrLen(Punct()) do begin
            P := CopyStr(Punct(), i, 1);
            case Shape of
                1:
                    if not (ForCode and (P = ' ')) then
                        Result.Add(P + 'B');
                2:
                    Result.Add('A' + P + 'B');
                3:
                    if P <> ' ' then
                        Result.Add('A' + P);
            end;
        end;
        exit(Result);
    end;

    local procedure SeedCode(var K: Record "LT R6 Code Key"; Shape: Integer)
    var
        V: Text;
    begin
        K.Reset();
        K.DeleteAll();
        foreach V in Values(Shape, true) do begin
            K.K := CopyStr(V, 1, MaxStrLen(K.K));
            K.Insert();
        end;
    end;

    local procedure SeedText(var K: Record "LT R6 Text Key"; Shape: Integer)
    var
        V: Text;
    begin
        K.Reset();
        K.DeleteAll();
        foreach V in Values(Shape, false) do begin
            K.K := CopyStr(V, 1, MaxStrLen(K.K));
            K.Insert();
        end;
    end;

    local procedure ListCode(var K: Record "LT R6 Code Key"): Text
    var
        Result: Text;
    begin
        if K.FindSet() then
            repeat
                if Result <> '' then
                    Result += Sep();
                Result += K.K;
            until K.Next() = 0;
        exit(Result);
    end;

    local procedure ListText(var K: Record "LT R6 Text Key"): Text
    var
        Result: Text;
    begin
        if K.FindSet() then
            repeat
                if Result <> '' then
                    Result += Sep();
                Result += K.K;
            until K.Next() = 0;
        exit(Result);
    end;

    local procedure ObserveShape(var Observer: Codeunit "Probe Observer"; Shape: Integer)
    var
        C: Record "LT R6 Code Key";
        TempC: Record "LT R6 Code Key" temporary;
        T: Record "LT R6 Text Key";
        TempT: Record "LT R6 Text Key" temporary;
    begin
        SeedCode(C, Shape);
        Observer.Observe('code normal', ListCode(C));
        SeedCode(TempC, Shape);
        Observer.Observe('code temporary', ListCode(TempC));
        SeedText(T, Shape);
        Observer.Observe('text normal', ListText(T));
        SeedText(TempT, Shape);
        Observer.Observe('text temporary', ListText(TempT));
    end;

    [Test]
    procedure Order_Leading()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, 1);
        Observer.Expect('code normal', '!B¦"B¦#B¦$B¦%B¦&B¦(B¦)B¦*B¦,B¦.B¦/B¦:B¦;B¦?B¦@B¦[B¦\B¦]B¦^B¦_B¦`B¦{B¦|B¦}B¦~B¦+B¦<B¦=B¦>B¦0¦9¦A¦B¦''B¦-B¦BB¦C');
        Observer.Expect('code temporary', '!B¦"B¦#B¦$B¦%B¦&B¦(B¦)B¦*B¦,B¦.B¦/B¦:B¦;B¦?B¦@B¦[B¦\B¦]B¦^B¦_B¦`B¦{B¦|B¦}B¦~B¦+B¦<B¦=B¦>B¦0¦9¦A¦B¦''B¦-B¦BB¦C');
        Observer.Expect('text normal', ' B¦!B¦"B¦#B¦$B¦%B¦&B¦(B¦)B¦*B¦,B¦.B¦/B¦:B¦;B¦?B¦@B¦[B¦\B¦]B¦^B¦_B¦`B¦{B¦|B¦}B¦~B¦+B¦<B¦=B¦>B¦0¦9¦A¦B¦''B¦-B¦BB¦C');
        Observer.Expect('text temporary', ' B¦!B¦"B¦#B¦$B¦%B¦&B¦(B¦)B¦*B¦,B¦.B¦/B¦:B¦;B¦?B¦@B¦[B¦\B¦]B¦^B¦_B¦`B¦{B¦|B¦}B¦~B¦+B¦<B¦=B¦>B¦0¦9¦A¦B¦''B¦-B¦BB¦C');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Interior()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, 2);
        Observer.Expect('code normal', 'A¦A B¦A!B¦A"B¦A#B¦A$B¦A%B¦A&B¦A(B¦A)B¦A*B¦A,B¦A.B¦A/B¦A:B¦A;B¦A?B¦A@B¦A[B¦A\B¦A]B¦A^B¦A_B¦A`B¦A{B¦A|B¦A}B¦A~B¦A+B¦A<B¦A=B¦A>B¦A0B¦A9B¦AA¦AAB¦AB¦A''B¦A-B¦ABB¦AC¦B');
        Observer.Expect('code temporary', 'A¦A B¦A!B¦A"B¦A#B¦A$B¦A%B¦A&B¦A(B¦A)B¦A*B¦A,B¦A.B¦A/B¦A:B¦A;B¦A?B¦A@B¦A[B¦A\B¦A]B¦A^B¦A_B¦A`B¦A{B¦A|B¦A}B¦A~B¦A+B¦A<B¦A=B¦A>B¦A0B¦A9B¦AA¦AAB¦AB¦A''B¦A-B¦ABB¦AC¦B');
        Observer.Expect('text normal', 'A¦A B¦A!B¦A"B¦A#B¦A$B¦A%B¦A&B¦A(B¦A)B¦A*B¦A,B¦A.B¦A/B¦A:B¦A;B¦A?B¦A@B¦A[B¦A\B¦A]B¦A^B¦A_B¦A`B¦A{B¦A|B¦A}B¦A~B¦A+B¦A<B¦A=B¦A>B¦A0B¦A9B¦AA¦AAB¦AB¦A''B¦A-B¦ABB¦AC¦B');
        Observer.Expect('text temporary', 'A¦A B¦A!B¦A"B¦A#B¦A$B¦A%B¦A&B¦A(B¦A)B¦A*B¦A,B¦A.B¦A/B¦A:B¦A;B¦A?B¦A@B¦A[B¦A\B¦A]B¦A^B¦A_B¦A`B¦A{B¦A|B¦A}B¦A~B¦A+B¦A<B¦A=B¦A>B¦A0B¦A9B¦AA¦AAB¦AB¦A''B¦A-B¦ABB¦AC¦B');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Trailing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, 3);
        Observer.Expect('code normal', 'A¦A''¦A-¦A!¦A"¦A#¦A$¦A%¦A&¦A(¦A)¦A*¦A,¦A.¦A/¦A:¦A;¦A?¦A@¦A[¦A\¦A]¦A^¦A_¦A`¦A{¦A|¦A}¦A~¦A+¦A<¦A=¦A>¦A0¦A9¦AA¦B');
        Observer.Expect('code temporary', 'A¦A''¦A-¦A!¦A"¦A#¦A$¦A%¦A&¦A(¦A)¦A*¦A,¦A.¦A/¦A:¦A;¦A?¦A@¦A[¦A\¦A]¦A^¦A_¦A`¦A{¦A|¦A}¦A~¦A+¦A<¦A=¦A>¦A0¦A9¦AA¦B');
        Observer.Expect('text normal', 'A¦A''¦A-¦A!¦A"¦A#¦A$¦A%¦A&¦A(¦A)¦A*¦A,¦A.¦A/¦A:¦A;¦A?¦A@¦A[¦A\¦A]¦A^¦A_¦A`¦A{¦A|¦A}¦A~¦A+¦A<¦A=¦A>¦A0¦A9¦AA¦B');
        Observer.Expect('text temporary', 'A¦A''¦A-¦A!¦A"¦A#¦A$¦A%¦A&¦A(¦A)¦A*¦A,¦A.¦A/¦A:¦A;¦A?¦A@¦A[¦A\¦A]¦A^¦A_¦A`¦A{¦A|¦A}¦A~¦A+¦A<¦A=¦A>¦A0¦A9¦AA¦B');
        Observer.Verify();
    end;

    [Test]
    procedure Order_IssueValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, 4);
        Observer.Expect('code normal', 'A.B¦AB¦A-B¦TTS.001¦TTSA¦TTS-A¦TTS-HD.001');
        Observer.Expect('code temporary', 'A.B¦AB¦A-B¦TTS.001¦TTSA¦TTS-A¦TTS-HD.001');
        Observer.Expect('text normal', 'A.B¦AB¦A-B¦TTS.001¦TTSA¦TTS-A¦TTS-HD.001');
        Observer.Expect('text temporary', 'A.B¦AB¦A-B¦TTS.001¦TTSA¦TTS-A¦TTS-HD.001');
        Observer.Verify();
    end;

    local procedure ObserveIssueFilters(var Observer: Codeunit "Probe Observer"; var K: Record "LT R6 Code Key"; Prefix: Text)
    begin
        SeedCode(K, 4);
        K.Ascending(false);
        Observer.Observe(Prefix + ' desc', ListCode(K));
        K.Ascending(true);
        K.SetRange(K, 'TTS.001', 'TTSA');
        Observer.Observe(Prefix + ' range TTS.001..TTSA', ListCode(K));
        K.SetRange(K, 'TTS-A', 'TTS.001');
        Observer.Observe(Prefix + ' range TTS-A..TTS.001', ListCode(K));
        K.SetFilter(K, '>%1', 'TTS.001');
        Observer.Observe(Prefix + ' gt TTS.001', ListCode(K));
        K.SetFilter(K, '<%1', 'TTS-HD.001');
        Observer.Observe(Prefix + ' lt TTS-HD.001', ListCode(K));
        K.SetFilter(K, '<%1', 'AB');
        Observer.Observe(Prefix + ' lt AB', ListCode(K));
        K.SetFilter(K, '>%1', 'A-B');
        Observer.Observe(Prefix + ' gt A-B', ListCode(K));
        K.SetFilter(K, '*-*');
        Observer.Observe(Prefix + ' wildcard hyphen', ListCode(K));
        K.SetRange(K);
    end;

    [Test]
    procedure IssueValues_CodeFilters()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT R6 Code Key";
        TempC: Record "LT R6 Code Key" temporary;
    begin
        ObserveIssueFilters(Observer, C, 'normal');
        ObserveIssueFilters(Observer, TempC, 'temporary');
        Observer.Expect('normal desc', 'TTS-HD.001¦TTS-A¦TTSA¦TTS.001¦A-B¦AB¦A.B');
        Observer.Expect('normal range TTS.001..TTSA', 'TTS.001¦TTSA');
        Observer.Expect('normal range TTS-A..TTS.001', '');
        Observer.Expect('normal gt TTS.001', 'TTSA¦TTS-A¦TTS-HD.001');
        Observer.Expect('normal lt TTS-HD.001', 'A.B¦AB¦A-B¦TTS.001¦TTSA¦TTS-A');
        Observer.Expect('normal lt AB', 'A.B');
        Observer.Expect('normal gt A-B', 'TTS.001¦TTSA¦TTS-A¦TTS-HD.001');
        Observer.Expect('normal wildcard hyphen', 'A-B¦TTS-A¦TTS-HD.001');
        Observer.Expect('temporary desc', 'TTS-HD.001¦TTS-A¦TTSA¦TTS.001¦A-B¦AB¦A.B');
        Observer.Expect('temporary range TTS.001..TTSA', 'TTS.001¦TTSA');
        Observer.Expect('temporary range TTS-A..TTS.001', '');
        Observer.Expect('temporary gt TTS.001', 'TTSA¦TTS-A¦TTS-HD.001');
        Observer.Expect('temporary lt TTS-HD.001', 'A.B¦AB¦A-B¦TTS.001¦TTSA¦TTS-A');
        Observer.Expect('temporary lt AB', 'A.B');
        Observer.Expect('temporary gt A-B', 'TTS.001¦TTSA¦TTS-A¦TTS-HD.001');
        Observer.Expect('temporary wildcard hyphen', 'A-B¦TTS-A¦TTS-HD.001');
        Observer.Verify();
    end;
}
