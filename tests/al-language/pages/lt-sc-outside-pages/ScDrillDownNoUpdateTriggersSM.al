// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-markedonly-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 89010 "LT SC Operation" of ScDrillDownMarkedOnly.al; own pages 89245, 89246, test codeunit 89247
// Facts: the neighbour ScDrillDownMarkedOnly.al does not cover: a field's OnDrillDown does Rec.ClearMarks(), marks row 10 and Rec.MarkedOnly(true) WITHOUT
//   CurrPage.Update on a Worksheet page that has row triggers (OnAfterGetRecord and OnAfterGetCurrRecord; only OnAfterGetRecord). After TestField.Drilldown():
//   the rows First/Next lists, GoToRecord on row 20, and the same after a later Next/Previous move.
// BC versions: 27, 28, 29

page 89245 "LT SM SC Ops NoUpd Both"
{
    PageType = Worksheet;
    SourceTable = "LT SC Operation";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(MarkedCount; MarkedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Operation 10';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ClearMarks();
                        if Rec.Get('10') then
                            Rec.Mark(true);
                        Rec.MarkedOnly(true);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Operation No."; Rec."Operation No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    trigger OnAfterGetCurrRecord()
    begin
    end;

    var
        MarkedCount: Integer;
}

page 89246 "LT SM SC Ops NoUpd AGR"
{
    PageType = Worksheet;
    SourceTable = "LT SC Operation";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(MarkedCount; MarkedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Operation 10';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ClearMarks();
                        if Rec.Get('10') then
                            Rec.Mark(true);
                        Rec.MarkedOnly(true);
                    end;
                }
            }
            repeater(Lines)
            {
                field("Operation No."; Rec."Operation No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
    end;

    var
        MarkedCount: Integer;
}

codeunit 89247 "LT SM SC DrillDown NoUpdate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Operation: Record "LT SC Operation";
    begin
        Operation.DeleteAll();
        Operation."Operation No." := '10';
        Operation.Insert();
        Operation."Operation No." := '20';
        Operation.Insert();
    end;

    [Test]
    procedure BothTriggers_DrilldownWithoutUpdate_ListAndGoTo()
    var
        Observer: Codeunit "Probe Observer";
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SM SC Ops NoUpd Both";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Observer.Observe('goto20 before', Format(Operations.GoToRecord(Operation20)));
        Operations.MarkedCount.Drilldown();
        Observer.Observe('current after drilldown', Operations."Operation No.".Value());
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Observer.Observe('listed', Listed);
        Observer.Observe('goto20 after', Format(Operations.GoToRecord(Operation20)));
        Listed := '';
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Observer.Observe('listed again', Listed);
        Operations.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OnAfterGetRecordOnly_DrilldownWithoutUpdate_ListAndGoTo()
    var
        Observer: Codeunit "Probe Observer";
        Operation20: Record "LT SC Operation";
        Operations: TestPage "LT SM SC Ops NoUpd AGR";
        Listed: Text;
    begin
        Setup();
        Operation20.Get('20');
        Operations.OpenEdit();
        Observer.Observe('goto20 before', Format(Operations.GoToRecord(Operation20)));
        Operations.MarkedCount.Drilldown();
        Observer.Observe('current after drilldown', Operations."Operation No.".Value());
        if Operations.First() then
            repeat
                Listed += ' ' + Operations."Operation No.".Value();
            until not Operations.Next();
        Observer.Observe('listed', Listed);
        Observer.Observe('goto20 after', Format(Operations.GoToRecord(Operation20)));
        Operations.Close();
        Observer.Finish();
    end;
}
