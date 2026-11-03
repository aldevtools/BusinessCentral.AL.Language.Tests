// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); this file holds the shared own objects of the PnB probes (tables 70527-70529, report 70530, log codeunits 70572-70574, enum 70532)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Probes-needed rows: none (fixtures only)
// BC versions: 29 (27 and 28 by CI)

table 70527 "LT PnB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            begin
                LogCu.Add('Name.OnValidate:' + Format(CurrFieldNo));
            end;
        }
        field(3; Amount; Decimal)
        {
            trigger OnValidate()
            begin
                LogCu.Add('Amount.OnValidate:' + Format(CurrFieldNo));
            end;
        }
        field(4; "Parent Id"; Integer) { }
        field(5; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
            OptionCaption = 'Nil,Uno,Dos';
        }
        field(6; Flag; Boolean) { }
        field(7; Dur; Duration) { }
        field(8; DF; DateFormula) { }
        field(9; Dt; Date) { }
        field(10; Gd; Guid) { }
    }

    keys
    {
        key(PK; Id) { }
        key(ByName; Name) { }
        key(ByAmount; Amount, Name) { }
    }

    var
        LogCu: Codeunit "LT PnB Log 2";
}

table 70528 "LT PnB Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { }
    }
}

table 70529 "LT PnB Auto"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { }
    }
}

report 70530 "LT PnB Rep"
{
    Caption = 'LT PnB Caption';

    dataset
    {
        dataitem(Rows; "LT PnB Row")
        {
            DataItemTableView = sorting(Id) where("Parent Id" = const(0));
            column(RowId; Id) { }
            column(RowName; Name) { }
            column(RowAmount; Amount) { }
            column(RowTag; Tag) { }
            column(ColSpaced; Id) { }
            dataitem("Kid Item (Table)"; "LT PnB Row")
            {
                DataItemLink = "Parent Id" = field(Id);
                DataItemTableView = sorting(Id);
                column(KidId; Id) { }
            }
            trigger OnAfterGetRecord()
            begin
                if (SkipId <> 0) and (Id = SkipId) then
                    CurrReport.Skip();
                if (BreakId <> 0) and (Id = BreakId) then
                    CurrReport.Break();
                Tag := 'T' + Format(Id);
                LogCu.Add('Row' + Format(Id));
            end;
        }
        dataitem(TempItem; "LT PnB Row")
        {
            UseTemporary = true;
            column(TmpId; Id) { }
            trigger OnPreDataItem()
            begin
                TempInfo := Format(TempItem.IsTemporary()) + '/' + Format(TempItem.Count());
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Opts)
                {
                    field(Prefix; Prefix) { ApplicationArea = All; }
                    field(Flag; FlagVar) { ApplicationArea = All; }
                    field(Pick; Pick) { ApplicationArea = All; }
                    field(Num; Num) { ApplicationArea = All; }
                    field(When; When) { ApplicationArea = All; }
                    field(Amt; Amt) { ApplicationArea = All; }
                }
            }
        }
        actions
        {
            area(Processing)
            {
                action(StampText)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                        Prefix := 'stamped';
                    end;
                }
            }
        }
        trigger OnInit()
        begin
            LogCu.Add('RP.OnInit');
        end;

        trigger OnOpenPage()
        begin
            LogCu.Add('RP.OnOpenPage');
        end;

        trigger OnClosePage()
        begin
            LogCu.Add('RP.OnClosePage');
        end;
    }

    trigger OnInitReport()
    begin
        LogCu.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        LogCu.Add('OnPreReport:' + Prefix);
        if FailPre then
            Error('PnB pre-report error');
    end;

    trigger OnPostReport()
    begin
        LogCu.Add('OnPostReport');
    end;

    procedure SetSkip(Id: Integer)
    begin
        SkipId := Id;
    end;

    procedure SetBreak(Id: Integer)
    begin
        BreakId := Id;
    end;

    procedure SetFailPre()
    begin
        FailPre := true;
    end;

    procedure GetTempInfo(): Text
    begin
        exit(TempInfo);
    end;

    procedure GetPrefix(): Text
    begin
        exit(Prefix);
    end;

    procedure SetPrefix(NewPrefix: Text)
    begin
        Prefix := NewPrefix;
    end;

    var
        LogCu: Codeunit "LT PnB Log 1";
        Tag: Text;
        Prefix: Text;
        FlagVar: Boolean;
        Pick: Option A,B,C;
        Num: Integer;
        When: Date;
        Amt: Decimal;
        SkipId: Integer;
        BreakId: Integer;
        FailPre: Boolean;
        TempInfo: Text;
}

codeunit 70572 "LT PnB Log 1"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        E: Text;
    begin
        foreach E in Entries do begin
            if Result <> '' then
                Result += ',';
            Result += E;
        end;
        exit(Result);
    end;
}

codeunit 70573 "LT PnB Log 2"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        E: Text;
    begin
        foreach E in Entries do begin
            if Result <> '' then
                Result += ',';
            Result += E;
        end;
        exit(Result);
    end;
}

codeunit 70574 "LT PnB Log 3"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        E: Text;
    begin
        foreach E in Entries do begin
            if Result <> '' then
                Result += ',';
            Result += E;
        end;
        exit(Result);
    end;
}

enum 70532 "LT PnB Enum"
{
    Extensible = true;

    value(0; First) { }
    value(5; Fifth) { Caption = 'Cinq'; }
    value(2; Second) { }
}

enumextension 70533 "LT PnB Enum Ext" extends "LT PnB Enum"
{
    value(7; Seventh) { }
}

enumextension 70534 "LT PnB Enum Ext2" extends "LT PnB Enum"
{
    value(3; Third) { }
}

