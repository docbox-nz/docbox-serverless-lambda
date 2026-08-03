#![recursion_limit = "256"]
use docbox_management::{
    config::{ServerConfigData, load_server_config_data_secret},
    core::aws::aws_config,
    interface::ManagedServerInterface,
    server::load_managed_server,
};
use docbox_management_interface::{DocboxManagementCommand, ManagementError};
use lambda_runtime::{Diagnostic, LambdaEvent, service_fn};
use std::sync::OnceLock;
use thiserror::Error;

/// The server version extracted from the Cargo.toml
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

static INTERFACE: OnceLock<ManagedServerInterface> = OnceLock::new();

#[tokio::main]
async fn main() -> Result<(), lambda_runtime::Error> {
    #[cfg(debug_assertions)]
    {
        _ = dotenvy::dotenv();
    }

    lambda_runtime::tracing::init_default_subscriber();

    // Load AWS configuration
    let aws_config = aws_config().await;

    let config_secret_name = std::env::var("DOCBOX_MANAGEMENT_CONFIG_SECRET_NAME")
        .map_err(|_| MissingConfigSecretName)?;

    // Load the config data
    let config: ServerConfigData =
        load_server_config_data_secret(&aws_config, &config_secret_name).await?;

    let server = load_managed_server(&aws_config, &config).await?;

    let interface = ManagedServerInterface { config, server };

    if INTERFACE.set(interface).is_err() {
        panic!("failed to setup global app state")
    }

    lambda_runtime::run(service_fn(function_handler)).await
}

async fn function_handler(
    event: LambdaEvent<DocboxManagementCommand>,
) -> Result<serde_json::Value, Diagnostic> {
    let interface = INTERFACE.get().expect("app state uninitialized");

    let response = event
        .payload
        .execute(interface)
        .await
        .map_err(|error| match error {
            ManagementError::UnsupportedOperation => Diagnostic {
                error_type: "UNSUPPORTED_OPERATION".to_string(),
                error_message: ManagementError::UnsupportedOperation.to_string(),
            },
            ManagementError::SerializeResponse(error) => Diagnostic {
                error_type: "SERIALIZE_RESPONSE".to_string(),
                error_message: error.to_string(),
            },
            ManagementError::Service(error) => Diagnostic {
                error_type: "SERVICE_ERROR".to_string(),
                error_message: error.to_string(),
            },
        })?;

    Ok(response)
}

#[derive(Debug, Error)]
#[error("missing required DOCBOX_MANAGEMENT_CONFIG_SECRET_NAME environment variable")]
struct MissingConfigSecretName;
