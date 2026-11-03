// BC Documentation: https://www.newtonsoft.com/json/help/html/T_Newtonsoft_Json_JsonTextWriter.htm
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99100
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: DotNet Newtonsoft.Json.JsonTextWriter over a System.IO.StringWriter: the app can declare the type and a simple object write produces the expected text.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.IO.StringWriter"; LtAlStringWriter) { }
    }

    assembly("Newtonsoft.Json")
    {
        type("Newtonsoft.Json.JsonTextWriter"; LtAlJsonTextWriter) { }
    }
}

codeunit 99100 "LT AL JsonTextWriter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryWrite(var Result: Text)
    var
        Sw: DotNet LtAlStringWriter;
        Writer: DotNet LtAlJsonTextWriter;
    begin
        Sw := Sw.StringWriter();
        Writer := Writer.JsonTextWriter(Sw);
        Writer.WriteStartObject();
        Writer.WritePropertyName('name');
        Writer.WriteValue('Alpha');
        Writer.WritePropertyName('count');
        Writer.WriteValue(3);
        Writer.WritePropertyName('on');
        Writer.WriteValue(true);
        Writer.WriteEndObject();
        Writer.Flush();
        Result := Sw.ToString();
    end;

    [Test]
    procedure AL_JsonTextWriter_SimpleObject()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        ClearLastError();
        if TryWrite(Result) then
            Observer.Observe('write', Result)
        else
            Observer.ObserveError('write');
        Observer.Expect('write', '{"name":"Alpha","count":3,"on":true}');
        Observer.Verify();
    end;
}
