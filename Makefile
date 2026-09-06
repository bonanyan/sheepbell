APP        := HerdrBell
SCHEME     := HerdrBell
CONFIG     ?= Release
BUILD_DIR  := build
DERIVED    := $(BUILD_DIR)/DerivedData
BUILT_APP  := $(DERIVED)/Build/Products/$(CONFIG)/$(APP).app

MASTER  := Sources/Resources/Artwork/app-icon-master.png
ICONSET := Sources/Resources/Assets.xcassets/AppIcon.appiconset

SOURCES := $(shell find Sources Tests project.yml -type f 2>/dev/null)

.DEFAULT_GOAL := all

.PHONY: all package test install clean icons

all: $(BUILD_DIR)/$(APP).app

icons: $(ICONSET)/icon_1024.png

$(ICONSET)/icon_1024.png: $(MASTER) Scripts/MakeIcon.swift
	swift Scripts/MakeIcon.swift --master $(MASTER)

$(BUILD_DIR)/$(APP).app: $(SOURCES) $(ICONSET)/icon_1024.png
	xcodegen generate
	xcodebuild -project $(APP).xcodeproj -scheme $(SCHEME) -configuration $(CONFIG) \
		-derivedDataPath $(DERIVED) build
	rm -rf $@
	cp -R $(BUILT_APP) $@
	codesign --force --deep --sign - $@

package: all
	cd $(BUILD_DIR) && rm -f $(APP).zip && zip -qry $(APP).zip $(APP).app

test:
	xcodegen generate
	xcodebuild -project $(APP).xcodeproj -scheme $(SCHEME) \
		-derivedDataPath $(DERIVED) test

install: all
	./Scripts/install.sh

clean:
	rm -rf $(BUILD_DIR)
