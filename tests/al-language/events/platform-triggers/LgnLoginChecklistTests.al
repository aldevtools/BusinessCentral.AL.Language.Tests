// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guided-experience/guided-experience-assistedsetupexistsandisnotcomplete-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: AL Runner issue 7343. Base Application's "Checklist Events" (codeunit 1997) subscribes to "System Initialization".OnAfterLogin. For a Web, Windows or
//   Desktop client, in a company whose checklist is not set up yet, it calls Checklist.InitializeGuidedExperienceItems(), which raises
//   "Guided Experience".OnRegisterAssistedSetup, and then marks the checklist setup as done. Questions: does the session of the corpus CI raise
//   OnAfterLogin before the first test, in which session and with which client type, does it raise OnRegisterAssistedSetup, is the assisted setup
//   row that this app's OnRegisterAssistedSetup subscriber registers there without the test registering it, and does Checklist still want to initialize.
//   The subscribers keep what they saw in a SingleInstance codeunit (state of the session) and never fail.
// What this does not measure: the issue's case "the checklist was set up before the app was installed" (the CI tenant is fixed), and a
//   BcContainerHelper login (the corpus CI uses its own test runner session; the client type and the login events it sees are in the observations).
// Measured on 27.5 and 28.5 (29.0: see the pull request; the final run checks it): the corpus CI test session is a Web client with GuiAllowed. Before the
//   first test of this codeunit it raised OnRegisterAssistedSetup and then OnAfterLogin, once each, both in the test session. The row this app's
//   subscriber registers exists and is not complete without the test registering it, and Checklist.ShouldInitializeChecklist(false) is already No
//   (the login marked the checklist setup as done). The second test sees no further call.
// BC versions: 27 - 29

// local object: the subscribers and the wizard page exist to be run by the login raised before the first test; when they run is the subject
codeunit 77320 "LGN Login State"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        Sessions: List of [Integer];

    procedure Add(Entry: Text; SessionNo: Integer)
    begin
        Entries.Add(Entry);
        Sessions.Add(SessionNo);
    end;

    procedure Calls(EventName: Text): Integer
    var
        E: Text;
        N: Integer;
    begin
        foreach E in Entries do
            if E.StartsWith(EventName + '|') then
                N += 1;
        exit(N);
    end;

    procedure AsText(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;

    procedure CallsInSession(SessionNo: Integer): Integer
    var
        S: Integer;
        N: Integer;
    begin
        foreach S in Sessions do
            if S = SessionNo then
                N += 1;
        exit(N);
    end;
}

page 77322 "LGN Login Wizard"
{
    PageType = NavigatePage;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Step1)
            {
                InstructionalText = 'Step 1';
            }
        }
    }
}

codeunit 77321 "LGN Login Subs"
{
    local procedure Note(EventName: Text)
    var
        State: Codeunit "LGN Login State";
    begin
        State.Add(EventName + '|' + CompanyName() + '|' + Format(CurrentClientType()) + '|' + Format(GuiAllowed()), SessionId());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AfterLogin()
    begin
        Note('OnAfterLogin');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        Note('OnRegisterAssistedSetup');
        if GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"LGN Login Wizard") then
            exit;
        GuidedExperience.InsertAssistedSetup('Set up LGN', 'Set up LGN', 'Set up the login probe.', 0,
            ObjectType::Page, Page::"LGN Login Wizard", AssistedSetupGroup::Extensions, '', VideoCategory::Extensions, '');
    end;
}

codeunit 77323 "LGN Login Checklist Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        State: Codeunit "LGN Login State";

    // Nothing in this test registers the row or raises the login: the first test of the codeunit reads what is already there.
    [Test]
    procedure LoginChecklist_FirstTest_WhatTheSessionSaw()
    var
        Observer: Codeunit "Probe Observer";
        GuidedExperience: Codeunit "Guided Experience";
        Checklist: Codeunit Checklist;
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        Observer.Observe('entries', State.AsText());
        Observer.Observe('OnAfterLogin calls', Format(State.Calls('OnAfterLogin')));
        Observer.Observe('OnRegisterAssistedSetup calls', Format(State.Calls('OnRegisterAssistedSetup')));
        Observer.Observe('calls in the test session', Format(State.CallsInSession(SessionId())));
        Observer.Observe('test: client type', Format(CurrentClientType()));
        Observer.Observe('test: GuiAllowed', Format(GuiAllowed()));
        Observer.Observe('row of this app exists and is not complete', Format(GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, Page::"LGN Login Wizard")));
        Observer.Observe('row of this app exists', Format(GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"LGN Login Wizard")));
        Observer.Observe('Checklist.ShouldInitializeChecklist(false)', Format(Checklist.ShouldInitializeChecklist(false)));
        Observer.Expect('entries', 'OnRegisterAssistedSetup|<Company>|Web|Yes;OnAfterLogin|<Company>|Web|Yes;');
        Observer.Expect('OnAfterLogin calls', '1');
        Observer.Expect('OnRegisterAssistedSetup calls', '1');
        Observer.Expect('calls in the test session', '2');
        Observer.Expect('test: client type', 'Web');
        Observer.Expect('test: GuiAllowed', 'Yes');
        Observer.Expect('row of this app exists and is not complete', 'Yes');
        Observer.Expect('row of this app exists', 'Yes');
        Observer.Expect('Checklist.ShouldInitializeChecklist(false)', 'No');
        Observer.Verify();
    end;

    // The second test of the codeunit runs in the same session: the login and the registration are not raised again for it.
    [Test]
    procedure LoginChecklist_SecondTest_NotRaisedAgain()
    var
        Observer: Codeunit "Probe Observer";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        Observer.Observe('OnAfterLogin calls', Format(State.Calls('OnAfterLogin')));
        Observer.Observe('OnRegisterAssistedSetup calls', Format(State.Calls('OnRegisterAssistedSetup')));
        Observer.Observe('row of this app exists and is not complete', Format(GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, Page::"LGN Login Wizard")));
        Observer.Expect('OnAfterLogin calls', '1');
        Observer.Expect('OnRegisterAssistedSetup calls', '1');
        Observer.Expect('row of this app exists and is not complete', 'Yes');
        Observer.Verify();
    end;
}
