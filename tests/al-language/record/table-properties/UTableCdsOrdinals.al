// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optionordinalvalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 599.1): OptionOrdinalValues needs TableType = CRM or CDS and ExternalType Picklist, State or Status (AL0167 otherwise, see the must-not-compile case).
// The table below is a CDS table: its records can be built and read in memory, so the names against the ordinals show in Format, assignment, Evaluate
// and FieldRef. Object ids 69581 and 69782.

table 69581 "LT U Cds Option"
{
    TableType = CDS;
    ExternalName = 'ltucdsoption';

    fields
    {
        field(1; Id; Guid)
        {
            ExternalName = 'ltucdsoptionid';
            ExternalType = 'Uniqueidentifier';
            ExternalAccess = Insert;
        }
        field(2; Opt; Option)
        {
            ExternalName = 'ltuopt';
            ExternalType = 'Picklist';
            OptionMembers = Alpha,Beta,Gamma;
            OptionOrdinalValues = 5, 10, 20;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69782 "LT U Cds Option Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OptionOrdinalValues_Format_Assign_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT U Cds Option" temporary;
        Ordinal: Integer;
        Parsed: Option Alpha,Beta,Gamma;
    begin
        Rec.Init();
        Rec.Opt := Rec.Opt::Beta;
        Ordinal := Rec.Opt;
        Observer.Observe('beta_format', Format(Rec.Opt));
        Observer.Observe('beta_ordinal', Format(Ordinal));
        Observer.Observe('beta_format_ordinal', Format(Rec.Opt, 0, 2));
        Observer.Observe('beta_format_xml', Format(Rec.Opt, 0, 9));
        Rec.Opt := Rec.Opt::Gamma;
        Ordinal := Rec.Opt;
        Observer.Observe('gamma_ordinal', Format(Ordinal));
        Rec.Opt := Rec.Opt::Alpha;
        Ordinal := Rec.Opt;
        Observer.Observe('alpha_ordinal', Format(Ordinal));
        Observer.Observe('init_value_format', Format(Rec.Opt));

        Rec.Opt := 10;
        Observer.Observe('assign_10_format', Format(Rec.Opt));
        Rec.Opt := 20;
        Observer.Observe('assign_20_format', Format(Rec.Opt));
        Rec.Opt := 5;
        Observer.Observe('assign_5_format', Format(Rec.Opt));
        Rec.Opt := 1;
        Observer.Observe('assign_1|no_error', 'true');
        Rec.Opt := 2;
        Observer.Observe('assign_2|no_error', 'true');

        Observer.Observe('evaluate_name_ok', Format(Evaluate(Rec.Opt, 'Gamma')));
        Observer.Observe('evaluate_name_format', Format(Rec.Opt));
        Observer.Observe('evaluate_ordinal_10_ok', Format(Evaluate(Rec.Opt, '10')));
        Observer.Observe('evaluate_ordinal_10_format', Format(Rec.Opt));
        Observer.Observe('evaluate_ordinal_1_ok', Format(Evaluate(Rec.Opt, '1')));
        Observer.ObserveError('evaluate_ordinal_1');
        Observer.Observe('evaluate_unknown_ok', Format(Evaluate(Rec.Opt, 'Delta')));
        Observer.Observe('local_option_evaluate_gamma', Format(Evaluate(Parsed, 'Gamma')));
        Observer.Observe('local_option_gamma_ordinal', Format(Parsed));
        Observer.Expect('beta_format', 'Beta');
        Observer.Expect('beta_ordinal', '1');
        Observer.Expect('beta_format_ordinal', '1');
        Observer.Expect('beta_format_xml', '1');
        Observer.Expect('gamma_ordinal', '2');
        Observer.Expect('alpha_ordinal', '0');
        Observer.Expect('init_value_format', 'Alpha');
        Observer.Expect('assign_10_format', '10');
        Observer.Expect('assign_20_format', '20');
        Observer.Expect('assign_5_format', '5');
        Observer.Expect('assign_1|no_error', 'true');
        Observer.Expect('assign_2|no_error', 'true');
        Observer.Expect('evaluate_name_ok', 'Yes');
        Observer.Expect('evaluate_name_format', 'Gamma');
        Observer.Expect('evaluate_ordinal_10_ok', 'Yes');
        Observer.Expect('evaluate_ordinal_10_format', '10');
        Observer.Expect('evaluate_ordinal_1_ok', 'Yes');
        Observer.Expect('evaluate_ordinal_1|text', '');
        Observer.Expect('evaluate_ordinal_1|code', '');
        Observer.Expect('evaluate_unknown_ok', 'No');
        Observer.Expect('local_option_evaluate_gamma', 'Yes');
        Observer.Expect('local_option_gamma_ordinal', 'Gamma');
        Observer.Verify();
    end;

    [Test]
    procedure OptionOrdinalValues_FieldRef_Filters()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT U Cds Option" temporary;
        Plain: Record "LT U Cds Option";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Rec.SetRange(Opt, Rec.Opt::Gamma);
        Observer.Observe('range_gamma_filter_text', Rec.GetFilter(Opt));
        Rec.SetFilter(Opt, 'Beta|Gamma');
        Observer.Observe('filter_names_text', Rec.GetFilter(Opt));
        Rec.SetFilter(Opt, '10');
        Observer.Observe('filter_ordinal_10_text', Rec.GetFilter(Opt));
        Rec.SetFilter(Opt, '1');
        Observer.Observe('filter_ordinal_1|no_error', 'true');
        Rec.SetFilter(Opt, '>=10');
        Observer.Observe('filter_ge_10_text', Rec.GetFilter(Opt));
        Rec.Reset();

        Rec.Init();
        Rec.Opt := Rec.Opt::Beta;
        RecRef.GetTable(Rec);
        FieldRef := RecRef.Field(Rec.FieldNo(Opt));
        Observer.Observe('fieldref_value', Format(FieldRef.Value));
        Observer.Observe('fieldref_option_members', FieldRef.OptionMembers);
        Observer.Observe('fieldref_option_caption', FieldRef.OptionCaption);
        Observer.Observe('fieldref_format_ordinal', Format(FieldRef.Value, 0, 2));
        FieldRef.Value := 20;
        Observer.Observe('fieldref_set_20_value', Format(FieldRef.Value));
        asserterror FieldRef.Value := 'Alpha';
        Observer.ObserveError('fieldref_set_alpha');
        Observer.Observe('fieldref_after_failed_alpha', Format(FieldRef.Value));
        FieldRef.Validate(10);
        Observer.Observe('fieldref_validate_10_value', Format(FieldRef.Value));

        Observer.Observe('is_temporary', Format(Rec.IsTemporary()));
        Rec.Insert();
        Observer.Observe('temp_insert_count', Format(Rec.Count()));
        Observer.Observe('temp_find_first', Format(Rec.FindFirst()));
        Observer.Observe('temp_find_first_value', Format(Rec.Opt));
        asserterror Plain.Init();
        Observer.Observe('plain_init_failed', Format(GetLastErrorText() <> ''));
        ClearLastError();
        asserterror Plain.Insert();
        Observer.Observe('plain_insert_failed', Format(GetLastErrorText() <> ''));
        ClearLastError();
        asserterror Plain.FindFirst();
        Observer.Observe('plain_find_first_failed', Format(GetLastErrorText() <> ''));
        ClearLastError();
        Observer.Expect('range_gamma_filter_text', 'Gamma');
        Observer.Expect('filter_names_text', 'Beta|Gamma');
        Observer.Expect('filter_ordinal_10_text', '10');
        Observer.Expect('filter_ordinal_1|no_error', 'true');
        Observer.Expect('filter_ge_10_text', '>=10');
        Observer.Expect('fieldref_value', 'Beta');
        Observer.Expect('fieldref_option_members', 'Alpha,Beta,Gamma');
        Observer.Expect('fieldref_option_caption', 'Alpha,Beta,Gamma');
        Observer.Expect('fieldref_format_ordinal', '1');
        Observer.Expect('fieldref_set_20_value', '20');
#if BC28PLUS
        Observer.Expect('fieldref_set_alpha|text', 'The value "Alpha" can''t be evaluated into type Option.');
#else
        Observer.Expect('fieldref_set_alpha|text', 'The type NavOption is unknown.');
#endif
#if BC28PLUS
        Observer.Expect('fieldref_set_alpha|code', 'Evaluate:Format');
#else
        Observer.Expect('fieldref_set_alpha|code', 'NotSupportedType');
#endif
        Observer.Expect('fieldref_after_failed_alpha', '20');
        Observer.Expect('fieldref_validate_10_value', '10');
        Observer.Expect('is_temporary', 'Yes');
        Observer.Expect('temp_insert_count', '1');
        Observer.Expect('temp_find_first', 'Yes');
        Observer.Expect('temp_find_first_value', 'Beta');
        Observer.Expect('plain_init_failed', 'Yes');
        Observer.Expect('plain_insert_failed', 'Yes');
        Observer.Expect('plain_find_first_failed', 'Yes');
        Observer.Verify();
    end;
}
