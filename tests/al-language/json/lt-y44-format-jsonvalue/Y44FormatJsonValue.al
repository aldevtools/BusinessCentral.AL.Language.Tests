// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 92860
// Probe: gap cycle 4, spec G4-16. Format of a JsonValue that holds a value, for each kind of value (SetValue overloads), next to WriteTo,
//        standard formats 0, 1, 2 and 9, the Format text read back through JsonToken.ReadFrom, and values read from JSON text.
//        Already pinned nearby: json/JsonValueSetters.al ValueAsToken (text, decimal 12.50, boolean at format 0).
// BC versions: 27, 28, 29

codeunit 92860 "LT Y44 Format JsonValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryFmt(V: JsonValue; Std: Integer; var Result: Text)
    begin
        Result := Format(V, 0, Std);
    end;

    local procedure Fmt(Name: Text; V: JsonValue; Std: Integer)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryFmt(V, Std, Result) then
            Observer.Observe('fmt_' + Name + '_' + Format(Std), Result)
        else
            Observer.ObserveError('fmt_' + Name + '_' + Format(Std));
    end;

    local procedure WT(Name: Text; V: JsonValue)
    var
        Txt: Text;
    begin
        V.WriteTo(Txt);
        Observer.Observe('wt_' + Name, Txt);
    end;

    local procedure Both(Name: Text; V: JsonValue)
    begin
        Fmt(Name, V, 0);
        WT(Name, V);
    end;

    local procedure Quoted(): Text
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        exit('He said "hi"\' + Tab + 'x');
    end;

    [Test]
    procedure FormatJsonValue_Numbers()
    var
        V: JsonValue;
        I: Integer;
        Bi: BigInteger;
        D: Decimal;
        By: Byte;
        Du: Duration;
        Op: Option A,B,C,D;
    begin
        I := 42;
        V.SetValue(I);
        Both('int42', V);
        I := -1313548468;
        V.SetValue(I);
        Both('intneg', V);
        Bi := 9007199254740993L;
        V.SetValue(Bi);
        Both('bigint', V);
        Bi := -5;
        V.SetValue(Bi);
        Both('bigneg', V);
        D := 12.5;
        V.SetValue(D);
        Both('dec12_5', V);
        D := -0.001;
        V.SetValue(D);
        Both('decneg', V);
        D := 1234567.89;
        V.SetValue(D);
        Both('decbig', V);
        By := 7;
        V.SetValue(By);
        Both('byte', V);
        Du := 1234567;
        V.SetValue(Du);
        Both('duration', V);
        Op := Op::D;
        V.SetValue(Op);
        Both('option', V);
        Observer.Finish();
    end;

    [Test]
    procedure FormatJsonValue_TextLike()
    var
        V: JsonValue;
        T: Text;
        C: Code[10];
        Ch: Char;
    begin
        T := Quoted();
        V.SetValue(T);
        Both('text', V);
        C := 'AB1';
        V.SetValue(C);
        Both('code', V);
        Ch := 'A';
        V.SetValue(Ch);
        Both('charA', V);
        Ch := 34;
        V.SetValue(Ch);
        Both('charquote', V);
        T := '';
        V.SetValue(T);
        Both('textempty', V);
        V.SetValue(false);
        Both('false', V);
        Observer.Finish();
    end;

    [Test]
    procedure FormatJsonValue_DateTime()
    var
        V: JsonValue;
        Dt: Date;
        Tm: Time;
        DT2: DateTime;
    begin
        Dt := 20240315D;
        V.SetValue(Dt);
        Both('date', V);
        Dt := 0D;
        V.SetValue(Dt);
        Both('date0', V);
        Tm := 143015.123T;
        V.SetValue(Tm);
        Both('time', V);
        Tm := 0T;
        V.SetValue(Tm);
        Both('time0', V);
        DT2 := CreateDateTime(20240315D, 143015.123T);
        V.SetValue(DT2);
        Both('datetime', V);
        DT2 := 0DT;
        V.SetValue(DT2);
        Both('datetime0', V);
        Observer.Finish();
    end;

    local procedure AllStd(Name: Text; V: JsonValue)
    begin
        Fmt(Name, V, 1);
        Fmt(Name, V, 2);
        Fmt(Name, V, 9);
    end;

    [Test]
    procedure FormatJsonValue_StandardFormats_Scalars()
    var
        V: JsonValue;
        I: Integer;
        D: Decimal;
        T: Text;
    begin
        I := 42;
        V.SetValue(I);
        AllStd('int', V);
        D := 1234567.89;
        V.SetValue(D);
        AllStd('dec', V);
        V.SetValue(true);
        AllStd('bool', V);
        T := 'x';
        V.SetValue(T);
        AllStd('text', V);
        Observer.Finish();
    end;

    [Test]
    procedure FormatJsonValue_StandardFormats_DatesAndNull()
    var
        V: JsonValue;
        Dt: Date;
        DT2: DateTime;
    begin
        Dt := 20240315D;
        V.SetValue(Dt);
        AllStd('date', V);
        DT2 := CreateDateTime(20240315D, 143015.123T);
        V.SetValue(DT2);
        AllStd('datetime', V);
        V.SetValueToNull();
        AllStd('null', V);
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryReadFrom(Src: Text; var Tok: JsonToken; var Answer: Boolean)
    begin
        Answer := Tok.ReadFrom(Src);
    end;

    local procedure ReadBack(Name: Text; V: JsonValue)
    var
        Tok: JsonToken;
        A: JsonToken;
        Answer: Boolean;
        Txt: Text;
    begin
        ClearLastError();
        if not TryReadFrom('{"a":' + Format(V) + '}', Tok, Answer) then begin
            Observer.ObserveError('readfrom_' + Name);
            exit;
        end;
        Observer.Observe('readfrom_' + Name, Format(Answer));
        if not Answer then
            exit;
        if Tok.SelectToken('a', A) then begin
            A.WriteTo(Txt);
            Observer.Observe('back_' + Name, Txt);
        end else
            Observer.Observe('back_' + Name, '<no a>');
    end;

    [Test]
    procedure FormatJsonValue_ReadBack()
    var
        V: JsonValue;
        I: Integer;
        T: Text;
        Dt: Date;
        Tm: Time;
        DT2: DateTime;
        Du: Duration;
    begin
        I := -1313548468;
        V.SetValue(I);
        ReadBack('int', V);
        T := Quoted();
        V.SetValue(T);
        ReadBack('text', V);
        Dt := 20240315D;
        V.SetValue(Dt);
        ReadBack('date', V);
        DT2 := CreateDateTime(20240315D, 143015.123T);
        V.SetValue(DT2);
        ReadBack('datetime', V);
        Tm := 143015.123T;
        V.SetValue(Tm);
        ReadBack('time', V);
        Du := 1234567;
        V.SetValue(Du);
        ReadBack('duration', V);
        Observer.Finish();
    end;

    [Test]
    procedure FormatJsonValue_FromReadFrom()
    var
        Tok: JsonToken;
        M: JsonToken;
        Name: Text;
        Names: List of [Text];
    begin
        Tok.ReadFrom('{"n":42,"d":12.50,"e":1.0E2,"s":"x","b":false,"z":null}');
        Names.AddRange('n', 'd', 'e', 's', 'b', 'z');
        foreach Name in Names do begin
            Tok.SelectToken(Name, M);
            Both('read_' + Name, M.AsValue());
        end;
        Observer.Finish();
    end;
}
