use crate::{commands::GetTenantsCommand, error::CommandResult};
use docbox_management::server::ManagedServer;

pub async fn get_tenants(
    managed_server: &ManagedServer,
    command: GetTenantsCommand,
) -> CommandResult {
    let mut tenants =
        docbox_management::tenant::get_tenants::get_tenants(&managed_server.db_provider).await?;

    if let Some(env) = command.env {
        tenants.retain(|tenant| tenant.env.eq(&env));
    }

    let payload = serde_json::to_value(tenants)?;
    Ok(payload)
}
