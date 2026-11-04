// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: none (reports, log and subscribers of the AM report output tests, AMReportOutputTests.al)
// Reports with one layout each (Word, Excel, RDLC), a request page field that flows into a column, an OnPreRendering trigger and
// Reporting Triggers subscribers that log only while the AM log is active. One layout file per report, each with its own name.
// BC versions: 27 - 29

codeunit 79250 "LT AM Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Active: Boolean;

    procedure Start()
    begin
        Entries := '';
        Active := true;
    end;

    procedure Stop()
    begin
        Active := false;
    end;

    procedure IsActive(): Boolean
    begin
        exit(Active);
    end;

    procedure Add(Entry: Text)
    begin
        if Active then
            Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        Active := false;
        exit(Result);
    end;
}

report 79251 "LT AM Word Rpt"
{
    DefaultRenderingLayout = LtAmWordLayout;

    dataset
    {
        dataitem(AmRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(AmNum; Number)
            {
            }
            column(AmReq; ReqText)
            {
            }
            column(AmMark; 'AMMARK')
            {
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqText; ReqText)
                {
                    ApplicationArea = All;
                    Caption = 'Request text';
                }
            }
        }
    }

    rendering
    {
        layout(LtAmWordLayout)
        {
            Type = Word;
            LayoutFile = './reports/layouts-saveas/LtAmWordLayout.docx';
        }
    }

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        Keys: Text;
        KeyName: Text;
    begin
        foreach KeyName in RenderingPayload.Keys() do
            Keys += KeyName + ',';
        AmLog.Add('OnPreRendering(' + Keys + ')');
    end;

    var
        AmLog: Codeunit "LT AM Log";
        ReqText: Text[30];
}

report 79252 "LT AM Excel Rpt"
{
    DefaultRenderingLayout = LtAmExcelLayout;

    dataset
    {
        dataitem(AmRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(AmNum; Number)
            {
            }
            column(AmReq; ReqText)
            {
            }
            column(AmMark; 'AMMARK')
            {
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqText; ReqText)
                {
                    ApplicationArea = All;
                    Caption = 'Request text';
                }
            }
        }
    }

    rendering
    {
        layout(LtAmExcelLayout)
        {
            Type = Excel;
            LayoutFile = './reports/layouts-saveas/LtAmExcelLayout.xlsx';
        }
    }

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        Keys: Text;
        KeyName: Text;
    begin
        foreach KeyName in RenderingPayload.Keys() do
            Keys += KeyName + ',';
        AmLog.Add('OnPreRendering(' + Keys + ')');
    end;

    var
        AmLog: Codeunit "LT AM Log";
        ReqText: Text[30];
}

report 79253 "LT AM Rdlc Rpt"
{
    DefaultRenderingLayout = LtAmRdlcLayout;

    dataset
    {
        dataitem(AmRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(AmNum; Number)
            {
            }
            column(AmReq; ReqText)
            {
            }
            column(AmMark; 'AMMARK')
            {
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ReqText; ReqText)
                {
                    ApplicationArea = All;
                    Caption = 'Request text';
                }
            }
        }
    }

    rendering
    {
        layout(LtAmRdlcLayout)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtAmRdlcLayout.rdlc';
        }
    }

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        Keys: Text;
        KeyName: Text;
    begin
        foreach KeyName in RenderingPayload.Keys() do
            Keys += KeyName + ',';
        AmLog.Add('OnPreRendering(' + Keys + ')');
    end;

    var
        AmLog: Codeunit "LT AM Log";
        ReqText: Text[30];
}

codeunit 79254 "LT AM Subscribers"
{
    var
        AmLog: Codeunit "LT AM Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure AmSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        if (ReportId < 79251) or (ReportId > 79253) then
            exit;
        AmLog.Add('SubstituteReport(' + Format(ReportId) + ',' + Format(RunMode) + ',req=' + Format(StrPos(RequestPageXml, 'AMREQ42') > 0) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure AmDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    begin
        if (ObjectId < 79251) or (ObjectId > 79253) then
            exit;
        // The document stream is not read here: reading it could change what the caller receives.
        AmLog.Add('OnDocumentReady(' + Format(ObjectId) + ',keys=' + Format(ObjectPayload.Keys().Count()) + ',documenttype=' + Value(ObjectPayload, 'documenttype') +
            ',layoutmimetype=' + Value(ObjectPayload, 'layoutmimetype') + ',layoutname=' + Value(ObjectPayload, 'layoutname') + ',objectname=' + Value(ObjectPayload, 'objectname') +
            ',success=' + Format(Success) + ')');
    end;

    local procedure Value(Payload: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Payload.Get(KeyName, Token) then
            exit('<absent>');
        if not Token.IsValue() then
            exit('<not a value>');
        exit(Token.AsValue().AsText());
    end;
}
