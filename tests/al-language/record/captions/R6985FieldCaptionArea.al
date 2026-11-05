// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 95690, log and OnResolveCaptionClass subscriber 95691 (SingleInstance, used only by
//   test codeunit 95692), test codeunit 95692
// Probe: al-runner issue 6985. FieldCaption and FieldRef.Caption of a table field whose literal CaptionClass has an area that is not a number
// ('R6985A,2,1,UOM'), which a subscriber of Caption Class.OnResolveCaptionClass claims (it sets Caption and Resolved); an area the subscriber
// sees but does not claim ('R6985B,x', with and without a Caption property); an area where it sets Caption but leaves Resolved false; per read:
// the caption, every event call (area, expression, whether Language is the session language), and whether a second read of the same field, or
// CaptionClassTranslate of the same text afterwards, raises the event again. Also FieldCaption read in the field's OnValidate trigger.
// BC versions: 29 (27 and 28 by CI)

table 95690 "R6985 CC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Weight; Decimal) { CaptionClass = 'R6985A,2,1,UOM'; }
        field(3; Second; Decimal) { CaptionClass = 'R6985A,second'; }
        field(4; Unclaimed; Decimal) { CaptionClass = 'R6985B,x'; }
        field(5; UnclaimedCap; Decimal) { Caption = 'Has Caption'; CaptionClass = 'R6985B,y'; }
        field(6; NotResolved; Decimal) { CaptionClass = 'R6985N,z'; }
        field(7; RefRead; Decimal) { CaptionClass = 'R6985A,ref'; }
        field(8; Translated; Decimal) { CaptionClass = 'R6985A,tr'; }
        field(9; Validated; Decimal)
        {
            CaptionClass = 'R6985A,val';
            trigger OnValidate()
            begin
                SeenCaption := FieldCaption(Validated);
            end;
        }
        field(10; SeenCaption; Text[250]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 95691 "R6985 CC Log"
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
        if not (CaptionArea in ['R6985A', 'R6985B', 'R6985N']) then
            exit;
        Calls += CaptionArea + '(' + CaptionExpr + ')lang=' + Format(Language = GlobalLanguage()) + ';';
        case CaptionArea of
            'R6985A':
                begin
                    Caption := 'My ' + CaptionExpr;
                    Resolved := true;
                end;
            'R6985N':
                Caption := 'not resolved ' + CaptionExpr;
        end;
    end;
}

codeunit 95692 "R6985 FieldCaption Area"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "R6985 CC Log";

    [Test]
    procedure FieldCaption_ClaimedArea()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R6985 CC Row";
    begin
        Log.Take();
        Observer.Observe('caption', Row.FieldCaption(Weight));
        Observer.Observe('calls', Log.Take());
        Observer.Observe('field name', Row.FieldName(Weight));
        Observer.Observe('calls after field name', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure FieldCaption_ClaimedArea_SecondRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R6985 CC Row";
        Other: Record "R6985 CC Row";
    begin
        Log.Take();
        Observer.Observe('first', Row.FieldCaption(Second));
        Observer.Observe('first calls', Log.Take());
        Observer.Observe('second', Row.FieldCaption(Second));
        Observer.Observe('second calls', Log.Take());
        Observer.Observe('other record', Other.FieldCaption(Second));
        Observer.Observe('other record calls', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure FieldCaption_UnclaimedArea()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R6985 CC Row";
    begin
        Log.Take();
        Observer.Observe('no caption property', Row.FieldCaption(Unclaimed));
        Observer.Observe('no caption property calls', Log.Take());
        Observer.Observe('caption property', Row.FieldCaption(UnclaimedCap));
        Observer.Observe('caption property calls', Log.Take());
        Observer.Observe('caption set, not resolved', Row.FieldCaption(NotResolved));
        Observer.Observe('caption set, not resolved calls', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefCaption_ClaimedArea()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Log.Take();
        RecRef.Open(Database::"R6985 CC Row");
        FldRef := RecRef.Field(7);
        Observer.Observe('caption', FldRef.Caption());
        Observer.Observe('calls', Log.Take());
        Observer.Observe('again', FldRef.Caption());
        Observer.Observe('again calls', Log.Take());
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure FieldCaption_ThenCaptionClassTranslate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R6985 CC Row";
    begin
        Log.Take();
        Observer.Observe('field caption', Row.FieldCaption(Translated));
        Observer.Observe('field caption calls', Log.Take());
        Observer.Observe('translate', CaptionClassTranslate('R6985A,tr'));
        Observer.Observe('translate calls', Log.Take());
        Observer.Observe('translate other', CaptionClassTranslate('R6985A,tr2'));
        Observer.Observe('translate other calls', Log.Take());
        Observer.Observe('field caption after', Row.FieldCaption(Translated));
        Observer.Observe('field caption after calls', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure FieldCaption_InOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "R6985 CC Row";
    begin
        Log.Take();
        Row.Validate(Validated, 1);
        Observer.Observe('seen', Row.SeenCaption);
        Observer.Observe('calls', Log.Take());
        Observer.Finish();
    end;
}
