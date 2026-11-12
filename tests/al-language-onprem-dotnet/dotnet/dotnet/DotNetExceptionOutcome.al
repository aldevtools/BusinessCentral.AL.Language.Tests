// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability-overview
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 99017 to 99019
// Probe: from al-runner issue 7924 (a .NET exception raised inside AL code: what the AL code and the test see).
// Area: four exceptions, each raised by a DotNet call in AL code:
//   - uri:     System.Uri.IsBaseOf with an unassigned Uri variable (ArgumentNullException), the issue's shape;
//   - convert: System.Convert.ToInt32('abc') (FormatException);
//   - getter:  the property getter AbsolutePath of a relative System.Uri (InvalidOperationException);
//   - ctor:    the constructor System.Text.StringBuilder(-1) (ArgumentOutOfRangeException).
//   Cells: (a) the plain call inside Codeunit.Run (the error a test that makes the plain call ends with), Boolean, text and code;
//   (b) asserterror around the call, the text never read (the test goes on); (c) a [TryFunction] in the test codeunit around the
//   call, only the Boolean read; (d) asserterror, then GetLastErrorText, GetLastErrorCode, the innermost frame of
//   GetLastErrorCallStack and the GetLastErrorObject exception (type, message, inner exception); (e) a [TryFunction] of another
//   codeunit that keeps the DotNet variables as globals, called in an if.
// Already pinned elsewhere, not repeated: new System.Uri('12345') and XmlDocument.LoadXml('') in a TryFunction and in Codeunit.Run
//   (WdTryFunctionDotNetException.al); GetLastErrorObject of AL errors (dotnet-interop/GetLastErrorObject.al, AzLastErrorObject.al).
// Not measurable: ErrorInfo of a .NET exception (AL has no reader of the last error as an ErrorInfo; GetLastErrorObject is the object).
//   The literal outcome of a test that makes the plain call (it fails; a corpus test cannot fail): cell (a) shows the error instead.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)
dotnet
{
    assembly("System")
    {
        type("System.Uri"; DnExcUri) { }
        type("System.UriKind"; DnExcUriKind) { }
    }
    assembly("mscorlib")
    {
        type("System.Convert"; DnExcConvert) { }
        type("System.Text.StringBuilder"; DnExcBuilder) { }
        type("System.Exception"; DnExcException) { }
        type("System.Type"; DnExcType) { }
    }
}

// Raises one of the four exceptions with plain calls; the DotNet variables are globals (cell e).
codeunit 99017 "DnExc Raiser"
{
    var
        Base: DotNet DnExcUri;
        Other: DotNet DnExcUri;
        Relative: DotNet DnExcUri;
        Kind: DotNet DnExcUriKind;
        Convert: DotNet DnExcConvert;
        Builder: DotNet DnExcBuilder;

    procedure Raise(Which: Text)
    var
        Number: Integer;
        Input: Text;
        Path: Text;
    begin
        case Which of
            'uri':
                begin
                    Base := Base.Uri('https://example.com/a/');
                    if Base.IsBaseOf(Other) then;
                end;
            'convert':
                begin
                    Input := 'abc';
                    Number := Convert.ToInt32(Input);
                end;
            'getter':
                begin
                    Relative := Relative.Uri('a/b', Kind.Relative);
                    Path := Relative.AbsolutePath;
                end;
            'ctor':
                Builder := Builder.StringBuilder(-1);
        end;
    end;

    [TryFunction]
    procedure TryRaise(Which: Text)
    begin
        Raise(Which);
    end;

    [TryFunction]
    procedure TryUriIsBaseOf()
    begin
        Base := Base.Uri('https://example.com/a/');
        if Base.IsBaseOf(Other) then;
    end;
}

// Codeunit.Run of the plain call (cell a).
codeunit 99018 "DnExc Runner"
{
    var
        Which: Text;

    procedure SetWhich(NewWhich: Text)
    begin
        Which := NewWhich;
    end;

    trigger OnRun()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        Raiser.Raise(Which);
    end;
}

codeunit 99019 "DnExc Outcome"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RunPlain(Which: Text)
    var
        Runner: Codeunit "DnExc Runner";
    begin
        ClearLastError();
        Runner.SetWhich(Which);
        Observer.Observe(Which + '_run', Format(Runner.Run()));
        Observer.ObserveError(Which);
    end;

    // the innermost frame of the error's call stack (the routine that raised)
    local procedure TopFrame(): Text
    var
        Stack: Text;
    begin
        Stack := GetLastErrorCallStack();
        if Stack.IndexOf('\') > 0 then
            exit(Stack.Substring(1, Stack.IndexOf('\') - 1));
        exit(Stack);
    end;

    local procedure FirstLine(Value: Text): Text
    var
        Lf: Text[1];
    begin
        Lf[1] := 10;
        exit(CopyStr(Value, 1, StrPos(Value + Lf, Lf) - 1));
    end;

    // Every last-error reader, right after the error (GetLastErrorObject first read directly, never in a try function).
    local procedure DescribeLastError()
    var
        Exc: DotNet DnExcException;
        Inner: DotNet DnExcException;
        TypeOfExc: DotNet DnExcType;
        LastText: Text;
        LastCode: Text;
        Frame: Text;
    begin
        LastText := GetLastErrorText();
        LastCode := GetLastErrorCode();
        Frame := TopFrame();
        Exc := GetLastErrorObject();
        Observer.Observe('text', LastText);
        Observer.Observe('code', LastCode);
        Observer.Observe('top_frame', Frame);
        Observer.Observe('object_null', Format(IsNull(Exc)));
        if IsNull(Exc) then
            exit;
        TypeOfExc := Exc.GetType();
        Observer.Observe('object_type', TypeOfExc.FullName);
        Observer.Observe('object_message_is_text', Format(Exc.Message = LastText));
        if Exc.Message <> LastText then
            Observer.Observe('object_message', FirstLine(Exc.Message));
        Inner := Exc.InnerException;
        Observer.Observe('inner_null', Format(IsNull(Inner)));
        if IsNull(Inner) then
            exit;
        TypeOfExc := Inner.GetType();
        Observer.Observe('inner_type', TypeOfExc.FullName);
        Observer.Observe('inner_message', FirstLine(Inner.Message));
    end;

    [TryFunction]
    local procedure TryUriInline()
    var
        Base: DotNet DnExcUri;
        Other: DotNet DnExcUri;
    begin
        Base := Base.Uri('https://example.com/a/');
        if Base.IsBaseOf(Other) then;
    end;

    [TryFunction]
    local procedure TryConvertInline()
    var
        Convert: DotNet DnExcConvert;
        Input: Text;
        Number: Integer;
    begin
        Input := 'abc';
        Number := Convert.ToInt32(Input);
    end;

    [TryFunction]
    local procedure TryGetterInline()
    var
        Relative: DotNet DnExcUri;
        Kind: DotNet DnExcUriKind;
        Path: Text;
    begin
        Relative := Relative.Uri('a/b', Kind.Relative);
        Path := Relative.AbsolutePath;
    end;

    [TryFunction]
    local procedure TryCtorInline()
    var
        Builder: DotNet DnExcBuilder;
    begin
        Builder := Builder.StringBuilder(-1);
    end;

    // (a) the plain call inside Codeunit.Run
    [Test]
    procedure DnExc_PlainCall_CodeunitRun_UriConvert()
    begin
        RunPlain('uri');
        RunPlain('convert');
        Observer.Finish();
    end;

    [Test]
    procedure DnExc_PlainCall_CodeunitRun_GetterCtor()
    begin
        RunPlain('getter');
        RunPlain('ctor');
        Observer.Finish();
    end;

    // (b) asserterror around the call, the text never read: the test goes on
    [Test]
    procedure DnExc_AssertError_TextNotRead()
    var
        Base: DotNet DnExcUri;
        Other: DotNet DnExcUri;
        Raiser: Codeunit "DnExc Raiser";
    begin
        Base := Base.Uri('https://example.com/a/');
        asserterror if Base.IsBaseOf(Other) then;
        Observer.Observe('uri_inline', 'reached');
        asserterror Raiser.Raise('uri');
        Observer.Observe('uri', 'reached');
        asserterror Raiser.Raise('convert');
        Observer.Observe('convert', 'reached');
        asserterror Raiser.Raise('getter');
        Observer.Observe('getter', 'reached');
        asserterror Raiser.Raise('ctor');
        Observer.Observe('ctor', 'reached');
        Observer.Finish();
    end;

    // (c) a [TryFunction] around the call, only the Boolean read
    [Test]
    procedure DnExc_TryFunction_BooleanOnly()
    begin
        Observer.Observe('uri', Format(TryUriInline()));
        Observer.Observe('convert', Format(TryConvertInline()));
        Observer.Observe('getter', Format(TryGetterInline()));
        Observer.Observe('ctor', Format(TryCtorInline()));
        if TryUriInline() then
            Observer.Observe('uri_if', 'then')
        else
            Observer.Observe('uri_if', 'else');
        Observer.Finish();
    end;

    // (d) asserterror, then every reader of the last error, once per exception
    [Test]
    procedure DnExc_AssertError_LastError_Uri()
    var
        Base: DotNet DnExcUri;
        Other: DotNet DnExcUri;
    begin
        ClearLastError();
        Base := Base.Uri('https://example.com/a/');
        asserterror if Base.IsBaseOf(Other) then;
        DescribeLastError();
        Observer.Finish();
    end;

    [Test]
    procedure DnExc_AssertError_LastError_Convert()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        ClearLastError();
        asserterror Raiser.Raise('convert');
        DescribeLastError();
        Observer.Finish();
    end;

    [Test]
    procedure DnExc_AssertError_LastError_Getter()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        ClearLastError();
        asserterror Raiser.Raise('getter');
        DescribeLastError();
        Observer.Finish();
    end;

    [Test]
    procedure DnExc_AssertError_LastError_Ctor()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        ClearLastError();
        asserterror Raiser.Raise('ctor');
        DescribeLastError();
        Observer.Finish();
    end;

    // (e) a [TryFunction] of another codeunit with global DotNet variables, called in an if
    [Test]
    procedure DnExc_OtherCodeunit_TryFunction_InIf()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        ClearLastError();
        if Raiser.TryUriIsBaseOf() then
            Observer.Observe('uri', 'then')
        else
            Observer.Observe('uri', 'else');
        Observer.Observe('uri|code', GetLastErrorCode());
        ClearLastError();
        if Raiser.TryRaise('convert') then
            Observer.Observe('convert', 'then')
        else
            Observer.Observe('convert', 'else');
        Observer.Observe('convert|code', GetLastErrorCode());
        ClearLastError();
        if not Raiser.TryRaise('getter') then
            Observer.Observe('getter', 'not')
        else
            Observer.Observe('getter', 'then');
        Observer.Observe('getter|code', GetLastErrorCode());
        ClearLastError();
        if Raiser.TryRaise('ctor') then
            Observer.Observe('ctor', 'then')
        else
            Observer.Observe('ctor', 'else');
        Observer.Observe('ctor|code', GetLastErrorCode());
        Observer.Finish();
    end;
}
