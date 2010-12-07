#!/usr/bin/env ruby

$file_with_two_entries =<<-EOF
# extended LDIF
#
# LDAPv3
# base <dc=sdk,dc=xx,dc=com> with scope sub # filter: (objectclass=*) # requesting: ALL #

dn: dc=sdk,dc=xx,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: XX
dc: sdk

# urn:uuid:a2a76b44-de30-439c-bb41-adc565b94203, Applications, sdk.xx.com
dn:
uid=urn:uuid:a2a76b44-de30-439c-bb41-adc565b94203,ou=Applications,dc=sdk,d
 c=xx,dc=com
owner: cn=sdkportal@sb-domain.com,ou=People,dc=sdk,dc=xx,dc=com
mail: sdkportal@sb-domain.com
uid: urn:uuid:a2a76b44-de30-439c-bb41-adc565b94203
objectClass: top
objectClass: SdkApplication
objectClass: uidObject
member: cn=SDKExternal,ou=Groups,dc=sdk,dc=xx,dc=com
cn: NathansNewApp18
applicationEnabled: TRUE
disableReason: Application Is Enabled


# urn:uuid:345f3a22-dd69-44b2-99ee-4d694046bf0d, Applications, sdk.xx.com
dn:
uid=urn:uuid:345f3a22-dd69-44b2-99ee-4d694046bf0d,ou=Applications,dc=sdk,dc=xx,dc=com
owner: cn=david_jones@sb-domain.com,ou=People,dc=sdk,dc=xx,dc=com
mail: david_alaniz@saa.senate.gov
uid: urn:uuid:345f3a22-dd69-44b2-99ee-4d694046bf0d
objectClass: top
objectClass: SdkApplication
objectClass: uidObject
member: cn=SDKExternal,ou=Groups,dc=sdk,dc=xx,dc=com
cn: FOOBAR
applicationEnabled: TRUE
disableReason: Application Is Enabled

EOF
