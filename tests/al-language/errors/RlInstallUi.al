// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Probe: AL Runner issue 5751 (writer RL). An install routine that shows a Message (plain, not inside a TryFunction) and keeps going, and the
//   other UI calls setup code reaches during install. Pinned elsewhere, not repeated here: GuiAllowed() is false in a Subtype = Install
//   codeunit, and Message / Confirm / Page.RunModal inside a TryFunction there (install/lt-cm-install-leads/CmInstallLeads.al:54-61);
//   CompanyName() during install is the session company (install/TestInstallEnvVisible_Tests.al).
// The code runs in "Extension Triggers" install subscribers of this app (a new Subtype = Install codeunit needs a change of
//   check-install-triggers.py). The subscribers record what they see into "LT RL Install Ui Seed" (per company) and "LT RL Install Ui Seed Db"
//   (per database); the test codeunit reads the rows back. Writes are `if Insert() then;` (the first call wins), calls that may raise run in
//   TryFunctions, so the install never fails. A plain Message cannot raise: in a TryFunction it ends 'ok' (CmInstallLeads.al:59).
// BC versions: 27 - 29

table 88200 "LT RL Install Ui Seed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[30]) { }
        field(2; Txt; Text[2048]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 88201 "LT RL Install Ui Seed Db"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Code; Code[30]) { }
        field(2; Txt; Text[2048]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 88202 "LT RL Install Ui Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        Dlg: Dialog;
    begin
        Add('GUIALLOWED', Format(GuiAllowed()));
        Add('CLIENTTYPE', Format(CurrentClientType()));
        Add('WORKDATE IS TODAY', Format(WorkDate() = Today()));
        Add('WORKDATE IS 0D', Format(WorkDate() = 0D));
        // The reporter's shape: a write, then a plain Message, then more code.
        Add('BEFORE MESSAGE', 'reached');
        ClearLastError();
        Message('LT RL install message %1', 1);
        Add('AFTER MESSAGE', 'reached');
        Add('LAST ERROR AFTER MESSAGE', GetLastErrorText());
        Message('LT RL install message two');
        Add('AFTER SECOND MESSAGE', 'reached');
        // The guarded shape: the branch is not taken when GuiAllowed() is false.
        if GuiAllowed() then
            Add('GUARDED BRANCH', 'taken')
        else
            Add('GUARDED BRANCH', 'skipped');
        Add('STRMENU', Outcome(TryStrMenu()));
        Add('DIALOG OPEN', Outcome(TryDialogOpen(Dlg)));
        Add('DIALOG UPDATE', Outcome(TryDialogUpdate(Dlg)));
        Add('DIALOG CLOSE', Outcome(TryDialogClose(Dlg)));
        Add('PAGE.RUN', Outcome(TryPageRun()));
        Add('HYPERLINK', Outcome(TryHyperlink()));
        Add('NOTIFICATION.SEND', Outcome(TryNotificationSend()));
        Add('ERROR IN TRY', Outcome(TryError()));
        Add('END', 'reached');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    begin
        AddDb('GUIALLOWED', Format(GuiAllowed()));
        AddDb('WORKDATE IS TODAY', Format(WorkDate() = Today()));
        Message('LT RL install message per database');
        AddDb('AFTER MESSAGE', 'reached');
    end;

    local procedure Outcome(Ok: Boolean): Text
    var
        Result: Text;
    begin
        if Ok then
            Result := 'ok'
        else
            Result := 'error: ' + GetLastErrorText() + ' | code: ' + GetLastErrorCode();
        ClearLastError();
        exit(CopyStr(Result, 1, 2048));
    end;

    [TryFunction]
    local procedure TryStrMenu()
    begin
        if StrMenu('LT RL one,LT RL two', 2, 'LT RL install strmenu') = 0 then;
    end;

    [TryFunction]
    local procedure TryDialogOpen(var Dlg: Dialog)
    begin
        Dlg.Open('LT RL install dialog #1####');
    end;

    [TryFunction]
    local procedure TryDialogUpdate(var Dlg: Dialog)
    begin
        Dlg.Update(1, 'LT RL');
    end;

    [TryFunction]
    local procedure TryDialogClose(var Dlg: Dialog)
    begin
        Dlg.Close();
    end;

    [TryFunction]
    local procedure TryPageRun()
    begin
        Page.Run(Page::"LT RL Install Ui Page");
    end;

    [TryFunction]
    local procedure TryHyperlink()
    begin
        Hyperlink('https://example.com/lt-rl-install');
    end;

    [TryFunction]
    local procedure TryNotificationSend()
    var
        N: Notification;
    begin
        N.Message('LT RL install notification');
        N.Send();
    end;

    [TryFunction]
    local procedure TryError()
    begin
        Error('LT RL install error in try');
    end;

    local procedure Add(Code: Code[30]; Txt: Text)
    var
        Seed: Record "LT RL Install Ui Seed";
    begin
        Seed.Code := Code;
        Seed.Txt := CopyStr(Txt, 1, MaxStrLen(Seed.Txt));
        if Seed.Insert() then;
    end;

    local procedure AddDb(Code: Code[30]; Txt: Text)
    var
        Seed: Record "LT RL Install Ui Seed Db";
    begin
        Seed.Code := Code;
        Seed.Txt := CopyStr(Txt, 1, MaxStrLen(Seed.Txt));
        if Seed.Insert() then;
    end;
}

page 88203 "LT RL Install Ui Page"
{
    PageType = Card;
    SourceTable = "LT RL Install Ui Seed";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
        }
    }
}

codeunit 88204 "LT RL Install Ui Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure InstallSubscriber_PlainMessageAndOtherUi()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('GuiAllowed', Seed('GUIALLOWED'));
        Observer.Observe('CurrentClientType', Seed('CLIENTTYPE'));
        Observer.Observe('WorkDate = Today', Seed('WORKDATE IS TODAY'));
        Observer.Observe('WorkDate = 0D', Seed('WORKDATE IS 0D'));
        Observer.Observe('before Message', Seed('BEFORE MESSAGE'));
        Observer.Observe('after Message', Seed('AFTER MESSAGE'));
        Observer.Observe('last error after Message', Seed('LAST ERROR AFTER MESSAGE'));
        Observer.Observe('after second Message', Seed('AFTER SECOND MESSAGE'));
        Observer.Observe('if GuiAllowed() branch', Seed('GUARDED BRANCH'));
        Observer.Observe('StrMenu', Seed('STRMENU'));
        Observer.Observe('Dialog.Open', Seed('DIALOG OPEN'));
        Observer.Observe('Dialog.Update', Seed('DIALOG UPDATE'));
        Observer.Observe('Dialog.Close', Seed('DIALOG CLOSE'));
        Observer.Observe('Page.Run', Seed('PAGE.RUN'));
        Observer.Observe('Hyperlink', Seed('HYPERLINK'));
        Observer.Observe('Notification.Send', Seed('NOTIFICATION.SEND'));
        Observer.Observe('Error in try', Seed('ERROR IN TRY'));
        Observer.Observe('end', Seed('END'));
        // Values of the CI legs 27.5, 28.5 and 29.0 (Linux), the same on all three. 'last error after Message': ClearLastError() runs just before the Message.
        Observer.Expect('GuiAllowed', 'No');
        Observer.Expect('CurrentClientType', 'SOAP');
        Observer.Expect('WorkDate = Today', 'Yes');
        Observer.Expect('WorkDate = 0D', 'No');
        Observer.Expect('before Message', 'reached');
        Observer.Expect('after Message', 'reached');
        Observer.Expect('last error after Message', '');
        Observer.Expect('after second Message', 'reached');
        Observer.Expect('if GuiAllowed() branch', 'skipped');
        Observer.Expect('StrMenu', 'error: Microsoft Dynamics 365 Business Central Data Services attempted to issue a client callback to show a selection menu: LT RL install strmenu (CodeUnit 88202 LT RL Install Ui Subs). Client callbacks are not supported on Microsoft Dynamics 365 Business Central Data Services. | code: CallbackNotAllowed');
        Observer.Expect('Dialog.Open', 'ok');
        Observer.Expect('Dialog.Update', 'ok');
        Observer.Expect('Dialog.Close', 'ok');
        Observer.Expect('Page.Run', 'error: Microsoft Dynamics 365 Business Central Data Services attempted to issue a client callback to run page 88203 LT RL Install Ui Page. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Data Services. | code: CallbackNotAllowed');
        Observer.Expect('Hyperlink', 'ok');
        Observer.Expect('Notification.Send', 'ok');
        Observer.Expect('Error in try', 'error: LT RL install error in try | code: Dialog');
        Observer.Expect('end', 'reached');
        Observer.Verify();
    end;

    [Test]
    procedure InstallSubscriberPerDatabase_PlainMessage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('GuiAllowed', SeedDb('GUIALLOWED'));
        Observer.Observe('WorkDate = Today', SeedDb('WORKDATE IS TODAY'));
        Observer.Observe('after Message', SeedDb('AFTER MESSAGE'));
        Observer.Expect('GuiAllowed', 'No');
        Observer.Expect('WorkDate = Today', 'Yes');
        Observer.Expect('after Message', 'reached');
        Observer.Verify();
    end;

    local procedure Seed(Code: Code[30]): Text
    var
        S: Record "LT RL Install Ui Seed";
    begin
        if not S.Get(Code) then
            exit('<missing>');
        exit(S.Txt);
    end;

    local procedure SeedDb(Code: Code[30]): Text
    var
        S: Record "LT RL Install Ui Seed Db";
    begin
        if not S.Get(Code) then
            exit('<missing>');
        exit(S.Txt);
    end;
}
