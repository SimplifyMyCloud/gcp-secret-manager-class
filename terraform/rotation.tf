# rotation.tf
# ---------------------------------------------------------------------------
# DEEP DIVE: Rotation notifications.
#   "Joshua" was Professor Falken's backdoor password into WOPR. If a backdoor
#   password must exist, rotate it on a schedule so a war-dialing teenager
#   can't reuse it forever.
#
# Secret Manager does NOT rotate secret values for you (it is not a database
# credential broker). What it DOES do is emit a Pub/Sub message on a schedule
# so YOUR automation (a Cloud Function, Cloud Run job, etc.) can generate a new
# value and add a new version. This models the "who actually rotates it" reality.
# ---------------------------------------------------------------------------

resource "google_pubsub_topic" "rotation" {
  project = var.project_id
  name    = "${var.name_prefix}-rotation-events"
  labels  = var.labels
}

# The Secret Manager service agent must be allowed to publish to the topic.
# This binding MUST exist before a secret references the topic, or creation fails.
resource "google_pubsub_topic_iam_member" "sm_publishes" {
  project = var.project_id
  topic   = google_pubsub_topic.rotation.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_project_service_identity.secretmanager.email}"
}

# The "Joshua" backdoor password, configured to fire a rotation reminder
# every 30 days.
resource "google_secret_manager_secret" "joshua_backdoor" {
  project   = var.project_id
  secret_id = "${var.name_prefix}-joshua-backdoor"
  labels    = var.labels

  replication {
    auto {}
  }

  # Where rotation notifications (and other event messages) are delivered.
  topics {
    name = google_pubsub_topic.rotation.id
  }

  rotation {
    next_rotation_time = var.first_rotation_time
    rotation_period    = "2592000s" # 30 days
  }

  depends_on = [google_pubsub_topic_iam_member.sm_publishes]
}
