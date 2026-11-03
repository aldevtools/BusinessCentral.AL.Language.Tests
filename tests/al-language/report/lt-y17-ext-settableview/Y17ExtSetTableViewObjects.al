// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-settableview-method
// Scope: in-scope
// Fixtures used: none (own objects below; log 91844 is used only by test codeunit 91849)
// Probe: gap cycle 1, G10 (corpus writer Y17). Objects for Y17ExtSetTableViewTests.al: a processing-only report RB (Req over H > Base over BL)
// and a reportextension RX that adds, after Base, an item XH over PH (linked to Req) with a nested XL over PL (the Get Source Documents /
// Serv. Get Source Documents shape). A top-level added item does not compile (AL0680): tests/must-not-compile/cases/2340.
// BC versions: 27-29

table 91840 "LT Y17 Ext H"
{
    DataClassification = SystemMetadata;
    fields { field(1; "No."; Code[20]) { } }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 91841 "LT Y17 Ext PH"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Subtype; Integer) { }
        field(2; "No."; Code[20]) { }
        field(3; Cust; Code[20]) { }
    }
    keys
    {
        key(PK; Subtype, "No.") { Clustered = true; }
        key(ByCust; Cust) { }
    }
}

table 91842 "LT Y17 Ext PL"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Subtype; Integer) { }
        field(2; "Doc No."; Code[20]) { }
        field(3; "Line No."; Integer) { }
        field(4; Item; Code[20]) { }
    }
    keys { key(PK; Subtype, "Doc No.", "Line No.") { Clustered = true; } }
}

table 91843 "LT Y17 Ext BL"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }
    keys { key(PK; "No.", "Line No.") { Clustered = true; } }
}

codeunit 91844 "LT Y17 Ext Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 91845 "LT Y17 Ext RB"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Req; "LT Y17 Ext H")
        {
            dataitem(Base; "LT Y17 Ext BL")
            {
                DataItemLink = "No." = field("No.");

                trigger OnPreDataItem()
                begin
                    Log.Add('pre Base [' + Base.GetFilters() + ']');
                end;

                trigger OnAfterGetRecord()
                begin
                    Log.Add('Base:' + Base."No." + '/' + Format(Base."Line No."));
                end;
            }

            trigger OnPreDataItem()
            begin
                Log.Add('pre Req [' + Req.GetFilters() + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('Req:' + Req."No.");
            end;
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('OnPreReport');
    end;

    trigger OnPostReport()
    begin
        Log.Add('OnPostReport');
    end;

    var
        Log: Codeunit "LT Y17 Ext Log";
}

reportextension 91846 "LT Y17 Ext RX" extends "LT Y17 Ext RB"
{
    dataset
    {
        addafter(Base)
        {
            dataitem(XH; "LT Y17 Ext PH")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting(Subtype, "No.");

                dataitem(XL; "LT Y17 Ext PL")
                {
                    DataItemLink = Subtype = field(Subtype), "Doc No." = field("No.");

                    trigger OnPreDataItem()
                    begin
                        XLog.Add('pre XL [' + XL.GetFilters() + ']');
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        XLog.Add('XL:' + Format(XL.Subtype) + '/' + XL."Doc No." + '/' + Format(XL."Line No.") + '/' + XL.Item);
                    end;
                }

                trigger OnPreDataItem()
                begin
                    XLog.Add('pre XH [' + XH.GetFilters() + ']');
                end;

                trigger OnAfterGetRecord()
                begin
                    XLog.Add('XH:' + Format(XH.Subtype) + '/' + XH."No." + '/' + XH.Cust);
                end;
            }
        }
    }

    var
        XLog: Codeunit "LT Y17 Ext Log";
}
