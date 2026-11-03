// Purpose: prove that a dependent app can read and write fields added by a
// dependency app's tableextension — the symbol-merge scenario that caused
// AL0132/AL0133 in the BC Runner.
tableextension 60205 "ALT Internal Table Ext" extends "ALT Internal Table"
{
    fields
    {
        field(50000; "ALT Foo"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(50001; "ALT Bar"; Text[50])
        {
            DataClassification = SystemMetadata;
        }
    }
}
