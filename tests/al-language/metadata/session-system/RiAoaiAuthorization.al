// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.ai.azure-openai
// Scope: in-scope
// Fixtures used: Probe Observer (69160); System Application codeunits "Azure OpenAI" (7771) and "AOAI Deployments"
// Probe (writer RI, al-runtime-rs issue 5693): "Azure OpenAI".SetAuthorization(model type, deployment) sets First Party authorization, so
//   IsAuthorizationConfigured asks the platform (ALCopilotFunctions.IsPlatformAuthorizationConfigured, a server class with no AL body).
//   What that answer is on the test container, for each model type, and that a fresh codeunit answers without asking.
// BC versions: 27, 28, 29

codeunit 88061 "LT RI AOAI Authorization"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFirstParty(ModelType: Enum "AOAI Model Type"; var Configured: Boolean)
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIDeployments: Codeunit "AOAI Deployments";
    begin
        AzureOpenAI.SetAuthorization(ModelType, AOAIDeployments.GetGPT41Latest());
        Configured := AzureOpenAI.IsAuthorizationConfigured(ModelType);
    end;

    [TryFunction]
    local procedure TryNotSet(ModelType: Enum "AOAI Model Type"; var Configured: Boolean)
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        Configured := AzureOpenAI.IsAuthorizationConfigured(ModelType);
    end;

    local procedure ObserveFirstParty(Name: Text; ModelType: Enum "AOAI Model Type"; var Observer: Codeunit "Probe Observer")
    var
        Configured: Boolean;
    begin
        ClearLastError();
        if TryFirstParty(ModelType, Configured) then
            Observer.Observe(Name, 'ok ' + Format(Configured))
        else
            Observer.Observe(Name, 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FirstParty_ChatCompletions_IsAuthorizationConfigured()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFirstParty('chat', Enum::"AOAI Model Type"::"Chat Completions", Observer);
        Observer.Expect('chat', 'ok No');
        Observer.Verify();
    end;

    [Test]
    procedure FirstParty_Embeddings_IsAuthorizationConfigured()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFirstParty('embeddings', Enum::"AOAI Model Type"::Embeddings, Observer);
        Observer.Expect('embeddings', 'ok No');
        Observer.Verify();
    end;

    [Test]
    procedure FirstParty_TextCompletions_IsAuthorizationConfigured()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveFirstParty('text', Enum::"AOAI Model Type"::"Text Completions", Observer);
        Observer.Expect('text', 'ok No');
        Observer.Verify();
    end;

    [Test]
    procedure NotSet_ChatCompletions_IsAuthorizationConfigured()
    var
        Observer: Codeunit "Probe Observer";
        Configured: Boolean;
    begin
        ClearLastError();
        if TryNotSet(Enum::"AOAI Model Type"::"Chat Completions", Configured) then
            Observer.Observe('not set', 'ok ' + Format(Configured))
        else
            Observer.Observe('not set', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('not set', 'ok No');
        Observer.Verify();
    end;
}
