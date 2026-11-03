// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 81850, pages 81851-81853 (UnopenedFixtures.al)
// Probe: corpus issue 673 item 1 (al-runtime-rs #292). Every literal asserted below is what BC 27.5, 28.5 and 29.0 produced in the corpus CI.
// Facts (fixtures): CurrPage methods (Update(false/true), SaveRecord, Activate, Caption, Editable, SetSelectionFilter, Rec) run by a procedure of a Page variable that was never opened: ListPart with a temporary Integer source, List and Card with a table; called directly and through a TryFunction; with SetRecord/SetTableView before; RunModal of the same variable afterwards.
// BC versions: 27+

table 81850 "LT BL Unopened Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 81851 "LT BL Unopened Part"
{
    PageType = ListPart;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(KeyCtl; Rec.Number) { ApplicationArea = All; }
            }
        }
    }

    procedure Act(Op: Text) Log: Text
    var
        Sel: Record Integer;
    begin
        Log := 'start';
        case Op of
            'update-false':
                CurrPage.Update(false);
            'update-true':
                CurrPage.Update(true);
            'saverecord':
                CurrPage.SaveRecord();
            'activate':
                CurrPage.Activate();
            'activate-true':
                CurrPage.Activate(true);
            'caption-get':
                Log += ' [' + CurrPage.Caption + ']';
            'caption-set':
                begin
                    CurrPage.Caption := 'LT BL Set Caption';
                    Log += ' [' + CurrPage.Caption + ']';
                end;
            'editable-get':
                Log += ' ' + Format(CurrPage.Editable);
            'editable-set':
                begin
                    CurrPage.Editable := false;
                    Log += ' ' + Format(CurrPage.Editable);
                end;
            'selection':
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    Log += ' [' + Sel.GetFilters() + '] ' + Format(Sel.Count());
                end;
            'rec':
                Log += ' [' + Format(Rec.Number) + '] [' + Rec.GetFilters() + ']';
        end;
        Log += ' end';
    end;
}

page 81852 "LT BL Unopened List"
{
    PageType = List;
    SourceTable = "LT BL Unopened Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(KeyCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure Act(Op: Text) Log: Text
    var
        Sel: Record "LT BL Unopened Row";
    begin
        Log := 'start';
        case Op of
            'update-false':
                CurrPage.Update(false);
            'update-true':
                CurrPage.Update(true);
            'saverecord':
                CurrPage.SaveRecord();
            'activate':
                CurrPage.Activate();
            'activate-true':
                CurrPage.Activate(true);
            'caption-get':
                Log += ' [' + CurrPage.Caption + ']';
            'caption-set':
                begin
                    CurrPage.Caption := 'LT BL Set Caption';
                    Log += ' [' + CurrPage.Caption + ']';
                end;
            'editable-get':
                Log += ' ' + Format(CurrPage.Editable);
            'editable-set':
                begin
                    CurrPage.Editable := false;
                    Log += ' ' + Format(CurrPage.Editable);
                end;
            'selection':
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    Log += ' [' + Sel.GetFilters() + '] ' + Format(Sel.Count());
                end;
            'rec':
                Log += ' [' + Format(Rec.Id) + '] [' + Rec.GetFilters() + ']';
        end;
        Log += ' end';
    end;
}

page 81853 "LT BL Unopened Card"
{
    PageType = Card;
    SourceTable = "LT BL Unopened Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(KeyCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure Act(Op: Text) Log: Text
    var
        Sel: Record "LT BL Unopened Row";
    begin
        Log := 'start';
        case Op of
            'update-false':
                CurrPage.Update(false);
            'update-true':
                CurrPage.Update(true);
            'saverecord':
                CurrPage.SaveRecord();
            'activate':
                CurrPage.Activate();
            'activate-true':
                CurrPage.Activate(true);
            'caption-get':
                Log += ' [' + CurrPage.Caption + ']';
            'caption-set':
                begin
                    CurrPage.Caption := 'LT BL Set Caption';
                    Log += ' [' + CurrPage.Caption + ']';
                end;
            'editable-get':
                Log += ' ' + Format(CurrPage.Editable);
            'editable-set':
                begin
                    CurrPage.Editable := false;
                    Log += ' ' + Format(CurrPage.Editable);
                end;
            'selection':
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    Log += ' [' + Sel.GetFilters() + '] ' + Format(Sel.Count());
                end;
            'rec':
                Log += ' [' + Format(Rec.Id) + '] [' + Rec.GetFilters() + ']';
        end;
        Log += ' end';
    end;
}
