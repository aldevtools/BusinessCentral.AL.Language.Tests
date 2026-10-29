// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures for CmInstallLeads.al (codeunit 84840): corpus issue 669 (odd AL behavior leads, part D), items 41, 42, 43.
// The install codeunit 84838 records what it sees into "LT CM Install Seed" (per company) and "LT CM Install Seed Db" (per database);
// the test codeunit reads the rows back. Calls that may raise an error run inside try functions, so the install never fails.

table 84837 "LT CM Install Seed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[30]) { }
        field(2; Txt; Text[2048]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 84841 "LT CM Install Seed Db"
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

codeunit 84838 "LT CM Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Info: ModuleInfo;
        Seed: Record "LT CM Install Seed Db";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Seed.DeleteAll();
        AddDb('DATAVERSION', Format(Info.DataVersion));
        AddDb('APPVERSION', Format(Info.AppVersion));
        AddDb('ALLOBJ OWN', Format(CountOwnObjects(Info)));
    end;

    trigger OnInstallAppPerCompany()
    var
        Info: ModuleInfo;
        Seed: Record "LT CM Install Seed";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Seed.DeleteAll();
        // Item 43
        Add('DATAVERSION', Format(Info.DataVersion));
        Add('APPVERSION', Format(Info.AppVersion));
        // Item 42
        Add('ALLOBJ OWN', Format(CountOwnObjects(Info)));
        // Item 41: a write transaction is open (the rows above), then each call runs inside its own try function.
        Add('GUIALLOWED', Format(GuiAllowed()));
        Add('IF CODEUNIT.RUN', Outcome(TryIfCodeunitRun()));
        Add('CODEUNIT.RUN STATEMENT', Outcome(TryCodeunitRunStatement()));
        Add('CONFIRM', Outcome(TryConfirm()));
        Add('PAGE.RUNMODAL', Outcome(TryPageRunModal()));
        Add('MESSAGE', Outcome(TryMessage()));
        Add('COMMIT', Outcome(TryCommit()));
        Add('AFTER COMMIT', 'reached');
    end;

    local procedure CountOwnObjects(Info: ModuleInfo): Integer
    var
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.SetRange("App Package ID", Info.PackageId);
        exit(AllObj.Count());
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(CopyStr('error: ' + GetLastErrorText() + ' | code: ' + GetLastErrorCode(), 1, 2048));
    end;

    [TryFunction]
    local procedure TryIfCodeunitRun()
    begin
        if Codeunit.Run(Codeunit::"LT CM Install Noop") then;
    end;

    [TryFunction]
    local procedure TryCodeunitRunStatement()
    begin
        Codeunit.Run(Codeunit::"LT CM Install Noop");
    end;

    [TryFunction]
    local procedure TryConfirm()
    begin
        if Confirm('LT CM install confirm') then;
    end;

    [TryFunction]
    local procedure TryPageRunModal()
    begin
        Page.RunModal(Page::"LT CM Install Page");
    end;

    [TryFunction]
    local procedure TryMessage()
    begin
        Message('LT CM install message');
    end;

    [TryFunction]
    local procedure TryCommit()
    begin
        Commit();
    end;

    local procedure Add(Code: Code[30]; Txt: Text)
    var
        Seed: Record "LT CM Install Seed";
    begin
        Seed.Code := Code;
        Seed.Txt := CopyStr(Txt, 1, MaxStrLen(Seed.Txt));
        if not Seed.Insert() then
            Seed.Modify();
    end;

    local procedure AddDb(Code: Code[30]; Txt: Text)
    var
        Seed: Record "LT CM Install Seed Db";
    begin
        Seed.Code := Code;
        Seed.Txt := CopyStr(Txt, 1, MaxStrLen(Seed.Txt));
        if not Seed.Insert() then
            Seed.Modify();
    end;
}

codeunit 84839 "LT CM Install Noop"
{
    trigger OnRun()
    begin
    end;
}

page 84842 "LT CM Install Page"
{
    PageType = Card;
    SourceTable = "LT CM Install Seed";

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
        }
    }
}

// Probe UM (ADR-046 Q1): see install/lt-um-install-order/UmInstallOrder.al. Writes only `if Insert() then;` into a DataPerCompany = false log.
codeunit 90434 "LT UM Ay Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Ay', 'OnInstallAppPerCompany');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('Ay', 'OnInstallAppPerDatabase');
    end;
}
