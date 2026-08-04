# outputs.tf
output "launch_code_secret_id" {
  description = "WOPR's launch-code secret container. Add a value with: gcloud secrets versions add <this> --data-file=-"
  value       = google_secret_manager_secret.launch_code.secret_id
}

output "launch_code_secret_name" {
  description = "Fully-qualified resource name of the launch-code secret."
  value       = google_secret_manager_secret.launch_code.name
}

output "wopr_service_account" {
  description = "Least-privilege consumer identity (has secretAccessor on the launch-code secret only)."
  value       = google_service_account.wopr.email
}

output "secretmanager_service_agent" {
  description = "The Secret Manager P4SA that uses the CMEK key and publishes rotation events."
  value       = google_project_service_identity.secretmanager.email
}

output "cmek_warplan_secret_id" {
  description = "CMEK deep-dive secret (encrypted with your KMS key, user-managed replication)."
  value       = google_secret_manager_secret.cmek_warplan.secret_id
}

output "kms_key" {
  description = "The KMS key encrypting the war-plan secret. Disable/destroy it to shred the secret."
  value       = google_kms_crypto_key.secret_key.id
}

output "joshua_backdoor_secret_id" {
  description = "Backdoor-password secret with a 30-day rotation notification wired to Pub/Sub."
  value       = google_secret_manager_secret.joshua_backdoor.secret_id
}

output "rotation_topic" {
  description = "Pub/Sub topic that receives rotation notifications."
  value       = google_pubsub_topic.rotation.id
}
