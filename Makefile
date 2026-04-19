APP_NAME := 火山Code订阅用量

.PHONY: build run package-app dmg clean

build:
	swift build

run:
	swift run CodingPlanMenuBar

package-app:
	./script/package_macos_app.sh

dmg: package-app
	./script/build_dmg.sh

clean:
	rm -rf dist
	rm -rf .build .swiftpm
