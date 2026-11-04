// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-triggers
// Scope: in-scope
// Fixtures for codeunit 84549 "LT CH Report Leads" (ChReportLeads.al): table 84530, log codeunit 84531, reports 84532, 84535, 84536, 84538, 84540, 84542, 84544,
// report extensions 84537, 84539, 84541, 84543, page 84534. Corpus issue 667, items 117 to 126.

table 84530 "LT CH R Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Grp; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 84531 "LT CH R Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CurrentMode: Integer;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure SetMode(NewMode: Integer)
    begin
        CurrentMode := NewMode;
    end;

    procedure Mode(): Integer
    begin
        exit(CurrentMode);
    end;
}

// Item 122: Enabled of request page fields bound to report globals set in OnInitReport and in the request page OnOpenPage.
report 84532 "LT CH RP Enabled"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(OpenBound; OpenVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Open bound';
                        Enabled = OpenEnabled;
                    }
                    field(InitBound; InitVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Init bound';
                        Enabled = InitEnabled;
                    }
                    field(Plain; PlainVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Plain';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            OpenEnabled := Log.Mode() = 1;
            Log.Add('OnOpenPage openEnabled=' + Format(OpenEnabled) + ' initEnabled=' + Format(InitEnabled));
        end;
    }

    trigger OnInitReport()
    begin
        InitEnabled := Log.Mode() = 1;
    end;

    var
        Log: Codeunit "LT CH R Log";
        OpenVal: Integer;
        InitVal: Integer;
        PlainVal: Integer;
        OpenEnabled: Boolean;
        InitEnabled: Boolean;
}

// Item 117: a part on a request page, and a procedure of the part's page called from the request page and from the report.
page 84534 "LT CH RP Part"
{
    PageType = ListPart;
    SourceTable = "LT CH R Row";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure Ping(): Text
    begin
        exit('part ping count=' + Format(Rec.Count()));
    end;
}

// Item 118: an Error in the request page OnClosePage of a ProcessingOnly report.
report 84535 "LT CH RP CloseError"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Opt; OptVal) { ApplicationArea = All; Caption = 'Opt'; }
                }
            }
        }

        trigger OnClosePage()
        begin
            Log.Add('OnClosePage');
            Error('LT CH close error');
        end;
    }

    trigger OnInitReport()
    begin
        Log.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        Log.Add('OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('OnPostReport');
    end;

    var
        Log: Codeunit "LT CH R Log";
        OptVal: Integer;
}

// Item 123: the order of the report triggers, the data item triggers and OnPreRendering of a report and its extension, under SaveAs Xml; and CurrReport.Quit.
report 84536 "LT CH Order"
{
    UseRequestPage = false;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            column(Num; Number) { }

            trigger OnPreDataItem()
            begin
                Log.Add('base OnPreDataItem');
                if Log.Mode() = 2 then
                    CurrReport.Quit();
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('base OnAfterGetRecord ' + Format(Number));
            end;

            trigger OnPostDataItem()
            begin
                Log.Add('base OnPostDataItem');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Log.Add('base OnInitReport');
    end;

    trigger OnPreReport()
    begin
        Log.Add('base OnPreReport');
        if Log.Mode() = 1 then
            CurrReport.Quit();
    end;

    trigger OnPostReport()
    begin
        Log.Add('base OnPostReport');
    end;

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        Log.Add('base OnPreRendering');
    end;

    var
        Log: Codeunit "LT CH R Log";
}

reportextension 84537 "LT CH Order Ext" extends "LT CH Order"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                Log.Add('ext OnBeforePreDataItem');
            end;

            trigger OnAfterPreDataItem()
            begin
                Log.Add('ext OnAfterPreDataItem');
            end;

            trigger OnBeforeAfterGetRecord()
            begin
                Log.Add('ext OnBeforeAfterGetRecord ' + Format(Number));
            end;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('ext OnAfterAfterGetRecord ' + Format(Number));
            end;

            trigger OnBeforePostDataItem()
            begin
                Log.Add('ext OnBeforePostDataItem');
            end;

            trigger OnAfterPostDataItem()
            begin
                Log.Add('ext OnAfterPostDataItem');
            end;
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('ext OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('ext OnPostReport');
    end;

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        Log.Add('ext OnPreRendering');
    end;

    var
        Log: Codeunit "LT CH R Log";
}

// Item 120: RequestFilterFields of a data item set by a report extension (modify).
report 84538 "LT CH Filter Fields"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Items; "LT CH R Row")
        {
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                Log.Add('filters=[' + Items.GetFilters() + ']');
            end;
        }
    }

    var
        Log: Codeunit "LT CH R Log";
}

reportextension 84539 "LT CH Filter Fields Ext" extends "LT CH Filter Fields"
{
    dataset
    {
        modify(Items)
        {
            RequestFilterFields = Name;
        }
    }
}

// Item 119: SaveValues = true on the base request page, and a field the report extension adds (bound to an extension global).
report 84540 "LT CH SaveValues"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(BaseInt; BaseIntVal) { ApplicationArea = All; Caption = 'Base int'; }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('base OnPreReport int=' + Format(BaseIntVal));
    end;

    var
        Log: Codeunit "LT CH R Log";
        BaseIntVal: Integer;
}

reportextension 84541 "LT CH SaveValues Ext" extends "LT CH SaveValues"
{
    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(ExtBool; ExtBoolVal) { ApplicationArea = All; Caption = 'Ext bool'; }
                field(ExtText; ExtTextVal) { ApplicationArea = All; Caption = 'Ext text'; }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('ext OnPreReport bool=' + Format(ExtBoolVal) + ' text=' + ExtTextVal);
    end;

    var
        Log: Codeunit "LT CH R Log";
        ExtBoolVal: Boolean;
        ExtTextVal: Text[30];
}

// Items 124 and 125: request page triggers and field validation under Execute and SaveAs with parameters, and an OnOpenPage (base and extension) that assigns
// the option globals.
report 84542 "LT CH Params"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            begin
                Log.Add('OnPreDataItem opt=' + Format(OptVal));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Opt; OptVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Opt';

                        trigger OnValidate()
                        begin
                            Log.Add('Opt OnValidate ' + Format(OptVal));
                        end;
                    }
                }
            }
        }

        trigger OnInit()
        begin
            Log.Add('RP OnInit opt=' + Format(OptVal));
        end;

        trigger OnOpenPage()
        begin
            Log.Add('RP OnOpenPage opt=' + Format(OptVal));
            if Log.Mode() = 1 then
                OptVal := 99;
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            Log.Add('RP OnQueryClosePage ' + Format(CloseAction));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            Log.Add('RP OnClosePage opt=' + Format(OptVal));
        end;
    }

    trigger OnInitReport()
    begin
        Log.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        Log.Add('OnPreReport opt=' + Format(OptVal));
    end;

    var
        Log: Codeunit "LT CH R Log";
        OptVal: Integer;
}

reportextension 84543 "LT CH Params Ext" extends "LT CH Params"
{
    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(ExtOpt; ExtOptVal)
                {
                    ApplicationArea = All;
                    Caption = 'Ext opt';

                    trigger OnValidate()
                    begin
                        Log.Add('ExtOpt OnValidate ' + Format(ExtOptVal));
                    end;
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('ext OnOpenPage ext=' + Format(ExtOptVal));
            if Log.Mode() = 1 then
                ExtOptVal := 77;
        end;
    }

    trigger OnPreReport()
    begin
        Log.Add('ext OnPreReport ext=' + Format(ExtOptVal));
    end;

    var
        Log: Codeunit "LT CH R Log";
        ExtOptVal: Integer;
}

// Item 126: SaveValues = true, a Boolean option that OnOpenPage sets, the value the user enters, and what OnPreReport and OnPreDataItem see.
report 84544 "LT CH Lost Value"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            begin
                Log.Add('OnPreDataItem show=' + Format(ShowVal));
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Show; ShowVal) { ApplicationArea = All; Caption = 'Show'; }
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('OnOpenPage show=' + Format(ShowVal));
            ShowVal := true;
        end;
    }

    trigger OnPreReport()
    begin
        Log.Add('OnPreReport show=' + Format(ShowVal));
    end;

    var
        Log: Codeunit "LT CH R Log";
        ShowVal: Boolean;
}
