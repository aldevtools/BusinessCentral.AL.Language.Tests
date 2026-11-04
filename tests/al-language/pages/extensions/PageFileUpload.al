// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: page 72346, codeunit 72347
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72346 "LT P123 Upload Card"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'P123 upload card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Dummy; Dummy) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(UploadMany)
            {
                ApplicationArea = All;
                Caption = 'Upload many';
                AllowMultipleFiles = true;
                AllowedFileExtensions = '.txt', '.csv';

                trigger OnAction(Files: List of [FileUpload])
                begin
                    Dummy := Format(Files.Count());
                end;
            }
            fileuploadaction(UploadOne)
            {
                ApplicationArea = All;
                Caption = 'Upload one';
                AllowMultipleFiles = false;
                AllowedFileExtensions = '.json';

                trigger OnAction(Files: List of [FileUpload])
                begin
                    Dummy := Format(Files.Count());
                end;
            }
        }
    }

    var
        Dummy: Text;
}

codeunit 72347 "LT P123 Upload Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_FileUploadActionDeclaredOnly()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P123 Upload Card";
    begin
        P.OpenView();
        Observer.Observe('caption', P.Caption());
        Observer.Observe('dummy', P.Dummy.Value());
        Observer.Expect('caption', 'P123 upload card');
        Observer.Expect('dummy', '');
        Observer.Verify();
    end;
}
