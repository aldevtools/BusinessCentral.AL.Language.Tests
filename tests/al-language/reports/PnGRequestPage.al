// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Rpt (70150), LT PnG Rpt Ext (70151), LT PnG Rpt NoFilter (70152), LT PnG Rpt Filter (70153), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 13 (Request pages: a reportextension control bound to a protected var of the base report; a reportextension that only adds controls) and 15 (Request pages: ShowFilter = false with data items, parameters text)
// Facts: controls of a reportextension on the request page, their values in OnPreReport of base and extension, parameters text content, ShowFilter = false against true
// BC versions: 29 (27 and 28 by CI)

codeunit 70173 "LT PnG Request Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Integer;
        HandlerCalls: Integer;
        Seen: Text;

    [Test]
    [HandlerFunctions('ProtectedVarHandler')]
    procedure ExtensionControlReadsBaseProtectedVar()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Mode := 1;
        HandlerCalls := 0;
        Seen := '';
        Params := Report.RunRequestPage(Report::"LT PnG Rpt");
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Observe('seen', Seen);
        Observer.Observe('params-has-ExtProtCtl', Format(Params.Contains('ExtProtCtl')));
        Observer.Observe('params-has-ExtOwnCtl', Format(Params.Contains('ExtOwnCtl')));
        Observer.Observe('params-has-ReqTextCtl', Format(Params.Contains('ReqTextCtl')));
        Observer.Observe('params-has-BaseInit', Format(Params.Contains('BaseInit')));
        Observer.Observe('params-has-ProtWritten', Format(Params.Contains('ProtWritten')));
        Observer.Observe('params-has-OwnWritten', Format(Params.Contains('OwnWritten')));
        Observer.Expect('calls', '1');
        Observer.Expect('seen', 'prot=BaseInit|own=|text=TextInit|num=3|prot-after=ProtWritten');
        Observer.Expect('params-has-ExtProtCtl', 'No');
        Observer.Expect('params-has-ExtOwnCtl', 'No');
        Observer.Expect('params-has-ReqTextCtl', 'No');
        Observer.Expect('params-has-BaseInit', 'No');
        Observer.Expect('params-has-ProtWritten', 'Yes');
        Observer.Expect('params-has-OwnWritten', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoFilterHandler')]
    procedure ShowFilterFalseParameters()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Mode := 1;
        HandlerCalls := 0;
        Params := Report.RunRequestPage(Report::"LT PnG Rpt NoFilter");
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Observe('has-dataitem-tag', Format(Params.Contains('<DataItem')));
        Observer.Observe('has-dataitem-name', Format(Params.Contains('name="Items"')));
        Observer.Observe('has-optctl', Format(Params.Contains('OptCtl')));
        Observer.Observe('has-optvalue', Format(Params.Contains('opt-value')));
        Observer.Observe('has-table-name', Format(Params.Contains('LT PnG Item')));
        Observer.Observe('has-filter-text', Format(Params.Contains('Filter')));
        Observer.Expect('calls', '1');
        Observer.Expect('has-dataitem-tag', 'Yes');
        Observer.Expect('has-dataitem-name', 'Yes');
        Observer.Expect('has-optctl', 'No');
        Observer.Expect('has-optvalue', 'Yes');
        Observer.Expect('has-table-name', 'No');
        Observer.Expect('has-filter-text', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('WithFilterHandler')]
    procedure ShowFilterTrueParameters()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Mode := 1;
        HandlerCalls := 0;
        Params := Report.RunRequestPage(Report::"LT PnG Rpt Filter");
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Observe('has-dataitem-tag', Format(Params.Contains('<DataItem')));
        Observer.Observe('has-dataitem-name', Format(Params.Contains('name="Items"')));
        Observer.Observe('has-optctl', Format(Params.Contains('OptCtl')));
        Observer.Observe('has-optvalue', Format(Params.Contains('opt-value')));
        
        Observer.Expect('calls', '1');
        Observer.Expect('has-dataitem-tag', 'Yes');
        Observer.Expect('has-dataitem-name', 'Yes');
        Observer.Expect('has-optctl', 'No');
        Observer.Expect('has-optvalue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NoFilterHandler')]
    procedure ShowFilterFalseCancelled()
    var
        Observer: Codeunit "Probe Observer";
        Params: Text;
    begin
        Mode := 3;
        HandlerCalls := 0;
        Params := Report.RunRequestPage(Report::"LT PnG Rpt NoFilter");
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Observe('params-length', Format(StrLen(Params)));
        Observer.Expect('calls', '1');
        Observer.Expect('params-length', '0');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ProtectedVarHandler(var RP: TestRequestPage "LT PnG Rpt")
    begin
        HandlerCalls += 1;
        case Mode of
            1:
                begin
                    Seen := 'prot=' + RP.ExtProtCtl.Value() + '|own=' + RP.ExtOwnCtl.Value() + '|text=' + RP.ReqTextCtl.Value() + '|num=' + RP.ReqNumCtl.Value();
                    RP.ExtProtCtl.SetValue('ProtWritten');
                    RP.ExtOwnCtl.SetValue('OwnWritten');
                    Seen += '|prot-after=' + RP.ExtProtCtl.Value();
                    RP.OK().Invoke();
                end;
            2, 4:
                begin
                    RP.ExtProtCtl.SetValue('ProtWritten');
                    RP.ExtOwnCtl.SetValue('OwnWritten');
                    RP.ReqTextCtl.SetValue('TextWritten');
                    RP.OK().Invoke();
                end;
            3:
                RP.Cancel().Invoke();
        end;
    end;

    [RequestPageHandler]
    procedure NoFilterHandler(var RP: TestRequestPage "LT PnG Rpt NoFilter")
    begin
        HandlerCalls += 1;
        if Mode = 3 then begin
            RP.Cancel().Invoke();
            exit;
        end;
        RP.OptCtl.SetValue('opt-value');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WithFilterHandler(var RP: TestRequestPage "LT PnG Rpt Filter")
    begin
        HandlerCalls += 1;
        RP.OptCtl.SetValue('opt-value');
        RP.OK().Invoke();
    end;
}
