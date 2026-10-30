// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-add-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own test codeunit 91350
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: HttpHeaders.Add('User-Agent', V) on the headers of a request message and on HttpClient.DefaultRequestHeaders, for product/comment forms with blanks
//   and slashes in odd places ('A B / C D 365 E', 'a / b', 'a /1', 'a/ 1', '/', 'a/b/c', 'a@b'): the Boolean Add returns (or the error text and code),
//   GetValues afterwards (count and each value), and Contains('User-Agent'). lt-se-header-values/SeHeaderValues.al pins 'a b', 'a/1 b/2' and a browser form.
// BC versions: 27, 28, 29

codeunit 91350 "LT Y7 User Agent Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAdd(var H: HttpHeaders; V: Text; var Ret: Boolean)
    begin
        Ret := H.Add('User-Agent', V);
    end;

    [TryFunction]
    local procedure TryGetValues(var H: HttpHeaders; var Vals: List of [Text])
    begin
        H.GetValues('User-Agent', Vals);
    end;

    [TryFunction]
    local procedure TryContains(var H: HttpHeaders; var Has: Boolean)
    begin
        Has := H.Contains('User-Agent');
    end;

    local procedure ReadBack(var H: HttpHeaders): Text
    var
        Vals: List of [Text];
        V: Text;
        Out: Text;
        Has: Boolean;
    begin
        if TryGetValues(H, Vals) then begin
            Out := 'n=' + Format(Vals.Count());
            foreach V in Vals do
                Out += '[' + V + ']';
        end else
            Out := 'get=E[' + CopyStr(GetLastErrorText(), 1, 80) + '|' + GetLastErrorCode() + ']';
        ClearLastError();
        if TryContains(H, Has) then
            Out += ' contains=' + Format(Has)
        else
            Out += ' contains=E[' + CopyStr(GetLastErrorText(), 1, 80) + '|' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Out);
    end;

    local procedure AddTo(var Observer: Codeunit "Probe Observer"; var H: HttpHeaders; ObsKey: Text; V: Text)
    var
        Ret: Boolean;
    begin
        ClearLastError();
        if TryAdd(H, V, Ret) then
            Observer.Observe(ObsKey, 'ret=' + Format(Ret) + ' ' + ReadBack(H))
        else begin
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode() + '] ' + ReadBack(H));
            ClearLastError();
        end;
    end;

    local procedure Req(var Observer: Codeunit "Probe Observer"; ObsKey: Text; V: Text)
    var
        R: HttpRequestMessage;
        H: HttpHeaders;
    begin
        R.GetHeaders(H);
        AddTo(Observer, H, ObsKey, V);
    end;

    local procedure Cli(var Observer: Codeunit "Probe Observer"; ObsKey: Text; V: Text)
    var
        Client: HttpClient;
        H: HttpHeaders;
    begin
        H := Client.DefaultRequestHeaders();
        AddTo(Observer, H, ObsKey, V);
    end;

    local procedure CliDirect(var Observer: Codeunit "Probe Observer"; ObsKey: Text; V: Text)
    var
        Client: HttpClient;
        H: HttpHeaders;
        Ret: Boolean;
    begin
        ClearLastError();
        if TryAddDirect(Client, V, Ret) then begin
            H := Client.DefaultRequestHeaders();
            Observer.Observe(ObsKey, 'ret=' + Format(Ret) + ' ' + ReadBack(H));
        end else begin
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode() + ']');
            ClearLastError();
        end;
    end;

    [TryFunction]
    local procedure TryAddDirect(var Client: HttpClient; V: Text; var Ret: Boolean)
    begin
        Ret := Client.DefaultRequestHeaders.Add('User-Agent', V);
    end;

    [Test]
    procedure Y7_UserAgent_RequestHeaders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'A B / C D 365 E', 'A B / C D 365 E');
        Req(Observer, 'a / b', 'a / b');
        Req(Observer, 'a /1', 'a /1');
        Req(Observer, 'a/ 1', 'a/ 1');
        Req(Observer, '/', '/');
        Req(Observer, 'a/b/c', 'a/b/c');
        Req(Observer, 'a@b', 'a@b');
        Observer.Finish();
    end;

    [Test]
    procedure Y7_UserAgent_DefaultRequestHeaders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cli(Observer, 'A B / C D 365 E', 'A B / C D 365 E');
        Cli(Observer, 'a / b', 'a / b');
        Cli(Observer, 'a /1', 'a /1');
        Cli(Observer, 'a/ 1', 'a/ 1');
        Cli(Observer, '/', '/');
        Cli(Observer, 'a/b/c', 'a/b/c');
        Cli(Observer, 'a@b', 'a@b');
        Observer.Finish();
    end;

    [Test]
    procedure Y7_UserAgent_DefaultRequestHeaders_DirectCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CliDirect(Observer, 'A B / C D 365 E', 'A B / C D 365 E');
        CliDirect(Observer, 'a / b', 'a / b');
        CliDirect(Observer, 'a /1', 'a /1');
        CliDirect(Observer, 'a/ 1', 'a/ 1');
        CliDirect(Observer, '/', '/');
        CliDirect(Observer, 'a/b/c', 'a/b/c');
        CliDirect(Observer, 'a@b', 'a@b');
        Observer.Finish();
    end;
}
