// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpageview-property
// Scope: in-scope
// Fixtures used: Assert (60021) -- and Base Application page 790 "G/L Account Categories"
//                with its two factbox parts on page 791 "G/L Accounts ListPart", and page
//                7357 "Whse. Internal Pick" with its lines part on page 7358
//
/// <summary>
/// Pins that a part's SubPageView filters the part on a host page that ships PRECOMPILED in
/// Base Application, not only on a page this app compiles.
///
/// TestPartSubPageView.al pins the same rule on pages this app declares. The claim here is the
/// same; the route is not. A client that reads a precompiled page's layout from the app's
/// symbols has to carry the part's SubPageView over by itself, and dropping it shows the part
/// every row its view excludes. Written for AL Runner issue
/// StefanMaron/BusinessCentral.AL.Runner#4968, where exactly that happened.
///
/// Page 790 carries two parts over the same page 791 and the same G/L Account rows:
///
///   "G/L Accounts without Category"  SubPageView = where("Account Subcategory Entry No." = const(0))
///   "G/L Accounts in Category"       SubPageLink = "Account Subcategory Entry No." = field("Entry No.")
///
/// Each test seeds two accounts: one with no subcategory (-IN) and one under a category it
/// inserts (-OUT), under numbers of its own so the two tests do not collide within one
/// codeunit's isolation. The view arm asserts the -IN account is in its part and the -OUT one
/// is not, so an empty part cannot pass it. The link arm is the control: parked on the
/// inserted category, the other part shows the -OUT account and not the -IN one, so both rows
/// are reachable through page 791.
///
/// GoToKey rather than a First/Next walk: a company with demo data has other accounts in both
/// parts, and this test asserts only about the two rows it inserted.
///
/// The SORTING half uses page 7357 "Whse. Internal Pick", whose lines part declares
/// SubPageLink = "No." = field("No.") and SubPageView = sorting("No.", "Sorting Sequence No.").
/// The lines table's primary key is ("No.", "Line No."), so the three seeded lines come out
/// L1, L2, L3 in key order and L2, L3, L1 in the view's order. The page's OnOpenPage filters
/// the host to the user's warehouse locations, so the test makes the user a warehouse employee
/// at a location it inserts, and that location its default
/// when the company gives the user none.
///
/// Written by agent stma-auto-5, an automated implementation agent acting on the account
/// holder's behalf.
/// </summary>
codeunit 67990 "SPVP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure PrecompiledHostPartSubPageViewShowsOnlyTheRowsItsViewSelects()
    var
        GLAccountCategory: Record "G/L Account Category";
        Host: TestPage "G/L Account Categories";
    begin
        InsertCategory(GLAccountCategory);
        InsertAccount('SPVP-IN', 0);
        InsertAccount('SPVP-OUT', GLAccountCategory."Entry No.");

        Host.OpenView();
        Assert.IsTrue(Host."G/L Accounts without Category".GoToKey('SPVP-IN'),
            'the view part must show an account with no subcategory');
        Assert.IsFalse(Host."G/L Accounts without Category".GoToKey('SPVP-OUT'),
            'the view part must not show an account its SubPageView excludes');
        Host.Close();
    end;

    [Test]
    procedure PrecompiledHostLinkedPartShowsTheRowTheViewExcluded()
    var
        GLAccountCategory: Record "G/L Account Category";
        Host: TestPage "G/L Account Categories";
    begin
        InsertCategory(GLAccountCategory);
        InsertAccount('SPVP-LINK-IN', 0);
        InsertAccount('SPVP-LINK-OUT', GLAccountCategory."Entry No.");

        Host.OpenView();
        Assert.IsTrue(Host.GoToRecord(GLAccountCategory), 'the host must find the inserted category');
        Assert.IsTrue(Host."G/L Accounts in Category".GoToKey('SPVP-LINK-OUT'),
            'the linked part must show the account under the host''s category');
        Assert.IsFalse(Host."G/L Accounts in Category".GoToKey('SPVP-LINK-IN'),
            'the linked part must not show an account under no category');
        Host.Close();
    end;

    [Test]
    procedure PrecompiledHostPartSubPageViewSortsTheRows()
    var
        Header: Record "Whse. Internal Pick Header";
        Host: TestPage "Whse. Internal Pick";
        Seen: Text;
    begin
        MakeUserWarehouseEmployeeAt('SPVP');
        Header."No." := 'SPVP-SORT';
        Header."Location Code" := 'SPVP';
        Header.Insert();
        InsertPickLine(Header."No.", 10000, 30, 'L1');
        InsertPickLine(Header."No.", 20000, 10, 'L2');
        InsertPickLine(Header."No.", 30000, 20, 'L3');

        Host.OpenView();
        Assert.IsTrue(Host.GoToRecord(Header), 'the host must find the inserted internal pick');
        if Host.WhseInternalPickLines.First() then
            repeat
                // An editable part may show a trailing blank new row; it carries no item.
                if Host.WhseInternalPickLines."Item No.".Value <> '' then
                    Seen += Host.WhseInternalPickLines."Item No.".Value + ';';
            until not Host.WhseInternalPickLines.Next();
        Host.Close();

        Assert.AreEqual('L2;L3;L1;', Seen,
            'the lines part must show its rows in the SubPageView''s Sorting Sequence No. order, not primary key order');
    end;

    local procedure MakeUserWarehouseEmployeeAt(LocationCode: Code[10])
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        IsDefault: Boolean;
    begin
        Location.Code := LocationCode;
        Location.Insert();
        // The page also wants the user to have a DEFAULT location; make this one the default
        // only when the company does not already give the user one.
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.SetRange(Default, true);
        IsDefault := WarehouseEmployee.IsEmpty();
        WarehouseEmployee.Init();
        WarehouseEmployee."User ID" := CopyStr(UserId(), 1, MaxStrLen(WarehouseEmployee."User ID"));
        WarehouseEmployee."Location Code" := LocationCode;
        WarehouseEmployee.Default := IsDefault;
        WarehouseEmployee.Insert();
    end;

    local procedure InsertPickLine(DocumentNo: Code[20]; LineNo: Integer; SortingSequenceNo: Integer; ItemNo: Code[20])
    var
        Line: Record "Whse. Internal Pick Line";
    begin
        Line."No." := DocumentNo;
        Line."Line No." := LineNo;
        Line."Sorting Sequence No." := SortingSequenceNo;
        Line."Item No." := ItemNo;
        Line.Insert();
    end;

    local procedure InsertCategory(var GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := 0;
        GLAccountCategory.Description := 'SPVP Category';
        GLAccountCategory.Insert();
        Assert.AreNotEqual(0, GLAccountCategory."Entry No.", 'the inserted category must get an entry number');
    end;

    local procedure InsertAccount(No: Code[20]; SubcategoryEntryNo: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := No;
        GLAccount.Name := No;
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount."Account Subcategory Entry No." := SubcategoryEntryNo;
        GLAccount.Insert();
    end;
}
