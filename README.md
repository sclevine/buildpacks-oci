# CF Local - Dockerfile POC

DEPRECATED: Check out [CF Local](https://github.com/sclevine/cflocal).

Put this Dockerfile in any app directory and run `docker build -t myapp .` to build a Docker image of that app.

Run the app using: `docker run -it --rm -p 8080:8080 myapp`

Features:
  - Builds against the latest cflinuxfs2
  - Always uses the latest stable version of the default system buildpacks

Limitations:
  - Java JAR or WAR files must be unzipped and treated as the app directory
  - An application's manifest.yml will not be respected
