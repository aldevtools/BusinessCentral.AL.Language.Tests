// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/bigtext/bigtext-data-type
// Scope: in-scope
// Fixtures used: table 74200, codeunit 69160 "Probe Observer"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74205 "LT StT BigText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fresh(var Rec: Record "LT StT Rec")
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
    end;

    local procedure Rep(Piece: Text; Times: Integer): Text
    var
        i: Integer;
        R: Text;
    begin
        for i := 1 to Times do
            R += Piece;
        exit(R);
    end;

    [Test]
    procedure EmptyBigText()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('length', Format(Big.Length()));
        Observer.Observe('textpos', Format(Big.TextPos('a')));
        Observer.Observe('textpos-empty', Format(Big.TextPos('')));
        Big.GetSubText(T, 1, 1);
        Observer.Observe('getsubtext', 'no error');
        Observer.Expect('length', '0');
        Observer.Expect('textpos', '0');
        Observer.Expect('textpos-empty', '0');
        Observer.Expect('getsubtext', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure AddTextAppend()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Big.AddText('Hello');
        Observer.Observe('len1', Format(Big.Length()));
        Big.AddText(' World');
        Observer.Observe('len2', Format(Big.Length()));
        Big.GetSubText(T, 1);
        Observer.Observe('all', T);
        Big.AddText('');
        Observer.Observe('len-after-empty', Format(Big.Length()));
        Observer.Expect('len1', '5');
        Observer.Expect('len2', '11');
        Observer.Expect('all', 'Hello World');
        Observer.Expect('len-after-empty', '11');
        Observer.Verify();
    end;

    [Test]
    procedure AddTextAtPosition()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Big.AddText('abcdef');
        Big.AddText('XY', 3);
        Big.GetSubText(T, 1);
        Observer.Observe('insert-mid', T);
        Observer.Observe('len', Format(Big.Length()));
        Big.AddText('Z', 1);
        Big.GetSubText(T, 1);
        Observer.Observe('insert-start', T);
        Big.AddText('Q', Big.Length() + 1);
        Big.GetSubText(T, 1);
        Observer.Observe('insert-end', T);
        Observer.Expect('insert-mid', 'abXYcdef');
        Observer.Expect('len', '8');
        Observer.Expect('insert-start', 'ZabXYcdef');
        Observer.Expect('insert-end', 'ZabXYcdefQ');
        Observer.Verify();
    end;

    [Test]
    procedure AddTextPositionErrors()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
    begin
        Big.AddText('abc');
        asserterror Big.AddText('x', 0);
        Observer.ObserveError('pos0');
        asserterror Big.AddText('x', -1);
        Observer.ObserveError('neg');
        Big.AddText('x', 5);
        Observer.Observe('beyond-plus-one', 'no error');
        Observer.Observe('len', Format(Big.Length()));
        Observer.Expect('pos0|text', 'The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('pos0|code', 'OutsidePermittedRange');
        Observer.Expect('neg|text', 'The value of INSSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('neg|code', 'OutsidePermittedRange');
        Observer.Expect('beyond-plus-one', 'no error');
        Observer.Expect('len', '4');
        Observer.Verify();
    end;

    [Test]
    procedure GetSubTextForms()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
        N: Integer;
    begin
        Big.AddText('0123456789');
        N := Big.GetSubText(T, 3, 4);
        Observer.Observe('n-3-4', Format(N));
        Observer.Observe('t-3-4', T);
        N := Big.GetSubText(T, 8);
        Observer.Observe('n-8', Format(N));
        Observer.Observe('t-8', T);
        N := Big.GetSubText(T, 8, 100);
        Observer.Observe('n-8-100', Format(N));
        Observer.Observe('t-8-100', T);
        N := Big.GetSubText(T, 1, 0);
        Observer.Observe('n-1-0', Format(N));
        Observer.Observe('t-1-0', T);
        N := Big.GetSubText(T, 10, 1);
        Observer.Observe('n-10-1', Format(N));
        Observer.Observe('t-10-1', T);
        Observer.Expect('n-3-4', '4');
        Observer.Expect('t-3-4', '2345');
        Observer.Expect('n-8', '3');
        Observer.Expect('t-8', '789');
        Observer.Expect('n-8-100', '3');
        Observer.Expect('t-8-100', '789');
        Observer.Expect('n-1-0', '0');
        Observer.Expect('t-1-0', '');
        Observer.Expect('n-10-1', '1');
        Observer.Expect('t-10-1', '9');
        Observer.Verify();
    end;

    [Test]
    procedure GetSubTextErrors()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
        N: Integer;
    begin
        Big.AddText('0123456789');
        asserterror N := Big.GetSubText(T, 0, 1);
        Observer.ObserveError('pos0');
        N := Big.GetSubText(T, 11, 1);
        Observer.Observe('pos-len-plus-1', 'no error');
        N := Big.GetSubText(T, 20);
        Observer.Observe('pos-20', 'no error');
        asserterror N := Big.GetSubText(T, 1, -1);
        Observer.ObserveError('neg-len');
        asserterror N := Big.GetSubText(T, -3, 1);
        Observer.ObserveError('neg-pos');
        Observer.Expect('pos0|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('pos0|code', 'OutsidePermittedRange');
        Observer.Expect('pos-len-plus-1', 'no error');
        Observer.Expect('pos-20', 'no error');
        Observer.Expect('neg-len|text', 'The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Observer.Expect('neg-len|code', 'OutsidePermittedRange');
        Observer.Expect('neg-pos|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: -3. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('neg-pos|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure TextPosForms()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
    begin
        Big.AddText('abcabcABC');
        Observer.Observe('bc', Format(Big.TextPos('bc')));
        Observer.Observe('abc', Format(Big.TextPos('abc')));
        Observer.Observe('upper', Format(Big.TextPos('ABC')));
        Observer.Observe('lower-vs-upper', Format(Big.TextPos('aBc')));
        Observer.Observe('missing', Format(Big.TextPos('zzz')));
        Observer.Observe('empty', Format(Big.TextPos('')));
        Observer.Observe('whole', Format(Big.TextPos('abcabcABC')));
        Observer.Observe('longer', Format(Big.TextPos('abcabcABCx')));
        Observer.Observe('last', Format(Big.TextPos('C')));
        Observer.Expect('bc', '2');
        Observer.Expect('abc', '1');
        Observer.Expect('upper', '7');
        Observer.Expect('lower-vs-upper', '0');
        Observer.Expect('missing', '0');
        Observer.Expect('empty', '0');
        Observer.Expect('whole', '1');
        Observer.Expect('longer', '0');
        Observer.Expect('last', '9');
        Observer.Verify();
    end;

    [Test]
    procedure LengthLargeText()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
        N: Integer;
    begin
        Big.AddText(Rep('0123456789', 5000));
        Observer.Observe('len1', Format(Big.Length()));
        Big.AddText(Rep('ab', 20000));
        Observer.Observe('len2', Format(Big.Length()));
        N := Big.GetSubText(T, 49999, 4);
        Observer.Observe('n', Format(N));
        Observer.Observe('around-join', T);
        Observer.Observe('textpos-ab', Format(Big.TextPos('ab')));
        Observer.Observe('textpos-9a', Format(Big.TextPos('9ab')));
        Observer.Expect('len1', '50000');
        Observer.Expect('len2', '90000');
        Observer.Expect('n', '4');
        Observer.Expect('around-join', '89ab');
        Observer.Expect('textpos-ab', '50001');
        Observer.Expect('textpos-9a', '50000');
        Observer.Verify();
    end;

    [Test]
    procedure ConvertTextAndBack()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Big.AddText('direct');
        T := Format(Big);
        Observer.Observe('format', T);
        Big.GetSubText(T, 1, 3);
        Observer.Observe('sub', T);
        Observer.Expect('format', 'direct');
        Observer.Expect('sub', 'dir');
        Observer.Verify();
    end;

    [Test]
    procedure ClearBigText()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
    begin
        Big.AddText('abc');
        Clear(Big);
        Observer.Observe('len-after-clear', Format(Big.Length()));
        Big.AddText('z');
        Observer.Observe('len-after-add', Format(Big.Length()));
        Observer.Expect('len-after-clear', '0');
        Observer.Expect('len-after-add', '1');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToStreamAndRead()
    var
        Rec: Record "LT StT Rec";
        Big: BigText;
        Big2: BigText;
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Big.AddText('big text content');
        Rec.Data.CreateOutStream(Out);
        Big.Write(Out);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('blob-len', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Big2.Read(Ins);
        Observer.Observe('read-len', Format(Big2.Length()));
        Big2.GetSubText(T, 1);
        Observer.Observe('read-text', T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('blob-len', '16');
        Observer.Expect('read-len', '16');
        Observer.Expect('read-text', 'big text content');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadReplacesContent()
    var
        Rec: Record "LT StT Rec";
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('stream');
        Rec.Modify();
        Big.AddText('previous content');
        Rec.Data.CreateInStream(Ins);
        Big.Read(Ins);
        Observer.Observe('len', Format(Big.Length()));
        Big.GetSubText(T, 1);
        Observer.Observe('text', T);
        Observer.Expect('len', '6');
        Observer.Expect('text', 'stream');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromEmptyStream()
    var
        Rec: Record "LT StT Rec";
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
    begin
        Fresh(Rec);
        Big.AddText('previous');
        Rec.Data.CreateInStream(Ins);
        Big.Read(Ins);
        Observer.Observe('len', Format(Big.Length()));
        Observer.Expect('len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure WriteNonAscii()
    var
        Rec: Record "LT StT Rec";
        Big: BigText;
        Big2: BigText;
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        T[1] := 228;
        T[2] := 8364;
        T[3] := 'x';
        Big.AddText(T);
        Rec.Data.CreateOutStream(Out);
        Big.Write(Out);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('blob-len', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Big2.Read(Ins);
        Observer.Observe('read-len', Format(Big2.Length()));
        Big2.GetSubText(T, 1);
        Observer.Observe('same', Format(Format(T[2])));
        Observer.Expect('blob-len', '3');
        Observer.Expect('read-len', '3');
        Observer.Expect('same', '€');
        Observer.Verify();
    end;

    [Test]
    procedure WriteReadLargeText()
    var
        Rec: Record "LT StT Rec";
        Big: BigText;
        Big2: BigText;
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
    begin
        Fresh(Rec);
        Big.AddText(Rep('0123456789', 10000));
        Rec.Data.CreateOutStream(Out);
        Big.Write(Out);
        Rec.Modify();
        Rec.CalcFields(Data);
        Observer.Observe('blob-len', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Big2.Read(Ins);
        Observer.Observe('read-len', Format(Big2.Length()));
        Observer.Expect('blob-len', '100000');
        Observer.Expect('read-len', '100000');
        Observer.Verify();
    end;

    [Test]
    procedure ReadBigTextThenText()
    var
        Rec: Record "LT StT Rec";
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('line1');
        Out.WriteText();
        Out.WriteText('line2');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Big.Read(Ins);
        Observer.Observe('len', Format(Big.Length()));
        Big.GetSubText(T, 1);
        Observer.Observe('text', T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('len', '12');
        Observer.Expect('text', 'line1\r\nline2');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 51: the BigText boundary cases that AddTextPositionErrors,
    // GetSubTextForms and TextPosForms above leave open: AddText far past the end, AddText of an empty text, and what
    // GetSubText returns for a position past the end.
    [Test]
    procedure LT_BU_BigText_MoreBoundaries()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
        N: Integer;
    begin
        Big.AddText('abc');
        Big.AddText('x', 999);
        Big.GetSubText(T, 1);
        Observer.Observe('add at 999', T + '|' + Format(Big.Length()));
        Big.AddText('', 1);
        Big.GetSubText(T, 1);
        Observer.Observe('add empty at 1', T + '|' + Format(Big.Length()));
        T := 'old';
        N := Big.GetSubText(T, 5);
        Observer.Observe('subtext past end', '[' + T + ']|' + Format(N));
        T := 'old';
        N := Big.GetSubText(T, 4, 10);
        Observer.Observe('subtext last char long length', '[' + T + ']|' + Format(N));
        T := 'old';
        N := Big.GetSubText(T, 2, 0);
        Observer.Observe('subtext length 0', '[' + T + ']|' + Format(N));
        Clear(Big);
        T := 'old';
        N := Big.GetSubText(T, 1);
        Observer.Observe('subtext of empty', '[' + T + ']|' + Format(N));
        Observer.Observe('textpos in empty', Format(Big.TextPos('a')));
        Observer.Expect('add at 999', 'abcx|4');
        Observer.Expect('add empty at 1', 'abcx|4');
        Observer.Expect('subtext past end', '[]|0');
        Observer.Expect('subtext last char long length', '[x]|1');
        Observer.Expect('subtext length 0', '[]|0');
        Observer.Expect('subtext of empty', '[]|0');
        Observer.Expect('textpos in empty', '0');
        Observer.Verify();
    end;

    // Writer SN (2026-10-25, runtime hand-off refuse-json-streams "BigText.AddText position > len+1; GetSubText position > len; empty BigText GetSubText"):
    // the text and length after AddText beyond the end, and what GetSubText returns and leaves in its Text argument past the end.
    [TryFunction]
    local procedure TryAddText(var Big: BigText; Piece: Text; Pos: Integer)
    begin
        Big.AddText(Piece, Pos);
    end;

    [Test]
    procedure AddTextBeyondEnd()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Big.AddText('abc');
        Big.AddText('x', 5);
        Big.GetSubText(T, 1);
        Observer.Observe('plus-two-text', T);
        Observer.Observe('plus-two-len', Format(Big.Length()));
        if not TryAddText(Big, 'y', 100) then
            Observer.ObserveError('far');
        Big.GetSubText(T, 1);
        Observer.Observe('far-text', T);
        Observer.Observe('far-len', Format(Big.Length()));
        Clear(Big);
        if not TryAddText(Big, 'z', 3) then
            Observer.ObserveError('empty-pos3');
        Big.GetSubText(T, 1);
        Observer.Observe('empty-pos3-text', T);
        Observer.Observe('empty-pos3-len', Format(Big.Length()));
        Observer.Expect('plus-two-text', 'abcx');
        Observer.Expect('plus-two-len', '4');
        Observer.Expect('far-text', 'abcxy');
        Observer.Expect('far-len', '5');
        Observer.Expect('empty-pos3-text', 'z');
        Observer.Expect('empty-pos3-len', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GetSubTextPastEnd()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
        N: Integer;
    begin
        Big.AddText('0123456789');
        T := 'keep';
        N := Big.GetSubText(T, 11, 1);
        Observer.Observe('n-11-1', Format(N));
        Observer.Observe('t-11-1', T);
        T := 'keep';
        N := Big.GetSubText(T, 20);
        Observer.Observe('n-20', Format(N));
        Observer.Observe('t-20', T);
        T := 'keep';
        N := Big.GetSubText(T, 11);
        Observer.Observe('n-11', Format(N));
        Observer.Observe('t-11', T);
        T := 'keep';
        N := Big.GetSubText(T, 10, 5);
        Observer.Observe('n-10-5', Format(N));
        Observer.Observe('t-10-5', T);
        Observer.Expect('n-11-1', '0');
        Observer.Expect('t-11-1', '');
        Observer.Expect('n-20', '0');
        Observer.Expect('t-20', '');
        Observer.Expect('n-11', '0');
        Observer.Expect('t-11', '');
        Observer.Expect('n-10-5', '1');
        Observer.Expect('t-10-5', '9');
        Observer.Verify();
    end;

    [Test]
    procedure GetSubTextOfEmptyBigText()
    var
        Big: BigText;
        Observer: Codeunit "Probe Observer";
        T: Text;
        N: Integer;
    begin
        T := 'keep';
        N := Big.GetSubText(T, 1, 1);
        Observer.Observe('n-1-1', Format(N));
        Observer.Observe('t-1-1', T);
        T := 'keep';
        N := Big.GetSubText(T, 1);
        Observer.Observe('n-1', Format(N));
        Observer.Observe('t-1', T);
        T := 'keep';
        N := Big.GetSubText(T, 5, 2);
        Observer.Observe('n-5-2', Format(N));
        Observer.Observe('t-5-2', T);
        T := 'keep';
        asserterror N := Big.GetSubText(T, 0, 1);
        Observer.ObserveError('pos0');
        Observer.Expect('n-1-1', '0');
        Observer.Expect('t-1-1', '');
        Observer.Expect('n-1', '0');
        Observer.Expect('t-1', '');
        Observer.Expect('n-5-2', '0');
        Observer.Expect('t-5-2', '');
        Observer.Expect('pos0|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('pos0|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;
}
