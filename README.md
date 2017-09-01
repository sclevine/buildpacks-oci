# Buildpacks for OCI - Proof of Concept

## Instructions
1. Start any Dockerfile with:
```
FROM sclevine/buildpacks
```

2. Put the Dockerfile in a CF app directory.

3. Build the Docker image: `docker build -t myapp .`

4. Run the app: `docker run -it --rm -p 8080:8080 myapp`

Limitations:
  - Java JAR or WAR files must be unzipped
  - No support for manifest.yml files
