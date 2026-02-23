# Full-Stack Web Application

This repository contains a full-stack web application built with Node.js,
Express, and SQLite. It includes scripts and documentation for setting up,
configuring, and deploying the application on an AWS EC2 instance. The application
uses Docker for containerization and simplified deployment.

- [Development Guide (Docker)](dev-node/README.md)
- [Deployment Guide (Docker)](deploy-docker/README.md)

>[!TIP]
>Docker is the recommended approach for development and deployment as it abstracts away many of the complexities of server configuration and application setup. It allows you to run the application in a consistent environment across different machines and simplifies the deployment process. You are not required to use Docker for this course, but it is highly recommended for a smoother experience. If you choose to deploy manually without Docker, you will need to follow the manual deployment instructions provided in the documentation.

## Technology Stack

- Backend technology stack
    - Web Server: [nginx](https://www.nginx.com/) as a reverse proxy server for future deployment
    - Backend Runtime: [Node.js](https://nodejs.org/)
    - Backend Framework: [Express](https://expressjs.com/)
    - Database: [SQLite](https://sqlite.org/) for data storage
- Frontend technology stack
    - Templates: [EJS](https://ejs.co/) for server-side rendering
    - UX/UI: [Bootstrap](https://getbootstrap.com/) for responsive design (planned)
    - Client-Side Interactivity: [JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript) (planned)
- Testing Frameworks
    - End-to-End Testing: [Playwright](https://playwright.dev/)
- Tools:
    - Container: [Docker](https://www.docker.com/)
    - CI/CD: [GitHub Actions](https://github.com/features/actions)
 
## Team Workflow

- Solo developer
