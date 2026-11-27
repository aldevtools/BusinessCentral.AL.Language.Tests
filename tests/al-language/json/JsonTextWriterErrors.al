// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Base Application codeunit 1234 "Json Text Reader/Writer"; own helper codeunit 73474, test codeunit 73475
// Probe (AL Runner issue 8219, item 1): the AL error that a Newtonsoft.Json JsonWriterException becomes when it is raised inside
//   "Json Text Reader/Writer" (which wraps a .NET JsonTextWriter), and what GetLastErrorCode gives for it. Each scenario is a call
//   sequence on a new "Json Text Reader/Writer" that leaves the JSON writer in a state where the last call is invalid:
//   EndObjectTwice      WriteStartObject(''), WriteEndObject(), WriteEndObject()        (the issue's first repro)
//   StartObjectInObject WriteStartObject(''), WriteStartObject('')                      (the issue's second repro)
//   PropertyTwice       WriteStartObject(''), WriteProperty('a'), WriteProperty('b')    (WritePropertyName after a property name)
//   PropertyInArray     WriteStartArray(''), WriteProperty('a')                         (WritePropertyName inside an array)
//   EndArrayInObject    WriteStartObject(''), WriteEndArray()                           (WriteEndArray while an object is open)
//   EndArrayTwice       WriteStartArray(''), WriteEndArray(), WriteEndArray()
//   EndObjectInArray    WriteStartArray(''), WriteEndObject()
//   StartArrayInObject  WriteStartObject(''), WriteStartArray('')
//   PropertyAfterEnd    WriteStartObject(''), WriteEndObject(), WriteStringProperty('a', 'x')
//   EndObjectFirst      WriteEndObject() on a new writer (the .NET writer is not created yet: a null DotNet variable)
//   Control             SetDoNotFormat(), WriteStartObject(''), WriteStringProperty('a', 'x'), WriteEndObject(); no error, and the JSON text.
//   Forms: TryFunction (try_<scenario>: "ok" or "E: <GetLastErrorText> | <GetLastErrorCode>"), and for the two repros of the issue also
//   the statement under asserterror (assert_<scenario>, ObserveError: text and code).
//   Measured on BC 29.0 (Linux, W1, en-US session) with an invented app holding these objects; the values are that run's readings,
//   turned into Expect and Verify by convert.py verbatim. This pull request's CI checks them on 27.5, 28.5 and 29.0.
//   Facts (BC 29.0): a JsonWriterException becomes the AL error 'A call to Newtonsoft.Json.JsonTextWriter.<Method> failed with this
//   message: <the exception's message>' with GetLastErrorCode 'DotNetInvoke:JsonWriter', the same under asserterror and in a
//   TryFunction. The messages: 'No token to close. Path ''.' (WriteEndObject or WriteEndArray with nothing open, WriteEndArray
//   while an object is open, WriteEndObject while an array is open); 'Token <Token> in state <State> would result in an invalid JSON
//   object. Path ''.' (StartObject or StartArray in state ObjectStart, PropertyName in state Property or ArrayStart).
//   PropertyAfterEnd raises nothing. A call before the writer exists: 'A DotNet variable has not been instantiated. Attempting to
//   call Newtonsoft.Json.JsonTextWriter.WriteEndObject in CodeUnit Json Text Reader/Writer: WriteEndObject'
//   (DotNetVariableNotCreated). The control writes {"a":"x"}.
// BC versions: 27, 28, 29 by CI
codeunit 73474 "LT JTW Probe"
{
    // One scenario on the given writer.
    procedure Run(var Writer: Codeunit "Json Text Reader/Writer"; Scenario: Text)
    begin
        case Scenario of
            'EndObjectTwice':
                begin
                    Writer.WriteStartObject('');
                    Writer.WriteEndObject();
                    Writer.WriteEndObject();
                end;
            'StartObjectInObject':
                begin
                    Writer.WriteStartObject('');
                    Writer.WriteStartObject('');
                end;
            'PropertyTwice':
                begin
                    Writer.WriteStartObject('');
                    Writer.WriteProperty('a');
                    Writer.WriteProperty('b');
                end;
            'PropertyInArray':
                begin
                    Writer.WriteStartArray('');
                    Writer.WriteProperty('a');
                end;
            'EndArrayInObject':
                begin
                    Writer.WriteStartObject('');
                    Writer.WriteEndArray();
                end;
            'EndArrayTwice':
                begin
                    Writer.WriteStartArray('');
                    Writer.WriteEndArray();
                    Writer.WriteEndArray();
                end;
            'EndObjectInArray':
                begin
                    Writer.WriteStartArray('');
                    Writer.WriteEndObject();
                end;
            'StartArrayInObject':
                begin
                    Writer.WriteStartObject('');
                    Writer.WriteStartArray('');
                end;
            'PropertyAfterEnd':
                begin
                    Writer.WriteStartObject('');
                    Writer.WriteEndObject();
                    Writer.WriteStringProperty('a', 'x');
                end;
            'EndObjectFirst':
                Writer.WriteEndObject();
            'Control':
                begin
                    Writer.SetDoNotFormat();
                    Writer.WriteStartObject('');
                    Writer.WriteStringProperty('a', 'x');
                    Writer.WriteEndObject();
                end;
        end;
    end;

    [TryFunction]
    local procedure TryRun(var Writer: Codeunit "Json Text Reader/Writer"; Scenario: Text)
    begin
        Run(Writer, Scenario);
    end;

    // try_<Scenario>: the scenario on a new writer inside a TryFunction.
    procedure ObserveTry(var Observer: Codeunit "Probe Observer"; Scenario: Text)
    var
        Writer: Codeunit "Json Text Reader/Writer";
    begin
        ClearLastError();
        if TryRun(Writer, Scenario) then
            Observer.Observe('try_' + Scenario, 'ok')
        else
            Observer.Observe('try_' + Scenario, 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
        ClearLastError();
    end;
}

codeunit 73475 "LT JTW Writer Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The issue's two repros as statements under asserterror, then in the TryFunction form.
    [Test]
    procedure IssueRepros_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT JTW Probe";
        Writer1: Codeunit "Json Text Reader/Writer";
        Writer2: Codeunit "Json Text Reader/Writer";
    begin
        Writer1.WriteStartObject('');
        Writer1.WriteEndObject();
        asserterror Writer1.WriteEndObject();
        Observer.ObserveError('assert_EndObjectTwice');

        Writer2.WriteStartObject('');
        asserterror Writer2.WriteStartObject('');
        Observer.ObserveError('assert_StartObjectInObject');

        Probe.ObserveTry(Observer, 'EndObjectTwice');
        Probe.ObserveTry(Observer, 'StartObjectInObject');
        Observer.Expect('assert_EndObjectTwice|text', 'A call to Newtonsoft.Json.JsonTextWriter.WriteEndObject failed with this message: No token to close. Path ''''.');
        Observer.Expect('assert_EndObjectTwice|code', 'DotNetInvoke:JsonWriter');
        Observer.Expect('assert_StartObjectInObject|text', 'A call to Newtonsoft.Json.JsonTextWriter.WriteStartObject failed with this message: Token StartObject in state ObjectStart would result in an invalid JSON object. Path ''''.');
        Observer.Expect('assert_StartObjectInObject|code', 'DotNetInvoke:JsonWriter');
        Observer.Expect('try_EndObjectTwice', 'E: A call to Newtonsoft.Json.JsonTextWriter.WriteEndObject failed with this message: No token to close. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Expect('try_StartObjectInObject', 'E: A call to Newtonsoft.Json.JsonTextWriter.WriteStartObject failed with this message: Token StartObject in state ObjectStart would result in an invalid JSON object. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Verify();
    end;

    // The neighbours: the other write calls that reach a JsonWriterException, in the TryFunction form.
    [Test]
    procedure WriterStates_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT JTW Probe";
    begin
        Probe.ObserveTry(Observer, 'PropertyTwice');
        Probe.ObserveTry(Observer, 'PropertyInArray');
        Probe.ObserveTry(Observer, 'EndArrayInObject');
        Probe.ObserveTry(Observer, 'EndArrayTwice');
        Probe.ObserveTry(Observer, 'EndObjectInArray');
        Probe.ObserveTry(Observer, 'StartArrayInObject');
        Probe.ObserveTry(Observer, 'PropertyAfterEnd');
        Observer.Expect('try_PropertyTwice', 'E: A call to Newtonsoft.Json.JsonTextWriter.WritePropertyName failed with this message: Token PropertyName in state Property would result in an invalid JSON object. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Expect('try_PropertyInArray', 'E: A call to Newtonsoft.Json.JsonTextWriter.WritePropertyName failed with this message: Token PropertyName in state ArrayStart would result in an invalid JSON object. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Expect('try_EndArrayInObject', 'E: A call to Newtonsoft.Json.JsonTextWriter.WriteEndArray failed with this message: No token to close. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Expect('try_EndArrayTwice', 'E: A call to Newtonsoft.Json.JsonTextWriter.WriteEndArray failed with this message: No token to close. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Expect('try_EndObjectInArray', 'E: A call to Newtonsoft.Json.JsonTextWriter.WriteEndObject failed with this message: No token to close. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Expect('try_StartArrayInObject', 'E: A call to Newtonsoft.Json.JsonTextWriter.WriteStartArray failed with this message: Token StartArray in state ObjectStart would result in an invalid JSON object. Path ''''. | DotNetInvoke:JsonWriter');
        Observer.Expect('try_PropertyAfterEnd', 'ok');
        Observer.Verify();
    end;

    // A write call before the .NET writer exists, and the control without an error (with its JSON text, unformatted).
    [Test]
    procedure NullWriterAndControl()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT JTW Probe";
        Writer: Codeunit "Json Text Reader/Writer";
    begin
        Probe.ObserveTry(Observer, 'EndObjectFirst');
        Probe.ObserveTry(Observer, 'Control');
        Probe.Run(Writer, 'Control');
        Observer.Observe('control_json', Writer.GetJSonAsText());
        Observer.Expect('try_EndObjectFirst', 'E: A DotNet variable has not been instantiated. Attempting to call Newtonsoft.Json.JsonTextWriter.WriteEndObject in CodeUnit Json Text Reader/Writer: WriteEndObject | DotNetVariableNotCreated');
        Observer.Expect('try_Control', 'ok');
        Observer.Expect('control_json', '{"a":"x"}');
        Observer.Verify();
    end;
}
