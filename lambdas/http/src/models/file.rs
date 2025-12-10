use crate::error::HttpError;
use axum::http::StatusCode;
use chrono::{DateTime, Utc};
use docbox_database::models::{
    file::{FileId, FileWithExtra},
    folder::FolderId,
    generated_file::GeneratedFile,
    presigned_upload_task::PresignedUploadTaskId,
};
use docbox_processing::ProcessingConfig;
use garde::Validate;
use mime::Mime;
use serde::{Deserialize, Serialize};
use serde_with::serde_as;
use std::collections::HashMap;
use thiserror::Error;
use utoipa::ToSchema;

/// Request to create a new presigned file upload
#[serde_as]
#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreatePresignedRequest {
    /// Name of the file being uploaded
    #[garde(length(min = 1, max = 255))]
    #[schema(min_length = 1, max_length = 255)]
    pub name: String,

    /// Folder to store the file in
    #[garde(skip)]
    #[schema(value_type = Uuid)]
    pub folder_id: FolderId,

    /// Size of the file being uploaded
    #[garde(range(min = 1))]
    #[schema(minimum = 1)]
    pub size: i32,

    /// Mime type of the file
    #[garde(skip)]
    #[serde_as(as = "serde_with::DisplayFromStr")]
    #[schema(value_type = String)]
    pub mime: Mime,

    /// Optional parent file ID
    #[garde(skip)]
    #[schema(value_type = Option<Uuid>)]
    pub parent_id: Option<FileId>,

    /// Optional processing config
    #[garde(skip)]
    pub processing_config: Option<ProcessingConfig>,

    /// Whether to disable mime sniffing for the file. When false/not specified
    /// if a application/octet-stream mime type is provided the file name
    /// will be used to attempt to determine the real mime type
    #[garde(skip)]
    pub disable_mime_sniffing: Option<bool>,
}

#[derive(Serialize, ToSchema)]
pub struct PresignedUploadResponse {
    #[schema(value_type = Uuid)]
    pub task_id: PresignedUploadTaskId,
    pub method: String,
    pub uri: String,
    pub headers: HashMap<String, String>,
}

#[derive(Serialize, ToSchema)]
#[serde(tag = "status")]
#[allow(clippy::large_enum_variant)]
pub enum PresignedStatusResponse {
    Pending,
    Complete {
        file: FileWithExtra,
        generated: Vec<GeneratedFile>,
    },
    Failed {
        error: String,
    },
}

/// Request to rename and or move a file
#[derive(Debug, Validate, Deserialize, ToSchema)]
pub struct UpdateFileRequest {
    /// Name for the folder
    #[garde(inner(length(min = 1, max = 255)))]
    #[schema(min_length = 1, max_length = 255)]
    pub name: Option<String>,

    /// New parent folder for the folder
    #[garde(skip)]
    #[schema(value_type = Option<Uuid>)]
    pub folder_id: Option<FolderId>,

    /// Whether to pin the file
    #[garde(skip)]
    #[schema(value_type = Option<bool>)]
    pub pinned: Option<bool>,
}

/// Response for requesting a document box
#[derive(Debug, Serialize, ToSchema)]
pub struct FileResponse {
    /// The file itself
    pub file: FileWithExtra,
    /// Files generated from the file (thumbnails, pdf, etc)
    pub generated: Vec<GeneratedFile>,
}

#[derive(Default, Debug, Deserialize)]
#[serde(default)]
pub struct RawFileQuery {
    pub download: bool,
}

/// Request to rename and or move a file
#[derive(Debug, Validate, Deserialize, ToSchema)]
pub struct GetPresignedRequest {
    /// Expiry time in seconds for the presigned URL
    #[garde(skip)]
    #[schema(default = 900)]
    pub expires_at: Option<i64>,
}

#[derive(Serialize, ToSchema)]
pub struct PresignedDownloadResponse {
    pub method: String,
    pub uri: String,
    pub headers: HashMap<String, String>,
    pub expires_at: DateTime<Utc>,
}

#[derive(Debug, Error)]
pub enum HttpFileError {
    #[error("unknown file")]
    UnknownFile,

    #[error("unknown task")]
    UnknownTask,

    #[error("file size is larger than the maximum allowed size (requested: {0}, maximum: {1})")]
    FileTooLarge(i32, i32),
    #[error("no matching generated file")]
    NoMatchingGenerated,

    #[allow(unused)]
    #[error("unsupported file type")]
    UnsupportedFileType,
}

impl HttpError for HttpFileError {
    fn status(&self) -> axum::http::StatusCode {
        match self {
            HttpFileError::FileTooLarge(_, _) => StatusCode::BAD_REQUEST,
            HttpFileError::UnknownFile
            | HttpFileError::NoMatchingGenerated
            | HttpFileError::UnknownTask => StatusCode::NOT_FOUND,
            HttpFileError::UnsupportedFileType => StatusCode::BAD_REQUEST,
        }
    }
}
