// Probe: Format(RecordId, 0, 10) and Evaluate(RecordId, Text, 10) (the bookmark form), next to the bookmark= value of GetUrl for the same
// records; Evaluate with number 10 of texts that are no bookmark and into other types; Format(Variant holding a RecordId, 0, 10).
// Gap cycle 5, spec G5-10 (writer Y49). Object ids: tables 92943 and 92944, page 92943, codeunit 92943.
// Fixtures used: Probe Observer (codeunit 69160).

table 92943 "LT Y49 Bm Code Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 92944 "LT Y49 Bm Line Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Doc Type"; Option) { OptionMembers = Quote,Order,Invoice; }
        field(2; "No."; Code[20]) { }
        field(3; "Line No."; Integer) { }
    }
    keys { key(PK; "Doc Type", "No.", "Line No.") { Clustered = true; } }
}

page 92943 "LT Y49 Bm Code List"
{
    PageType = List;
    SourceTable = "LT Y49 Bm Code Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }
}

codeunit 92943 "LT Y49 RecordId Format10"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        A: Record "LT Y49 Bm Code Row";
        B: Record "LT Y49 Bm Line Row";
    begin
        A.DeleteAll();
        B.DeleteAll();
        AddA('A-1');
        AddA('1');
        AddA('12345');
        B.Init();
        B."Doc Type" := B."Doc Type"::Order;
        B."No." := 'X';
        B."Line No." := 10000;
        B.Insert();
    end;

    local procedure AddA(No: Code[20])
    var
        A: Record "LT Y49 Bm Code Row";
    begin
        A.Init();
        A."No." := No;
        A.Name := 'Name ' + No;
        A.Insert();
    end;

    local procedure Bookmark(Url: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(Url, 'bookmark=');
        if P = 0 then
            exit('nobookmark');
        exit(CopyStr(Url, P + 9));
    end;

    local procedure ObsFormat10(Name: Text; Rid: RecordId)
    var
        Res: Text;
    begin
        ClearLastError();
        if TryFormat10(Rid, Res) then
            Observer.Observe(Name, '[' + Res + ']')
        else begin
            Observer.Observe(Name, 'raised');
            Observer.ObserveError(Name);
        end;
    end;

    [TryFunction]
    local procedure TryFormat10(Rid: RecordId; var Res: Text)
    begin
        Res := Format(Rid, 0, 10);
    end;

    [Test]
    procedure RecIdFormat10_Shapes()
    var
        A: Record "LT Y49 Bm Code Row";
        Blank: Record "LT Y49 Bm Code Row";
        B: Record "LT Y49 Bm Line Row";
    begin
        Seed();
        A.Get('A-1');
        ObsFormat10('A-1', A.RecordId);
        Observer.Observe('A-1 url', Bookmark(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y49 Bm Code List", A, false)));
        A.Get('1');
        ObsFormat10('1', A.RecordId);
        Observer.Observe('1 url', Bookmark(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y49 Bm Code List", A, false)));
        A.Get('12345');
        ObsFormat10('12345', A.RecordId);
        Observer.Observe('12345 url', Bookmark(GetUrl(ClientType::Web, 'My Company', ObjectType::Page, Page::"LT Y49 Bm Code List", A, false)));
        B.FindFirst();
        ObsFormat10('B line', B.RecordId);
        ObsFormat10('blank record', Blank.RecordId);
        Blank.Init();
        Blank."No." := 'A-1';
        ObsFormat10('unread record with key', Blank.RecordId);
        Observer.Finish();
    end;

    // 'found <value of field FieldNo>', 'not found' or the error of RecordRef.Get.
    local procedure GetText(RecId: RecordId; FieldNo: Integer): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryGet(RecId, FieldNo, Res) then
            exit(Res);
        Res := 'raised ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Res);
    end;

    [TryFunction]
    local procedure TryGet(RecId: RecordId; FieldNo: Integer; var Res: Text)
    var
        RecRef: RecordRef;
    begin
        if RecRef.Get(RecId) then
            Res := 'found ' + Format(RecRef.Field(FieldNo).Value)
        else
            Res := 'not found';
    end;

    [Test]
    procedure RecIdEvaluate10_RoundTrip()
    var
        A: Record "LT Y49 Bm Code Row";
        B: Record "LT Y49 Bm Line Row";
        RecId: RecordId;
        Txt: Text;
        Ok: Boolean;
    begin
        Seed();
        A.Get('A-1');
        Txt := Format(A.RecordId, 0, 10);
        ClearLastError();
        Ok := Evaluate(RecId, Txt, 10);
        Observer.Observe('A-1 ok', Format(Ok));
        Observer.Observe('A-1 recid', Format(RecId));
        Observer.Observe('A-1 table', Format(RecId.TableNo));
        Observer.Observe('A-1 get', GetText(RecId, 2));
        Observer.Observe('A-1 equal', Format(RecId = A.RecordId));
        A.Get('1');
        Clear(RecId);
        Ok := Evaluate(RecId, Format(A.RecordId, 0, 10), 10);
        Observer.Observe('1 ok', Format(Ok) + ' ' + Format(RecId));
        B.FindFirst();
        Clear(RecId);
        Ok := Evaluate(RecId, Format(B.RecordId, 0, 10), 10);
        Observer.Observe('B ok', Format(Ok) + ' ' + Format(RecId));
        Observer.Observe('B get', GetText(RecId, 3));
        Clear(RecId);
        Ok := Evaluate(RecId, Format(A.RecordId), 10);
        Observer.Observe('format0 text with 10', Format(Ok) + ' ' + Format(RecId));
        Clear(RecId);
        Ok := Evaluate(RecId, Format(A.RecordId, 0, 10));
        Observer.Observe('bookmark text without number', Format(Ok) + ' ' + Format(RecId));
        Observer.Finish();
    end;

    [Test]
    procedure RecIdEvaluate10_OtherTexts()
    var
        A: Record "LT Y49 Bm Code Row";
        RecId: RecordId;
        Ok: Boolean;
    begin
        Seed();
        A.Get('A-1');
        Ok := Evaluate(RecId, 'LT Y49 Bm Code Row: A-1', 10);
        Observer.Observe('format0 text', Format(Ok) + ' ' + Format(RecId));
        Clear(RecId);
        Ok := Evaluate(RecId, '', 10);
        Observer.Observe('empty', Format(Ok) + ' ' + Format(RecId));
        Ok := Evaluate(RecId, 'garbage', 10);
        Observer.Observe('garbage', Format(Ok) + ' ' + Format(RecId));
        Clear(RecId);
        Ok := Evaluate(RecId, '17;D2sBAAJ7', 10);
        Observer.Observe('bookmark with wrong length', Format(Ok) + ' ' + Format(RecId));
        ObsStmtRecId('garbage stmt', 'garbage');
        ObsStmtRecId('empty stmt', '');
        ObsStmtRecId('format0 text stmt', 'LT Y49 Bm Code Row: A-1');
        ObsStmtRecId('bookmark stmt', Format(A.RecordId, 0, 10));
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate10_OtherTargets()
    var
        T: Text;
        I: Integer;
        D: Date;
        G: Guid;
        Ok: Boolean;
    begin
        Ok := Evaluate(T, 'x', 10);
        Observer.Observe('text', Format(Ok) + ' [' + T + ']');
        Ok := Evaluate(I, '12', 10);
        Observer.Observe('integer', Format(Ok) + ' ' + Format(I));
        Ok := Evaluate(D, '2024-03-05', 10);
        Observer.Observe('date', Format(Ok) + ' ' + Format(D, 0, 9));
        Ok := Evaluate(G, '{3F2504E0-4F89-11D3-9A0C-0305E82C3301}', 10);
        Observer.Observe('guid', Format(Ok) + ' ' + Format(G));
        ClearLastError();
        Observer.Observe('integer stmt', Format(TryStmtInt('12')));
        Observer.ObserveError('integer stmt');
        Observer.Observe('date stmt', Format(TryStmtDate('2024-03-05')));
        Observer.ObserveError('date stmt');
        Observer.Finish();
    end;

    local procedure ObsStmtRecId(Name: Text; Txt: Text)
    begin
        ClearLastError();
        Observer.Observe(Name, Format(TryStmtRecId(Txt)));
        Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryStmtRecId(Txt: Text)
    var
        RecId: RecordId;
    begin
        Evaluate(RecId, Txt, 10);
    end;

    [TryFunction]
    local procedure TryStmtInt(Txt: Text)
    var
        I: Integer;
    begin
        Evaluate(I, Txt, 10);
    end;

    [TryFunction]
    local procedure TryStmtDate(Txt: Text)
    var
        D: Date;
    begin
        Evaluate(D, Txt, 10);
    end;

    [Test]
    procedure RecIdFormat10_Variant()
    var
        A: Record "LT Y49 Bm Code Row";
        V: Variant;
        Res: Text;
    begin
        Seed();
        A.Get('A-1');
        V := A.RecordId;
        ClearLastError();
        if TryFormatVariant(V, 10, Res) then
            Observer.Observe('variant 10', '[' + Res + ']')
        else begin
            Observer.Observe('variant 10', 'raised');
            Observer.ObserveError('variant 10');
        end;
        if TryFormatVariant(V, 0, Res) then
            Observer.Observe('variant 0', '[' + Res + ']')
        else begin
            Observer.Observe('variant 0', 'raised');
            Observer.ObserveError('variant 0');
        end;
        Observer.Observe('direct', Format(A.RecordId, 0, 10));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryFormatVariant(V: Variant; N: Integer; var Res: Text)
    begin
        Res := Format(V, 0, N);
    end;
}
