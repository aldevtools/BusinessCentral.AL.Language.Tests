// Fixture for TestPageQueryCloseError_Tests.al.
/// <summary>
/// The row "QCE Error Modal" writes from its OnOpenPage. Nothing else writes it, so its
/// presence or absence after a failed close is entirely the platform's answer about what an
/// error raised in OnQueryClosePage does to the writes the page already made.
/// </summary>
table 60675 "QCE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Set ID"; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
