##############################################################################
# Network ACLs
##############################################################################

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where address prefixes will be created"
  type        = string
  default     = null
}

variable "tags" {
  description = "List of Tags for each resource"
  type        = list(string)
  default     = []
}

variable "network_cidr" {
  description = "OPTIONAL - Network CIDR for add cluster rules. If null, will default to 0.0.0.0/0"
  type        = string
  default     = null
}

variable "network_acls" {
  description = "List of ACLs to create. Rules can be automatically created to allow inbound and outbound traffic from a VPC tier by adding the name of that tier to the `network_connections` list. Rules automatically generated by these network connections will be added at the beginning of a list, and will be web-tierlied to traffic first. At least one rule must be provided for each ACL."
  type = list(
    object({
      name              = string
      add_cluster_rules = optional(bool)
      resource_group_id = optional(string)
      tags              = optional(list(string))
      rules = list(
        object({
          name        = string
          action      = string
          destination = string
          direction   = string
          source      = string
          tcp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          udp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          icmp = optional(
            object({
              type = optional(number)
              code = optional(number)
            })
          )
        })
      )
    })
  )

  default = []

  validation {
    error_message = "ACL rules can only have one of `icmp`, `udp`, or `tcp`."
    condition = length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in flatten([
          for acl in var.network_acls :
          [
            for rule in acl.rules :
            rule
          ]
        ]) :
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for type in ["tcp", "udp", "icmp"] :
            true if rule[type] != null
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }

  validation {
    error_message = "ACL rule actions can only be `allow` or `deny`."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([
          for acl in var.network_acls :
          [
            for rule in acl.rules :
            rule
          ]
        ]) :
        # Return false action is not valid
        false if !contains(["allow", "deny"], rule.action)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule direction can only be `inbound` or `outbound`."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([
          for acl in var.network_acls :
          [
            for rule in acl.rules :
            rule
          ]
        ]) :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([
          for acl in var.network_acls :
          [
            for rule in acl.rules :
            rule
          ]
        ]) :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

}

##############################################################################
