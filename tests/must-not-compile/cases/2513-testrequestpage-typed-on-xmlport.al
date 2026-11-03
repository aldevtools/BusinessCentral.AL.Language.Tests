// @expect AL0185 | Report 'MNC Y40 XmlPort' is missing
// @expect AL0240 | The signature of procedure 'XmlPortRequestPage' does not match the signature required by attribute 'RequestPageHandler': parameter 1 is expected to be of type 'var TestRequestPage' but found type 'var '. The expected signature is: XmlPortRequestPage(var RequestPage: TestRequestPage).
// A RequestPageHandler typed on an xmlport: TestRequestPage takes a report only, so a test cannot handle the request page of an
// xmlport (the runs are xmlport/lt-y40-xmlport-request-page/Y40XmlPortRequestPage.al, writer Y40).
xmlport 50000 "MNC Y40 XmlPort"
{
    schema
    {
        textelement(Root) { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; Note) { }
            }
        }
    }

    var
        Note: Text[30];
}

codeunit 50001 "MNC Y40 XmlPort Handler"
{
    Subtype = Test;

    [RequestPageHandler]
    procedure XmlPortRequestPage(var RP: TestRequestPage "MNC Y40 XmlPort")
    begin
    end;
}
