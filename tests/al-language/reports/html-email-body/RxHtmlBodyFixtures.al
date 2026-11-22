// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: none; shared by test codeunit 80017 (this app) and test codeunit 99005 (tests/al-language-onprem-dotnet)
// Facts: the table, the three reports and the helper of the Html email body probes (al-runner issue 6924).
//   RX Word Default: a Word layout the AL compiler generates (RxWordDefault.docx is not committed; no colors).
//   RX Word Alpha: a hand-built Word layout (RxWordAlpha.docx) whose text uses colors with transparency (w14:textFill with
//   w14:alpha), a run color, a paragraph shading and a table cell shading.
//   RX Rdlc: an RDLC layout the AL compiler generates (RxRdlc.rdl is not committed).
// local object: the reports' own layouts (generated, hand-built with transparent colors, RDLC) and their dataset table are what the tests check.
// BC versions: 27 - 29

table 80012 "RX Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 80013 "RX Word Default"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWordDefault;

    dataset
    {
        dataitem(Row; "RX Row")
        {
            column(RowId; Id) { }
            column(RowTxt; Txt) { }
        }
    }

    rendering
    {
        layout(RxWordDefault)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWordDefault.docx';
        }
    }
}

report 80014 "RX Word Alpha"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxWordAlpha;

    dataset
    {
        dataitem(Row; "RX Row")
        {
            column(RowId; Id) { }
            column(RowTxt; Txt) { }
        }
    }

    rendering
    {
        layout(RxWordAlpha)
        {
            Type = Word;
            LayoutFile = './reports/html-email-body/RxWordAlpha.docx';
        }
    }
}

report 80015 "RX Rdlc"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = RxRdlc;

    dataset
    {
        dataitem(Row; "RX Row")
        {
            column(RowId; Id) { }
            column(RowTxt; Txt) { }
        }
    }

    rendering
    {
        layout(RxRdlc)
        {
            Type = RDLC;
            LayoutFile = './reports/html-email-body/RxRdlc.rdl';
        }
    }
}

codeunit 80016 "RX Html Body"
{
    procedure Rows(N: Integer)
    var
        Row: Record "RX Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to N do begin
            Row.Init();
            Row.Id := I;
            Row.Txt := 'RXROW' + Format(I);
            Row.Insert();
        end;
    end;

    [TryFunction]
    local procedure TrySave(ReportId: Integer; var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Ok := Report.SaveAs(ReportId, '', ReportFormat::Html, OutS);
    end;

    // Saves the report as Html into a Temp Blob and reads the whole text back with one InStream.Read (as Email Message Impl. reads a body).
    procedure Render(ReportId: Integer; var Body: Text; var Completed: Boolean; var Ok: Boolean; var Eos: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Body := '';
        ClearLastError();
        Completed := TrySave(ReportId, TempBlob, Ok);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Body);
        Eos := InS.EOS();
    end;

    procedure CountOf(Value: Text; Part: Text) N: Integer
    var
        P: Integer;
    begin
        P := StrPos(Value, Part);
        while P > 0 do begin
            N += 1;
            Value := CopyStr(Value, P + StrLen(Part));
            P := StrPos(Value, Part);
        end;
    end;
}
