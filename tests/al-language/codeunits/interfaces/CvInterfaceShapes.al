// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 85360-85363
// Facts: corpus issue 670 (odd AL behavior leads, part E): an interface variable assigned from an enum FlowField (with and without CalcFields,
//   and for an ordinal without an implementation); interface methods that return a Record, a Codeunit or a Page; a Codeunit return value
//   passed up through several call levels; an interface method with a `var ... temporary` record parameter.
//   Compile-time halves: must-not-compile cases 1768 (implementation drops `temporary`: AL0582), 1769 (interface from an enum that does not
//   implement it: AL0122), 1770 (`case` over a Record: AL0698).
// Leads: microsoft/AL issues 5926, 6647, 6652, 6679, 6156, 5675.
// Probe: values observed on a local BC 29.0 tier; 27.5 and 28.5 checked by the corpus CI.
// BC versions: 27, 28, 29
interface "LT CV I Shapes"
{
    procedure Name(): Text;
    procedure GetRec(Id: Integer): Record "LT CV Shape Row";
    procedure GetCu(Tag: Text): Codeunit "LT CV Shape Helper";
    procedure GetPage(Tag: Text): Page "LT CV Shape Card";
    procedure Fill(var TempBuf: Record "LT CV Shape Row" temporary): Text;
}

enum 85360 "LT CV Shape Kind" implements "LT CV I Shapes"
{
    Extensible = false;

    value(0; Alpha)
    {
        Implementation = "LT CV I Shapes" = "LT CV Shape Impl A";
    }
    value(1; Beta)
    {
        Implementation = "LT CV I Shapes" = "LT CV Shape Impl B";
    }
}

table 85360 "LT CV Shape Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT CV Shape Kind") { }
        field(3; LookupId; Integer) { }
        field(4; KindFf; Enum "LT CV Shape Kind")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT CV Shape Row".Kind where(Id = field(LookupId)));
        }
        field(5; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 85360 "LT CV Shape Card"
{
    PageType = Card;
    SourceTable = "LT CV Shape Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    var
        PageTag: Text;

    procedure SetTag(NewTag: Text)
    begin
        PageTag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(PageTag);
    end;
}

codeunit 85362 "LT CV Shape Helper"
{
    var
        HelperTag: Text;

    procedure SetTag(NewTag: Text)
    begin
        HelperTag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(HelperTag);
    end;
}

codeunit 85360 "LT CV Shape Impl A" implements "LT CV I Shapes"
{
    procedure Name(): Text
    begin
        exit('A');
    end;

    procedure GetRec(Id: Integer): Record "LT CV Shape Row"
    var
        R: Record "LT CV Shape Row";
    begin
        R.Id := Id;
        R.Name := 'from A';
        R.Kind := R.Kind::Beta;
        exit(R);
    end;

    procedure GetCu(Tag: Text): Codeunit "LT CV Shape Helper"
    var
        H: Codeunit "LT CV Shape Helper";
    begin
        H.SetTag('A:' + Tag);
        exit(H);
    end;

    procedure GetPage(Tag: Text): Page "LT CV Shape Card"
    var
        P: Page "LT CV Shape Card";
    begin
        P.SetTag('A:' + Tag);
        exit(P);
    end;

    procedure Fill(var TempBuf: Record "LT CV Shape Row" temporary): Text
    begin
        TempBuf.Id := 1;
        TempBuf.Name := 'A1';
        TempBuf.Insert();
        TempBuf.Id := 2;
        TempBuf.Name := 'A2';
        TempBuf.Insert();
        exit(Format(TempBuf.IsTemporary()));
    end;
}

codeunit 85361 "LT CV Shape Impl B" implements "LT CV I Shapes"
{
    procedure Name(): Text
    begin
        exit('B');
    end;

    procedure GetRec(Id: Integer): Record "LT CV Shape Row"
    var
        R: Record "LT CV Shape Row";
    begin
        R.Id := Id + 100;
        R.Name := 'from B';
        exit(R);
    end;

    procedure GetCu(Tag: Text): Codeunit "LT CV Shape Helper"
    var
        H: Codeunit "LT CV Shape Helper";
    begin
        H.SetTag('B:' + Tag);
        exit(H);
    end;

    procedure GetPage(Tag: Text): Page "LT CV Shape Card"
    var
        P: Page "LT CV Shape Card";
    begin
        P.SetTag('B:' + Tag);
        exit(P);
    end;

    procedure Fill(var TempBuf: Record "LT CV Shape Row" temporary): Text
    begin
        TempBuf.Id := 7;
        TempBuf.Name := 'B7';
        TempBuf.Insert();
        exit(Format(TempBuf.IsTemporary()));
    end;
}

codeunit 85363 "LT CV Interface Shape Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT CV Shape Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Kind := R.Kind::Beta;
        R.Insert();
        R.Id := 2;
        R.Kind := R.Kind::Alpha;
        R.LookupId := 1;
        R.Insert();
    end;

    [TryFunction]
    local procedure TryAssign(Kind: Enum "LT CV Shape Kind"; var I: Interface "LT CV I Shapes")
    begin
        I := Kind;
    end;

    [TryFunction]
    local procedure TryAssignAndCall(Kind: Enum "LT CV Shape Kind")
    var
        I: Interface "LT CV I Shapes";
    begin
        I := Kind;
        I.Name();
    end;

    local procedure Level3(Tag: Text): Codeunit "LT CV Shape Helper"
    var
        I: Interface "LT CV I Shapes";
    begin
        I := Enum::"LT CV Shape Kind"::Beta;
        exit(I.GetCu(Tag));
    end;

    local procedure Level2(Tag: Text): Codeunit "LT CV Shape Helper"
    begin
        exit(Level3(Tag + '2'));
    end;

    local procedure Level1(Tag: Text): Codeunit "LT CV Shape Helper"
    begin
        exit(Level2(Tag + '1'));
    end;

    [Test]
    procedure EnumFlowField_ToInterface()
    var
        R: Record "LT CV Shape Row";
        I: Interface "LT CV I Shapes";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Get(2);
        I := R.KindFf;
        Observer.Observe('no_calcfields|ff', Format(R.KindFf));
        Observer.Observe('no_calcfields|name', I.Name());
        R.CalcFields(KindFf);
        I := R.KindFf;
        Observer.Observe('calcfields|ff', Format(R.KindFf));
        Observer.Observe('calcfields|name', I.Name());
        R.LookupId := 99;
        R.CalcFields(KindFf);
        I := R.KindFf;
        Observer.Observe('no_target|ff', Format(R.KindFf));
        Observer.Observe('no_target|name', I.Name());
        Observer.Expect('no_calcfields|ff', 'Alpha');
        Observer.Expect('no_calcfields|name', 'A');
        Observer.Expect('calcfields|ff', 'Beta');
        Observer.Expect('calcfields|name', 'B');
        Observer.Expect('no_target|ff', 'Alpha');
        Observer.Expect('no_target|name', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure EnumField_OrdinalWithoutImplementation()
    var
        R: Record "LT CV Shape Row";
        I: Interface "LT CV I Shapes";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        R.Kind := Enum::"LT CV Shape Kind".FromInteger(5);
        Observer.Observe('ordinal', Format(R.Kind.AsInteger()));
        ClearLastError();
        Ok := TryAssign(R.Kind, I);
        Observer.Observe('assign|ok', Format(Ok));
        Observer.ObserveError('assign');
        ClearLastError();
        Ok := TryAssignAndCall(R.Kind);
        Observer.Observe('assign_call|ok', Format(Ok));
        Observer.ObserveError('assign_call');
        Observer.Expect('ordinal', '5');
        Observer.Expect('assign|ok', 'No');
        Observer.Expect('assign|text', 'Enum does not contain value 5.');
        Observer.Expect('assign|code', 'ArgumentOutOfRange');
        Observer.Expect('assign_call|ok', 'No');
        Observer.Expect('assign_call|text', 'Enum does not contain value 5.');
        Observer.Expect('assign_call|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure InterfaceReturnsRecord()
    var
        R: Record "LT CV Shape Row";
        I: Interface "LT CV I Shapes";
        Observer: Codeunit "Probe Observer";
    begin
        I := Enum::"LT CV Shape Kind"::Alpha;
        R := I.GetRec(5);
        Observer.Observe('a|id', Format(R.Id));
        Observer.Observe('a|name', R.Name);
        Observer.Observe('a|kind', Format(R.Kind));
        I := Enum::"LT CV Shape Kind"::Beta;
        Observer.Observe('b|direct_id', Format(I.GetRec(5).Id));
        Observer.Observe('b|direct_name', I.GetRec(5).Name);
        Observer.Expect('a|id', '5');
        Observer.Expect('a|name', 'from A');
        Observer.Expect('a|kind', 'Beta');
        Observer.Expect('b|direct_id', '105');
        Observer.Expect('b|direct_name', 'from B');
        Observer.Verify();
    end;

    [Test]
    procedure InterfaceReturnsCodeunitAndPage()
    var
        H: Codeunit "LT CV Shape Helper";
        P: Page "LT CV Shape Card";
        I: Interface "LT CV I Shapes";
        Observer: Codeunit "Probe Observer";
    begin
        I := Enum::"LT CV Shape Kind"::Alpha;
        H := I.GetCu('x');
        Observer.Observe('cu|var', H.GetTag());
        Observer.Observe('cu|direct', I.GetCu('y').GetTag());
        P := I.GetPage('p');
        Observer.Observe('page|var', P.GetTag());
        I := Enum::"LT CV Shape Kind"::Beta;
        Observer.Observe('page|direct', I.GetPage('q').GetTag());
        Observer.Expect('cu|var', 'A:x');
        Observer.Expect('cu|direct', 'A:y');
        Observer.Expect('page|var', 'A:p');
        Observer.Expect('page|direct', 'B:q');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitReturnThroughCallLevels()
    var
        H: Codeunit "LT CV Shape Helper";
        Observer: Codeunit "Probe Observer";
    begin
        H := Level1('t');
        Observer.Observe('levels|var', H.GetTag());
        Observer.Observe('levels|direct', Level1('u').GetTag());
        Observer.Expect('levels|var', 'B:t12');
        Observer.Expect('levels|direct', 'B:u12');
        Observer.Verify();
    end;

    [Test]
    procedure TemporaryRecordParameter()
    var
        TempBuf: Record "LT CV Shape Row" temporary;
        R: Record "LT CV Shape Row";
        I: Interface "LT CV I Shapes";
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        I := Enum::"LT CV Shape Kind"::Alpha;
        Observer.Observe('a|istemp_inside', I.Fill(TempBuf));
        Observer.Observe('a|temp_count', Format(TempBuf.Count()));
        Observer.Observe('a|db_count', Format(R.Count()));
        I := Enum::"LT CV Shape Kind"::Beta;
        Observer.Observe('b|istemp_inside', I.Fill(TempBuf));
        Observer.Observe('b|temp_count', Format(TempBuf.Count()));
        Observer.Observe('b|db_count', Format(R.Count()));
        Observer.Expect('a|istemp_inside', 'Yes');
        Observer.Expect('a|temp_count', '2');
        Observer.Expect('a|db_count', '0');
        Observer.Expect('b|istemp_inside', 'Yes');
        Observer.Expect('b|temp_count', '3');
        Observer.Expect('b|db_count', '0');
        Observer.Verify();
    end;
}
