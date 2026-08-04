# kms.tf
# ---------------------------------------------------------------------------
# DEEP DIVE: Customer-Managed Encryption Keys (CMEK).
#   The "war plan" secret - so sensitive we keep a finger on the kill switch.
#
# By default Secret Manager encrypts everything at rest with Google-managed
# keys (AES-256) - you do nothing. With CMEK, YOU own the KMS key: you control
# rotation, and you can disable/destroy the key to make the secret
# permanently unreadable (a "cryptographic shred" / kill switch).
#
# CMEK requires USER-MANAGED replication: you pick the region(s), and each
# region's replica is bound to a key in that same region.
# ---------------------------------------------------------------------------

resource "google_kms_key_ring" "secrets" {
  project  = var.project_id
  name     = "${var.name_prefix}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "secret_key" {
  name     = "${var.name_prefix}-key"
  key_ring = google_kms_key_ring.secrets.id
  purpose  = "ENCRYPT_DECRYPT"

  # You control the rotation cadence of the KEY (independent of secret value
  # rotation). 90 days is a common baseline.
  rotation_period = "7776000s" # 90 days

  # Guardrail so a `terraform destroy` in class cannot orphan encrypted data.
  # In production you typically set this true to prevent accidental key loss.
  lifecycle {
    prevent_destroy = false
  }
}

# The Secret Manager service agent must be able to use the key to encrypt and
# decrypt secret material. Granted on the KEY only - least privilege.
resource "google_kms_crypto_key_iam_member" "sm_uses_key" {
  crypto_key_id = google_kms_crypto_key.secret_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.secretmanager.email}"
}

# A CMEK-encrypted secret (the "war plan"), pinned to one region and one key.
resource "google_secret_manager_secret" "cmek_warplan" {
  project   = var.project_id
  secret_id = "${var.name_prefix}-cmek-warplan"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secret_key.id
        }
      }
    }
  }

  # Ensure the service agent can use the key before the secret is created.
  depends_on = [google_kms_crypto_key_iam_member.sm_uses_key]
}
