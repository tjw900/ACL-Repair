Notes for AC-Hell

Working Functionality:
* Removes legacy groups from ACL when copied, such as UNCLE\arcs_ad_admin and admin_tier1nas
* Removes explicit user entries if the group also appears as an entry and the user is a member
* Removes full control from all groups except UNCLE\Win_Sys_Admins
* Generates fresh ACL's with all required entries to avoid anything Oracle flavoured
* Applies fresh ACL's only where meaningful differences occur in the source
* Fresh ACL permissions automatically propagate to all folders and files underneath

Non-Working Functionality:
* Support for importing sources, destinations and top level groups
* Differentiating between explicit allows and denials, currently converts everything to allow
* Differentiating between read-only groups and modify groups, current converts everything to modify
* Does not touch owners, owner fix will still be able to repair them as before
