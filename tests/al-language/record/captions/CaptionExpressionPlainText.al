// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 99780, tables 99780 and 99781, log codeunit 99782 (used only by test codeunit 99786), pages
//   99783 to 99785, test codeunit 99786
// local object: the CaptionClass expression is the thing under test, so the tables and pages are own objects (standing rule 2)
// Probe: al-runner issues 7379 (a CaptionClass expression that only calls Enum.AsInteger is refused at the page open) and 7382 (the caption of a
//   field whose CaptionClass expression gives a plain text without a comma is refused). Neighbours: QdCaptionClassAreas.al (areas 1, 2, 5, 101,
//   empty text, '3,'), WcExtFieldAfterResolve.al (a literal without a comma), SxCaptionClassCount.al (counts at page open).
// Facts: the caption FieldCaption, FieldRef.Caption and a Card or List control give for fields whose CaptionClass expression (a) only reads an enum
//   field with AsInteger and gives a label or the formatted enum value, (b) gives the formatted enum value with no comma, (c) gives a label with
//   no comma, (d) gives an empty text, (e) gives 'Area,text' with a non-numeric area, (f) gives a plain text for a field that also has a Caption
//   property; the error text of FieldCaption inside an OnInsert Error; the empty-record and row runs at the page open for an expression that
//   calls AsInteger. Observed on real BC; every literal asserted below is what BC produced.
// BC versions: 27, 28, 29 (corpus CI)

enum 99780 "HC Kind"
{
    Extensible = true;

    value(0; Item) { Caption = 'Item'; }
    value(1; Resource) { Caption = 'Resource'; }
}

table 99780 "HC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "HC Kind") { }
        field(3; AsIntLabel; Code[20]) { CaptionClass = AsIntCaption(); }
        field(4; PlainFormat; Code[20]) { CaptionClass = PlainFormatCaption(); }
        field(5; PlainLabel; Code[20]) { CaptionClass = PlainLabelCaption(); }
        field(6; EmptyText; Code[20]) { CaptionClass = EmptyCaption(); }
        field(7; NonNumericArea; Code[20]) { CaptionClass = NonNumericAreaCaption(); }
        field(8; WithCaption; Code[20]) { Caption = 'Static Caption'; CaptionClass = PlainFormatCaption(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        AlreadyErr: Label 'Already there. %1 = %2.';
    begin
        if Id = 99 then
            Error(AlreadyErr, FieldCaption(PlainFormat), PlainFormat);
    end;

    local procedure AsIntCaption(): Text[80]
    var
        AllLbl: Label 'All';
    begin
        if Kind.AsInteger() = 0 then
            exit(AllLbl)
        else
            exit(Format(Kind));
    end;

    local procedure PlainFormatCaption(): Text[80]
    begin
        exit(Format(Kind));
    end;

    local procedure PlainLabelCaption(): Text[80]
    var
        PlainLbl: Label 'Plain label text';
    begin
        exit(PlainLbl);
    end;

    local procedure EmptyCaption(): Text[80]
    begin
        exit('');
    end;

    local procedure NonNumericAreaCaption(): Text[80]
    begin
        exit('Zed,some text');
    end;
}

table 99781 "HC Count Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "HC Kind") { }
        field(3; Amount; Decimal) { CaptionClass = CountedCaption(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure CountedCaption(): Text[80]
    var
        Log: Codeunit "HC Log";
    begin
        Log.Hit(Id);
        if Kind.AsInteger() = 0 then
            exit('All');
        exit(Format(Kind));
    end;
}

codeunit 99782 "HC Log"
{
    SingleInstance = true;

    var
        EmptyRuns: Integer;
        RowRuns: Integer;

    procedure Hit(RowId: Integer)
    begin
        if RowId = 0 then
            EmptyRuns += 1
        else
            RowRuns += 1;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := 'empty=' + Format(EmptyRuns) + ' rows=' + Format(RowRuns);
        EmptyRuns := 0;
        RowRuns := 0;
        exit(Result);
    end;
}

page 99783 "HC Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "HC Row";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(AsIntLabel; Rec.AsIntLabel) { ApplicationArea = All; }
                field(PlainFormat; Rec.PlainFormat) { ApplicationArea = All; }
                field(PlainLabel; Rec.PlainLabel) { ApplicationArea = All; }
                field(EmptyText; Rec.EmptyText) { ApplicationArea = All; }
                field(NonNumericArea; Rec.NonNumericArea) { ApplicationArea = All; }
                field(WithCaption; Rec.WithCaption) { ApplicationArea = All; }
            }
        }
    }
}

page 99784 "HC List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "HC Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(AsIntLabel; Rec.AsIntLabel) { ApplicationArea = All; }
                field(PlainFormat; Rec.PlainFormat) { ApplicationArea = All; }
                field(PlainLabel; Rec.PlainLabel) { ApplicationArea = All; }
                field(EmptyText; Rec.EmptyText) { ApplicationArea = All; }
                field(NonNumericArea; Rec.NonNumericArea) { ApplicationArea = All; }
                field(WithCaption; Rec.WithCaption) { ApplicationArea = All; }
            }
        }
    }
}

page 99785 "HC Count Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "HC Count Row";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 99786 "HC CaptionClass Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(KindValue: Enum "HC Kind")
    var
        Row: Record "HC Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Kind := KindValue;
        Row.Insert();
    end;

    local procedure FieldCaptions(var Row: Record "HC Row"): Text
    begin
        exit(
            'asint=' + Row.FieldCaption(AsIntLabel) +
            '|plainformat=' + Row.FieldCaption(PlainFormat) +
            '|plainlabel=' + Row.FieldCaption(PlainLabel) +
            '|empty=' + Row.FieldCaption(EmptyText) +
            '|nonnumeric=' + Row.FieldCaption(NonNumericArea) +
            '|withcaption=' + Row.FieldCaption(WithCaption));
    end;

    [Test]
    procedure FieldCaption_PlainExpressions_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "HC Row";
    begin
        Row.Kind := Row.Kind::Item;
        Observer.Observe('captions', FieldCaptions(Row));
        Observer.Finish();
    end;

    [Test]
    procedure FieldCaption_PlainExpressions_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "HC Row";
    begin
        Row.Kind := Row.Kind::Resource;
        Observer.Observe('captions', FieldCaptions(Row));
        Observer.Finish();
    end;

    [Test]
    procedure FieldRefCaption_PlainExpressions_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "HC Row";
        RecRef: RecordRef;
        Got: Text;
        FieldNo: Integer;
    begin
        Row.Kind := Row.Kind::Resource;
        RecRef.GetTable(Row);
        for FieldNo := 3 to 8 do
            Got += Format(FieldNo) + '=' + RecRef.Field(FieldNo).Caption() + '|';
        Observer.Observe('captions', Got);
        Observer.Finish();
    end;

    [Test]
    procedure FieldCaption_PlainExpression_InOnInsertError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "HC Row";
    begin
        Row.DeleteAll();
        Row.Id := 99;
        Row.Kind := Row.Kind::Resource;
        asserterror Row.Insert(true);
        Observer.ObserveError('insert');
        Observer.Finish();
    end;

    [Test]
    procedure CardControlCaptions_PlainExpressions_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "HC Card";
    begin
        Seed(Enum::"HC Kind"::Resource);
        Card.OpenEdit();
        Observer.Observe('asint', Card.AsIntLabel.Caption());
        Observer.Observe('plainformat', Card.PlainFormat.Caption());
        Observer.Observe('plainlabel', Card.PlainLabel.Caption());
        Observer.Observe('empty', Card.EmptyText.Caption());
        Observer.Observe('nonnumeric', Card.NonNumericArea.Caption());
        Observer.Observe('withcaption', Card.WithCaption.Caption());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CardControlCaptions_PlainExpressions_KindItem()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "HC Card";
    begin
        Seed(Enum::"HC Kind"::Item);
        Card.OpenEdit();
        Observer.Observe('asint', Card.AsIntLabel.Caption());
        Observer.Observe('plainformat', Card.PlainFormat.Caption());
        Observer.Observe('plainlabel', Card.PlainLabel.Caption());
        Observer.Observe('empty', Card.EmptyText.Caption());
        Observer.Observe('nonnumeric', Card.NonNumericArea.Caption());
        Observer.Observe('withcaption', Card.WithCaption.Caption());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ListControlCaptions_PlainExpressions_KindResource()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "HC List";
    begin
        Seed(Enum::"HC Kind"::Resource);
        List.OpenView();
        Observer.Observe('asint', List.AsIntLabel.Caption());
        Observer.Observe('plainformat', List.PlainFormat.Caption());
        Observer.Observe('plainlabel', List.PlainLabel.Caption());
        Observer.Observe('empty', List.EmptyText.Caption());
        Observer.Observe('nonnumeric', List.NonNumericArea.Caption());
        Observer.Observe('withcaption', List.WithCaption.Caption());
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountCard_AsIntegerExpression_RunsAtOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "HC Log";
        Row: Record "HC Count Row";
        Card: TestPage "HC Count Card";
        Got: Text;
        Round: Integer;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Kind := Row.Kind::Resource;
        Row.Insert();
        for Round := 1 to 2 do begin
            Log.Take();
            Card.OpenEdit();
            Got += 'open ' + Log.Take();
            Observer.Observe('caption ' + Format(Round), Card.Amount.Caption());
            Got += ' read ' + Log.Take();
            Card.Close();
            Got += ' close ' + Log.Take() + '|';
        end;
        Observer.Observe('cycles', Got);
        Observer.Finish();
    end;

    [Test]
    procedure CountRow_AsIntegerExpression_FieldCaptionRunsOncePerRead()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "HC Log";
        Row: Record "HC Count Row";
    begin
        Row.Kind := Row.Kind::Resource;
        Log.Take();
        Observer.Observe('caption', Row.FieldCaption(Amount));
        Observer.Observe('after first read', Log.Take());
        Observer.Observe('caption again', Row.FieldCaption(Amount));
        Observer.Observe('after second read', Log.Take());
        Observer.Finish();
    end;
}
