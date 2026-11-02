// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61459, 61460, 61461
// Probe: three server classes the System Application and Microsoft's apps call through DotNet, called from a test session:
//   - Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword(Length, MinNonAlphanumeric) (behind
//     "Password Handler".GenerateSecretPassword): the shape of the random output over many calls (length, character classes,
//     the set of non-alphanumeric characters, the minimum of non-alphanumerics) and the errors for out-of-range arguments.
//   - Microsoft.Dynamics.Nav.Runtime.VSCodeRequestHelper.GetLaunchInformationQueryPart (behind "VS Code Integration"): the
//     parameter names of the query part (values are server and session specific and are not asserted).
//   - Microsoft.Dynamics.Nav.DataSearch.AL.ALSearch (the platform item search used by Copilot item search):
//     IsItemSearchReady (FindItems is held as a Suspect_ procedure, see there).
// Facts: GeneratePassword accepts lengths 1 to 128 ("Password length incorrect" otherwise) and a minimum of non-alphanumerics from 0
//   to the length ("Number of non alphanumeric characters is incorrect" otherwise), both DotNetInvoke:Argument; it uses 25
//   non-alphanumeric characters and does not guarantee upper case, lower case or digits; the query part names server,
//   serverInstance, port, authentication, runtime and appVersion; IsItemSearchReady is false in a test session.
// Expected values: corpus CI (Linux containers) BC 27.5, 28.5 and 29.0, batch runs 41332956805, 41336116625, 41336138376.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.PasswordGenerator")
    {
        type("Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator"; LtY58PasswordGenerator) { }
    }
    assembly("Microsoft.Dynamics.Nav.Ncl")
    {
        type("Microsoft.Dynamics.Nav.Runtime.VSCodeRequestHelper"; LtY58VSCodeRequestHelper) { }
    }
    assembly("Microsoft.Dynamics.Nav.DataSearch")
    {
        type("Microsoft.Dynamics.Nav.DataSearch.AL.ALSearch"; LtY58ALSearch) { }
        type("Microsoft.Dynamics.Nav.DataSearch.Models.SearchOptions"; LtY58SearchOptions) { }
        type("Microsoft.Dynamics.Nav.DataSearch.Models.SearchQuery"; LtY58SearchQuery) { }
        type("Microsoft.Dynamics.Nav.DataSearch.Models.SearchResult"; LtY58SearchResult) { }
    }
    assembly("Microsoft.Dynamics.Nav.Service.CopilotApi")
    {
        type("Microsoft.Dynamics.Nav.Service.CopilotApi.AL.ALCopilotCapability"; LtY58CopilotCapability) { }
    }
}

codeunit 61459 "LT Y58 PasswordGenerator"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Generator: DotNet LtY58PasswordGenerator;

    [TryFunction]
    local procedure TryGenerate(Length: Integer; MinNonAlphanumeric: Integer; var Password: Text)
    begin
        Password := Generator.GeneratePassword(Length, MinNonAlphanumeric);
    end;

    local procedure IsAlphanumeric(C: Char): Boolean
    begin
        exit(((C >= 'a') and (C <= 'z')) or ((C >= 'A') and (C <= 'Z')) or ((C >= '0') and (C <= '9')));
    end;

    local procedure ObserveShape(Observer: Codeunit "Probe Observer"; Name: Text; Length: Integer; MinNonAlphanumeric: Integer; Calls: Integer)
    var
        Password: Text;
        Symbols: Text;
        C: Char;
        I: Integer;
        J: Integer;
        NonAlnum: Integer;
        MinSeen: Integer;
        AllLength: Boolean;
        LacksUpper: Boolean;
        LacksLower: Boolean;
        LacksDigit: Boolean;
        HasUpper: Boolean;
        HasLower: Boolean;
        HasDigit: Boolean;
        AllDifferent: Boolean;
        Previous: Text;
    begin
        AllLength := true;
        AllDifferent := true;
        MinSeen := 999;
        for I := 1 to Calls do begin
            Password := Generator.GeneratePassword(Length, MinNonAlphanumeric);
            if StrLen(Password) <> Length then
                AllLength := false;
            if Password = Previous then
                AllDifferent := false;
            Previous := Password;
            NonAlnum := 0;
            HasUpper := false;
            HasLower := false;
            HasDigit := false;
            for J := 1 to StrLen(Password) do begin
                C := Password[J];
                if not IsAlphanumeric(C) then begin
                    NonAlnum += 1;
                    if StrPos(Symbols, Format(C)) = 0 then
                        Symbols += Format(C);
                end;
                if (C >= 'A') and (C <= 'Z') then
                    HasUpper := true;
                if (C >= 'a') and (C <= 'z') then
                    HasLower := true;
                if (C >= '0') and (C <= '9') then
                    HasDigit := true;
            end;
            if NonAlnum < MinSeen then
                MinSeen := NonAlnum;
            if not HasUpper then
                LacksUpper := true;
            if not HasLower then
                LacksLower := true;
            if not HasDigit then
                LacksDigit := true;
        end;
        Observer.Observe(Name + ' every length as asked', Format(AllLength));
        Observer.Observe(Name + ' consecutive calls differ', Format(AllDifferent));
        Observer.Observe(Name + ' fewest non-alphanumerics >= asked', Format(MinSeen >= MinNonAlphanumeric));
        Observer.Observe(Name + ' some password without upper case', Format(LacksUpper));
        Observer.Observe(Name + ' some password without lower case', Format(LacksLower));
        Observer.Observe(Name + ' some password without digit', Format(LacksDigit));
        Observer.Observe(Name + ' non-alphanumerics seen (sorted)', SortChars(Symbols));
    end;

    local procedure SortChars(Value: Text): Text
    var
        Result: Text;
        Code: Integer;
        C: Char;
    begin
        for Code := 33 to 126 do begin
            C := Code;
            if StrPos(Value, Format(C)) > 0 then
                Result += Format(C);
        end;
        for Code := 1 to StrLen(Value) do
            if (Value[Code] < 33) or (Value[Code] > 126) then
                Result += Format(Value[Code]);
        exit(Result);
    end;

    [Test]
    procedure PasswordGenerator_Shape_8_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, '8/1', 8, 1, 400);
        Observer.Expect('8/1 every length as asked', 'Yes');
        Observer.Expect('8/1 consecutive calls differ', 'Yes');
        Observer.Expect('8/1 fewest non-alphanumerics >= asked', 'Yes');
        Observer.Expect('8/1 some password without upper case', 'Yes');
        Observer.Expect('8/1 some password without lower case', 'Yes');
        Observer.Expect('8/1 some password without digit', 'Yes');
        Observer.Expect('8/1 non-alphanumerics seen (sorted)', '!#$%&()*+-./:;=>?@[]^_{|}');
        Observer.Verify();
    end;

    [Test]
    procedure PasswordGenerator_Shape_64_0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, '64/0', 64, 0, 400);
        Observer.Expect('64/0 every length as asked', 'Yes');
        Observer.Expect('64/0 consecutive calls differ', 'Yes');
        Observer.Expect('64/0 fewest non-alphanumerics >= asked', 'Yes');
        Observer.Expect('64/0 some password without upper case', 'No');
        Observer.Expect('64/0 some password without lower case', 'No');
        Observer.Expect('64/0 some password without digit', 'No');
        Observer.Expect('64/0 non-alphanumerics seen (sorted)', '!#$%&()*+-./:;=>?@[]^_{|}');
        Observer.Verify();
    end;

    [Test]
    procedure PasswordGenerator_Shape_16_10()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, '16/10', 16, 10, 200);
        Observer.Expect('16/10 every length as asked', 'Yes');
        Observer.Expect('16/10 consecutive calls differ', 'Yes');
        Observer.Expect('16/10 fewest non-alphanumerics >= asked', 'Yes');
        Observer.Expect('16/10 some password without upper case', 'Yes');
        Observer.Expect('16/10 some password without lower case', 'Yes');
        Observer.Expect('16/10 some password without digit', 'Yes');
        Observer.Expect('16/10 non-alphanumerics seen (sorted)', '!#$%&()*+-./:;=>?@[]^_{|}');
        Observer.Verify();
    end;

    [Test]
    procedure PasswordGenerator_Shape_5_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveShape(Observer, '5/5', 5, 5, 200);
        Observer.Expect('5/5 every length as asked', 'Yes');
        Observer.Expect('5/5 consecutive calls differ', 'Yes');
        Observer.Expect('5/5 fewest non-alphanumerics >= asked', 'Yes');
        Observer.Expect('5/5 some password without upper case', 'Yes');
        Observer.Expect('5/5 some password without lower case', 'Yes');
        Observer.Expect('5/5 some password without digit', 'Yes');
        Observer.Expect('5/5 non-alphanumerics seen (sorted)', '!#$%&()*+-./:;=>?@[]^_{|}');
        Observer.Verify();
    end;

    [Test]
    procedure PasswordGenerator_Arguments()
    var
        Observer: Codeunit "Probe Observer";
        Password: Text;
    begin
        if TryGenerate(0, 0, Password) then Observer.Observe('length 0', Format(StrLen(Password))) else Observer.ObserveError('length 0');
        if TryGenerate(1, 0, Password) then Observer.Observe('length 1', Format(StrLen(Password))) else Observer.ObserveError('length 1');
        if TryGenerate(128, 1, Password) then Observer.Observe('length 128', Format(StrLen(Password))) else Observer.ObserveError('length 128');
        if TryGenerate(129, 1, Password) then Observer.Observe('length 129', Format(StrLen(Password))) else Observer.ObserveError('length 129');
        if TryGenerate(-1, 0, Password) then Observer.Observe('length -1', Format(StrLen(Password))) else Observer.ObserveError('length -1');
        if TryGenerate(4, 6, Password) then Observer.Observe('min 6 > length 4', Format(StrLen(Password))) else Observer.ObserveError('min 6 > length 4');
        if TryGenerate(8, -1, Password) then Observer.Observe('min -1', Format(StrLen(Password))) else Observer.ObserveError('min -1');
        Observer.Expect('length 0|text', 'A call to Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword failed with this message: Password length incorrect');
        Observer.Expect('length 0|code', 'DotNetInvoke:Argument');
        Observer.Expect('length 1', '1');
        Observer.Expect('length 128', '128');
        Observer.Expect('length 129|text', 'A call to Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword failed with this message: Password length incorrect');
        Observer.Expect('length 129|code', 'DotNetInvoke:Argument');
        Observer.Expect('length -1|text', 'A call to Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword failed with this message: Password length incorrect');
        Observer.Expect('length -1|code', 'DotNetInvoke:Argument');
        Observer.Expect('min 6 > length 4|text', 'A call to Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword failed with this message: Number of non alphanumeric characters is incorrect');
        Observer.Expect('min 6 > length 4|code', 'DotNetInvoke:Argument');
        Observer.Expect('min -1|text', 'A call to Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword failed with this message: Number of non alphanumeric characters is incorrect');
        Observer.Expect('min -1|code', 'DotNetInvoke:Argument');
        Observer.Verify();
    end;
}

codeunit 61460 "LT Y58 VSCodeRequestHelper"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: DotNet LtY58VSCodeRequestHelper;

    [TryFunction]
    local procedure TryQueryPart(var QueryPart: Text)
    begin
        QueryPart := Helper.GetLaunchInformationQueryPart();
    end;

    [Test]
    procedure VSCodeRequestHelper_LaunchQueryPart_Names()
    var
        Observer: Codeunit "Probe Observer";
        QueryPart: Text;
        Part: Text;
        Names: Text;
        Empty: Text;
    begin
        if not TryQueryPart(QueryPart) then begin
            Observer.ObserveError('query part');
            Observer.Expect('starts with ? or &', 'No');
            Observer.Expect('parameter names', 'server;serverInstance;port;authentication;runtime;appVersion;');
            Observer.Expect('parameters with empty value', '');
            Observer.Verify();
            exit;
        end;
        Observer.Observe('starts with ? or &', Format(QueryPart.StartsWith('?') or QueryPart.StartsWith('&')));
        foreach Part in QueryPart.TrimStart('?&').Split('&') do begin
            if Part.Contains('=') then begin
                Names += Part.Substring(1, Part.IndexOf('=') - 1) + ';';
                if Part.EndsWith('=') then
                    Empty += Part.Substring(1, Part.IndexOf('=') - 1) + ';';
            end else
                Names += Part + '(no =);';
        end;
        Observer.Observe('parameter names', Names);
        Observer.Observe('parameters with empty value', Empty);
        Observer.Expect('starts with ? or &', 'No');
        Observer.Expect('parameter names', 'server;serverInstance;port;authentication;runtime;appVersion;');
        Observer.Expect('parameters with empty value', '');
        Observer.Verify();
    end;
}

codeunit 61461 "LT Y58 ALSearch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Search: DotNet LtY58ALSearch;

    [TryFunction]
    local procedure TryIsReady(var Ready: Boolean)
    begin
        Ready := Search.IsItemSearchReady();
    end;

    [TryFunction]
    local procedure TryFindItems(var Result: Text)
    var
        Options: DotNet LtY58SearchOptions;
        SearchQuery: DotNet LtY58SearchQuery;
        Capability: DotNet LtY58CopilotCapability;
        SearchResult: DotNet LtY58SearchResult;
        CurrentModuleInfo: ModuleInfo;
    begin
        Options := Options.SearchOptions();
        SearchQuery := SearchQuery.SearchQuery('1');
        SearchQuery.AddRequiredTerm('bicycle');
        SearchQuery.Top := 5;
        Options.AddSearchQuery(SearchQuery);
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Capability := Capability.ALCopilotCapability(CurrentModuleInfo.Publisher(), CurrentModuleInfo.Id(), Format(CurrentModuleInfo.AppVersion()), 'LT Y58 Probe');
        SearchResult := Search.FindItems(Options, Capability);
        if IsNull(SearchResult) then
            Result := 'null'
        else
            Result := 'result';
    end;

    [Test]
    procedure ALSearch_IsItemSearchReady()
    var
        Observer: Codeunit "Probe Observer";
        Ready: Boolean;
    begin
        if TryIsReady(Ready) then
            Observer.Observe('ready', Format(Ready))
        else
            Observer.ObserveError('ready');
        Observer.Expect('ready', 'No');
        Observer.Verify();
    end;

    // Held (not a test): on the Linux CI containers FindItems returned a result on BC 27.5 but ended the test on 28.5 and 29.0 with
    // "An unexpected error occurred after a database command was cancelled." (not caught by the TryFunction). To be checked on the
    // Windows containers before it is asserted.
    procedure Suspect_ALSearch_FindItems_InTestSession()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        if TryFindItems(Result) then
            Observer.Observe('find items', Result)
        else
            Observer.ObserveError('find items');
        Observer.Finish();
    end;
}
