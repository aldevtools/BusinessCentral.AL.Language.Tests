// Migrated from AL Runner tests/runner-extras/user-security-id (UsiSrc.al).
// A per-user singleton buffer keyed on UserSecurityId — the shape AL uses whenever a page
// needs scratch state that belongs to the current user and nobody else. The field is
// deliberately NAMED UserSecurityId, shadowing the system function, because that is how the
// pattern is written in the wild: inside this table `UserSecurityId` is the field and
// `UserSecurityId()` is the function, and a runner that conflates them breaks the table.
table 60858 "USI Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; UserSecurityId; Guid) { }
        field(2; Payload; Text[50]) { }
    }

    keys
    {
        key(PK; UserSecurityId) { Clustered = true; }
    }

    /// <summary>
    /// Returns the current user's row, creating it on first use. The trapping Get is what
    /// makes this idempotent; the raising Get in the tests is what proves the row is really
    /// reachable afterwards.
    /// </summary>
    procedure GetForCurrentUser()
    begin
        if not Get(UserSecurityId()) then begin
            Init();
            UserSecurityId := UserSecurityId();
            Insert(true);
        end;
    end;
}
