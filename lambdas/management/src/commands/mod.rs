use docbox_management::{
    config::ServerConfigData,
    database::sqlx::types::Uuid,
    server::ManagedServer,
    tenant::{
        create_tenant::CreateTenantConfig, delete_tenant::DeleteTenantOptions,
        migrate_tenants::MigrateTenantsConfig, migrate_tenants_search::MigrateTenantsSearchConfig,
        migrate_tenants_storage::MigrateTenantsStorageConfig,
    },
};
use lambda_runtime::Diagnostic;
use serde::Deserialize;

mod migrate;
mod root;
mod tenant;
mod tenants;

#[derive(Debug, Deserialize)]
#[serde(tag = "command", content = "payload")]
pub enum Command {
    /// Create and initialize the root database
    CreateRoot,
    /// Check the root database is initialized
    CheckRoot,
    /// Create a new tenant
    CreateTenant(CreateTenantConfig),
    /// Get a specific tenant
    GetTenant(GetTenantCommand),
    /// Delete a tenant
    DeleteTenant(DeleteTenantCommand),
    /// Get a list of tenants
    GetTenants(GetTenantsCommand),
    /// Set the allowed CORS origins for a tenant
    SetTenantAllowedCorsOrigins(SetTenantAllowedCorsOriginsCommand),
    /// Apply database migrations for a collection of tenants
    Migrate(MigrateTenantsConfig),
    /// Apply root migrations
    MigrateRoot,
    /// Apply search migrations for a collection of tenants
    MigrateSearch(MigrateTenantsSearchConfig),
    /// Apply storage migrations for a collection of tenants
    MigrateStorage(MigrateTenantsStorageConfig),
    /// Migrate a tenant from secrets based DB authentication to IAM authentication
    MigrateIAM(MigrateTenantIamCommand),
}

#[derive(Debug, Deserialize)]
pub struct GetTenantCommand {
    pub env: String,
    pub tenant_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct DeleteTenantCommand {
    pub env: String,
    pub tenant_id: Uuid,
    pub options: DeleteTenantOptions,
}

#[derive(Debug, Deserialize)]
pub struct SetTenantAllowedCorsOriginsCommand {
    pub env: String,
    pub tenant_id: Uuid,
    pub origins: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct GetTenantsCommand {
    pub env: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct MigrateTenantIamCommand {
    pub env: String,
    pub tenant_id: Option<Uuid>,
}

pub async fn execute_command(
    managed_server: &ManagedServer,
    config: &ServerConfigData,
    command: Command,
) -> Result<serde_json::Value, Diagnostic> {
    let result = match command {
        Command::CreateRoot => root::create_root(managed_server, config).await,
        Command::CheckRoot => root::check_root(managed_server).await,
        Command::CreateTenant(tenant_config) => {
            tenant::create_tenant(managed_server, tenant_config).await
        }
        Command::GetTenant(command) => tenant::get_tenant(managed_server, command).await,
        Command::DeleteTenant(command) => {
            tenant::delete_tenant(managed_server, config, command).await
        }
        Command::GetTenants(command) => tenants::get_tenants(managed_server, command).await,
        Command::SetTenantAllowedCorsOrigins(command) => {
            tenant::set_allowed_storage_cors_origins(managed_server, command).await
        }
        Command::Migrate(command) => migrate::migrate(managed_server, command).await,
        Command::MigrateRoot => migrate::migrate_root(managed_server).await,
        Command::MigrateSearch(command) => migrate::migrate_search(managed_server, command).await,
        Command::MigrateStorage(command) => migrate::migrate_storage(managed_server, command).await,
        Command::MigrateIAM(command) => migrate::migrate_tenant_iam(managed_server, command).await,
    };

    let payload = result?;
    Ok(payload)
}
