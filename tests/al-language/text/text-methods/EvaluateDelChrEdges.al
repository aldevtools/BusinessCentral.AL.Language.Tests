// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: (1) Evaluate into a Text[n] and a Code[n] with a source longer than n (the result used, then the stored text and its length), and into a Text or Code
// with a format number; (2) DelChr with a Where text of one to five characters from = < > (and a repeated one), against a text with leading, inner and trailing matches.
// Object id 67859.

codeunit 67859 "LT Evaluate DelChr Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEvalText5(Source: Text; var Result: Text; var Ok: Boolean)
    var
        T: Text[5];
    begin
        Ok := Evaluate(T, Source);
        Result := T;
    end;

    [TryFunction]
    local procedure TryEvalCode5(Source: Text; var Result: Text; var Ok: Boolean)
    var
        C: Code[5];
    begin
        Ok := Evaluate(C, Source);
        Result := C;
    end;

    [TryFunction]
    local procedure TryEvalFormat(Source: Text; FormatNumber: Integer; var Result: Text; var Ok: Boolean)
    var
        T: Text;
    begin
        Ok := Evaluate(T, Source, FormatNumber);
        Result := T;
    end;

    [TryFunction]
    local procedure TryEvalCodeFormat(Source: Text; FormatNumber: Integer; var Result: Text; var Ok: Boolean)
    var
        C: Code[20];
    begin
        Ok := Evaluate(C, Source, FormatNumber);
        Result := C;
    end;

    local procedure Show(Called: Boolean; Ok: Boolean; Result: Text): Text
    begin
        if not Called then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('returned=' + Format(Ok) + '|result=[' + Result + ']|len=' + Format(StrLen(Result)));
    end;

    [Test]
    procedure Evaluate_TextLongerThanTheTarget()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
        Called: Boolean;
    begin
        ClearLastError();
        Called := TryEvalText5('abcdefghij', Result, Ok);
        Observer.Observe('text5_ten_chars', Show(Called, Ok, Result));
        ClearLastError();
        Called := TryEvalText5('abcde', Result, Ok);
        Observer.Observe('text5_five_chars', Show(Called, Ok, Result));
        ClearLastError();
        Called := TryEvalText5('abcdef', Result, Ok);
        Observer.Observe('text5_six_chars', Show(Called, Ok, Result));
        ClearLastError();
        Called := TryEvalCode5('abcdefghij', Result, Ok);
        Observer.Observe('code5_ten_chars', Show(Called, Ok, Result));
        ClearLastError();
        Called := TryEvalCode5('abcdef', Result, Ok);
        Observer.Observe('code5_six_chars', Show(Called, Ok, Result));
        ClearLastError();
        Called := TryEvalCode5('ab de', Result, Ok);
        Observer.Observe('code5_with_space', Show(Called, Ok, Result));
        Observer.Expect('text5_ten_chars', 'returned=No|result=[]|len=0');
        Observer.Expect('text5_five_chars', 'returned=Yes|result=[abcde]|len=5');
        Observer.Expect('text5_six_chars', 'returned=No|result=[]|len=0');
        Observer.Expect('code5_ten_chars', 'returned=No|result=[]|len=0');
        Observer.Expect('code5_six_chars', 'returned=No|result=[]|len=0');
        Observer.Expect('code5_with_space', 'returned=Yes|result=[AB DE]|len=5');
        Observer.Verify();
    end;

    local procedure FormatCase(var Observer: Codeunit "Probe Observer"; Number: Integer)
    var
        Result: Text;
        Ok: Boolean;
        Called: Boolean;
    begin
        ClearLastError();
        Called := TryEvalFormat('a<b>&c', Number, Result, Ok);
        Observer.Observe('text_format_' + Format(Number), Show(Called, Ok, Result));
        ClearLastError();
        Called := TryEvalCodeFormat('a<b>&c', Number, Result, Ok);
        Observer.Observe('code_format_' + Format(Number), Show(Called, Ok, Result));
    end;

    [Test]
    procedure Evaluate_TextWithFormatNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatCase(Observer, 0);
        FormatCase(Observer, 1);
        FormatCase(Observer, 9);
        Observer.Expect('text_format_0', 'returned=Yes|result=[a<b>&c]|len=6');
        Observer.Expect('code_format_0', 'returned=Yes|result=[A<B>&C]|len=6');
        Observer.Expect('text_format_1', 'returned=Yes|result=[a<b>&c]|len=6');
        Observer.Expect('code_format_1', 'returned=Yes|result=[A<B>&C]|len=6');
        Observer.Expect('text_format_9', 'returned=Yes|result=[a<b>&c]|len=6');
        Observer.Expect('code_format_9', 'returned=Yes|result=[A<B>&C]|len=6');
        Observer.Verify();
    end;

    local procedure Del(Source: Text; Where: Text; What: Text): Text
    begin
        exit('[' + DelChr(Source, Where, What) + ']');
    end;

    [TryFunction]
    local procedure TryDel(Source: Text; Where: Text; What: Text; var Result: Text)
    begin
        Result := DelChr(Source, Where, What);
    end;

    local procedure DelOutcome(Where: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryDel('<<a<b>>c>>', Where, '<>', Result) then
            exit('ok:[' + Result + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DelChr_WhereLongerThanOne()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('where_1_equals', DelOutcome('='));
        Observer.Observe('where_1_less', DelOutcome('<'));
        Observer.Observe('where_1_greater', DelOutcome('>'));
        Observer.Observe('where_2_less_greater', DelOutcome('<>'));
        Observer.Observe('where_2_equals_less', DelOutcome('=<'));
        Observer.Observe('where_3', DelOutcome('=<>'));
        Observer.Observe('where_4', DelOutcome('=<>='));
        Observer.Observe('where_4_less', DelOutcome('<<<<'));
        Observer.Observe('where_4_mixed', DelOutcome('<>=<'));
        Observer.Observe('where_5', DelOutcome('=<>=<'));
        Observer.Observe('where_empty', DelOutcome(''));
        Observer.Observe('where_letter', DelOutcome('x'));
        Observer.Expect('where_1_equals', 'ok:[abc]');
        Observer.Expect('where_1_less', 'ok:[a<b>>c>>]');
        Observer.Expect('where_1_greater', 'ok:[<<a<b>>c]');
        Observer.Expect('where_2_less_greater', 'ok:[a<b>>c]');
        Observer.Expect('where_2_equals_less', 'ok:[abc]');
        Observer.Expect('where_3', 'ok:[abc]');
        Observer.Expect('where_4', 'ok:[abc]');
        Observer.Expect('where_4_less', 'ok:[a<b>>c>>]');
        Observer.Expect('where_4_mixed', 'ok:[abc]');
        Observer.Expect('where_5', 'ok:[abc]');
        Observer.Expect('where_empty', 'ok:[<<a<b>>c>>]');
        Observer.Expect('where_letter', 'error:Incorrect use of the where parameter.|ALSystemString');
        Observer.Verify();
    end;
}
