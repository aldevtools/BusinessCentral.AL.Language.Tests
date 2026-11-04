// Batch 5, md:163: the text and code of the error for an object id nobody compiled ("compiled with emit version N").
// The emit version differs by BC version (27024 for BC 27 in the AL Runner measurement); the Observer records the raw text.

codeunit 67055 "W5 Missing Caller"
{
    procedure RunMissingCodeunit(Id: Integer)
    begin
        Codeunit.Run(Id);
    end;
}

codeunit 67056 "W5 Missing Object Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The caller named in the text: the object whose code runs the call.
    [Test]
    procedure MissingCodeunit_FromHelperCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Caller: Codeunit "W5 Missing Caller";
    begin
        asserterror Caller.RunMissingCodeunit(99999999);
        Observer.ObserveError('run_missing_codeunit_via_helper');
        Observer.Expect('run_missing_codeunit_via_helper|text', 'You tried to invoke the CodeUnit object with the ID 99999999 from the object W5 Missing Object Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_missing_codeunit_via_helper|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    // Report, page and xmlport: unsure what each raises and in which form: Try wrappers.
    [Test]
    procedure MissingReport_Page_XmlPort()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRunReport(99999999);
        Observer.Observe('report_ok', Format(Ok));
        Observer.ObserveError('run_missing_report');
        Ok := TryRunPage(99999999);
        Observer.Observe('page_ok', Format(Ok));
        Observer.ObserveError('run_missing_page');
        Ok := TryRunXmlPort(99999999);
        Observer.Observe('xmlport_ok', Format(Ok));
        Observer.ObserveError('run_missing_xmlport');
        Observer.Expect('report_ok', 'No');
        Observer.Expect('run_missing_report|text', 'You tried to invoke the Report object with the ID 99999999 from the object W5 Missing Object Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_missing_report|code', 'AL:MetadataNotFound');
        Observer.Expect('page_ok', 'No');
        Observer.Expect('run_missing_page|text', 'You tried to invoke the Page object with the ID 99999999 from the object W5 Missing Object Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_missing_page|code', 'AL:MetadataNotFound');
        Observer.Expect('xmlport_ok', 'No');
        Observer.Expect('run_missing_xmlport|text', 'You tried to invoke the XmlPort object with the ID 99999999 from the object W5 Missing Object Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run_missing_xmlport|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunReport(Id: Integer)
    begin
        Report.Run(Id);
    end;

    [TryFunction]
    local procedure TryRunPage(Id: Integer)
    begin
        Page.Run(Id);
    end;

    [TryFunction]
    local procedure TryRunXmlPort(Id: Integer)
    begin
        Xmlport.Run(Id);
    end;
}
