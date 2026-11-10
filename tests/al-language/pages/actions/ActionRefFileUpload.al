// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-fileuploadaction-control
// Scope: in-scope (Cloud). TestPage only.
// local object: the fileuploadaction and the actionref that promotes it are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own page 63460, test codeunit 63462
// Probe (al-runner issue 3990): a TestPage has no member for a fileuploadaction (pinned: testpage/TestPageLabelControlContracts.al, AL0132), but an
//   actionref that promotes one compiles as a TestPage member. What Invoke() of that actionref does: whether the OnAction(Files) trigger runs
//   and with how many files, or the error text and code; and what Visible() and Enabled() answer. An actionref of a plain action is the control.
// BC versions: 27, 28, 29

page 63460 "PNL FU Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TraceCtl; Trace) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction("Upload Files")
            {
                ApplicationArea = All;
                AllowMultipleFiles = true;

                trigger OnAction(Files: List of [FileUpload])
                begin
                    Trace += 'upload ran with ' + Format(Files.Count()) + ' files;';
                end;
            }
            action(PlainAction)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Trace += 'plain ran;';
                end;
            }
        }
        area(Promoted)
        {
            actionref(UploadRef; "Upload Files") { }
            actionref(PlainRef; PlainAction) { }
        }
    }

    var
        Trace: Text;
}

codeunit 63462 "PNL ActionRef File Upload"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryUploadRef(var P: TestPage "PNL FU Card")
    begin
        P.UploadRef.Invoke();
    end;

    [TryFunction]
    local procedure TryPlainRef(var P: TestPage "PNL FU Card")
    begin
        P.PlainRef.Invoke();
    end;

    local procedure Drive(var P: TestPage "PNL FU Card")
    begin
        Observer.Observe('upload ref', 'visible=' + Format(P.UploadRef.Visible()) + ' enabled=' + Format(P.UploadRef.Enabled()));
        Observer.Observe('plain ref', 'visible=' + Format(P.PlainRef.Visible()) + ' enabled=' + Format(P.PlainRef.Enabled()));
        if TryPlainRef(P) then
            Observer.Observe('plain ref invoke', 'ok')
        else
            Observer.ObserveError('plain ref invoke error');
        Observer.Observe('trace after the plain ref', P.TraceCtl.Value());
        if TryUploadRef(P) then
            Observer.Observe('upload ref invoke', 'ok')
        else
            Observer.ObserveError('upload ref invoke error');
        Observer.Observe('trace after the upload ref', P.TraceCtl.Value());
    end;

    [Test]
    procedure ActionRefOfFileUploadAction_OpenView_Invoke()
    var
        P: TestPage "PNL FU Card";
    begin
        Observer.Discard();
        P.OpenView();
        Drive(P);
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ActionRefOfFileUploadAction_OpenEdit_Invoke()
    var
        P: TestPage "PNL FU Card";
    begin
        Observer.Discard();
        P.OpenEdit();
        Drive(P);
        P.Close();
        Observer.Finish();
    end;
}
