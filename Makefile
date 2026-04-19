APP_NAME := Volcengine TokenPlan Menubar

.PHONY: build run package-app dmg clean

build:
	cd swift-menubar && swift build

run:
	cd swift-menubar && swift run CodingPlanMenuBar

package-app:
	./script/package_macos_app.sh

dmg: package-app
	./script/build_dmg.sh

clean:
	rm -rf dist
	cd swift-menubar && rm -rf .build .swiftpm
