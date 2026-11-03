// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-method-reference
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunits 83854 and 83855
// Probe: corpus #664 item 44 (microsoft/AL issue 8170, open): a procedure named Array that returns a JsonToken. The tracker reports that the app
//   publishes but every call into the codeunit fails with "C# compilation has failed ... CS0119". Kept in its own file so it can be dropped if the
//   app does not publish.
// Facts: a call to the procedure named Array and a call to another procedure of the same codeunit: return values or error text and code
// BC versions: 27, 28, 29

codeunit 83854 "LT BN3 Array Proc"
{
    procedure Array(Flag: Boolean): JsonToken
    var
        A: JsonArray;
        O: JsonObject;
    begin
        if Flag then begin
            A.Add(1);
            A.Add(2);
            exit(A.AsToken());
        end;
        O.Add('a', 1);
        exit(O.AsToken());
    end;

    procedure Other(): Integer
    begin
        exit(7);
    end;
}

codeunit 83855 "LT BN3 Array Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOther(var Result: Integer)
    var
        P: Codeunit "LT BN3 Array Proc";
    begin
        Result := P.Other();
    end;

    [TryFunction]
    local procedure TryArray(Flag: Boolean; var Result: Text)
    var
        P: Codeunit "LT BN3 Array Proc";
        T: JsonToken;
    begin
        T := P.Array(Flag);
        T.WriteTo(Result);
        Result := Format(T.IsArray()) + '|' + Result;
    end;

    [Test]
    procedure BN3_ProcedureNamedArray_Calls()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        R: Text;
    begin
        if TryOther(I) then
            Observer.Observe('other', Format(I))
        else
            Observer.Observe('other', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        if TryArray(true, R) then
            Observer.Observe('array true', R)
        else
            Observer.Observe('array true', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        if TryArray(false, R) then
            Observer.Observe('array false', R)
        else
            Observer.Observe('array false', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('other', '7');
        Observer.Expect('array true', 'Yes|[1,2]');
        Observer.Expect('array false', 'No|{"a":1}');
        Observer.Verify();
    end;
}
