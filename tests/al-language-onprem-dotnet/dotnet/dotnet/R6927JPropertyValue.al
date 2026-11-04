// BC Documentation: https://www.newtonsoft.com/json/help/html/P_Newtonsoft_Json_Linq_JProperty_Value.htm
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; Base Application codeunit 5459 "JSON Management";
//   self-contained codeunit 95300
// Probe: al-runtime-rs issue 6927: Base Application's "JSON Management".GetPropertyValueFromJObjectByName reads
//   `value := JProperty.Value();` into a Variant and GetStringPropertyValueByName formats it. JProperty has the property
//   `JToken Value`; its base JToken also has the generic method `T Value<T>(object key)` of the same name. Observed on the
//   corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: JProperty.Value() and JProperty.Value (without parentheses) read the property: the JValue of the property, whose
//   Format is the JSON string's text; in a Variant it stays a DotNet value. "JSON Management".InitializeObject and
//   GetStringPropertyValueByName return the text of a string property and false for a missing one.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Newtonsoft.Json")
    {
        type("Newtonsoft.Json.Linq.JObject"; LtR69JObject) { }
        type("Newtonsoft.Json.Linq.JProperty"; LtR69JProperty) { }
        type("Newtonsoft.Json.Linq.JToken"; LtR69JToken) { }
    }
}

codeunit 95300 "LT R6927 JProperty Value"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure JPropertyValue_CalledWithoutArguments_ReadsTheProperty()
    var
        JObject: DotNet LtR69JObject;
        JProperty: DotNet LtR69JProperty;
        JToken: DotNet LtR69JToken;
        Value: Variant;
    begin
        JObject := JObject.Parse('{"accessCode":"ABC123","count":7}');
        JProperty := JObject.Property('accessCode');
        Value := JProperty.Value();
        Observer.Observe('Variant Format', Format(Value));
        Observer.Observe('Variant IsDotNet', Format(Value.IsDotNet()));
        Observer.Observe('Variant IsText', Format(Value.IsText()));
        JToken := JProperty.Value();
        Observer.Observe('JToken Format', Format(JToken));
        JToken := JProperty.Value;
        Observer.Observe('no parentheses Format', Format(JToken));
        JProperty := JObject.Property('count');
        Value := JProperty.Value();
        Observer.Observe('number Format', Format(Value));
        Observer.Expect('Variant Format', 'ABC123');
        Observer.Expect('Variant IsDotNet', 'Yes');
        Observer.Expect('Variant IsText', 'No');
        Observer.Expect('JToken Format', 'ABC123');
        Observer.Expect('no parentheses Format', 'ABC123');
        Observer.Expect('number Format', '7');
        Observer.Verify();
    end;

    [Test]
    procedure JsonManagement_GetStringPropertyValueByName_ReturnsTheText()
    var
        JSONManagement: Codeunit "JSON Management";
        Value: Text;
    begin
        JSONManagement.InitializeObject('{"accessCode":"ABC123"}');
        Observer.Observe('found', Format(JSONManagement.GetStringPropertyValueByName('accessCode', Value)));
        Observer.Observe('value', Value);
        Observer.Observe('missing found', Format(JSONManagement.GetStringPropertyValueByName('noSuchName', Value)));
        Observer.Observe('missing value', Value);
        Observer.Expect('found', 'Yes');
        Observer.Expect('value', 'ABC123');
        Observer.Expect('missing found', 'No');
        Observer.Expect('missing value', '');
        Observer.Verify();
    end;
}
