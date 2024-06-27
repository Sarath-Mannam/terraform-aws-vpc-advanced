# The reason for storing azs in locals for because user cannot able to override the value, if we store azs in variable then users can
# able to override the value. And locals can store intermediate values, And it can validate expressions and it can run some conditions
# and it can get runtime values
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  # Here 2 is exclusive will fetch values from index 0 and 1. 
}

# output "azs" {
#   value = local.azs
# }