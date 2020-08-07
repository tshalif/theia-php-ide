TAG = tshalif/php-theia:latest

BASE_IMAGE = theiaide/theia-full:1.4.0

BUILD_CONTAINER = $(shell cat .build-image.container)

all: .build-image

.build-image: .build-image.container
	echo buildah container: $(BUILD_CONTAINER)
	buildah add $(BUILD_CONTAINER) theia-build.sh theia-run.sh .
	buildah run $(BUILD_CONTAINER) -- sudo ./theia-build.sh
	buildah config --port 5000 --entrypoint /home/theia/theia-run.sh $(BUILD_CONTAINER)
	buildah commit --rm $(BUILD_CONTAINER) $(TAG)
	buildah push $(TAG) docker-daemon:$(TAG)

.build-image.container:
	buildah from $(BASE_IMAGE) > $@

clean:
	rm -rf node_modules lib plugins src-gen webpack.config.js gen-webpack.config.js .build-image.container
