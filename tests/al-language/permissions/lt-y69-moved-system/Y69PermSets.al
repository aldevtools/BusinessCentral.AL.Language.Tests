// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permission-set-object
// Scope: in-scope
// Fixtures: permission sets, a permission set extension, an entitlement and helper codeunits for the tests of writer Y69
//   (al-runner issues 6716 and 6717 by SShadowS): Y69MovedTables.al and Y69SystemGrants.al in this folder.
// 6716: BC 29 ships eight tables twice under one id: Base Application declares them with ObsoleteState = Moved, Business Foundation
//   (MovedFrom the Base Application) declares the target (Reason Code 231, Return Reason 6635, Source Code 230, Source Code Setup 242,
//   No. Series 308, No. Series Line 309, No. Series Relationship 310, No. Series Tenant 1263). The sets below name them by name, in
//   tabledata and table grants, directly, through an included set, an excluded set, a permission set extension and the Permissions
//   property of a codeunit. By id is not allowed (AL0653, must-not-compile case 2670).
// 6717: sets with named `system "<name>" = X` grants.
// Names of the objects are prefixed LT Y69.

permissionset 93700 "LT Y69 MV Name"
{
    Assignable = true;
    Permissions = tabledata "Reason Code" = R,
                  tabledata Customer = R;
}

permissionset 93701 "LT Y69 MV Plain"
{
    Assignable = true;
    Permissions = tabledata Customer = R;
}

permissionset 93702 "LT Y69 MV All"
{
    Assignable = true;
    Permissions = tabledata "Reason Code" = RIMD,
                  tabledata "Return Reason" = RIMD,
                  tabledata "Source Code" = RIMD,
                  tabledata "Source Code Setup" = RIMD,
                  tabledata "No. Series" = RIMD,
                  tabledata "No. Series Line" = RIMD,
                  tabledata "No. Series Relationship" = RIMD,
                  tabledata "No. Series Tenant" = RIMD,
                  table "Reason Code" = X,
                  table "No. Series" = X,
                  tabledata Customer = R;
}

permissionset 93703 "LT Y69 MV Inner"
{
    Assignable = false;
    Permissions = tabledata "Return Reason" = R;
}

permissionset 93704 "LT Y69 MV Outer"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y69 MV Inner";
    Permissions = tabledata Customer = R;
}

permissionset 93705 "LT Y69 MV Excl"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y69 MV All";
    ExcludedPermissionSets = "LT Y69 MV Name";
}

permissionset 93706 "LT Y69 MV Ext Base"
{
    Assignable = true;
    Permissions = tabledata Customer = R;
}

permissionsetextension 93707 "LT Y69 MV Ext" extends "LT Y69 MV Ext Base"
{
    Permissions = tabledata "Source Code" = R,
                  tabledata "No. Series Tenant" = RIMD;
}

permissionset 93708 "LT Y69 MV Indirect"
{
    Assignable = true;
    Permissions = tabledata "Reason Code" = r,
                  tabledata "No. Series" = r,
                  tabledata Customer = R;
}

// The Permissions property of an object names a moved table (indirect permission for the code of this codeunit).
codeunit 93709 "LT Y69 MV Writer"
{
    Permissions = tabledata "Reason Code" = ri, tabledata "No. Series" = rimd;

    procedure InsertReason(): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Reason Code");
        RecRef.Field(1).Value := 'LTY69W';
        RecRef.Insert(false);
        Error('LT Y69 ok');
    end;

    procedure DeleteSeries(): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"No. Series");
        RecRef.Field(1).SetRange('LTY69');
        RecRef.FindFirst();
        RecRef.Delete(false);
        Error('LT Y69 ok');
    end;
}

// System object grants (issue 6717).
permissionset 93720 "LT Y69 SY Basic"
{
    Assignable = true;
    Permissions = system "Tools, Security, Roles" = X,
                  tabledata Customer = R;
}

permissionset 93721 "LT Y69 SY Outer"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y69 SY Inner";
    Permissions = system "Tools, Security, Roles" = X;
}

permissionset 93722 "LT Y69 SY Inner"
{
    Assignable = false;
    Permissions = tabledata Customer = R;
}

permissionset 93723 "LT Y69 SY Many"
{
    Assignable = true;
    Permissions = system "Add Table Field To Page" = X,
                  system "Allow Action Export To Excel" = X,
                  system "Tools, Debugger" = X,
                  system "Microsoft Dynamics NAV Server" = X,
                  tabledata Customer = R;
}

permissionset 93724 "LT Y69 SY Only"
{
    Assignable = true;
    Permissions = system "Tools, Security, Roles" = X;
}

permissionset 93725 "LT Y69 SY Indirect"
{
    Assignable = true;
    Permissions = system "Tools, Security, Roles" = x,
                  tabledata Customer = R;
}

permissionset 93727 "LT Y69 SY Wild"
{
    Assignable = true;
    Permissions = system * = X,
                  tabledata Customer = R;
}

permissionset 93729 "LT Y69 SY Mid"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y69 SY Basic";
}

permissionset 93730 "LT Y69 SY Excl"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y69 SY Many";
    ExcludedPermissionSets = "LT Y69 SY Basic";
}

permissionset 93731 "LT Y69 SY Plain"
{
    Assignable = true;
    Permissions = tabledata Customer = R;
}

permissionsetextension 93732 "LT Y69 SY Ext" extends "LT Y69 SY Plain"
{
    Permissions = system "Tools, Security, Roles" = X;
}

// Shared helpers of the Y69 tests (no state).
codeunit 93735 "LT Y69 Helper"
{
    // The moved tables in a fixed order: 1 Reason Code .. 8 No. Series Tenant.
    procedure MovedTableId(Index: Integer): Integer
    begin
        case Index of
            1:
                exit(Database::"Reason Code");
            2:
                exit(Database::"Return Reason");
            3:
                exit(Database::"Source Code");
            4:
                exit(Database::"Source Code Setup");
            5:
                exit(Database::"No. Series");
            6:
                exit(Database::"No. Series Line");
            7:
                exit(Database::"No. Series Relationship");
            8:
                exit(Database::"No. Series Tenant");
        end;
    end;

    procedure MovedTableCount(): Integer
    begin
        exit(8);
    end;

    // One row 'LTY69' in each moved table (key field 1; the other key fields get fixed values), inserted without triggers.
    procedure SeedMoved()
    var
        i: Integer;
        RecRef: RecordRef;
    begin
        for i := 1 to MovedTableCount() do begin
            RecRef.Open(MovedTableId(i));
            RecRef.Field(1).SetRange('LTY69');
            if not RecRef.FindFirst() then begin
                RecRef.Close();
                RecRef.Open(MovedTableId(i));
                RecRef.Init();
                FillKey(RecRef, 'LTY69');
                RecRef.Insert(false);
            end;
            RecRef.Close();
        end;
    end;

    procedure CleanMoved()
    var
        i: Integer;
        RecRef: RecordRef;
    begin
        for i := 1 to MovedTableCount() do begin
            RecRef.Open(MovedTableId(i));
            RecRef.Field(1).SetFilter('LTY69*');
            if RecRef.FindSet() then
                RecRef.DeleteAll(false);
            RecRef.Close();
        end;
    end;

    procedure FillKey(var RecRef: RecordRef; KeyValue: Text)
    begin
        RecRef.Field(1).Value := KeyValue;
        case RecRef.Number of
            Database::"No. Series Line":
                RecRef.Field(2).Value := 1;
            Database::"No. Series Relationship":
                RecRef.Field(2).Value := KeyValue;
        end;
    end;

    // One operation on the seeded row of a table; always ends in Error('LT Y69 ok') so that nothing stays.
    // Kind 1 read, 2 insert, 3 modify, 4 delete.
    procedure Op(Kind: Integer; TableId: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        case Kind of
            1:
                RecRef.FindFirst();
            2:
                begin
                    RecRef.Init();
                    FillKey(RecRef, 'LTY69I');
                    RecRef.Insert(false);
                end;
            3:
                begin
                    RecRef.Field(1).SetRange('LTY69');
                    RecRef.FindFirst();
                    RecRef.Modify(false);
                end;
            4:
                begin
                    RecRef.Field(1).SetRange('LTY69');
                    RecRef.FindFirst();
                    RecRef.Delete(false);
                end;
        end;
        Error('LT Y69 ok');
    end;

    // The four operations as four characters: o = worked, D = a permission error, ! = another error.
    procedure FourOps(TableId: Integer): Text
    var
        Kind: Integer;
        Result: Text;
    begin
        for Kind := 1 to 4 do begin
            ClearLastError();
            asserterror Op(Kind, TableId);
            if GetLastErrorText() = 'LT Y69 ok' then
                Result += 'o'
            else
                if GetLastErrorText().StartsWith('Sorry, the current permissions prevented the action.') then
                    Result += 'D'
                else
                    Result += '!';
            ClearLastError();
        end;
        exit(Result);
    end;

    // The first error of one operation: its text and code.
    procedure ErrorOf(Kind: Integer; TableId: Integer): Text
    begin
        ClearLastError();
        asserterror Op(Kind, TableId);
        exit(GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    // Expanded Permission rows of a role as 'type:id:RIMDX;' (type: ordinal; letters: Yes = the letter, Indirect = lower case, else '-').
    procedure Expanded(RoleId: Code[20]): Text
    var
        ExpandedPermission: Record "Expanded Permission";
        Result: Text;
    begin
        ExpandedPermission.SetRange("Role ID", RoleId);
        if ExpandedPermission.FindSet() then
            repeat
                Result += Format(ExpandedPermission."Object Type", 0, 2) + ':' + Format(ExpandedPermission."Object ID") + ':' +
                    Letter(ExpandedPermission."Read Permission", 'R') + Letter(ExpandedPermission."Insert Permission", 'I') +
                    Letter(ExpandedPermission."Modify Permission", 'M') + Letter(ExpandedPermission."Delete Permission", 'D') +
                    Letter(ExpandedPermission."Execute Permission", 'X') + ';';
            until ExpandedPermission.Next() = 0;
        exit(Format(ExpandedPermission.Count()) + ' rows ' + Result);
    end;

    local procedure Letter(Value: Option " ",Yes,Indirect; Which: Text[1]): Text
    begin
        case Value of
            Value::Yes:
                exit(Which);
            Value::Indirect:
                exit(Which.ToLower());
        end;
        exit('-');
    end;
}

// The Permissions property of every object kind that has it, naming a moved table (compile shapes; the codeunit's runs in Y69MovedTables.al).
table 93714 "LT Y69 MV Table Perm"
{
    Permissions = tabledata "Reason Code" = ri, tabledata "No. Series Line" = r;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 93715 "LT Y69 MV Page Perm"
{
    PageType = Card;
    SourceTable = "LT Y69 MV Table Perm";
    Permissions = tabledata "Source Code" = rimd;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

report 93716 "LT Y69 MV Report Perm"
{
    ProcessingOnly = true;
    UsageCategory = None;
    Permissions = tabledata "Return Reason" = r;
}

query 93717 "LT Y69 MV Query Perm"
{
    Permissions = tabledata "No. Series" = r;

    elements
    {
        dataitem(Series; "No. Series")
        {
            column(Code; Code) { }
        }
    }
}

xmlport 93718 "LT Y69 MV XmlPort Perm"
{
    Permissions = tabledata "No. Series Tenant" = rimd;

    schema
    {
        textelement(Root)
        {
            tableelement(Reason; "Reason Code")
            {
                fieldelement(Code; Reason.Code) { }
            }
        }
    }
}
