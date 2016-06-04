.PHONY: docs test release

docs:
	jazzy \
		--author Daniel Tomlinson \
		--author_url https://dantoml.com \
		--github_url https://github.com/DanToml/Latch \
		--module-version $(VERSION) \
		--output docs \
		--module Latch

test:
	xcodebuild test -scheme Latch-OSX

release: docs
	git add -A
	git commit -am "Release $(VERSION)"
	git tag $(VERSION)
	git push
	git push --tags
	pod trunk push
