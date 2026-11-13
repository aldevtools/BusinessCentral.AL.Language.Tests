// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table, reports and helper of RxHtmlBodyFixtures.al (80012 - 80016); test codeunit 80017
// Probe: every literal asserted below is what the corpus CI matrix (BC 27.5, 28.5, 29.0 on Linux) produced; the three versions gave the same values.
// Facts (al-runner issue 6924): Email Message.Create runs the body through Email Message Impl. ReplaceRgbaColorsWithRgb, a DotNet
//   Regex.Replace with the pattern rgba\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*1(\.0{0,2})?\) and the replacement rgb($1, $2, $3)
//   (System Application 27.5, 28.1 and 29.0: same code; SetBodyValue calls it for every non-empty body, Html or not; SetBody and
//   AppendToBody go through it too). Asked here:
//   - the Html of a Word layout report saved with Report.SaveAs(..., ReportFormat::Html, OutStream) and read whole: does it contain
//     'rgba(' or 'rgb(', and does GetBody after Create(..., true) and Create(..., false) give the same text
//     and the same length; for the generated layout with 0, 1 and 3 rows and for a hand-built layout with transparent colors;
//   - Create(..., true, true) (Sanitize) of the generated layout's Html: GetBody equal to the body or not;
//   - the RDLC layout saved as Html: what SaveAs answers and what the stream holds;
//   - plain bodies with rgba(...) texts: the GetBody text after Create with Html true and false, SetBody and AppendToBody.
// Results:
//   - Word layout Html (generated layout, 1 and 3 rows; hand-built layout with w14:alpha transparent text, run color, highlight, run, paragraph,
//     table and cell shading, 2 rows): no 'rgba(' and no 'rgb(' in the Html; GetBody equals the body, same length, Html true and false.
//     With 0 rows SaveAs Html answers false (ReportResultEmpty) and writes nothing; the empty body gives an empty GetBody.
//   - Create(..., true, true) (Sanitize) changes the Word layout Html: GetBody differs from the body and is not empty.
//   - RDLC layout: SaveAs Html answers false, ReportUnsupportedFormat, nothing written.
//   - Plain bodies: only alpha 1, 1., 1.0 and 1.00 are replaced, by rgb(r, g, b) with ', ' separators, Html true and false alike; whitespace
//     (space, tab, CR LF) after a comma is allowed; alpha 0, 0.5, 10, 1.5, 1.000, upper case RGBA, four digits, a space after '(' or before
//     a comma, three parts, and rgb( stay unchanged. SetBody and AppendToBody replace the same way.
// The same Regex.Replace called directly on DotNet Regex: tests/al-language-onprem-dotnet/dotnet/html-email-body/RxRegexDnTests.al.
// BC versions: 27 - 29

codeunit 80017 "RX Email Body Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Html: Codeunit "RX Html Body";
        ToTxt: Label 'rx.probe@contoso.com', Locked = true;

    local procedure ObserveBody(var Observer: Codeunit "Probe Observer"; Name: Text; Body: Text)
    var
        MsgHtml: Codeunit "Email Message";
        MsgPlain: Codeunit "Email Message";
        Got: Text;
    begin
        Observer.Observe(Name + ' body <> empty', Format(Body <> ''));
        Observer.Observe(Name + ' body rgba( count', Format(Html.CountOf(Body, 'rgba(')));
        Observer.Observe(Name + ' body rgb( count', Format(Html.CountOf(Body, 'rgb(')));
        MsgHtml.Create(ToTxt, 'RX subject', Body, true);
        Got := MsgHtml.GetBody();
        Observer.Observe(Name + ' html GetBody = body', Format(Got = Body));
        Observer.Observe(Name + ' html length equal', Format(StrLen(Got) = StrLen(Body)));
        Observer.Observe(Name + ' html GetBody rgba( count', Format(Html.CountOf(Got, 'rgba(')));
        Observer.Observe(Name + ' html GetBody rgb( count', Format(Html.CountOf(Got, 'rgb(')));
        MsgPlain.Create(ToTxt, 'RX subject', Body, false);
        Got := MsgPlain.GetBody();
        Observer.Observe(Name + ' plain GetBody = body', Format(Got = Body));
        Observer.Observe(Name + ' plain length equal', Format(StrLen(Got) = StrLen(Body)));
    end;

    local procedure WordCell(var Observer: Codeunit "Probe Observer"; ReportId: Integer; RowCount: Integer; Name: Text)
    var
        Body: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(RowCount);
        Html.Render(ReportId, Body, Completed, Ok, Eos);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.Observe(Name + ' returned', Format(Ok));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name + ' eos after read', Format(Eos));
        Observer.Observe(Name + ' starts <html', Format(LowerCase(CopyStr(Body, 1, 5)) = '<html'));
        ObserveBody(Observer, Name, Body);
    end;

    local procedure PlainCell(var Observer: Codeunit "Probe Observer"; Name: Text; Body: Text)
    var
        MsgHtml: Codeunit "Email Message";
        MsgPlain: Codeunit "Email Message";
    begin
        MsgHtml.Create(ToTxt, 'RX subject', Body, true);
        Observer.Observe(Name + ' html', MsgHtml.GetBody());
        MsgPlain.Create(ToTxt, 'RX subject', Body, false);
        Observer.Observe(Name + ' plain', MsgPlain.GetBody());
    end;

    [Test]
    procedure WordDefault_OneRow_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Default", 1, 'word1');
        Observer.Expect('word1 completed', 'Yes');
        Observer.Expect('word1 returned', 'Yes');
        Observer.Expect('word1 err|text', '');
        Observer.Expect('word1 err|code', '');
        Observer.Expect('word1 eos after read', 'Yes');
        Observer.Expect('word1 starts <html', 'Yes');
        Observer.Expect('word1 body <> empty', 'Yes');
        Observer.Expect('word1 body rgba( count', '0');
        Observer.Expect('word1 body rgb( count', '0');
        Observer.Expect('word1 html GetBody = body', 'Yes');
        Observer.Expect('word1 html length equal', 'Yes');
        Observer.Expect('word1 html GetBody rgba( count', '0');
        Observer.Expect('word1 html GetBody rgb( count', '0');
        Observer.Expect('word1 plain GetBody = body', 'Yes');
        Observer.Expect('word1 plain length equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WordDefault_ThreeRows_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Default", 3, 'word3');
        Observer.Expect('word3 completed', 'Yes');
        Observer.Expect('word3 returned', 'Yes');
        Observer.Expect('word3 err|text', '');
        Observer.Expect('word3 err|code', '');
        Observer.Expect('word3 eos after read', 'Yes');
        Observer.Expect('word3 starts <html', 'Yes');
        Observer.Expect('word3 body <> empty', 'Yes');
        Observer.Expect('word3 body rgba( count', '0');
        Observer.Expect('word3 body rgb( count', '0');
        Observer.Expect('word3 html GetBody = body', 'Yes');
        Observer.Expect('word3 html length equal', 'Yes');
        Observer.Expect('word3 html GetBody rgba( count', '0');
        Observer.Expect('word3 html GetBody rgb( count', '0');
        Observer.Expect('word3 plain GetBody = body', 'Yes');
        Observer.Expect('word3 plain length equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WordDefault_NoRow_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Default", 0, 'word0');
        Observer.Expect('word0 completed', 'Yes');
        Observer.Expect('word0 returned', 'No');
        Observer.Expect('word0 err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('word0 err|code', 'ReportResultEmpty');
        Observer.Expect('word0 eos after read', 'Yes');
        Observer.Expect('word0 starts <html', 'No');
        Observer.Expect('word0 body <> empty', 'No');
        Observer.Expect('word0 body rgba( count', '0');
        Observer.Expect('word0 body rgb( count', '0');
        Observer.Expect('word0 html GetBody = body', 'Yes');
        Observer.Expect('word0 html length equal', 'Yes');
        Observer.Expect('word0 html GetBody rgba( count', '0');
        Observer.Expect('word0 html GetBody rgb( count', '0');
        Observer.Expect('word0 plain GetBody = body', 'Yes');
        Observer.Expect('word0 plain length equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WordAlpha_TransparentColors_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Alpha", 2, 'alpha');
        Observer.Expect('alpha completed', 'Yes');
        Observer.Expect('alpha returned', 'Yes');
        Observer.Expect('alpha err|text', '');
        Observer.Expect('alpha err|code', '');
        Observer.Expect('alpha eos after read', 'Yes');
        Observer.Expect('alpha starts <html', 'Yes');
        Observer.Expect('alpha body <> empty', 'Yes');
        Observer.Expect('alpha body rgba( count', '0');
        Observer.Expect('alpha body rgb( count', '0');
        Observer.Expect('alpha html GetBody = body', 'Yes');
        Observer.Expect('alpha html length equal', 'Yes');
        Observer.Expect('alpha html GetBody rgba( count', '0');
        Observer.Expect('alpha html GetBody rgb( count', '0');
        Observer.Expect('alpha plain GetBody = body', 'Yes');
        Observer.Expect('alpha plain length equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WordDefault_Sanitized_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Msg: Codeunit "Email Message";
        Body: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(1);
        Html.Render(Report::"RX Word Default", Body, Completed, Ok, Eos);
        Msg.Create(ToTxt, 'RX subject', Body, true, true);
        Observer.Observe('sanitized GetBody = body', Format(Msg.GetBody() = Body));
        Observer.Observe('sanitized GetBody <> empty', Format(Msg.GetBody() <> ''));
        Observer.Expect('sanitized GetBody = body', 'No');
        Observer.Expect('sanitized GetBody <> empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rdlc_SaveAsHtml_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(1);
        Html.Render(Report::"RX Rdlc", Body, Completed, Ok, Eos);
        Observer.Observe('rdlc completed', Format(Completed));
        Observer.Observe('rdlc returned', Format(Ok));
        Observer.ObserveError('rdlc err');
        Observer.Observe('rdlc body length', Format(StrLen(Body)));
        Observer.Observe('rdlc body rgba( count', Format(Html.CountOf(Body, 'rgba(')));
        Observer.Expect('rdlc completed', 'Yes');
        Observer.Expect('rdlc returned', 'No');
        Observer.Expect('rdlc err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('rdlc err|code', 'ReportUnsupportedFormat');
        Observer.Expect('rdlc body length', '0');
        Observer.Expect('rdlc body rgba( count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_AlphaNotOne_Unchanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'alpha 0.5', 'x rgba(1,2,3,0.5) y');
        PlainCell(Observer, 'alpha 0', 'x rgba(1,2,3,0) y');
        PlainCell(Observer, 'alpha 10', 'x rgba(1,2,3,10) y');
        PlainCell(Observer, 'alpha 1.000', 'x rgba(1,2,3,1.000) y');
        PlainCell(Observer, 'alpha 1.5', 'x rgba(1,2,3,1.5) y');
        Observer.Expect('alpha 0.5 html', 'x rgba(1,2,3,0.5) y');
        Observer.Expect('alpha 0.5 plain', 'x rgba(1,2,3,0.5) y');
        Observer.Expect('alpha 0 html', 'x rgba(1,2,3,0) y');
        Observer.Expect('alpha 0 plain', 'x rgba(1,2,3,0) y');
        Observer.Expect('alpha 10 html', 'x rgba(1,2,3,10) y');
        Observer.Expect('alpha 10 plain', 'x rgba(1,2,3,10) y');
        Observer.Expect('alpha 1.000 html', 'x rgba(1,2,3,1.000) y');
        Observer.Expect('alpha 1.000 plain', 'x rgba(1,2,3,1.000) y');
        Observer.Expect('alpha 1.5 html', 'x rgba(1,2,3,1.5) y');
        Observer.Expect('alpha 1.5 plain', 'x rgba(1,2,3,1.5) y');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_AlphaOne_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'alpha 1', 'x rgba(1,2,3,1) y');
        PlainCell(Observer, 'alpha 1.', 'x rgba(1,2,3,1.) y');
        PlainCell(Observer, 'alpha 1.0 spaces', 'x rgba(10, 20, 30, 1.0) y');
        PlainCell(Observer, 'alpha 1.00', 'x rgba(255,255,255,1.00) y');
        PlainCell(Observer, 'two', 'rgba(1,2,3,1)rgba(4,5,6,1)');
        PlainCell(Observer, 'css', '<p style="color:rgba(0,128,0,1);">t</p>');
        Observer.Expect('alpha 1 html', 'x rgb(1, 2, 3) y');
        Observer.Expect('alpha 1 plain', 'x rgb(1, 2, 3) y');
        Observer.Expect('alpha 1. html', 'x rgb(1, 2, 3) y');
        Observer.Expect('alpha 1. plain', 'x rgb(1, 2, 3) y');
        Observer.Expect('alpha 1.0 spaces html', 'x rgb(10, 20, 30) y');
        Observer.Expect('alpha 1.0 spaces plain', 'x rgb(10, 20, 30) y');
        Observer.Expect('alpha 1.00 html', 'x rgb(255, 255, 255) y');
        Observer.Expect('alpha 1.00 plain', 'x rgb(255, 255, 255) y');
        Observer.Expect('two html', 'rgb(1, 2, 3)rgb(4, 5, 6)');
        Observer.Expect('two plain', 'rgb(1, 2, 3)rgb(4, 5, 6)');
        Observer.Expect('css html', '<p style="color:rgb(0, 128, 0);">t</p>');
        Observer.Expect('css plain', '<p style="color:rgb(0, 128, 0);">t</p>');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_NoMatch_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PlainCell(Observer, 'upper', 'RGBA(1,2,3,1)');
        PlainCell(Observer, 'four digits', 'rgba(1234,2,3,1)');
        PlainCell(Observer, 'space after paren', 'rgba( 1,2,3,1)');
        PlainCell(Observer, 'space before comma', 'rgba(1 ,2,3,1)');
        PlainCell(Observer, 'three parts', 'rgba(1,2,3)');
        PlainCell(Observer, 'rgb', 'rgb(1,2,3)');
        Observer.Expect('upper html', 'RGBA(1,2,3,1)');
        Observer.Expect('upper plain', 'RGBA(1,2,3,1)');
        Observer.Expect('four digits html', 'rgba(1234,2,3,1)');
        Observer.Expect('four digits plain', 'rgba(1234,2,3,1)');
        Observer.Expect('space after paren html', 'rgba( 1,2,3,1)');
        Observer.Expect('space after paren plain', 'rgba( 1,2,3,1)');
        Observer.Expect('space before comma html', 'rgba(1 ,2,3,1)');
        Observer.Expect('space before comma plain', 'rgba(1 ,2,3,1)');
        Observer.Expect('three parts html', 'rgba(1,2,3)');
        Observer.Expect('three parts plain', 'rgba(1,2,3)');
        Observer.Expect('rgb html', 'rgb(1,2,3)');
        Observer.Expect('rgb plain', 'rgb(1,2,3)');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_Whitespace_Forms()
    var
        Observer: Codeunit "Probe Observer";
        CrLf: Text[2];
        Tab: Text[1];
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
        Tab[1] := 9;
        PlainCell(Observer, 'crlf', 'rgba(1,' + CrLf + '2,3,1)');
        PlainCell(Observer, 'tab', 'rgba(1,' + Tab + '2,3,1)');
        PlainCell(Observer, 'line around', 'a' + CrLf + 'rgba(1,2,3,1)' + CrLf + 'b');
        Observer.Expect('crlf html', 'rgb(1, 2, 3)');
        Observer.Expect('crlf plain', 'rgb(1, 2, 3)');
        Observer.Expect('tab html', 'rgb(1, 2, 3)');
        Observer.Expect('tab plain', 'rgb(1, 2, 3)');
        Observer.Expect('line around html', 'a\r\nrgb(1, 2, 3)\r\nb');
        Observer.Expect('line around plain', 'a\r\nrgb(1, 2, 3)\r\nb');
        Observer.Verify();
    end;

    [Test]
    procedure SetBody_AppendToBody_Replace()
    var
        Observer: Codeunit "Probe Observer";
        Msg: Codeunit "Email Message";
        Empty: Codeunit "Email Message";
    begin
        Msg.Create(ToTxt, 'RX subject', 'start', true);
        Msg.SetBody('rgba(1,2,3,1)');
        Observer.Observe('SetBody', Msg.GetBody());
        Msg.AppendToBody(' rgba(4,5,6,1.0)');
        Observer.Observe('AppendToBody', Msg.GetBody());
        Msg.AppendToBody(' rgba(7,8,9,0.5)');
        Observer.Observe('AppendToBody alpha 0.5', Msg.GetBody());
        Empty.Create(ToTxt, 'RX subject', '', true);
        Observer.Observe('empty body', Empty.GetBody());
        Observer.Expect('SetBody', 'rgb(1, 2, 3)');
        Observer.Expect('AppendToBody', 'rgb(1, 2, 3) rgb(4, 5, 6)');
        Observer.Expect('AppendToBody alpha 0.5', 'rgb(1, 2, 3) rgb(4, 5, 6) rgba(7,8,9,0.5)');
        Observer.Expect('empty body', '');
        Observer.Verify();
    end;
}
