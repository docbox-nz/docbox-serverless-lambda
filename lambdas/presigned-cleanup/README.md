# Docbox Presigned Cleanup Lambda

presigned-cleanup is a background task to perform cleanup and deletion of
expired presigned file upload resource

This should be connected like so:

Amazon Event Bridge Trigger ("rate(1 hour)") -> Docbox Presigned Cleanup Lambda

> Adjust schedule to you're desired cleanup rate.

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install)
- [Cargo Lambda](https://www.cargo-lambda.info/guide/installation.html)

## Building

To build the project for production, run `cargo lambda build --release`. Remove the `--release` flag to build for development.

Read more about building your lambda function in [the Cargo Lambda documentation](https://www.cargo-lambda.info/commands/build.html).
