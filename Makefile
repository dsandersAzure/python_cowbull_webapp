ifndef BUILD_NUMBER
  override BUILD_NUMBER := 20.04-22
endif

ifndef COWBULL_PORT
  override COWBULL_PORT := 8000
endif

ifndef COWBULL_SERVER
  override COWBULL_SERVER := localhost
endif

ifndef COWBULL_SERVER_IMAGE
  override COWBULL_SERVER_IMAGE := dsanderscan/cowbull:20.04-28
endif

ifndef COWBULL_SERVER_URL
  override COWBULL_SERVER_URL := http://host.docker.internal
endif

ifndef COWBULL_WEBAPP_PORT
  override COWBULL_WEBAPP_PORT := 8080
endif

ifndef DATE_FORMAT
  override DATE_FORMAT := %Y-%m-%dT%H:%M:%S%Z
endif

ifndef HOMEDIR
  override HOMEDIR := $(shell echo ~)
endif

ifndef HOST_IP
  override HOST_IP := host.docker.internal
#   override HOST_IP := $(shell ipconfig getifaddr $(HOST_IF))
endif

ifndef IMAGE_NAME
  override IMAGE_NAME := cowbull_webapp
endif

ifndef IMAGE_REG
  override IMAGE_REG := dsanderscan
endif

ifndef REDIS_PORT
  override REDIS_PORT := 6379
endif

ifndef VENV
	override VENV := $(HOMEDIR)/virtuals/cowbull_webapp_p3/bin/activate
endif

ifndef WORKDIR
  override WORKDIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
endif

define start_docker
	docker run \
	  --detach \
	  --name redis \
	  -p $(REDIS_PORT):6379 \
	  redis:alpine3.11; \
	docker run \
	  --name cowbull_server \
	  -p $(COWBULL_PORT):8080 \
	  --env PORT=8080 \
	  --env LOGGING_LEVEL=$(1) \
	  --env PERSISTER='{"engine_name": "redis", "parameters": {"host": "$(HOST_IP)", "port": 6379, "db": 0}}' \
	  --detach \
	  $(COWBULL_SERVER_IMAGE)
endef

define stop_docker
	echo; \
	echo "Stopping Docker cowbull container "; \
	docker stop cowbull_server; \
	echo "Removing Docker cowbull container"; \
	docker rm cowbull_server; \
	echo "Stopping Docker Redis container "; \
	docker stop redis; \
	echo "Removing Docker Redis container"; \
	docker rm redis; \
	echo; \
	echo
endef

define end_log
	echo; \
	echo "Started $(1) at  : $(2)"; \
	echo "Finished $(1) at : $(3)"; \
	echo
endef

.PHONY: build debug docker push run shell test

build:
	@start="`date +"$(DATE_FORMAT)"`"; \
	docker build \
	    --build-arg=build_number=$(BUILD_NUMBER) \
		--tag $(IMAGE_REG)/$(IMAGE_NAME):$(BUILD_NUMBER) \
		. ; \
	enddate="`date +$(DATE_FORMAT)`"; \
	$(call end_log,"build",$$start,$$enddate)

debug:
	@start="`date +"$(DATE_FORMAT)"`"; \
	source $(VENV); \
	PYTHONPATH=$(WORKDIR) \
		LOGGING_LEVEL=10 \
		COWBULL_PORT=$(COWBULL_PORT) \
		COWBULL_SERVER=$(COWBULL_SERVER) \
		python app.py; \
	deactivate; \
	enddate="`date +$(DATE_FORMAT)`"; \
	$(call end_log,"debug",$$start,$$enddate)

docker:
	@start="`date +"$(DATE_FORMAT)"`"; \
	source $(VENV); \
	$(call start_docker,10); \
	docker run \
	    -it \
		--rm \
		-p $(COWBULL_WEBAPP_PORT):8080 \
		--env COWBULL_PORT=host.docker.internal \
		--env PORT=8080 \
		--env COWBULL_SERVER=host.docker.internal \
		$(IMAGE_REG)/$(IMAGE_NAME):$(BUILD_NUMBER); \
	$(call stop_docker); \
	enddate="`date +$(DATE_FORMAT)`"; \
	$(call end_log,"build",$$start,$$enddate)

push:
	@start="`date +"$(DATE_FORMAT)"`"; \
	docker push $(IMAGE_REG)/$(IMAGE_NAME):$(BUILD_NUMBER); \
	enddate="`date +$(DATE_FORMAT)`"; \
	$(call end_log,"push",$$start,$$enddate)

run:
	@start="`date +"$(DATE_FORMAT)"`"; \
	source $(VENV); \
	PYTHONPATH=$(WORKDIR) \
		LOGGING_LEVEL=30 \
		COWBULL_PORT=$(COWBULL_PORT) \
		COWBULL_SERVER=$(COWBULL_SERVER) \
		FLASK_PORT=$(COWBULL_WEBAPP_PORT) \
		python app.py; \
	deactivate; \
	enddate="`date +$(DATE_FORMAT)`"; \
	$(call end_log,"run",$$start,$$enddate)

shell:
	@start="`date +"$(DATE_FORMAT)"`"; \
	docker run \
		-it --rm  \
		$(IMAGE_REG)/$(IMAGE_NAME):$(BUILD_NUMBER) /bin/sh; \
	enddate="`date +$(DATE_FORMAT)`"; \
	$(call end_log,"run",$$start,$$enddate)

test:
	@start="`date +"$(DATE_FORMAT)"`"; \
	source $(VENV); \
	PYTHONPATH=$(WORKDIR) \
		LOGGING_LEVEL=30 \
		python tests/main.py; \
	deactivate; \
	enddate="`date +$(DATE_FORMAT)`"; \
	$(call end_log,"tests",$$start,$$enddate)
