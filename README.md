# s6-overlay-rootfs

The base build to get [s6-overlay](https://github.com/just-containers/s6-overlay) rootfs in your base image.
[What's that?](https://skarnet.org/software/s6/overview.html)

# Build

Login to AWS ECR

`aws ecr get-login-password --region us-east-1 --profile voma | docker login --username AWS --password-stdin 385480189778.dkr.ecr.us-east-1.amazonaws.com`

Build the image (multi-arch)

`docker buildx build --platform linux/amd64,linux/arm64 -t 385480189778.dkr.ecr.us-east-1.amazonaws.com/voma-s6-overlay-rootfs:latest --push .`

# Usage

`COPY --from=385480189778.dkr.ecr.us-east-1.amazonaws.com/voma-s6-overlay-rootfs:latest ["/", "/"]`