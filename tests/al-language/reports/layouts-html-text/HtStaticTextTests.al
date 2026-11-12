// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-howto-report-layout
// Scope: in-scope
// Fixtures used: Probe Observer (69160); HT S Row, HT Static Rpt, HT Empty Rpt and their Word layouts (HtStaticFixtures.al)
// Probe: written against the al-runtime-rs ADR-040 amendment of 2026-11-12, Part B section B5 (which fixed text of a Word layout reaches
//   the Html that Report.SaveAs writes). Each test saves a report as Html into a Temp Blob on a UTF-8 stream, reads it whole and asks
//   Body.Contains(<marker>) for the markers of one cell. For the characters BC escapes (C10 to C12) the text between two markers is
//   recorded too (at most 60 characters). Cells:
//   C1 plain body paragraph, C2 table cell, C3 page header and footer, C4 a content control bound to a constant column and its placeholder,
//   C5 static text inside the repeater with 2 rows and with 0 rows, C6 text after the repeater, C7 hidden run and hidden paragraph style,
//   C8 an unbound content control, C9 a word split over two runs, C10 & < >, C11 non-ASCII letters, C12 spaces (one, two, no-break, tab),
//   C13 text beside a DATE field, C14 text box and footnote, C15 case, C16 tracked insertion and deletion, C17 caps and small caps,
//   C18 character styles that hide or capitalize, C19 document defaults with caps, C20 rgba(..) text before and after Email Message.Create;
//   S1 to S4 which layout is used: default, a temporary selection by name, a user-defined Tenant Report Layout row named by a GUID,
//   a Tenant Report Layout Selection row. Layouts other than the default (HtExtras, HtDefaults, HtOther) are chosen with
//   Report Layout Selection.SetTempLayoutSelectedName before the save and cleared after it.
// Not measured yet: every test is in observe form (Observer.Finish), to be measured on a Windows tier and converted.
// BC versions: 27 - 29

codeunit 75225 "HT Static Text Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TenantLayoutNameTxt: Label '{8E3F1A52-6C0D-4B7E-A9F4-3D2C1B0A9E86}', Locked = true;

    local procedure Rows(N: Integer)
    var
        Row: Record "HT S Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to N do begin
            Row.Init();
            Row.Id := I;
            Row.Txt := 'HTROWTXT' + Format(I);
            Row.Insert();
        end;
    end;

    [TryFunction]
    local procedure TrySaveHtml(ReportId: Integer; var TempBlob: Codeunit "Temp Blob"; var Saved: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Saved := Report.SaveAs(ReportId, '', ReportFormat::Html, OutS);
    end;

    // Saves ReportId as Html, with LayoutName as a temporary selection when it is not empty, and records the answer.
    local procedure Save(var Observer: Codeunit "Probe Observer"; ReportId: Integer; LayoutName: Text[250]): Text
    var
        Selection: Record "Report Layout Selection";
        TempBlob: Codeunit "Temp Blob";
        Info: ModuleInfo;
        InS: InStream;
        Saved: Boolean;
        Ok: Boolean;
        Body: Text;
    begin
        if LayoutName <> '' then begin
            NavApp.GetCurrentModuleInfo(Info);
            Selection.SetTempLayoutSelectedName(LayoutName, Info.Id());
        end;
        ClearLastError();
        Ok := TrySaveHtml(ReportId, TempBlob, Saved);
        Selection.ClearTempLayoutSelected();
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('error');
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('length > 0', Format(TempBlob.Length() > 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Body);
        Observer.Observe('body <> empty', Format(Body <> ''));
        exit(Body);
    end;

    local procedure Has(var Observer: Codeunit "Probe Observer"; Body: Text; Marker: Text)
    begin
        Observer.Observe('contains ' + Marker, Format(Body.Contains(Marker)));
    end;

    local procedure Between(var Observer: Codeunit "Probe Observer"; Body: Text; FirstMarker: Text; SecondMarker: Text)
    var
        StartPos: Integer;
        EndPos: Integer;
        Part: Text;
    begin
        StartPos := Body.IndexOf(FirstMarker);
        if StartPos = 0 then begin
            Observer.Observe('between ' + FirstMarker, '<first marker absent>');
            exit;
        end;
        StartPos += StrLen(FirstMarker);
        Part := CopyStr(Body, StartPos);
        EndPos := Part.IndexOf(SecondMarker);
        if EndPos = 0 then begin
            Observer.Observe('between ' + FirstMarker, '<second marker absent>');
            exit;
        end;
        if EndPos > 61 then begin
            Observer.Observe('between ' + FirstMarker, '<more than 60 characters>');
            exit;
        end;
        Observer.Observe('between ' + FirstMarker, CopyStr(Part, 1, EndPos - 1));
    end;

    local procedure Occurrences(Body: Text; Marker: Text): Integer
    begin
        exit(Body.Split(Marker).Count() - 1);
    end;

    [Test]
    procedure Static_C1_C2_BodyParagraphAndTableCell()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTBODY1');
        Has(Observer, Body, 'HTCELL1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C3_HeaderAndFooter()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", 'HtExtras');
        Has(Observer, Body, 'HTEXTRASBODY1');
        Has(Observer, Body, 'HTHEADER1');
        Has(Observer, Body, 'HTFOOTER1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C4_BoundControlAndPlaceholder()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTCONST1');
        Has(Observer, Body, 'HTPLACEHOLDER1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C5_C6_RepeaterWithTwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Observer.Observe('HTINREPEAT1 occurrences', Format(Occurrences(Body, 'HTINREPEAT1')));
        Has(Observer, Body, 'HTROWTXT1');
        Has(Observer, Body, 'HTROWTXT2');
        Has(Observer, Body, 'HTAFTERREPEAT1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C5_C6_RepeaterWithNoRow()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Empty Rpt", '');
        Observer.Observe('HTINREPEAT1 occurrences', Format(Occurrences(Body, 'HTINREPEAT1')));
        Has(Observer, Body, 'HTROWTXT1');
        Has(Observer, Body, 'HTAFTERREPEAT1');
        Has(Observer, Body, 'HTBODY1');
        Has(Observer, Body, 'HTCONST1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C7_HiddenRunAndHiddenParagraphStyle()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTVISIBLE1');
        Has(Observer, Body, 'HTHIDDEN1');
        Has(Observer, Body, 'HTHIDDENSTYLE1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C8_UnboundContentControl()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTPLAINSDT1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C9_WordSplitOverTwoRuns()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTSPL');
        Has(Observer, Body, 'IT1');
        Has(Observer, Body, 'HTSPLIT1');
        Between(Observer, Body, 'HTSPL', 'IT1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C10_AmpersandLessGreater()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTAMP1 & HTAMP2');
        Has(Observer, Body, 'HTAMP1 &amp; HTAMP2');
        Between(Observer, Body, 'HTAMP1', 'HTAMP2');
        Has(Observer, Body, 'HTLT1 < HTLT2');
        Has(Observer, Body, 'HTLT1 &lt; HTLT2');
        Between(Observer, Body, 'HTLT1', 'HTLT2');
        Has(Observer, Body, 'HTGT1 > HTGT2');
        Has(Observer, Body, 'HTGT1 &gt; HTGT2');
        Between(Observer, Body, 'HTGT1', 'HTGT2');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C11_NonAsciiLetters()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
        Literal: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Literal := 'HTUML1 ' + Chr(228) + Chr(246) + Chr(252) + ' ' + Chr(233) + ' ' + Chr(8364) + ' HTUML2';
        Observer.Observe('contains literal letters', Format(Body.Contains(Literal)));
        Has(Observer, Body, 'HTUML1 &#228;&#246;&#252; &#233; &#8364; HTUML2');
        Has(Observer, Body, 'HTUML1 &auml;&ouml;&uuml; &eacute; &euro; HTUML2');
        Has(Observer, Body, 'HTUML1');
        Has(Observer, Body, 'HTUML2');
        Between(Observer, Body, 'HTUML1', 'HTUML2');
        Observer.Finish();
    end;

    local procedure Chr(Code: Integer): Text
    var
        C: Text[1];
    begin
        C := ' ';
        C[1] := Code;
        exit(C);
    end;

    [Test]
    procedure Static_C12_Spaces()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTSP1 HTSP2');
        Between(Observer, Body, 'HTSP1', 'HTSP2');
        Has(Observer, Body, 'HTSPTWO1  HTSPTWO2');
        Between(Observer, Body, 'HTSPTWO1', 'HTSPTWO2');
        Observer.Observe('contains HTSPNB1 nbsp HTSPNB2', Format(Body.Contains('HTSPNB1' + Chr(160) + 'HTSPNB2')));
        Has(Observer, Body, 'HTSPNB1&nbsp;HTSPNB2');
        Has(Observer, Body, 'HTSPNB1&#160;HTSPNB2');
        Has(Observer, Body, 'HTSPNB1 HTSPNB2');
        Has(Observer, Body, 'HTSPTAB1');
        Has(Observer, Body, 'HTSPTAB2');
        Observer.Observe('contains HTSPTAB1 tab HTSPTAB2', Format(Body.Contains('HTSPTAB1' + Chr(9) + 'HTSPTAB2')));
        Observer.Finish();
    end;

    [Test]
    procedure Static_C13_C14_FieldTextBoxFootnote()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", 'HtExtras');
        Has(Observer, Body, 'HTFIELD1');
        Has(Observer, Body, 'HTTEXTBOX1');
        Has(Observer, Body, 'HTNOTEANCHOR1');
        Has(Observer, Body, 'HTFOOTNOTE1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C15_Case()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTCase1');
        Has(Observer, Body, 'HTCASE1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C16_TrackedInsertionAndDeletion()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", 'HtExtras');
        Has(Observer, Body, 'HTKEEP1');
        Has(Observer, Body, 'HTINS1');
        Has(Observer, Body, 'HTDEL1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C17_CapsAndSmallCaps()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTCaps1');
        Has(Observer, Body, 'HTCAPS1');
        Has(Observer, Body, 'HTSmall1');
        Has(Observer, Body, 'HTSMALL1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C18_CharacterStyles()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTRSTYLEVIS1');
        Has(Observer, Body, 'HTRSTYLEHID1');
        Has(Observer, Body, 'HTRStyleCaps1');
        Has(Observer, Body, 'HTRSTYLECAPS1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C19_DocumentDefaultsCaps()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", 'HtDefaults');
        Has(Observer, Body, 'HTDefCaps1');
        Has(Observer, Body, 'HTDEFCAPS1');
        Has(Observer, Body, 'HTBODY1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_C20_RgbaBeforeAndAfterEmailMessage()
    var
        Observer: Codeunit "Probe Observer";
        Message: Codeunit "Email Message";
        Body: Text;
        Got: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTRGB1 rgba(1,2,3,1) HTRGB2');
        Between(Observer, Body, 'HTRGB1', 'HTRGB2');
        Between(Observer, Body, 'HTRGBS1', 'HTRGBS2');
        Message.Create('ht.probe@contoso.com', 'HT subject', Body, true);
        Got := Message.GetBody();
        Observer.Observe('GetBody <> empty', Format(Got <> ''));
        Observer.Observe('GetBody = body', Format(Got = Body));
        Has(Observer, Got, 'HTBODY1');
        Has(Observer, Got, 'rgba(1,2,3,1)');
        Has(Observer, Got, 'rgb(1, 2, 3)');
        Has(Observer, Got, 'rgb(1,2,3)');
        Between(Observer, Got, 'HTRGB1', 'HTRGB2');
        Between(Observer, Got, 'HTRGBS1', 'HTRGBS2');
        Observer.Finish();
    end;

    [Test]
    procedure Static_S1_DefaultLayout()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTBODY1');
        Has(Observer, Body, 'HTOTHERLAYOUT1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_S2_TempSelectionByName()
    var
        Observer: Codeunit "Probe Observer";
        Body: Text;
    begin
        Rows(2);
        Body := Save(Observer, Report::"HT Static Rpt", 'HtOther');
        Has(Observer, Body, 'HTBODY1');
        Has(Observer, Body, 'HTOTHERLAYOUT1');
        Observer.Finish();
    end;

    [Test]
    procedure Static_S3_UserDefinedRowByGuidName()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        LayoutList: Record "Report Layout List";
        Selection: Record "Report Layout Selection";
        TempBlob: Codeunit "Temp Blob";
        NullGuid: Guid;
        OutS: OutStream;
        InS: InStream;
        Saved: Boolean;
        Body: Text;
    begin
        Rows(2);
        Layout.SetRange("Report ID", Report::"HT Static Rpt");
        Layout.DeleteAll();
        Layout.Reset();
        LayoutList.SetRange("Report ID", Report::"HT Static Rpt");
        LayoutList.SetRange(Name, 'HtOther');
        Observer.Observe('HtOther in Report Layout List', Format(LayoutList.FindFirst()));
        TempBlob.CreateOutStream(OutS);
        LayoutList.Layout.ExportStream(OutS);
        Observer.Observe('HtOther layout exported', Format(TempBlob.Length() > 0));
        TempBlob.CreateInStream(InS);
        Layout.Init();
        Layout."Report ID" := Report::"HT Static Rpt";
        Layout.Name := TenantLayoutNameTxt;
        Layout."Layout Format" := Layout."Layout Format"::Word;
        Layout.Description := 'HT user-defined other layout';
        Layout.Layout.ImportStream(InS, 'HT user-defined other layout');
        Layout.Insert();
        Selection.SetTempLayoutSelectedName(TenantLayoutNameTxt, NullGuid);
        Clear(TempBlob);
        ClearLastError();
        Observer.Observe('ok', Format(TrySaveHtml(Report::"HT Static Rpt", TempBlob, Saved)));
        Observer.ObserveError('error');
        Selection.ClearTempLayoutSelected();
        Observer.Observe('saved', Format(Saved));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Body);
        Has(Observer, Body, 'HTBODY1');
        Has(Observer, Body, 'HTOTHERLAYOUT1');
        Layout.SetRange("Report ID", Report::"HT Static Rpt");
        Layout.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure Static_S4_TenantReportLayoutSelectionRow()
    var
        Observer: Codeunit "Probe Observer";
        LayoutSelection: Record "Tenant Report Layout Selection";
        Info: ModuleInfo;
        Body: Text;
    begin
        Rows(2);
        NavApp.GetCurrentModuleInfo(Info);
        LayoutSelection.SetRange("Report ID", Report::"HT Static Rpt");
        LayoutSelection.DeleteAll();
        LayoutSelection.Init();
        LayoutSelection."Report ID" := Report::"HT Static Rpt";
        LayoutSelection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(LayoutSelection."Company Name"));
        LayoutSelection."Layout Name" := 'HtOther';
        LayoutSelection."App ID" := Info.Id();
        LayoutSelection.Insert();
        Body := Save(Observer, Report::"HT Static Rpt", '');
        Has(Observer, Body, 'HTBODY1');
        Has(Observer, Body, 'HTOTHERLAYOUT1');
        LayoutSelection.SetRange("Report ID", Report::"HT Static Rpt");
        LayoutSelection.DeleteAll();
        Observer.Finish();
    end;
}
