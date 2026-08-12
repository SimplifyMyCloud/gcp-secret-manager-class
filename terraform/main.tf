# main.tf
# ---------------------------------------------------------------------------
# WarGames (1982) themed core demo.
#   "Shall we play a game?"
#
# A secret CONTAINER (no value) for WOPR's nuclear launch code, a
# least-privilege consumer identity (WOPR itself), and an IAM binding scoped
# to the single secret.
# ---------------------------------------------------------------------------

# Look up the project so we can build the Secret Manager service-agent email.
data "google_project" "this" {
  project_id = var.project_id
}

# The Secret Manager "P4SA" (per-product service agent). Terraform can force it
# to exist; it is the identity Secret Manager uses to call KMS (CMEK) and to
# publish rotation notifications to Pub/Sub.
resource "google_project_service_identity" "secretmanager" {
  provider = google-beta
  project  = var.project_id
  service  = "secretmanager.googleapis.com"
}

# The service agent is created asynchronously; IAM bindings that reference it
# can fail with "service account does not exist" if applied too soon. Wait for
# it to propagate before granting it rights (on KMS and Pub/Sub).
resource "time_sleep" "wait_for_service_agent" {
  depends_on      = [google_project_service_identity.secretmanager]
  create_duration = "30s"
}

# ---------------------------------------------------------------------------
# 1. The main secret: WOPR's launch code (movie value: CPE1704TKS).
#    NOTE: we create the container only. We deliberately DO NOT create a
#    google_secret_manager_secret_version here, because the plaintext value
#    would be stored in Terraform state. The value is added out-of-band with
#    `gcloud secrets versions add` (see demos/01-basics.sh).
# ---------------------------------------------------------------------------
resource "google_secret_manager_secret" "launch_code" {
  project   = var.project_id
  secret_id = "${var.name_prefix}-launch-code"
  labels    = var.labels

  # Automatic replication: Google stores the secret redundantly across regions
  # and manages the encryption key. Simplest and the default recommendation.
  replication {
    auto {}
  }
}

# ---------------------------------------------------------------------------
# 2. A least-privilege consumer identity: WOPR, the war-planning computer.
#    In real life this is the service account your app / Cloud Run / GKE
#    workload runs as. It gets secretAccessor on ONE secret, not the project.
# ---------------------------------------------------------------------------
resource "google_service_account" "wopr" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-wopr"
  display_name = "WOPR - demo launch-code consumer"
}

# secretAccessor is granted at the SECRET level (resource-scoped), so WOPR
# can read this one secret and nothing else in the project.
resource "google_secret_manager_secret_iam_member" "wopr_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.launch_code.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.wopr.email}"
}

# Let the presenter impersonate WOPR for the least-privilege demo. Impersonation
# requires serviceAccountTokenCreator ON the target SA - a distinct, sensitive
# permission that Owner does NOT include. Only created if var.demo_impersonator
# is set.
resource "google_service_account_iam_member" "impersonator" {
  count              = var.demo_impersonator == "" ? 0 : 1
  service_account_id = google_service_account.wopr.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.demo_impersonator
}
