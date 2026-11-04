// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021);
//                self-contained pages 68230, 68231, codeunits 68232 (tests), 68233 (log)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the order of the close triggers of a host and its parts, that Enabled reads the part control's
// property while Editable = false on a part control does not stop a TestPage from writing through it,
// how SubPageView and SubPageLink combine, and which rows a part shows when the host row is new (a blank link
// value).
// BC versions: 27.5

codeunit 68233 "Probe Part Close Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

page 68230 "Probe PT Part"
{
    PageType = ListPart;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Text Field"; Rec."Text Field") { ApplicationArea = All; }
            }
        }
    }

    var
        PartLog: Codeunit "Probe Part Close Log";

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        PartLog.Add('part.OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        PartLog.Add('part.OnClosePage');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        PartLog.Add('part.OnModifyRecord');
        exit(true);
    end;
}

page 68231 "Probe PT Host"
{
    PageType = Card;
    SourceTable = "ALT Universal";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            part(Linked; "Probe PT Part")
            {
                ApplicationArea = All;
                SubPageLink = "Integer Field" = field("Entry No.");
            }
            part(ReadOnlyPart; "Probe PT Part")
            {
                ApplicationArea = All;
                Editable = false;
                SubPageLink = "Integer Field" = field("Entry No.");
            }
            part(DisabledPart; "Probe PT Part")
            {
                ApplicationArea = All;
                Enabled = false;
                SubPageLink = "Integer Field" = field("Entry No.");
            }
            part(ViewPart; "Probe PT Part")
            {
                ApplicationArea = All;
                SubPageView = where("Text Field" = const('v'));
                SubPageLink = "Integer Field" = field("Entry No.");
            }
        }
    }

    var
        PartLog: Codeunit "Probe Part Close Log";

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        PartLog.Add('host.OnQueryClosePage');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        PartLog.Add('host.OnClosePage');
    end;
}

codeunit 68232 "Probe Part Close Link"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        PartLog: Codeunit "Probe Part Close Log";

    local procedure Initialize()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Cleanup.Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 2;
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 11;
        ALTUniversal."Integer Field" := 1;
        ALTUniversal."Text Field" := 'v';
        ALTUniversal.Insert();
        ALTUniversal."Entry No." := 12;
        ALTUniversal."Text Field" := 'w';
        ALTUniversal.Insert();
        Commit();
        PartLog.Take();
    end;

    local procedure LinkedRows(var Host: TestPage "Probe PT Host"): Text
    var
        Result: Text;
    begin
        if Host.Linked.First() then
            repeat
                Result += Host.Linked."Entry No.".Value() + ' ';
            until not Host.Linked.Next();
        exit(Result);
    end;

    local procedure ViewRows(var Host: TestPage "Probe PT Host"): Text
    var
        Result: Text;
    begin
        if Host.ViewPart.First() then
            repeat
                Result += Host.ViewPart."Entry No.".Value() + ' ';
            until not Host.ViewPart.Next();
        exit(Result);
    end;

    [Test]
    procedure Parts_CloseTriggers_AllPartsQueryClose_ThenHost_ThenPartsClose_ThenHost()
    var
        Host: TestPage "Probe PT Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);
        PartLog.Take();

        Host.Close();

        Assert.AreEqual('part.OnQueryClosePage(None);part.OnQueryClosePage(None);part.OnQueryClosePage(None);part.OnQueryClosePage(None);host.OnQueryClosePage;part.OnClosePage;part.OnClosePage;part.OnClosePage;part.OnClosePage;host.OnClosePage;', PartLog.Take(), 'order');
    end;

    [Test]
    procedure Parts_EnabledReadsTheControl_EditableFalseDoesNotBlockWrites()
    var
        Host: TestPage "Probe PT Host";
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);

        Assert.IsTrue(Host.Linked.Enabled(), 'enabled part');
        Assert.IsFalse(Host.DisabledPart.Enabled(), 'Enabled = false on the part control');
        Assert.IsTrue(Host.Linked.Visible(), 'visible');
        Assert.IsTrue(Host.ReadOnlyPart.Editable(), 'Editable = false on the control is not reported');

        Host.ReadOnlyPart.First();
        Host.ReadOnlyPart."Text Field".SetValue('ro-write');
        PartLog.Take();
        Host.ReadOnlyPart.Next();

        Assert.IsTrue(PartLog.Take().StartsWith('part.OnModifyRecord;'), 'the row was saved when the cursor left it');
        ALTUniversal.Get(11);
        Assert.AreEqual('ro-write', ALTUniversal."Text Field", 'the write went through');
        Host.Close();
    end;

    [Test]
    procedure Parts_SubPageView_AndLink_AreCombined_BlankHostLinksToBlankValue()
    var
        Host: TestPage "Probe PT Host";
    begin
        Initialize();
        Host.OpenEdit();
        Host.GoToKey(1);

        Assert.AreEqual('11 12 0 ', LinkedRows(Host), 'the link alone, and the blank new-row line at the end');
        Assert.AreEqual('11 0 ', ViewRows(Host), 'the view and the link together');

        Host.GoToKey(2);
        Assert.AreEqual('', LinkedRows(Host), 'a host row no part row links to: not even a blank line, as the first read finds nothing');
        Host.Close();
    end;
}
