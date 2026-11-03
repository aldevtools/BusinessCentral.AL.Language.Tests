// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none (own objects).
// local object: Execute is checked the first time a session loads an object (Y84 finding), so each Execute denial case of
//   Y24PermExecute.al (91977) needs objects that no other test in the app loads. Since test codeunits run in id order in one session,
//   the shared objects of Y24PermObjects.al (loaded earlier by 91976 and others) would open instead of being denied. These objects are
//   used only by the cases that are denied (a denied load does not count as loaded) and by nothing else.
// BC versions: 27, 28, 29
// Object ids 95060-95067.

table 95060 "LT Y24 Fx Tbl"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Describe(): Text
    begin
        exit('tp');
    end;
}

codeunit 95061 "LT Y24 Fx Target"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

// Runs each object kind; the exact set "LT Y24 Fx Granter" grants Execute on this codeunit only.
codeunit 95062 "LT Y24 Fx Granter"
{
    procedure Run(Which: Integer): Text
    var
        Row: Record "LT Y24 Fx Tbl";
        Target: Codeunit "LT Y24 Fx Target";
        FxRep: Report "LT Y24 Fx Rep";
        TempRow: Record "LT Y24 Row" temporary;
        Qry: Query "LT Y24 Fx Query";
        OutS: OutStream;
    begin
        case Which of
            1:
                begin
                    Codeunit.Run(Codeunit::"LT Y24 Fx Target");
                    exit('run');
                end;
            2:
                exit(Target.Ping());
            3:
                begin
                    FxRep.UseRequestPage(false);
                    FxRep.RunModal();
                    exit(FxRep.Seen());
                end;
            4:
                begin
                    Page.Run(Page::"LT Y24 Fx Card");
                    exit('page');
                end;
            6:
                begin
                    TempRow.Data.CreateOutStream(OutS);
                    Xmlport.Export(Xmlport::"LT Y24 Fx Xml", OutS);
                    exit('xml ' + Format(TempRow.Data.Length()));
                end;
            7:
                begin
                    Qry.Open();
                    exit('query ' + Format(Qry.Read()));
                end;
            8:
                exit(Row.Describe());
        end;
    end;
}

report 95063 "LT Y24 Fx Rep"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT Y24 Row")
        {
            trigger OnAfterGetRecord()
            begin
                SeenIds += Format(Row.Id) + ';';
            end;
        }
    }

    var
        SeenIds: Text;

    procedure Seen(): Text
    begin
        exit('seen ' + SeenIds);
    end;
}

page 95064 "LT Y24 Fx Card"
{
    PageType = Card;
    SourceTable = "LT Y24 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(ValueCtl; Rec.Value) { ApplicationArea = All; }
        }
    }
}

query 95065 "LT Y24 Fx Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT Y24 Row")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 95066 "LT Y24 Fx Xml"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y24 Row")
            {
                fieldattribute(Id; Row.Id) { }
            }
        }
    }
}

// Exact set for the granter case: table data on the row table, Execute on the fresh granter codeunit only.
permissionset 95067 "LT Y24 Fx Granter"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y24 Row" = RIMD,
        codeunit "LT Y24 Fx Granter" = X;
}
