// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-editable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72061, pages 72062 and 72063, codeunits 72059 and 72064
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Page variable Editable (section; PINNED, 'Not probed: a View-mode page given Editable(true), CurrPage.Editable read before the page opens')
// Facts: Editable of the TestPage and of its field for a page with the property Editable = false given Editable(true) before RunModal, the same page not touched, an editable page given Editable(false), and CurrPage.Editable read in OnInit and OnOpenPage of each
// BC versions: 29 (27 and 28 by CI)

table 72061 "LT PnD Ed Row"
{
    DataClassification = SystemMetadata;

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

codeunit 72059 "LT PnD Ed Holder"
{
    SingleInstance = true;

    var
        Seen: Dictionary of [Text, Text];

    procedure ResetSeen()
    begin
        Clear(Seen);
    end;

    procedure Put(KeyName: Text; Value: Text)
    begin
        if Seen.ContainsKey(KeyName) then
            Seen.Set(KeyName, Value)
        else
            Seen.Add(KeyName, Value);
    end;

    procedure Get(KeyName: Text): Text
    begin
        if Seen.ContainsKey(KeyName) then
            exit(Seen.Get(KeyName));
        exit('<not set>');
    end;
}

page 72062 "LT PnD Ed ReadOnly"
{
    PageType = Card;
    SourceTable = "LT PnD Ed Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnInit()
    var
        Holder: Codeunit "LT PnD Ed Holder";
    begin
        Holder.Put('readonly.oninit', Format(CurrPage.Editable));
    end;

    trigger OnOpenPage()
    var
        Holder: Codeunit "LT PnD Ed Holder";
    begin
        Holder.Put('readonly.onopen', Format(CurrPage.Editable));
    end;
}

page 72063 "LT PnD Ed Editable"
{
    PageType = Card;
    SourceTable = "LT PnD Ed Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnInit()
    var
        Holder: Codeunit "LT PnD Ed Holder";
    begin
        Holder.Put('editable.oninit', Format(CurrPage.Editable));
    end;

    trigger OnOpenPage()
    var
        Holder: Codeunit "LT PnD Ed Holder";
    begin
        Holder.Put('editable.onopen', Format(CurrPage.Editable));
    end;
}

codeunit 72064 "LT PnD Page Editable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Row: Record "LT PnD Ed Row")
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'abc';
        Row.Insert();
    end;

    [ModalPageHandler]
    procedure ReadOnlyHandler(var P: TestPage "LT PnD Ed ReadOnly")
    var
        Holder: Codeunit "LT PnD Ed Holder";
    begin
        Holder.Put('readonly.page', Format(P.Editable()));
        Holder.Put('readonly.field', Format(P.Name.Editable()));
    end;

    [ModalPageHandler]
    procedure EditableHandler(var P: TestPage "LT PnD Ed Editable")
    var
        Holder: Codeunit "LT PnD Ed Holder";
    begin
        Holder.Put('editable.page', Format(P.Editable()));
        Holder.Put('editable.field', Format(P.Name.Editable()));
    end;

    [Test]
    [HandlerFunctions('ReadOnlyHandler')]
    procedure ViewModePage_Untouched()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Ed Holder";
        Row: Record "LT PnD Ed Row";
        Pg: Page "LT PnD Ed ReadOnly";
    begin
        Seed(Row);
        Holder.ResetSeen();
        Observer.Observe('varBeforeRun', Format(Pg.Editable()));
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Observe('onInit', Holder.Get('readonly.oninit'));
        Observer.Observe('onOpenPage', Holder.Get('readonly.onopen'));
        Observer.Observe('testPage', Holder.Get('readonly.page'));
        Observer.Observe('testPageField', Holder.Get('readonly.field'));
        Observer.Expect('varBeforeRun', 'No');
        Observer.Expect('onInit', 'No');
        Observer.Expect('onOpenPage', 'No');
        Observer.Expect('testPage', 'No');
        Observer.Expect('testPageField', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadOnlyHandler')]
    procedure ViewModePage_GivenEditableTrue()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Ed Holder";
        Row: Record "LT PnD Ed Row";
        Pg: Page "LT PnD Ed ReadOnly";
    begin
        Seed(Row);
        Holder.ResetSeen();
        Pg.Editable(true);
        Observer.Observe('varAfterSet', Format(Pg.Editable()));
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Observe('onInit', Holder.Get('readonly.oninit'));
        Observer.Observe('onOpenPage', Holder.Get('readonly.onopen'));
        Observer.Observe('testPage', Holder.Get('readonly.page'));
        Observer.Observe('testPageField', Holder.Get('readonly.field'));
        Observer.Expect('varAfterSet', 'Yes');
        Observer.Expect('onInit', 'No');
        Observer.Expect('onOpenPage', 'No');
        Observer.Expect('testPage', 'No');
        Observer.Expect('testPageField', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EditableHandler')]
    procedure EditablePage_Untouched()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Ed Holder";
        Row: Record "LT PnD Ed Row";
        Pg: Page "LT PnD Ed Editable";
    begin
        Seed(Row);
        Holder.ResetSeen();
        Observer.Observe('varBeforeRun', Format(Pg.Editable()));
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Observe('onInit', Holder.Get('editable.oninit'));
        Observer.Observe('onOpenPage', Holder.Get('editable.onopen'));
        Observer.Observe('testPage', Holder.Get('editable.page'));
        Observer.Observe('testPageField', Holder.Get('editable.field'));
        Observer.Expect('varBeforeRun', 'Yes');
        Observer.Expect('onInit', 'Yes');
        Observer.Expect('onOpenPage', 'Yes');
        Observer.Expect('testPage', 'Yes');
        Observer.Expect('testPageField', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EditableHandler')]
    procedure EditablePage_GivenEditableFalse()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Ed Holder";
        Row: Record "LT PnD Ed Row";
        Pg: Page "LT PnD Ed Editable";
    begin
        Seed(Row);
        Holder.ResetSeen();
        Pg.Editable(false);
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Observe('onInit', Holder.Get('editable.oninit'));
        Observer.Observe('onOpenPage', Holder.Get('editable.onopen'));
        Observer.Observe('testPage', Holder.Get('editable.page'));
        Observer.Observe('testPageField', Holder.Get('editable.field'));
        Observer.Expect('onInit', 'Yes');
        Observer.Expect('onOpenPage', 'No');
        Observer.Expect('testPage', 'No');
        Observer.Expect('testPageField', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReadOnlyHandler')]
    procedure ViewModePage_EditableTrueThenFalse()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT PnD Ed Holder";
        Row: Record "LT PnD Ed Row";
        Pg: Page "LT PnD Ed ReadOnly";
    begin
        Seed(Row);
        Holder.ResetSeen();
        Pg.Editable(true);
        Pg.Editable(false);
        Observer.Observe('varAfterSets', Format(Pg.Editable()));
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Observe('testPage', Holder.Get('readonly.page'));
        Observer.Observe('testPageField', Holder.Get('readonly.field'));
        Observer.Expect('varAfterSets', 'No');
        Observer.Expect('testPage', 'No');
        Observer.Expect('testPageField', 'No');
        Observer.Verify();
    end;
}
