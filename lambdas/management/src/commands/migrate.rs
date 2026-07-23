use docbox_management::{
    server::ManagedServer,
    tenant::{
        migrate_tenant_secret_to_iam::migrate_tenant_secret_to_iam,
        migrate_tenants::MigrateTenantsConfig,
        migrate_tenants_search::{MigrateTenantsSearchConfig, migrate_tenants_search},
        migrate_tenants_storage::{MigrateTenantsStorageConfig, migrate_tenants_storage},
    },
};
use serde_json::json;

use crate::{commands::MigrateTenantIamCommand, error::CommandResult};

pub async fn migrate(
    managed_server: &ManagedServer,
    config: MigrateTenantsConfig,
) -> CommandResult {
    let outcome = docbox_management::tenant::migrate_tenants::migrate_tenants(
        &managed_server.db_provider,
        config,
    )
    .await?;

    let payload = serde_json::to_value(outcome)?;
    Ok(payload)
}

pub async fn migrate_root(managed_server: &ManagedServer) -> CommandResult {
    docbox_management::root::migrate_root::migrate_root(&managed_server.db_provider, None).await?;

    Ok(json!({}))
}

pub async fn migrate_search(
    managed_server: &ManagedServer,
    config: MigrateTenantsSearchConfig,
) -> CommandResult {
    let outcome =
        migrate_tenants_search(&managed_server.db_provider, &managed_server.search, config).await?;
    let payload = serde_json::to_value(outcome)?;
    Ok(payload)
}

pub async fn migrate_storage(
    managed_server: &ManagedServer,
    config: MigrateTenantsStorageConfig,
) -> CommandResult {
    let outcome =
        migrate_tenants_storage(&managed_server.db_provider, &managed_server.storage, config)
            .await?;

    let payload = serde_json::to_value(outcome)?;
    Ok(payload)
}

pub async fn migrate_tenant_iam(
    managed_server: &ManagedServer,
    config: MigrateTenantIamCommand,
) -> CommandResult {
    let mut tenants =
        docbox_management::tenant::get_tenants::get_tenants(&managed_server.db_provider).await?;

    tenants.retain(|tenant| {
        tenant.env.eq(&config.env) && config.tenant_id.is_none_or(|id| tenant.id.eq(&id))
    });

    let mut migrated_tenants = Vec::new();

    for mut tenant in tenants {
        if tenant.db_iam_user_name.is_some() {
            tracing::debug!(?tenant, "skipping tenant with iam user name already set");
            continue;
        }

        migrate_tenant_secret_to_iam(
            &managed_server.db_provider,
            &managed_server.secrets,
            &mut tenant,
        )
        .await?;
        migrated_tenants.push(tenant);
    }

    let payload = serde_json::to_value(migrated_tenants)?;
    Ok(payload)
}
