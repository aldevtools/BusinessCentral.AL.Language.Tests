// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-httpclient
// Scope: in-scope
// Fixtures used: none; shared Assert (60021)
//
/// <summary>
/// CLAIM: with TestHttpRequestPolicy = BlockOutboundRequests and no [HttpClientHandler] to
/// serve it, an outbound request raises the platform's own unhandled-request error instead of
/// reaching the network. Its own codeunit because the property is codeunit-level.
///
/// This is the half of AL's HTTP-mocking contract the corpus can express. The other half --
/// what an [HttpClientHandler] does when it serves a request, and what a handler returning true
/// does -- cannot be tested here at all: the attribute has scope OnPrem, and this app targets
/// Cloud, so the AL compiler rejects it with
/// "error AL0296: The application object or method 'HttpClientHandler' has scope 'OnPrem' and
/// cannot be used for 'Cloud' development." Measured, not assumed. That coverage therefore lives
/// in AL Runner's own tests/runner-extras, in an OnPrem-target bundle, with the same reason
/// recorded there.
///
/// TestHttpClient.al is the complementary case for the policy: no TestHttpRequestPolicy
/// declared, a real outbound GET, and it passes -- which is what says an ABSENT policy allows
/// outbound requests.
/// </summary>
codeunit 60318 "HttpClient Block NoHandler"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure BlockPolicy_NoHandler_RaisesTheUnhandledRequestError()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        asserterror Client.Get('https://unreachable.invalid/blocked', Response);

        // Asserted on the policy name rather than the whole sentence: the wording is the
        // platform's and may be retranslated, but a message about the blocking policy is the
        // claim -- and it is what tells the two failure modes apart from a network timeout.
        Assert.ExpectedError('BlockOutboundRequests');
    end;
}
