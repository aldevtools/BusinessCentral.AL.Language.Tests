// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: none; self-contained tables 79700-79701, reports 79710-79726 and report extensions 79740-79742; log codeunits 79702-79705
// Probe: the objects of the probes in AqTests.al (corpus issue 646).
// BC versions: 27-29

table 79700 "LT AQ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Amount; Decimal) { }
        field(3; Name; Text[30]) { }
        field(4; SumQty; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT AQ Entry".Qty where(RowCode = field(Code)));
        }
        field(5; CntEntries; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT AQ Entry" where(RowCode = field(Code)));
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 79701 "LT AQ Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; EntryNo; Integer) { }
        field(2; RowCode; Code[20]) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
    }
}

// Item 11: CurrReport.Language set to values outside the culture range, in OnPreReport.
// CurrReport.Language := -2 is left out: on the BC 29 Linux tier it raised an uncatchable 'Unexpected CLR exception thrown.: System.ArgumentOutOfRangeException:
// culture ('-2') must be a non-negative and non-zero value. (Parameter 'culture')' that the TryFunction did not catch (a Linux suspect, kept as report 79726 without a test).
report 79710 "LT AQ Lang"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(N; Number) { }
        }
    }

    trigger OnPreReport()
    begin
        Probe(70000);
        Probe(99998);
        Log.Add('after=' + Format(CurrReport.Language) + ' global=' + Format(CurrReport.Language = GlobalLanguage()));
    end;

    local procedure Probe(Value: Integer)
    begin
        ClearLastError();
        if TrySet(Value) then
            Log.Add(Format(Value) + ' ok reads ' + Format(CurrReport.Language))
        else
            Log.Add(Format(Value) + ' error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySet(Value: Integer)
    begin
        CurrReport.Language := Value;
    end;

    var
        Log: Codeunit "LT AQ Log";
}

// Item 11 through Report.Run: the same, in a processing-only report.
report 79725 "LT AQ Lang Run"
{
    UsageCategory = None;
    UseRequestPage = false;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    trigger OnPreReport()
    begin
        Probe(70000);
        Probe(99998);
        Log.Add('after=' + Format(CurrReport.Language) + ' global=' + Format(CurrReport.Language = GlobalLanguage()));
    end;

    local procedure Probe(Value: Integer)
    begin
        ClearLastError();
        if TrySet(Value) then
            Log.Add(Format(Value) + ' ok reads ' + Format(CurrReport.Language))
        else
            Log.Add(Format(Value) + ' error=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySet(Value: Integer)
    begin
        CurrReport.Language := Value;
    end;

    var
        Log: Codeunit "LT AQ Log";
}

// Not run by a test (see report 79710): CurrReport.Language := -2.
report 79726 "LT AQ Lang Minus Two"
{
    UsageCategory = None;
    UseRequestPage = false;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    trigger OnPreReport()
    begin
        CurrReport.Language := -2;
    end;
}

// Item 12: the data item systemId of two SaveAs runs.
report 79711 "LT AQ Rows"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT AQ Row")
        {
            column(RowCode; Code) { }
        }
    }
}

// Item 13: RequestOptionsPage.Caption set in the request page OnOpenPage.
report 79712 "LT AQ Caption"
{
    UsageCategory = None;
    Caption = 'LT AQ static caption';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
        Caption = 'LT AQ request page caption';

        layout
        {
            area(Content)
            {
                field(Ctl; Ctl) { ApplicationArea = All; }
            }
        }

        trigger OnOpenPage()
        begin
            RequestOptionsPage.Caption := 'LT AQ caption set in OnOpenPage';
        end;
    }

    var
        Ctl: Integer;
}

// Item 14: a SaveValues request page extended by a variable control and a record field control.
report 79713 "LT AQ Saved"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Opts)
                {
                    field(BaseCtl; BaseVal) { ApplicationArea = All; }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('base=' + Format(BaseVal));
    end;

    var
        Log: Codeunit "LT AQ Log Saved Ext";
        BaseVal: Integer;
}

reportextension 79740 "LT AQ Saved Ext" extends "LT AQ Saved"
{
    requestpage
    {
        layout
        {
            addlast(Opts)
            {
                field(ExtVarCtl; ExtVal) { ApplicationArea = All; }
                field(ExtFieldCtl; ExtRow.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        ExtLog.Add('ext var=' + Format(ExtVal) + ' ext field=[' + ExtRow.Name + ']');
    end;

    var
        ExtLog: Codeunit "LT AQ Log Saved Ext";
        ExtVal: Integer;
        ExtRow: Record "LT AQ Row";
}

// Item 15: SaveValues with a stored data item filter, then SetTableView or a record passed to Report.RunModal.
report 79714 "LT AQ Saved Filter"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(RowDi; "LT AQ Row")
        {
            RequestFilterFields = Code;

            trigger OnPreDataItem()
            begin
                Log.Add('pre count=' + Format(RowDi.Count()) + ' filter=[' + RowDi.GetFilter(Code) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + RowDi.Code);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
    }

    var
        Log: Codeunit "LT AQ Log Filter";
}

// Item 17: a report procedure sets a data item filter before RunModal (no SaveValues).
report 79715 "LT AQ Proc Filter"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(RowDi; "LT AQ Row")
        {
            RequestFilterFields = Code;

            trigger OnPreDataItem()
            begin
                Log.Add('pre count=' + Format(RowDi.Count()) + ' filter=[' + RowDi.GetFilter(Code) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + RowDi.Code);
            end;
        }
    }

    requestpage
    {
    }

    procedure SetCallerFilter(Filter: Text)
    begin
        RowDi.SetFilter(Code, Filter);
    end;

    var
        Log: Codeunit "LT AQ Log Filter";
}

// Item 16: CalcFields on a data item added by a report extension, and CalcFields naming a normal field.
report 79716 "LT AQ CalcF Base"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Par; "LT AQ Row")
        {
            DataItemTableView = where(Code = const('A1'));
            column(ParCode; Code) { }
        }
    }
}

reportextension 79741 "LT AQ CalcF Ext" extends "LT AQ CalcF Base"
{
    dataset
    {
        addlast(Par)
        {
            dataitem(ExtRow; "LT AQ Row")
            {
                DataItemLink = Code = field(Code);
                CalcFields = SumQty, CntEntries;
                column(ExtSum; SumQty) { }

                trigger OnAfterGetRecord()
                begin
                    ExtLog.Add('ext ' + ExtRow.Code + ' sum=' + Format(ExtRow.SumQty) + ' cnt=' + Format(ExtRow.CntEntries));
                end;
            }
        }
    }

    var
        ExtLog: Codeunit "LT AQ Log";
}

report 79717 "LT AQ CalcF Normal"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT AQ Row")
        {
            DataItemTableView = where(Code = const('A1'));
            CalcFields = Amount, SumQty;
            column(RowAmount; Amount) { }

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + Row.Code + ' amount=' + Format(Row.Amount) + ' sum=' + Format(Row.SumQty));
            end;
        }
    }

    var
        Log: Codeunit "LT AQ Log";
}

// Item 18: the same data set with and without WordMergeDataItem.
report 79718 "LT AQ WM On"
{
    UsageCategory = None;
    UseRequestPage = false;
    WordMergeDataItem = Par;

    dataset
    {
        dataitem(Par; "LT AQ Row")
        {
            column(PCode; Code) { }
            dataitem(Ent; "LT AQ Entry")
            {
                DataItemLink = RowCode = field(Code);
                column(EQty; Qty) { }
            }
        }
    }
}

report 79719 "LT AQ WM Off"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Par; "LT AQ Row")
        {
            column(PCode; Code) { }
            dataitem(Ent; "LT AQ Entry")
            {
                DataItemLink = RowCode = field(Code);
                column(EQty; Qty) { }
            }
        }
    }
}

// Item 19: Report.WordXmlPart of a nested data item with names that hold a space and special characters, and of an extended report.
report 79720 "LT AQ Word Xml"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem("Par Item"; "LT AQ Row")
        {
            column(Par_Code; Code) { }
            column(Amt_x; Amount) { }
            dataitem("Sales & Line/x"; "LT AQ Entry")
            {
                DataItemLink = RowCode = field(Code);
                column(Qty_No; Qty) { }
            }
        }
    }
}

report 79721 "LT AQ Word Xml Ext Base"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Base; "LT AQ Row")
        {
            column(BCode; Code) { }
        }
    }
}

reportextension 79742 "LT AQ Word Xml Ext" extends "LT AQ Word Xml Ext Base"
{
    dataset
    {
        add(Base)
        {
            column(XName; Name) { }
        }
        addlast(Base)
        {
            dataitem(XEnt; "LT AQ Entry")
            {
                DataItemLink = RowCode = field(Code);
                column(XQty; Qty) { }
            }
        }
    }
}

// Item 22: the legacy ExcelLayout property on a report.
report 79722 "LT AQ Excel Legacy"
{
    UsageCategory = None;
    UseRequestPage = false;
    ExcelLayout = './reports/LtAqExcelLegacy.xlsx';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(N; Number) { }
        }
    }
}

// Item 24: a rendering layout without Subtype, and a report with an RDLC and a Word layout (a rendering section without DefaultRenderingLayout does not compile: AL0721, must-not-compile case 1121).
report 79723 "LT AQ No Subtype"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = AqWordNoSub;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(N; Number) { }
        }
    }

    rendering
    {
        layout(AqRdlcFirst)
        {
            Type = RDLC;
            LayoutFile = './reports/LtAqNoSubtypeRdlc.rdlc';
        }
        layout(AqWordNoSub)
        {
            Type = Word;
            LayoutFile = './reports/LtAqNoSubtypeWord.docx';
        }
    }
}

// Items 5, 8 and 9: request page with an OnInit that sets a control, an option control, and disabled and hidden actions.
report 79724 "LT AQ Req Page"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT AQ Row")
        {
            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(IntCtl; IntVal) { ApplicationArea = All; }
                field(OptCtl; OptVal) { ApplicationArea = All; }
            }
        }

        actions
        {
            area(Processing)
            {
                action(DisAct)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    trigger OnAction()
                    begin
                        Log.Add('DisAct ran');
                    end;
                }
                action(InvAct)
                {
                    ApplicationArea = All;
                    Visible = false;
                    trigger OnAction()
                    begin
                        Log.Add('InvAct ran');
                    end;
                }
            }
        }

        trigger OnInit()
        begin
            if Log.Mode() = 1 then
                IntVal := 5;
            Log.Add('OnInit int=' + Format(IntVal) + ' opt=' + Format(OptVal));
        end;

        trigger OnOpenPage()
        begin
            Log.Add('OnOpenPage int=' + Format(IntVal) + ' opt=' + Format(OptVal));
        end;
    }

    var
        Log: Codeunit "LT AQ Log Req Page";
        IntVal: Integer;
        OptVal: Option Alpha,Beta,Gamma;
}

// One single-instance log per test codeunit (79702: LT AQ Report Tests, 79703: LT AQ Req Page Tests, 79704: LT AQ Saved Ext Tests, 79705: LT AQ Filter Tests).
codeunit 79702 "LT AQ Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        CurrentMode: Integer;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
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

codeunit 79703 "LT AQ Log Req Page"
{
    SingleInstance = true;

    var
        Lines: Text;
        CurrentMode: Integer;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
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

codeunit 79704 "LT AQ Log Saved Ext"
{
    SingleInstance = true;

    var
        Lines: Text;
        CurrentMode: Integer;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
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

codeunit 79705 "LT AQ Log Filter"
{
    SingleInstance = true;

    var
        Lines: Text;
        CurrentMode: Integer;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
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
