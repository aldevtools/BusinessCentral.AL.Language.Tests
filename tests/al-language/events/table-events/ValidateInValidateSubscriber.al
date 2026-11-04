// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 95242, codeunits 95243 (subscribers), 95244 (log),
//   95245 (helper), test codeunit 95246
// Probe (al-runner issue 6924, item 3.9): a subscriber of OnAfterValidateEvent of a field calls Validate of the same field of
//   the same Rec again. Observed: whether the field's OnValidate trigger and the two validate events run for the inner
//   Validate, and which xRec each of them sees (the before-image of the outer Validate, or the record as it is when the
//   inner Validate starts). record/TestXRecContracts.al pins the inner xRec of a Validate that the table's own OnValidate
//   trigger nests; this file covers a Validate nested by an event subscriber and by a codeunit that OnValidate calls.
//   A subscriber that guards with `if Rec.F = xRec.F then exit` and validates again is the shape that must end; the log
//   codeunit stops every nesting at depth 3 so the probe ends either way.
// Result (BC 27.5 service tier, observed by the corpus CI): a Validate that an event subscriber or a codeunit nests runs the
//   before event, OnValidate and the after event again, and each of them sees as xRec the record as it was when that inner
//   Validate started (not the outer before-image), so the xRec guard ends the nesting.
// BC versions: 27-29

table 95242 "LT VS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Loc; Code[10])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT VS Log";
                Helper: Codeunit "LT VS Helper";
            begin
                Log.Add('T(rec=' + Rec.Loc + ',x=' + xRec.Loc + ',cur=' + Format(CurrFieldNo) + ')');
                if (Log.Mode() = 4) and Log.Enter() then begin
                    Helper.Revalidate(Rec);
                    Log.Leave();
                end;
            end;
        }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 95244 "LT VS Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CurrentMode: Integer;
        Depth: Integer;

    procedure Start(NewMode: Integer)
    begin
        Entries := '';
        CurrentMode := NewMode;
        Depth := 0;
    end;

    procedure Mode(): Integer
    begin
        exit(CurrentMode);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    begin
        exit(Entries);
    end;

    // True while fewer than 3 nested calls are open; the caller calls Leave after its nested Validate.
    procedure Enter(): Boolean
    begin
        if Depth >= 3 then begin
            Add('stop');
            exit(false);
        end;
        Depth += 1;
        exit(true);
    end;

    procedure Leave()
    begin
        Depth -= 1;
    end;
}

codeunit 95245 "LT VS Helper"
{
    procedure Revalidate(var Row: Record "LT VS Row")
    begin
        Row.Validate(Loc, 'INNER');
    end;
}

codeunit 95243 "LT VS Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"LT VS Row", 'OnBeforeValidateEvent', 'Loc', false, false)]
    local procedure BeforeValidateLoc(var Rec: Record "LT VS Row"; var xRec: Record "LT VS Row"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT VS Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('B(rec=' + Rec.Loc + ',x=' + xRec.Loc + ',cur=' + Format(CurrFieldNo) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT VS Row", 'OnAfterValidateEvent', 'Loc', false, false)]
    local procedure AfterValidateLoc(var Rec: Record "LT VS Row"; var xRec: Record "LT VS Row"; CurrFieldNo: Integer)
    var
        Log: Codeunit "LT VS Log";
    begin
        if Log.Mode() = 0 then
            exit;
        Log.Add('A(rec=' + Rec.Loc + ',x=' + xRec.Loc + ',cur=' + Format(CurrFieldNo) + ')');
        case Log.Mode() of
            1:
                if Log.Enter() then begin
                    Rec.Validate(Loc);
                    Log.Leave();
                end;
            2:
                if Rec.Loc <> 'INNER' then
                    if Log.Enter() then begin
                        Rec.Validate(Loc, 'INNER');
                        Log.Leave();
                    end;
            3:
                begin
                    if Rec.Loc = xRec.Loc then begin
                        Log.Add('guard exit');
                        exit;
                    end;
                    if Log.Enter() then begin
                        Rec.Validate(Loc);
                        Log.Leave();
                    end;
                end;
            5:
                begin
                    if Rec.Loc = xRec.Loc then begin
                        Log.Add('guard exit');
                        exit;
                    end;
                    if Log.Enter() then begin
                        Rec.Validate(Loc, Rec.Loc);
                        Log.Leave();
                    end;
                end;
        end;
    end;
}

codeunit 95246 "LT VS Validate In Subscriber"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(Mode: Integer; var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT VS Log";
        Row: Record "LT VS Row";
        Stored: Record "LT VS Row";
    begin
        Log.Start(0);
        Row.Id := Mode;
        Row.Loc := 'RED';
        Row.Insert();
        Log.Start(Mode);
        Row.Validate(Loc, 'BLUE');
        Observer.Observe('log', Log.Take());
        Observer.Observe('rec after', Row.Loc);
        Row.Modify();
        Stored.Get(Mode);
        Observer.Observe('stored', Stored.Loc);
        Log.Start(0);
    end;

    [Test]
    procedure AfterValidateSubscriber_ValidatesSameFieldAgain_NoValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(1, Observer);
        Observer.Expect('log', 'B(rec=BLUE,x=RED,cur=0);T(rec=BLUE,x=RED,cur=0);A(rec=BLUE,x=RED,cur=0);B(rec=BLUE,x=BLUE,cur=0);T(rec=BLUE,x=BLUE,cur=0);A(rec=BLUE,x=BLUE,cur=0);stop;');
        Observer.Expect('rec after', 'BLUE');
        Observer.Expect('stored', 'BLUE');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateSubscriber_ValidatesSameFieldAgain_NewValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(2, Observer);
        Observer.Expect('log', 'B(rec=BLUE,x=RED,cur=0);T(rec=BLUE,x=RED,cur=0);A(rec=BLUE,x=RED,cur=0);B(rec=INNER,x=BLUE,cur=0);T(rec=INNER,x=BLUE,cur=0);A(rec=INNER,x=BLUE,cur=0);');
        Observer.Expect('rec after', 'INNER');
        Observer.Expect('stored', 'INNER');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateSubscriber_XRecGuard_ValidatesAgain_NoValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(3, Observer);
        Observer.Expect('log', 'B(rec=BLUE,x=RED,cur=0);T(rec=BLUE,x=RED,cur=0);A(rec=BLUE,x=RED,cur=0);B(rec=BLUE,x=BLUE,cur=0);T(rec=BLUE,x=BLUE,cur=0);A(rec=BLUE,x=BLUE,cur=0);guard exit;');
        Observer.Expect('rec after', 'BLUE');
        Observer.Expect('stored', 'BLUE');
        Observer.Verify();
    end;

    [Test]
    procedure AfterValidateSubscriber_XRecGuard_ValidatesAgain_SameValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(5, Observer);
        Observer.Expect('log', 'B(rec=BLUE,x=RED,cur=0);T(rec=BLUE,x=RED,cur=0);A(rec=BLUE,x=RED,cur=0);B(rec=BLUE,x=BLUE,cur=0);T(rec=BLUE,x=BLUE,cur=0);A(rec=BLUE,x=BLUE,cur=0);guard exit;');
        Observer.Expect('rec after', 'BLUE');
        Observer.Expect('stored', 'BLUE');
        Observer.Verify();
    end;

    [Test]
    procedure OnValidate_CodeunitValidatesSameFieldAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(4, Observer);
        Observer.Expect('log', 'B(rec=BLUE,x=RED,cur=0);T(rec=BLUE,x=RED,cur=0);B(rec=INNER,x=BLUE,cur=0);T(rec=INNER,x=BLUE,cur=0);B(rec=INNER,x=INNER,cur=0);T(rec=INNER,x=INNER,cur=0);B(rec=INNER,x=INNER,cur=0);T(rec=INNER,x=INNER,cur=0);stop;A(rec=INNER,x=INNER,cur=0);A(rec=INNER,x=INNER,cur=0);A(rec=INNER,x=BLUE,cur=0);A(rec=INNER,x=RED,cur=0);');
        Observer.Expect('rec after', 'INNER');
        Observer.Expect('stored', 'INNER');
        Observer.Verify();
    end;
}
