#Dockerfile vars

#vars
TAG=3.2.8p1
IMAGENAME=docker-ispconfig
IMAGEFULLNAME=avhost/${IMAGENAME}
BRANCH=${shell git symbolic-ref --short HEAD}

help:
	    @echo "Makefile arguments:"
	    @echo ""
	    @echo "Makefile commands:"
	    @echo "build"
			@echo "publish-latest"
			@echo "publish-tag"

.DEFAULT_GOAL := all

build:
	@echo ">>>> Build docker image"
	docker build --build-arg TAG=${TAG} --build-arg BUILDDATE=${BUILDDATE} -t ${IMAGEFULLNAME}:${BRANCH} .

publish-latest:
	@echo ">>>> Publish docker image"
	docker tag ${IMAGEFULLNAME}:${BRANCH} ${IMAGEFULLNAME}:latest
	docker push ${IMAGEFULLNAME}:latest

publish-tag:
	@echo ">>>> Publish docker image"
	docker tag ${IMAGEFULLNAME}:${BRANCH} ${IMAGEFULLNAME}:${TAG}
	docker push ${IMAGEFULLNAME}:${TAG}

seccheck:
	grype --add-cpes-if-none dir:.

sboom:
	syft dir:. > sbom.txt
	syft dir:. -o json > sbom.json


all: seccheck sboom build publish-latest publish-tag
