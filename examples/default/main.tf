##############################################################################
# Network ACL
##############################################################################

module "acl_map" {
  source = "./config_modules/list_to_map"
  list   = var.network_acls
}

resource "ibm_is_network_acl" "acl" {
  for_each       = module.acl_map.value
  vpc            = var.vpc_id
  name           = "${var.prefix}-${each.value.name}"
  resource_group = lookup(each.value, "resource_group_id", null)
  tags = concat(
    var.tags == null ? [] : var.tags,
    lookup(each.value, "tags", null) == null ? [] : each.value.tags
  )

  dynamic "rules" {
    # Add cluster rules individually to prevent inconsistant typing errors
    for_each = concat([for rule in local.cluster_rules : rule if each.value.add_cluster_rules == true], each.value.rules)
    content {
      name        = rules.value.name
      action      = rules.value.action
      source      = rules.value.source
      destination = rules.value.destination
      direction   = rules.value.direction

      dynamic "tcp" {
        for_each = (
          # if rules null
          rules.value.tcp == null
          # empty array
          ? []
          # otherwise check each possible field against how many of the values are
          # equal to null and only include rules where one of the values is not null
          # this allows for patterns to include `tcp` blocks for conversion to list
          # while still not creating a rule. default behavior would force the rule to
          # be included if all indiviual values are set to null
          : length([
            for value in ["port_min", "port_max", "source_port_min", "source_port_min"] :
            true if lookup(rules.value["tcp"], value, null) == null
          ]) == 4
          ? []
          : [rules.value]
        )
        content {
          port_min        = lookup(rules.value.tcp, "port_min", null)
          port_max        = lookup(rules.value.tcp, "port_max", null)
          source_port_min = lookup(rules.value.tcp, "source_port_min", null)
          source_port_max = lookup(rules.value.tcp, "source_port_min", null)
        }
      }

      dynamic "udp" {
        for_each = (
          # if rules null
          rules.value.udp == null
          # empty array
          ? []
          # otherwise check each possible field against how many of the values are
          # equal to null and only include rules where one of the values is not null
          # this allows for patterns to include `udp` blocks for conversion to list
          # while still not creating a rule. default behavior would force the rule to
          # be included if all indiviual values are set to null
          : length([
            for value in ["port_min", "port_max", "source_port_min", "source_port_min"] :
            true if lookup(rules.value["udp"], value, null) == null
          ]) == 4
          ? []
          : [rules.value]
        )
        content {
          port_min        = lookup(rules.value.udp, "port_min", null)
          port_max        = lookup(rules.value.udp, "port_max", null)
          source_port_min = lookup(rules.value.udp, "source_port_min", null)
          source_port_max = lookup(rules.value.udp, "source_port_min", null)
        }
      }

      dynamic "icmp" {
        for_each = (
          # if rules null
          rules.value.icmp == null
          # empty array
          ? []
          # otherwise check each possible field against how many of the values are
          # equal to null and only include rules where one of the values is not null
          # this allows for patterns to include `udp` blocks for conversion to list
          # while still not creating a rule. default behavior would force the rule to
          # be included if all indiviual values are set to null
          : length([
            for value in ["code", "type"] :
            true if lookup(rules.value["icmp"], value, null) == null
          ]) == 2
          ? []
          : [rules.value]
        )
        content {
          type = rules.value.icmp.type
          code = rules.value.icmp.code
        }
      }
    }

  }
}

##############################################################################
