// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clearall-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 85541, table extension 85542, page 85543, page extension 85544, test codeunit 85545
// Probe: corpus issue 670 (AL issues 5730, 4862, 6499): which globals ClearAll() resets when it runs in a table extension, in the base
// table, and in a page extension's OnAfterGetRecord (after the base page's OnAfterGetRecord). The base object and its extension are in
// the same app; the case of an extension from a second app is not covered (it needs a second app).
// Facts (BC 29 local): ClearAll() in a table extension procedure resets the base table's globals and the extension's, and keeps the
// fields (also the extension field); ClearAll() in the base table resets the extension's globals too. ClearAll() in a page extension's
// OnAfterGetRecord resets the base page's globals (set in its OnOpenPage and OnAfterGetRecord) and keeps Rec.
// BC versions: 27.5, 28.5, 29.0
table 85541 "LT CY CA Row"
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

    var
        BaseGlob: Integer;

    procedure SetBase(Value: Integer)
    begin
        BaseGlob := Value;
    end;

    procedure GetBase(): Integer
    begin
        exit(BaseGlob);
    end;

    procedure ClearAllInBase()
    begin
        ClearAll();
    end;
}

tableextension 85542 "LT CY CA Row Ext" extends "LT CY CA Row"
{
    fields
    {
        field(85540; ExtNo; Integer) { DataClassification = SystemMetadata; }
    }

    var
        ExtGlob: Integer;

    procedure SetExt(Value: Integer)
    begin
        ExtGlob := Value;
    end;

    procedure GetExt(): Integer
    begin
        exit(ExtGlob);
    end;

    procedure ClearAllInExt()
    begin
        ClearAll();
    end;
}

page 85543 "LT CY CA Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT CY CA Row";

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { }
            field(NameCtl; Rec.Name) { }
            field(PageGlobCtl; PageGlob) { Editable = false; }
            field(PageOpenCtl; PageOpen) { Editable = false; }
        }
    }

    var
        PageGlob: Integer;
        PageOpen: Integer;

    trigger OnOpenPage()
    begin
        PageOpen := 3;
    end;

    trigger OnAfterGetRecord()
    begin
        PageGlob := 42;
    end;
}

pageextension 85544 "LT CY CA Card Ext" extends "LT CY CA Card"
{
    layout
    {
        addlast(Content)
        {
            field(ExtGlobCtl; ExtPageGlob) { ApplicationArea = All; Editable = false; }
            field(ExtSeenCtl; ExtSeen) { ApplicationArea = All; Editable = false; }
        }
    }

    var
        ExtPageGlob: Integer;
        ExtSeen: Integer;

    trigger OnOpenPage()
    begin
        ExtPageGlob := 9;
    end;

    trigger OnAfterGetRecord()
    begin
        ClearAll();
        ExtSeen := 1;
    end;
}

codeunit 85545 "LT CY ClearAll Extensions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CY_ClearAll_InTableExtension_And_BaseTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CY CA Row";
    begin
        Row.Id := 1;
        Row.Name := 'n';
        Row.ExtNo := 4;
        Row.SetBase(5);
        Row.SetExt(6);
        Row.ClearAllInExt();
        Observer.Observe('in ext: base glob', Format(Row.GetBase()));
        Observer.Observe('in ext: ext glob', Format(Row.GetExt()));
        Observer.Observe('in ext: fields', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.ExtNo));
        Row.SetBase(5);
        Row.SetExt(6);
        Row.ClearAllInBase();
        Observer.Observe('in base: base glob', Format(Row.GetBase()));
        Observer.Observe('in base: ext glob', Format(Row.GetExt()));
        Observer.Observe('in base: fields', Format(Row.Id) + '|' + Row.Name + '|' + Format(Row.ExtNo));
        Observer.Expect('in ext: base glob', '0');
        Observer.Expect('in ext: ext glob', '0');
        Observer.Expect('in ext: fields', '1|n|4');
        Observer.Expect('in base: base glob', '0');
        Observer.Expect('in base: ext glob', '0');
        Observer.Expect('in base: fields', '1|n|4');
        Observer.Verify();
    end;

    [Test]
    procedure CY_ClearAll_InPageExtension_OnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CY CA Row";
        Card: TestPage "LT CY CA Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'n';
        Row.Insert();
        Card.OpenView();
        Card.GoToKey(1);
        Observer.Observe('page glob', Card.PageGlobCtl.Value());
        Observer.Observe('page open glob', Card.PageOpenCtl.Value());
        Observer.Observe('ext glob', Card.ExtGlobCtl.Value());
        Observer.Observe('ext seen', Card.ExtSeenCtl.Value());
        Observer.Observe('rec', Card.IdCtl.Value() + '|' + Card.NameCtl.Value());
        Card.Close();
        Observer.Expect('page glob', '0');
        Observer.Expect('page open glob', '0');
        Observer.Expect('ext glob', '0');
        Observer.Expect('ext seen', '1');
        Observer.Expect('rec', '1|n');
        Observer.Verify();
    end;
}
