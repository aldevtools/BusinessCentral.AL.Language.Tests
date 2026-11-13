// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.text.regularexpressions.regex.replace
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 80012, reports 80013 - 80015 and helper codeunit 80016 of the Cloud app
//   (tests/al-language/reports/html-email-body/RxHtmlBodyFixtures.al); test codeunit 99005
// Probe: every literal asserted below is what the corpus CI matrix (BC 27.5, 28.5, 29.0 on Linux) produced; the three versions gave the same values.
// Facts (al-runner issue 6924): the exact call System Application codeunit 8905 "Email Message Impl." makes in ReplaceRgbaColorsWithRgb
//   (27.5, 28.1, 29.0: same code), Body := Regex.Replace(Body, Pattern, Replacement) on an uninitialised DotNet Regex variable, with a copy
//   of its pattern rgba\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*1(\.0{0,2})?\) and replacement rgb($1, $2, $3): on the Html of a Word
//   layout report saved with Report.SaveAs(..., ReportFormat::Html, OutStream) (generated layout with 1 and 3 rows, hand-built layout with
//   transparent colors), is the result equal to the input, of the same length, does Regex.IsMatch answer true; and on short plain texts,
//   what the result is.
// Results: the Word layout Html (generated and hand-built with transparent colors) holds no 'rgba(', IsMatch answers false and Replace returns
//   the same text, same length. Plain texts: the same answers as Email Message.Create in RxEmailBodyTests.al.
// BC versions: 27 - 29

codeunit 99005 "RX Regex Dn Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Html: Codeunit "RX Html Body";
        PatternTok: Label 'rgba\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*1(\.0{0,2})?\)', Locked = true;
        ReplacementTok: Label 'rgb($1, $2, $3)', Locked = true;

    local procedure Replaced(Body: Text): Text
    var
        Rx: DotNet RxDnRegex;
    begin
        Body := Rx.Replace(Body, PatternTok, ReplacementTok);
        exit(Body);
    end;

    local procedure IsMatch(Body: Text): Boolean
    var
        Rx: DotNet RxDnRegex;
    begin
        exit(Rx.IsMatch(Body, PatternTok));
    end;

    local procedure WordCell(var Observer: Codeunit "Probe Observer"; ReportId: Integer; RowCount: Integer; Name: Text)
    var
        Body: Text;
        Got: Text;
        Completed: Boolean;
        Ok: Boolean;
        Eos: Boolean;
    begin
        Html.Rows(RowCount);
        Html.Render(ReportId, Body, Completed, Ok, Eos);
        Observer.Observe(Name + ' returned', Format(Completed and Ok));
        Observer.Observe(Name + ' body <> empty', Format(Body <> ''));
        Observer.Observe(Name + ' body rgba( count', Format(Html.CountOf(Body, 'rgba(')));
        Observer.Observe(Name + ' IsMatch', Format(IsMatch(Body)));
        Got := Replaced(Body);
        Observer.Observe(Name + ' Replace = body', Format(Got = Body));
        Observer.Observe(Name + ' length equal', Format(StrLen(Got) = StrLen(Body)));
        Observer.Observe(Name + ' Replace rgba( count', Format(Html.CountOf(Got, 'rgba(')));
    end;

    [Test]
    procedure WordDefault_Replace_Unchanged()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Default", 1, 'word1');
        WordCell(Observer, Report::"RX Word Default", 3, 'word3');
        Observer.Expect('word1 returned', 'Yes');
        Observer.Expect('word1 body <> empty', 'Yes');
        Observer.Expect('word1 body rgba( count', '0');
        Observer.Expect('word1 IsMatch', 'No');
        Observer.Expect('word1 Replace = body', 'Yes');
        Observer.Expect('word1 length equal', 'Yes');
        Observer.Expect('word1 Replace rgba( count', '0');
        Observer.Expect('word3 returned', 'Yes');
        Observer.Expect('word3 body <> empty', 'Yes');
        Observer.Expect('word3 body rgba( count', '0');
        Observer.Expect('word3 IsMatch', 'No');
        Observer.Expect('word3 Replace = body', 'Yes');
        Observer.Expect('word3 length equal', 'Yes');
        Observer.Expect('word3 Replace rgba( count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure WordAlpha_Replace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WordCell(Observer, Report::"RX Word Alpha", 2, 'alpha');
        Observer.Expect('alpha returned', 'Yes');
        Observer.Expect('alpha body <> empty', 'Yes');
        Observer.Expect('alpha body rgba( count', '0');
        Observer.Expect('alpha IsMatch', 'No');
        Observer.Expect('alpha Replace = body', 'Yes');
        Observer.Expect('alpha length equal', 'Yes');
        Observer.Expect('alpha Replace rgba( count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_Replace_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('alpha 0.5', Replaced('x rgba(1,2,3,0.5) y'));
        Observer.Observe('alpha 1', Replaced('x rgba(1,2,3,1) y'));
        Observer.Observe('alpha 1.0 spaces', Replaced('x rgba(10, 20, 30, 1.0) y'));
        Observer.Observe('alpha 1.000', Replaced('x rgba(1,2,3,1.000) y'));
        Observer.Observe('upper', Replaced('RGBA(1,2,3,1)'));
        Observer.Observe('two', Replaced('rgba(1,2,3,1)rgba(4,5,6,1)'));
        Observer.Observe('empty', Replaced(''));
        Observer.Expect('alpha 0.5', 'x rgba(1,2,3,0.5) y');
        Observer.Expect('alpha 1', 'x rgb(1, 2, 3) y');
        Observer.Expect('alpha 1.0 spaces', 'x rgb(10, 20, 30) y');
        Observer.Expect('alpha 1.000', 'x rgba(1,2,3,1.000) y');
        Observer.Expect('upper', 'RGBA(1,2,3,1)');
        Observer.Expect('two', 'rgb(1, 2, 3)rgb(4, 5, 6)');
        Observer.Expect('empty', '');
        Observer.Verify();
    end;
}

dotnet
{
    assembly("netstandard")
    {
        type("System.Text.RegularExpressions.Regex"; RxDnRegex) { }
    }
}
