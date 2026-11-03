// Probe (observe only): XmlDocument.ReadFrom with XmlReadOptions, foreach over a JsonArray, HttpContent without a network call.
// Settles docs/probes-needed.md rows 954, 969, 971 (batch 4). Object ids 68071 - 68073.

codeunit 68071 "W4 Xml Options Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Read(Xml: Text; UseOptions: Boolean; Preserve: Boolean; SetPreserve: Boolean): Text
    var
        Options: XmlReadOptions;
        Doc: XmlDocument;
        Ok: Boolean;
        Output: Text;
    begin
        if UseOptions then begin
            if SetPreserve then
                Options.PreserveWhitespace(Preserve);
            Ok := XmlDocument.ReadFrom(Xml, Options, Doc);
        end else
            Ok := XmlDocument.ReadFrom(Xml, Doc);
        if not Ok then
            exit('read=false');
        Doc.WriteTo(Output);
        exit('read=true [' + Output + ']');
    end;

    [Test]
    procedure ReadFrom_InnerWhitespace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no_options', Read('<root>  <a/>  </root>', false, false, false));
        Observer.Observe('default_options', Read('<root>  <a/>  </root>', true, false, false));
        Observer.Observe('preserve_true', Read('<root>  <a/>  </root>', true, true, true));
        Observer.Observe('preserve_false', Read('<root>  <a/>  </root>', true, false, true));
        Observer.Expect('no_options', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>]');
        Observer.Expect('default_options', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>]');
        Observer.Expect('preserve_true', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>]');
        Observer.Expect('preserve_false', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>]');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_WhitespaceAroundTheRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no_options', Read(' <root/> ', false, false, false));
        Observer.Observe('default_options', Read(' <root/> ', true, false, false));
        Observer.Observe('preserve_true', Read(' <root/> ', true, true, true));
        Observer.Observe('preserve_false', Read(' <root/> ', true, false, true));
        Observer.Expect('no_options', 'read=true [<?xml version="1.0" encoding="utf-16"?> <root /> ]');
        Observer.Expect('default_options', 'read=true [<?xml version="1.0" encoding="utf-16"?> <root /> ]');
        Observer.Expect('preserve_true', 'read=true [<?xml version="1.0" encoding="utf-16"?> <root /> ]');
        Observer.Expect('preserve_false', 'read=true [<?xml version="1.0" encoding="utf-16"?> <root /> ]');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_TextContentWhitespace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('no_options', Read('<root> x <a> y </a>' + '</root>', false, false, false));
        Observer.Observe('default_options', Read('<root> x <a> y </a>' + '</root>', true, false, false));
        Observer.Observe('preserve_true', Read('<root> x <a> y </a>' + '</root>', true, true, true));
        Observer.Observe('preserve_false', Read('<root> x <a> y </a>' + '</root>', true, false, true));
        Observer.Expect('no_options', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root> x <a> y </a></root>]');
        Observer.Expect('default_options', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root> x <a> y </a></root>]');
        Observer.Expect('preserve_true', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root> x <a> y </a></root>]');
        Observer.Expect('preserve_false', 'read=true [<?xml version="1.0" encoding="utf-16"?>\r\n<root> x <a> y </a></root>]');
        Observer.Verify();
    end;
}

codeunit 68072 "W4 Json Foreach Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ThreeObjects(var Arr: JsonArray)
    var
        Obj: JsonObject;
        i: Integer;
    begin
        Clear(Arr);
        for i := 1 to 3 do begin
            Clear(Obj);
            Obj.Add('n', i);
            Arr.Add(Obj);
        end;
    end;

    local procedure Dump(Arr: JsonArray): Text
    var
        Output: Text;
    begin
        Arr.WriteTo(Output);
        exit(Output);
    end;

    [Test]
    procedure ForeachJsonArray_OrderAndBreak()
    var
        Arr: JsonArray;
        Tok: JsonToken;
        Seen: Text;
        Count: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        ThreeObjects(Arr);
        foreach Tok in Arr do begin
            Seen += Format(Tok.AsObject().Keys().Count()) + ':';
            Count += 1;
        end;
        Observer.Observe('count', Format(Count));
        Observer.Observe('keys_per_element', Seen);
        Count := 0;
        foreach Tok in Arr do begin
            Count += 1;
            if Count = 2 then
                break;
        end;
        Observer.Observe('count_with_break_at_2', Format(Count));
        Observer.Observe('token_after_break_is_object', Format(Tok.IsObject()));
        Observer.Expect('count', '3');
        Observer.Expect('keys_per_element', '1:1:1:');
        Observer.Expect('count_with_break_at_2', '2');
        Observer.Expect('token_after_break_is_object', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachJsonArray_EmptyArray()
    var
        Arr: JsonArray;
        Tok: JsonToken;
        Count: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        foreach Tok in Arr do
            Count += 1;
        Observer.Observe('count_empty', Format(Count));
        Observer.Expect('count_empty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachJsonArray_ChangeTheTokenObject()
    var
        Arr: JsonArray;
        Tok: JsonToken;
        Obj: JsonObject;
        Observer: Codeunit "Probe Observer";
    begin
        ThreeObjects(Arr);
        foreach Tok in Arr do begin
            Obj := Tok.AsObject();
            Obj.Add('added', true);
        end;
        Observer.Observe('array_after_add_through_AsObject_copy', Dump(Arr));
        ThreeObjects(Arr);
        foreach Tok in Arr do
            Tok.AsObject().Replace('n', 9);
        Observer.Observe('array_after_replace_on_token_AsObject', Dump(Arr));
        Observer.Expect('array_after_add_through_AsObject_copy', '[{"n":1,"added":true},{"n":2,"added":true},{"n":3,"added":true}]');
        Observer.Expect('array_after_replace_on_token_AsObject', '[{"n":9},{"n":9},{"n":9}]');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachJsonArray_ReassignTheLoopVariable()
    var
        Arr: JsonArray;
        Tok: JsonToken;
        Observer: Codeunit "Probe Observer";
    begin
        ThreeObjects(Arr);
        foreach Tok in Arr do
            Tok.ReadFrom('"x"');
        Observer.Observe('array_after_token_readfrom', Dump(Arr));
        Observer.Expect('array_after_token_readfrom', '[{"n":1},{"n":2},{"n":3}]');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachJsonArray_ArrayChangedInsideTheLoop()
    var
        Arr: JsonArray;
        Tok: JsonToken;
        Count: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        ThreeObjects(Arr);
        foreach Tok in Arr do begin
            Count += 1;
            if Count = 1 then
                Arr.Add(4);
        end;
        Observer.Observe('count_when_array_grows', Format(Count));
        Observer.Observe('array_length_after', Format(Arr.Count()));
        Observer.Expect('count_when_array_grows', '3');
        Observer.Expect('array_length_after', '4');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachJsonArray_SimpleValues()
    var
        Arr: JsonArray;
        Tok: JsonToken;
        Seen: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Arr.Add(3);
        Arr.Add('b');
        Arr.Add(true);
        Arr.Add(1.5);
        foreach Tok in Arr do
            Seen += Format(Tok.AsValue().AsText()) + '|';
        Observer.Observe('values_in_order', Seen);
        Observer.Expect('values_in_order', '3|b|true|1.5|');
        Observer.Verify();
    end;
}

codeunit 68073 "W4 Http Content Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryReadAs(var Content: HttpContent; var Result: Text)
    begin
        Content.ReadAs(Result);
    end;

    local procedure ReadOutcome(var Content: HttpContent): Text
    var
        Result: Text;
    begin
        if TryReadAs(Content, Result) then
            exit('ok:[' + Result + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure ReadAs_FreshContent()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('readas_text_fresh', ReadOutcome(Content));
        ClearLastError();
        Content.GetHeaders(Headers);
        Observer.Observe('content_type_present_fresh', Format(Headers.Contains('Content-Type')));
        Observer.Expect('readas_text_fresh', 'ok:[]');
        Observer.Expect('content_type_present_fresh', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromText_HeadersAndRoundTrip()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Values: array[10] of Text;
        Observer: Codeunit "Probe Observer";
    begin
        Content.WriteFrom('hello');
        Content.GetHeaders(Headers);
        Observer.Observe('contains_content_type', Format(Headers.Contains('Content-Type')));
        Observer.Observe('contains_content_type_lower', Format(Headers.Contains('content-type')));
        if Headers.GetValues('Content-Type', Values) then
            Observer.Observe('content_type_value', Values[1])
        else
            Observer.Observe('content_type_value', '<none>');
        Observer.Observe('contains_content_length', Format(Headers.Contains('Content-Length')));
        Observer.Observe('roundtrip', ReadOutcome(Content));
        Observer.Expect('contains_content_type', 'Yes');
        Observer.Expect('contains_content_type_lower', 'Yes');
        Observer.Expect('content_type_value', 'text/plain; charset=utf-8');
        Observer.Expect('contains_content_length', 'No');
        Observer.Expect('roundtrip', 'ok:[hello]');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromInStream_NonAsciiBytes()
    var
        TempBlob: Codeunit "Temp Blob";
        Content: HttpContent;
        OutS: OutStream;
        InS: InStream;
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('äöü€');
        TempBlob.CreateInStream(InS);
        Content.WriteFrom(InS);
        Observer.Observe('utf8_bytes_read_as_text', ReadOutcome(Content));
        Observer.Observe('same_as_written', Format(ReadOutcome(Content) = 'ok:[äöü€]'));
        Observer.Expect('utf8_bytes_read_as_text', 'ok:[äöü€]');
        Observer.Expect('same_as_written', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RequestContent_IsCopyOrReference()
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
        Got: HttpContent;
        Headers: HttpHeaders;
        Observer: Codeunit "Probe Observer";
    begin
        Content.WriteFrom('one');
        Req.Content := Content;
        Content.WriteFrom('two');
        Req.Content.ReadAs(ReadHolder);
        Observer.Observe('request_content_after_original_written_again', ReadHolder);
        Got := Req.Content;
        Got.WriteFrom('three');
        Req.Content.ReadAs(ReadHolder);
        Observer.Observe('request_content_after_fetched_copy_written', ReadHolder);
        Observer.Expect('request_content_after_original_written_again', 'one');
        Observer.Expect('request_content_after_fetched_copy_written', 'one');
        Observer.Verify();
    end;

    [Test]
    procedure RequestWithoutContent_ReadAs()
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
        Observer: Codeunit "Probe Observer";
    begin
        Content := Req.Content;
        Observer.Observe('readas_of_request_without_content', ReadOutcome(Content));
        ClearLastError();
        Observer.Expect('readas_of_request_without_content', 'error:Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    var
        ReadHolder: Text;
}
