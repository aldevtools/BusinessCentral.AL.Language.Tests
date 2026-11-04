// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-editable-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// TestRequestPage.Editable() at page level, in a RequestPageHandler: Yes for the request page of a ProcessingOnly report and of a report with a layout; No when the request page
// states Editable = false (its fields then read Editable No as well).
// Fixtures used: self-contained table 69544, codeunit 69554 (log), reports 69548 to 69550, codeunit 69555
// BC versions: 27.5

table 69544 "PS Rp Row"
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

codeunit 69554 "PS Rp Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 69548 "PS Rp Processing"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "PS Rp Row") { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Value; Value)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Value: Integer;
}

report 69549 "PS Rp NotProcessing"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Row; "PS Rp Row")
        {
            column(Id; Id) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Value; Value)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Value: Integer;
}

report 69550 "PS Rp NotEditable"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "PS Rp Row") { }
    }

    requestpage
    {
        Editable = false;

        layout
        {
            area(Content)
            {
                field(Value; Value)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Value: Integer;
}

codeunit 69555 "PS Rp Editable Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('ProcessingHandler')]
    procedure Editable_ProcessingOnlyReport()
    var
        Rpt: Report "PS Rp Processing";
        Log: Codeunit "PS Rp Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Commit();
        Rpt.Run();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'page_editable=Yes field_editable=Yes;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ProcessingHandler(var RP: TestRequestPage "PS Rp Processing")
    var
        Log: Codeunit "PS Rp Log";
    begin
        Log.Add('page_editable=' + Format(RP.Editable()) + ' field_editable=' + Format(RP.Value.Editable()));
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('NotProcessingHandler')]
    procedure Editable_ReportWithLayout()
    var
        Rpt: Report "PS Rp NotProcessing";
        Log: Codeunit "PS Rp Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Commit();
        Rpt.Run();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'page_editable=Yes field_editable=Yes;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure NotProcessingHandler(var RP: TestRequestPage "PS Rp NotProcessing")
    var
        Log: Codeunit "PS Rp Log";
    begin
        Log.Add('page_editable=' + Format(RP.Editable()) + ' field_editable=' + Format(RP.Value.Editable()));
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('NotEditableHandler')]
    procedure Editable_RequestPageEditableFalse()
    var
        Rpt: Report "PS Rp NotEditable";
        Log: Codeunit "PS Rp Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Commit();
        Rpt.Run();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'page_editable=No field_editable=No;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure NotEditableHandler(var RP: TestRequestPage "PS Rp NotEditable")
    var
        Log: Codeunit "PS Rp Log";
    begin
        Log.Add('page_editable=' + Format(RP.Editable()) + ' field_editable=' + Format(RP.Value.Editable()));
        RP.Cancel().Invoke();
    end;
}
