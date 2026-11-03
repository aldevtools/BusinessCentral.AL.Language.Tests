// Fixture for "Test External Business Event" (68611): the event category the
// ExternalBusinessEvent attribute in "EBE Publisher" (68610) names.
using System.Integration;

enumextension 68610 "EBE Event Category" extends EventCategory
{
    value(68610; "EBE Example")
    {
        Caption = 'EBE Example';
    }
}
