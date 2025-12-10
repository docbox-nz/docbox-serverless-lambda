use axum::{Extension, Json, http::StatusCode};

use crate::{
    VERSION,
    extensions::max_file_size::MaxFileSizeBytes,
    models::{document_box::DocumentBoxOptions, utils::DocboxServerResponse},
};

pub const UTILS_TAG: &str = "Utils";

/// Server status
///
/// Request basic details about the server
#[utoipa::path(
    get,
    operation_id = "server_details",
    tag = UTILS_TAG,
    path = "/server-details",
    responses(
        (status = 200, description = "Got server details successfully", body = DocboxServerResponse)
    )
)]
pub async fn server_details() -> Json<DocboxServerResponse> {
    Json(DocboxServerResponse { version: VERSION })
}

/// Health check
///
/// Check that the server is running using this endpoint
#[utoipa::path(
    get,
    operation_id = "health",
    tag = UTILS_TAG,
    path = "/health",
    responses(
        (status = 200, description = "Health check success")
    )
)]
pub async fn health() -> StatusCode {
    StatusCode::OK
}

/// Get options
///
/// Requests options and settings from docbox
#[utoipa::path(
    get,
    operation_id = "options",
    tag = UTILS_TAG,
    path = "/options",
    responses(
        (status = 200, description = "Got settings successfully", body = DocumentBoxOptions)
    )
)]
pub async fn get_options(
    Extension(MaxFileSizeBytes(max_file_size)): Extension<MaxFileSizeBytes>,
) -> Json<DocumentBoxOptions> {
    Json(DocumentBoxOptions { max_file_size })
}
