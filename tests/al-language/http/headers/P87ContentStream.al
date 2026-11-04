// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228), table 74221
// Probe: written against BC 29 (runtime 16); every value is observed through Probe Observer and measured later on real BC 29. No request is ever sent.
// Facts: WriteFrom of an InStream (Blob field of an own temporary table, OutStream written into a Blob) and the headers around it
// BC versions: 29

codeunit 74226 "LT P87 Content Stream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Type(var H: HttpHeaders): Text
    begin
        exit(Helper.DoGet(H, 'Content-Type'));
    end;

    local procedure Read(var C: HttpContent): Text
    var
        T: Text;
        R: Boolean;
    begin
        T := 'preset';
        R := C.ReadAs(T);
        exit(Format(R) + '/' + T);
    end;

    local procedure FillBlob(var Rec: Record "LT P87 Blob" temporary; Txt: Text)
    var
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Code := 'B1';
        Rec.Data.CreateOutStream(OutS);
        OutS.WriteText(Txt);
        Rec.Insert();
    end;

    [Test]
    procedure BlobStream_HeaderBeforeWrite()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillBlob(Rec, 'blob text');
        C.GetHeaders(H);
        Observer.Observe('add', Helper.DoAdd(H, 'X-A', '1'));
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.WriteFrom(InS);
        Observer.Observe('oldHasA', Helper.DoContains(H, 'X-A'));
        Observer.Observe('oldType', Type(H));
        C.GetHeaders(H2);
        Observer.Observe('newHasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('newKeys', Helper.Keys(H2));
        Observer.Observe('newType', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Expect('add', 'added');
        Observer.Expect('oldHasA', 'Yes');
        Observer.Expect('oldType', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('newHasA', 'Yes');
        Observer.Expect('newKeys', '2:Content-Type,X-A,');
        Observer.Expect('newType', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('read', 'Yes/blob text');
        Observer.Verify();
    end;

    [Test]
    procedure BlobStream_HeaderAfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillBlob(Rec, 'blob text');
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('type', Type(H));
        Observer.Observe('add', Helper.DoAdd(H, 'X-A', '1'));
        C.GetHeaders(H2);
        Observer.Observe('hasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('read', Read(C));
        Observer.Observe('readAgain', Read(C));
        Observer.Expect('keys', '1:Content-Type,');
        Observer.Expect('type', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('add', 'added');
        Observer.Expect('hasA', 'Yes');
        Observer.Expect('read', 'Yes/blob text');
        Observer.Expect('readAgain', 'Yes/blob text');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyBlobStream()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Code := 'B1';
        Rec.Insert();
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('type', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Expect('keys', '1:Content-Type,');
        Observer.Expect('type', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('read', 'Yes/');
        Observer.Verify();
    end;

    [Test]
    procedure StreamThenClearThenText()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillBlob(Rec, 'blob text');
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.GetHeaders(H);
        Helper.DoAdd(H, 'X-A', '1');
        C.WriteFrom(InS);
        C.Clear();
        C.WriteFrom('text');
        C.GetHeaders(H2);
        Observer.Observe('hasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('keys', Helper.Keys(H2));
        Observer.Observe('type', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Expect('hasA', 'No');
        Observer.Expect('keys', '1:Content-Type,');
        Observer.Expect('type', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('read', 'Yes/text');
        Observer.Verify();
    end;

    [Test]
    procedure OutStreamIntoBlob_ThenContent()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
        InS2: InStream;
        T: Text;
    begin
        FillBlob(Rec, 'line1');
        C.WriteFrom('from content');
        C.GetHeaders(H);
        Observer.Observe('type', Type(H));
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        InS.ReadText(T);
        Observer.Observe('blobText', T);
        Observer.Observe('contentAsStream', Format(C.ReadAs(InS2)));
        InS2.ReadText(T);
        Observer.Observe('streamText', T);
        Observer.Expect('type', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('blobText', 'line1');
        Observer.Expect('contentAsStream', 'Yes');
        Observer.Expect('streamText', 'from content');
        Observer.Verify();
    end;

    [Test]
    procedure PartiallyReadStream_Headers()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
        Part: Text;
    begin
        FillBlob(Rec, 'abcdefghij');
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        InS.ReadText(Part, 3);
        Observer.Observe('part', Part);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('type', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Expect('part', 'abc');
        Observer.Expect('type', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('read', 'Yes/defghij');
        Observer.Verify();
    end;
}
