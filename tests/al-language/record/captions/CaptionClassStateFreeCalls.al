// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 62410, log codeunit 62410 (SingleInstance, used only by test codeunit 62419), helper codeunit
//   62411, tables 62410 to 62413, table extension 62410, pages 62410 to 62417, test codeunit 62419
// local object: the CaptionClass expression of the table fields is the thing under test, so the tables and pages are own objects (standing rule 2)
// Probe: al-runner issues 7424 (a CaptionClass expression that calls UserSecurityId, filters and reads a local record and calls a codeunit, on
//   a cue page), 7467 (an expression in a table extension that raises an integration event with no subscriber and calls RecordRef.GetTable(Rec)
//   on a local RecordRef), 7391 (an expression that can reach Message, Confirm or Error but does not take that branch with the record of the
//   page open), 7379 (Enum.AsInteger inside a codeunit the expression calls) and 7382 (the caption on a ListPart of a card run with Page.Run).
// Area: CaptionClass expressions that call something but leave no state behind.
//   Expressions: CueCc (UserSecurityId, SetRange, SetLoadFields, FindFirst on a local record, a codeunit call; gives '' when no row is found),
//   NotTakenCc (Message for Id 777, Confirm for Id 778, Error for Id 779, else a plain text), HelperCc (AsInteger in a codeunit),
//   RefCopyCc (an integration event with no subscriber, RecordRef.GetTable(Rec), an own area with the table and field number), and the same
//   RefCopyCc shape in a table extension that sets the CaptionClass of a field of the table it extends with modify().
//   Readers: FieldCaption, FieldRef.Caption, Card (OpenEdit and OpenView), List, a ListPart and a CardPart with a cuegroup on a host Card (TestPage
//   and Page.Run with a PageHandler), the CardPart opened alone.
//   Branch taken: FieldCaption and a page open with a row whose Id takes the Message branch (how many messages a MessageHandler sees) and
//   the Error branch (the error of FieldCaption and of the open).
//   Counts: table 62412 has the same four expressions and logs each run (empty record or a row) per field; three cycles of open, GoToRecord
//   and Close on a Card, open and Close on the cue CardPart, and two FieldCaption reads per field.
// Neighbours (not repeated here): CaptionExpressionPlainText.al (AsInteger in the table itself, plain texts, Card and List),
//   SxCaptionClassCount.al and testpage/Y61CaptionClassCount.al (counts for one to fifteen fields, a Message that always runs),
//   testpage/QbCaptionClassModify.al (modify() with a CaptionClass), format-evaluate/autoformat/TestCaptionClassResolverFailure.al (an error in
//   an OnResolveCaptionClass subscriber).
// Not covered: a RoleCenter page that hosts the cue part (a TestPage of a RoleCenter is its own area).
// Observe form: every test ends with Finish(), which reports the observed values.
// BC versions: 27, 28, 29 (corpus CI)

enum 62410 "CCF Kind"
{
    Extensible = false;

    value(0; Postal) { Caption = 'Postal'; }
    value(1; Street) { Caption = 'Street'; }
}

codeunit 62410 "CCF Log"
{
    SingleInstance = true;

    var
        EmptyRuns: array[4] of Integer;
        RowRuns: array[4] of Integer;
        Messages: Integer;
        KeptText: Text;

    // FieldNumber is 10 to 13.
    procedure Hit(FieldNumber: Integer; RowId: Integer)
    begin
        if RowId = 0 then
            EmptyRuns[FieldNumber - 9] += 1
        else
            RowRuns[FieldNumber - 9] += 1;
    end;

    // 'f10:<empty-record runs>/<row runs> f11:...' for the fields that ran, 'none' when nothing ran. Clears the counts.
    procedure Take(): Text
    var
        Result: Text;
        Index: Integer;
    begin
        for Index := 1 to 4 do begin
            if (EmptyRuns[Index] <> 0) or (RowRuns[Index] <> 0) then
                Result += 'f' + Format(Index + 9) + ':' + Format(EmptyRuns[Index]) + '/' + Format(RowRuns[Index]) + ' ';
            EmptyRuns[Index] := 0;
            RowRuns[Index] := 0;
        end;
        if Result = '' then
            exit('none');
        exit(Result.TrimEnd());
    end;

    procedure AddMessage()
    begin
        Messages += 1;
    end;

    procedure TakeMessages(): Integer
    var
        Result: Integer;
    begin
        Result := Messages;
        Messages := 0;
        exit(Result);
    end;

    procedure Keep(NewText: Text)
    begin
        KeptText := NewText;
    end;

    procedure TakeKept(): Text
    var
        Result: Text;
    begin
        Result := KeptText;
        KeptText := '';
        exit(Result);
    end;
}

codeunit 62411 "CCF Helper"
{
    procedure GetCaptionArea(): Text
    var
        AreaLbl: Label 'CcfCueArea', Locked = true;
    begin
        exit(AreaLbl);
    end;

    procedure KindNumber(Kind: Enum "CCF Kind"): Integer
    begin
        exit(Kind.AsInteger());
    end;
}

table 62410 "CCF Cue Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "User Security ID"; Guid) { }
        field(2; "Cue No."; Integer) { }
        field(3; Status; Option) { OptionMembers = Draft,Ready; }
        field(4; "Cue Name"; Text[50]) { }
    }

    keys { key(PK; "User Security ID", "Cue No.") { Clustered = true; } }

    procedure FilterCuesForUser(var CueSetup: Record "CCF Cue Setup"; UserSecurityID: Guid)
    begin
        CueSetup.Reset();
        CueSetup.SetRange("User Security ID", UserSecurityID);
    end;
}

// The expressions without a log: nothing they do outlives the call.
table 62411 "CCF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "CCF Kind") { }
        field(10; "Cue 1"; Integer) { CaptionClass = CueCc(1); }
        field(11; "Not Taken"; Decimal) { CaptionClass = NotTakenCc(); }
        field(12; "Helper Kind"; Code[20]) { CaptionClass = HelperCc(); }
        field(13; "Ref Copy"; Text[50]) { CaptionClass = RefCopyCc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    local procedure CueCc(CueNo: Integer): Text
    var
        CueSetup: Record "CCF Cue Setup";
        Helper: Codeunit "CCF Helper";
    begin
        CueSetup.FilterCuesForUser(CueSetup, UserSecurityId());
        CueSetup.SetRange(Status, CueSetup.Status::Ready);
        CueSetup.SetRange("Cue No.", CueNo);
        CueSetup.SetLoadFields("Cue Name");
        if CueSetup.FindFirst() then
            exit(Helper.GetCaptionArea() + ',' + CueSetup."Cue Name");
    end;

    local procedure NotTakenCc(): Text
    var
        TakenMsg: Label 'CCF message branch';
        TakenQst: Label 'CCF confirm branch?';
        TakenErr: Label 'CCF error branch';
    begin
        if Id = 777 then
            Message(TakenMsg);
        if Id = 778 then
            if Confirm(TakenQst) then;
        if Id = 779 then
            Error(TakenErr);
        exit('Not taken text');
    end;

    local procedure HelperCc(): Text
    var
        Helper: Codeunit "CCF Helper";
        AllLbl: Label 'All';
    begin
        if Helper.KindNumber(Kind) = 0 then
            exit(AllLbl)
        else
            exit(Format(Kind));
    end;

    local procedure RefCopyCc() Result: Text
    var
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeRefCopyCc(Kind, IsHandled, Result);
        if IsHandled then
            exit(Result);

        RecRef.GetTable(Rec);
        if Kind <> Kind::Postal then
            Result := 'CCFAREA,1'
        else
            Result := 'CCFAREA,0';
        exit(Result + ',' + Format(Database::"CCF Row") + ',' + Format(FieldNo("Ref Copy")));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefCopyCc(Kind: Enum "CCF Kind"; var IsHandled: Boolean; var Result: Text)
    begin
    end;
}

// The same four expressions, each logging its run first (the field number and whether the record is empty).
table 62412 "CCF Count Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "CCF Kind") { }
        field(10; "Cue 1"; Integer) { CaptionClass = CueCc(1); }
        field(11; "Not Taken"; Decimal) { CaptionClass = NotTakenCc(); }
        field(12; "Helper Kind"; Code[20]) { CaptionClass = HelperCc(); }
        field(13; "Ref Copy"; Text[50]) { CaptionClass = RefCopyCc(); }
    }

    keys { key(PK; Id) { Clustered = true; } }

    var
        Log: Codeunit "CCF Log";

    local procedure CueCc(CueNo: Integer): Text
    var
        CueSetup: Record "CCF Cue Setup";
        Helper: Codeunit "CCF Helper";
    begin
        Log.Hit(10, Id);
        CueSetup.FilterCuesForUser(CueSetup, UserSecurityId());
        CueSetup.SetRange(Status, CueSetup.Status::Ready);
        CueSetup.SetRange("Cue No.", CueNo);
        CueSetup.SetLoadFields("Cue Name");
        if CueSetup.FindFirst() then
            exit(Helper.GetCaptionArea() + ',' + CueSetup."Cue Name");
    end;

    local procedure NotTakenCc(): Text
    var
        TakenMsg: Label 'CCF message branch';
        TakenErr: Label 'CCF error branch';
    begin
        Log.Hit(11, Id);
        if Id = 777 then
            Message(TakenMsg);
        if Id = 779 then
            Error(TakenErr);
        exit('Not taken text');
    end;

    local procedure HelperCc(): Text
    var
        Helper: Codeunit "CCF Helper";
        AllLbl: Label 'All';
    begin
        Log.Hit(12, Id);
        if Helper.KindNumber(Kind) = 0 then
            exit(AllLbl)
        else
            exit(Format(Kind));
    end;

    local procedure RefCopyCc() Result: Text
    var
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        Log.Hit(13, Id);
        OnBeforeRefCopyCc(Kind, IsHandled, Result);
        if IsHandled then
            exit(Result);

        RecRef.GetTable(Rec);
        if Kind <> Kind::Postal then
            Result := 'CCFAREA,1'
        else
            Result := 'CCFAREA,0';
        exit(Result + ',' + Format(Database::"CCF Count Row") + ',' + Format(FieldNo("Ref Copy")));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRefCopyCc(Kind: Enum "CCF Kind"; var IsHandled: Boolean; var Result: Text)
    begin
    end;
}

// The table of al-runner issue 7467: its field "Address 2" gets a CaptionClass from the table extension below.
table 62413 "CCF Addr"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Address 2"; Text[50]) { Caption = 'Address 2'; }
        field(3; "Sell Address 2"; Text[50]) { Caption = 'Sell Address 2'; }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

tableextension 62410 "CCF Addr Ext" extends "CCF Addr"
{
    fields
    {
        field(62410; "CCF Address Type"; Enum "CCF Kind") { }
        modify("Address 2") { CaptionClass = GetAddress2CaptionClass(); }
    }

    local procedure GetAddress2CaptionClass() Result: Text
    var
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeGetAddress2CaptionClass("CCF Address Type", IsHandled, Result);
        if IsHandled then
            exit(Result);

        RecRef.GetTable(Rec);
        if "CCF Address Type" <> "CCF Address Type"::Postal then
            Result := 'CCFADDR,1'
        else
            Result := 'CCFADDR,0';
        exit(Result + ',' + Format(Database::"CCF Addr") + ',' + Format(FieldNo("Sell Address 2")));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAddress2CaptionClass(AddressType: Enum "CCF Kind"; var IsHandled: Boolean; var Result: Text)
    begin
    end;
}

page 62410 "CCF Card"
{
    PageType = Card;
    SourceTable = "CCF Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Kind; Rec.Kind) { ApplicationArea = All; }
            field(Cue1; Rec."Cue 1") { ApplicationArea = All; }
            field(NotTaken; Rec."Not Taken") { ApplicationArea = All; }
            field(HelperKind; Rec."Helper Kind") { ApplicationArea = All; }
            field(RefCopy; Rec."Ref Copy") { ApplicationArea = All; }
        }
    }
}

page 62411 "CCF List"
{
    PageType = List;
    SourceTable = "CCF Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Cue1; Rec."Cue 1") { ApplicationArea = All; }
                field(NotTaken; Rec."Not Taken") { ApplicationArea = All; }
                field(HelperKind; Rec."Helper Kind") { ApplicationArea = All; }
                field(RefCopy; Rec."Ref Copy") { ApplicationArea = All; }
            }
        }
    }
}

page 62412 "CCF Part"
{
    PageType = ListPart;
    SourceTable = "CCF Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(NotTaken; Rec."Not Taken") { ApplicationArea = All; }
                field(HelperKind; Rec."Helper Kind") { ApplicationArea = All; }
                field(RefCopy; Rec."Ref Copy") { ApplicationArea = All; }
            }
        }
    }
}

page 62413 "CCF Cues"
{
    PageType = CardPart;
    SourceTable = "CCF Row";

    layout
    {
        area(Content)
        {
            cuegroup(Cues)
            {
                field(Cue1; Rec."Cue 1") { ApplicationArea = All; }
            }
        }
    }
}

page 62414 "CCF Host"
{
    PageType = Card;
    SourceTable = "CCF Addr";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Address2; Rec."Address 2") { ApplicationArea = All; }
            part(Lines; "CCF Part") { ApplicationArea = All; }
            part(Cues; "CCF Cues") { ApplicationArea = All; }
        }
    }
}

page 62415 "CCF Count Card"
{
    PageType = Card;
    SourceTable = "CCF Count Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Cue1; Rec."Cue 1") { ApplicationArea = All; }
            field(NotTaken; Rec."Not Taken") { ApplicationArea = All; }
            field(HelperKind; Rec."Helper Kind") { ApplicationArea = All; }
            field(RefCopy; Rec."Ref Copy") { ApplicationArea = All; }
        }
    }
}

page 62416 "CCF Count Cues"
{
    PageType = CardPart;
    SourceTable = "CCF Count Row";

    layout
    {
        area(Content)
        {
            cuegroup(Cues)
            {
                field(Cue1; Rec."Cue 1") { ApplicationArea = All; }
            }
        }
    }
}

page 62417 "CCF Addr Card"
{
    PageType = Card;
    SourceTable = "CCF Addr";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Address2; Rec."Address 2") { ApplicationArea = All; }
            field(AddressType; Rec."CCF Address Type") { ApplicationArea = All; }
        }
    }
}

codeunit 62419 "CCF State Free Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "CCF Log";

    local procedure Clean()
    var
        Row: Record "CCF Row";
        CountRow: Record "CCF Count Row";
        CueSetup: Record "CCF Cue Setup";
        Addr: Record "CCF Addr";
    begin
        Row.DeleteAll();
        CountRow.DeleteAll();
        CueSetup.DeleteAll();
        Addr.DeleteAll();
        Log.Take();
        Log.TakeMessages();
        Log.TakeKept();
    end;

    local procedure SeedRow(RowId: Integer; KindValue: Enum "CCF Kind")
    var
        Row: Record "CCF Row";
    begin
        Row.Id := RowId;
        Row.Kind := KindValue;
        Row.Insert();
    end;

    local procedure SeedCountRow(RowId: Integer; KindValue: Enum "CCF Kind")
    var
        CountRow: Record "CCF Count Row";
    begin
        CountRow.Id := RowId;
        CountRow.Kind := KindValue;
        CountRow.Insert();
    end;

    // A Ready row of cue 1 for the current user, a Draft row of cue 2 for the current user, and a Ready row of cue 1 for another user.
    local procedure SeedSetup()
    var
        CueSetup: Record "CCF Cue Setup";
    begin
        CueSetup."User Security ID" := UserSecurityId();
        CueSetup."Cue No." := 1;
        CueSetup.Status := CueSetup.Status::Ready;
        CueSetup."Cue Name" := 'My cue';
        CueSetup.Insert();
        CueSetup."Cue No." := 2;
        CueSetup.Status := CueSetup.Status::Draft;
        CueSetup."Cue Name" := 'Draft cue';
        CueSetup.Insert();
        CueSetup."User Security ID" := CreateGuid();
        CueSetup."Cue No." := 1;
        CueSetup.Status := CueSetup.Status::Ready;
        CueSetup."Cue Name" := 'Other cue';
        CueSetup.Insert();
    end;

    local procedure SeedAddr(KindValue: Enum "CCF Kind")
    var
        Addr: Record "CCF Addr";
    begin
        Addr."No." := 'A1';
        Addr."CCF Address Type" := KindValue;
        Addr.Insert();
    end;

    local procedure FieldCaptions(var Row: Record "CCF Row"): Text
    begin
        exit(
            'cue=[' + Row.FieldCaption("Cue 1") +
            '] nottaken=[' + Row.FieldCaption("Not Taken") +
            '] helper=[' + Row.FieldCaption("Helper Kind") +
            '] refcopy=[' + Row.FieldCaption("Ref Copy") + ']');
    end;

    [Test]
    procedure StateFree_FieldCaption_NoSetupRow_KindPostal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCF Row";
    begin
        Clean();
        Row.Kind := Row.Kind::Postal;
        Observer.Observe('empty record', FieldCaptions(Row));
        Row.Id := 5;
        Observer.Observe('record with an Id', FieldCaptions(Row));
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_FieldCaption_SetupRow_KindStreet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCF Row";
    begin
        Clean();
        SeedSetup();
        Row.Kind := Row.Kind::Street;
        Observer.Observe('empty record', FieldCaptions(Row));
        Row.Id := 5;
        Observer.Observe('record with an Id', FieldCaptions(Row));
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_FieldRefCaption_SetupRow_KindStreet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCF Row";
        RecRef: RecordRef;
        Got: Text;
        FieldNumber: Integer;
    begin
        Clean();
        SeedSetup();
        Row.Id := 5;
        Row.Kind := Row.Kind::Street;
        RecRef.GetTable(Row);
        for FieldNumber := 10 to 13 do
            Got += Format(FieldNumber) + '=[' + RecRef.Field(FieldNumber).Caption() + '] ';
        Observer.Observe('GetTable of the record', Got);
        RecRef.Close();
        RecRef.Open(Database::"CCF Row");
        Got := '';
        for FieldNumber := 10 to 13 do
            Got += Format(FieldNumber) + '=[' + RecRef.Field(FieldNumber).Caption() + '] ';
        Observer.Observe('RecordRef.Open', Got);
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_Card_OpenEdit_SetupRow_KindStreet()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "CCF Card";
    begin
        Clean();
        SeedSetup();
        SeedRow(1, Enum::"CCF Kind"::Street);
        Card.OpenEdit();
        Observer.Observe('cue', '[' + Card.Cue1.Caption() + ']');
        Observer.Observe('nottaken', '[' + Card.NotTaken.Caption() + ']');
        Observer.Observe('helper', '[' + Card.HelperKind.Caption() + ']');
        Observer.Observe('refcopy', '[' + Card.RefCopy.Caption() + ']');
        Observer.Observe('cue again', '[' + Card.Cue1.Caption() + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_Card_OpenView_NoSetupRow_KindPostal()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "CCF Card";
    begin
        Clean();
        SeedRow(1, Enum::"CCF Kind"::Postal);
        Card.OpenView();
        Observer.Observe('cue', '[' + Card.Cue1.Caption() + ']');
        Observer.Observe('nottaken', '[' + Card.NotTaken.Caption() + ']');
        Observer.Observe('helper', '[' + Card.HelperKind.Caption() + ']');
        Observer.Observe('refcopy', '[' + Card.RefCopy.Caption() + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_Card_OpenNew_SetupRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "CCF Card";
    begin
        Clean();
        SeedSetup();
        Card.OpenNew();
        Observer.Observe('cue', '[' + Card.Cue1.Caption() + ']');
        Observer.Observe('nottaken', '[' + Card.NotTaken.Caption() + ']');
        Observer.Observe('helper', '[' + Card.HelperKind.Caption() + ']');
        Observer.Observe('refcopy', '[' + Card.RefCopy.Caption() + ']');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_List_OpenView_SetupRow_KindStreet()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "CCF List";
    begin
        Clean();
        SeedSetup();
        SeedRow(1, Enum::"CCF Kind"::Street);
        SeedRow(2, Enum::"CCF Kind"::Postal);
        List.OpenView();
        Observer.Observe('cue', '[' + List.Cue1.Caption() + ']');
        Observer.Observe('nottaken', '[' + List.NotTaken.Caption() + ']');
        Observer.Observe('helper', '[' + List.HelperKind.Caption() + ']');
        Observer.Observe('refcopy', '[' + List.RefCopy.Caption() + ']');
        List.Next();
        Observer.Observe('helper on row 2', '[' + List.HelperKind.Caption() + ']');
        Observer.Observe('refcopy on row 2', '[' + List.RefCopy.Caption() + ']');
        List.Close();
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_Host_PartAndCuePart_Captions()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "CCF Host";
    begin
        Clean();
        SeedSetup();
        SeedRow(1, Enum::"CCF Kind"::Street);
        SeedAddr(Enum::"CCF Kind"::Street);
        Host.OpenEdit();
        Observer.Observe('host address 2', '[' + Host.Address2.Caption() + ']');
        Observer.Observe('part nottaken', '[' + Host.Lines.NotTaken.Caption() + ']');
        Observer.Observe('part helper', '[' + Host.Lines.HelperKind.Caption() + ']');
        Observer.Observe('part refcopy', '[' + Host.Lines.RefCopy.Caption() + ']');
        Observer.Observe('cue part cue', '[' + Host.Cues.Cue1.Caption() + ']');
        Host.Close();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HostPageHandler')]
    procedure StateFree_Host_PageRun_PartAndCuePart_Captions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        SeedSetup();
        SeedRow(1, Enum::"CCF Kind"::Street);
        SeedAddr(Enum::"CCF Kind"::Street);
        Page.Run(Page::"CCF Host");
        Observer.Observe('captions the page handler read', Log.TakeKept());
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_CuePart_OpenView_Alone()
    var
        Observer: Codeunit "Probe Observer";
        Cues: TestPage "CCF Cues";
    begin
        Clean();
        SeedSetup();
        SeedRow(1, Enum::"CCF Kind"::Street);
        Cues.OpenView();
        Observer.Observe('cue', '[' + Cues.Cue1.Caption() + ']');
        Cues.Close();
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_CuePart_OpenView_NoSetupRow()
    var
        Observer: Codeunit "Probe Observer";
        Cues: TestPage "CCF Cues";
    begin
        Clean();
        SeedRow(1, Enum::"CCF Kind"::Street);
        Cues.OpenView();
        Observer.Observe('cue', '[' + Cues.Cue1.Caption() + ']');
        Cues.Close();
        Observer.Finish();
    end;

    // al-runner issue 7467: the expression lives in the table extension.
    [Test]
    procedure StateFree_TableExtension_FieldCaption_BothKinds()
    var
        Observer: Codeunit "Probe Observer";
        Addr: Record "CCF Addr";
        RecRef: RecordRef;
    begin
        Clean();
        Addr."CCF Address Type" := Addr."CCF Address Type"::Postal;
        Observer.Observe('postal', '[' + Addr.FieldCaption("Address 2") + ']');
        Addr."CCF Address Type" := Addr."CCF Address Type"::Street;
        Observer.Observe('street', '[' + Addr.FieldCaption("Address 2") + ']');
        RecRef.GetTable(Addr);
        Observer.Observe('street, FieldRef.Caption', '[' + RecRef.Field(2).Caption() + ']');
        Observer.Observe('field without a CaptionClass', '[' + Addr.FieldCaption("Sell Address 2") + ']');
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_TableExtension_Card_Captions()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "CCF Addr Card";
    begin
        Clean();
        SeedAddr(Enum::"CCF Kind"::Street);
        Card.OpenEdit();
        Observer.Observe('street row', '[' + Card.Address2.Caption() + ']');
        Card.AddressType.SetValue(Enum::"CCF Kind"::Postal);
        Observer.Observe('after SetValue of the type to Postal', '[' + Card.Address2.Caption() + ']');
        Card.Close();
        Card.OpenView();
        Observer.Observe('second open, postal row', '[' + Card.Address2.Caption() + ']');
        Card.Close();
        Observer.Finish();
    end;

    // al-runner issue 7391: the branch is taken. FieldCaption with a record whose Id is 777 shows the message.
    [Test]
    [HandlerFunctions('CountMessage')]
    procedure StateFree_BranchTaken_FieldCaption_Message()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCF Row";
        Got: Text;
    begin
        Clean();
        Row.Id := 777;
        Got := Row.FieldCaption("Not Taken");
        Observer.Observe('caption', '[' + Got + ']');
        Observer.Observe('messages', Format(Log.TakeMessages()));
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_BranchTaken_FieldCaption_Error()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CCF Row";
        Got: Text;
    begin
        Clean();
        Row.Id := 779;
        asserterror begin
            Got := Row.FieldCaption("Not Taken");
            Error('no error, caption [%1]', Got);
        end;
        Observer.ObserveError('FieldCaption');
        Observer.Finish();
    end;

    // The row of the card takes the Message branch, the empty record of the open does not.
    [Test]
    [HandlerFunctions('CountMessage')]
    procedure StateFree_BranchTaken_Card_RowTakesMessageBranch()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "CCF Count Card";
    begin
        Clean();
        SeedCountRow(777, Enum::"CCF Kind"::Street);
        Card.OpenEdit();
        Observer.Observe('open runs', Log.Take());
        Observer.Observe('open messages', Format(Log.TakeMessages()));
        Observer.Observe('caption', '[' + Card.NotTaken.Caption() + ']');
        Observer.Observe('read runs', Log.Take());
        Observer.Observe('read messages', Format(Log.TakeMessages()));
        Card.Close();
        Observer.Observe('close runs', Log.Take());
        Observer.Observe('close messages', Format(Log.TakeMessages()));
        Observer.Finish();
    end;

    // The row of the card takes the Error branch.
    [Test]
    procedure StateFree_BranchTaken_Card_RowTakesErrorBranch()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "CCF Count Card";
    begin
        Clean();
        SeedCountRow(779, Enum::"CCF Kind"::Street);
        asserterror begin
            Card.OpenEdit();
            Error('no error, caption [%1]', Card.NotTaken.Caption());
        end;
        Observer.ObserveError('open');
        Observer.Observe('runs', Log.Take());
        Observer.Finish();
    end;

    // A row that takes no branch: no message handler is declared, so a message would fail the test.
    [Test]
    procedure StateFree_BranchNotTaken_Card_ThreeCycles_RunsPerField()
    var
        Observer: Codeunit "Probe Observer";
        CountRow: Record "CCF Count Row";
        Card: TestPage "CCF Count Card";
        Opens: Text;
        Moves: Text;
        Closes: Text;
        Cycle: Integer;
    begin
        Clean();
        SeedSetup();
        SeedCountRow(1, Enum::"CCF Kind"::Street);
        SeedCountRow(2, Enum::"CCF Kind"::Postal);
        SeedCountRow(3, Enum::"CCF Kind"::Street);
        CountRow.Get(2);
        for Cycle := 1 to 3 do begin
            Log.Take();
            Card.OpenEdit();
            Opens += Log.Take() + '|';
            Card.GoToRecord(CountRow);
            Moves += Log.Take() + '|';
            if Cycle = 1 then begin
                Observer.Observe('cue', '[' + Card.Cue1.Caption() + ']');
                Observer.Observe('nottaken', '[' + Card.NotTaken.Caption() + ']');
                Observer.Observe('helper', '[' + Card.HelperKind.Caption() + ']');
                Observer.Observe('refcopy', '[' + Card.RefCopy.Caption() + ']');
                Observer.Observe('runs of the four Caption() reads', Log.Take());
            end;
            Card.Close();
            Closes += Log.Take() + '|';
        end;
        Observer.Observe('open', Opens);
        Observer.Observe('GoToRecord', Moves);
        Observer.Observe('close', Closes);
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_CountCuePart_ThreeCycles_RunsPerField()
    var
        Observer: Codeunit "Probe Observer";
        Cues: TestPage "CCF Count Cues";
        Opens: Text;
        Closes: Text;
        Cycle: Integer;
    begin
        Clean();
        SeedSetup();
        SeedCountRow(1, Enum::"CCF Kind"::Street);
        for Cycle := 1 to 3 do begin
            Log.Take();
            Cues.OpenView();
            Opens += Log.Take() + '|';
            if Cycle = 1 then begin
                Observer.Observe('cue', '[' + Cues.Cue1.Caption() + ']');
                Observer.Observe('runs of the Caption() read', Log.Take());
            end;
            Cues.Close();
            Closes += Log.Take() + '|';
        end;
        Observer.Observe('open', Opens);
        Observer.Observe('close', Closes);
        Observer.Finish();
    end;

    [Test]
    procedure StateFree_Count_FieldCaption_RunsPerRead()
    var
        Observer: Codeunit "Probe Observer";
        CountRow: Record "CCF Count Row";
        Got: Text;
    begin
        Clean();
        SeedSetup();
        CountRow.Id := 5;
        CountRow.Kind := CountRow.Kind::Street;
        Got := CountRow.FieldCaption("Cue 1");
        Observer.Observe('cue', '[' + Got + '] ' + Log.Take());
        Got := CountRow.FieldCaption("Cue 1");
        Observer.Observe('cue again', '[' + Got + '] ' + Log.Take());
        Got := CountRow.FieldCaption("Helper Kind");
        Observer.Observe('helper', '[' + Got + '] ' + Log.Take());
        Got := CountRow.FieldCaption("Ref Copy");
        Observer.Observe('refcopy', '[' + Got + '] ' + Log.Take());
        Got := CountRow.FieldCaption("Ref Copy");
        Observer.Observe('refcopy again', '[' + Got + '] ' + Log.Take());
        Got := CountRow.FieldCaption("Not Taken");
        Observer.Observe('nottaken', '[' + Got + '] ' + Log.Take());
        Observer.Finish();
    end;

    [PageHandler]
    procedure HostPageHandler(var Host: TestPage "CCF Host")
    begin
        Log.Keep(
            'host address 2=[' + Host.Address2.Caption() +
            '] part nottaken=[' + Host.Lines.NotTaken.Caption() +
            '] part helper=[' + Host.Lines.HelperKind.Caption() +
            '] part refcopy=[' + Host.Lines.RefCopy.Caption() +
            '] cue part cue=[' + Host.Cues.Cue1.Caption() + ']');
        Host.Close();
    end;

    [MessageHandler]
    procedure CountMessage(Msg: Text[1024])
    begin
        Log.AddMessage();
    end;
}
