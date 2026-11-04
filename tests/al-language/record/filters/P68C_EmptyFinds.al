// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findfirst-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 70701, 70702, 70703
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FindFirst / FindLast / FindSet / Find / Get on an empty or filtered-out set with the result unused: error text and code per table
// BC versions: 29 (27 and 28 by CI)

codeunit 70722 "LT P68 Empty Finds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFlt(var R: Record "LT P68 Flt"; Op: Text)
    begin
        case Op of
            'FindFirst':
                R.FindFirst();
            'FindLast':
                R.FindLast();
            'FindSet':
                R.FindSet();
            'FindSetTrue':
                R.FindSet(true);
            'Find':
                R.Find();
            'Find-':
                R.Find('-');
            'Find+':
                R.Find('+');
            'Find=':
                R.Find('=');
            'Find>':
                R.Find('>');
            'Find<':
                R.Find('<');
            'Find>=':
                R.Find('>=');
            'Find<=':
                R.Find('<=');
            'Next':
                R.Next();
            'Get':
                R.Get(77);
        end;
    end;

    [TryFunction]
    local procedure TryKeyed(var R: Record "LT P68 Keyed"; Op: Text)
    begin
        case Op of
            'FindFirst':
                R.FindFirst();
            'FindLast':
                R.FindLast();
            'FindSet':
                R.FindSet();
            'Find':
                R.Find();
            'Find-':
                R.Find('-');
            'Find+':
                R.Find('+');
            'Find=':
                R.Find('=');
            'Next':
                R.Next();
            'Get':
                R.Get('NOPE');
        end;
    end;

    [TryFunction]
    local procedure TryComp(var R: Record "LT P68 Comp"; Op: Text)
    begin
        case Op of
            'FindFirst':
                R.FindFirst();
            'FindLast':
                R.FindLast();
            'FindSet':
                R.FindSet();
            'Find':
                R.Find();
            'Find-':
                R.Find('-');
            'Find+':
                R.Find('+');
            'Find=':
                R.Find('=');
            'Next':
                R.Next();
            'Get':
                R.Get(7, 8);
        end;
    end;

    local procedure RunFlt(var R: Record "LT P68 Flt"; Op: Text): Text
    begin
        ClearLastError();
        if TryFlt(R, Op) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RunKeyed(var R: Record "LT P68 Keyed"; Op: Text): Text
    begin
        ClearLastError();
        if TryKeyed(R, Op) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RunComp(var R: Record "LT P68 Comp"; Op: Text): Text
    begin
        ClearLastError();
        if TryComp(R, Op) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Ops(): List of [Text]
    var
        L: List of [Text];
    begin
        L.Add('FindFirst');
        L.Add('FindLast');
        L.Add('FindSet');
        L.Add('Find');
        L.Add('Find-');
        L.Add('Find+');
        L.Add('Find=');
        L.Add('Next');
        L.Add('Get');
        exit(L);
    end;

    [Test]
    procedure Empty_Flt_Table_Unused_Result()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        Op: Text;
    begin
        R.DeleteAll();
        foreach Op in Ops() do
            Observer.Observe('flt:' + Op, RunFlt(R, Op));
        Observer.Observe('flt:FindSetTrue', RunFlt(R, 'FindSetTrue'));
        Observer.Observe('flt:Find>', RunFlt(R, 'Find>'));
        Observer.Observe('flt:Find<', RunFlt(R, 'Find<'));
        Observer.Observe('flt:Find>=', RunFlt(R, 'Find>='));
        Observer.Observe('flt:Find<=', RunFlt(R, 'Find<='));
        Observer.Expect('flt:FindFirst', 'The LT P68 Flt table is empty.|DB:TableIsEmpty');
        Observer.Expect('flt:FindLast', 'The LT P68 Flt table is empty.|DB:TableIsEmpty');
        Observer.Expect('flt:FindSet', 'The LT P68 Flt table is empty.|DB:TableIsEmpty');
        Observer.Expect('flt:Find', 'The LT P68 Flt does not exist. Identification fields and values: No.=''0''|DB:RecordNotFound');
        Observer.Expect('flt:Find-', 'The LT P68 Flt table is empty.|DB:TableIsEmpty');
        Observer.Expect('flt:Find+', 'The LT P68 Flt table is empty.|DB:TableIsEmpty');
        Observer.Expect('flt:Find=', 'The LT P68 Flt does not exist. Identification fields and values: No.=''0''|DB:RecordNotFound');
        Observer.Expect('flt:Next', 'ok');
        Observer.Expect('flt:Get', 'The LT P68 Flt does not exist. Identification fields and values: No.=''77''|DB:RecordNotFound');
        Observer.Expect('flt:FindSetTrue', 'The LT P68 Flt table is empty.|DB:TableIsEmpty');
        Observer.Expect('flt:Find>', 'The LT P68 Flt does not exist. >\\Identification fields and values:\\No.=''0''|DB:RecordNotFound');
        Observer.Expect('flt:Find<', 'The LT P68 Flt does not exist. <\\Identification fields and values:\\No.=''0''|DB:RecordNotFound');
        Observer.Expect('flt:Find>=', 'The LT P68 Flt does not exist. Identification fields and values: No.=''0''|DB:RecordNotFound');
        Observer.Expect('flt:Find<=', 'The LT P68 Flt does not exist. Identification fields and values: No.=''0''|DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Empty_Keyed_Table_Unused_Result()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Keyed";
        Op: Text;
    begin
        R.DeleteAll();
        foreach Op in Ops() do
            Observer.Observe('keyed:' + Op, RunKeyed(R, Op));
        Observer.Expect('keyed:FindFirst', 'The LT P68 Keyed table is empty.|DB:TableIsEmpty');
        Observer.Expect('keyed:FindLast', 'The LT P68 Keyed table is empty.|DB:TableIsEmpty');
        Observer.Expect('keyed:FindSet', 'The LT P68 Keyed table is empty.|DB:TableIsEmpty');
        Observer.Expect('keyed:Find', 'The LT P68 Keyed does not exist. Identification fields and values: Code=''''|DB:RecordNotFound');
        Observer.Expect('keyed:Find-', 'The LT P68 Keyed table is empty.|DB:TableIsEmpty');
        Observer.Expect('keyed:Find+', 'The LT P68 Keyed table is empty.|DB:TableIsEmpty');
        Observer.Expect('keyed:Find=', 'The LT P68 Keyed does not exist. Identification fields and values: Code=''''|DB:RecordNotFound');
        Observer.Expect('keyed:Next', 'ok');
        Observer.Expect('keyed:Get', 'The LT P68 Keyed does not exist. Identification fields and values: Code=''NOPE''|DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Empty_Composite_Table_Unused_Result()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
        Op: Text;
    begin
        R.DeleteAll();
        foreach Op in Ops() do
            Observer.Observe('comp:' + Op, RunComp(R, Op));
        Observer.Expect('comp:FindFirst', 'The LT P68 Comp table is empty.|DB:TableIsEmpty');
        Observer.Expect('comp:FindLast', 'The LT P68 Comp table is empty.|DB:TableIsEmpty');
        Observer.Expect('comp:FindSet', 'The LT P68 Comp table is empty.|DB:TableIsEmpty');
        Observer.Expect('comp:Find', 'The LT P68 Comp does not exist. Identification fields and values: Grp=''0'',Sub=''0''|DB:RecordNotFound');
        Observer.Expect('comp:Find-', 'The LT P68 Comp table is empty.|DB:TableIsEmpty');
        Observer.Expect('comp:Find+', 'The LT P68 Comp table is empty.|DB:TableIsEmpty');
        Observer.Expect('comp:Find=', 'The LT P68 Comp does not exist. Identification fields and values: Grp=''0'',Sub=''0''|DB:RecordNotFound');
        Observer.Expect('comp:Next', 'ok');
        Observer.Expect('comp:Get', 'The LT P68 Comp does not exist. Identification fields and values: Grp=''7'',Sub=''8''|DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Empty_Asserterror_FindFirst_FindLast()
    var
        Observer: Codeunit "Probe Observer";
        F: Record "LT P68 Flt";
        K: Record "LT P68 Keyed";
        C: Record "LT P68 Comp";
    begin
        F.DeleteAll();
        K.DeleteAll();
        C.DeleteAll();
        asserterror F.FindFirst();
        Observer.ObserveError('flt-first');
        asserterror F.FindLast();
        Observer.ObserveError('flt-last');
        asserterror K.FindFirst();
        Observer.ObserveError('keyed-first');
        asserterror K.FindLast();
        Observer.ObserveError('keyed-last');
        asserterror C.FindFirst();
        Observer.ObserveError('comp-first');
        asserterror C.FindLast();
        Observer.ObserveError('comp-last');
        Observer.Expect('flt-first|text', 'The LT P68 Flt table is empty.');
        Observer.Expect('flt-first|code', 'DB:TableIsEmpty');
        Observer.Expect('flt-last|text', 'The LT P68 Flt table is empty.');
        Observer.Expect('flt-last|code', 'DB:TableIsEmpty');
        Observer.Expect('keyed-first|text', 'The LT P68 Keyed table is empty.');
        Observer.Expect('keyed-first|code', 'DB:TableIsEmpty');
        Observer.Expect('keyed-last|text', 'The LT P68 Keyed table is empty.');
        Observer.Expect('keyed-last|code', 'DB:TableIsEmpty');
        Observer.Expect('comp-first|text', 'The LT P68 Comp table is empty.');
        Observer.Expect('comp-first|code', 'DB:TableIsEmpty');
        Observer.Expect('comp-last|text', 'The LT P68 Comp table is empty.');
        Observer.Expect('comp-last|code', 'DB:TableIsEmpty');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Out_Flt_Table()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
        Op: Text;
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 3 do begin
            R.Init();
            R."No." := i;
            R.Int := i;
            R.Txt := CopyStr('T' + Format(i), 1, 30);
            R.Insert();
        end;
        R.SetRange(Int, 99);
        Observer.Observe('count', Format(R.Count()));
        foreach Op in Ops() do
            Observer.Observe('filtered:' + Op, RunFlt(R, Op));
        R.Reset();
        R.SetFilter(Txt, 'Z*');
        asserterror R.FindFirst();
        Observer.ObserveError('text-filter-first');
        R.Reset();
        R.SetRange("No.", 50, 60);
        asserterror R.FindLast();
        Observer.ObserveError('pk-range-last');
        Observer.Expect('count', '0');
        Observer.Expect('filtered:FindFirst', 'There is no LT P68 Flt within the filter.\\Filters: Int: 99|DB:NothingInsideFilter');
        Observer.Expect('filtered:FindLast', 'There is no LT P68 Flt within the filter.\\Filters: Int: 99|DB:NothingInsideFilter');
        Observer.Expect('filtered:FindSet', 'There is no LT P68 Flt within the filter.\\Filters: Int: 99|DB:NothingInsideFilter');
        Observer.Expect('filtered:Find', 'The LT P68 Flt does not exist. Identification fields and values: No.=''3''|DB:RecordNotFound');
        Observer.Expect('filtered:Find-', 'There is no LT P68 Flt within the filter.\\Filters: Int: 99|DB:NothingInsideFilter');
        Observer.Expect('filtered:Find+', 'There is no LT P68 Flt within the filter.\\Filters: Int: 99|DB:NothingInsideFilter');
        Observer.Expect('filtered:Find=', 'The LT P68 Flt does not exist. Identification fields and values: No.=''3''|DB:RecordNotFound');
        Observer.Expect('filtered:Next', 'ok');
        Observer.Expect('filtered:Get', 'The LT P68 Flt does not exist. Identification fields and values: No.=''77''|DB:RecordNotFound');
        Observer.Expect('text-filter-first|text', 'There is no LT P68 Flt within the filter.\\Filters: Txt: Z*');
        Observer.Expect('text-filter-first|code', 'DB:NothingInsideFilter');
        Observer.Expect('pk-range-last|text', 'There is no LT P68 Flt within the filter.\\Filters: No.: 50..60');
        Observer.Expect('pk-range-last|code', 'DB:NothingInsideFilter');
        Observer.Verify();
    end;

    [Test]
    procedure Filtered_Out_Comp_Table()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Comp";
    begin
        R.DeleteAll();
        R.Init();
        R.Grp := 1;
        R.Sub := 1;
        R.Insert();
        R.SetRange(Grp, 2);
        asserterror R.FindFirst();
        Observer.ObserveError('grp-first');
        R.SetRange(Grp, 1);
        R.SetRange(Sub, 5);
        asserterror R.FindLast();
        Observer.ObserveError('grp-sub-last');
        R.Reset();
        asserterror R.Get(1, 2);
        Observer.ObserveError('get-miss');
        asserterror R.Get(1);
        Observer.ObserveError('get-partial');
        Observer.Expect('grp-first|text', 'There is no LT P68 Comp within the filter.\\Filters: Grp: 2');
        Observer.Expect('grp-first|code', 'DB:NothingInsideFilter');
        Observer.Expect('grp-sub-last|text', 'There is no LT P68 Comp within the filter.\\Filters: Grp: 1, Sub: 5');
        Observer.Expect('grp-sub-last|code', 'DB:NothingInsideFilter');
        Observer.Expect('get-miss|text', 'The LT P68 Comp does not exist. Identification fields and values: Grp=''1'',Sub=''2''');
        Observer.Expect('get-miss|code', 'DB:RecordNotFound');
        Observer.Expect('get-partial|text', 'The LT P68 Comp does not exist. Identification fields and values: Grp=''1'',Sub=''0''');
        Observer.Expect('get-partial|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Miss_Keyed_And_Flt()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT P68 Keyed";
        F: Record "LT P68 Flt";
    begin
        K.DeleteAll();
        F.DeleteAll();
        asserterror K.Get('X');
        Observer.ObserveError('keyed-get');
        asserterror K.Get('');
        Observer.ObserveError('keyed-get-blank');
        asserterror F.Get(0);
        Observer.ObserveError('flt-get-zero');
        asserterror F.Get(-5);
        Observer.ObserveError('flt-get-neg');
        Observer.Expect('keyed-get|text', 'The LT P68 Keyed does not exist. Identification fields and values: Code=''X''');
        Observer.Expect('keyed-get|code', 'DB:RecordNotFound');
        Observer.Expect('keyed-get-blank|text', 'The LT P68 Keyed does not exist. Identification fields and values: Code=''''');
        Observer.Expect('keyed-get-blank|code', 'DB:RecordNotFound');
        Observer.Expect('flt-get-zero|text', 'The LT P68 Flt does not exist. Identification fields and values: No.=''0''');
        Observer.Expect('flt-get-zero|code', 'DB:RecordNotFound');
        Observer.Expect('flt-get-neg|text', 'The LT P68 Flt does not exist. Identification fields and values: No.=''-5''');
        Observer.Expect('flt-get-neg|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}
