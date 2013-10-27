lessc_options=--verbose
#lessc_options=--yui-compress

compile-less:
	cd assets/themes/bootstrap && \
	lessc $(lessc_options) less/style.less css/style.css