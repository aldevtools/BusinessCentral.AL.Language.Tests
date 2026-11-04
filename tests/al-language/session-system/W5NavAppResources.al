// Batch 5, md:246 (NavApp resources): ListResources filter wildcards and case, how exactly a resource name is matched, text encodings.
// The corpus app packages session/res (greeting.txt = 'Hello from packaged resource', sub/nested.txt). The publisher compiles this file into the corpus app, so those
// resources are the ones read. Reading is behind Try wrappers: a refused name shows as text.

codeunit 67064 "W5 NavApp Resource Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ListResources with filters: the names that match, in the order BC returns them.
    // The name is matched exactly, relative to the resource folder.
    [Test]
    procedure GetResourceAsText_NameMatching()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('greeting.txt', ReadName('greeting.txt'));
        Observer.Observe('GREETING.TXT', ReadName('GREETING.TXT'));
        Observer.Observe('Greeting.txt', ReadName('Greeting.txt'));
        Observer.Observe('sub/nested.txt', ReadName('sub/nested.txt'));
        Observer.Observe('sub\nested.txt', ReadName('sub\nested.txt'));
        Observer.Observe('SUB/nested.txt', ReadName('SUB/nested.txt'));
        Observer.Observe('/greeting.txt', ReadName('/greeting.txt'));
        Observer.Observe('./greeting.txt', ReadName('./greeting.txt'));
        Observer.Observe('session/res/greeting.txt', ReadName('session/res/greeting.txt'));
        Observer.Observe('res/greeting.txt', ReadName('res/greeting.txt'));
        Observer.Observe('greeting', ReadName('greeting'));
        Observer.Observe('empty', ReadName(''));
        Observer.Observe('greeting.txt_with_trailing_space', ReadName('greeting.txt '));
        Observer.Expect('greeting.txt', 'ok:Hello from packaged resource');
        Observer.Expect('GREETING.TXT', 'error:A resource matching ''GREETING.TXT'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('Greeting.txt', 'error:A resource matching ''Greeting.txt'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('sub/nested.txt', 'ok:nested-resource-content');
        Observer.Expect('sub\nested.txt', 'error:A resource matching ''sub\nested.txt'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('SUB/nested.txt', 'error:A resource matching ''SUB/nested.txt'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('/greeting.txt', 'error:A resource matching ''/greeting.txt'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('./greeting.txt', 'error:A resource matching ''./greeting.txt'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('session/res/greeting.txt', 'error:A resource matching ''session/res/greeting.txt'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('res/greeting.txt', 'error:A resource matching ''res/greeting.txt'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('greeting', 'error:A resource matching ''greeting'' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('empty', 'error:A resource matching '''' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Expect('greeting.txt_with_trailing_space', 'error:A resource matching ''greeting.txt '' could not be found in app ''AL Language Coverage Tests by AL Language x''.');
        Observer.Verify();
    end;

    // Text encodings for a plain ASCII resource.
    [Test]
    procedure GetResourceAsText_Encodings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8', ReadEncoded(TextEncoding::UTF8));
        Observer.Observe('utf16', ReadEncoded(TextEncoding::UTF16));
        Observer.Observe('msdos', ReadEncoded(TextEncoding::MSDos));
        Observer.Observe('windows', ReadEncoded(TextEncoding::Windows));
        Observer.Observe('default_encoding', ReadDefault());
        Observer.Expect('utf8', 'ok:length=28:first=Hello');
        Observer.Expect('utf16', 'ok:length=14:first=效汬⁯牦浯');
        Observer.Expect('msdos', 'ok:length=28:first=Hello');
        Observer.Expect('windows', 'ok:length=28:first=Hello');
        Observer.Expect('default_encoding', 'ok:length=28:first=Hello');
        Observer.Verify();
    end;

    // The resource read as JSON when it is not JSON.
    [Test]
    procedure GetResourceAsJson_NotJson()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryAsJson('greeting.txt');
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('as_json_of_text');
        Observer.Expect('ok', 'No');
        Observer.Expect('as_json_of_text|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('as_json_of_text|code', 'InvalidJsonData');
        Observer.Verify();
    end;

    local procedure Joined(Names: List of [Text]): Text
    var
        Name: Text;
        Result: Text;
    begin
        foreach Name in Names do
            Result += Name + '|';
        exit(Format(Names.Count()) + ':' + Result);
    end;

    local procedure ReadName(Name: Text): Text
    var
        Content: Text;
    begin
        ClearLastError();
        if TryReadText(Name, Content) then
            exit('ok:' + Content);
        Content := 'error:' + GetLastErrorText();
        ClearLastError();
        exit(Content);
    end;

    local procedure ReadEncoded(Encoding: TextEncoding): Text
    var
        Content: Text;
    begin
        ClearLastError();
        if TryReadEncoded(Encoding, Content) then
            exit('ok:length=' + Format(StrLen(Content)) + ':first=' + CopyStr(Content, 1, 5));
        Content := 'error:' + GetLastErrorText();
        ClearLastError();
        exit(Content);
    end;

    local procedure ReadDefault(): Text
    var
        Content: Text;
    begin
        Content := NavApp.GetResourceAsText('greeting.txt');
        exit('ok:length=' + Format(StrLen(Content)) + ':first=' + CopyStr(Content, 1, 5));
    end;

    [TryFunction]
    local procedure TryReadText(Name: Text; var Content: Text)
    begin
        Content := NavApp.GetResourceAsText(Name);
    end;

    [TryFunction]
    local procedure TryReadEncoded(Encoding: TextEncoding; var Content: Text)
    begin
        Content := NavApp.GetResourceAsText('greeting.txt', Encoding);
    end;

    [TryFunction]
    local procedure TryAsJson(Name: Text)
    var
        Json: JsonObject;
    begin
        Json := NavApp.GetResourceAsJson(Name);
    end;
}
