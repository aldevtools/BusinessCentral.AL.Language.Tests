// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcfields-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Report Log (67077); own objects 67098 - 67099, 67108 - 67114, 67126
// Probe: shared fixtures of the report probes: header and line tables with FlowFields, and ProcessingOnly reports that log the FlowField values and rows they read.
// BC versions: 27.0+

table 67098 "LT F3 RHead"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[50]) { }
        field(3; SumQty; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT F3 RLine".Qty where("Head Code" = field("Code")));
        }
        field(4; LineCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT F3 RLine" where("Head Code" = field("Code")));
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 67099 "LT F3 RLine"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Head Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Integer) { }
        field(4; HeadDescr; Text[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT F3 RHead".Descr where("Code" = field("Head Code")));
        }
        field(5; Sibs; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT F3 RLine" where("Head Code" = field("Head Code")));
        }
    }

    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }
}

// In-memory log: written from report triggers that run inside TryFunctions, where table writes are not allowed. Used by one test codeunit only.
codeunit 67126 "LT F3 Report Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Clear()
    begin
        if Entries.Count() > 0 then
            Entries.RemoveRange(1, Entries.Count());
    end;

    procedure Add(Value: Text)
    begin
        Entries.Add(Value);
    end;

    procedure Dump(): Text
    var
        Entry: Text;
        Result: Text;
    begin
        foreach Entry in Entries do
            Result += Entry + ' | ';
        exit(Result);
    end;
}

codeunit 67108 "LT F3 Report Data"
{
    procedure Seed()
    var
        Head: Record "LT F3 RHead";
        Line: Record "LT F3 RLine";
        Log: Codeunit "LT F3 Report Log";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Log.Clear();
        AddHead('H1', 'First');
        AddHead('H2', 'Second');
        AddHead('H3', 'Third');
        AddLine('H1', 1, 10);
        AddLine('H1', 2, 20);
        AddLine('H1', 3, 30);
        AddLine('H2', 1, 5);
        AddLine('H2', 2, 7);
    end;

    local procedure AddHead(HeadCode: Code[20]; Descr: Text[50])
    var
        Head: Record "LT F3 RHead";
    begin
        Head.Init();
        Head."Code" := HeadCode;
        Head.Descr := Descr;
        Head.Insert();
    end;

    local procedure AddLine(HeadCode: Code[20]; LineNo: Integer; Qty: Integer)
    var
        Line: Record "LT F3 RLine";
    begin
        Line.Init();
        Line."Head Code" := HeadCode;
        Line."Line No." := LineNo;
        Line.Qty := Qty;
        Line.Insert();
    end;
}

report 67109 "LT F3 CalcFields Lists"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT F3 RHead")
        {
            CalcFields = SumQty, LineCount;

            dataitem(Child; "LT F3 RLine")
            {
                DataItemLink = "Head Code" = field("Code");
                CalcFields = HeadDescr, Sibs;

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT F3 Report Log";
                begin
                    Log.Add('Child ' + Child."Head Code" + '/' + Format(Child."Line No.") + ' descr=' + Child.HeadDescr + ' sibs=' + Format(Child.Sibs));
                end;
            }

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT F3 Report Log";
            begin
                Log.Add('Parent ' + Parent."Code" + ' sum=' + Format(Parent.SumQty) + ' count=' + Format(Parent.LineCount));
            end;
        }
    }
}

report 67110 "LT F3 CalcFields None"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT F3 RHead")
        {
            dataitem(Child; "LT F3 RLine")
            {
                DataItemLink = "Head Code" = field("Code");

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT F3 Report Log";
                begin
                    Log.Add('Child ' + Child."Head Code" + '/' + Format(Child."Line No.") + ' descr=' + Child.HeadDescr + ' sibs=' + Format(Child.Sibs));
                end;
            }

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT F3 Report Log";
            begin
                Log.Add('Parent ' + Parent."Code" + ' sum=' + Format(Parent.SumQty) + ' count=' + Format(Parent.LineCount));
            end;
        }
    }
}

report 67111 "LT F3 CalcFields Single"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT F3 RHead")
        {
            CalcFields = SumQty;

            dataitem(Child; "LT F3 RLine")
            {
                DataItemLink = "Head Code" = field("Code");
                CalcFields = Sibs;

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT F3 Report Log";
                begin
                    Log.Add('Child ' + Child."Head Code" + '/' + Format(Child."Line No.") + ' descr=' + Child.HeadDescr + ' sibs=' + Format(Child.Sibs));
                end;
            }

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT F3 Report Log";
            begin
                Log.Add('Parent ' + Parent."Code" + ' sum=' + Format(Parent.SumQty) + ' count=' + Format(Parent.LineCount));
            end;
        }
    }
}

// The child has its own view filter on the link field.
report 67112 "LT F3 Link Filter View"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT F3 RHead")
        {
            dataitem(Child; "LT F3 RLine")
            {
                DataItemLink = "Head Code" = field("Code");
                DataItemTableView = where("Head Code" = filter('H1'));

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT F3 Report Log";
                begin
                    Log.Add('Child ' + Child."Head Code" + '/' + Format(Child."Line No."));
                end;
            }

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT F3 Report Log";
            begin
                Log.Add('Parent ' + Parent."Code");
            end;
        }
    }
}

// The child has no view; the caller sets one with SetTableView.
report 67113 "LT F3 Link Filter Caller"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT F3 RHead")
        {
            dataitem(Child; "LT F3 RLine")
            {
                DataItemLink = "Head Code" = field("Code");

                trigger OnAfterGetRecord()
                var
                    Log: Codeunit "LT F3 Report Log";
                begin
                    Log.Add('Child ' + Child."Head Code" + '/' + Format(Child."Line No."));
                end;
            }

            trigger OnPreDataItem()
            var
                Log: Codeunit "LT F3 Report Log";
            begin
                Log.Add('Child filters at Parent.OnPreDataItem=[' + Child.GetFilters() + ']');
            end;

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT F3 Report Log";
            begin
                Log.Add('Parent ' + Parent."Code" + ' child filters=[' + Child.GetFilters() + ']');
            end;
        }
    }
}

// A ProcessingOnly report with request page fields, logging its triggers.
report 67114 "LT F3 Request Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Parent; "LT F3 RHead")
        {
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT F3 Report Log";
            begin
                Log.Add('Parent ' + Parent."Code");
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
                    field(TagCtl; Tag)
                    {
                        ApplicationArea = All;
                        Caption = 'Tag';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            Log: Codeunit "LT F3 Report Log";
        begin
            Log.Add('RP OnOpenPage');
        end;
    }

    var
        Tag: Text[20];

    trigger OnInitReport()
    var
        Log: Codeunit "LT F3 Report Log";
    begin
        Tag := 'default';
        Log.Add('OnInitReport');
    end;

    trigger OnPreReport()
    var
        Log: Codeunit "LT F3 Report Log";
    begin
        Log.Add('OnPreReport tag=' + Tag);
    end;

    trigger OnPostReport()
    var
        Log: Codeunit "LT F3 Report Log";
    begin
        Log.Add('OnPostReport');
    end;
}
