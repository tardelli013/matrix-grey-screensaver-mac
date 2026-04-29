NAME        := MatrixGrey
BUNDLE      := $(NAME).saver
BUILD       := build
BUNDLE_PATH := $(BUILD)/$(BUNDLE)
SOURCES     := $(wildcard Sources/*.swift)
DEST        := $(HOME)/Library/Screen Savers
TARGET      := arm64-apple-macos13.0

CONFIG_NAME    := MatrixGreyConfig
CONFIG_BIN     := $(BUILD)/$(CONFIG_NAME)
CONFIG_APP     := $(BUILD)/$(CONFIG_NAME).app
CONFIG_SOURCES := Sources/Settings.swift Sources/ConfigureWindowController.swift Configurator/main.swift
APPS_DIR       := $(HOME)/Applications

.PHONY: all build install reinstall configure app install-app uninstall purge clean preview

all: build

build: $(BUNDLE_PATH)

$(BUNDLE_PATH): $(SOURCES) Resources/Info.plist
	@rm -rf "$(BUNDLE_PATH)"
	@mkdir -p "$(BUNDLE_PATH)/Contents/MacOS"
	@mkdir -p "$(BUNDLE_PATH)/Contents/Resources"
	cp Resources/Info.plist "$(BUNDLE_PATH)/Contents/Info.plist"
	swiftc \
		-target $(TARGET) \
		-module-name $(NAME) \
		-emit-library \
		-Xlinker -bundle \
		-framework ScreenSaver \
		-framework AppKit \
		-framework Foundation \
		-O \
		-o "$(BUNDLE_PATH)/Contents/MacOS/$(NAME)" \
		$(SOURCES)
	codesign --force --sign - "$(BUNDLE_PATH)"
	@echo "Built $(BUNDLE_PATH)"

install: build
	@mkdir -p "$(DEST)"
	@rm -rf "$(DEST)/$(BUNDLE)"
	cp -R "$(BUNDLE_PATH)" "$(DEST)/"
	@killall legacyScreenSaver 2>/dev/null || true
	@killall legacyScreenSaverAgent 2>/dev/null || true
	@killall ScreenSaverEngine 2>/dev/null || true
	@killall WallpaperAgent 2>/dev/null || true
	@echo ""
	@echo "Installed to $(DEST)/$(BUNDLE)"
	@echo "Killed screensaver and wallpaper agents so the next preview reloads fresh."
	@echo "If you have System Settings open, quit it (Cmd+Q) and reopen — it caches"
	@echo "the .saver bundle inside its own process."

reinstall: clean install

configure: $(CONFIG_BIN)
	"$(CONFIG_BIN)"

$(CONFIG_BIN): $(CONFIG_SOURCES)
	@mkdir -p "$(BUILD)"
	swiftc \
		-target $(TARGET) \
		-framework AppKit \
		-framework ScreenSaver \
		-framework Foundation \
		-O \
		-o "$(CONFIG_BIN)" \
		$(CONFIG_SOURCES)
	codesign --force --sign - "$(CONFIG_BIN)"

app: $(CONFIG_APP)

$(CONFIG_APP): $(CONFIG_BIN) Resources/Configurator-Info.plist
	@rm -rf "$(CONFIG_APP)"
	@mkdir -p "$(CONFIG_APP)/Contents/MacOS"
	@mkdir -p "$(CONFIG_APP)/Contents/Resources"
	cp Resources/Configurator-Info.plist "$(CONFIG_APP)/Contents/Info.plist"
	cp "$(CONFIG_BIN)" "$(CONFIG_APP)/Contents/MacOS/$(CONFIG_NAME)"
	codesign --force --sign - "$(CONFIG_APP)"
	@echo "Built $(CONFIG_APP)"

install-app: app
	@mkdir -p "$(APPS_DIR)"
	@rm -rf "$(APPS_DIR)/$(CONFIG_NAME).app"
	cp -R "$(CONFIG_APP)" "$(APPS_DIR)/"
	@echo ""
	@echo "Installed to $(APPS_DIR)/$(CONFIG_NAME).app"
	@echo "Open via Spotlight (Cmd+Space) and search 'Matrix Grey Config'."

uninstall:
	@rm -rf "$(DEST)/$(BUNDLE)"
	@rm -rf "$(APPS_DIR)/$(CONFIG_NAME).app"
	@echo "Removed $(DEST)/$(BUNDLE)"
	@echo "Removed $(APPS_DIR)/$(CONFIG_NAME).app"

purge: uninstall clean
	@defaults delete com.tardelli.MatrixGrey 2>/dev/null || true
	@defaults delete com.tardelli.MatrixGreyConfig 2>/dev/null || true
	@echo "Removed preferences for com.tardelli.MatrixGrey and com.tardelli.MatrixGreyConfig"
	@echo "Project fully purged from this machine."

PREVIEW_NAME    := RenderPreview
PREVIEW_BIN     := $(BUILD)/$(PREVIEW_NAME)
PREVIEW_SOURCES := Sources/Glyphs.swift Sources/MatrixColumn.swift Tools/RenderPreview/main.swift
PREVIEW_OUT     := docs/preview.png

preview: $(PREVIEW_OUT)

$(PREVIEW_OUT): $(PREVIEW_BIN)
	@mkdir -p docs
	"$(PREVIEW_BIN)" "$(PREVIEW_OUT)"

$(PREVIEW_BIN): $(PREVIEW_SOURCES)
	@mkdir -p "$(BUILD)"
	swiftc \
		-target $(TARGET) \
		-framework AppKit \
		-framework Foundation \
		-O \
		-o "$(PREVIEW_BIN)" \
		$(PREVIEW_SOURCES)

clean:
	rm -rf "$(BUILD)"
