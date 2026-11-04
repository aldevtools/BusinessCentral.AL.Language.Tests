table 60332 "TBA Trace"
{
    Caption = 'TBA Trace';
    DataClassification = CustomerContent;
    TableType = Normal;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Event"; Text[100])
        {
            Caption = 'Event';
        }
        field(3; "Input Text"; Text[250])
        {
            Caption = 'Input Text';
        }
        field(4; "Output Text"; Text[250])
        {
            Caption = 'Output Text';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure Log(NewEvent: Text)
    var
        Trace: Record "TBA Trace";
        NextNo: Integer;
    begin
        if Trace.FindLast() then
            NextNo := Trace."Entry No.";
        Trace.Init();
        Trace."Entry No." := NextNo + 1;
        Trace."Event" := CopyStr(NewEvent, 1, MaxStrLen(Trace."Event"));
        Trace.Insert();
    end;

    procedure Events(): Text
    var
        Trace: Record "TBA Trace";
        Result: Text;
    begin
        if Trace.FindSet() then
            repeat
                Result += Trace."Event" + ';';
            until Trace.Next() = 0;
        exit(Result);
    end;
}
