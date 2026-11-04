// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/bigtext/bigtext-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against BC 29 (P93); the lead measures the facts on a local BC 29 and turns them into assertions.
// Facts: BigText.AddText with a position, GetSubText overloads, Length, TextPos
// BC versions: 29 (27 and 28 by CI)

codeunit 70324 "LT P93 BigText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAdd(var Big: BigText; S: Text; Pos: Integer)
    begin
        Big.AddText(S, Pos);
    end;

    [TryFunction]
    local procedure TryAddBig(var Big: BigText; Other: BigText; Pos: Integer)
    begin
        Big.AddText(Other, Pos);
    end;

    [TryFunction]
    local procedure TrySub(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean; var R: Text; var Ret: Integer)
    begin
        if WithLen then
            Ret := Big.GetSubText(R, Pos, Len)
        else
            Ret := Big.GetSubText(R, Pos);
    end;

    [TryFunction]
    local procedure TrySubBig(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean; var R: Text; var Ret: Integer)
    var
        Target: BigText;
    begin
        if WithLen then
            Ret := Big.GetSubText(Target, Pos, Len)
        else
            Ret := Big.GetSubText(Target, Pos);
        if Target.Length() > 0 then
            Target.GetSubText(R, 1);
    end;

    local procedure Content(Big: BigText): Text
    var
        T: Text;
    begin
        if Big.Length() = 0 then
            exit('');
        Big.GetSubText(T, 1);
        exit(T);
    end;

    local procedure Add(var Big: BigText; S: Text; Pos: Integer): Text
    begin
        if TryAdd(Big, S, Pos) then
            exit('ok len=' + Format(Big.Length()) + ' content=' + Content(Big));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' len=' + Format(Big.Length()));
    end;

    local procedure AddB(var Big: BigText; S: Text; Pos: Integer): Text
    var
        Other: BigText;
    begin
        Other.AddText(S);
        if TryAddBig(Big, Other, Pos) then
            exit('ok len=' + Format(Big.Length()) + ' content=' + Content(Big));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' len=' + Format(Big.Length()));
    end;

    local procedure Sub(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean): Text
    var
        R: Text;
        Ret: Integer;
    begin
        R := 'unset';
        if TrySub(Big, Pos, Len, WithLen, R, Ret) then
            exit('ret=' + Format(Ret) + ' text=[' + R + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure SubB(Big: BigText; Pos: Integer; Len: Integer; WithLen: Boolean): Text
    var
        R: Text;
        Ret: Integer;
    begin
        R := 'unset';
        if TrySubBig(Big, Pos, Len, WithLen, R, Ret) then
            exit('ret=' + Format(Ret) + ' text=[' + R + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Mk(S: Text): BigText
    var
        Big: BigText;
    begin
        Big.AddText(S);
        exit(Big);
    end;

    [Test]
    procedure AddText_Position_Text()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Observer.Observe('start-empty', Add(Big, 'abc', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('start', Add(Big, 'XY', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('middle', Add(Big, 'XY', 3));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('end', Add(Big, 'XY', 7));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('last-char', Add(Big, 'XY', 6));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('beyond', Add(Big, 'XY', 9));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('far-beyond', Add(Big, 'XY', 1000));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('zero', Add(Big, 'XY', 0));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('negative', Add(Big, 'XY', -1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('empty-text', Add(Big, '', 3));
        Clear(Big);
        Observer.Observe('empty-big-beyond', Add(Big, 'XY', 5));
        Clear(Big);
        Observer.Observe('empty-big-zero', Add(Big, 'XY', 0));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('repeat-1', Add(Big, 'XY', 3));
        Observer.Observe('repeat-2', Add(Big, 'Z', 3));
        Observer.Observe('repeat-end', Add(Big, 'E', Big.Length() + 1));
        Observer.Expect('start-empty', 'ok len=3 content=abc');
        Observer.Expect('start', 'ok len=8 content=XYabcdef');
        Observer.Expect('middle', 'ok len=8 content=abXYcdef');
        Observer.Expect('end', 'ok len=8 content=abcdefXY');
        Observer.Expect('last-char', 'ok len=8 content=abcdeXYf');
        Observer.Expect('beyond', 'ok len=8 content=abcdefXY');
        Observer.Expect('far-beyond', 'ok len=8 content=abcdefXY');
        Observer.Expect('zero', 'error:The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange len=6');
        Observer.Expect('negative', 'error:The value of INSSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange len=6');
        Observer.Expect('empty-text', 'ok len=6 content=abcdef');
        Observer.Expect('empty-big-beyond', 'ok len=2 content=XY');
        Observer.Expect('empty-big-zero', 'error:The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange len=0');
        Observer.Expect('repeat-1', 'ok len=8 content=abXYcdef');
        Observer.Expect('repeat-2', 'ok len=9 content=abZXYcdef');
        Observer.Expect('repeat-end', 'ok len=10 content=abZXYcdefE');
        Observer.Verify();
    end;

    [Test]
    procedure AddText_Position_Big()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Observer.Observe('start-empty', AddB(Big, 'abc', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('start', AddB(Big, 'XY', 1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('middle', AddB(Big, 'XY', 3));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('end', AddB(Big, 'XY', 7));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('beyond', AddB(Big, 'XY', 9));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('zero', AddB(Big, 'XY', 0));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('negative', AddB(Big, 'XY', -1));
        Clear(Big);
        Big.AddText('abcdef');
        Observer.Observe('empty-other', AddB(Big, '', 3));
        Clear(Big);
        Big.AddText('abcdef');
        Big.AddText(Big, 4);
        Observer.Observe('self-middle', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Observer.Expect('start-empty', 'ok len=3 content=abc');
        Observer.Expect('start', 'ok len=8 content=XYabcdef');
        Observer.Expect('middle', 'ok len=8 content=abXYcdef');
        Observer.Expect('end', 'ok len=8 content=abcdefXY');
        Observer.Expect('beyond', 'ok len=8 content=abcdefXY');
        Observer.Expect('zero', 'error:The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange len=6');
        Observer.Expect('negative', 'error:The value of INSSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange len=6');
        Observer.Expect('empty-other', 'ok len=6 content=abcdef');
        Observer.Expect('self-middle', 'len=12 content=abcabcdefdef');
        Observer.Verify();
    end;

    [Test]
    procedure AddText_NoPosition()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
        Other: BigText;
    begin
        Big.AddText('abc');
        Big.AddText('def');
        Observer.Observe('text-append', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Other.AddText('ghi');
        Big.AddText(Other);
        Observer.Observe('big-append', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Big.AddText('');
        Observer.Observe('empty-append', 'len=' + Format(Big.Length()));
        Big.AddText('jkl', 1);
        Observer.Observe('pos1', 'len=' + Format(Big.Length()) + ' content=' + Content(Big));
        Clear(Big);
        Observer.Observe('cleared-len', Format(Big.Length()));
        Big.AddText('ä€');
        Observer.Observe('unicode-len', Format(Big.Length()));
        Observer.Observe('unicode', Content(Big));
        Observer.Expect('text-append', 'len=6 content=abcdef');
        Observer.Expect('big-append', 'len=9 content=abcdefghi');
        Observer.Expect('empty-append', 'len=9');
        Observer.Expect('pos1', 'len=12 content=jklabcdefghi');
        Observer.Expect('cleared-len', '0');
        Observer.Expect('unicode-len', '2');
        Observer.Expect('unicode', 'ä€');
        Observer.Verify();
    end;

    [Test]
    procedure GetSubText_Text()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Big.AddText('abcdef');
        Observer.Observe('all', Sub(Big, 1, 0, false));
        Observer.Observe('from3', Sub(Big, 3, 0, false));
        Observer.Observe('last', Sub(Big, 6, 0, false));
        Observer.Observe('len-mid', Sub(Big, 2, 3, true));
        Observer.Observe('len-exact', Sub(Big, 4, 3, true));
        Observer.Observe('len-too-long', Sub(Big, 4, 10, true));
        Observer.Observe('len-zero', Sub(Big, 2, 0, true));
        Observer.Observe('len-negative', Sub(Big, 2, -1, true));
        Observer.Observe('pos-after-end', Sub(Big, 7, 0, false));
        Observer.Observe('pos-after-end-len', Sub(Big, 7, 1, true));
        Observer.Observe('pos-far', Sub(Big, 100, 1, true));
        Observer.Observe('pos-zero', Sub(Big, 0, 0, false));
        Observer.Observe('pos-zero-len', Sub(Big, 0, 2, true));
        Observer.Observe('pos-negative', Sub(Big, -1, 2, true));
        Observer.Observe('len-1', Sub(Big, 1, 1, true));
        Observer.Observe('empty-big', Sub(Mk(''), 1, 0, false));
        Observer.Observe('empty-big-len', Sub(Mk(''), 1, 3, true));
        Observer.Expect('all', 'ret=6 text=[abcdef]');
        Observer.Expect('from3', 'ret=4 text=[cdef]');
        Observer.Expect('last', 'ret=1 text=[f]');
        Observer.Expect('len-mid', 'ret=3 text=[bcd]');
        Observer.Expect('len-exact', 'ret=3 text=[def]');
        Observer.Expect('len-too-long', 'ret=3 text=[def]');
        Observer.Expect('len-zero', 'ret=0 text=[]');
        Observer.Expect('len-negative', 'error:The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.|OutsidePermittedRange');
        Observer.Expect('pos-after-end', 'ret=0 text=[]');
        Observer.Expect('pos-after-end-len', 'ret=0 text=[]');
        Observer.Expect('pos-far', 'ret=0 text=[]');
        Observer.Expect('pos-zero', 'error:The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange');
        Observer.Expect('pos-zero-len', 'error:The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange');
        Observer.Expect('pos-negative', 'error:The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange');
        Observer.Expect('len-1', 'ret=1 text=[a]');
        Observer.Expect('empty-big', 'ret=0 text=[]');
        Observer.Expect('empty-big-len', 'ret=0 text=[]');
        Observer.Verify();
    end;

    [Test]
    procedure GetSubText_Big()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Big.AddText('abcdef');
        Observer.Observe('all', SubB(Big, 1, 0, false));
        Observer.Observe('from3', SubB(Big, 3, 0, false));
        Observer.Observe('len-mid', SubB(Big, 2, 3, true));
        Observer.Observe('len-too-long', SubB(Big, 4, 10, true));
        Observer.Observe('len-zero', SubB(Big, 2, 0, true));
        Observer.Observe('len-negative', SubB(Big, 2, -1, true));
        Observer.Observe('pos-after-end', SubB(Big, 7, 0, false));
        Observer.Observe('pos-far', SubB(Big, 100, 1, true));
        Observer.Observe('pos-zero', SubB(Big, 0, 0, false));
        Observer.Observe('pos-negative', SubB(Big, -1, 2, true));
        Observer.Observe('empty-big', SubB(Mk(''), 1, 0, false));
        Observer.Expect('all', 'ret=6 text=[abcdef]');
        Observer.Expect('from3', 'ret=4 text=[cdef]');
        Observer.Expect('len-mid', 'ret=3 text=[bcd]');
        Observer.Expect('len-too-long', 'ret=3 text=[def]');
        Observer.Expect('len-zero', 'ret=0 text=[unset]');
        Observer.Expect('len-negative', 'error:The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.|OutsidePermittedRange');
        Observer.Expect('pos-after-end', 'ret=0 text=[unset]');
        Observer.Expect('pos-far', 'ret=0 text=[unset]');
        Observer.Expect('pos-zero', 'error:The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange');
        Observer.Expect('pos-negative', 'error:The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.|OutsidePermittedRange');
        Observer.Expect('empty-big', 'ret=0 text=[unset]');
        Observer.Verify();
    end;

    [Test]
    procedure GetSubText_TargetOverwritten()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
        Target: BigText;
        T: Text;
        Ret: Integer;
    begin
        Big.AddText('abcdef');
        Target.AddText('old-content');
        Ret := Big.GetSubText(Target, 2, 2);
        Observer.Observe('big-target-ret', Format(Ret));
        Observer.Observe('big-target-len', Format(Target.Length()));
        Observer.Observe('big-target', Content(Target));
        T := 'old';
        Ret := Big.GetSubText(T, 2, 2);
        Observer.Observe('text-target-ret', Format(Ret));
        Observer.Observe('text-target', T);
        T := 'old';
        Ret := Big.GetSubText(T, 4, 0);
        Observer.Observe('text-len0-ret', Format(Ret));
        Observer.Observe('text-len0', '[' + T + ']');
        Observer.Expect('big-target-ret', '2');
        Observer.Expect('big-target-len', '2');
        Observer.Expect('big-target', 'bc');
        Observer.Expect('text-target-ret', '2');
        Observer.Expect('text-target', 'bc');
        Observer.Expect('text-len0-ret', '0');
        Observer.Expect('text-len0', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure LengthAndTextPos()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigText;
    begin
        Observer.Observe('len-empty', Format(Big.Length()));
        Big.AddText('Hello World Hello');
        Observer.Observe('len', Format(Big.Length()));
        Observer.Observe('pos-hello', Format(Big.TextPos('Hello')));
        Observer.Observe('pos-world', Format(Big.TextPos('World')));
        Observer.Observe('pos-lower', Format(Big.TextPos('hello')));
        Observer.Observe('pos-missing', Format(Big.TextPos('xyz')));
        Observer.Observe('pos-empty', Format(Big.TextPos('')));
        Observer.Observe('pos-space', Format(Big.TextPos(' ')));
        Observer.Observe('pos-whole', Format(Big.TextPos('Hello World Hello')));
        Observer.Observe('pos-longer', Format(Big.TextPos('Hello World Hello!')));
        Observer.Observe('pos-last-char', Format(Big.TextPos('o')));
        Big.AddText('XY', 1);
        Observer.Observe('len-after-insert', Format(Big.Length()));
        Observer.Observe('pos-after-insert', Format(Big.TextPos('Hello')));
        Observer.Observe('pos-inserted', Format(Big.TextPos('XY')));
        Observer.Expect('len-empty', '0');
        Observer.Expect('len', '17');
        Observer.Expect('pos-hello', '1');
        Observer.Expect('pos-world', '7');
        Observer.Expect('pos-lower', '0');
        Observer.Expect('pos-missing', '0');
        Observer.Expect('pos-empty', '0');
        Observer.Expect('pos-space', '6');
        Observer.Expect('pos-whole', '1');
        Observer.Expect('pos-longer', '0');
        Observer.Expect('pos-last-char', '5');
        Observer.Expect('len-after-insert', '19');
        Observer.Expect('pos-after-insert', '3');
        Observer.Expect('pos-inserted', '1');
        Observer.Verify();
    end;
}
