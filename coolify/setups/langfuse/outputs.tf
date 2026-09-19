output "langfuse_project_uuid" {
  value = coolify_project.langfuse.uuid
}

output "langfuse_service_uuid" {
  value = coolify_service.langfuse.uuid
}

output "initial_admin_password" {
  description = "Retrieve securely once after deployment; also preserved in protected Terraform state."
  value       = random_password.admin.result
  sensitive   = true
}
