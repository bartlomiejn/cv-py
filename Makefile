ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

PYTHON ?= /usr/local/bin/python3
CMAKE ?= cmake
OCV_VER ?= 4.3.0
JLEVEL ?= 10
DATASETS ?= $(ROOT_DIR)/datasets

SRC_DIR := $(ROOT_DIR)/src
CONFIG_DIR := $(ROOT_DIR)/config
OUTPUT_DIR := $(ROOT_DIR)/output
MPL_DIR := $(OUTPUT_DIR)/matplotlib
KERAS_DIR := $(OUTPUT_DIR)/keras
VENV_DIR := $(OUTPUT_DIR)/venv
OCV_DIR := $(OUTPUT_DIR)/opencv-$(OCV_VER)
OCV_CONTRIB_DIR := $(OUTPUT_DIR)/opencv-contrib-$(OCV_VER)
OCV_CONTRIB_MOD_DIR := $(OCV_CONTRIB_DIR)/opencv-$(OCV_VER)/modules
OCV_OBJ_DIR := $(OUTPUT_DIR)/obj-opencv-$(OCV_VER)

KERAS_CFG := $(KERAS_DIR)/keras.json

SRC_DIR := $(ROOT_DIR)/src
SRC_ML_DIR := $(SRC_DIR)/machine_learning

VENV_ACTIVATE := $(VENV_DIR)/bin/activate
VENV_PYTHON := $(VENV_DIR)/bin/python
VENV_PYTHON_VER = $(shell $(VENV_PYTHON) -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
VENV_PYTHON_ENV = \
	MPLBACKEND=TkAgg \
	MPLCONFIGDIR=$(MPL_DIR) \
	KERAS_HOME=$(KERAS_DIR) \
	PYTHONPATH=$(PYTHONPATH):$(SRC_ML_DIR) \
	DATASETS=$(DATASETS)
VENV_REQUIREMENTS := $(ROOT_DIR)/requirements.txt

OCV_URL := https://github.com/opencv/opencv/archive/$(OCV_VER).tar.gz
OCV_CONTRIB_URL := https://github.com/opencv/opencv_contrib/archive/$(OCV_VER).tar.gz
OCV_ARCHIVE := output/opencv.tar.gz
OCV_CONTRIB_ARCHIVE := output/opencv_contrib.tar.gz
OCV_CMAKE_PARAMS = \
	-DCMAKE_BUILD_TYPE=RELEASE \
	-DCMAKE_INSTALL_PREFIX=$(OCV_OBJ_DIR) \
	-DPYTHON3_LIBRARY=$(shell $(VENV_PYTHON) pythonlib.py) \
	-DPYTHON3_INCLUDE_DIR=$(shell $(VENV_PYTHON) include.py) \
	-DPYTHON3_EXECUTABLE=$(VENV_PYTHON) \
	-DBUILD_opencv_python2=OFF \
	-DBUILD_opencv_python3=ON \
	-DINSTALL_PYTHON_EXAMPLES=ON \
	-DINSTALL_C_EXAMPLES=OFF \
	-DOPENCV_ENABLE_NONFREE=ON \
	-DBUILD_EXAMPLES=ON
OCB_LIB_VER = $(shell $(VENV_PYTHON) -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor}m')")
OCV_LIB = $(OCV_OBJ_DIR)/lib/python$(VENV_PYTHON_VER)/site-packages/cv2/python-$(VENV_PYTHON_VER)/cv2.cpython-$(OCB_LIB_VER)-darwin.so
VENV_OCV_SYMLINK = $(VENV_DIR)/lib/python$(VENV_PYTHON_VER)/site-packages/cv2.so

$(OUTPUT_DIR):
	mkdir -pv $@

$(MPL_DIR): $(OUTPUT_DIR)
	mkdir -pv $@

$(KERAS_DIR): $(OUTPUT_DIR)
	mkdir -pv $@

$(KERAS_CFG): $(KERAS_DIR)
	cp -f $(ROOT_DIR)/keras.json $@

$(OCV_ARCHIVE): $(OUTPUT_DIR)
	test -f $@ || wget -O $@ $(OCV_URL)

$(OCV_CONTRIB_ARCHIVE): $(OUTPUT_DIR)
	test -f $@ || wget -O $@ $(OCV_URL)

$(OCV_DIR): $(OCV_ARCHIVE) $(OCV_CONTRIB_ARCHIVE)
	test -d $@ || ( \
		mkdir -pv $@; \
		mkdir -pv $(OCV_CONTRIB_DIR); \
		tar -xzf $(OCV_ARCHIVE) -C $(OUTPUT_DIR); \
		tar -xzf $(OCV_CONTRIB_ARCHIVE) -C $(OCV_CONTRIB_DIR); \
	)

$(VENV_ACTIVATE): $(OUTPUT_DIR)
	test -d $(VENV_DIR) || ( \
		mkdir -pv $(VENV_DIR); \
		$(PYTHON) -m venv $(VENV_DIR); \
	)
	source $(VENV_ACTIVATE) && pip install -r $(VENV_REQUIREMENTS)
 
venv: $(MPL_DIR) $(KERAS_CFG) $(VENV_ACTIVATE)

opencv: $(OCV_DIR) venv
	mkdir -pv $(OCV_DIR)/build
	mkdir -pv $(OCV_OBJ_DIR)
	source $(VENV_ACTIVATE) \
		&& cd $(OCV_DIR)/build \
		&& $(CMAKE) $(OCV_CMAKE_PARAMS) .. \
		&& $(MAKE) -j$(JLEVEL) \
		&& $(MAKE) install
	$(MAKE) gen-opencv-symlink
	$(VENV_PYTHON) -c "import cv2; print(cv2.__version__)"

gen-opencv-symlink:
	ln -s $(OCV_LIB) $(VENV_OCV_SYMLINK)

setup: venv opencv

run: $(OUTPUT_DIR)
ifeq ($(SRC),)
	$(error Set SRC={source file path} to run a script.)
endif
	source $(VENV_ACTIVATE) && $(VENV_PYTHON_ENV) python $(SRC_DIR)/$(SRC) \
		$(PARAMS)

clean-venv:
	rm -rf $(VENV_DIR)

clean:
	rm -rf $(OUTPUT_DIR)
