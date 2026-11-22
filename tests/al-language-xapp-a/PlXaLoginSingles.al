// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 8115, cell s09; tests: tests/al-language/events/platform-triggers/PlLoginSingleTests.al): a dependency app's
//   (XApp A, not the app under test, not Microsoft) subscriber of "System Initialization".OnAfterLogin sets the globals of a SingleInstance
//   codeunit of its own app (an Integer, a List, a Text). Does it run in the test session, and which state does the test see?
//   Added beside tests/al-language-xapp-a/G1sXaInstall.al (corpus pull request 1405), which this file does not change.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

// singleinstance-shared-on-purpose: the probe is what a SingleInstance codeunit of a dependency app carries from the login session into
// the test session and from one test codeunit to the next (two test codeunits read the same instance).
codeunit 98486 "LT PL XA Singles"
{
    SingleInstance = true;

    var
        Cnt: Integer;
        Names: List of [Text];
        Txt: Text;
        LoginCalls: Integer;

    procedure SetFromLogin()
    begin
        Cnt := 10;
        Names.Add('x');
        Txt += 'L';
        LoginCalls += 1;
    end;

    procedure IncCnt()
    begin
        Cnt += 1;
    end;

    procedure GetCnt(): Integer
    begin
        exit(Cnt);
    end;

    procedure NameCount(): Integer
    begin
        exit(Names.Count());
    end;

    procedure GetTxt(): Text
    begin
        exit(Txt);
    end;

    procedure GetLoginCalls(): Integer
    begin
        exit(LoginCalls);
    end;
}

codeunit 98487 "LT PL XA Login Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Singles: Codeunit "LT PL XA Singles";
    begin
        Singles.SetFromLogin();
    end;
}
