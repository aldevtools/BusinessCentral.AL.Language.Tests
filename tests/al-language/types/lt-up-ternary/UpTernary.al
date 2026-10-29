// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own interfaces "LT UP Preview" and "LT UP Selector", codeunits 90493-90497
// Probe (writer UP, al-runner issues 6213 and 6215):
//   1. a conditional expression with a Text[250] true branch and an unbounded Text false branch (StrSubstNo result, Text variable), the value
//      read into an unbounded Text return value: the false value that fits is returned unchanged, at 250 characters it still fits, at 251
//      the conversion raises. Pinned before for Text[10] true / 12-char Text false: types/TestTernaryContracts.al (PYC_Ternary_MoreBranchPairs).
//   2. an interface true branch with a codeunit false branch (the reverse, a codeunit true branch with an interface false branch, does not compile: must-not-compile case 2291): which implementation is called. Pinned before: interface/interface
//      and codeunit/codeunit pairs (types/TestTernaryContracts.al, ObjectForms).
// BC versions: 27-29

interface "LT UP Preview"
{
    procedure GetPreview(): Text;
}

interface "LT UP Selector"
{
    procedure GetName(): Text;
}

codeunit 90493 "LT UP Special" implements "LT UP Preview", "LT UP Selector"
{
    var
        Calls: Integer;

    procedure GetPreview(): Text
    begin
        Calls += 1;
        exit('special' + Format(Calls));
    end;

    procedure GetName(): Text
    begin
        exit('special');
    end;
}

codeunit 90494 "LT UP Default" implements "LT UP Preview"
{
    procedure GetPreview(): Text
    begin
        exit('default');
    end;
}

codeunit 90495 "LT UP Factory"
{
    procedure GetSelector(): Interface "LT UP Selector"
    var
        Special: Codeunit "LT UP Special";
    begin
        exit(Special);
    end;

    procedure ViaCast(UseSpecial: Boolean): Interface "LT UP Preview"
    var
        Default: Codeunit "LT UP Default";
    begin
        exit(UseSpecial ? (GetSelector() as "LT UP Preview") : Default);
    end;

    procedure ViaVariable(UseSpecial: Boolean): Interface "LT UP Preview"
    var
        Default: Codeunit "LT UP Default";
        Special: Codeunit "LT UP Special";
        Preview: Interface "LT UP Preview";
    begin
        Preview := Special;
        exit(UseSpecial ? Preview : Default);
    end;

    procedure AssignToInterfaceVariable(UseSpecial: Boolean): Text
    var
        Default: Codeunit "LT UP Default";
        Special: Codeunit "LT UP Special";
        Preview: Interface "LT UP Preview";
        Chosen: Interface "LT UP Preview";
    begin
        Preview := Special;
        Chosen := UseSpecial ? Preview : Default;
        exit(Chosen.GetPreview());
    end;
}

codeunit 90496 "LT UP Url Builder"
{
    var
        BaseUrl: Text[250];
        AccountName: Text;

    procedure SetBaseUrl(NewBaseUrl: Text[250])
    begin
        BaseUrl := NewBaseUrl;
    end;

    procedure SetAccountName(NewAccountName: Text)
    begin
        AccountName := NewAccountName;
    end;

    procedure GetBaseUrl(): Text[250]
    begin
        exit(BaseUrl);
    end;

    procedure GetUrl(): Text
    var
        BaseUrlTok: Label 'https://%1.blob.core.windows.net', Locked = true;
    begin
        exit(BaseUrl <> '' ? GetBaseUrl() : StrSubstNo(BaseUrlTok, AccountName));
    end;

    procedure GetUrlFromText(): Text
    var
        Fallback: Text;
    begin
        Fallback := 'https://' + AccountName;
        exit(BaseUrl <> '' ? BaseUrl : Fallback);
    end;

    procedure GetUrlIntoTextVariable(): Text
    var
        Result: Text;
        Fallback: Text;
    begin
        Fallback := AccountName;
        Result := BaseUrl <> '' ? BaseUrl : Fallback;
        exit(Result);
    end;
}

codeunit 90497 "LT UP Ternary Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UP_Ternary_Text250TrueUnboundedTextFalse()
    var
        Observer: Codeunit "Probe Observer";
        Builder: Codeunit "LT UP Url Builder";
    begin
        Builder.SetAccountName('acct');
        Observer.Observe('false StrSubstNo', Builder.GetUrl());
        Observer.Observe('false Text variable', Builder.GetUrlFromText());
        Observer.Observe('false into Text variable', Builder.GetUrlIntoTextVariable());
        Builder.SetBaseUrl('https://custom.example');
        Observer.Observe('true StrSubstNo', Builder.GetUrl());
        Observer.Observe('true Text variable', Builder.GetUrlFromText());
        Observer.Observe('true into Text variable', Builder.GetUrlIntoTextVariable());
        Observer.Expect('false StrSubstNo', 'https://acct.blob.core.windows.net');
        Observer.Expect('false Text variable', 'https://acct');
        Observer.Expect('false into Text variable', 'acct');
        Observer.Expect('true StrSubstNo', 'https://custom.example');
        Observer.Expect('true Text variable', 'https://custom.example');
        Observer.Expect('true into Text variable', 'https://custom.example');
        Observer.Verify();
    end;

    [Test]
    procedure UP_Ternary_Text250TrueUnboundedTextFalse_Length()
    var
        Observer: Codeunit "Probe Observer";
        Builder: Codeunit "LT UP Url Builder";
        R: Text;
    begin
        Builder.SetAccountName(PadStr('', 250 - StrLen('https://'), 'a'));
        if TryUrlFromText(Builder, R) then
            Observer.Observe('250 chars', 'ok|' + Format(StrLen(R)))
        else
            Observer.Observe('250 chars', 'error');
        Builder.SetAccountName(PadStr('', 251 - StrLen('https://'), 'a'));
        if TryUrlFromText(Builder, R) then
            Observer.Observe('251 chars', 'ok|' + Format(StrLen(R)))
        else
            ObserveLastError(Observer, '251 chars');
        Builder.SetAccountName(PadStr('', 300, 'a'));
        if TryIntoTextVariable(Builder, R) then
            Observer.Observe('300 chars into Text variable', 'ok|' + Format(StrLen(R)))
        else
            ObserveLastError(Observer, '300 chars into Text variable');
        Observer.Expect('250 chars', 'ok|250');
        Observer.Verify();
    end;

    local procedure ObserveLastError(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Msg: Text;
    begin
        Msg := GetLastErrorText();
        Observer.Observe(Name + ' code', GetLastErrorCode());
        Observer.Observe(Name + ' length', Format(StrLen(Msg)));
        Observer.Observe(Name + ' head', CopyStr(Msg, 1, 110));
        Observer.Observe(Name + ' tail', CopyStr(Msg, StrLen(Msg) - 20));
    end;

    [TryFunction]
    local procedure TryUrlFromText(var Builder: Codeunit "LT UP Url Builder"; var Result: Text)
    begin
        Result := Builder.GetUrlFromText();
    end;

    [TryFunction]
    local procedure TryIntoTextVariable(var Builder: Codeunit "LT UP Url Builder"; var Result: Text)
    begin
        Result := Builder.GetUrlIntoTextVariable();
    end;

    [Test]
    procedure UP_Ternary_InterfaceTrueCodeunitFalse()
    var
        Observer: Codeunit "Probe Observer";
        Factory: Codeunit "LT UP Factory";
    begin
        Observer.Observe('cast, false', Factory.ViaCast(false).GetPreview());
        Observer.Observe('cast, true', Factory.ViaCast(true).GetPreview());
        Observer.Observe('variable, false', Factory.ViaVariable(false).GetPreview());
        Observer.Observe('variable, true', Factory.ViaVariable(true).GetPreview());
        Observer.Observe('assigned, false', Factory.AssignToInterfaceVariable(false));
        Observer.Observe('assigned, true', Factory.AssignToInterfaceVariable(true));
        Observer.Expect('cast, false', 'default');
        Observer.Expect('cast, true', 'special1');
        Observer.Expect('variable, false', 'default');
        Observer.Expect('variable, true', 'special1');
        Observer.Expect('assigned, false', 'default');
        Observer.Expect('assigned, true', 'special1');
        Observer.Verify();
    end;
}
