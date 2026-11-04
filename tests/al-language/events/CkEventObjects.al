// Fixtures for "LT CK Event Leads" (84712). Corpus issue 669 (odd AL behavior leads, part D), items 3, 4, 5, 8, 9, 10, 11, 12, 14, 15.
// Every subscriber codeunit is EventSubscriberInstance = Manual, so it runs only while a test binds it.
// Compile results of these declarations (same on BC 27, 28, 29): AL0547 warning on the GlobalVarAccess events, AL0588 warning on the
// Enum-as-Option subscriber, AL0593 warning on the Text[30] subscribers, AL0635 warning on the OnPrem-scoped subscriber.

table 84700 "LT CK Ev Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer)
        {
            trigger OnValidate()
            begin
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 84701 "LT CK Ev Enum"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
    value(5; C) { }
}

codeunit 84702 "LT CK Ev Log"
{
    SingleInstance = true;

    var
        Lines: Text;
        Member: Integer;

    procedure Reset()
    begin
        Lines := '';
        Member := 0;
    end;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Text(): Text
    begin
        exit(Lines);
    end;

    procedure SetMember(Value: Integer)
    begin
        Member := Value;
    end;

    procedure GetMember(): Integer
    begin
        exit(Member);
    end;
}

codeunit 84703 "LT CK Ev Pub"
{
    var
        G: Integer;

    procedure SetG(Value: Integer)
    begin
        G := Value;
    end;

    procedure GetG(): Integer
    begin
        exit(G);
    end;

    procedure RaiseEnum(E: Enum "LT CK Ev Enum")
    begin
        OnEnum(E);
    end;

    procedure RaiseOption(Ordinal: Integer)
    var
        O: Option A,B,C;
    begin
        O := Ordinal;
        OnOption(O);
    end;

    procedure RaiseText(Value: Text[100]; var VT: Text[100])
    begin
        OnText(Value, VT);
    end;

    procedure RaiseHandled(Initial: Boolean): Boolean
    var
        Handled: Boolean;
    begin
        Handled := Initial;
        OnHandled(Handled, 7);
        exit(Handled);
    end;

    procedure RaiseGlobalRead()
    begin
        OnGlobalRead(1);
    end;

    procedure RaiseGlobalWrite()
    begin
        OnGlobalWrite(1);
    end;

    procedure RaiseScoped(): Integer
    var
        X: Integer;
    begin
        X := 1;
        OnScoped(X);
        exit(X);
    end;

    procedure RaiseNoSubscribers(): Integer
    var
        X: Integer;
    begin
        X := 3;
        OnNoSubscribers(X);
        exit(X);
    end;

    procedure RaiseIsolated(): Integer
    var
        Counter: Integer;
    begin
        Counter := 1;
        OnIsolated(Counter);
        exit(Counter);
    end;

    procedure RaisePerm(): Integer
    var
        X: Integer;
    begin
        X := 1;
        OnPerm(X);
        exit(X);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnum(E: Enum "LT CK Ev Enum")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOption(O: Option A,B,C)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnText(T: Text[100]; var VT: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandled(var Handled: Boolean; Plain: Integer)
    begin
    end;

    [IntegrationEvent(false, true)]
    local procedure OnGlobalRead(X: Integer)
    begin
    end;

    [IntegrationEvent(false, true)]
    local procedure OnGlobalWrite(X: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnScoped(var X: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNoSubscribers(var X: Integer)
    begin
    end;

    [IntegrationEvent(false, false, true)]
    local procedure OnIsolated(var Counter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPerm(var X: Integer)
    begin
    end;
}

// Items 5, 10, 11, 12, 14, 15: parameter matching.
codeunit 84704 "LT CK Ev Subs"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT CK Ev Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnEnum', '', false, false)]
    local procedure EnumAsOption(E: Option A,B,C)
    begin
        Log.Add('opt=' + Format(E) + '/' + Format(E, 0, 2));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnOption', '', false, false)]
    local procedure OptionOtherMembers(O: Option X,Y)
    begin
        Log.Add('xy=' + Format(O) + '/' + Format(O, 0, 2));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnText', '', false, false)]
    local procedure TextSmaller(T: Text[30]; var VT: Text[30])
    begin
        Log.Add('t=' + Format(StrLen(T)) + ',vt=' + Format(StrLen(VT)));
        VT := 'sub';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnHandled', '', false, false)]
    local procedure HandledByValue(Handled: Boolean)
    begin
        Log.Add('entry=' + Format(Handled));
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnGlobalRead', '', false, false)]
    local procedure GlobalRead(X: Integer; G: Integer)
    begin
        Log.Add('g=' + Format(G));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnGlobalWrite', '', false, false)]
    local procedure GlobalWrite(var G: Integer)
    begin
        G := G + 100;
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CK Ev Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsertReordered(RunTrigger: Boolean; var Rec: Record "LT CK Ev Row")
    begin
        Log.Add('bi=' + Format(RunTrigger) + '/' + Format(Rec.Id));
        Rec.Val := 7;
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CK Ev Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsertOtherCase(var REC: Record "LT CK Ev Row"; runtrigger: Boolean)
    begin
        Log.Add('ai=' + Format(runtrigger) + '/' + Format(REC.Val));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT CK Ev Row", 'OnAfterValidateEvent', 'Val', false, false)]
    local procedure AfterValidateSubset(CurrFieldNo: Integer; var Rec: Record "LT CK Ev Row")
    begin
        Log.Add('av=' + Format(CurrFieldNo) + '/' + Format(Rec.Val));
        Rec.Val := Rec.Val + 1;
    end;
}

// Item 3: a subscriber with Scope OnPrem in a Cloud app on a Cloud publisher (warning AL0635).
codeunit 84705 "LT CK Ev OnPrem Sub"
{
    EventSubscriberInstance = Manual;

    [Scope('OnPrem')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnScoped', '', false, false)]
    local procedure OnScoped(var X: Integer)
    begin
        X := 42;
    end;
}

// Item 9: one isolated subscriber changes the var argument and a SingleInstance member, then raises.
codeunit 84706 "LT CK Ev Iso Sub"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT CK Ev Log";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnIsolated', '', false, false)]
    local procedure OnIsolated(var Counter: Integer)
    var
        Row: Record "LT CK Ev Row";
    begin
        Counter := 10;
        Log.SetMember(99);
        Log.Add('iso');
        Row.Id := 84706;
        Row.Insert();
        Error('LT-CK-ISO-FAILED');
    end;
}

// Item 8: a page without SourceTable and a subscriber to its OnOpenPageEvent.
page 84707 "LT CK Ev NoSrc"
{
    PageType = Card;
    UsageCategory = None;
    Caption = 'LT CK Ev NoSrc';
}

codeunit 84708 "LT CK Ev Page Sub"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT CK Ev Log";

    [EventSubscriber(ObjectType::Page, Page::"LT CK Ev NoSrc", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPage()
    begin
        Log.Add('open');
    end;
}
