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

# To run the least-privilege demo you IMPERSONATE the WOPR service account,
# which requires roles/iam.serviceAccountTokenCreator ON that SA. Owner does
# NOT grant this. Set this to the presenter's identity to enable the demo.
# e.g. "user:you@example.com". Empty string = skip the binding.
variable "demo_impersonator" {
  description = "Member allowed to impersonate the WOPR SA for the impersonation demo. Empty to skip."
  type        = string
  default     = ""
}
