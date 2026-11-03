// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 71164
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): a Guid assigned to Text and Code
// Facts: format (braces, case) of a Guid assigned to Text/Code, a target one character too short and exactly long enough, Format with the format numbers, round trip through Evaluate
// BC versions: 29 (27 and 28 by CI)

codeunit 71164 "LT P69 Guid Text Lengths"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryText38(G: Guid; var R: Text)
    var
        T: Text[38];
    begin
        T := G;
        R := T;
    end;

    [TryFunction]
    local procedure TryText40(G: Guid; var R: Text)
    var
        T: Text[40];
    begin
        T := G;
        R := T;
    end;

    [TryFunction]
    local procedure TryCode38(G: Guid; var R: Text)
    var
        C: Code[38];
    begin
        C := G;
        R := C;
    end;

    [TryFunction]
    local procedure TryCode40(G: Guid; var R: Text)
    var
        C: Code[40];
    begin
        C := G;
        R := C;
    end;

    [TryFunction]
    local procedure TryUnbounded(G: Guid; var R: Text)
    var
        T: Text;
    begin
        T := G;
        R := T;
    end;

    local procedure Res(Ok: Boolean; R: Text): Text
    begin
        if Ok then
            exit(Format(StrLen(R)) + '|' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Sample(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        exit(G);
    end;

    [Test]
    procedure GuidToText_TargetLengths()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        R: Text;
        Ok: Boolean;
    begin
        G := Sample();
        Ok := TryText38(G, R);
        Observer.Observe('text38', Res(Ok, R));
        Ok := TryText40(G, R);
        Observer.Observe('text40', Res(Ok, R));
        Ok := TryUnbounded(G, R);
        Observer.Observe('unbounded', Res(Ok, R));
        Ok := TryCode38(G, R);
        Observer.Observe('code38', Res(Ok, R));
        Ok := TryCode40(G, R);
        Observer.Observe('code40', Res(Ok, R));
        Observer.Expect('text38', '38|{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('text40', '38|{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('unbounded', '38|{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('code38', '38|{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('code40', '38|{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Verify();
    end;

    [Test]
    procedure GuidToText_FormatNumbers()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        i: Integer;
    begin
        G := Sample();
        for i := 0 to 4 do
            Observer.Observe('format_' + Format(i), Format(G, 0, i));
        Observer.Observe('format_9', Format(G, 0, 9));
        Observer.Observe('format_default', Format(G));
        Observer.Observe('lower', LowerCase(Format(G)));
        Observer.Observe('strlen_default', Format(StrLen(Format(G))));
        Observer.Observe('strlen_0', Format(StrLen(Format(G, 0, 0))));
        Observer.Observe('strlen_4', Format(StrLen(Format(G, 0, 4))));
        Observer.Expect('format_0', '{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('format_1', '{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('format_2', '{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('format_3', 'AB12CD34EF567890ABCDEF1234567890');
        Observer.Expect('format_4', 'AB12CD34-EF56-7890-ABCD-EF1234567890');
        Observer.Expect('format_9', '{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('format_default', '{AB12CD34-EF56-7890-ABCD-EF1234567890}');
        Observer.Expect('lower', '{ab12cd34-ef56-7890-abcd-ef1234567890}');
        Observer.Expect('strlen_default', '38');
        Observer.Expect('strlen_0', '38');
        Observer.Expect('strlen_4', '36');
        Observer.Verify();
    end;

    [Test]
    procedure GuidToText_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        G2: Guid;
        T: Text;
        C: Code[40];
        Ok: Boolean;
    begin
        G := Sample();
        T := G;
        C := G;
        Ok := Evaluate(G2, T);
        Observer.Observe('text_eval', Format(Ok) + '|' + Format(G2 = G));
        Clear(G2);
        Ok := Evaluate(G2, C);
        Observer.Observe('code_eval', Format(Ok) + '|' + Format(G2 = G));
        Clear(G2);
        Ok := Evaluate(G2, LowerCase(T));
        Observer.Observe('lower_eval', Format(Ok) + '|' + Format(G2 = G));
        Clear(G2);
        Ok := Evaluate(G2, DelChr(T, '=', '{}'));
        Observer.Observe('nobraces_eval', Format(Ok) + '|' + Format(G2 = G));
        Observer.Observe('text_equals_format', Format(T = Format(G)));
        Observer.Observe('code_equals_text', Format(C = T));
        Observer.Observe('code_uppercase', Format(C = UpperCase(C)));
        Observer.Observe('text_uppercase', Format(T = UpperCase(T)));
        Observer.Observe('first_char', CopyStr(T, 1, 1));
        Observer.Observe('last_char', CopyStr(T, StrLen(T), 1));
        Observer.Expect('text_eval', 'Yes|Yes');
        Observer.Expect('code_eval', 'Yes|Yes');
        Observer.Expect('lower_eval', 'Yes|Yes');
        Observer.Expect('nobraces_eval', 'Yes|Yes');
        Observer.Expect('text_equals_format', 'Yes');
        Observer.Expect('code_equals_text', 'Yes');
        Observer.Expect('code_uppercase', 'Yes');
        Observer.Expect('text_uppercase', 'Yes');
        Observer.Expect('first_char', '{');
        Observer.Expect('last_char', '}');
        Observer.Verify();
    end;

    [Test]
    procedure GuidToText_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryText38(G, R);
        Observer.Observe('text38', Res(Ok, R));
        Ok := TryCode40(G, R);
        Observer.Observe('code40', Res(Ok, R));
        Observer.Observe('format', Format(G));
        Observer.Expect('text38', '38|{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('code40', '38|{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('format', '{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;
}
