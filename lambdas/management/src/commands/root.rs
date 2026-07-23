use crate::error::CommandResult;
use docbox_management::{config::ServerConfigData, server::ManagedServer};
use serde_json::json;

pub async fn create_root(
    managed_server: &ManagedServer,
    config: &ServerConfigData,
) -> CommandResult {
    if config.database.root_iam {
        docbox_management::root::initialize::initialize_iam(&managed_server.db_provider).await?;
    } else if let Some(root_secret_name) = config.database.root_secret_name.as_ref() {
        docbox_management::root::initialize::initialize(
            &managed_server.db_provider,
            &managed_server.secrets,
            root_secret_name,
        )
        .await?;
    }

    Ok(json!({ "success": true }))
}

pub async fn check_root(managed_server: &ManagedServer) -> CommandResult {
    let is_initialized =
        docbox_management::root::initialize::is_initialized(&managed_server.db_provider).await?;

    Ok(json!({ "is_initialized": is_initialized}))
}
