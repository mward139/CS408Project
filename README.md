# Full Stack Web Application Starter

This is a starter template for a full stack web application built with Node.js,
Express, and SQLite. It is fully containerized using Docker, making it easy to
deploy to various environments, including AWS EC2 instances.

## Quick Start

- Install [Docker](https://docs.docker.com/get-docker/) on your local machine.
  - Make sure and select WSL 2 backend if using Windows.
- Configure the project with `./dev.sh new`
- Start the application with `./dev.sh`

Optional validation commands:

- Validate Docker Hub auth: `./dev.sh docker`
- Validate EC2 SSH + env: `./dev.sh ec2`
- Run both checks: `./dev.sh login`

## Documentation

Project documentation is available in the [`docs`](docs) directory, covering
development, deployment, and configuration topics in detail.
