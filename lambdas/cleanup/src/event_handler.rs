use aws_lambda_events::event::eventbridge::EventBridgeEvent;
use docbox_core::{
    aws::aws_config,
    database::{DatabasePoolCache, DatabasePoolCacheConfig},
    purge::{
        purge_expired_presigned_tasks::safe_purge_expired_presigned_tasks,
        purge_expired_tasks::safe_purge_expired_tasks,
        purge_expired_website_metadata::safe_purge_expired_website_metadata,
    },
    secrets::{SecretManager, SecretsManagerConfig},
    storage::{StorageLayerFactory, StorageLayerFactoryConfig},
};
use lambda_runtime::{Error, LambdaEvent};
use std::sync::Arc;
use tokio::sync::OnceCell;

static DEPENDENCIES: OnceCell<Dependencies> = OnceCell::const_new();

pub struct Dependencies {
    pub db: Arc<DatabasePoolCache>,
    pub storage: StorageLayerFactory,
}

async fn dependencies() -> Result<Dependencies, Box<dyn std::error::Error + Send + Sync>> {
    let aws_config = aws_config().await;

    // Create secrets manager
    let secrets_config = SecretsManagerConfig::from_env()?;
    let secrets = SecretManager::from_config(&aws_config, secrets_config);

    // Load database credentials
    let db_pool_config = DatabasePoolCacheConfig::from_env()?;

    // Setup database cache / connector
    let db = Arc::new(DatabasePoolCache::from_config(
        aws_config.clone(),
        db_pool_config,
        secrets.clone(),
    ));

    // Setup storage factory
    let storage_factory_config = StorageLayerFactoryConfig::from_env()?;
    let storage = StorageLayerFactory::from_config(&aws_config, storage_factory_config);

    Ok(Dependencies { db, storage })
}

pub(crate) async fn outer_function_handler(
    event: LambdaEvent<EventBridgeEvent>,
) -> Result<(), Error> {
    let dependencies = DEPENDENCIES.get_or_try_init(dependencies).await?;
    function_handler(event, dependencies).await
}

async fn function_handler(
    _event: LambdaEvent<EventBridgeEvent>,
    dependencies: &Dependencies,
) -> Result<(), Error> {
    safe_purge_expired_presigned_tasks(dependencies.db.clone(), dependencies.storage.clone()).await;
    safe_purge_expired_website_metadata(dependencies.db.clone()).await;
    safe_purge_expired_tasks(dependencies.db.clone()).await;

    Ok(())
}
