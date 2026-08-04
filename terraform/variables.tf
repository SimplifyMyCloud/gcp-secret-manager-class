# variables.tf
variable "project_id" {
  description = "GCP project to deploy the Secret Manager classroom demo into."
  type        = string
  default     = "simplifymycloud-dev"
}

variable "region" {
  description = "Default region. Used for the CMEK (user-managed replication) deep-dive secret."
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Prefix for every resource this demo creates, so it never collides with existing project resources. Themed after WarGames (1982)."
  type        = string
  default     = "wargames"
}

variable "labels" {
  description = "Labels applied to every secret. Great for cost attribution and for scoping IAM Conditions / org policy."
  type        = map(string)
  default = {
    purpose = "classroom-demo"
    theme   = "wargames"
    env     = "dev"
  }
}

# next_rotation_time must be a future RFC3339 timestamp. Set to a fixed value
# (rather than timestamp()+X) so Terraform does not show a perpetual diff.
variable "first_rotation_time" {
  description = "When Secret Manager should first emit a rotation notification (RFC3339, must be in the future)."
  type        = string
  default     = "2026-09-01T00:00:00Z"
}
