// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope, but ONLY for a Target = OnPrem app - "User Property" (2000000121) is Scope = OnPrem
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// CLAIM: the platform creates the "User Property" row that belongs to a User whichever way the
// User row is written. A User saved by a PAGE - a new record on a DelayedInsert card, saved by
// CurrPage.Update() from a field's OnValidate, the shape of Base Application's "User Card" - gets
// its companion row exactly as a User inserted by Record.Insert does.
//
// The companion row is written by the platform's User system-table insert trigger, not by any AL,
// so the page save and the record API reach the same rule. "Test User Property Session Usr"
// (61203) pins the row for the session user; this file pins it for users created in the test.
//
// Every positive read is paired with a negative one: a Get that answered true for any key would
// satisfy "row exists", so each test also asks for a security id no user carries.
codeunit 61204 "Test User Property Page Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure UserProperty_UserInsertedThroughPage_HasCompanionRow()
    // CLAIM: a User row saved by CurrPage.Update() on a new record has a User Property row keyed
    // by the security id the page's OnInsertRecord assigned. Read while the page is still open,
    // so the row is the one the Update saved, not one written when the page closed.
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
        UserInsertCard: TestPage "Test User Insert Card";
        UserName: Code[50];
    begin
        UserName := NewUserName();

        UserInsertCard.OpenNew();
        UserInsertCard.UserNameField.SetValue(UserName);

        UserRec.SetRange("User Name", UserName);
        Assert.IsTrue(UserRec.FindFirst(), 'control arm: CurrPage.Update() must have inserted the User row');
        Assert.IsFalse(IsNullGuid(UserRec."User Security ID"), 'control arm: OnInsertRecord must have assigned a security id');

        Assert.IsTrue(
            UserProperty.Get(UserRec."User Security ID"),
            'a User inserted through a page must have a User Property row keyed by its security id');
        Assert.AreEqual(
            UserRec."User Security ID", UserProperty."User Security ID",
            'the User Property row must carry the page-inserted User''s security id');

        Assert.IsFalse(
            UserProperty.Get(CreateGuid()),
            'User Property must have no row for a security id that belongs to no user');

        UserInsertCard.Close();
    end;

    [Test]
    procedure UserProperty_UserInsertedThroughRecord_HasCompanionRow()
    // CLAIM: the same invariant through Record.Insert(false), the path without any trigger, as the
    // control that the page test above asserts the same rule and not a page-specific one.
    var
        UserRec: Record User;
        UserProperty: Record "User Property";
    begin
        UserRec.Init();
        UserRec."User Security ID" := CreateGuid();
        UserRec."User Name" := NewUserName();
        UserRec.Insert(false);

        Assert.IsTrue(
            UserProperty.Get(UserRec."User Security ID"),
            'a User inserted through Record.Insert(false) must have a User Property row keyed by its security id');
        Assert.IsFalse(
            UserProperty.Get(CreateGuid()),
            'User Property must have no row for a security id that belongs to no user');
    end;

    local procedure NewUserName(): Code[50]
    begin
        exit(CopyStr('T61204' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 50));
    end;
}

page 61205 "Test User Insert Card"
{
    PageType = Card;
    SourceTable = User;
    DelayedInsert = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(UserNameField; Rec."User Name")
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    // Base Application's "User Card" validates the name into CurrPage.Update(),
                    // which saves the new record there and then: the insert is the page's
                    // SaveRecord, not the delayed insert on leaving the record.
                    CurrPage.Update();
                end;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // The same assignment Base Application's "User Card" makes: the page, not the table,
        // gives a new User its security id.
        Rec."User Security ID" := CreateGuid();
        exit(true);
    end;
}
