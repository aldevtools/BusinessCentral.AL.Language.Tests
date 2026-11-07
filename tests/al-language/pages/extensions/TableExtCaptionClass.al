// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own table 72304, tableextension 72305, page 72306, codeunit 72307
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72304 "LT P123 CCBase"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 72305 "LT P123 CCBase Ext" extends "LT P123 CCBase"
{
    fields
    {
        field(72303; CapClassed; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Plain caption';
            CaptionClass = '3,Class caption';
        }
    }
}

page 72306 "LT P123 CCBase Page"
{
    PageType = Card;
    SourceTable = "LT P123 CCBase";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(CapClassed; Rec.CapClassed) { ApplicationArea = All; }
        }
    }
}

// Writer BP (corpus issue 664, microsoft/AL issue 7813): CaptionClass of a table extension set to a procedure call, in modify() of a
// base field (with FieldNo as the argument) and on a new field (a procedure without parentheses). The app once failed to publish (C# CS0029).
tableextension 82554 "LT BP CCBase Ext" extends "LT P123 CCBase"
{
    fields
    {
        modify(Id) { CaptionClass = BP_GetCaptionClass(FieldNo(Id)); }
        field(82554; "BP Style Code"; Code[20])
        {
            DataClassification = SystemMetadata;
            CaptionClass = BP_GetCaptionClass82554;
        }
    }

    procedure BP_GetCaptionClass(FldNo: Integer): Text[80]
    begin
        exit('3,Stand in ' + Format(FldNo));
    end;

    procedure BP_GetCaptionClass82554(): Text
    begin
        exit(BP_GetCaptionClass(82554));
    end;
}

page 82555 "LT BP CCBase Page"
{
    PageType = Card;
    SourceTable = "LT P123 CCBase";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(StyleCode; Rec."BP Style Code") { ApplicationArea = All; }
        }
    }
}
codeunit 72307 "LT P123 CaptionClass Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_ExtFieldCaptionClass()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 CCBase";
        P: TestPage "LT P123 CCBase Page";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1; T.Insert();
        Observer.Observe('fieldcaption', T.FieldCaption(CapClassed));
        P.OpenEdit();
        Observer.Observe('page field caption', P.CapClassed.Caption());
        Observer.Expect('fieldcaption', 'Class caption');
        Observer.Expect('page field caption', 'Class caption');
        Observer.Verify();
    end;

    // Writer BP (corpus issue 664, microsoft/AL issue 7813).
    [Test]
    procedure BP_TableExtCaptionClass_ProcedureCall()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 CCBase";
        P: TestPage "LT BP CCBase Page";
    begin
        T.DeleteAll();
        T.Id := 1;
        T.Insert();
        Observer.Observe('modify FieldCaption', T.FieldCaption(Id));
        Observer.Observe('new field FieldCaption', T.FieldCaption("BP Style Code"));
        P.OpenView();
        Observer.Observe('modify page caption', P.Id.Caption());
        Observer.Observe('new field page caption', P.StyleCode.Caption());
        P.Close();
        Observer.Expect('modify FieldCaption', 'Stand in 1');
        Observer.Expect('new field FieldCaption', 'Stand in 82554');
        Observer.Expect('modify page caption', 'Stand in 1');
        Observer.Expect('new field page caption', 'Stand in 82554');
        Observer.Verify();
    end;

    // Cross-app ownership: public dependency procedure versus local tableextension procedure.
    // Expected branch markers are a probe hypothesis until genuine native CI adjudicates them.
    [Test]
    procedure TableExt_CrossApp_BareCallSelectsLocal()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.ExtensionBare());
        Observer.Expect('result', '3,Extension 19');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CrossApp_BaseCallKeepsBase()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.BaseCall());
        Observer.Expect('result', '3,Base 17');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CrossApp_AddedCaptionSelectsLocal()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.FieldCaption(CollisionCaption));
        Observer.Expect('result', 'Extension 97890');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CrossApp_ModifiedCaptionSelectsLocal()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.FieldCaption(BaseLabel));
        Observer.Expect('result', 'Extension 2');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CrossApp_UniqueCaptionControl()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.FieldCaption(UniqueCaption));
        Observer.Expect('result', 'Unique 97891');
        Observer.Verify();
    end;

    local procedure Initialize()
    var
        Cleanup: Codeunit ALTFixtureCleanup;
        T: Record "TBL Lexical Owner Base";
    begin
        Cleanup.Initialize();
        T.Init();
        T.Id := 1;
        T.Insert(false);
    end;

    // Unparenthesized lookup and explicitly qualified access are separate observed boundaries.
    [Test]
    procedure TableExt_CrossApp_NoParenCallSelectsLocal()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.ExtensionZeroBare());
        Observer.Expect('result', '3,Extension zero');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CrossApp_NoParenBaseKeepsBase()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.BaseZeroCall());
        Observer.Expect('result', '3,Base zero');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CrossApp_NoParenCaptionSelectsLocal()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.FieldCaption(ZeroCaption));
        Observer.Expect('result', 'Extension zero');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CrossApp_QualifiedCallKeepsBase()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        T.Get(1);
        Observer.Observe('result', T.GetCaptionClass(23));
        Observer.Expect('result', '3,Base 23');
        Observer.Verify();
    end;


    // A bounded base result must not be imposed on the selected unbounded local declaration.
    [Test]
    procedure TableExt_CrossApp_BoundedBase_LongLocalResultStaysUnbounded()
    var
        T: Record "TBL Lexical Owner Base";
        Observer: Codeunit "Probe Observer";
        Actual: Text;
    begin
        Initialize();
        T.Get(1);
        Actual := T.ExtensionLong();
        Observer.Observe('result', Actual);
        Observer.Observe('length', Format(StrLen(Actual)));
        Observer.Expect('result', '3,LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL');
        Observer.Expect('length', '102');
        Observer.Verify();
    end;
}
