lessc_options=--verbose
#lessc_options=--yui-compress

serve: compile-less
	jekyll serve

compile-less:
	cd assets/themes/bootstrap && \
	lessc $(lessc_options) less/style.less css/style.css && \
	lessc $(lessc_options) less/cv.less css/cv.css