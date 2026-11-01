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

// Writer Y64 (2026-11-01, al-runner issues 6643 and 6649): what install code sees of AllObj / AllObjWithCaption rows of type TableData of a Base
// Application table (5050 Contact), the reporter's setup shape (a field whose OnValidate reads AllObjWithCaption, validated in
// OnInstallAppPerCompany), and NavApp.LoadPackageData of an own table (the corpus app ships no package data) per company and of a
// DataPerCompany = false table per database. Rows go only `if Insert() then;` into DataPerCompany = false table 93330 and the per-company setup
// table 93331; a failed TryFunction stops the install transaction (the next Commit raises 'An error occurred and the transaction is stopped.'), so
// the Validate and LoadPackageData run through `if Codeunit.Run` after a Commit and the reads use `if Get`.
// Tests: Y64InstallLeads.al (codeunit 93333).
table 93330 "LT Y64 Install Seen"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Company"; Text[30]) { }
        field(2; Code; Code[30]) { }
        field(3; Txt; Text[2048]) { }
    }

    keys { key(PK; "Company", Code) { Clustered = true; } }
}

table 93331 "LT Y64 Install Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            TableRelation = AllObj."Object ID" where("Object Type" = const(TableData));

            trigger OnValidate()
            begin
                AllObject.Get(AllObject."Object Type"::TableData, "Table ID");
                TableName := CopyStr(AllObject."Object Caption", 1, MaxStrLen(TableName));
            end;
        }
        field(2; TableName; Text[30]) { }
    }

    keys { key(PK; "Table ID") { Clustered = true; } }

    var
        AllObject: Record AllObjWithCaption;
}

table 93332 "LT Y64 Install Pkg Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 93336 "LT Y64 Install Pkg Db Row"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93337 "LT Y64 Install Loader"
{
    trigger OnRun()
    var
        Row: Record "LT Y64 Install Pkg Row";
    begin
        if not Row.IsEmpty() then
            exit;
        NavApp.LoadPackageData(Database::"LT Y64 Install Pkg Row");
    end;
}

codeunit 93338 "LT Y64 Install Loader Db"
{
    trigger OnRun()
    begin
        NavApp.LoadPackageData(Database::"LT Y64 Install Pkg Db Row");
    end;
}

codeunit 93339 "LT Y64 Install Validator"
{
    TableNo = "LT Y64 Install Setup";

    trigger OnRun()
    begin
        Rec.Validate("Table ID", Database::Contact);
    end;
}

codeunit 93329 "LT Y64 Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Row: Record "LT Y64 Install Pkg Db Row";
    begin
        See('<db>', 'CONTEXT', Format(GetExecutionContext()));
        See('<db>', 'ALLOBJCAP TABLEDATA 5050', AllObjCaption(5050));
        See('<db>', 'ALLOBJ TABLEDATA 5050', AllObjRow(5050));
        Commit();
        if Codeunit.Run(Codeunit::"LT Y64 Install Loader Db") then
            See('<db>', 'LOAD DB TABLE', 'ok|rows=' + Format(Row.Count()))
        else
            See('<db>', 'LOAD DB TABLE', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    trigger OnInstallAppPerCompany()
    var
        MySetup: Record "LT Y64 Install Setup";
        Row: Record "LT Y64 Install Pkg Row";
        Co: Text[30];
    begin
        Co := CopyStr(CompanyName(), 1, 30);
        See(Co, 'CONTEXT', Format(GetExecutionContext()));
        See(Co, 'ALLOBJCAP TABLEDATA 5050', AllObjCaption(5050));
        See(Co, 'ALLOBJ TABLEDATA 5050', AllObjRow(5050));
        See(Co, 'ALLOBJCAP TABLE 5050', AllObjCaptionTable(5050));
        See(Co, 'ALLOBJCAP TABLEDATA OWN', AllObjCaption(Database::"LT Y64 Install Setup"));
        See(Co, 'ALLOBJCAP TABLEDATA 18', AllObjCaption(18));
        Commit();
        MySetup.Init();
        if Codeunit.Run(Codeunit::"LT Y64 Install Validator", MySetup) then
            See(Co, 'SETUP VALIDATE', 'ok|' + MySetup.TableName)
        else
            See(Co, 'SETUP VALIDATE', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        if MySetup.Insert() then;
        Commit();
        if Codeunit.Run(Codeunit::"LT Y64 Install Loader") then
            See(Co, 'LOAD OWN TABLE', 'ok|rows=' + Format(Row.Count()))
        else
            See(Co, 'LOAD OWN TABLE', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure AllObjCaption(Id: Integer): Text
    var
        Caption: Record AllObjWithCaption;
    begin
        if Caption.Get(Caption."Object Type"::TableData, Id) then
            exit('Yes|' + Caption."Object Name" + '|' + Caption."Object Caption");
        exit('No');
    end;

    local procedure AllObjCaptionTable(Id: Integer): Text
    var
        Caption: Record AllObjWithCaption;
    begin
        if Caption.Get(Caption."Object Type"::Table, Id) then
            exit('Yes|' + Caption."Object Name" + '|' + Caption."Object Caption");
        exit('No');
    end;

    local procedure AllObjRow(Id: Integer): Text
    var
        AllObjRec: Record AllObj;
    begin
        if AllObjRec.Get(AllObjRec."Object Type"::TableData, Id) then
            exit('Yes|' + AllObjRec."Object Name");
        exit('No');
    end;

    local procedure See(Co: Text[30]; Code: Code[30]; Txt: Text)
    var
        Seen: Record "LT Y64 Install Seen";
    begin
        Seen."Company" := Co;
        Seen.Code := Code;
        Seen.Txt := CopyStr(Txt, 1, MaxStrLen(Seen.Txt));
        if Seen.Insert() then;
    end;
}
