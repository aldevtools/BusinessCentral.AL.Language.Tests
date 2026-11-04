// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Helper (70835), LT RptMrg Capture (70831), report 70883 / 70884 and the layout files of ReportMergerFixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// for Report.SaveAs of each ReportFormat (Pdf, Word, Excel, Html, Xml). Observed: whether the merger was called, the key list in order, every key and value
// flattened to path=value (masking: see ReportMergerFixtures.al), the object id.
// Facts: layoutmimetype, layoutname, object id and name, request values in the payload.
// BC versions: 29 (the final facts get added later)

codeunit 70836 "LT RptMrg Payload"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObservePayload(var Observer: Codeunit "Probe Observer"; Fmt: ReportFormat; RequestXml: Text; Rows: Integer)
    var
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
    begin
        Helper.SeedRows(Rows);
        Helper.ProbeSave(Observer, Fmt, RequestXml, Cap);
        Observer.Observe('object id', Cap.Item('id', 1));
        Observer.Observe('payload keys', Cap.Item('payload keys', 1));
        Helper.ObserveLong(Observer, 'payload', Cap.Item('payload', 1));
    end;

    [Test]
    procedure SaveAs_Pdf_CustomLayout_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePayload(Observer, ReportFormat::Pdf, '', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('payload length', '414');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/pdf" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Word_CustomLayout_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePayload(Observer, ReportFormat::Word, '', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('payload length', '470');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/vnd.openxmlformats-officedocument.wordprocessingml.document" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Excel_CustomLayout_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePayload(Observer, ReportFormat::Excel, '', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('payload length', '464');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Html_CustomLayout_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePayload(Observer, ReportFormat::Html, '', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('payload length', '408');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="text/html" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Xml_CustomLayout_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePayload(Observer, ReportFormat::Xml, '', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('calls', '0');
        Observer.Expect('object id', '<no call 1>');
        Observer.Expect('payload keys', '<no call 1>');
        Observer.Expect('payload length', '11');
        Observer.Expect('payload part 1', '<no call 1>');
        Observer.Ignore('output'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure SaveAs_Pdf_NoRows_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePayload(Observer, ReportFormat::Pdf, '', 0);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('payload length', '414');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/pdf" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Pdf_RequestValue_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObservePayload(Observer, ReportFormat::Pdf, '<?xml version="1.0" standalone="yes"?><ReportParameters name="LT RptMrg Report" id="70883"><Options><Field name="ModeVal">7</Field></Options><DataItems><DataItem name="Rows">VERSION(1) SORTING(Id) WHERE(Id=1(1))</DataItem></DataItems></ReportParameters>', 2);
        Observer.Expect('try completed', 'Yes');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('output', 'RLB-RENDEREDLMC-OUT');
        Observer.Expect('calls', '1');
        Observer.Expect('object id', '70883');
        Observer.Expect('payload keys', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('payload length', '527');
        Observer.Expect('payload part 1', 'filterviews[0].name="Rows" ; filterviews[0].tableid=70826 ; filterviews[0].view="VERSION(1) SORTING(Field1) WHERE(Field1=1(1))" ; version=1 ; objectname="LT Merger Main" ; objectid=70883 ; documenttype="application/pdf" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomA" ; layoutmimetype="application/x-lmc-layout" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_PayloadKeys_SameAcrossFormats()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        CapPdf: Codeunit "LT RptMrg Capture";
        CapWord: Codeunit "LT RptMrg Capture";
        CapExcel: Codeunit "LT RptMrg Capture";
        CapHtml: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(1);
        BindSubscription(CapPdf);
        if Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved) then;
        UnbindSubscription(CapPdf);
        BindSubscription(CapWord);
        if Helper.TrySaveAs(ReportFormat::Word, '', Output, Saved) then;
        UnbindSubscription(CapWord);
        BindSubscription(CapExcel);
        if Helper.TrySaveAs(ReportFormat::Excel, '', Output, Saved) then;
        UnbindSubscription(CapExcel);
        BindSubscription(CapHtml);
        if Helper.TrySaveAs(ReportFormat::Html, '', Output, Saved) then;
        UnbindSubscription(CapHtml);
        Observer.Observe('keys pdf', CapPdf.Item('payload keys', 1));
        Observer.Observe('keys word', CapWord.Item('payload keys', 1));
        Observer.Observe('keys excel', CapExcel.Item('payload keys', 1));
        Observer.Observe('keys html', CapHtml.Item('payload keys', 1));
        Observer.Observe('payload pdf = word', Format(CapPdf.Item('payload', 1) = CapWord.Item('payload', 1)));
        Observer.Observe('payload pdf = excel', Format(CapPdf.Item('payload', 1) = CapExcel.Item('payload', 1)));
        Observer.Observe('payload pdf = html', Format(CapPdf.Item('payload', 1) = CapHtml.Item('payload', 1)));
        Observer.Expect('keys pdf', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('keys word', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('keys excel', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('keys html', 'filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid');
        Observer.Expect('payload pdf = word', 'No');
        Observer.Expect('payload pdf = excel', 'No');
        Observer.Expect('payload pdf = html', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_NoDefaultReport_PayloadText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(1);
        BindSubscription(Cap);
        if Helper.TrySaveAsNoDefault(ReportFormat::Pdf, Output, Saved) then;
        UnbindSubscription(Cap);
        Observer.Observe('calls', Format(Cap.CallCount()));
        Observer.Observe('object id', Cap.Item('id', 1));
        Helper.ObserveLong(Observer, 'payload', Cap.Item('payload', 1));
        Observer.Expect('calls', '1');
        Observer.Expect('object id', '70884');
        Observer.Expect('payload length', '422');
        Observer.Expect('payload part 1', 'filterviews=[] ; version=1 ; objectname="LT Merger No Default" ; objectid=70884 ; documenttype="application/pdf" ; invokedby=<guid> ; invokeddatetime=<datetime> ; companyname=<masked> ; printername="" ; duplex=false ; color=false ; defaultcopies=1 ; papertray=null ; intent="Save" ; layoutmodel="Custom" ; layoutname="CustomB" ; layoutmimetype="application/x-lmc-layout-b" ; layoutapplicationid=<guid> ; reportrunid=<guid>');
        Observer.Verify();
    end;
}
