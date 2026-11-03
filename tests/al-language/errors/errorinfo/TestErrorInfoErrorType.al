// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-errortype-method
// Scope: in-scope (Cloud-compatible) -- ErrorType binds against this app's Cloud target,
//   runtime 16.0, as errorinfo/TestErrorInfoType.al's header records for all 21 members.
// Fixtures used: shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: ErrorInfo.ErrorType decides WHOSE TEXT the raised error reports.
///
/// ErrorType::Client (the default) reports the ErrorInfo's own Message verbatim.
/// ErrorType::Internal REPLACES it with a generic platform message carrying a
/// per-raise correlation identifier, so the author's text never reaches the caller.
///
/// errorinfo/TestErrorInfoType.al pins ErrorType as an ACCESSOR -- that a written value
/// reads back. Nothing upstream pinned what the value DOES when the ErrorInfo is raised,
/// which is the whole point of the member. This file does that.
///
/// WHAT EACH TEST WOULD CATCH:
///
///   ErrorType_RoundTrips_BothMembers
///       an implementation that ignores its argument, or that cannot represent Internal.
///
///   ClientErrorType_ReportsTheMessageVerbatim
///       an implementation that masks EVERY raised ErrorInfo. Without this test, a
///       platform that always substituted the generic text would pass the Internal test
///       below and look correct.
///
///   InternalErrorType_MasksTheAuthorsMessage
///       the complement, and the load-bearing half: an implementation that ignores
///       ErrorType and reports Message regardless. The pair is what discriminates --
///       neither test alone can tell "honours ErrorType" from "always does one thing".
///
///   InternalErrorType_EachRaiseIsDistinct
///       that the substituted text carries something PER-RAISE rather than being one
///       fixed constant. Two raises of one identical ErrorInfo must not produce identical
///       text. This is asserted structurally rather than by matching the platform's
///       wording, so it holds across versions and locales without pinning prose.
/// </summary>
codeunit 60758 "Test ErrorInfo ErrorType"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure ErrorType_RoundTrips_BothMembers()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create('round trip');

        // Internal first: it is the non-default, so an implementation answering the
        // default would fail here rather than in the Client leg below.
        EI.ErrorType(ErrorType::Internal);
        Assert.AreEqual('Internal', Format(EI.ErrorType()), 'ErrorType must round-trip Internal');

        EI.ErrorType(ErrorType::Client);
        Assert.AreEqual('Client', Format(EI.ErrorType()), 'ErrorType must round-trip Client');
    end;

    [Test]
    procedure ClientErrorType_ReportsTheMessageVerbatim()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create('the client visible text');
        EI.ErrorType(ErrorType::Client);

        asserterror Error(EI);
        Assert.AreEqual('the client visible text', GetLastErrorText(),
            'a Client-type ErrorInfo must report its own Message verbatim');
    end;

    [Test]
    procedure InternalErrorType_MasksTheAuthorsMessage()
    var
        EI: ErrorInfo;
        Raised: Text;
    begin
        Initialize();
        EI := ErrorInfo.Create('the internal secret text');
        EI.ErrorType(ErrorType::Internal);

        asserterror Error(EI);
        Raised := GetLastErrorText();

        Assert.AreNotEqual('', Raised, 'an Internal-type ErrorInfo must still raise a non-empty error');
        Assert.AreEqual(0, StrPos(Raised, 'the internal secret text'),
            'an Internal-type ErrorInfo must NOT leak its own Message to the caller');
    end;

    [Test]
    procedure InternalErrorType_EachRaiseIsDistinct()
    var
        EI: ErrorInfo;
        First: Text;
        Second: Text;
    begin
        Initialize();

        EI := ErrorInfo.Create('identical message both times');
        EI.ErrorType(ErrorType::Internal);
        asserterror Error(EI);
        First := GetLastErrorText();

        ClearLastError();

        EI := ErrorInfo.Create('identical message both times');
        EI.ErrorType(ErrorType::Internal);
        asserterror Error(EI);
        Second := GetLastErrorText();

        Assert.AreNotEqual('', First, 'the first Internal raise must produce text');
        Assert.AreNotEqual('', Second, 'the second Internal raise must produce text');
        // Same author message both times, so any difference comes from the platform's
        // own per-raise correlation value rather than from the input.
        Assert.AreNotEqual(First, Second,
            'each Internal raise must carry a per-raise correlation, so two raises of one identical ErrorInfo differ');
    end;

    local procedure Initialize()
    begin
        ClearLastError();
        Cleanup.Initialize();
    end;
}
