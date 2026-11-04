// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-code-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table LT CodeDig Row (71456)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Code[20] comparisons that the committed types/lt-code-digits-page-run-view/P145CodeCompare.al does not cover: '-5' vs '3', '1A' vs '10', '' vs '0' (both directions), the same through record fields, and the order of a secondary Code key and of Code filters over these values.
// BC versions: 29 (27 and 28 by CI)

table 71456 "LT CodeDig Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Code"; Code[20]) { }
        field(3; Alt; Code[20]) { }
        field(4; Txt; Text[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(Sec; "Code") { }
    }
}

codeunit 71457 "LT CodeDig Compare"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cmp(var Observer: Codeunit "Probe Observer"; Name: Text; A: Code[20]; B: Code[20])
    begin
        Observer.Observe(Name, 'gt=' + Format(A > B) + ' lt=' + Format(A < B) + ' eq=' + Format(A = B) + ' ne=' + Format(A <> B) + ' ge=' + Format(A >= B) + ' le=' + Format(A <= B));
    end;

    local procedure CmpFields(var Observer: Codeunit "Probe Observer"; Name: Text; A: Code[20]; B: Code[20])
    var
        Rec: Record "LT CodeDig Row";
    begin
        Rec."Code" := A;
        Rec.Alt := B;
        Observer.Observe(Name, 'gt=' + Format(Rec."Code" > Rec.Alt) + ' lt=' + Format(Rec."Code" < Rec.Alt) + ' eq=' + Format(Rec."Code" = Rec.Alt) + ' ge=' + Format(Rec."Code" >= Rec.Alt) + ' le=' + Format(Rec."Code" <= Rec.Alt));
    end;

    local procedure Seed(Values: List of [Text])
    var
        Row: Record "LT CodeDig Row";
        V: Text;
        N: Integer;
    begin
        Row.DeleteAll();
        foreach V in Values do begin
            N += 1;
            Row.Init();
            Row.Id := N;
            Row."Code" := CopyStr(V, 1, 20);
            Row.Insert();
        end;
    end;

    local procedure Joined(var Row: Record "LT CodeDig Row"): Text
    var
        Result: Text;
        Item: Text;
    begin
        if Row.FindSet() then
            repeat
                Item := Row."Code";
                if Item = '' then
                    Item := '<empty>';
                if Result <> '' then
                    Result += '|';
                Result += Item;
            until Row.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure P182b_CodeVars_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cmp(Observer, 'm5-3', '-5', '3');
        Cmp(Observer, '3-m5', '3', '-5');
        Cmp(Observer, 'm5-m10', '-5', '-10');
        Cmp(Observer, 'm10-m5', '-10', '-5');
        Cmp(Observer, 'm5-m5', '-5', '-5');
        Cmp(Observer, 'm0-0', '-0', '0');
        Cmp(Observer, 'p5-3', '+5', '3');
        Cmp(Observer, '5-p5', '5', '+5');
        Cmp(Observer, 'm5-empty', '-5', '');
        Cmp(Observer, 'm5-0', '-5', '0');
        Cmp(Observer, 'm1-9', '-1', '9');
        Cmp(Observer, 'm5-A', '-5', 'A');
        Observer.Expect('m5-3', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('3-m5', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('m5-m10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('m10-m5', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('m5-m5', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('m0-0', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('p5-3', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('5-p5', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('m5-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('m5-0', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('m1-9', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('m5-A', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_CodeVars_DigitThenLetter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cmp(Observer, '1A-10', '1A', '10');
        Cmp(Observer, '10-1A', '10', '1A');
        Cmp(Observer, '1A-1B', '1A', '1B');
        Cmp(Observer, '1A-2', '1A', '2');
        Cmp(Observer, '2-1A', '2', '1A');
        Cmp(Observer, '10A-9A', '10A', '9A');
        Cmp(Observer, '9A-10A', '9A', '10A');
        Cmp(Observer, '1A-1a', '1A', '1a');
        Cmp(Observer, '1A-1', '1A', '1');
        Cmp(Observer, '1-1A', '1', '1A');
        Cmp(Observer, '1A-A1', '1A', 'A1');
        Cmp(Observer, '01A-1A', '01A', '1A');
        Cmp(Observer, '1A-empty', '1A', '');
        Observer.Expect('1A-10', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('10-1A', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('1A-1B', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('1A-2', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('2-1A', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('10A-9A', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('9A-10A', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('1A-1a', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('1A-1', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('1-1A', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('1A-A1', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('01A-1A', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('1A-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_CodeVars_EmptyVersusZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cmp(Observer, 'empty-0', '', '0');
        Cmp(Observer, '0-empty', '0', '');
        Cmp(Observer, 'empty-00', '', '00');
        Cmp(Observer, '00-empty', '00', '');
        Cmp(Observer, 'empty-space', '', ' ');
        Cmp(Observer, 'space-empty', ' ', '');
        Cmp(Observer, 'empty-A', '', 'A');
        Cmp(Observer, 'A-empty', 'A', '');
        Cmp(Observer, 'empty-m1', '', '-1');
        Cmp(Observer, 'm1-empty', '-1', '');
        Cmp(Observer, 'empty-1', '', '1');
        Cmp(Observer, '1-empty', '1', '');
        Cmp(Observer, 'empty-empty', '', '');
        Observer.Expect('empty-0', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('0-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('empty-00', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('00-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('empty-space', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('space-empty', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Expect('empty-A', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('A-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('empty-m1', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('m1-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('empty-1', 'gt=No lt=Yes eq=No ne=Yes ge=No le=Yes');
        Observer.Expect('1-empty', 'gt=Yes lt=No eq=No ne=Yes ge=Yes le=No');
        Observer.Expect('empty-empty', 'gt=No lt=No eq=Yes ne=No ge=Yes le=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_CodeFields_Negative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CmpFields(Observer, 'm5-3', '-5', '3');
        CmpFields(Observer, '3-m5', '3', '-5');
        CmpFields(Observer, 'm5-m10', '-5', '-10');
        CmpFields(Observer, 'm10-m5', '-10', '-5');
        CmpFields(Observer, 'm5-m5', '-5', '-5');
        Observer.Expect('m5-3', 'gt=Yes lt=No eq=No ge=Yes le=No');
        Observer.Expect('3-m5', 'gt=No lt=Yes eq=No ge=No le=Yes');
        Observer.Expect('m5-m10', 'gt=Yes lt=No eq=No ge=Yes le=No');
        Observer.Expect('m10-m5', 'gt=No lt=Yes eq=No ge=No le=Yes');
        Observer.Expect('m5-m5', 'gt=No lt=No eq=Yes ge=Yes le=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_CodeFields_DigitThenLetter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CmpFields(Observer, '1A-10', '1A', '10');
        CmpFields(Observer, '10-1A', '10', '1A');
        CmpFields(Observer, '1A-2', '1A', '2');
        CmpFields(Observer, '9A-10A', '9A', '10A');
        CmpFields(Observer, '1A-1a', '1A', '1a');
        Observer.Expect('1A-10', 'gt=Yes lt=No eq=No ge=Yes le=No');
        Observer.Expect('10-1A', 'gt=No lt=Yes eq=No ge=No le=Yes');
        Observer.Expect('1A-2', 'gt=Yes lt=No eq=No ge=Yes le=No');
        Observer.Expect('9A-10A', 'gt=Yes lt=No eq=No ge=Yes le=No');
        Observer.Expect('1A-1a', 'gt=No lt=No eq=Yes ge=Yes le=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_CodeFields_EmptyVersusZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CmpFields(Observer, 'empty-0', '', '0');
        CmpFields(Observer, '0-empty', '0', '');
        CmpFields(Observer, 'empty-00', '', '00');
        CmpFields(Observer, 'empty-A', '', 'A');
        CmpFields(Observer, 'empty-m1', '', '-1');
        Observer.Expect('empty-0', 'gt=No lt=Yes eq=No ge=No le=Yes');
        Observer.Expect('0-empty', 'gt=Yes lt=No eq=No ge=Yes le=No');
        Observer.Expect('empty-00', 'gt=No lt=Yes eq=No ge=No le=Yes');
        Observer.Expect('empty-A', 'gt=No lt=Yes eq=No ge=No le=Yes');
        Observer.Expect('empty-m1', 'gt=No lt=Yes eq=No ge=No le=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_CodeFields_StoredValuesCompared()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CodeDig Row";
        Other: Record "LT CodeDig Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row."Code" := '-5';
        Row.Alt := '1A';
        Row.Insert();
        Row.Id := 2;
        Row."Code" := '3';
        Row.Alt := '10';
        Row.Insert();
        Row.Get(1);
        Other.Get(2);
        Observer.Observe('stored-m5-vs-3', 'gt=' + Format(Row."Code" > Other."Code") + ' lt=' + Format(Row."Code" < Other."Code"));
        Observer.Observe('stored-1A-vs-10', 'gt=' + Format(Row.Alt > Other.Alt) + ' lt=' + Format(Row.Alt < Other.Alt));
        Observer.Observe('stored-m5-vs-literal3', 'gt=' + Format(Row."Code" > '3') + ' lt=' + Format(Row."Code" < '3'));
        Observer.Observe('stored-10-vs-literal1A', 'gt=' + Format(Other.Alt > '1A') + ' lt=' + Format(Other.Alt < '1A'));
        Row.Txt := '-5';
        Observer.Observe('text-field-m5-vs-code-3', 'gt=' + Format(Row.Txt > Other."Code") + ' lt=' + Format(Row.Txt < Other."Code"));
        Row.Txt := '1A';
        Observer.Observe('text-field-1A-vs-code-10', 'gt=' + Format(Row.Txt > Other.Alt) + ' lt=' + Format(Row.Txt < Other.Alt));
        Row.Txt := '';
        Observer.Observe('text-field-empty-vs-code-0', 'gt=' + Format(Row.Txt > '0') + ' lt=' + Format(Row.Txt < '0'));
        Observer.Expect('stored-m5-vs-3', 'gt=Yes lt=No');
        Observer.Expect('stored-1A-vs-10', 'gt=Yes lt=No');
        Observer.Expect('stored-m5-vs-literal3', 'gt=No lt=Yes');
        Observer.Expect('stored-10-vs-literal1A', 'gt=No lt=Yes');
        Observer.Expect('text-field-m5-vs-code-3', 'gt=No lt=Yes');
        Observer.Expect('text-field-1A-vs-code-10', 'gt=Yes lt=No');
        Observer.Expect('text-field-empty-vs-code-0', 'gt=No lt=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_SecondaryKeyOrder_Mixed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CodeDig Row";
        Values: List of [Text];
    begin
        Values.Add('10');
        Values.Add('-5');
        Values.Add('3');
        Values.Add('1A');
        Values.Add('0');
        Values.Add('9');
        Values.Add('A');
        Values.Add('');
        Seed(Values);
        Row.SetCurrentKey("Code");
        Observer.Observe('ascending', Joined(Row));
        Row.Ascending(false);
        Observer.Observe('descending', Joined(Row));
        Observer.Expect('ascending', '<empty>|0|10|1A|3|-5|9|A');
        Observer.Expect('descending', 'A|9|-5|3|1A|10|0|<empty>');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_SecondaryKeyOrder_DigitsAndEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CodeDig Row";
        Values: List of [Text];
    begin
        Values.Add('');
        Values.Add('0');
        Values.Add('00');
        Values.Add('1');
        Values.Add('01');
        Values.Add('10');
        Values.Add('-1');
        Values.Add('-10');
        Seed(Values);
        Row.SetCurrentKey("Code");
        Observer.Observe('ascending', Joined(Row));
        Observer.Expect('ascending', '<empty>|0|00|01|1|-1|10|-10');
        Observer.Verify();
    end;

    [Test]
    procedure P182b_Filters_OverMixedValues()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CodeDig Row";
        Values: List of [Text];
    begin
        Values.Add('10');
        Values.Add('-5');
        Values.Add('3');
        Values.Add('1A');
        Values.Add('0');
        Values.Add('9');
        Values.Add('A');
        Values.Add('');
        Seed(Values);
        Row.SetCurrentKey("Code");
        Row.SetRange("Code", '-5', '3');
        Observer.Observe('range-m5-3', Joined(Row));
        Row.SetRange("Code", '1A', '9');
        Observer.Observe('range-1A-9', Joined(Row));
        Row.SetFilter("Code", '<%1', '10');
        Observer.Observe('lt-10', Joined(Row));
        Row.SetFilter("Code", '>%1', '3');
        Observer.Observe('gt-3', Joined(Row));
        Row.SetFilter("Code", '>%1', '0');
        Observer.Observe('gt-0', Joined(Row));
        Row.SetFilter("Code", '<=%1', '0');
        Observer.Observe('le-0', Joined(Row));
        Row.SetFilter("Code", '>=%1', '1A');
        Observer.Observe('ge-1A', Joined(Row));
        Row.SetRange("Code", '');
        Observer.Observe('range-empty', Joined(Row));
        Row.SetRange("Code", '0');
        Observer.Observe('range-0', Joined(Row));
        Row.SetRange("Code", '-5');
        Observer.Observe('range-m5', Joined(Row));
        Observer.Expect('range-m5-3', '');
        Observer.Expect('range-1A-9', '1A|3|-5|9');
        Observer.Expect('lt-10', '<empty>|0');
        Observer.Expect('gt-3', '-5|9|A');
        Observer.Expect('gt-0', '10|1A|3|-5|9|A');
        Observer.Expect('le-0', '<empty>|0');
        Observer.Expect('ge-1A', '1A|3|-5|9|A');
        Observer.Expect('range-empty', '<empty>');
        Observer.Expect('range-0', '0');
        Observer.Expect('range-m5', '-5');
        Observer.Verify();
    end;
}
