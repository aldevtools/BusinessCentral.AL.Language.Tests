// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500), LT Y Seen (75501); own table 75530, reports 75531-75540, page 75541, test codeunit 75512
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: properties of a report request page that has a source table: SourceTableView and SourceTableTemporary (seen in OnOpenPage), DeleteAllowed and ModifyAllowed (TestRequestPage Delete and SetValue),
// AutoSplitKey and MultipleNewLines (key of a new line, TestRequestPage New), DataCaptionFields and DataCaptionExpression (TestRequestPage Caption), CardPageId, LinksAllowed, PopulateAllFields, HelpLink.
// ContextSensitiveHelpPage needs the manifest property contextSensitiveHelpUrl and cannot be set together with HelpLink (must-not-compile cases 0812 and 0813).
// BC versions: 27-29

table 75530 "LT Y Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DocNo; Code[10]) { }
        field(2; LineNo; Integer) { }
        field(3; Descr; Text[30]) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; DocNo, LineNo) { Clustered = true; }
    }
}

page 75541 "LT Y RP Card"
{
    PageType = Card;
    SourceTable = "LT Y Line";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(DocNoCard; Rec.DocNo) { ApplicationArea = All; }
        }
    }
}

report 75531 "LT Y RP View"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        SourceTableView = sorting(DocNo, LineNo) where(DocNo = const('A'));

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Seen: Codeunit "LT Y Seen";
        begin
            Seen.Put('view', Rec.GetView());
            Seen.Put('filters', Rec.GetFilters());
            Seen.Put('count', Format(Rec.Count()));
            Seen.Put('temporary', Format(Rec.IsTemporary()));
        end;
    }
}

report 75532 "LT Y RP Temp"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        SourceTableTemporary = true;

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        var
            Seen: Codeunit "LT Y Seen";
        begin
            Seen.Put('temporary', Format(Rec.IsTemporary()));
            Seen.Put('count_before', Format(Rec.Count()));
            Rec.Init();
            Rec.DocNo := 'T';
            Rec.LineNo := 1;
            Rec.Insert();
            Seen.Put('count_after', Format(Rec.Count()));
        end;
    }
}

report 75533 "LT Y RP Locked"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        DeleteAllowed = false;
        ModifyAllowed = false;
        InsertAllowed = false;

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

report 75534 "LT Y RP Open"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        DeleteAllowed = true;
        ModifyAllowed = true;
        InsertAllowed = true;

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

report 75535 "LT Y RP Caption Fields"
{
    UsageCategory = None;
    ProcessingOnly = true;
    Caption = 'LT Y request';

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        DataCaptionFields = DocNo, Descr;

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }
    }
}

report 75536 "LT Y RP Caption Expr"
{
    UsageCategory = None;
    ProcessingOnly = true;
    Caption = 'LT Y request';

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        DataCaptionExpression = 'Expression caption';

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }
    }
}

report 75537 "LT Y RP Split"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        SourceTableView = sorting(DocNo, LineNo);
        AutoSplitKey = true;
        MultipleNewLines = true;

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
                field(LineNoCtl; Rec.LineNo) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

report 75538 "LT Y RP NoSplit"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        SourceTableView = sorting(DocNo, LineNo);

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
                field(LineNoCtl; Rec.LineNo) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

report 75539 "LT Y RP Misc"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        CardPageId = "LT Y RP Card";
        LinksAllowed = false;
        PopulateAllFields = true;
        HelpLink = 'https://example.com/lt-y-request-page';

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }
    }
}

report 75540 "LT Y RP Links"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Line; "LT Y Line") { }
    }

    requestpage
    {
        SourceTable = "LT Y Line";
        LinksAllowed = true;

        layout
        {
            area(Content)
            {
                field(DocNoCtl; Rec.DocNo) { ApplicationArea = All; }
            }
        }
    }
}
