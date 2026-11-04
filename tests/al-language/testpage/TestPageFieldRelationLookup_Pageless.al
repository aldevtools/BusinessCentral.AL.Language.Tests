// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: TRL Pageless (60570), TRL Host (60565)
//
// The third related table in the TableRelation-lookup suite, and the only one that declares
// NEITHER LookupPageId NOR DrillDownPageId. It is "TRL Related" (60563) minus exactly those
// properties, so a lookup that resolves a relation to it has a related table and no page the
// relation can name.
//
// BC's own NavRecord.GetPageToOpen returns LookupFormId, falling back to DrillDownPageId, and
// answers 0 for this table. What the lookup does with that 0 was the question this fixture was
// built to ask, and a service tier answered it: BC decides to show a modal form anyway and
// raises "Unhandled UI: ModalPage" (run 35493508143, all eight cloud legs).
//
// WHICH page BC intended is not measurable from the corpus. A [ModalPageHandler] probe was
// tried and cannot work: FindHandler's page-id check sits inside its `appObject != null`
// guard, so a null registered form skips the check and .ObjectId then NREs (run 35494023689).
// BC decides to open a page and does not materialise one. Runner issue #4403 tracks it.

table 60570 "TRL Pageless"
{
    DataClassification = CustomerContent;
    // Deliberately no LookupPageId and no DrillDownPageId. That absence is the subject.

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
