// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-customization-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 76000 (pages/lt-z-page-props/ZFixtures.al); pages 76200-76219, codeunits 76220-76221
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles corpus issue 618: page customization object properties ClearActions, ClearLayout, ClearViews, DeleteAllowed, InsertAllowed, ModifyAllowed,
//   PromotedActionCategories, and the control properties Editable, Importance, MaskType, QuickEntry and Width of modify() in a page customization.
// Facts: what a TestPage sees of a customized page (control and action state, the errors of New and of an edit, Page Metadata flags). A page customization changes
//   a page for every user; this file records whether the TestPage honors it. The values the compiler rejects (Editable = true on a field without
//   AllowInCustomizations, ClearViews on a card, out-of-range Width, invalid enum values) are must-not-compile cases.
// BC versions: 29 (27 and 28 by CI)

page 76200 "LT Z CA Base"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { field(Id; Rec.Id) { ApplicationArea = All; } field(Name; Rec.Name) { ApplicationArea = All; } } }

    actions { area(Processing) { action(ActA) { ApplicationArea = All; trigger OnAction() var Log: Codeunit "LT Z Cust Log"; begin Log.Add('ActA'); end; } } }
}

pagecustomization "LT Z CA Cust" customizes "LT Z CA Base"
{
    ClearActions = true;
}

page 76201 "LT Z CL Base"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { field(Id; Rec.Id) { ApplicationArea = All; } field(Name; Rec.Name) { ApplicationArea = All; } } }

    actions { area(Processing) { action(ActB) { ApplicationArea = All; trigger OnAction() var Log: Codeunit "LT Z Cust Log"; begin Log.Add('ActB'); end; } } }
}

pagecustomization "LT Z CL Cust" customizes "LT Z CL Base"
{
    ClearLayout = true;
}

page 76202 "LT Z CV Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { ApplicationArea = All; } field(Name; Rec.Name) { ApplicationArea = All; } } } }

    actions { area(Processing) { action(ActC) { ApplicationArea = All; trigger OnAction() var Log: Codeunit "LT Z Cust Log"; begin Log.Add('ActC'); end; } } }

    views { view(V1) { Filters = where(Id = const(1)); } }
}

pagecustomization "LT Z CV Cust" customizes "LT Z CV Base"
{
    ClearViews = true;
}

page 76203 "LT Z CD1 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { ApplicationArea = All; } field(Name; Rec.Name) { ApplicationArea = All; } } } }

    actions { area(Processing) { action(DeleteIt) { ApplicationArea = All; trigger OnAction() begin Rec.Delete(true); end; } } }
}

pagecustomization "LT Z CD1 Cust" customizes "LT Z CD1 Base"
{
    DeleteAllowed = false;
}

page 76204 "LT Z CI1 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { ApplicationArea = All; } field(Name; Rec.Name) { ApplicationArea = All; } } } }

    actions { area(Processing) { action(DeleteIt) { ApplicationArea = All; trigger OnAction() begin Rec.Delete(true); end; } } }
}

pagecustomization "LT Z CI1 Cust" customizes "LT Z CI1 Base"
{
    InsertAllowed = false;
}

page 76205 "LT Z CM1 Base"
{
    PageType = List;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { ApplicationArea = All; } field(Name; Rec.Name) { ApplicationArea = All; } } } }

    actions { area(Processing) { action(DeleteIt) { ApplicationArea = All; trigger OnAction() begin Rec.Delete(true); end; } } }
}

pagecustomization "LT Z CM1 Cust" customizes "LT Z CM1 Base"
{
    ModifyAllowed = false;
}

page 76206 "LT Z CP Base"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { field(Id; Rec.Id) { ApplicationArea = All; } field(Name; Rec.Name) { ApplicationArea = All; } } }

    actions { area(Processing) { action(A1) { ApplicationArea = All; Promoted = true; PromotedCategory = Category4; trigger OnAction() var Log: Codeunit "LT Z Cust Log"; begin Log.Add('A1'); end; } } }
}

pagecustomization "LT Z CP Cust" customizes "LT Z CP Base"
{
    PromotedActionCategories = 'A,B';
}

page 76207 "LT Z CF Base"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { field(Id; Rec.Id) { ApplicationArea = All; }
field(Name; Rec.Name) { ApplicationArea = All; }
field(Amt; Rec.Amount) { ApplicationArea = All; }
field(Mask; Rec.Name) { ApplicationArea = All; }
field(Qe; Rec.Name) { ApplicationArea = All; }
field(Wid; Rec.Name) { ApplicationArea = All; }
field(Dt; Rec.Dt) { ApplicationArea = All; Editable = false; } } }
}

pagecustomization "LT Z CF Cust" customizes "LT Z CF Base"
{
    layout
    {
        modify(Name) { Editable = false; }
        modify(Amt) { Importance = Additional; }
        modify(Mask) { MaskType = Concealed; }
        modify(Qe) { QuickEntry = false; }
        modify(Wid) { Width = 10; }
        modify(Dt) { Editable = true; }
    }
}

page 76208 "LT Z CG Base"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout { area(Content) { field(Id; Rec.Id) { ApplicationArea = All; }
field(Std; Rec.Name) { ApplicationArea = All; }
field(Pro; Rec.Name) { ApplicationArea = All; }
field(Add; Rec.Name) { ApplicationArea = All; }
field(None; Rec.Name) { ApplicationArea = All; }
field(Qe2; Rec.Name) { ApplicationArea = All; } } }
}

pagecustomization "LT Z CG Cust" customizes "LT Z CG Base"
{
    layout
    {
        modify(Std) { Importance = Standard; }
        modify(Pro) { Importance = Promoted; }
        modify(Add) { Importance = Additional; }
        modify(None) { MaskType = None; }
        modify(Qe2) { QuickEntry = true; Width = 50; }
    }
}

codeunit 76220 "LT Z Page Customization Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Meta(PageId: Integer; Prefix: Text)
    var
        PageMeta: Record "Page Metadata";
    begin
        if not PageMeta.Get(PageId) then begin
            Observer.Observe(Prefix + ' meta', 'not found');
            exit;
        end;
        Observer.Observe(Prefix + ' insert allowed', Format(PageMeta.InsertAllowed));
        Observer.Observe(Prefix + ' modify allowed', Format(PageMeta.ModifyAllowed));
        Observer.Observe(Prefix + ' delete allowed', Format(PageMeta.DeleteAllowed));
    end;

    local procedure Seed()
    var
        R: Record "LT Z Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'One';
        R.Insert();
        R.Id := 2;
        R.Name := 'Two';
        R.Insert();
    end;

    [TryFunction]
    local procedure TryActA(var P: TestPage "LT Z CA Base"; var Visible: Text)
    begin
        Visible := Format(P.ActA.Visible());
    end;

    [Test]
    procedure ZClearActions_ActionList()
    var
        Log: Codeunit "LT Z Cust Log";
        P: TestPage "LT Z CA Base";
        Visible: Text;
    begin
        Seed();
        Log.Take();
        P.OpenView();
        Observer.Observe('name', P.Name.Value());
        ClearLastError();
        Observer.Observe('acta visible read ok', Format(TryActA(P, Visible)));
        Observer.Observe('acta visible', Visible);
        Observer.ObserveError('acta visible read');
        P.Close();
        Observer.Expect('name', 'One');
        Observer.Expect('acta visible read ok', 'Yes');
        Observer.Expect('acta visible', 'Yes');
        Observer.Expect('acta visible read|text', '');
        Observer.Expect('acta visible read|code', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryName(var P: TestPage "LT Z CL Base"; var Value: Text)
    begin
        Value := P.Name.Value();
    end;

    [Test]
    procedure ZClearLayout_ControlList()
    var
        P: TestPage "LT Z CL Base";
        Value: Text;
    begin
        Seed();
        P.OpenView();
        ClearLastError();
        Observer.Observe('name read ok', Format(TryName(P, Value)));
        Observer.Observe('name', Value);
        Observer.ObserveError('name read');
        Observer.Observe('actb visible', Format(P.ActB.Visible()));
        P.Close();
        Observer.Expect('name read ok', 'Yes');
        Observer.Expect('name', 'One');
        Observer.Expect('name read|text', '');
        Observer.Expect('name read|code', '');
        Observer.Expect('actb visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ZClearViews_ListRunsUnchanged()
    var
        P: TestPage "LT Z CV Base";
    begin
        Seed();
        P.OpenView();
        P.First();
        Observer.Observe('first', P.Name.Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('second', P.Name.Value());
        Observer.Observe('actc visible', Format(P.ActC.Visible()));
        P.Close();
        Observer.Expect('first', 'One');
        Observer.Expect('next', 'Yes');
        Observer.Expect('second', 'Two');
        Observer.Expect('actc visible', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDelete(var P: TestPage "LT Z CD1 Base")
    begin
        P.DeleteIt.Invoke();
    end;

    [Test]
    procedure ZCustDeleteAllowed()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z CD1 Base";
    begin
        Seed();
        Meta(Page::"LT Z CD1 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('delete ok', Format(TryDelete(P)));
        Observer.ObserveError('delete');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('delete ok', 'Yes');
        Observer.Expect('delete|text', '');
        Observer.Expect('delete|code', '');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNew(var P: TestPage "LT Z CI1 Base")
    begin
        P.New();
        P.Id.SetValue(3);
        P.Name.SetValue('Three');
    end;

    [Test]
    procedure ZCustInsertAllowed()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z CI1 Base";
    begin
        Seed();
        Meta(Page::"LT Z CI1 Base", 'page');
        P.OpenEdit();
        P.First();
        ClearLastError();
        Observer.Observe('new ok', Format(TryNew(P)));
        Observer.ObserveError('new');
        P.Close();
        Observer.Observe('rows', Format(R.Count()));
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('new ok', 'Yes');
        Observer.Expect('new|text', '');
        Observer.Expect('new|code', '');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEdit(var P: TestPage "LT Z CM1 Base")
    begin
        P.Name.SetValue('Changed');
    end;

    [Test]
    procedure ZCustModifyAllowed()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z CM1 Base";
    begin
        Seed();
        Meta(Page::"LT Z CM1 Base", 'page');
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        ClearLastError();
        Observer.Observe('edit ok', Format(TryEdit(P)));
        Observer.ObserveError('edit');
        P.Close();
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        Observer.Expect('page insert allowed', 'Yes');
        Observer.Expect('page modify allowed', 'Yes');
        Observer.Expect('page delete allowed', 'Yes');
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('edit ok', 'Yes');
        Observer.Expect('edit|text', '');
        Observer.Expect('edit|code', '');
        Observer.Expect('stored name', 'Changed');
        Observer.Verify();
    end;

    [Test]
    procedure ZCustPromotedActionCategories_ActionUnchanged()
    var
        Log: Codeunit "LT Z Cust Log";
        P: TestPage "LT Z CP Base";
    begin
        Seed();
        Log.Take();
        P.OpenView();
        Observer.Observe('visible', Format(P.A1.Visible()));
        P.A1.Invoke();
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Expect('visible', 'Yes');
        Observer.Expect('log', 'A1;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySet(var P: TestPage "LT Z CF Base"; Field: Integer)
    begin
        case Field of
            1:
                P.Name.SetValue('Changed');
            3:
                P.Mask.SetValue('masked');
            4:
                P.Wid.SetValue('wide');
            5:
                P.Qe.SetValue('quick');
            6:
                P.Amt.SetValue(5);
        end;
    end;

    [Test]
    procedure ZCustControls_EditableImportanceMaskQuickEntryWidth()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z CF Base";
        Field: Integer;
    begin
        Seed();
        P.OpenEdit();
        P.First();
        Observer.Observe('name editable', Format(P.Name.Editable()));
        Observer.Observe('dt editable', Format(P.Dt.Editable()));
        Observer.Observe('amt editable', Format(P.Amt.Editable()));
        Observer.Observe('mask value', P.Mask.Value());
        Observer.Observe('qe visible', Format(P.Qe.Visible()));
        Observer.Observe('wid visible', Format(P.Wid.Visible()));
        for Field := 1 to 6 do begin
            if Field = 2 then
                continue;
            ClearLastError();
            Observer.Observe('set ' + Format(Field) + ' ok', Format(TrySet(P, Field)));
            Observer.ObserveError('set ' + Format(Field));
        end;
        P.Close();
        R.Get(1);
        Observer.Observe('stored name', R.Name);
        Observer.Observe('stored amount', Format(R.Amount));
        Observer.Expect('name editable', 'Yes');
        Observer.Expect('dt editable', 'No');
        Observer.Expect('amt editable', 'Yes');
        Observer.Expect('mask value', 'One');
        Observer.Expect('qe visible', 'Yes');
        Observer.Expect('wid visible', 'Yes');
        Observer.Expect('set 1 ok', 'Yes');
        Observer.Expect('set 1|text', '');
        Observer.Expect('set 1|code', '');
        Observer.Expect('set 3 ok', 'Yes');
        Observer.Expect('set 3|text', '');
        Observer.Expect('set 3|code', '');
        Observer.Expect('set 4 ok', 'Yes');
        Observer.Expect('set 4|text', '');
        Observer.Expect('set 4|code', '');
        Observer.Expect('set 5 ok', 'Yes');
        Observer.Expect('set 5|text', '');
        Observer.Expect('set 5|code', '');
        Observer.Expect('set 6 ok', 'Yes');
        Observer.Expect('set 6|text', '');
        Observer.Expect('set 6|code', '');
        Observer.Expect('stored name', 'quick');
        Observer.Expect('stored amount', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ZCustImportanceValues_CompileAndRun()
    var
        P: TestPage "LT Z CG Base";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('std', Format(P.Std.Visible()));
        Observer.Observe('pro', Format(P.Pro.Visible()));
        Observer.Observe('add', Format(P.Add.Visible()));
        Observer.Observe('none', Format(P.None.Visible()));
        Observer.Observe('qe2', Format(P.Qe2.Visible()));
        P.Close();
        Observer.Expect('std', 'Yes');
        Observer.Expect('pro', 'Yes');
        Observer.Expect('add', 'Yes');
        Observer.Expect('none', 'Yes');
        Observer.Expect('qe2', 'Yes');
        Observer.Verify();
    end;
}

codeunit 76221 "LT Z Cust Log"
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
