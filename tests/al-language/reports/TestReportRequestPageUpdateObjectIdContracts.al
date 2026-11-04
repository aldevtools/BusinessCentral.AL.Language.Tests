// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-objectid-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/requestpage/requestpage-update-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 69120, codeunit 69121 (log), report 69122, codeunit 69123 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - RequestOptionsPage.Update(false) in the OnValidate of a request page field refreshes the other controls: a TestRequestPage handler that
//    sets Source to 21 reads Derived 42 (the trigger set Derived := Source * 2 and called Update).
//  - CurrReport.ObjectId(false) reads "Report <id>" and ObjectId(true) "Report <caption>" ("Report Q1 caption" for a report with the Caption
//    'Q1 caption'; the name when there is no caption was not measured).
//  - CurrReport.Preview() is false in a report run by Report.Run (with and without the request page) and RunModal.
// BC versions: 27.5

table 69120 "Probe RPU Table"
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

codeunit 69121 "Probe RPU Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

report 69122 "Probe RPU Report"
{
    Caption = 'Q1 caption';
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(T; "Probe RPU Table") { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Source; Source)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Derived := Source * 2;
                        RequestOptionsPage.Update(false);
                        RpuLog.Add('validated source ' + Format(Source));
                    end;
                }
                field(Derived; Derived) { ApplicationArea = All; }
            }
        }
    }

    var
        Source: Integer;
        Derived: Integer;
        RpuLog: Codeunit "Probe RPU Log";

    trigger OnPreReport()
    begin
        RpuLog.Add('ObjectId(false)=[' + CurrReport.ObjectId(false) + '] ObjectId(true)=[' + CurrReport.ObjectId(true) + ']');
        RpuLog.Add('Preview=' + Format(CurrReport.Preview()));
    end;
}

codeunit 69123 "Probe Report RPU"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        RpuLog: Codeunit "Probe RPU Log";
        Seen: Text;

    [RequestPageHandler]
    procedure SetSourceHandler(var RP: TestRequestPage "Probe RPU Report")
    begin
        RP.Source.SetValue(21);
        Seen := RP.Derived.Value();
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetSourceHandler')]
    procedure RequestPageUpdate_RefreshesTheOtherControls()
    begin
        RpuLog.Take();

        Report.Run(Report::"Probe RPU Report");

        Assert.AreEqual('42', Seen, 'Derived');
        Assert.AreEqual('validated source 21;ObjectId(false)=[Report 69122] ObjectId(true)=[Report Q1 caption];Preview=No;', RpuLog.Take(), 'log');
    end;

    [Test]
    procedure ObjectIdAndPreview_WithoutTheRequestPage_AndWithRunModal()
    var
        RpuReport: Report "Probe RPU Report";
    begin
        RpuLog.Take();
        RpuReport.UseRequestPage(false);
        RpuReport.Run();
        Assert.AreEqual('ObjectId(false)=[Report 69122] ObjectId(true)=[Report Q1 caption];Preview=No;', RpuLog.Take(), 'Run');

        RpuReport.UseRequestPage(false);
        RpuReport.RunModal();
        Assert.AreEqual('ObjectId(false)=[Report 69122] ObjectId(true)=[Report Q1 caption];Preview=No;', RpuLog.Take(), 'RunModal');
    end;
}
