// Fixture for TestCodeunitMetadataVirtualTable: a codeunit whose Subtype is the one AL
// codeunit subtype the "CodeUnit Metadata" (2000000137) SubType column names no member for.
//
// That column's OptionMembers are Normal,Test,TestRunner,Upgrade -- four members -- while AL
// accepts a fifth, Install. So this fixture asks the platform a question no other codeunit in
// this suite can: what does the SubType column report when the codeunit declares a subtype the
// column has no member for? The answer is the point of the test, not an implementation detail;
// see TestCodeunitMetadataVirtualTable.al.
//
// The install triggers are deliberately empty. Nothing here should change company state -- the
// fixture exists to be READ through CodeUnit Metadata, not to install anything.

codeunit 60838 "ALT Install Probe"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
    end;

    trigger OnInstallAppPerDatabase()
    begin
    end;
}

// Writer UR (tests/al-language/install/lt-ur-block-order/UrBlockOrderTests.al): an install codeunit in id block 0 (50302); it only logs, with `if Insert() then;`.
codeunit 50302 "LT UR Install Low"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('I50302', 'company');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Log: Record "LT UR Install Log";
    begin
        Log.Add('I50302', 'database');
    end;
}
