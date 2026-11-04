// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Permissions Mock (Microsoft)
// Probe (corpus issue 663 items 8, 10, 13 and 15):
// - item 8: Format and FieldRef give the plain value of a table field with MaskType = Concealed.
// - item 10: Width on an XMLport fieldattribute (and fieldelement) of an XML port: what an export writes for a value longer than Width.
// - item 13: EntityName and EntitySetName on a system part compile and the page opens. SubPageLink and SubPageView on a system part do not compile
//   (AL0171, must-not-compile case 1865); a TestPage cannot reach a system part (AL0132, case 1864).
// - item 15: Permissions on a request page, for a user whose permission set has indirect insert only: the request page's OnOpenPage and
//   OnQueryClosePage may insert, the report's own OnPreReport may not (the request page inserts stay). Without the property the insert in
//   OnQueryClosePage is denied and comes back as a message.
// Object ids 86090-86099.

table 86090 "LT DH Props Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Secret; Text[30]) { MaskType = Concealed; }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 86091 "LT DH Props SysPart Card"
{
    PageType = Card;
    SourceTable = "LT DH Props Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = All;
                EntityName = 'dhLink';
                EntitySetName = 'dhLinks';
            }
        }
    }
}

xmlport 86092 "LT DH Props Width Xml"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT DH Props Row")
            {
                fieldattribute(Short; Row.Name) { Width = 3; }
                fieldattribute(Wide; Row.Name) { Width = 20; }
                fieldelement(Element; Row.Name) { Width = 3; }
            }
        }
    }
}

table 86093 "LT DH Props Rp Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

permissionset 86094 "LT DH Props Rp Set"
{
    Assignable = true;
    Permissions = tabledata "LT DH Props Rp Target" = i;
}

report 86095 "LT DH Props Rp With Perms"
{
    ProcessingOnly = true;

    requestpage
    {
        Permissions = tabledata "LT DH Props Rp Target" = I;

        trigger OnOpenPage()
        var
            Target: Record "LT DH Props Rp Target";
        begin
            Target.Id := 1;
            Target.Insert();
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            Target: Record "LT DH Props Rp Target";
        begin
            Target.Id := 4;
            Target.Insert();
            exit(true);
        end;
    }

    trigger OnPreReport()
    var
        Target: Record "LT DH Props Rp Target";
    begin
        Target.Id := 2;
        Target.Insert();
    end;
}

report 86096 "LT DH Props Rp No Perms"
{
    ProcessingOnly = true;

    requestpage
    {
        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            Target: Record "LT DH Props Rp Target";
        begin
            Target.Id := 3;
            Target.Insert();
            exit(true);
        end;
    }
}

codeunit 86097 "LT DH Other Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SetTok: Label 'LT DH Props Rp Set', Locked = true;

    [Test]
    procedure MaskTypeConcealed_FormatAndFieldRef_PlainValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DH Props Row";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Secret := 'pw-1';
        Row.Insert();
        Row.Get(1);
        Observer.Observe('format', Format(Row.Secret));
        Observer.Observe('format_0_9', Format(Row.Secret, 0, 9));
        RecRef.GetTable(Row);
        Observer.Observe('fieldref_value', Format(RecRef.Field(2).Value));
        Observer.Observe('strlen', Format(StrLen(Row.Secret)));
        Observer.Expect('format', 'pw-1');
        Observer.Expect('format_0_9', 'pw-1');
        Observer.Expect('fieldref_value', 'pw-1');
        Observer.Expect('strlen', '4');
        Observer.Verify();
    end;

    [Test]
    procedure WidthXmlAttribute_Export_LongValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DH Props Row";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'abcdefgh';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'ab';
        Row.Insert();
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Xmlport::"LT DH Props Width Xml", OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        Observer.Observe('export', Result);
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Row Short="abcdefgh" Wide="abcdefgh">|    <Element>abcdefgh</Element>|  </Row>|  <Row Short="ab" Wide="ab">|    <Element>ab</Element>|  </Row>|</Root>|');
        Observer.Verify();
    end;

    [Test]
    procedure SystemPartEntityName_Page_Opens()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DH Props Row";
        Pg: TestPage "LT DH Props SysPart Card";
    begin
        Row.DeleteAll();
        Row.Id := 7;
        Row.Insert();
        Pg.OpenView();
        Observer.Observe('id', Pg.Id.Value);
        Pg.Close();
        Observer.Expect('id', '7');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestOk')]
    procedure RequestPagePermissions_WithPermissions_IndirectOnlyUser()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('run', RunUnderMock(Report::"LT DH Props Rp With Perms"));
        Observer.Observe('target_ids', TargetIds());
        Observer.Expect('run', 'error: Sorry, the current permissions prevented the action. (TableData 86093 LT DH Props Rp Target Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Expect('target_ids', '1;4;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestOkNoPerms')]
    procedure RequestPagePermissions_WithoutPermissions_IndirectOnlyUser()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('run', RunUnderMock(Report::"LT DH Props Rp No Perms"));
        Observer.Observe('target_ids', TargetIds());
        Observer.Expect('run', 'error: Unhandled UI: Message Sorry, the current permissions prevented the action. (TableData 86093 LT DH Props Rp Target Insert: AL Language Coverage Tests) | TestWrapped:MissingUIHandler');
        Observer.Expect('target_ids', '');
        Observer.Verify();
    end;

    local procedure RunUnderMock(ReportId: Integer) Result: Text
    var
        Mock: Codeunit "Permissions Mock";
        Target: Record "LT DH Props Rp Target";
        WasStarted: Boolean;
    begin
        Target.DeleteAll();
        Commit();
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
        Mock.Set(SetTok);
        Result := RunReport(ReportId);
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;

    local procedure TargetIds() Ids: Text
    var
        Target: Record "LT DH Props Rp Target";
    begin
        if Target.FindSet() then
            repeat
                Ids += Format(Target.Id) + ';';
            until Target.Next() = 0;
    end;

    local procedure RunReport(ReportId: Integer): Text
    var
        Runner: Codeunit "LT DH Props Rp Runner";
    begin
        Runner.SetReport(ReportId);
        if Runner.Run() then
            exit('ok');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    [RequestPageHandler]
    procedure RequestOk(var RP: TestRequestPage "LT DH Props Rp With Perms")
    begin
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RequestOkNoPerms(var RP: TestRequestPage "LT DH Props Rp No Perms")
    begin
        RP.OK().Invoke();
    end;
}

codeunit 86098 "LT DH Props Rp Runner"
{
    var
        ReportToRun: Integer;

    procedure SetReport(ReportId: Integer)
    begin
        ReportToRun := ReportId;
    end;

    trigger OnRun()
    begin
        Report.Run(ReportToRun);
    end;
}
