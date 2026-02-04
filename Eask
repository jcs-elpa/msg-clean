;; -*- mode: eask; lexical-binding: t -*-

(package "msg-clean"
		 "0.1.0"
		 "Keep messages buffer clean")

(website-url "https://github.com/jcs-elpa/msg-clean")
(keywords "convenience" "messages" "clean")

(package-file "message-clean-mode.el")

(script "test" "echo \"Error: no test specified\" && exit 1")

(source 'gnu)
(source 'jcs-elpa)

(depends-on "emacs" "26.1")
(depends-on "msgu")

(setq network-security-level 'low      ; see https://github.com/jcs090218/setup-emacs-windows/issues/156#issuecomment-932956432
	  byte-compile-error-on-warn nil)
