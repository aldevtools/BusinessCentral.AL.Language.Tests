// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT EMF Kind (97997) and LT EMF Line (97997) of AL Language XApp A
//   (tests/al-language-xapp-a/table-objects/EnumMemberFieldTypeXaEnum.al and _XaTable.al); LT EMF Kind (97055) and
//   LT EMF Own Namespace Reader (97056) in EnumMemberFieldType_Twin.al; LT EMF Using Reader (97057) in
//   EnumMemberFieldType_Using.al
// Probe: written against al-runner issue 8317; measured on a local BC 29.1 OnPrem w1 container.
// BC versions: 27.0+
//
// CLAIM: `Rec.Field::Member` names a member of the field's own enum, whatever enum of that name the
// file finds by its own namespace and usings: the name found twice (this file uses neither enum's
// namespace, so the search in every namespace finds both), found in
// the file's own namespace (EmfTwin's reader), or found through a `using` (EmfUsing's reader). The
// twin has Production at ordinal 5; the field's enum at 1, Transfer at 2. An assignment, a comparison,
// a case and `.AsInteger()` on the member all take the field's enum's value.
// local object: the test codeunit; the enums of one name live in two apps on purpose.

namespace ALLanguage.Coverage.EmfTests;

using ALLanguage.Coverage.EmfData;
using ALLanguage.Coverage.EmfUsing;

codeunit 97055 "LT EMF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FieldMember_NameFoundTwice_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT EMF Line";
    begin
        Line.Kind := Line.Kind::Production;
        Observer.Observe('assign_ordinal', Format(Line.Kind.AsInteger()));
        Observer.Observe('assign_name', Format(Line.Kind));
        Observer.Observe('member_ordinal', Format(Line.Kind::Transfer.AsInteger()));
        Line.Kind := Line.Kind::Transfer;
        Observer.Observe('equals_production', Format(Line.Kind = Line.Kind::Production));
        Observer.Observe('equals_transfer', Format(Line.Kind = Line.Kind::Transfer));
        case Line.Kind of
            Line.Kind::Production:
                Observer.Observe('case', 'production');
            Line.Kind::Transfer:
                Observer.Observe('case', 'transfer');
            else
                Observer.Observe('case', 'else');
        end;
        Observer.Expect('assign_ordinal', '1');
        Observer.Expect('assign_name', 'Production');
        Observer.Expect('member_ordinal', '2');
        Observer.Expect('equals_production', 'No');
        Observer.Expect('equals_transfer', 'Yes');
        Observer.Expect('case', 'transfer');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_SameNamedEnumInOwnNamespace_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit ALLanguage.Coverage.EmfTwin."LT EMF Own Namespace Reader";
        Line: Record "LT EMF Line";
    begin
        Observer.Observe('assign_ordinal', Format(Reader.ProductionOrdinal()));
        Line.Kind := Line.Kind::Production;
        Observer.Observe('production_is_production', Format(Reader.IsProduction(Line)));
        Line.Kind := Line.Kind::Transfer;
        Observer.Observe('transfer_is_production', Format(Reader.IsProduction(Line)));
        Observer.Expect('assign_ordinal', '1');
        Observer.Expect('production_is_production', 'Yes');
        Observer.Expect('transfer_is_production', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FieldMember_SameNamedEnumThroughUsing_IsTheFieldsEnumMember()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT EMF Using Reader";
        Line: Record "LT EMF Line";
    begin
        Observer.Observe('assign_ordinal', Format(Reader.ProductionOrdinal()));
        Line.Kind := Line.Kind::Production;
        Observer.Observe('production_is_production', Format(Reader.IsProduction(Line)));
        Line.Kind := Line.Kind::Transfer;
        Observer.Observe('transfer_is_production', Format(Reader.IsProduction(Line)));
        Observer.Expect('assign_ordinal', '1');
        Observer.Expect('production_is_production', 'Yes');
        Observer.Expect('transfer_is_production', 'No');
        Observer.Verify();
    end;
}
