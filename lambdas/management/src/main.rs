#![recursion_limit = "256"]
use docbox_management::{
    config::{ServerConfigData, load_server_config_data_secret},
    core::aws::aws_config,
    server::{ManagedServer, load_managed_server},
};
use lambda_runtime::{Diagnostic, LambdaEvent, service_fn};
use std::sync::OnceLock;
use thiserror::Error;

use crate::commands::{Command, execute_command};

mod commands;
mod error;

/// The server version extracted from the Cargo.toml
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

struct AppState {
    managed_server: ManagedServer,
    config: ServerConfigData,
}

static APP_STATE: OnceLock<AppState> = OnceLock::new();

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

    let managed_server = load_managed_server(&aws_config, &config).await?;

    if APP_STATE
        .set(AppState {
            managed_server,
            config,
        })
        .is_err()
    {
        panic!("failed to setup global app state")
    }

    lambda_runtime::run(service_fn(function_handler)).await
}

async fn function_handler(event: LambdaEvent<Command>) -> Result<serde_json::Value, Diagnostic> {
    let AppState {
        managed_server,
        config,
    } = APP_STATE.get().expect("app state uninitialized");
    let payload = execute_command(managed_server, config, event.payload).await?;

    Ok(payload)
}

#[derive(Debug, Error)]
#[error("missing required DOCBOX_MANAGEMENT_CONFIG_SECRET_NAME environment variable")]
struct MissingConfigSecretName;
