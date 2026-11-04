// Probe: CaptionClass on page controls whose area is not a number or that has no comma. What reaches the Caption Class codeunit's OnResolveCaptionClass, with which language, how often (at open and at every Caption() read), and what the caption is when nobody resolves it.
// Settles: md:284. md:677 (CaptionClassTranslate) is already measured by tests/al-language/types/PSCaptionClass.al, see the manifest.

codeunit 68719 "W2 Caption Subscriber"
{
    SingleInstance = true;

    var
        Calls: Text;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if not CaptionArea.StartsWith('W2') then
            exit;
        Calls += 'resolve(' + CaptionArea + '|' + CaptionExpr + '|lang_is_session=' + Format(Language = GlobalLanguage()) + '|lang_is_1033=' + Format(Language = 1033) + ')';
        if CaptionArea = 'W2CC' then begin
            Caption := 'resolved:' + CaptionExpr;
            Resolved := true;
        end;
    end;
}

page 68720 "W2 Caption Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Claimed; Rec.Descr)
            {
                ApplicationArea = All;
                CaptionClass = 'W2CC,Hello';
            }
            field(Unclaimed; Rec.Grp)
            {
                ApplicationArea = All;
                CaptionClass = 'W2ZZ,Unclaimed text';
            }
            field(NoComma; Rec."No.")
            {
                ApplicationArea = All;
                CaptionClass = 'W2 No Comma';
            }
            field(FromVariable; ExtraText)
            {
                ApplicationArea = All;
                CaptionClass = 'W2CC,' + Suffix;
            }
            field(SetSuffix; Suffix)
            {
                ApplicationArea = All;
            }
            field(Plain; PlainText)
            {
                ApplicationArea = All;
                Caption = 'Plain caption';
            }
        }
    }

    var
        ExtraText: Text;
        Suffix: Text;
        PlainText: Text;
}

codeunit 68721 "W2 Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OpenPage_WhatTheEventSees()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "W2 Caption Subscriber";
        Pg: TestPage "W2 Caption Card";
    begin
        Subscriber.Take();
        Pg.OpenEdit();
        Observer.Observe('at_open', Subscriber.Take());
        Pg.Close();
        Observer.Expect('at_open', 'resolve(W2CC|Hello|lang_is_session=Yes|lang_is_1033=Yes)resolve(W2ZZ|Unclaimed text|lang_is_session=Yes|lang_is_1033=Yes)resolve(W2CC||lang_is_session=Yes|lang_is_1033=Yes)');
        Observer.Verify();
    end;

    [Test]
    procedure ClaimedArea_CaptionReadTwice()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "W2 Caption Subscriber";
        Pg: TestPage "W2 Caption Card";
    begin
        Pg.OpenEdit();
        Subscriber.Take();
        Observer.Observe('first_read', Pg.Claimed.Caption());
        Observer.Observe('first_read_events', Subscriber.Take());
        Observer.Observe('second_read', Pg.Claimed.Caption());
        Observer.Observe('second_read_events', Subscriber.Take());
        Pg.Close();
        Observer.Expect('first_read', 'resolved:Hello');
        Observer.Expect('first_read_events', '');
        Observer.Expect('second_read', 'resolved:Hello');
        Observer.Expect('second_read_events', '');
        Observer.Verify();
    end;

    [Test]
    procedure UnclaimedArea_CaptionReadTwice()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "W2 Caption Subscriber";
        Pg: TestPage "W2 Caption Card";
    begin
        Pg.OpenEdit();
        Subscriber.Take();
        Observer.Observe('first_read', Pg.Unclaimed.Caption());
        Observer.Observe('first_read_events', Subscriber.Take());
        Observer.Observe('second_read', Pg.Unclaimed.Caption());
        Observer.Observe('second_read_events', Subscriber.Take());
        Pg.Close();
        Observer.Expect('first_read', 'W2ZZ,Unclaimed text');
        Observer.Expect('first_read_events', '');
        Observer.Expect('second_read', 'W2ZZ,Unclaimed text');
        Observer.Expect('second_read_events', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoComma_CaptionRead()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "W2 Caption Subscriber";
        Pg: TestPage "W2 Caption Card";
    begin
        Pg.OpenEdit();
        Subscriber.Take();
        Observer.Observe('read', Pg.NoComma.Caption());
        Observer.Observe('read_events', Subscriber.Take());
        Pg.Close();
        Observer.Expect('read', 'W2 No Comma');
        Observer.Expect('read_events', '');
        Observer.Verify();
    end;

    [Test]
    procedure ExpressionFromPageVariable_FollowsTheVariable()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "W2 Caption Subscriber";
        Pg: TestPage "W2 Caption Card";
    begin
        Pg.OpenEdit();
        Subscriber.Take();
        Observer.Observe('before_set', Pg.FromVariable.Caption());
        Observer.Observe('before_set_events', Subscriber.Take());
        Pg.SetSuffix.SetValue('World');
        Observer.Observe('set_events', Subscriber.Take());
        Observer.Observe('after_set', Pg.FromVariable.Caption());
        Observer.Observe('after_set_events', Subscriber.Take());
        Pg.Close();
        Observer.Expect('before_set', 'resolved:');
        Observer.Expect('before_set_events', '');
        Observer.Expect('set_events', 'resolve(W2CC|World|lang_is_session=Yes|lang_is_1033=Yes)');
        Observer.Expect('after_set', 'resolved:World');
        Observer.Expect('after_set_events', '');
        Observer.Verify();
    end;

    [Test]
    procedure PlainCaption_RaisesNoEvent()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "W2 Caption Subscriber";
        Pg: TestPage "W2 Caption Card";
    begin
        Pg.OpenEdit();
        Subscriber.Take();
        Observer.Observe('read', Pg.Plain.Caption());
        Observer.Observe('read_events', Subscriber.Take());
        Pg.Close();
        Observer.Expect('read', 'Plain caption');
        Observer.Expect('read_events', '');
        Observer.Verify();
    end;
}
