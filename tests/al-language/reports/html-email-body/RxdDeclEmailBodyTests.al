// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); RXD Row, RXD Decl Word and RXD Decl Helper of RxdDeclFixtures.al (80040 - 80042); test codeunit 80044
// Probe (al-runner issue 6924): the e-mail body path for the reporter's report declaration (RXD Decl Word: WordLayout and RDLCLayout,
//   DefaultLayout = Word, no rendering section): Report.SaveAs as Html into a Temp Blob, read back with one InStream.Read, then
//   Email Message.Create(..., HtmlFormatted = true) and GetBody (Email Message Impl. replaces rgba(r,g,b,1) colors by rgb(r, g, b)).
//   The same stored states and temporary selections as RxdDeclLayoutTests.al. Asked: whether Html was produced, which layout's marker the
//   body holds, the counts of 'rgba(' and 'rgb(' and of the static texts rgba(1,2,3,1) and rgb(1, 2, 3) in the body and in GetBody,
//   and whether GetBody equals the body.
// Results (local observation on BC 27.5, 28.5 and 29.0; identical on all three):
//   - Where the Word layout runs (no row, empty-company RDLC row, company Word row; with or without SetTempLayoutSelected('')): Html
//     body with marker word, rgba(1,2,3,1) once and rgb(1, 2, 3) once; GetBody <> body, holds rgb(1, 2, 3) twice and no 'rgba('.
//   - With the temporary GUID tenant selection (every stored state): Html body with marker tenant, rgba(1,2,3,1) once, no 'rgb(';
//     GetBody <> body, holds rgb(1, 2, 3) once and no 'rgba('.
//   - Where the RDLC layout runs (company RDLC row, alone or with the empty-company row, with or without SetTempLayoutSelected('')):
//     SaveAs returns false with ReportUnsupportedFormat, the body is empty, and GetBody = body.
// BC versions: 27 - 29

codeunit 80044 "RXD Decl Email Body Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "RXD Decl Helper";
        ToTxt: Label 'rxd.probe@contoso.com', Locked = true;

    local procedure Setup(State: Integer; Mode: Integer)
    begin
        Helper.Cleanup();
        Helper.Rows(2);
        Helper.StoreState(State);
        if Mode = 1 then
            Helper.InsertTenantLayout();
    end;

    local procedure BodyFacts(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Msg: Codeunit "Email Message";
        Body: Text;
        Got: Text;
        Completed: Boolean;
        Ok: Boolean;
    begin
        Helper.SetTemp(Mode);
        ClearLastError();
        Completed := Helper.TrySave(ReportFormat::Html, TempBlob, Ok);
        Observer.Observe('completed', Format(Completed));
        Observer.Observe('returned', Format(Ok));
        Observer.ObserveError('err');
        Body := Helper.BodyText(TempBlob);
        Observer.Observe('body <> empty', Format(Body <> ''));
        Observer.Observe('body marker', Helper.Markers(Body));
        Observer.Observe('body rgba( count', Format(Helper.CountOf(Body, 'rgba(')));
        Observer.Observe('body rgb( count', Format(Helper.CountOf(Body, 'rgb(')));
        Observer.Observe('body rgba(1,2,3,1)', Format(Helper.CountOf(Body, 'rgba(1,2,3,1)')));
        Observer.Observe('body rgb(1, 2, 3)', Format(Helper.CountOf(Body, 'rgb(1, 2, 3)')));
        Msg.Create(ToTxt, 'RXD subject', Body, true);
        Got := Msg.GetBody();
        Observer.Observe('GetBody = body', Format(Got = Body));
        Observer.Observe('GetBody rgba( count', Format(Helper.CountOf(Got, 'rgba(')));
        Observer.Observe('GetBody rgb( count', Format(Helper.CountOf(Got, 'rgb(')));
        Observer.Observe('GetBody rgba(1,2,3,1)', Format(Helper.CountOf(Got, 'rgba(1,2,3,1)')));
        Observer.Observe('GetBody rgb(1, 2, 3)', Format(Helper.CountOf(Got, 'rgb(1, 2, 3)')));
    end;

    [Test]
    procedure EmailBody_NoRow_TempGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 1);
        BodyFacts(Observer, 1);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'tenant;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '1');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcCompany_TempEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 2);
        BodyFacts(Observer, 2);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('err|code', 'ReportUnsupportedFormat');
        Observer.Expect('body <> empty', 'No');
        Observer.Expect('body marker', 'none');
        Observer.Expect('body rgba( count', '0');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '0');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'Yes');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '0');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_NoRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 0);
        BodyFacts(Observer, 0);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'word;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '1');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '1');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '2');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '2');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_NoRow_TempEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(0, 2);
        BodyFacts(Observer, 2);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'word;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '1');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '1');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '2');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '2');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 0);
        BodyFacts(Observer, 0);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('err|code', 'ReportUnsupportedFormat');
        Observer.Expect('body <> empty', 'No');
        Observer.Expect('body marker', 'none');
        Observer.Expect('body rgba( count', '0');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '0');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'Yes');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '0');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcCompany_TempGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(1, 1);
        BodyFacts(Observer, 1);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'tenant;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '1');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcEmptyCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 0);
        BodyFacts(Observer, 0);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'word;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '1');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '1');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '2');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '2');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcEmptyCompany_TempGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 1);
        BodyFacts(Observer, 1);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'tenant;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '1');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcEmptyCompany_TempEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(2, 2);
        BodyFacts(Observer, 2);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'word;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '1');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '1');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '2');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '2');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcBoth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 0);
        BodyFacts(Observer, 0);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('err|code', 'ReportUnsupportedFormat');
        Observer.Expect('body <> empty', 'No');
        Observer.Expect('body marker', 'none');
        Observer.Expect('body rgba( count', '0');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '0');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'Yes');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '0');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcBoth_TempGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 1);
        BodyFacts(Observer, 1);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'tenant;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '1');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_RdlcBoth_TempEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(3, 2);
        BodyFacts(Observer, 2);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'No');
        Observer.Expect('err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('err|code', 'ReportUnsupportedFormat');
        Observer.Expect('body <> empty', 'No');
        Observer.Expect('body marker', 'none');
        Observer.Expect('body rgba( count', '0');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '0');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'Yes');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '0');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_WordCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 0);
        BodyFacts(Observer, 0);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'word;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '1');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '1');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '2');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '2');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_WordCompany_TempGuid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 1);
        BodyFacts(Observer, 1);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'tenant;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '0');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '0');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '1');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EmailBody_WordCompany_TempEmpty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup(4, 2);
        BodyFacts(Observer, 2);
        Helper.Cleanup();
        Observer.Expect('completed', 'Yes');
        Observer.Expect('returned', 'Yes');
        Observer.Expect('err|text', '');
        Observer.Expect('err|code', '');
        Observer.Expect('body <> empty', 'Yes');
        Observer.Expect('body marker', 'word;');
        Observer.Expect('body rgba( count', '1');
        Observer.Expect('body rgb( count', '1');
        Observer.Expect('body rgba(1,2,3,1)', '1');
        Observer.Expect('body rgb(1, 2, 3)', '1');
        Observer.Expect('GetBody = body', 'No');
        Observer.Expect('GetBody rgba( count', '0');
        Observer.Expect('GetBody rgb( count', '2');
        Observer.Expect('GetBody rgba(1,2,3,1)', '0');
        Observer.Expect('GetBody rgb(1, 2, 3)', '2');
        Observer.Verify();
    end;
}
