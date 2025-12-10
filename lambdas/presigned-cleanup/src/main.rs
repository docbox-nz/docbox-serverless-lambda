use lambda_runtime::{Error, run, service_fn, tracing};

mod event_handler;

use crate::event_handler::outer_function_handler;

#[tokio::main]
async fn main() -> Result<(), Error> {
    #[cfg(debug_assertions)]
    {
        _ = dotenvy::dotenv();
    }

    tracing::init_default_subscriber();

    run(service_fn(outer_function_handler)).await
}
