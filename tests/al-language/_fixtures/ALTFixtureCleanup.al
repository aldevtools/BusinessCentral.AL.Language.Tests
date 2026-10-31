codeunit 60019 ALTFixtureCleanup
{
    procedure Initialize()
    var
        ALTUniversal: Record "ALT Universal";
        ALTComposite: Record "ALT Composite";
        ALTTriggered: Record "ALT Triggered";
        ALTTriggerLog: Record "ALT Trigger Log";
        ALTParent: Record "ALT Parent";
        ALTChild: Record "ALT Child";
        ALTKeyed: Record "ALT Keyed";
        ALTBase: Record "ALT Base";
        ALTBlob: Record "ALT Blob";
        ALTErrorTrigger: Record "ALT Error Trigger";
        ALTInitValue: Record "ALT Init Value";
        ALTInternalTable: Record "ALT Internal Table";
        ALTRelationChild: Record "ALT Relation Child";
        ALTRelationParent: Record "ALT Relation Parent";
        ALTRelationParentB: Record "ALT Relation Parent B";
        ALTRelWhereParent: Record "ALT Rel Where Parent";
        ALTRelWhereChild: Record "ALT Rel Where Child";
        ALTManualTableEventPub: Record "ALT Manual TableEvent Pub";
        ALTMedia: Record "ALT Media";
        ALTIncludeSenderTablePub: Record "ALT IncludeSender Table Pub";
        ALTNoSubscriberTable: Record "ALT No Subscriber Table";
        ALTSubscribedTable: Record "ALT Subscribed Table";
        ALTTableFilterHolder: Record "ALT TableFilter Holder";
        ALTTableFilterPlainTarget: Record "ALT TF Plain Target";
    begin
        ALTUniversal.DeleteAll(false);
        ALTComposite.DeleteAll(false);
        ALTTriggered.DeleteAll(false);
        ALTTriggerLog.DeleteAll(false);
        ALTParent.DeleteAll(false);
        ALTChild.DeleteAll(false);
        ALTKeyed.DeleteAll(false);
        ALTBase.DeleteAll(false);
        ALTBlob.DeleteAll(false);
        ALTErrorTrigger.DeleteAll(false);
        ALTInitValue.DeleteAll(false);
        ALTInternalTable.DeleteAll(false);
        ALTRelationChild.DeleteAll(false);
        ALTRelationParent.DeleteAll(false);
        ALTRelationParentB.DeleteAll(false);
        ALTRelWhereChild.DeleteAll(false);
        ALTRelWhereParent.DeleteAll(false);
        ALTManualTableEventPub.DeleteAll(false);
        ALTMedia.DeleteAll(false);
        ALTIncludeSenderTablePub.DeleteAll(false);
        ALTNoSubscriberTable.DeleteAll(false);
        ALTSubscribedTable.DeleteAll(false);
        ALTTableFilterHolder.DeleteAll(false);
        ALTTableFilterPlainTarget.DeleteAll(false);
    end;
}
