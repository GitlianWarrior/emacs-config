;;; early-init.el --- Early initialization for Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; Early-init settings for emacs-app (Emacs 30.2) on macOS.
;; Runs before the package system and GUI are initialized.
;;; Code:

;; ============================================================
;; PERFORMANCE & STARTUP OPTIMIZATIONS
;; ============================================================

;; Maximize GC threshold during startup (restored by gcmh later)
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; After startup, put gc-cons-percentage back to the default (gcmh only
;; manages the threshold), and if init failed before gcmh loaded, fall
;; back to a sane threshold so GC isn't left switched off.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-percentage 0.1)
            (when (= gc-cons-threshold most-positive-fixnum)
              (setq gc-cons-threshold (* 16 1024 1024)))))

;; Temporarily disable file-name-handler-alist for faster loading
(defvar my--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist my--file-name-handler-alist)))

;; Prevent UI elements from ever being created (no flicker)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)

;; Prevent expensive frame resizing during startup
(setq frame-inhibit-implied-resize t)
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)
(setq use-file-dialog nil)
(setq use-dialog-box nil)

;; macOS NS-specific frame parameters
(when (featurep 'ns)
  (push '(ns-transparent-titlebar . t) default-frame-alist)
  (push '(ns-appearance . dark) default-frame-alist)
  (setq ns-use-native-fullscreen nil)
  (setq ns-use-fullscreen-animation nil)
  (setq ns-use-proxy-icon nil))

;; General performance tweaks
(setq inhibit-compacting-font-caches t)
(setq site-run-file nil)
(setq load-prefer-newer t)
(setq redisplay-skip-fontification-on-input t)
(setq fast-but-imprecise-scrolling t)

;; Turn off native compilation so packages just run byte-compiled.
(when (featurep 'native-compile)
  (setq native-comp-jit-compilation nil
        native-comp-enable-subr-trampolines nil
        native-comp-async-report-warnings-errors 'silent))

(provide 'early-init)
;;; early-init.el ends here
