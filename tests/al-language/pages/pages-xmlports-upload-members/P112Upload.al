// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-fileuploadaction-control
// Scope: in-scope
// Fixtures used: own table 71871, page 71872, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a page with a fileuploadaction whose OnAction trigger takes the uploaded files: the page opens through a TestPage and its plain action still runs. A TestPage has no member for a fileuploadaction (see misc/lt-probes-needed-7/PnGControlKinds.al), so the OnAction trigger itself cannot be invoked by a test; it is only declared and compiled here.
// BC versions: 29 (27 and 28 by CI)

table 71871 "LT P112 Up Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[100]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 71872 "LT P112 Upload"
{
    PageType = Card;
    SourceTable = "LT P112 Up Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(InfoCtl; Rec.Info) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(UploadIt)
            {
                ApplicationArea = All;
                Caption = 'Upload';
                AllowMultipleFiles = true;
                AllowedFileExtensions = '.txt', '.csv';

                trigger OnAction(Files: List of [FileUpload])
                var
                    Entry: Record "LT P112 Up Row";
                    F: FileUpload;
                begin
                    Entry.Id := 100;
                    Entry.Info := 'files=' + Format(Files.Count());
                    foreach F in Files do
                        Entry.Info := CopyStr(Entry.Info + ' ' + F.FileName(), 1, MaxStrLen(Entry.Info));
                    if not Entry.Insert() then
                        Entry.Modify();
                end;
            }
            action(PlainAct)
            {
                ApplicationArea = All;
                Caption = 'Plain';

                trigger OnAction()
                var
                    Entry: Record "LT P112 Up Row";
                begin
                    Entry.Id := 200;
                    Entry.Info := 'plain ran';
                    if not Entry.Insert() then
                        Entry.Modify();
                end;
            }
        }
    }
}

codeunit 71873 "LT P112 Upload Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P112_Upload_Page_Opens_PlainAction_Runs()
    var
        Observer: Codeunit "Probe Observer";
        Entry: Record "LT P112 Up Row";
        Card: TestPage "LT P112 Upload";
    begin
        Entry.DeleteAll();
        Entry.Id := 1;
        Entry.Insert();
        Card.OpenEdit();
        Card.GoToKey(1);
        Card.PlainAct.Invoke();
        Card.Close();
        Observer.Observe('plain row', Format(Entry.Get(200)));
        Observer.Observe('upload row', Format(Entry.Get(100)));
        Observer.Expect('plain row', 'Yes');
        Observer.Expect('upload row', 'No');
        Observer.Verify();
    end;
}
