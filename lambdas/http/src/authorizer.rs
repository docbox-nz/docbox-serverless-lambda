use axum::{
    Extension,
    extract::Request,
    http::{HeaderName, HeaderValue, StatusCode},
    middleware::Next,
    response::Response,
};
use docbox_http::{
    error::{DynHttpError, HttpError},
    middleware::{
        action_user::{USER_ID_HEADER, USER_IMAGE_ID_HEADER, USER_NAME_HEADER},
        tenant::{TENANT_ENV_HEADER, TENANT_ID_HEADER},
    },
};
use serde::Deserialize;
use thiserror::Error;

#[derive(Deserialize)]
struct AuthorizerTenant {
    id: String,
    env: String,
}

#[derive(Deserialize)]
struct AuthorizerUser {
    id: Option<String>,
    name: Option<String>,
    image_id: Option<String>,
}

const TENANT_ID_HEADER_NAME: HeaderName = HeaderName::from_static(TENANT_ID_HEADER);
const TENANT_ENV_HEADER_NAME: HeaderName = HeaderName::from_static(TENANT_ENV_HEADER);

const USER_ID_HEADER_NAME: HeaderName = HeaderName::from_static(USER_ID_HEADER);
const USER_NAME_HEADER_NAME: HeaderName = HeaderName::from_static(USER_NAME_HEADER);
const USER_IMAGE_ID_HEADER_NAME: HeaderName = HeaderName::from_static(USER_IMAGE_ID_HEADER);

#[derive(Debug, Error)]
#[error("provided tenant from authorizer is invalid: {0}")]
struct InvalidAuthorizerTenant(serde_json::Error);

impl HttpError for InvalidAuthorizerTenant {
    fn status(&self) -> axum::http::StatusCode {
        StatusCode::BAD_REQUEST
    }
}

#[derive(Debug, Error)]
#[error("provided user from authorizer is invalid: {0}")]
struct InvalidAuthorizerUser(serde_json::Error);

impl HttpError for InvalidAuthorizerUser {
    fn status(&self) -> axum::http::StatusCode {
        StatusCode::BAD_REQUEST
    }
}

#[derive(Debug, Error)]
#[error("attempted to access lambda without authorizer")]
struct MissingAuthorizer;

impl HttpError for MissingAuthorizer {
    fn status(&self) -> axum::http::StatusCode {
        StatusCode::BAD_REQUEST
    }
}

/// Middleware that takes information from the authorizer lambda and passes it along
/// as the expected headers
pub async fn authorizer_middleware(
    Extension(context): Extension<lambda_http::request::RequestContext>,
    mut request: Request,
    next: Next,
) -> Result<Response, DynHttpError> {
    let authorizer = context.authorizer().ok_or(MissingAuthorizer)?;
    let headers = request.headers_mut();

    // Remove user-provided headers from the request, we only trust the authorizer
    headers.remove(TENANT_ID_HEADER_NAME);
    headers.remove(TENANT_ENV_HEADER_NAME);

    headers.remove(USER_ID_HEADER_NAME);
    headers.remove(USER_NAME_HEADER_NAME);
    headers.remove(USER_IMAGE_ID_HEADER_NAME);

    if let Some(tenant) = authorizer
        .fields
        .get("tenant")
        .map(|value| serde_json::from_str::<AuthorizerTenant>(value.as_str().unwrap()))
        .transpose()
        .map_err(InvalidAuthorizerTenant)?
    {
        let id_value = HeaderValue::from_str(&tenant.id)?;
        let env_value = HeaderValue::from_str(&tenant.env)?;

        headers.insert(TENANT_ID_HEADER_NAME, id_value);
        headers.insert(TENANT_ENV_HEADER_NAME, env_value);
    }

    if let Some(user) = authorizer
        .fields
        .get("user")
        .map(|value| serde_json::from_str::<AuthorizerUser>(value.as_str().unwrap()))
        .transpose()
        .map_err(InvalidAuthorizerUser)?
    {
        if let Some(id) = user.id {
            let value = HeaderValue::from_str(&id)?;
            headers.insert(USER_ID_HEADER_NAME, value);
        }

        if let Some(name) = user.name {
            let value = HeaderValue::from_str(&name)?;
            headers.insert(USER_NAME_HEADER_NAME, value);
        }

        if let Some(image_id) = user.image_id {
            let value = HeaderValue::from_str(&image_id)?;
            headers.insert(USER_IMAGE_ID_HEADER_NAME, value);
        }
    }

    // Continue the request normally
    Ok(next.run(request).await)
}
