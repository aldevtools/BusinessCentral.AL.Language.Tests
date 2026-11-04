// Scope: fixture
// Fixtures used: none; table 93240
// A log for the Y61 page probes, kept in a table (no SingleInstance state), so several test codeunits may use it.
// Every test clears it first.

table 93240 "LT Y61 Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[250]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    procedure ClearLog()
    var
        L: Record "LT Y61 Log";
    begin
        L.DeleteAll();
    end;

    procedure AddLine(Value: Text)
    var
        L: Record "LT Y61 Log";
        NextId: Integer;
    begin
        if L.FindLast() then
            NextId := L.Id;
        L.Init();
        L.Id := NextId + 1;
        L.Txt := CopyStr(Value, 1, MaxStrLen(L.Txt));
        L.Insert();
    end;

    procedure Dump(): Text
    var
        L: Record "LT Y61 Log";
        Result: Text;
    begin
        if L.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += L.Txt;
            until L.Next() = 0;
        exit(Result);
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Dump();
        ClearLog();
        exit(Result);
    end;
}
