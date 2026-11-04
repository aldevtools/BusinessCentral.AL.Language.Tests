// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P145 Key (74900)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format(Boolean) into Code and Text variables and keys, with Get on the resulting texts (the compiling forms)
// BC versions: 29 (final facts are added after the measurement)

codeunit 74904 "LT P145 Bool Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryToCode2(B: Boolean; var Result: Text)
    var
        C: Code[2];
    begin
        C := Format(B);
        Result := C;
    end;

    [TryFunction]
    local procedure TryToCode3(B: Boolean; var Result: Text)
    var
        C: Code[3];
    begin
        C := Format(B);
        Result := C;
    end;

    [Test]
    procedure P145_FormatBoolean_IntoCodeAndText()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[20];
        T: Text;
        B: Boolean;
    begin
        B := true;
        C := Format(B);
        Observer.Observe('code-true', C);
        Observer.Observe('code-true-len', Format(StrLen(C)));
        B := false;
        C := Format(B);
        Observer.Observe('code-false', C);
        T := Format(true);
        Observer.Observe('text-true', T);
        Observer.Observe('format-true-0', Format(true, 0));
        Observer.Observe('format-true-1', Format(true, 0, 1));
        Observer.Observe('format-true-2', Format(true, 0, 2));
        Observer.Observe('format-true-9', Format(true, 0, 9));
        Observer.Observe('format-false-1', Format(false, 0, 1));
        Observer.Observe('format-false-9', Format(false, 0, 9));
        Observer.Observe('code-true-upper', Format(UpperCase(Format(true))));
        Observer.Observe('code-true-eq-text', Format(C = Format(false)));
        Observer.Expect('code-true', 'YES');
        Observer.Expect('code-true-len', '3');
        Observer.Expect('code-false', 'NO');
        Observer.Expect('text-true', 'Yes');
        Observer.Expect('format-true-0', 'Yes');
        Observer.Expect('format-true-1', 'Yes');
        Observer.Expect('format-true-2', '1');
        Observer.Expect('format-true-9', 'true');
        Observer.Expect('format-false-1', 'No');
        Observer.Expect('format-false-9', 'false');
        Observer.Expect('code-true-upper', 'YES');
        Observer.Expect('code-true-eq-text', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P145_FormatBoolean_IntoShortCode()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if TryToCode2(true, R) then
            Observer.Observe('code2-true', R)
        else
            Observer.Observe('code2-true-error', GetLastErrorText());
        if TryToCode2(false, R) then
            Observer.Observe('code2-false', R)
        else
            Observer.Observe('code2-false-error', GetLastErrorText());
        if TryToCode3(true, R) then
            Observer.Observe('code3-true', R)
        else
            Observer.Observe('code3-true-error', GetLastErrorText());
        if TryToCode3(false, R) then
            Observer.Observe('code3-false', R)
        else
            Observer.Observe('code3-false-error', GetLastErrorText());
        Observer.Expect('code2-true-error', 'The length of the string is 3, but it must be less than or equal to 2 characters. Value: Yes');
        Observer.Expect('code2-false', 'NO');
        Observer.Expect('code3-true', 'YES');
        Observer.Expect('code3-false', 'NO');
        Observer.Verify();
    end;

    [Test]
    procedure P145_FormatBoolean_AsRecordKey()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P145 Key";
        B: Boolean;
    begin
        Rec.DeleteAll();
        B := true;
        Rec.Init();
        Rec."Code" := Format(B);
        Rec.Insert();
        Rec.Init();
        Rec."Code" := Format(not B);
        Rec.Insert();
        Rec.Init();
        Rec."Code" := '1';
        Rec.Insert();
        Rec.Init();
        Rec."Code" := '0';
        Rec.Insert();
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Observe('get-format-true', Format(Rec.Get(Format(true))) + ':' + Rec."Code");
        Observer.Observe('get-format-false', Format(Rec.Get(Format(false))) + ':' + Rec."Code");
        Observer.Observe('get-format-b', Format(Rec.Get(Format(B))));
        Observer.Observe('get-Yes', Format(Rec.Get('Yes')));
        Observer.Observe('get-YES', Format(Rec.Get('YES')));
        Observer.Observe('get-TRUE', Format(Rec.Get('TRUE')));
        Observer.Observe('get-1', Format(Rec.Get('1')));
        Observer.Observe('get-0', Format(Rec.Get('0')));
        Observer.Observe('format-true-9-key', Format(Rec.Get(Format(true, 0, 9))));
        Observer.Expect('count', '4');
        Observer.Expect('get-format-true', 'Yes:YES');
        Observer.Expect('get-format-false', 'Yes:NO');
        Observer.Expect('get-format-b', 'Yes');
        Observer.Expect('get-Yes', 'Yes');
        Observer.Expect('get-YES', 'Yes');
        Observer.Expect('get-TRUE', 'No');
        Observer.Expect('get-1', 'Yes');
        Observer.Expect('get-0', 'Yes');
        Observer.Expect('format-true-9-key', 'No');
        Observer.Verify();
    end;
}
