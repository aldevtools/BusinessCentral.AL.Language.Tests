// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//
// Dialog Open/Update/Close in a test (no UI), Session / Database relations only.
// Fixtures used: Probe Observer (69160); self-contained table 73035, codeunit 73034
// BC versions: 29 (27 and 28 by CI)

table 73035 "LT EnT Session Rec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Integer) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 73034 "LT EnT Dialog Session"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Dialog_OpenUpdateClose()
    var
        Observer: Codeunit "Probe Observer";
        D: Dialog;
    begin
        D.Open('Working #1###### and #2######');
        Observer.Observe('open', 'ok');
        D.Update(1, 'abc');
        D.Update(2, 5);
        Observer.Observe('update', 'ok');
        D.Update();
        Observer.Observe('update all', 'ok');
        D.Close();
        Observer.Observe('close', 'ok');
        Observer.Expect('open', 'ok');
        Observer.Expect('update', 'ok');
        Observer.Expect('update all', 'ok');
        Observer.Expect('close', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Dialog_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Dialog;
    begin
        D.Open('Value #1######');
        asserterror D.Update(5, 'x');
        Observer.ObserveError('update bad index');
        asserterror D.Update(0, 'x');
        Observer.ObserveError('update zero');
        D.Close();
        asserterror D.Close();
        Observer.ObserveError('af54');
        Observer.Observe('close twice', 'ok');
        Observer.Expect('update bad index|text', 'No parameter with index ''5'' was found in the format string ''Value %s''.');
        Observer.Expect('update bad index|code', 'FormatStringParameterNotFound');
        Observer.Expect('update zero|text', 'No parameter with index ''0'' was found in the format string ''Value %s''.');
        Observer.Expect('update zero|code', 'FormatStringParameterNotFound');
        Observer.Expect('af54|text', 'The operation failed because the dialog box is not open.');
        Observer.Expect('af54|code', 'Dialog');
        Observer.Expect('close twice', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Dialog_UpdateWithoutOpen()
    var
        Observer: Codeunit "Probe Observer";
        D: Dialog;
    begin
        asserterror D.Update(1, 'x');
        Observer.ObserveError('update unopened');
        asserterror D.Close();
        Observer.ObserveError('af68');
        Observer.Observe('close unopened', 'ok');
        Observer.Expect('update unopened|text', 'The operation failed because the dialog box is not open.');
        Observer.Expect('update unopened|code', 'Dialog');
        Observer.Expect('af68|text', 'The operation failed because the dialog box is not open.');
        Observer.Expect('af68|code', 'Dialog');
        Observer.Expect('close unopened', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Dialog_HideSubsequent()
    var
        Observer: Codeunit "Probe Observer";
        D: Dialog;
        Prev: Boolean;
    begin
        Prev := D.HideSubsequentDialogs(true);
        Observer.Observe('previous', Format(Prev));
        Observer.Observe('now', Format(D.HideSubsequentDialogs(false)));
        Observer.Observe('restored', Format(D.HideSubsequentDialogs(Prev)));
        D.HideSubsequentDialogs(false);
        Observer.Expect('previous', 'Yes');
        Observer.Expect('now', 'No');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    // Writer UJ (al-runner issue 6178, Microsoft's retention policy code calls HideSubsequentDialogs before it opens dialogs):
    // Open / Update / Close after HideSubsequentDialogs(true) and (false), and the errors after it.
    [Test]
    procedure UJ_Dialog_HideSubsequent_OpenUpdateClose()
    var
        Observer: Codeunit "Probe Observer";
        D: Dialog;
        Prev: Boolean;
    begin
        Prev := D.HideSubsequentDialogs(true);
        D.Open('Working #1###### and #2######');
        D.Update(1, 'abc');
        D.Update(2, 5);
        D.Update();
        D.Close();
        Observer.Observe('hidden open update close', 'ok');
        D.HideSubsequentDialogs(false);
        D.Open('Working #1######');
        D.Update(1, 'def');
        D.Close();
        Observer.Observe('shown open update close', 'ok');
        D.HideSubsequentDialogs(true);
        D.Open('Value #1######');
        asserterror D.Update(5, 'x');
        Observer.ObserveError('hidden update bad index');
        D.Close();
        asserterror D.Close();
        Observer.ObserveError('hidden close twice');
        D.HideSubsequentDialogs(Prev);
        Observer.Observe('after restore', Format(D.HideSubsequentDialogs(Prev)));
        Observer.Finish();
    end;

    [Test]
    procedure UJ_Dialog_HideSubsequent_OpenedBefore()
    var
        Observer: Codeunit "Probe Observer";
        D: Dialog;
        Other: Dialog;
    begin
        D.Open('Before #1######');
        Other.HideSubsequentDialogs(true);
        D.Update(1, 'still open');
        Observer.Observe('update of a dialog opened before', 'ok');
        Other.Open('After #1######');
        Other.Update(1, 'x');
        Other.Close();
        D.Close();
        Other.HideSubsequentDialogs(false);
        Observer.Observe('closed both', 'ok');
        Observer.Finish();
    end;

    [Test]
    procedure Session_Relations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('database company', Format(Database.CompanyName() = CompanyName()));
        Observer.Observe('database session', Format(Database.SessionId() = SessionId()));
        Observer.Observe('session positive', Format(SessionId() > 0));
        Observer.Observe('userid nonempty', Format(UserId() <> ''));
        Observer.Observe('serviceinstance positive', Format(ServiceInstanceId() > 0));
        Observer.Observe('workdate relation', Format(WorkDate() >= 0D));
        Observer.Expect('database company', 'Yes');
        Observer.Expect('database session', 'Yes');
        Observer.Expect('session positive', 'Yes');
        Observer.Expect('userid nonempty', 'Yes');
        Observer.Expect('serviceinstance positive', 'Yes');
        Observer.Expect('workdate relation', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Database_WriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT EnT Session Rec";
    begin
        Rec.DeleteAll();
        Observer.Observe('before', Format(Database.IsInWriteTransaction()));
        Rec."No." := 1;
        Rec.Insert();
        Observer.Observe('after insert', Format(Database.IsInWriteTransaction()));
        Rec.DeleteAll();
        Observer.Expect('before', 'Yes');
        Observer.Expect('after insert', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Session_LogMessage_NoError()
    var
        Observer: Codeunit "Probe Observer";
        Dim: Dictionary of [Text, Text];
    begin
        Dim.Add('k', 'v');
        Session.LogMessage('0000EN1', 'message', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dim);
        Observer.Observe('logged', 'ok');
        Session.LogMessage('0000EN2', '', Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::All, 'k', 'v');
        Observer.Observe('logged empty', 'ok');
        Observer.Expect('logged', 'ok');
        Observer.Expect('logged empty', 'ok');
        Observer.Verify();
    end;
}
