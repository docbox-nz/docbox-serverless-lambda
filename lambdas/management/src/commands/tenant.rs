use docbox_management::{
    config::ServerConfigData,
    core::tenant::tenant_options_ext::TenantOptionsExt,
    server::ManagedServer,
    tenant::{
        create_tenant::CreateTenantConfig, delete_tenant::DeleteTenant,
        flush_tenant_cache::flush_tenant_cache,
        get_pending_tenant_migrations::get_pending_tenant_migrations,
        get_pending_tenant_search_migrations::get_pending_tenant_search_migrations,
        get_pending_tenant_storage_migrations::get_pending_tenant_storage_migrations,
    },
};
use serde_json::json;

use crate::{
    commands::{
        DeleteTenantCommand, GetTenantCommand, GetTenantPendingMigrationsCommand,
        SetTenantAllowedCorsOriginsCommand,
    },
    error::{CommandResult, TenantNotFoundError},
};

pub async fn create_tenant(
    managed_server: &ManagedServer,
    tenant_config: CreateTenantConfig,
) -> CommandResult {
    tracing::info!(?tenant_config, "creating tenant");

    let tenant = docbox_management::tenant::create_tenant::create_tenant(
        &managed_server.db_provider,
        &managed_server.search,
        &managed_server.storage,
        &managed_server.secrets,
        tenant_config,
    )
    .await?;

    tracing::info!(?tenant, "tenant created successfully");
    let payload = serde_json::to_value(&tenant)?;
    Ok(payload)
}

pub async fn get_tenant(
    managed_server: &ManagedServer,
    command: GetTenantCommand,
) -> CommandResult {
    let tenant = docbox_management::tenant::get_tenant::get_tenant(
        &managed_server.db_provider,
        &command.env,
        command.tenant_id,
    )
    .await?
    .ok_or(TenantNotFoundError)?;

    let payload = serde_json::to_value(&tenant)?;
    Ok(payload)
}

pub async fn delete_tenant(
    managed_server: &ManagedServer,
    config: &ServerConfigData,
    command: DeleteTenantCommand,
) -> CommandResult {
    let tenant = docbox_management::tenant::get_tenant::get_tenant(
        &managed_server.db_provider,
        &command.env,
        command.tenant_id,
    )
    .await?
    .ok_or(TenantNotFoundError)?;

    // Must close the connections in advance to ensure the tenant
    // database can be deleted
    managed_server.db_cache.close_tenant_pool(&tenant).await;

    // Tell the API server to flush and close its database pools
    flush_tenant_cache(&config.api).await?;

    docbox_management::tenant::delete_tenant::delete_tenant(
        &managed_server.db_provider,
        &managed_server.search,
        &managed_server.storage,
        &managed_server.events,
        &managed_server.secrets,
        DeleteTenant {
            env: command.env,
            tenant_id: command.tenant_id,
            options: command.options,
        },
    )
    .await?;

    Ok(json!({}))
}

pub async fn set_allowed_storage_cors_origins(
    managed_server: &ManagedServer,
    command: SetTenantAllowedCorsOriginsCommand,
) -> CommandResult {
    let tenant = docbox_management::tenant::get_tenant::get_tenant(
        &managed_server.db_provider,
        &command.env,
        command.tenant_id,
    )
    .await?
    .ok_or(TenantNotFoundError)?;

    let storage = managed_server
        .storage
        .create_layer(tenant.storage_layer_options());

    storage.set_bucket_cors_origins(command.origins).await?;

    Ok(json!({}))
}

pub async fn get_tenant_pending_migrations(
    managed_server: &ManagedServer,
    command: GetTenantPendingMigrationsCommand,
) -> CommandResult {
    let tenant = docbox_management::tenant::get_tenant::get_tenant(
        &managed_server.db_provider,
        &command.env,
        command.tenant_id,
    )
    .await?
    .ok_or(TenantNotFoundError)?;

    let pending_migrations =
        get_pending_tenant_migrations(&managed_server.db_provider, &tenant).await?;

    Ok(json!({
        "migrations": pending_migrations
    }))
}

pub async fn get_tenant_pending_search_migrations(
    managed_server: &ManagedServer,
    command: GetTenantPendingMigrationsCommand,
) -> CommandResult {
    let tenant = docbox_management::tenant::get_tenant::get_tenant(
        &managed_server.db_provider,
        &command.env,
        command.tenant_id,
    )
    .await?
    .ok_or(TenantNotFoundError)?;

    let pending_migrations = get_pending_tenant_storage_migrations(
        &managed_server.db_provider,
        &managed_server.storage,
        &tenant,
    )
    .await?;

    Ok(json!({
        "migrations": pending_migrations
    }))
}

pub async fn get_tenant_pending_storage_migrations(
    managed_server: &ManagedServer,
    command: GetTenantPendingMigrationsCommand,
) -> CommandResult {
    let tenant = docbox_management::tenant::get_tenant::get_tenant(
        &managed_server.db_provider,
        &command.env,
        command.tenant_id,
    )
    .await?
    .ok_or(TenantNotFoundError)?;

    let pending_migrations = get_pending_tenant_search_migrations(
        &managed_server.db_provider,
        &managed_server.search,
        &tenant,
    )
    .await?;

    Ok(json!({
        "migrations": pending_migrations
    }))
}
