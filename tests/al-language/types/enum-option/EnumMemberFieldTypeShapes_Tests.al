// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT EMF Kind (97997), LT EMF GKind (97990), LT EMF Grade (97991, global namespace)
//   and LT EMF Line (97997) of AL Language XApp A (tests/al-language-xapp-a/table-objects/EnumMemberFieldTypeXa*.al);
//   LT EMF Kind (61110), LT EMF Grade (61111) and LT EMF Graded Line (61111) of AL Language XApp B
//   (tests/al-language-xapp-b/EnumMemberFieldTypeXb*.al); the readers and twins in EnumMemberFieldTypeShapes_Twin.al,
//   _Ext.al, _BothUsings.al and _TwoTwins.al.
// Probe: written against the review of al-runner pull request 8319 (issue 8317); measured on a local BC 29.1 OnPrem w1
//   container.
// BC versions: 27.0+
//
// CLAIM: `Field::Member` on an Enum field names a member of the field's own enum, whatever enum of that name the file
// finds, in the shapes EnumMemberFieldType_Tests.al leaves open: a temporary record; a member an enum extension adds; a
// field a table extension adds; a field whose enum is in the global namespace; Rec and the bare field name in a table
// extension and in a page; a file whose usings find the name twice, once as the field's enum or twice as other enums; a
// file that finds another enum of that name in the global namespace. Every twin has Production at another ordinal than
// the field's enum (1).
// local object: the test codeunit; the enums of one name live in several apps on purpose.

namespace ALLanguage.Coverage.EmfShapeTests;

using ALLanguage.Coverage.EmfData;
using ALLanguage.Coverage.EmfGradeData;

codeunit 97052 "LT EMF Shape Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FieldMember_TemporaryRecord_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfTwin."LT EMF Twin Shapes Reader";
    begin
        Observer.Observe('ordinal', Format(Reader.TemporaryOrdinal()));
        Observer.Expect('ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_EnumExtensionMember_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT EMF Line";
    begin
        // This file uses neither enum's namespace: the search in every namespace finds the name three times.
        Line.Kind := Line.Kind::Recall;
        Observer.Observe('ordinal', Format(Line.Kind.AsInteger()));
        Observer.Observe('name', Format(Line.Kind));
        Observer.Observe('equals', Format(Line.Kind = Line.Kind::Recall));
        Observer.Expect('ordinal', '30');
        Observer.Expect('name', 'Recall');
        Observer.Expect('equals', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_FieldOfTableExtension_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfTwin."LT EMF Twin Shapes Reader";
    begin
        Observer.Observe('ordinal', Format(Reader.ExtensionFieldOrdinal()));
        Observer.Expect('ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_FieldEnumInGlobalNamespace_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfTwin."LT EMF Twin Shapes Reader";
    begin
        Observer.Observe('ordinal', Format(Reader.GlobalEnumFieldOrdinal()));
        Observer.Expect('ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_InTableExtension_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfTwin."LT EMF Twin Shapes Reader";
    begin
        Observer.Observe('rec', Format(Reader.RecInTableExtensionOrdinal()));
        Observer.Observe('bare', Format(Reader.BareInTableExtensionOrdinal()));
        Observer.Expect('rec', '1');
        Observer.Expect('bare', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_InPage_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfTwin."LT EMF Twin Shapes Reader";
    begin
        Observer.Observe('rec', Format(Reader.RecInPageOrdinal()));
        Observer.Observe('bare', Format(Reader.BareInPageOrdinal()));
        Observer.Expect('rec', '1');
        Observer.Expect('bare', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_UsingsFindFieldsEnumAndTwin_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfBoth."LT EMF Both Usings Reader";
    begin
        Observer.Observe('ordinal', Format(Reader.ProductionOrdinal()));
        Observer.Expect('ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_UsingsFindTwoTwins_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfTwins."LT EMF Two Twins Reader";
    begin
        Observer.Observe('ordinal', Format(Reader.ProductionOrdinal()));
        Observer.Expect('ordinal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_TwinInGlobalNamespace_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT EMF Graded Line";
    begin
        // This file finds XApp A's LT EMF Grade of the global namespace by the name, not the field's (namespace EmfGrades).
        Line.Grade := Line.Grade::Production;
        Observer.Observe('ordinal', Format(Line.Grade.AsInteger()));
        Observer.Observe('equals', Format(Line.Grade = Line.Grade::Production));
        Observer.Expect('ordinal', '1');
        Observer.Expect('equals', 'Yes');
        Observer.Verify();
    end;
}
