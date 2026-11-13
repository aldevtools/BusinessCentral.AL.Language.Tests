// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table, reports and helper of RxHtmlBodyFixtures.al (80012 - 80016); test codeunit 80017
// Probe: observe form; the values come from the corpus CI matrix of this pull request.
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
        Observer.Finish();
    end;

    [Test]
    procedure WordDefault_ThreeRows_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Default", 3, 'word3');
        Observer.Finish();
    end;

    [Test]
    procedure WordDefault_NoRow_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Default", 0, 'word0');
        Observer.Finish();
    end;

    [Test]
    procedure WordAlpha_TransparentColors_EmailBody()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Alpha", 2, 'alpha');
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
