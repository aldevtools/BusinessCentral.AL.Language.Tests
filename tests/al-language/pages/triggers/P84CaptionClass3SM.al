// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 89258, pages 89255 - 89257, test codeunit 89259
// Facts: P84Captions.al pins that a control with CaptionClass = '3,' (nothing after the comma) and its own Caption shows the caption of ANOTHER control
//   bound to the same field ('Ctl Plain'). This file pins which caption such a control shows: when it is the only control on its field; when controls on
//   the same field come before and after it; when the other control on the same field has no Caption property; and for a '3,' control on a field whose
//   table field has CaptionClass. Read through TestPage control Caption, also for the other controls.
// BC answers: the '3,' control shows the caption of the LAST control on the page bound to the same field (its Caption, or the table field's
//   caption when that control has no Caption property), even when that control comes after it; when no other control is bound to its field
//   it shows its own Caption, and with no Caption property the table field's caption. '3,x' shows 'x'.
// BC versions: 27, 28, 29

table 89258 "LT SM Cap3 Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Plain; Text[30]) { Caption = 'Plain Field'; }
        field(3; Other; Text[30]) { Caption = 'Other Field'; }
        field(4; Third; Text[30]) { Caption = 'Third Field'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 89255 "LT SM Cap3 Alone"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SM Cap3 Rec";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(OtherCtl; Rec.Other) { ApplicationArea = All; Caption = 'Ctl Other'; }
                field(Cap3; Rec.Plain) { ApplicationArea = All; Caption = 'Own Alone'; CaptionClass = '3,'; }
                field(Cap3NoCaption; Rec.Third) { ApplicationArea = All; CaptionClass = '3,'; }
            }
        }
    }
}

page 89256 "LT SM Cap3 Between"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SM Cap3 Rec";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(FirstCtl; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl First'; }
                field(Cap3; Rec.Plain) { ApplicationArea = All; Caption = 'Own Between'; CaptionClass = '3,'; }
                field(LastCtl; Rec.Plain) { ApplicationArea = All; Caption = 'Ctl Last'; }
                field(Cap3B; Rec.Other) { ApplicationArea = All; Caption = 'Own Other'; CaptionClass = '3,'; }
                field(OtherAfter; Rec.Other) { ApplicationArea = All; Caption = 'Ctl Other After'; }
            }
        }
    }
}

page 89257 "LT SM Cap3 NoCaption"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT SM Cap3 Rec";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Cap3; Rec.Plain) { ApplicationArea = All; Caption = 'Own NoCaption'; CaptionClass = '3,'; }
                field(PlainNoCaption; Rec.Plain) { ApplicationArea = All; }
                field(Cap3Text; Rec.Other) { ApplicationArea = All; Caption = 'Own Text'; CaptionClass = '3,x'; }
                field(OtherNoCaption; Rec.Other) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 89259 "LT SM CaptionClass3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Alone_OnlyControlOnItsField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT SM Cap3 Alone";
    begin
        P.OpenView();
        Observer.Observe('other', P.OtherCtl.Caption());
        Observer.Observe('cap3', P.Cap3.Caption());
        Observer.Observe('cap3 no caption', P.Cap3NoCaption.Caption());
        P.Close();
        Observer.Expect('other', 'Ctl Other');
        Observer.Expect('cap3', 'Own Alone');
        Observer.Expect('cap3 no caption', 'Third Field');
        Observer.Verify();
    end;

    [Test]
    procedure Between_ControlsBeforeAndAfterOnTheSameField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT SM Cap3 Between";
    begin
        P.OpenView();
        Observer.Observe('first', P.FirstCtl.Caption());
        Observer.Observe('cap3', P.Cap3.Caption());
        Observer.Observe('last', P.LastCtl.Caption());
        Observer.Observe('cap3 other', P.Cap3B.Caption());
        Observer.Observe('other after', P.OtherAfter.Caption());
        P.Close();
        Observer.Expect('first', 'Ctl First');
        Observer.Expect('cap3', 'Ctl Last');
        Observer.Expect('last', 'Ctl Last');
        Observer.Expect('cap3 other', 'Ctl Other After');
        Observer.Expect('other after', 'Ctl Other After');
        Observer.Verify();
    end;

    [Test]
    procedure NoCaption_OtherControlWithoutCaptionProperty()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT SM Cap3 NoCaption";
    begin
        P.OpenView();
        Observer.Observe('cap3', P.Cap3.Caption());
        Observer.Observe('plain no caption', P.PlainNoCaption.Caption());
        Observer.Observe('cap3 text', P.Cap3Text.Caption());
        Observer.Observe('other no caption', P.OtherNoCaption.Caption());
        P.Close();
        Observer.Expect('cap3', 'Plain Field');
        Observer.Expect('plain no caption', 'Plain Field');
        Observer.Expect('cap3 text', 'x');
        Observer.Expect('other no caption', 'Other Field');
        Observer.Verify();
    end;
}
