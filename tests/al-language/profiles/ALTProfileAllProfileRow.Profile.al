// A profile that declares every property "All Profile" (2000000178) surfaces as a column
// of its own, so TestAllProfileTable.al can assert each one against a value declared right
// here instead of against Base Application demo content.
//
// Note ProfileDescription, not Description: those are two different AL properties, and only
// ProfileDescription reaches All Profile."Description" on a service tier (ALT Profile
// SameApp declares the other one, and its row's Description comes back empty -- see
// TestAllProfileTable.al).
profile "ALT AllProfile Row"
{
    Caption = 'ALT AllProfile Row Fixture';
    ProfileDescription = 'Row fixture for the All Profile system table.';
    Enabled = true;
    Promoted = true;
    RoleCenter = "ALT Profile RC SameApp";
}
