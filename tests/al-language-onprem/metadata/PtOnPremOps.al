// OnPrem copy of the platform table runner (PtHelper.al in the Cloud app): the same RecordRef work, but compiled in a Target = OnPrem app, because a RecordRef
// opened from a Target = Cloud app cannot name the OnPrem-scope system tables (see PtOnPremTables.al, CloudRunner_RefusesOnPremTables). Not a test codeunit.
// Object ids 61237 and 61247.

codeunit 61237 "LT PT OnPrem Runner"
{
    TableNo = "LT PT Arg";

    trigger OnRun()
    var
        RR: RecordRef;
        Parts: List of [Text];
        Filters: Text;
        Changes: Text;
        Bar: Integer;
    begin
        RR.Open(Rec."Table No.");
        Bar := StrPos(Rec.Request, '|');
        if Bar = 0 then
            Filters := Rec.Request
        else begin
            Filters := CopyStr(Rec.Request, 1, Bar - 1);
            Changes := CopyStr(Rec.Request, Bar + 1);
        end;
        case Rec.Op of
            'columns':
                Rec.Result := Columns(RR);
            'hasrows':
                Rec.Result := Format(not RR.IsEmpty());
            'first':
                begin
                    if not RR.FindFirst() then
                        Rec.Result := 'none'
                    else
                        Rec.Result := Row(RR);
                end;
            'find':
                begin
                    Filter(RR, Filters);
                    if not RR.FindFirst() then
                        Rec.Result := 'none'
                    else
                        Rec.Result := Row(RR);
                end;
            'count':
                begin
                    Filter(RR, Filters);
                    Rec.Result := Format(RR.Count());
                end;
            'insert':
                begin
                    Assign(RR, Filters);
                    Rec.Result := Format(RR.Insert(Rec."Run Triggers"));
                end;
            'modify':
                begin
                    Filter(RR, Filters);
                    RR.FindFirst();
                    Assign(RR, Changes);
                    Rec.Result := Format(RR.Modify(Rec."Run Triggers"));
                end;
            'delete':
                begin
                    Filter(RR, Filters);
                    RR.FindFirst();
                    Rec.Result := Format(RR.Delete(Rec."Run Triggers"));
                end;
            'deleteall':
                begin
                    Filter(RR, Filters);
                    RR.DeleteAll(Rec."Run Triggers");
                    Rec.Result := 'done';
                end;
        end;
    end;

    local procedure Columns(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            Result += Format(FR.Number) + ':' + FR.Name + ':' + Format(FR.Type) + ':' + Format(FR.Length) + ':' + Format(FR.Class) + ';';
        end;
        exit(Result);
    end;

    // Every field that has a plain value, as no=value; Guid values are shown as set or blank (they differ per database), Blob, Media and MediaSet by type only.
    local procedure Row(var RR: RecordRef): Text
    var
        FR: FieldRef;
        Index: Integer;
        Result: Text;
        Value: Text;
    begin
        for Index := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(Index);
            case FR.Type of
                FieldType::Blob, FieldType::Media, FieldType::MediaSet:
                    Value := '<' + Format(FR.Type) + '>';
                FieldType::Guid:
                    if IsNullGuid(FR.Value) then
                        Value := '<blank guid>'
                    else
                        Value := '<guid>';
                else
                    Value := Format(FR.Value);
            end;
            Result += Format(FR.Number) + '=' + Value + ';';
        end;
        exit(Result);
    end;

    local procedure IsNullGuid(Value: Guid): Boolean
    var
        Blank: Guid;
    begin
        exit(Value = Blank);
    end;

    local procedure Split(Request: Text; var Numbers: List of [Integer]; var Values: List of [Text])
    var
        Parts: List of [Text];
        Part: Text;
        Eq: Integer;
        No: Integer;
    begin
        if Request = '' then
            exit;
        Parts := Request.Split(';');
        foreach Part in Parts do begin
            Eq := StrPos(Part, '=');
            Evaluate(No, CopyStr(Part, 1, Eq - 1));
            Numbers.Add(No);
            Values.Add(CopyStr(Part, Eq + 1));
        end;
    end;

    local procedure Filter(var RR: RecordRef; Request: Text)
    var
        FR: FieldRef;
        Numbers: List of [Integer];
        Values: List of [Text];
        Index: Integer;
    begin
        Split(Request, Numbers, Values);
        for Index := 1 to Numbers.Count() do begin
            FR := RR.Field(Numbers.Get(Index));
            FR.SetFilter('%1', Convert(FR, Values.Get(Index)));
        end;
    end;

    local procedure Assign(var RR: RecordRef; Request: Text)
    var
        FR: FieldRef;
        Numbers: List of [Integer];
        Values: List of [Text];
        Index: Integer;
    begin
        Split(Request, Numbers, Values);
        for Index := 1 to Numbers.Count() do begin
            FR := RR.Field(Numbers.Get(Index));
            FR.Value := Convert(FR, Values.Get(Index));
        end;
    end;

    local procedure Convert(var FR: FieldRef; Text: Text): Variant
    var
        IntValue: Integer;
        BoolValue: Boolean;
        DecValue: Decimal;
        GuidValue: Guid;
    begin
        case FR.Type of
            FieldType::Integer, FieldType::Option:
                begin
                    Evaluate(IntValue, Text);
                    exit(IntValue);
                end;
            FieldType::Boolean:
                begin
                    Evaluate(BoolValue, Text);
                    exit(BoolValue);
                end;
            FieldType::Decimal:
                begin
                    Evaluate(DecValue, Text);
                    exit(DecValue);
                end;
            FieldType::Guid:
                begin
                    Evaluate(GuidValue, Text);
                    exit(GuidValue);
                end;
        end;
        exit(Text);
    end;
}

codeunit 61247 "LT PT OnPrem Ops"
{
    // Runs one request in a codeunit of its own and returns "ok:<result>" or "error:<text>|<code>".
    procedure Perform(TableNo: Integer; Op: Text; Request: Text; RunTriggers: Boolean): Text
    var
        Arg: Record "LT PT Arg" temporary;
    begin
        ClearLastError();
        Arg.Init();
        Arg.Id := 1;
        Arg."Table No." := TableNo;
        Arg.Op := CopyStr(Op, 1, MaxStrLen(Arg.Op));
        Arg.Request := CopyStr(Request, 1, MaxStrLen(Arg.Request));
        Arg."Run Triggers" := RunTriggers;
        Arg.Insert();
        if not Codeunit.Run(Codeunit::"LT PT OnPrem Runner", Arg) then begin
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        exit('ok:' + Arg.Result);
    end;
}
