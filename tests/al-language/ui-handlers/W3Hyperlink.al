//sub:handlers
// Hyperlink in a test run (md:405).

codeunit 67762 "W3 Hyperlink Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;
        Runner: Codeunit "W3 Runner";

    [TryFunction]
    local procedure TryLink(Url: Text)
    begin
        Hyperlink(Url);
    end;

    [HyperlinkHandler]
    procedure LinkHandler(Link: Text[1024])
    begin
        Seen += '[' + Link + ']';
    end;

    // With a handler: is it called, with which text.
    [Test]
    [HandlerFunctions('LinkHandler')]
    procedure Hyperlink_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Observer.Observe('ok', Format(TryLink('https://example.invalid/w3?a=1&b=two words')));
        Observer.ObserveError('error');
        Observer.Observe('handler saw', Seen);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('handler saw', '[https://example.invalid/w3?a=1&b=two words]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LinkHandler')]
    procedure Hyperlink_WithHandler_EmptyAndMailtoUrl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Observer.Observe('empty: ok', Format(TryLink('')));
        Observer.ObserveError('empty');
        Observer.Observe('empty: handler saw', Seen);
        Seen := '';
        Observer.Observe('mailto: ok', Format(TryLink('mailto:someone@example.invalid')));
        Observer.ObserveError('mailto');
        Observer.Observe('mailto: handler saw', Seen);
        Observer.Expect('empty: ok', 'Yes');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('empty: handler saw', '[]');
        Observer.Expect('mailto: ok', 'Yes');
        Observer.Expect('mailto|text', '');
        Observer.Expect('mailto|code', '');
        Observer.Expect('mailto: handler saw', '[mailto:someone@example.invalid]');
        Observer.Verify();
    end;

    // Without a handler: nothing, an error, or an unhandled UI message.
    [Test]
    procedure Hyperlink_WithoutHandler()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Commit();
        Ok := Runner.Exec(0, 6, 'https://example.invalid/w3', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Unhandled UI: Hyperlink https://example.invalid/w3');
        Observer.Expect('error|code', 'MissingUIHandler');
        Observer.Verify();
    end;
}
