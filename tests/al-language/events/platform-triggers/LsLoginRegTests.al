// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); XApp A tests/al-language-xapp-a/LsXaLoginReg.al (log 91070, subscribers 91071);
//   subscribers 91049 and test codeunit 91050 below.
// Probe (al-runner issue 9021, cell reg): the "Guided Experience" registration events OnRegisterManualSetup and
//   OnRegisterGuidedExperienceItem and "System Initialization".OnAfterLogin, each with one subscriber in the app under test (ma) and one
//   in a dependency app (xa), all logging into one SingleInstance log. Read: the log as the main app's OnCompanyOpenCompleted subscriber
//   saw it, and as the test sees it. The subscribers register nothing.
// BC versions: 27 - 29

codeunit 91049 "LT LS MA Reg Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure OnRegisterManualSetup()
    var
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Log.Add('ma manual');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterGuidedExperienceItem', '', false, false)]
    local procedure OnRegisterGuidedExperienceItem()
    var
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Log.Add('ma item');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Log.Add('ma login');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure OnCompanyOpenCompleted()
    var
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Log.SnapOpen();
    end;
}

codeunit 91050 "LT LS Reg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Reg_LogOrder()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT LS XA Reg Log";
    begin
        Observer.Observe('at company open', Log.GetOpenTxt());
        Observer.Observe('in test', Log.GetTxt());
        Observer.Finish();
    end;
}
