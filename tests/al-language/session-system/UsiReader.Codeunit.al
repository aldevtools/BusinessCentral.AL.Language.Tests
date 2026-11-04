// Migrated from AL Runner tests/runner-extras/user-security-id (UsiSrc.al).
codeunit 60859 "USI Reader"
{
    /// <summary>
    /// Reads the function from a DIFFERENT object than the caller. A runner that seeds the
    /// identity per method scope rather than per session answers differently here.
    /// </summary>
    procedure Read(): Guid
    begin
        exit(UserSecurityId());
    end;
}
