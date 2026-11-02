// @expect AL0443 | The system object provided is not one of the valid system objects.
// A system grant must name one of the valid system objects (AllObj, Object Type System). Without any other error in the file this one is reported.
permissionset 59674 "MNC Y69 PS 2672"
{
    Assignable = true;
    Permissions = system "MNC Y69 No Such System Object" = X;
}
