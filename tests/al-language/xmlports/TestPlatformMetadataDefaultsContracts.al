// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68470, xmlport 68471, page 68472, profile
//                "Probe Defaults Profile", codeunits 68473 (subscriber) and 68474 (tests)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what the system tables report for objects that leave a property out:
//  - "XmlPort Metadata" of an xmlport with no properties: Direction Both, Format Xml, UseRequestPage Yes,
//    TransactionType UpdateNoLocks, Encoding UTF16 (not UTF8), Caption = the object name;
//  - "All Profile" of a profile that states only Caption and RoleCenter: Enabled Yes, Promoted No, empty
//    Description, "Role Center ID" the page id;
//  - "Event Subscription" of two table event subscribers: Event Type Trigger; Published Function is the
//    event name as written (OnAfterInsertEvent) and, for a field event, the name followed by " - " and the
//    field name (OnBeforeValidateEvent - Txt); the publisher is the table.
// BC versions: 27.5

table 68470 "Probe Defaults Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 68471 "Probe Defaults XmlPort"
{
    schema
    {
        textelement(Root)
        {
            textelement(Item) { }
        }
    }
}

page 68472 "Probe Defaults RC"
{
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter) { }
    }
}

profile "Probe Defaults Profile"
{
    Caption = 'Probe defaults profile';
    RoleCenter = "Probe Defaults RC";
}

codeunit 68473 "Probe Defaults Sub"
{
    [EventSubscriber(ObjectType::Table, Database::"Probe Defaults Table", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "Probe Defaults Table")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Defaults Table", 'OnBeforeValidateEvent', 'Txt', false, false)]
    local procedure BeforeValidate(var Rec: Record "Probe Defaults Table")
    begin
    end;
}

codeunit 68474 "Probe Metadata Defaults"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure XmlPortMetadata_PropertiesLeftOut_HaveTheirDefaults()
    var
        XmlPortMeta: Record "XmlPort Metadata";
    begin
        XmlPortMeta.Get(Xmlport::"Probe Defaults XmlPort");

        Assert.AreEqual(XmlPortMeta.Direction::Both, XmlPortMeta.Direction, 'Direction');
        Assert.AreEqual(XmlPortMeta.Format::Xml, XmlPortMeta.Format, 'Format');
        Assert.IsTrue(XmlPortMeta.UseRequestPage, 'UseRequestPage');
        Assert.AreEqual(XmlPortMeta.TransactionType::UpdateNoLocks, XmlPortMeta.TransactionType, 'TransactionType');
        Assert.AreEqual(XmlPortMeta.Encoding::UTF16, XmlPortMeta.Encoding, 'Encoding');
        Assert.AreEqual('Probe Defaults XmlPort', XmlPortMeta.Caption, 'Caption is the object name');
    end;

    [Test]
    procedure AllProfile_EnabledAndPromotedLeftOut_AreYesAndNo()
    var
        AllProfileRec: Record "All Profile";
    begin
        AllProfileRec.SetRange("Profile ID", 'PROBE DEFAULTS PROFILE');
        AllProfileRec.FindFirst();

        Assert.AreEqual('Probe defaults profile', AllProfileRec.Caption, 'Caption');
        Assert.IsTrue(AllProfileRec.Enabled, 'Enabled');
        Assert.IsFalse(AllProfileRec.Promoted, 'Promoted');
        Assert.AreEqual('', AllProfileRec.Description, 'Description');
        Assert.AreEqual(Page::"Probe Defaults RC", AllProfileRec."Role Center ID", 'Role Center ID');
    end;

    [Test]
    procedure EventSubscription_TableEvents_AreTriggerEventsNamedAsWritten()
    var
        EventSub: Record "Event Subscription";
        Rows: Text;
    begin
        EventSub.SetRange("Subscriber Codeunit ID", Codeunit::"Probe Defaults Sub");
        EventSub.FindSet();
        repeat
            Rows += Format(EventSub."Event Type") + ' ' + Format(EventSub."Publisher Object Type") + ' ' + Format(EventSub."Publisher Object ID") + ' [' + EventSub."Published Function" + '] ' + EventSub."Subscriber Function" + ';';
        until EventSub.Next() = 0;

        Assert.AreEqual(
            'Trigger Table 68470 [OnAfterInsertEvent] AfterInsert;Trigger Table 68470 [OnBeforeValidateEvent - Txt] BeforeValidate;',
            Rows, 'subscriptions');
    end;
}
