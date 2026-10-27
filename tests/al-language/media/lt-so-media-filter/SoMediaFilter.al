// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained table 89520 "LT SO Media Row"
// Probe: written against a real BC 29.0 service tier. Other BC versions are checked by the CI matrix.
//
// Writer SO (2026-10-28), for aldevtools/BusinessCentral.AL.Runner#5991: SetFilter on a Media (and MediaSet) field with the text
// '00000000-0000-0000-0000-000000000000' and its forms ('=', '<>', braces, the empty text, '' quoted, a MediaId, an invalid
// text), on rows with an empty Media and a row with an imported Media; what Count, IsEmpty and FindSet answer and which rows match.
// SetFilter(Media, '%1', <Guid>), SetRange(Media, <Guid>) and SetRange(Media, <Text>) do not compile (must-not-compile 2218-2220);
// with a Media value as the argument (empty or filled) both compile, and SO_MediaFilter_MediaValueArgument pins what they select.
// Also the reporter's shape: RecordRef.Field(...).SetFilter('<>0000...') then FindSet on an empty-media row.
// Table 89520 also carries two Option fields for the Option tests in fieldref/TestFieldRefEnumOrdinalByIndex.al (#5987).
// BC versions: 27.5, 28.5, 29.0

table 89520 "LT SO Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
        field(4; Opt; Option)
        {
            OptionMembers = Option1,Option2;
            OptionCaption = 'First caption,Second caption';
        }
        field(5; OptNoCap; Option)
        {
            Caption = 'Option Value';
            OptionMembers = Option1,Option2;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 89521 "LT SO Media Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Rows 1 and 3 hold no media; row 2 holds an imported 1x1 png. Answers the MediaId of row 2.
    local procedure Setup() Id: Guid
    var
        Rec: Record "LT SO Media Row";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        Out: OutStream;
        Ins: InStream;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Init();
        Rec."Entry No." := 2;
        Rec.Insert();
        TempBlob.CreateOutStream(Out);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Out);
        TempBlob.CreateInStream(Ins);
        Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Rec.Modify();
        Id := Rec.Pic.MediaId();
        Rec.Init();
        Rec."Entry No." := 3;
        Rec.Insert();
    end;

    local procedure Rows(var Rec: Record "LT SO Media Row") Result: Text
    begin
        Result := 'count=' + Format(Rec.Count()) + ' isempty=' + Format(Rec.IsEmpty()) + ' rows=';
        if Rec.FindSet() then
            repeat
                Result += Format(Rec."Entry No.") + ';';
            until Rec.Next() = 0;
    end;

    [TryFunction]
    local procedure TryMedia(FilterText: Text; var Result: Text)
    var
        Rec: Record "LT SO Media Row";
    begin
        Rec.SetFilter(Pic, FilterText);
        Result := 'getfilter=[' + Rec.GetFilter(Pic) + '] ' + Rows(Rec);
    end;

    [TryFunction]
    local procedure TryMediaSet(FilterText: Text; var Result: Text)
    var
        Rec: Record "LT SO Media Row";
    begin
        Rec.SetFilter(Pics, FilterText);
        Result := 'getfilter=[' + Rec.GetFilter(Pics) + '] ' + Rows(Rec);
    end;

    local procedure MediaOutcome(FilterText: Text) Result: Text
    begin
        ClearLastError();
        if not TryMedia(FilterText, Result) then
            Result := 'error=[' + GetLastErrorText() + '] code=' + GetLastErrorCode();
    end;

    local procedure MediaSetOutcome(FilterText: Text) Result: Text
    begin
        ClearLastError();
        if not TryMediaSet(FilterText, Result) then
            Result := 'error=[' + GetLastErrorText() + '] code=' + GetLastErrorCode();
    end;

    [Test]
    procedure SO_MediaFilter_NullGuidForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Observer.Observe('<>null', MediaOutcome('<>00000000-0000-0000-0000-000000000000'));
        Observer.Observe('null', MediaOutcome('00000000-0000-0000-0000-000000000000'));
        Observer.Observe('=null', MediaOutcome('=00000000-0000-0000-0000-000000000000'));
        Observer.Observe('<>{null}', MediaOutcome('<>{00000000-0000-0000-0000-000000000000}'));
        Observer.Observe('{null}', MediaOutcome('{00000000-0000-0000-0000-000000000000}'));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaFilter_EmptyAndQuoted()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Observer.Observe('empty text', MediaOutcome(''));
        Observer.Observe('quoted empty', MediaOutcome(''''''));
        Observer.Observe('<> quoted empty', MediaOutcome('<>'''''));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaFilter_MediaIdOfFilledRow()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Id := Setup();
        Observer.Observe('id', MediaOutcome(Format(Id)));
        Observer.Observe('<>id', MediaOutcome('<>' + Format(Id)));
        Observer.Observe('id plain', MediaOutcome(DelChr(Format(Id), '=', '{}')));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaFilter_InvalidText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Observer.Observe('abc', MediaOutcome('abc'));
        Observer.Observe('star', MediaOutcome('*'));
        Observer.Observe('zero', MediaOutcome('0'));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaFilter_MediaValueArgument()
    var
        Rec: Record "LT SO Media Row";
        Empty: Record "LT SO Media Row";
        Filled: Record "LT SO Media Row";
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Empty.Get(1);
        Filled.Get(2);
        Rec.SetRange(Pic, Empty.Pic);
        Observer.Observe('setrange empty media', 'getfilter=[' + Rec.GetFilter(Pic) + '] ' + Rows(Rec));
        Rec.Reset();
        Rec.SetRange(Pic, Filled.Pic);
        Observer.Observe('setrange filled media id', Format(Rec.GetFilter(Pic) = Format(Filled.Pic.MediaId())));
        Observer.Observe('setrange filled media', Rows(Rec));
        Rec.Reset();
        Rec.SetFilter(Pic, '<>%1', Empty.Pic);
        Observer.Observe('<>%1 empty media', 'getfilter=[' + Rec.GetFilter(Pic) + '] ' + Rows(Rec));
        Rec.Reset();
        Rec.SetFilter(Pic, '<>%1', Filled.Pic);
        Observer.Observe('<>%1 filled media', Rows(Rec));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaFilter_FieldRefReproShape()
    var
        Row: Record "LT SO Media Row";
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Insert();
        RecRef.Open(Database::"LT SO Media Row");
        FldRef := RecRef.Field(Row.FieldNo(Pic));
        FldRef.SetFilter('<>00000000-0000-0000-0000-000000000000');
        Observer.Observe('getfilter', FldRef.GetFilter());
        Observer.Observe('findset', Format(RecRef.FindSet()));
        Observer.Observe('count', Format(RecRef.Count()));
        FldRef.SetFilter('00000000-0000-0000-0000-000000000000');
        Observer.Observe('= findset', Format(RecRef.FindSet()));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaSetFilter_NullGuidForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Setup();
        Observer.Observe('<>null', MediaSetOutcome('<>00000000-0000-0000-0000-000000000000'));
        Observer.Observe('null', MediaSetOutcome('00000000-0000-0000-0000-000000000000'));
        Observer.Observe('empty text', MediaSetOutcome(''));
        Observer.Finish();
    end;
}
