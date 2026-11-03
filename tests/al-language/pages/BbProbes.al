// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-method-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects of BbObjects.al (80850 to 80855)
// Probe: corpus issue 653 item 2 (which Bump a Report variable calls when the base report has Bump(Integer) and its extension Bump(Text)),
//   item 9 (an enum value passed by value to a parameter of another enum type with AssignmentCompatibility = true), item 10 (a one-character
//   literal is a Char: it compiles into Integer, BigInteger and Decimal; 'xy' is refused, must-not-compile case 1251), and issue 639 items 10 to
//   12 and 18 (the page with a field FileUploadAction, a system part EntityName/EntitySetName and HelpLink opens in a TestPage).
// BC versions: 27, 28, 29
codeunit 80860 "LT BB Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure ReportExt_OverloadByParameterType()
    var
        R: Report "LT BB Base Report";
        T: Text;
        C: Code[10];
    begin
        T := 'abc';
        C := 'CODE';
        Observer.Observe('int', R.Bump(7));
        Observer.Observe('text', R.Bump(T));
        Observer.Observe('code', R.Bump(C));
        Observer.Observe('char literal', R.Bump('x'));
        Observer.Expect('int', 'base integer 7');
        Observer.Expect('text', 'extension text abc');
        Observer.Expect('code', 'extension text CODE');
        Observer.Expect('char literal', 'extension text x');
        Observer.Verify();
    end;

    // A Char variable binds to the base Bump(Integer) at compile time, but the call fails at run time.
    // Linux suspect, not asserted (not a [Test]): on the Linux BC container (27.5, 28.5, 29.0) the call raised
    // 'Unable to convert from System.Char to System.Int32.' with code Conversion, a CLR conversion text. Verify on the Windows nightly
    // before pinning it as BC behavior.
    procedure ReportExt_OverloadCharVariable()
    var
        R: Report "LT BB Base Report";
        Ch: Char;
    begin
        Ch := 'q';
        asserterror R.Bump(Ch);
        Observer.ObserveError('char var');
        Observer.Finish();
    end;

    [Test]
    procedure CharLiteral_ToNumbers()
    var
        I: Integer;
        BI: BigInteger;
        D: Decimal;
    begin
        I := 'x';
        BI := 'x';
        D := 'x';
        Observer.Observe('integer', Format(I));
        Observer.Observe('biginteger', Format(BI));
        Observer.Observe('decimal', Format(D));
        Observer.Expect('integer', '120');
        Observer.Expect('biginteger', '120');
        Observer.Expect('decimal', '120');
        Observer.Verify();
    end;

    local procedure Take(B: Enum "LT BB Enum B"): Text
    begin
        exit(Format(B.AsInteger()) + '|' + Format(B));
    end;

    [TryFunction]
    local procedure TryTake(A: Enum "LT BB Enum A"; var Shown: Text)
    begin
        Shown := Take(A);
    end;

    [Test]
    procedure Enum_ByValueToCompatibleEnum()
    var
        A: Enum "LT BB Enum A";
        Shown: Text;
    begin
        A := A::One;
        Observer.Observe('one', Take(A));
        A := A::Five;
        ClearLastError();
        if TryTake(A, Shown) then
            Observer.Observe('five', Shown)
        else
            Observer.ObserveError('five');
        // An ordinal that B lacks is passed on unchanged: AsInteger 5, Format shows the ordinal.
        Observer.Expect('one', '1|One');
        Observer.Expect('five', '5|5');
        Observer.Verify();
    end;

    [Test]
    procedure Page_FieldFileUploadAction_SystemPartEntityName_HelpLink()
    var
        Row: Record "LT BB Row";
        TP: TestPage "LT BB Controls";
    begin
        Row.DeleteAll();
        Row.Id := 3;
        Row.Txt := 'three';
        Row.Insert();
        TP.OpenView();
        TP.First();
        Observer.Observe('id', TP.Id.Value());
        Observer.Observe('txt', TP.Txt.Value());
        Observer.Observe('id visible', Format(TP.Id.Visible()));
        TP.Close();
        Observer.Expect('id', '3');
        Observer.Expect('txt', 'three');
        Observer.Expect('id visible', 'Yes');
        Observer.Verify();
    end;
}
