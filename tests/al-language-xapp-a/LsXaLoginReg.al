// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 9021, cell reg; tests: tests/al-language/events/platform-triggers/LsLoginRegTests.al): does a dependency app's
//   (XApp A) subscriber of "Guided Experience".OnRegisterManualSetup and OnRegisterGuidedExperienceItem run in the test session, and in
//   which order relative to the OnAfterLogin subscribers? The subscribers only log; they register nothing (no Microsoft table is written).
//   The main app has the same three subscribers on the same log.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

// singleinstance-shared-on-purpose: the log is written by subscribers of two apps and read by the main app's Company Triggers subscriber
// and its test codeunit.
codeunit 91070 "LT LS XA Reg Log"
{
    SingleInstance = true;

    var
        Txt: Text;
        OpenTxt: Text;
        Opened: Boolean;

    procedure Add(Tag: Text)
    begin
        Txt += Tag + ';';
    end;

    procedure SnapOpen()
    begin
        if Opened then
            exit;
        Opened := true;
        OpenTxt := Txt;
    end;

    procedure GetTxt(): Text
    begin
        exit(Txt);
    end;

    procedure GetOpenTxt(): Text
    begin
        exit(OpenTxt);
    end;
}

codeunit 91071 "LT LS XA Reg Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure OnRegisterManualSetup()
    var
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Log.Add('xa manual');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterGuidedExperienceItem', '', false, false)]
    local procedure OnRegisterGuidedExperienceItem()
    var
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Log.Add('xa item');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Log.Add('xa login');
    end;
}
