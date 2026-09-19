variable "coolify_endpoint" {
  description = "Existing self-hosted Coolify URL, independently reachable if the tunnel fails."
  type        = string
  validation {
    condition     = can(regex("^https?://", var.coolify_endpoint))
    error_message = "Provide an HTTP or HTTPS Coolify base URL."
  }
}

variable "coolify_server_uuid" {
  description = "UUID of the existing Coolify deployment server."
  type        = string
}

variable "langfuse_url" {
  description = "Public HTTPS URL for Langfuse, without a trailing slash."
  type        = string
  validation {
    condition     = can(regex("^https://[^/]+$", var.langfuse_url))
    error_message = "Use a public HTTPS URL without a path or trailing slash."
  }
}

variable "media_url" {
  description = "Public HTTPS URL for presigned MinIO media uploads, without a trailing slash."
  type        = string
  validation {
    condition     = can(regex("^https://[^/]+$", var.media_url))
    error_message = "Use a public HTTPS URL without a path or trailing slash."
  }
}

variable "initial_user_email" {
  description = "Email address for the initial Langfuse administrator."
  type        = string
  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+$", var.initial_user_email))
    error_message = "Provide a valid initial administrator email address."
  }
}

variable "project_name" {
  description = "Name of the dedicated Coolify project."
  type        = string
  default     = "langfuse"
}

variable "langfuse_image" {
  description = "Versioned Langfuse web image; update together with worker_image after reviewing release notes."
  type        = string
  default     = "docker.langfuse.com/langfuse/langfuse:4"
}

variable "worker_image" {
  description = "Langfuse worker image matching langfuse_image."
  type        = string
  default     = "docker.langfuse.com/langfuse/langfuse-worker:4"
}
