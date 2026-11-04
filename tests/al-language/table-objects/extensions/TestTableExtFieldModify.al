// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-caption-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldcaption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Modified (60506) and ALT Modified Ext (60499), the tableextension that
//   changes field 10's Caption through modify(...), leaves field 11 alone, and adds field
//   50000.
// BC versions: 27.0+
//
// CLAIM (the file's subject): a tableextension's `modify(<field>)` block CHANGES the existing
// field's declared properties on the extended table, and the changed value is what AL reads
// back. The corpus already pins what a tableextension ADDS — columns
// (TestTableExtCrossApp), keys and InitValue (TestTableExtKeysAndInitValue), OnValidate
// (TestTableExtFieldTestPageControl) — but nothing yet asks whether modify(...) does
// anything at all.
//
// The distinction matters because the two halves of a tableextension are not the same
// mechanism underneath: a field it ADDS is folded into the base table's own compiled
// metadata, while a property it MODIFIES is carried separately as a delta against that
// table. A consumer can implement the first and not the second, and every existing
// tableextension test in this corpus would still pass. So each test below is paired with a
// CONTROL ARM — an unmodified field of the same table, or the added field — which fails in
// the opposite direction if captions are simply broken.
//
// Caption is the property under test because AL permits very few properties in a table
// field's modify(...) at all — NotBlank, MinValue, MaxValue, Editable, DataClassification
// and most others are rejected at compile time (AL0246 / AL0294) in this position — and
// Caption is among the few that is both permitted and readable from AL.
//
// Written by agent stma-auto-2.

codeunit 60500 "TableExt Field Modify"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ── modify(...) changes the caption, via Record.FieldCaption ─────────────────────────

    [Test]
    procedure TableExtModify_FieldCaption_AnswersTheExtensionsCaption()
    // CLAIM: field 10 declares Caption = 'Original Overridden Caption' on the table and the
    // tableextension's modify(...) sets 'Extension Overridden Caption'. FieldCaption answers
    // the EXTENSION's value.
    var
        Modified: Record "ALT Modified";
    begin
        Assert.AreEqual(
          'Extension Overridden Caption', Modified.FieldCaption("Overridden Field"),
          'FieldCaption must answer the Caption the tableextension modify(...) declared, not the table''s own');
    end;

    [Test]
    procedure TableExtModify_FieldCaption_LeavesAnUnmodifiedFieldAlone()
    // CONTROL for the test above. Field 11 is declared by the same table and is NOT named by
    // any modify(...) block, so it must still answer the TABLE's caption. Without this arm a
    // consumer that returned the extension's caption for every field of the table would pass
    // the test above.
    var
        Modified: Record "ALT Modified";
    begin
        Assert.AreEqual(
          'Original Untouched Caption', Modified.FieldCaption("Untouched Field"),
          'a field no modify(...) names must keep the Caption its own table declared');
    end;

    [Test]
    procedure TableExtModify_FieldCaption_AddedFieldKeepsItsOwnCaption()
    // SECOND CONTROL: the field the SAME tableextension adds. An added field and a modified
    // field reach the table by different routes, so this arm distinguishes "the extension is
    // being read at all" from "the modify(...) half of it is being read".
    var
        Modified: Record "ALT Modified";
    begin
        Assert.AreEqual(
          'Added Field Caption', Modified.FieldCaption("Added Field"),
          'a field the tableextension ADDS must carry the Caption the extension declared for it');
    end;

    // ── The same claim through RecordRef/FieldRef ────────────────────────────────────────

    [Test]
    procedure TableExtModify_FieldRefCaption_AnswersTheExtensionsCaption()
    // CLAIM: the change is on the table's METADATA, not a property of the strongly-typed
    // Record wrapper — so the late-bound read answers it too. FieldRef.Caption reaches the
    // field metadata by a different path than Record.FieldCaption above.
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(60506);
        FldRef := RecRef.Field(10);
        Assert.AreEqual(
          'Extension Overridden Caption', FldRef.Caption(),
          'FieldRef.Caption must answer the Caption the tableextension modify(...) declared');
    end;

    [Test]
    procedure TableExtModify_FieldRefCaption_LeavesAnUnmodifiedFieldAlone()
    // CONTROL for the FieldRef arm, same role as the Record control above.
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(60506);
        FldRef := RecRef.Field(11);
        Assert.AreEqual(
          'Original Untouched Caption', FldRef.Caption(),
          'FieldRef.Caption on a field no modify(...) names must keep the table''s own Caption');
    end;

    // ── modify(...) changes only the property it names ───────────────────────────────────

    [Test]
    procedure TableExtModify_LeavesTheFieldsNameAndTypeIntact()
    // CLAIM: modify(...) changes the properties it lists and nothing else. The field keeps
    // its name, its number and its type — so the caption change above is a property change,
    // not the field being replaced. Asserted through FieldName (the name is NOT the caption
    // here, which is what makes this readable at all) and a round-tripped value.
    var
        Modified: Record "ALT Modified";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Assert.AreEqual(
          'Overridden Field', Modified.FieldName("Overridden Field"),
          'modify(...) must not change the field''s NAME');

        RecRef.Open(60506);
        FldRef := RecRef.Field(10);
        FldRef.Value := 'still a Text field';
        Assert.AreEqual(
          'still a Text field', Format(FldRef.Value),
          'modify(...) must leave the field''s TYPE assignable exactly as the table declared it');
    end;

    // ── Added by writer bs (corpus issue #668, items 81, 85, 100) ───────────────────────

    [Test]
    procedure TableExtModify_FieldTable_FieldCaption_AnswersTheExtensionsCaption()
    // CLAIM (issue #668 item 100): the virtual Field table reads the Caption a tableextension's modify(...) set, as FieldCaption and
    // FieldRef.Caption do above; the unmodified field keeps the table's Caption.
    var
        Observer: Codeunit "Probe Observer";
        FieldRec: Record Field;
    begin
        FieldRec.Get(60506, 10);
        Observer.Observe('field_table_caption_modified', FieldRec."Field Caption");
        FieldRec.Get(60506, 11);
        Observer.Observe('field_table_caption_untouched', FieldRec."Field Caption");
        Observer.Expect('field_table_caption_modified', 'Extension Overridden Caption');
        Observer.Expect('field_table_caption_untouched', 'Original Untouched Caption');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_CaptionProperty_TableCaptionAndMetadata()
    // CLAIM (issue #668 item 81): a tableextension may set Caption (it compiles on runtimes 16.1, 17.1 and 18.0). Which caption do
    // TableCaption, RecordRef.Caption and AllObjWithCaption answer for the extended table: the table's or the extension's?
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
        RecRef: RecordRef;
        AllObj: Record AllObjWithCaption;
    begin
        Observer.Observe('table_caption', Base.TableCaption());
        RecRef.Open(Database::"LT BS Base");
        Observer.Observe('recordref_caption', RecRef.Caption());
        RecRef.Close();
        AllObj.Get(AllObj."Object Type"::Table, Database::"LT BS Base");
        Observer.Observe('allobj_table_caption', AllObj."Object Caption");
        AllObj.Get(AllObj."Object Type"::TableExtension, 83150);
        Observer.Observe('allobj_tableextension_caption', AllObj."Object Caption");
        Observer.Expect('table_caption', 'LT BS Ext Caption');
        Observer.Expect('recordref_caption', 'LT BS Ext Caption');
        Observer.Expect('allobj_table_caption', 'LT BS Ext Caption');
        Observer.Expect('allobj_tableextension_caption', 'LT BS Base Ext One');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_FieldNameLongerThan30_NameAndValue()
    // CLAIM (issue #668 item 85): a tableextension field named with 35 characters compiles with warning AL0468 only. The app publishes; what
    // do FieldName, FieldRef.Name and the Field table give, and does the column store and read a value?
    var
        Observer: Codeunit "Probe Observer";
        Base: Record "LT BS Base";
        FieldRec: Record Field;
        RecRef: RecordRef;
    begin
        Base.DeleteAll();
        Base.Init();
        Base.Id := 1;
        Base."LT BS Field Name Longer Than Thirty" := 42;
        Base.Insert();
        Base.Get(1);
        Observer.Observe('value', Format(Base."LT BS Field Name Longer Than Thirty"));
        Observer.Observe('field_name', Base.FieldName("LT BS Field Name Longer Than Thirty"));
        Observer.Observe('field_caption', Base.FieldCaption("LT BS Field Name Longer Than Thirty"));
        RecRef.GetTable(Base);
        Observer.Observe('fieldref_name', RecRef.Field(83150).Name());
        FieldRec.Get(Database::"LT BS Base", 83150);
        Observer.Observe('field_table_name', FieldRec.FieldName);
        Observer.Observe('field_table_name_length', Format(StrLen(FieldRec.FieldName)));
        Base.SetRange("LT BS Field Name Longer Than Thirty", 42);
        Observer.Observe('filter_count', Format(Base.Count()));
        Observer.Observe('get_filters', Base.GetFilters());
        Base.DeleteAll();
        Observer.Expect('value', '42');
        Observer.Expect('field_name', 'LT BS Field Name Longer Than Thirty');
        Observer.Expect('field_caption', 'LT BS Field Name Longer Than Thirty');
        Observer.Expect('fieldref_name', 'LT BS Field Name Longer Than Thirty');
        Observer.Expect('field_table_name', 'LT BS Field Name Longer Than T');
        Observer.Expect('field_table_name_length', '30');
        Observer.Expect('filter_count', '1');
        Observer.Expect('get_filters', 'LT BS Field Name Longer Than Thirty: 42');
        Observer.Verify();
    end;
}
