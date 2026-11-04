// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 70404, pages 70408 70409, page extension 70400
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a SaveValues page extended by a control bound to a variable and one bound to a field: what is stored and restored when the page is reopened (OpenNew, OpenEdit); a page without SaveValues for comparison

table 70404 "LT P99 Save Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; F; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 70408 "LT P99 Save Card"
{
    PageType = Card;
    SourceTable = "LT P99 Save Row";
    SaveValues = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            field(BaseVarCtl; BaseVar)
            {
                ApplicationArea = All;
                Caption = 'Base var';
            }
        }
    }

    var
        BaseVar: Text[30];
}

page 70409 "LT P99 NoSave Card"
{
    PageType = Card;
    SourceTable = "LT P99 Save Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(FCtl; Rec.F) { ApplicationArea = All; }
            field(VarCtl; PlainVar)
            {
                ApplicationArea = All;
                Caption = 'Plain var';
            }
        }
    }

    var
        PlainVar: Text[30];
}

pageextension 70400 "LT P99 Save Ext" extends "LT P99 Save Card"
{
    layout
    {
        addlast(Content)
        {
            field(FCtl; Rec.F) { ApplicationArea = All; }
            field(ExtVarCtl; ExtVar)
            {
                ApplicationArea = All;
                Caption = 'Ext var';
            }
        }
    }

    var
        ExtVar: Text[30];
}

codeunit 70414 "LT P99 SaveValues"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Row: Record "LT P99 Save Row";
    begin
        Row.DeleteAll();
    end;

    [Test]
    procedure P99_ReopenNewAfterSave()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Save Row";
        Card: TestPage "LT P99 Save Card";
    begin
        Clean();
        Card.OpenNew();
        Card.IdCtl.SetValue('S1');
        Card.QtyCtl.SetValue(5);
        Card.FCtl.SetValue('field-F');
        Card.BaseVarCtl.SetValue('base-var');
        Card.ExtVarCtl.SetValue('ext-var');
        Card.Close();
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('db-F', Row.F);
        Card.OpenNew();
        Observer.Observe('new-Id', '[' + Card.IdCtl.Value() + ']');
        Observer.Observe('new-Qty', '[' + Card.QtyCtl.Value() + ']');
        Observer.Observe('new-F', '[' + Card.FCtl.Value() + ']');
        Observer.Observe('new-BaseVar', '[' + Card.BaseVarCtl.Value() + ']');
        Observer.Observe('new-ExtVar', '[' + Card.ExtVarCtl.Value() + ']');
        Card.Close();
        Observer.Expect('rows', '1');
        Observer.Expect('db-F', '');
        Observer.Expect('new-Id', '[]');
        Observer.Expect('new-Qty', '[0]');
        Observer.Expect('new-F', '[]');
        Observer.Expect('new-BaseVar', '[base-var]');
        Observer.Expect('new-ExtVar', '[ext-var]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_ReopenEditAfterSave()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Save Row";
        Card: TestPage "LT P99 Save Card";
    begin
        Clean();
        Row.Id := 'S1';
        Row.F := 'db-F';
        Row.Qty := 1;
        Row.Insert();
        Card.OpenEdit();
        Observer.Observe('first-F', '[' + Card.FCtl.Value() + ']');
        Card.BaseVarCtl.SetValue('base-var');
        Card.ExtVarCtl.SetValue('ext-var');
        Card.FCtl.SetValue('changed-F');
        Card.Close();
        Observer.Observe('db-F', Row.F);
        Row.Get('S1');
        Observer.Observe('db-F-after', Row.F);
        Card.OpenEdit();
        Observer.Observe('second-F', '[' + Card.FCtl.Value() + ']');
        Observer.Observe('second-BaseVar', '[' + Card.BaseVarCtl.Value() + ']');
        Observer.Observe('second-ExtVar', '[' + Card.ExtVarCtl.Value() + ']');
        Card.Close();
        Observer.Expect('first-F', '[db-F]');
        Observer.Expect('db-F', 'db-F');
        Observer.Expect('db-F-after', 'changed-F');
        Observer.Expect('second-F', '[changed-F]');
        Observer.Expect('second-BaseVar', '[base-var]');
        Observer.Expect('second-ExtVar', '[ext-var]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_ReopenWithoutSavingRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Save Row";
        Card: TestPage "LT P99 Save Card";
    begin
        Clean();
        Card.OpenNew();
        Card.FCtl.SetValue('unsaved-F');
        Card.BaseVarCtl.SetValue('unsaved-base');
        Card.ExtVarCtl.SetValue('unsaved-ext');
        Card.Close();
        Observer.Observe('rows', Format(Row.Count()));
        Card.OpenNew();
        Observer.Observe('F', '[' + Card.FCtl.Value() + ']');
        Observer.Observe('BaseVar', '[' + Card.BaseVarCtl.Value() + ']');
        Observer.Observe('ExtVar', '[' + Card.ExtVarCtl.Value() + ']');
        Card.Close();
        Observer.Expect('rows', '1');
        Observer.Expect('F', '[]');
        Observer.Expect('BaseVar', '[unsaved-base]');
        Observer.Expect('ExtVar', '[unsaved-ext]');
        Observer.Verify();
    end;

    [Test]
    procedure P99_NoSaveValuesForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P99 Save Row";
        Card: TestPage "LT P99 NoSave Card";
    begin
        Clean();
        Card.OpenNew();
        Card.IdCtl.SetValue('N1');
        Card.FCtl.SetValue('field-F');
        Card.VarCtl.SetValue('plain-var');
        Card.Close();
        Observer.Observe('rows', Format(Row.Count()));
        Card.OpenNew();
        Observer.Observe('new-Id', '[' + Card.IdCtl.Value() + ']');
        Observer.Observe('new-F', '[' + Card.FCtl.Value() + ']');
        Observer.Observe('new-Var', '[' + Card.VarCtl.Value() + ']');
        Card.Close();
        Observer.Expect('rows', '1');
        Observer.Expect('new-Id', '[]');
        Observer.Expect('new-F', '[]');
        Observer.Expect('new-Var', '[]');
        Observer.Verify();
    end;
}
