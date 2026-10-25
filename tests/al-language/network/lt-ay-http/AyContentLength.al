// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80508
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: the Content-Length header of an HttpContent after WriteFrom('hello'): before and after ReadAs(Text), after ReadAs(InStream), after a second
// WriteFrom of a longer text, after WriteFrom of an InStream, and when GetHeaders was taken before the first WriteFrom (Contains and GetValues).
// Writer PY (2026-10-20, tests PY_*): WriteFrom of another length after a read put Content-Length in the headers.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80508 "LT AY Content Length"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Len(var C: HttpContent): Text
    var
        H: HttpHeaders;
        Vals: List of [Text];
        V: Text;
        Out: Text;
    begin
        C.GetHeaders(H);
        Out := Format(H.Contains('Content-Length'));
        if H.GetValues('Content-Length', Vals) then
            foreach V in Vals do
                Out += '[' + V + ']';
        exit(Out);
    end;

    [Test]
    procedure ContentLength_AroundReadAsText()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        T: Text;
    begin
        Observer.Observe('fresh', Len(C));
        C.WriteFrom('hello');
        Observer.Observe('after_write', Len(C));
        C.ReadAs(T);
        Observer.Observe('after_readas_text', Len(C) + ' read=' + T);
        C.ReadAs(T);
        Observer.Observe('after_second_readas', Len(C) + ' read=' + T);
        Observer.Expect('fresh', 'No');
        Observer.Expect('after_write', 'No');
        Observer.Expect('after_readas_text', 'Yes[5] read=hello');
        Observer.Expect('after_second_readas', 'Yes[5] read=hello');
        Observer.Verify();
    end;

    [Test]
    procedure ContentLength_AroundReadAsInStream()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        InS: InStream;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(InS);
        Observer.Observe('after_readas_instream', Len(C));
        InS.ReadText(T);
        Observer.Observe('after_reading_stream', Len(C) + ' read=' + T);
        Observer.Expect('after_readas_instream', 'No');
        Observer.Expect('after_reading_stream', 'No read=hello');
        Observer.Verify();
    end;

    [Test]
    procedure ContentLength_SecondWriteFrom()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        T: Text;
    begin
        C.WriteFrom('hello');
        Observer.Observe('first', Len(C));
        C.WriteFrom('a longer text');
        Observer.Observe('second', Len(C));
        C.ReadAs(T);
        Observer.Observe('second_read', Len(C) + ' read=' + T);
        C.WriteFrom('');
        Observer.Observe('empty', Len(C));
        Observer.Expect('first', 'No');
        Observer.Expect('second', 'No');
        Observer.Expect('second_read', 'Yes[13] read=a longer text');
        Observer.Expect('empty', 'Yes[13]');
        Observer.Verify();
    end;

// Linux suspect (corpus CI 2026-10-19, 27.5/28.5/29.0): this test ends with the bare .NET text "Exception of type
// 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException' was thrown." Kept as source, not compiled, until the Windows nightly confirms it.
#if LT_AY_LINUX_SUSPECT
    [Test]
    procedure ContentLength_HeadersTakenBeforeWrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        Vals: List of [Text];
        T: Text;
    begin
        C.GetHeaders(H);
        C.WriteFrom('hello');
        H.GetValues('Content-Length', Vals);
        Observer.Observe('old_handle', Format(H.Contains('Content-Length')) + ' n=' + Format(Vals.Count()));
        Observer.Observe('new_handle', Len(C));
        C.ReadAs(T);
        Observer.Observe('new_handle_after_read', Len(C));
        Observer.Finish();
    end;
#endif

    [Test]
    procedure ContentLength_WriteFromInStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        C: HttpContent;
        OutS: OutStream;
        InS: InStream;
        T: Text;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('hello world');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        C.WriteFrom(InS);
        Observer.Observe('stream', Len(C));
        C.ReadAs(T);
        Observer.Observe('stream_read', Len(C) + ' read=' + T);
        Observer.Expect('stream', 'No');
        Observer.Expect('stream_read', 'Yes[11] read=hello world');
        Observer.Verify();
    end;

    // Writer PY (2026-10-20): probes-needed "HTTP" row "Content-Length value after HttpContent.WriteFrom of a non-empty body of another length,
    // once a read put a Content-Length in the headers".
    [Test]
    procedure PY_ContentLength_LongerBodyAfterRead()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(T);
        Observer.Observe('first_read', Len(C));
        C.WriteFrom('a longer text');
        Observer.Observe('rewritten', Len(C));
        C.ReadAs(T);
        Observer.Observe('second_read', Len(C) + ' read=' + T);
        Observer.Expect('first_read', 'Yes[5]');
        Observer.Expect('rewritten', 'Yes[5]');
        Observer.Expect('second_read', 'Yes[5] read=a longer text');
        Observer.Verify();
    end;

    [Test]
    procedure PY_ContentLength_ShorterBodyAfterRead()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(T);
        C.WriteFrom('hi');
        Observer.Observe('rewritten', Len(C));
        C.ReadAs(T);
        Observer.Observe('second_read', Len(C) + ' read=' + T);
        C.WriteFrom('a much longer text');
        Observer.Observe('third_write', Len(C));
        C.ReadAs(T);
        Observer.Observe('third_read', Len(C) + ' read=' + T);
        Observer.Expect('rewritten', 'Yes[5]');
        Observer.Expect('second_read', 'Yes[5] read=hi');
        Observer.Expect('third_write', 'Yes[5]');
        Observer.Expect('third_read', 'Yes[5] read=a much longer text');
        Observer.Verify();
    end;

    [Test]
    procedure PY_ContentLength_HandleTakenAfterReadThenRewrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        Vals: List of [Text];
        V: Text;
        Out: Text;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(T);
        C.GetHeaders(H);
        C.WriteFrom('a longer text');
        Out := Format(H.Contains('Content-Length'));
        if H.GetValues('Content-Length', Vals) then
            foreach V in Vals do
                Out += '[' + V + ']';
        Observer.Observe('old_handle', Out);
        Observer.Observe('new_handle', Len(C));
        Observer.Expect('old_handle', 'Yes[5]');
        Observer.Expect('new_handle', 'Yes[5]');
        Observer.Verify();
    end;

    [Test]
    procedure PY_ContentLength_InStreamAfterRead()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        C: HttpContent;
        OutS: OutStream;
        InS: InStream;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(T);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('hello world');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        C.WriteFrom(InS);
        Observer.Observe('stream', Len(C));
        C.ReadAs(T);
        Observer.Observe('stream_read', Len(C) + ' read=' + T);
        Observer.Expect('stream', 'Yes[5]');
        Observer.Expect('stream_read', 'Yes[5] read=hello world');
        Observer.Verify();
    end;

    // Writer SE (2026-10-25, tests SE_*): al-runtime-rs assumption http-content-length-after-read: a headers handle taken after WriteFrom and
    // before the read, the order of ReadAs(InStream) and ReadAs(Text), an empty body, a Content-Length added by hand before the read,
    // and a handle taken before the first WriteFrom (the Linux CI ended ContentLength_HeadersTakenBeforeWrite with a bare .NET exception).
    local procedure Show(var H: HttpHeaders): Text
    var
        Vals: List of [Text];
        V: Text;
        Out: Text;
    begin
        Out := Format(H.Contains('Content-Length'));
        if H.GetValues('Content-Length', Vals) then
            foreach V in Vals do
                Out += '[' + V + ']';
        exit(Out);
    end;

    [Test]
    procedure SE_ContentLength_HandleTakenBeforeRead()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.GetHeaders(H);
        Observer.Observe('old_handle_before_read', Show(H));
        C.ReadAs(T);
        Observer.Observe('old_handle_after_read', Show(H));
        Observer.Observe('new_handle_after_read', Len(C));
        Observer.Finish();
    end;

    [Test]
    procedure SE_ContentLength_InStreamThenText()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        InS: InStream;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(InS);
        Observer.Observe('after_instream', Len(C));
        C.ReadAs(T);
        Observer.Observe('after_text', Len(C) + ' read=' + T);
        Observer.Finish();
    end;

    [Test]
    procedure SE_ContentLength_TextThenInStream()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        InS: InStream;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(T);
        C.ReadAs(InS);
        InS.ReadText(T);
        Observer.Observe('after_instream', Len(C) + ' read=' + T);
        Observer.Finish();
    end;

    [Test]
    procedure SE_ContentLength_EmptyBody()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        T: Text;
    begin
        C.WriteFrom('');
        Observer.Observe('empty_write', Len(C));
        C.ReadAs(T);
        Observer.Observe('empty_read', Len(C) + ' read=' + T);
        C.WriteFrom('hello');
        C.ReadAs(T);
        Observer.Observe('then_hello_read', Len(C) + ' read=' + T);
        Observer.Finish();
    end;

    [Test]
    procedure SE_ContentLength_AddedByHandBeforeRead()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.GetHeaders(H);
        Observer.Observe('add', Format(H.Add('Content-Length', '3')));
        Observer.Observe('before_read', Show(H));
        C.ReadAs(T);
        Observer.Observe('after_read', Show(H) + ' read=' + T);
        Observer.Observe('new_handle', Len(C));
        Observer.Finish();
    end;

    [Test]
    procedure SE_ContentLength_HandleTakenBeforeWrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        T: Text;
    begin
        C.GetHeaders(H);
        C.WriteFrom('hello');
        Observer.Observe('old_contains', Format(H.Contains('Content-Length')));
        Observer.Observe('new_handle', Len(C));
        C.ReadAs(T);
        Observer.Observe('old_contains_after_read', Format(H.Contains('Content-Length')));
        Observer.Observe('new_handle_after_read', Len(C));
        Observer.Finish();
    end;
}
