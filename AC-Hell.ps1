clear

$CSVData = Import-Csv "$PSScriptRoot\migrationlocations.csv"

# Initilaises important group information
# Needs to be changed to work with an input file rather than be hard coded
foreach ($line in $CSVData)
{
    $source = $CSVData.source

    $destination = $CSVData.destination

    $groupid = $CSVData.group

    $starttime = [datetime]::Now

    $filename = $starttime.DateTime.replace(":","-")

    Start-Transcript -Path "$PSScriptRoot\AC-Hell Outputs\$groupid, $filename.csv"

    echo "Starting at " $starttime

    # Regex pattern used to identify members of the group
    $pattern = '(?<=CN=).+?(?=\,)'

    # Finds the members of the top level group and adds UNCLE\ to the front of their names
    # Input is the main fim group used for this share from the variable $groupid
    # Output is a list of users with UNCLE\ appended to the front in the variable $group
    $aclgroup = get-adgroup $groupid -properties * | select -expandproperty member
    $group = [regex]::Matches($aclgroup, $pattern).value
    $tempgroup = $group
    $group = @()
    foreach ($member in $tempgroup)
    {
        $member = "UNCLE\"+$member
        $group = $group+$member
    }

    # Makes the groupid accessible from other functions
    $groupid = "UNCLE\"+$groupid

    # List of SIDs that are not moving to OnTap, used to filter lists below
    # Will need to be constantly updated with newly found legacy SID's
    $exclusions = "UNCLE\BigKev","UNCLE\arcs_ad_admin","UNCLE\spomigrate","CREATOR OWNER","EVERYONE","NT AUTHORITY\SYSTEM","BUILTIN\Administrators","BUILTIN\Users","S-1-5-32-767","S-1-5-32-766","admin_tier1nas","admin_tier2nas","admin_tier3nas"

    # Creates a fresh Win_Sys_Admins SID to be applied to every folder interacted with
    $winsys = New-Object System.Security.AccessControl.FileSystemAccessRule("UNCLE\Win_Sys_Admins","FullControl","ContainerInherit, ObjectInherit","None","Allow")





    # Recursively gets all directories from the specified top level and performs the cleansing operation on each directory found
    # Needs to be changed to work with an input file rather than be hard coded
    get-childitem -directory $source -recurse | foreach-object{   
        # Compares the access of the current folder and its parent folder
        # Output is the differences between the two ACL's in text form in the variable $comp
        $acl = ((get-acl -literalpath $PSItem.fullname).access | sort-object -property identityreference -unique).identityreference.value
        $pacl = ((get-acl -literalpath $PSItem.parent.fullname).access | sort-object -property identityreference -unique).identityreference.value
        $comp = ((compare-object $pacl $acl).inputobject)

        # Removes all occurrences of the excluded SIDs from the comparison object
        # Output is only the user relevant differences like user groups and individual users
        if ($comp -ne $null)
        {
            foreach ($exclusion in $exclusions)
            {
                $comp = $comp | Where-Object {$PSitem -ne $exclusion}
            }
        }

        # Now that all the excluded groups have been removed from the comparison, runs additional operations if there are still differences
        if ($comp -ne $null)
        {   
            # Removes each of the exclusions from the original ACL and Parent ACL
            foreach ($exclusion in $exclusions)
            {
                $acl = $acl | Where-Object {$PSitem -ne $exclusion}
                $pacl = $pacl | Where-Object {$PSItem -ne $exclusion}
            }

            # Prints the full path of the object that has been selected for alteration
            $PSItem.fullname

            # If the ACL contains the group and a user, checks if the user is part of the group
            # If the user is part of the group, removes the explicit user permission
            if ($acl -contains $groupid)
            {
                foreach ($user in $group)
                    {
                        $acl = $acl | Where-Object {$PSitem -ne $user}
                    }
            }
        
            # If after all edits and filters, the current folder is still different to the parent, the custom permissions are copied to the new file
            if ((compare-object $acl $pacl) -ne $null)
            {
                # Creates a clean ACL and instanty grants full control to Win_Sys_Admins
                $emptyacl = New-Object System.Security.AccessControl.DirectorySecurity
                $emptyacl.AddAccessRule($winsys)

                # Creates a new "modify" ACE for each custom permission on the original file, and adds it to the clean ACL
                foreach ($ace in $acl)
                {
                    if ($ace -ne "UNCLE\Win_Sys_Admins")
                    {
                        $newace = New-Object System.Security.AccessControl.FileSystemAccessRule($ace,"Modify","ContainerInherit, ObjectInherit","None","Allow")
                        $emptyacl.AddAccessRule($newace)
                    }
                }

                # Configures the clean ACL to turn off inheritence and delete all existing permissions when it is applied
                $emptyacl.SetAccessRuleProtection($true,$false)
                

                # Overwrites the existing ACL in ONTAP with the clean ACL, aiming at the same directory in another drive letter
                # This change will cascade down and apply to all folders and files underneath the target folder
                $emptyacl | set-acl -literalpath $PSItem.fullname.replace($source,$destination)
            }
        }
    }


    $finishtime = [datetime]::Now
    echo "Finished  at " $finishtime

    $finishtime - $starttime | ft

    Stop-Transcript
}
