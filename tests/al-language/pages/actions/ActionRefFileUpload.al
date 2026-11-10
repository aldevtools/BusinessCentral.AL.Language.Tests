// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-fileuploadaction-control
// Scope: in-scope (Cloud). TestPage only.
// local object: the fileuploadaction and the actionref that promotes it are what is under test
// Fixtures used: own page 63460 (no test codeunit: see the comment at the end of the file)
// Probe (al-runner issue 3990): a TestPage has no member for a fileuploadaction (pinned: testpage/TestPageLabelControlContracts.al, AL0132), but an
//   actionref that promotes one compiles as a TestPage member. What Invoke() of that actionref does: whether the OnAction(Files) trigger runs
//   and with how many files, or the error text and code; and what Visible() and Enabled() answer. An actionref of a plain action is the control.
//   Answer: Invoke() ends the test with an uncatchable CLR exception (comment at the end of the file).
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

// The test codeunit 63462 "PNL ActionRef File Upload" was removed. Measured on BC 27.5, 28.5 and 29.0 (corpus CI run 42824219882, tests
//   ActionRefOfFileUploadAction_OpenView_Invoke and ActionRefOfFileUploadAction_OpenEdit_Invoke): TestPage.UploadRef.Invoke() on the
//   actionref of the fileuploadaction above, from a page opened with OpenView or OpenEdit, ends the test with
//   "Unexpected CLR exception thrown.: System.ArgumentException: Cannot get parameters from state as it is not a Dictionary"
//   (thrown in Microsoft.Dynamics.Nav.Client.Actions.InvokePageTriggerFileUploadAction.InvokeCore). The call was inside a TryFunction and the
//   TryFunction did not catch it, so no test can assert it; the OnAction(Files) trigger result was never reached. Before that call, in the
//   same tests, Visible() and Enabled() of both actionrefs and Invoke() of the plain action's actionref ran without an error (their values
//   were not measured).
