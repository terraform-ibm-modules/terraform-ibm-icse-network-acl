##############################################################################
# ACL Outputs
##############################################################################

output "acls" {
  description = "List of Network ACL names and ids"
  value = [
    for network_acl in ibm_is_network_acl.acl :
    {
      id            = network_acl.id
      name          = network_acl.name
      first_rule_id = length(network_acl.rules) > 0 ? network_acl.rules[0].id : null
    }
  ]
}


##############################################################################
