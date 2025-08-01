config {
  # Disable the terraform version check
  disabled_by_default = false
}

rule "terraform_required_version" {
  enabled = false
}
