#Dockerfile vars

#vars
TAG=v3.2.11p2
IMAGENAME=docker-ispconfig
IMAGEFULLNAME=avhost/${IMAGENAME}
BRANCH=${shell git symbolic-ref --short HEAD}
LASTCOMMIT=$(shell git log -1 --pretty=short | tail -n 1 | tr -d " " | tr -d "UPDATE:")
BUILDDATE=$(shell date -u +%Y%m%d)


help:
	    @echo "Makefile arguments:"
	    @echo ""
	    @echo "Makefile commands:"
	    @echo "build"
			@echo "publish-latest"
			@echo "publish-tag"

.DEFAULT_GOAL := all

build:
	@echo ">>>> Build docker image: " ${BRANCH}
	@docker build --build-arg TAG=${TAG} --build-arg BUILDDATE=${BUILDDATE} -t ${IMAGEFULLNAME}:${BRANCH} .

push:
	@echo ">>>> Publish docker image: " ${TAG}_${BRANCH}_${BUILDDATE}
	@docker build --push --no-cache=true --build-arg TAG=${TAG} --build-arg BUILDDATE=${BUILDDATE} -t ${IMAGEFULLNAME}:${TAG}_${BRANCH}_${BUILDDATE} .
	@docker build --push --no-cache=true --build-arg TAG=${TAG} --build-arg BUILDDATE=${BUILDDATE} -t ${IMAGEFULLNAME}:${TAG}_${BRANCH} .
	@docker build --push --no-cache=true --build-arg TAG=${TAG} --build-arg BUILDDATE=${BUILDDATE} -t ${IMAGEFULLNAME}:${BRANCH} .

seccheck:
	grype --add-cpes-if-none dir:.

imagecheck:
	trivy image ${IMAGEFULLNAME}:${BRANCH} 

sboom:
	syft dir:. > sbom.txt
	syft dir:. -o json > sbom.json


all: seccheck sboom build imagecheck
