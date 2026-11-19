// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-caption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); table 75410, page 75419, codeunit 75413 (tests)
// Probe: the page of al-runner issue 8193 (a List that declares its own public Caption(): Text, reads CurrPage.Caption in OnOpenPage and assigns CurrPage.Caption := Caption() + the stored text in OnAfterGetCurrRecord), the shape of Base Application page 5911.
// Read: CaptionRead (CurrPage.Caption) and CaptionReadParens (CurrPage.Caption()) are stored in OnOpenPage; the test reads TestPage.Caption after
// the open and after First.
// BC versions: OBSERVATION FORM (not yet measured)

table 75410 "CPC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// local object: the page of al-runner issue 8193 with its caption observed.
page 75419 "CPC Own Caption List"
{
    PageType = List;
    SourceTable = "CPC Row";
    Caption = 'Static';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CodeField; Rec."Code") { ApplicationArea = All; }
                field(CaptionRead; CaptionRead) { ApplicationArea = All; }
                field(CaptionReadParens; CaptionReadParens) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CaptionRead := CurrPage.Caption;
        CaptionReadParens := CurrPage.Caption();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := Caption() + CaptionRead;
    end;

    var
        CaptionRead: Text;
        CaptionReadParens: Text;

    procedure Caption(): Text
    begin
        exit('X ');
    end;
}

codeunit 75413 "CPC Own Caption List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OwnCaptionList_ReadThenAssignInAfterGetCurrRecord_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPC Row";
        P: TestPage "CPC Own Caption List";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Insert();
        P.OpenView();
        Observer.Observe('open: TestPage.Caption', P.Caption());
        Observer.Observe('open: CaptionRead', P.CaptionRead.Value());
        Observer.Observe('open: CaptionReadParens', P.CaptionReadParens.Value());
        P.First();
        Observer.Observe('First: TestPage.Caption', P.Caption());
        P.Close();
        Observer.Finish();
    end;
}
