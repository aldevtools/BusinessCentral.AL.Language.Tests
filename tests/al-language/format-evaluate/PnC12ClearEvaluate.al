// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows: Clear (fixes-7) "Clear of an array passed by var"; Evaluate (fixes-7) "Format(Enum, 0, 9) itself, Evaluate(Enum, 'lowercase name'), Evaluate(DateFormula, text, 2)"; InitValue of a DateFormula (fixes-7) "A calculable formula text such as '1Y' is kept as written"
// BC versions: 29 (27 and 28 by CI)

enum 71090 "LT PnC Color"
{
    Extensible = true;

    value(0; Red) { }
    value(5; "Dark Green") { }
    value(7; Blue) { Caption = 'Bleu'; }
}

table 71091 "LT PnC DateFormula Init"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; DF; DateFormula) { InitValue = '1Y'; }
        field(3; DF2; DateFormula) { InitValue = '<1M+CM>'; }
        field(4; DF3; DateFormula) { }
        field(5; Qty; Integer) { InitValue = 7; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 71114 "LT PnC Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ClearByVar(var Items: array[3] of Integer)
    begin
        Clear(Items);
    end;

    local procedure ClearTextByVar(var Items: array[3] of Text[10])
    begin
        Clear(Items);
    end;

    local procedure ClearOne(var Items: array[3] of Integer)
    begin
        Clear(Items[2]);
    end;

    [Test]
    procedure Clear_Array_ByVar()
    var
        Observer: Codeunit "Probe Observer";
        Ints: array[3] of Integer;
        Texts: array[3] of Text[10];
        i: Integer;
    begin
        for i := 1 to 3 do begin
            Ints[i] := i * 100;
            Texts[i] := 'x' + Format(i);
        end;
        ClearByVar(Ints);
        for i := 1 to 3 do begin
            Observer.Observe('ints' + Format(i), Format(Ints[i]));
        end;
        ClearTextByVar(Texts);
        for i := 1 to 3 do begin
            Observer.Observe('texts' + Format(i), '[' + Texts[i] + ']');
        end;
        for i := 1 to 3 do begin
            Ints[i] := i;
        end;
        ClearOne(Ints);
        Observer.Observe('oneCleared', Format(Ints[1]) + ',' + Format(Ints[2]) + ',' + Format(Ints[3]));
        Clear(Ints);
        Observer.Observe('allCleared', Format(Ints[1]) + ',' + Format(Ints[2]) + ',' + Format(Ints[3]));
        Observer.Expect('ints1', '0');
        Observer.Expect('ints2', '0');
        Observer.Expect('ints3', '0');
        Observer.Expect('texts1', '[]');
        Observer.Expect('texts2', '[]');
        Observer.Expect('texts3', '[]');
        Observer.Expect('oneCleared', '1,0,3');
        Observer.Expect('allCleared', '0,0,0');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_Json_And_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        JO: JsonObject;
        JA: JsonArray;
        T: Record "LT PnC Rec" temporary;
        Txt: Text;
    begin
        JO.Add('a', 1);
        Clear(JO);
        JO.WriteTo(Txt);
        Observer.Observe('jsonObject', Txt);
        JA.Add(1);
        Clear(JA);
        JA.WriteTo(Txt);
        Observer.Observe('jsonArray', Txt);
        T."No." := 1;
        T.Insert();
        T.SetRange("No.", 5);
        Clear(T);
        Observer.Observe('temporary.filters', T.GetFilters());
        Observer.Observe('temporary.count', Format(T.Count()));
        Observer.Expect('jsonObject', '{}');
        Observer.Expect('jsonArray', '[]');
        Observer.Expect('temporary.filters', '');
        Observer.Expect('temporary.count', '1');
        Observer.Verify();
    end;
}

codeunit 71115 "LT PnC Evaluate Enum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Format_Enum_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT PnC Color";
        i: Integer;
    begin
        C := C::"Dark Green";
        Observer.Observe('n0', Format(C, 0, 0));
        Observer.Observe('n1', Format(C, 0, 1));
        Observer.Observe('n2', Format(C, 0, 2));
        Observer.Observe('n9', Format(C, 0, 9));
        Observer.Expect('n0', 'Dark Green');
        Observer.Expect('n1', 'Dark Green');
        Observer.Expect('n2', '5');
        Observer.Expect('n9', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_Enum_Texts()
    var
        Observer: Codeunit "Probe Observer";
        C: Enum "LT PnC Color";
        ok: Boolean;
    begin
        ok := Evaluate(C, 'Dark Green');
        Observer.Observe('exact', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, 'dark green');
        Observer.Observe('lowercase', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, 'DARK GREEN');
        Observer.Observe('uppercase', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, ' Blue');
        Observer.Observe('leadingSpace', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, 'Bleu');
        Observer.Observe('caption', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, '7');
        Observer.Observe('ordinalText', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, '7', 9);
        Observer.Observe('ordinalText.f9', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, 'Blue', 9);
        Observer.Observe('name.f9', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, '6', 9);
        Observer.Observe('unknownOrdinal.f9', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, '');
        Observer.Observe('empty', Format(ok) + '|' + Format(C, 0, 2));
        C := C::Red;
        ok := Evaluate(C, 'nothing');
        Observer.Observe('nomatch', Format(ok) + '|' + Format(C, 0, 2));
        Observer.Expect('exact', 'Yes|5');
        Observer.Expect('lowercase', 'Yes|5');
        Observer.Expect('uppercase', 'Yes|5');
        Observer.Expect('leadingSpace', 'Yes|7');
        Observer.Expect('caption', 'Yes|7');
        Observer.Expect('ordinalText', 'Yes|7');
        Observer.Expect('ordinalText.f9', 'Yes|7');
        Observer.Expect('name.f9', 'Yes|7');
        Observer.Expect('unknownOrdinal.f9', 'Yes|6');
        Observer.Expect('empty', 'No|0');
        Observer.Expect('nomatch', 'No|0');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_DateFormula_Format2()
    var
        Observer: Codeunit "Probe Observer";
        DF: DateFormula;
        ok: Boolean;
    begin
        ok := Evaluate(DF, '1M+CM', 2);
        Observer.Observe('english.f2', Format(ok) + '|' + Format(DF));
        ok := Evaluate(DF, '1M+CM', 0);
        Observer.Observe('english.f0', Format(ok) + '|' + Format(DF));
        ok := Evaluate(DF, '1T', 2);
        Observer.Observe('german1T.f2', Format(ok) + '|' + Format(DF));
        ok := Evaluate(DF, '1T', 0);
        Observer.Observe('german1T.f0', Format(ok) + '|' + Format(DF));
        ok := Evaluate(DF, '1D', 2);
        Observer.Observe('1D.f2', Format(ok) + '|' + Format(DF));
        ok := Evaluate(DF, '1D', 9);
        Observer.Observe('1D.f9', Format(ok) + '|' + Format(DF));
        ok := Evaluate(DF, '<1D>', 2);
        Observer.Observe('brackets.f2', Format(ok) + '|' + Format(DF));
        ok := Evaluate(DF, 'xyz', 2);
        Observer.Observe('garbled.f2', Format(ok));
        ok := Evaluate(DF, '', 2);
        Observer.Observe('empty.f2', Format(ok) + '|' + Format(DF));
        Observer.Expect('english.f2', 'Yes|1M+CM');
        Observer.Expect('english.f0', 'Yes|1M+CM');
        Observer.Expect('german1T.f2', 'No|1M+CM');
        Observer.Expect('german1T.f0', 'No|1M+CM');
        Observer.Expect('1D.f2', 'Yes|1D');
        Observer.Expect('1D.f9', 'Yes|1D');
        Observer.Expect('brackets.f2', 'Yes|1D');
        Observer.Expect('garbled.f2', 'No');
        Observer.Expect('empty.f2', 'Yes|');
        Observer.Verify();
    end;
}

codeunit 71116 "LT PnC DateFormula Init Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure InitValue_DateFormula()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnC DateFormula Init";
        D: Date;
    begin
        T.DeleteAll();
        T.Init();
        Observer.Observe('df', Format(T.DF));
        Observer.Observe('df2', Format(T.DF2));
        Observer.Observe('df3', Format(T.DF3));
        Observer.Observe('count', Format(T.Qty));
        D := CalcDate(T.DF, DMY2Date(15, 3, 2024));
        Observer.Observe('calc1Y', Format(D, 0, 9));
        D := CalcDate(T.DF2, DMY2Date(15, 3, 2024));
        Observer.Observe('calc1M+CM', Format(D, 0, 9));
        T.Insert();
        T.Get(0);
        Observer.Observe('df.afterGet', Format(T.DF));
        Clear(T);
        Observer.Observe('df.afterClear', Format(T.DF));
        Observer.Observe('count.afterClear', Format(T.Qty));
        Observer.Expect('df', '1Y');
        Observer.Expect('df2', '1M+CM');
        Observer.Expect('df3', '');
        Observer.Expect('count', '7');
        Observer.Expect('calc1Y', '2025-03-15');
        Observer.Expect('calc1M+CM', '2024-04-30');
        Observer.Expect('df.afterGet', '1Y');
        Observer.Expect('df.afterClear', '1Y');
        Observer.Expect('count.afterClear', '7');
        Observer.Verify();
    end;
}
