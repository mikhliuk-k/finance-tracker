class Credentials < Google::Auth::Credentials
  self.scope = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]

  self.env_vars = [
    "GOOGLE_CLOUD_CREDENTIALS",
    "GOOGLE_CLOUD_KEYFILE",
    "GCLOUD_KEYFILE",
    "GOOGLE_CLOUD_CREDENTIALS_JSON",
    "GOOGLE_CLOUD_KEYFILE_JSON",
    "GCLOUD_KEYFILE_JSON"
  ]

  self.paths = [
    "~/.config/google_cloud/application_default_credentials.json"
  ]
end
