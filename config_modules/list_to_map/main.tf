##############################################################################
# Fail States
##############################################################################

locals {
  configuration_failure_conflicting_values_lookup_value_regex_and_value_is_not_null = regex("false", (
    var.value_is_not_null == true && var.lookup_value_regex != null
    ? true
    : false
  ))
}

##############################################################################
