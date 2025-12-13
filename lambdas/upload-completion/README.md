# Docbox Upload Completion Lambda

upload-completion is a handler for file upload completions to S3 to handle
finishing presigned file uploads

This should be connected like so:

S3 Object Created Event -> SQS -> Docbox Upload Completion Lambda

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install)
- [Cargo Lambda](https://www.cargo-lambda.info/guide/installation.html)

## Building

To build the project for production, run `cargo lambda build --release`. Remove the `--release` flag to build for development.

Read more about building your lambda function in [the Cargo Lambda documentation](https://www.cargo-lambda.info/commands/build.html).
