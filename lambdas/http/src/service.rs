use axum::{http::Uri, response::IntoResponse};
use futures::future::BoxFuture;
use http_body_util::BodyExt;
use lambda_http::RequestExt;
use tower_service::Service;

/// Service that translates requests and responses
/// between the lambda and axum
pub struct LambdaService<S> {
    pub inner: S,
}

impl<S> Service<lambda_http::Request> for LambdaService<S>
where
    S: Service<axum::http::Request<axum::body::Body>>,
    S::Response: axum::response::IntoResponse + Send + 'static,
    S::Error: std::error::Error + Send + Sync + 'static,
    S::Future: Send + 'static,
{
    type Response = lambda_http::Response<lambda_http::Body>;
    type Error = lambda_http::Error;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn poll_ready(
        &mut self,
        cx: &mut std::task::Context<'_>,
    ) -> std::task::Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx).map_err(Into::into)
    }

    fn call(&mut self, req: lambda_http::Request) -> Self::Future {
        let uri = req.uri().clone();
        let raw_path = req.raw_http_path().to_owned();
        let (mut parts, body) = req.into_parts();

        let body = match body {
            lambda_http::Body::Text(t) => t.into(),
            lambda_http::Body::Binary(v) => v.into(),
            _ => axum::body::Body::default(),
        };

        let mut url = match uri.host() {
            None => raw_path,
            Some(host) => format!(
                "{}://{}{}",
                uri.scheme_str().unwrap_or("https"),
                host,
                raw_path
            ),
        };

        if let Some(query) = uri.query() {
            url.push('?');
            url.push_str(query);
        }

        parts.uri = url.parse::<Uri>().unwrap();

        let request = axum::http::Request::from_parts(parts, body);

        let fut = self.inner.call(request);
        let fut = async move {
            let resp = fut.await?;
            let (parts, body) = resp.into_response().into_parts();
            let bytes = body.into_data_stream().collect().await?.to_bytes();
            let bytes: &[u8] = &bytes;

            let resp: axum::response::Response<lambda_http::Body> = match std::str::from_utf8(bytes)
            {
                Ok(body) => axum::response::Response::from_parts(parts, body.into()),
                Err(_) => axum::response::Response::from_parts(parts, bytes.into()),
            };
            Ok(resp)
        };

        Box::pin(fut)
    }
}
