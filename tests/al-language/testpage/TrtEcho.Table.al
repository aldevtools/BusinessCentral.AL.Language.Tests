// Migrated from AL Runner tests/runner-extras/testpage-record-triggers (TrtSrc.al).
/// <summary>Observation sink — page triggers write here so a test can see they ran.</summary>
table 60840 "TRT Echo"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[20]) { }
        field(2; Hits; Integer) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }

    procedure Bump(Name: Code[20])
    var
        Echo: Record "TRT Echo";
    begin
        if Echo.Get(Name) then begin
            Echo.Hits += 1;
            Echo.Modify();
        end else begin
            Echo.Init();
            Echo."Key" := Name;
            Echo.Hits := 1;
            Echo.Insert();
        end;
    end;
}
