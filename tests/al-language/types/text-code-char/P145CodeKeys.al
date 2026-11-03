// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P145 Key (74900), LT P145 Text Key (74915)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FindSet order over a Code primary key and a Text primary key with digit keys, descending order, a Code secondary key, SetFilter/SetRange on a Code field with digit values, Get and Find with keys 10 and 0010
// BC versions: 29 (final facts are added after the measurement)

codeunit 74902 "LT P145 Code Keys"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Rec: Record "LT P145 Key";
        Keys: List of [Text];
        K: Text;
    begin
        Rec.DeleteAll();
        Keys.Add('A9');
        Keys.Add('10');
        Keys.Add('2');
        Keys.Add('1010999');
        Keys.Add('9');
        Keys.Add('A10');
        Keys.Add('0010');
        Keys.Add('109002');
        Keys.Add('010');
        foreach K in Keys do begin
            Rec.Init();
            Rec."Code" := CopyStr(K, 1, 20);
            Rec.Alt := Rec."Code";
            Rec.Txt := CopyStr(K, 1, 20);
            Rec.Insert();
        end;
    end;

    local procedure ListOf(var Rec: Record "LT P145 Key"): Text
    var
        Result: Text;
    begin
        if Rec.FindSet() then
            repeat
                Result += Rec."Code" + ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    local procedure ListAlt(var Rec: Record "LT P145 Key"): Text
    var
        Result: Text;
    begin
        Rec.SetCurrentKey(Alt);
        if Rec.FindSet() then
            repeat
                Result += Rec."Code" + ',';
            until Rec.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure P145_PrimaryKeyOrder_FindSet()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
    begin
        Seed();
        Observer.Observe('ascending', ListOf(Rec));
        Rec.Ascending(false);
        Observer.Observe('descending', ListOf(Rec));
        Rec.Reset();
        Rec.FindFirst();
        Observer.Observe('first', Rec."Code");
        Rec.FindLast();
        Observer.Observe('last', Rec."Code");
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('ascending', '0010,010,10,1010999,109002,2,9,A10,A9,');
        Observer.Expect('descending', 'A9,A10,9,2,109002,1010999,10,010,0010,');
        Observer.Expect('first', '0010');
        Observer.Expect('last', 'A9');
        Observer.Expect('count', '9');
        Observer.Verify();
    end;

    [Test]
    procedure P145_SecondaryCodeKeyOrder()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
    begin
        Seed();
        Observer.Observe('alt-ascending', ListAlt(Rec));
        Rec.Reset();
        Rec.SetCurrentKey(Alt);
        Rec.Ascending(false);
        Rec.FindSet();
        Observer.Observe('alt-descending-first', Rec."Code");
        Rec.FindLast();
        Observer.Observe('alt-descending-last', Rec."Code");
        Observer.Expect('alt-ascending', '0010,010,10,1010999,109002,2,9,A10,A9,');
        Observer.Expect('alt-descending-first', 'A9');
        Observer.Expect('alt-descending-last', '0010');
        Observer.Verify();
    end;

    [Test]
    procedure P145_TextPrimaryKeyOrder_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P145 Text Key";
        Keys: List of [Text];
        K: Text;
        Result: Text;
    begin
        T.DeleteAll();
        Keys.Add('A9');
        Keys.Add('10');
        Keys.Add('2');
        Keys.Add('1010999');
        Keys.Add('9');
        Keys.Add('A10');
        Keys.Add('0010');
        Keys.Add('109002');
        Keys.Add('010');
        foreach K in Keys do begin
            T.Init();
            T.Id := CopyStr(K, 1, 20);
            T.Insert();
        end;
        if T.FindSet() then
            repeat
                Result += T.Id + ',';
            until T.Next() = 0;
        Observer.Observe('text-key-order', Result);
        Observer.Expect('text-key-order', '0010,010,10,1010999,109002,2,9,A10,A9,');
        Observer.Verify();
    end;

    [Test]
    procedure P145_SetFilter_GreaterThan()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
    begin
        Seed();
        Rec.SetFilter("Code", '>%1', '9');
        Observer.Observe('gt-9', ListOf(Rec));
        Rec.SetFilter("Code", '>%1', '10');
        Observer.Observe('gt-10', ListOf(Rec));
        Rec.SetFilter("Code", '>%1', '0010');
        Observer.Observe('gt-0010', ListOf(Rec));
        Rec.SetFilter("Code", '>%1', '109002');
        Observer.Observe('gt-109002', ListOf(Rec));
        Rec.SetFilter("Code", '>%1', '1010999');
        Observer.Observe('gt-1010999', ListOf(Rec));
        Rec.SetFilter("Code", '>%1', 'A9');
        Observer.Observe('gt-A9', ListOf(Rec));
        Rec.SetFilter("Code", '>%1', '2');
        Observer.Observe('gt-2', ListOf(Rec));
        Rec.SetFilter("Code", '>=%1', '10');
        Observer.Observe('ge-10', ListOf(Rec));
        Rec.SetFilter("Code", '<%1', '9');
        Observer.Observe('lt-9', ListOf(Rec));
        Rec.SetFilter("Code", '<%1', '10');
        Observer.Observe('lt-10', ListOf(Rec));
        Rec.SetFilter("Code", '<%1', '109002');
        Observer.Observe('lt-109002', ListOf(Rec));
        Rec.SetFilter("Code", '<=%1', '1010999');
        Observer.Observe('le-1010999', ListOf(Rec));
        Rec.SetFilter("Code", '<%1', 'A10');
        Observer.Observe('lt-A10', ListOf(Rec));
        Observer.Observe('getfilter-last', Rec.GetFilter("Code"));
        Observer.Expect('gt-9', 'A10,A9,');
        Observer.Expect('gt-10', '1010999,109002,2,9,A10,A9,');
        Observer.Expect('gt-0010', '010,10,1010999,109002,2,9,A10,A9,');
        Observer.Expect('gt-109002', '2,9,A10,A9,');
        Observer.Expect('gt-1010999', '109002,2,9,A10,A9,');
        Observer.Expect('gt-A9', '');
        Observer.Expect('gt-2', '9,A10,A9,');
        Observer.Expect('ge-10', '10,1010999,109002,2,9,A10,A9,');
        Observer.Expect('lt-9', '0010,010,10,1010999,109002,2,');
        Observer.Expect('lt-10', '0010,010,');
        Observer.Expect('lt-109002', '0010,010,10,1010999,');
        Observer.Expect('le-1010999', '0010,010,10,1010999,');
        Observer.Expect('lt-A10', '0010,010,10,1010999,109002,2,9,');
        Observer.Expect('getfilter-last', '<A10');
        Observer.Verify();
    end;

    [Test]
    procedure P145_SetFilter_AltKey_GreaterThan()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
    begin
        Seed();
        Rec.SetFilter(Alt, '>%1', '10');
        Observer.Observe('alt-gt-10', ListAlt(Rec));
        Rec.SetFilter(Alt, '>%1', '9');
        Observer.Observe('alt-gt-9', ListAlt(Rec));
        Rec.SetFilter(Alt, '<%1', '10');
        Observer.Observe('alt-lt-10', ListAlt(Rec));
        Rec.SetFilter(Alt, '109002..1010999');
        Observer.Observe('alt-range-pair', ListAlt(Rec));
        Rec.SetFilter(Alt, '9..10');
        Observer.Observe('alt-range-9-10', ListAlt(Rec));
        Rec.SetFilter(Alt, '0010..10');
        Observer.Observe('alt-range-0010-10', ListAlt(Rec));
        Observer.Expect('alt-gt-10', '1010999,109002,2,9,A10,A9,');
        Observer.Expect('alt-gt-9', 'A10,A9,');
        Observer.Expect('alt-lt-10', '0010,010,');
        Observer.Expect('alt-range-pair', '');
        Observer.Expect('alt-range-9-10', '');
        Observer.Expect('alt-range-0010-10', '0010,010,10,');
        Observer.Verify();
    end;

    [Test]
    procedure P145_SetRange_Ranges()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
    begin
        Seed();
        Rec.SetRange("Code", '9', '10');
        Observer.Observe('range-9-10', ListOf(Rec));
        Observer.Observe('range-9-10-count', Format(Rec.Count()));
        Rec.SetRange("Code", '109002', '1010999');
        Observer.Observe('range-pair', ListOf(Rec));
        Rec.SetRange("Code", '1010999', '109002');
        Observer.Observe('range-pair-reversed', ListOf(Rec));
        Rec.SetRange("Code", '0010', '10');
        Observer.Observe('range-0010-10', ListOf(Rec));
        Rec.SetRange("Code", '2', '9');
        Observer.Observe('range-2-9', ListOf(Rec));
        Rec.SetRange("Code", 'A9', 'A10');
        Observer.Observe('range-A9-A10', ListOf(Rec));
        Rec.SetRange("Code", '10');
        Observer.Observe('range-single-10', ListOf(Rec));
        Rec.SetRange("Code", '0010');
        Observer.Observe('range-single-0010', ListOf(Rec));
        Rec.SetRange("Code", '010');
        Observer.Observe('range-single-010', ListOf(Rec));
        Rec.SetRange("Code", '10', '10');
        Observer.Observe('range-10-10', ListOf(Rec));
        Rec.SetRange("Code", '1', '99');
        Observer.Observe('range-1-99', ListOf(Rec));
        Rec.SetRange("Code", '1', '999999');
        Observer.Observe('range-1-999999', ListOf(Rec));
        Rec.SetRange("Code", '0', '9');
        Observer.Observe('range-0-9', ListOf(Rec));
        Observer.Observe('getfilter-last', Rec.GetFilter("Code"));
        Observer.Expect('range-9-10', '');
        Observer.Expect('range-9-10-count', '0');
        Observer.Expect('range-pair', '');
        Observer.Expect('range-pair-reversed', '1010999,109002,');
        Observer.Expect('range-0010-10', '0010,010,10,');
        Observer.Expect('range-2-9', '2,9,');
        Observer.Expect('range-A9-A10', '');
        Observer.Expect('range-single-10', '10,');
        Observer.Expect('range-single-0010', '0010,');
        Observer.Expect('range-single-010', '010,');
        Observer.Expect('range-10-10', '10,');
        Observer.Expect('range-1-99', '10,1010999,109002,2,9,');
        Observer.Expect('range-1-999999', '10,1010999,109002,2,9,');
        Observer.Expect('range-0-9', '0010,010,10,1010999,109002,2,9,');
        Observer.Expect('getfilter-last', '0..9');
        Observer.Verify();
    end;

    [Test]
    procedure P145_SetFilter_OrAndWildcard()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
    begin
        Seed();
        Rec.SetFilter("Code", '9|10');
        Observer.Observe('or-9-10', ListOf(Rec));
        Rec.SetFilter("Code", '10|0010');
        Observer.Observe('or-10-0010', ListOf(Rec));
        Rec.SetFilter("Code", '9..10|A9');
        Observer.Observe('range-or', ListOf(Rec));
        Rec.SetFilter("Code", '10*');
        Observer.Observe('wild-10', ListOf(Rec));
        Rec.SetFilter("Code", '*10');
        Observer.Observe('wild-end-10', ListOf(Rec));
        Rec.SetFilter("Code", '1..9');
        Observer.Observe('range-1-9', ListOf(Rec));
        Rec.SetFilter("Code", '>9&<109003');
        Observer.Observe('gt9-and-lt109003', ListOf(Rec));
        Rec.SetFilter("Code", '<>10');
        Observer.Observe('ne-10', ListOf(Rec));
        Observer.Expect('or-9-10', '10,9,');
        Observer.Expect('or-10-0010', '0010,10,');
        Observer.Expect('range-or', 'A9,');
        Observer.Expect('wild-10', '10,1010999,109002,');
        Observer.Expect('wild-end-10', '0010,010,10,A10,');
        Observer.Expect('range-1-9', '10,1010999,109002,2,9,');
        Observer.Expect('gt9-and-lt109003', '');
        Observer.Expect('ne-10', '0010,010,1010999,109002,2,9,A10,A9,');
        Observer.Verify();
    end;

    [Test]
    procedure P145_Get_TenAndLeadingZeros()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
        V: Code[20];
        T: Text;
    begin
        Seed();
        Observer.Observe('get-10', Format(Rec.Get('10')) + ':' + Rec."Code");
        Observer.Observe('get-0010', Format(Rec.Get('0010')) + ':' + Rec."Code");
        Observer.Observe('get-010', Format(Rec.Get('010')) + ':' + Rec."Code");
        Observer.Observe('get-0000010', Format(Rec.Get('0000010')));
        Observer.Observe('get-9', Format(Rec.Get('9')));
        Observer.Observe('get-09', Format(Rec.Get('09')));
        Observer.Observe('get-a9', Format(Rec.Get('a9')) + ':' + Rec."Code");
        Observer.Observe('get-A09', Format(Rec.Get('A09')));
        Observer.Observe('get-empty', Format(Rec.Get('')));
        Observer.Observe('get-10space', Format(Rec.Get('10 ')));
        V := '0010';
        Observer.Observe('get-codevar-0010', Format(Rec.Get(V)));
        T := '10';
        Observer.Observe('get-textvar-10', Format(Rec.Get(T)));
        T := '0010';
        Observer.Observe('get-textvar-0010', Format(Rec.Get(T)) + ':' + Rec."Code");
        T := '00010';
        Observer.Observe('get-textvar-00010', Format(Rec.Get(T)));
        Observer.Expect('get-10', 'Yes:10');
        Observer.Expect('get-0010', 'Yes:0010');
        Observer.Expect('get-010', 'Yes:010');
        Observer.Expect('get-0000010', 'No');
        Observer.Expect('get-9', 'Yes');
        Observer.Expect('get-09', 'No');
        Observer.Expect('get-a9', 'Yes:A9');
        Observer.Expect('get-A09', 'No');
        Observer.Expect('get-empty', 'No');
        Observer.Expect('get-10space', 'Yes');
        Observer.Expect('get-codevar-0010', 'Yes');
        Observer.Expect('get-textvar-10', 'Yes');
        Observer.Expect('get-textvar-0010', 'Yes:0010');
        Observer.Expect('get-textvar-00010', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P145_Find_SignsAroundDigitKeys()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
    begin
        Seed();
        Rec."Code" := '10';
        Observer.Observe('find-eq-10', Format(Rec.Find('=')) + ':' + Rec."Code");
        Rec."Code" := '10';
        Observer.Observe('find-next-after-10', Format(Rec.Find('>')) + ':' + Rec."Code");
        Rec."Code" := '10';
        Observer.Observe('find-prev-before-10', Format(Rec.Find('<')) + ':' + Rec."Code");
        Rec."Code" := '9';
        Observer.Observe('find-next-after-9', Format(Rec.Find('>')) + ':' + Rec."Code");
        Rec."Code" := '9';
        Observer.Observe('find-prev-before-9', Format(Rec.Find('<')) + ':' + Rec."Code");
        Rec."Code" := '109002';
        Observer.Observe('find-next-after-109002', Format(Rec.Find('>')) + ':' + Rec."Code");
        Rec."Code" := '1010999';
        Observer.Observe('find-prev-before-1010999', Format(Rec.Find('<')) + ':' + Rec."Code");
        Rec."Code" := '5';
        Observer.Observe('find-ge-5', Format(Rec.Find('=>')) + ':' + Rec."Code");
        Rec."Code" := '5';
        Observer.Observe('find-le-5', Format(Rec.Find('<=')) + ':' + Rec."Code");
        Rec."Code" := '00010';
        Observer.Observe('find-eq-00010', Format(Rec.Find('=')));
        Observer.Expect('find-eq-10', 'Yes:10');
        Observer.Expect('find-next-after-10', 'Yes:1010999');
        Observer.Expect('find-prev-before-10', 'Yes:010');
        Observer.Expect('find-next-after-9', 'Yes:A10');
        Observer.Expect('find-prev-before-9', 'Yes:2');
        Observer.Expect('find-next-after-109002', 'Yes:2');
        Observer.Expect('find-prev-before-1010999', 'Yes:10');
        Observer.Expect('find-ge-5', 'Yes:9');
        Observer.Expect('find-le-5', 'Yes:2');
        Observer.Expect('find-eq-00010', 'No');
        Observer.Verify();
    end;
}
