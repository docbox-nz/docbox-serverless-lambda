use docbox_management::{
    core::storage::StorageLayerError,
    database::DbErr,
    root::{initialize::InitializeError, migrate_root::MigrateRootError},
    tenant::{
        create_tenant::CreateTenantError, delete_tenant::DeleteTenantError,
        flush_tenant_cache::FlushTenantCacheError, migrate_tenant_secret_to_iam::MigrateIAMError,
        migrate_tenants::MigrateTenantsError, migrate_tenants_search::MigrateTenantsSearchError,
        migrate_tenants_storage::MigrateTenantsStorageError,
    },
};
use lambda_runtime::Diagnostic;
use std::{
    error::Error,
    fmt::{Debug, Display},
};
use thiserror::Error;

pub type CommandResult = Result<serde_json::Value, DynCommandError>;

/// Wrapper for dynamic error handling using [HttpError] types
pub struct DynCommandError {
    /// The dynamic error cause
    inner: Box<dyn CommandError>,
}

impl Debug for DynCommandError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_tuple(self.inner.type_name())
            .field(&self.inner)
            .finish()
    }
}

impl Display for DynCommandError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        Display::fmt(&self.inner, f)
    }
}

impl Error for DynCommandError {}

impl From<DynCommandError> for Diagnostic {
    fn from(value: DynCommandError) -> Self {
        Diagnostic {
            error_type: value.inner.code(),
            error_message: value.inner.reason(),
        }
    }
}

/// Trait implemented by errors that can be converted into [HttpError]s
/// and used as error responses
pub trait CommandError: Error + Send + Sync + 'static {
    /// Provides the HTTP [StatusCode] to use when creating this error response
    fn code(&self) -> String {
        "INTERNAL_ERROR".to_string()
    }

    /// Provides the reason message to use in the error response
    fn reason(&self) -> String {
        self.to_string()
    }

    /// Provides the full type name for the actual error type thats been
    /// erased by dynamic typing (For better error source clarity)
    fn type_name(&self) -> &str {
        std::any::type_name::<Self>()
    }
}

/// Allow conversion from implementors of [HttpError] into a [DynHttpError]
impl<E> From<E> for DynCommandError
where
    E: CommandError,
{
    fn from(value: E) -> Self {
        DynCommandError {
            inner: Box::new(value),
        }
    }
}

impl CommandError for serde_json::Error {
    fn code(&self) -> String {
        "SERIALIZE_VALUE".to_string()
    }
}

impl CommandError for MigrateTenantsStorageError {}

impl CommandError for DbErr {}

impl CommandError for DeleteTenantError {}

impl CommandError for FlushTenantCacheError {}

impl CommandError for CreateTenantError {}

impl CommandError for StorageLayerError {}

impl CommandError for InitializeError {}

impl CommandError for MigrateTenantsError {}

impl CommandError for MigrateRootError {}

impl CommandError for MigrateIAMError {}

impl CommandError for MigrateTenantsSearchError {}

#[derive(Debug, Error)]
#[error("tenant not found")]
pub struct TenantNotFoundError;

impl CommandError for TenantNotFoundError {
    fn code(&self) -> String {
        "TENANT_NOT_FOUND".to_string()
    }
}
