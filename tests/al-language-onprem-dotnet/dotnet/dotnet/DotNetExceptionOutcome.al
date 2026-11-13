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
// Facts (measured by the corpus CI on 27.5, 28.5 and 29.0, the same on all three):
//   - Every exception becomes an AL error: Codeunit.Run returns No, asserterror catches it and the test goes on, a TryFunction returns
//     No (also in an if, and from another codeunit with global DotNet variables).
//   - Text: 'A call to <Type>.<Member> failed with this message: <exception message>' (Member is the method or property; a constructor
//     shows the type only). Code: 'DotNetInvoke:<exception class name without Exception>' (ArgumentNull, Format, InvalidOperation,
//     ArgumentOutOfRange). The ArgumentOutOfRange text keeps the second line of .NET's message ('\nActual value was -1.').
//   - The innermost frame of GetLastErrorCallStack is the AL statement that made the call.
//   - GetLastErrorObject: a Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException whose Message is the last error text and
//     whose InnerException is the .NET exception (its own message, first line).
// BC versions: 27.5, 28.5, 29.0
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
        Observer.Expect('uri_run', 'No');
        Observer.Expect('uri|text', 'A call to System.Uri.IsBaseOf failed with this message: Value cannot be null. (Parameter ''uri'')');
        Observer.Expect('uri|code', 'DotNetInvoke:ArgumentNull');
        Observer.Expect('convert_run', 'No');
        Observer.Expect('convert|text', 'A call to System.Convert.ToInt32 failed with this message: The input string ''abc'' was not in a correct format.');
        Observer.Expect('convert|code', 'DotNetInvoke:Format');
        Observer.Verify();
    end;

    [Test]
    procedure DnExc_PlainCall_CodeunitRun_GetterCtor()
    begin
        RunPlain('getter');
        RunPlain('ctor');
        Observer.Expect('getter_run', 'No');
        Observer.Expect('getter|text', 'A call to System.Uri.AbsolutePath failed with this message: This operation is not supported for a relative URI.');
        Observer.Expect('getter|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('ctor_run', 'No');
        Observer.Expect('ctor|text', 'A call to System.Text.StringBuilder failed with this message: capacity (''-1'') must be a non-negative value. (Parameter ''capacity'')\nActual value was -1.');
        Observer.Expect('ctor|code', 'DotNetInvoke:ArgumentOutOfRange');
        Observer.Verify();
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
        Observer.Expect('uri_inline', 'reached');
        Observer.Expect('uri', 'reached');
        Observer.Expect('convert', 'reached');
        Observer.Expect('getter', 'reached');
        Observer.Expect('ctor', 'reached');
        Observer.Verify();
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
        Observer.Expect('uri', 'No');
        Observer.Expect('convert', 'No');
        Observer.Expect('getter', 'No');
        Observer.Expect('ctor', 'No');
        Observer.Expect('uri_if', 'else');
        Observer.Verify();
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
        Observer.Expect('text', 'A call to System.Uri.IsBaseOf failed with this message: Value cannot be null. (Parameter ''uri'')');
        Observer.Expect('code', 'DotNetInvoke:ArgumentNull');
        Observer.Expect('top_frame', '"DnExc Outcome"(CodeUnit 99019).DnExc_AssertError_LastError_Uri line 7 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('object_null', 'No');
        Observer.Expect('object_type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('object_message_is_text', 'Yes');
        Observer.Expect('inner_null', 'No');
        Observer.Expect('inner_type', 'System.ArgumentNullException');
        Observer.Expect('inner_message', 'Value cannot be null. (Parameter ''uri'')');
        Observer.Verify();
    end;

    [Test]
    procedure DnExc_AssertError_LastError_Convert()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        ClearLastError();
        asserterror Raiser.Raise('convert');
        DescribeLastError();
        Observer.Expect('text', 'A call to System.Convert.ToInt32 failed with this message: The input string ''abc'' was not in a correct format.');
        Observer.Expect('code', 'DotNetInvoke:Format');
        Observer.Expect('top_frame', '"DnExc Raiser"(CodeUnit 99017).Raise line 15 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('object_null', 'No');
        Observer.Expect('object_type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('object_message_is_text', 'Yes');
        Observer.Expect('inner_null', 'No');
        Observer.Expect('inner_type', 'System.FormatException');
        Observer.Expect('inner_message', 'The input string ''abc'' was not in a correct format.');
        Observer.Verify();
    end;

    [Test]
    procedure DnExc_AssertError_LastError_Getter()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        ClearLastError();
        asserterror Raiser.Raise('getter');
        DescribeLastError();
        Observer.Expect('text', 'A call to System.Uri.AbsolutePath failed with this message: This operation is not supported for a relative URI.');
        Observer.Expect('code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('top_frame', '"DnExc Raiser"(CodeUnit 99017).Raise line 20 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('object_null', 'No');
        Observer.Expect('object_type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('object_message_is_text', 'Yes');
        Observer.Expect('inner_null', 'No');
        Observer.Expect('inner_type', 'System.InvalidOperationException');
        Observer.Expect('inner_message', 'This operation is not supported for a relative URI.');
        Observer.Verify();
    end;

    [Test]
    procedure DnExc_AssertError_LastError_Ctor()
    var
        Raiser: Codeunit "DnExc Raiser";
    begin
        ClearLastError();
        asserterror Raiser.Raise('ctor');
        DescribeLastError();
        Observer.Expect('text', 'A call to System.Text.StringBuilder failed with this message: capacity (''-1'') must be a non-negative value. (Parameter ''capacity'')\nActual value was -1.');
        Observer.Expect('code', 'DotNetInvoke:ArgumentOutOfRange');
        Observer.Expect('top_frame', '"DnExc Raiser"(CodeUnit 99017).Raise line 23 - AL Language Coverage Tests (OnPrem DotNet) by AL Language version 1.0.0.0');
        Observer.Expect('object_null', 'No');
        Observer.Expect('object_type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('object_message_is_text', 'Yes');
        Observer.Expect('inner_null', 'No');
        Observer.Expect('inner_type', 'System.ArgumentOutOfRangeException');
        Observer.Expect('inner_message', 'capacity (''-1'') must be a non-negative value. (Parameter ''capacity'')');
        Observer.Verify();
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
        Observer.Expect('uri', 'else');
        Observer.Expect('uri|code', 'DotNetInvoke:ArgumentNull');
        Observer.Expect('convert', 'else');
        Observer.Expect('convert|code', 'DotNetInvoke:Format');
        Observer.Expect('getter', 'not');
        Observer.Expect('getter|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('ctor', 'else');
        Observer.Expect('ctor|code', 'DotNetInvoke:ArgumentOutOfRange');
        Observer.Verify();
    end;
}
