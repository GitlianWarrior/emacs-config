;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Self-contained config for Emacs 30 or newer (Homebrew) on macOS.
;; Needs only Emacs, Homebrew, the Xcode Command Line Tools that Homebrew
;; installs (git, clang, clangd, lldb-dap, python3), and an internet
;; connection on first launch so packages can install from GNU/NonGNU
;; ELPA or MELPA.
;;; Code:

;; ============================================================
;; PRIVACY & SECURITY
;; ============================================================
;; Refuse HTTPS connections whose certificate doesn't check out,
;; instead of asking.
(setq gnutls-verify-error t)

;; Don't send your Emacs version, OS or previous page to websites.
(setq url-privacy-level '(email lastloc os emacs))

;; Look up passwords and tokens only in the macOS Keychain, never in a
;; plain-text ~/.authinfo file.  This also stops Emacs offering to save
;; passwords into such a file.
(setq auth-sources '(macos-keychain-internet))

;; ============================================================
;; PACKAGE SYSTEM & use-package
;; ============================================================
(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
;; Prefer GNU ELPA, then NonGNU ELPA, and only fall through to MELPA
;; when a package isn't available in either ELPA archive.
(setq package-archive-priorities
      '(("gnu"    . 20)
        ("nongnu" . 15)
        ("melpa"  . 5)))
(package-initialize)

;; Fetch the archive index once on a fresh machine so use-package can
;; install everything below.
(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t)

;; ============================================================
;; SHELL ENVIRONMENT
;; ============================================================
;; macOS apps launched from Finder/Dock get a stripped PATH.  Copy the
;; login shell's PATH into Emacs so anything you install later with
;; Homebrew is found.
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize))

;; Separate custom file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; ============================================================
;; GENERAL UX & PERFORMANCE
;; ============================================================
;; macOS NS port tweaks
(when (eq system-type 'darwin)
  (setq ns-command-modifier 'meta
        ns-option-modifier 'super
        ns-right-option-modifier 'none
        ns-function-modifier 'hyper
        mac-pass-command-to-system nil))

;; Rainbow delimiters
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Ultra-fast trackpad scrolling
(use-package ultra-scroll
  :init
  (setq scroll-conservatively 3
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))

;; Process performance
(setq read-process-output-max (* 1024 1024)
      process-adaptive-read-buffering nil)

;; Use macOS trash
(setq delete-by-moving-to-trash t
      trash-directory "~/.Trash")

;; No-littering: keeps backups, autosaves and state files under
;; var/ and etc/ inside the config directory.
(use-package no-littering
  :config
  (when (fboundp 'no-littering-theme-backups)
    (no-littering-theme-backups)))

;; History, recent files, places
(setq history-length 1000)
(savehist-mode 1)
(recentf-mode 1)
(save-place-mode 1)

;; Long lines
(global-so-long-mode 1)

;; Intelligent GC
(use-package gcmh
  :custom
  (gcmh-idle-delay 'auto)
  (gcmh-auto-idle-delay-factor 10)
  (gcmh-high-cons-threshold (* 32 1024 1024))
  :config
  (gcmh-mode 1))

;; ============================================================
;; LOOK & FEEL
;; ============================================================
(use-package doom-themes
  :config
  (load-theme 'doom-one t))

(defun my/first-available-font (fonts)
  "Return the first font family in FONTS that is installed on this system."
  (seq-find (lambda (f) (find-font (font-spec :family f))) fonts))

;; Falls back to Menlo, which ships with macOS.
(let ((family (my/first-available-font
               '("Iosevka"
                 "JetBrains Mono"
                 "Fira Code"
                 "Source Code Pro"
                 "SF Mono"
                 "Menlo"
                 "Monaco"))))
  (when family
    (set-face-attribute 'default nil :family family :height 150)))

;; Text-only mode line.
(use-package doom-modeline
  :custom (doom-modeline-icon nil)
  :init (doom-modeline-mode 1))

(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner 'logo
        dashboard-center-content t
        dashboard-items '((recents . 5)
                          (projects . 5)
                          (bookmarks . 5))))

;; Tab bar
(tab-bar-mode 1)
(setq tab-bar-show 1
      tab-bar-new-tab-choice "*scratch*")

;; ============================================================
;; NEW EMACS 30 BUILT-INS
;; ============================================================
(use-package completion-preview
  :ensure nil
  :custom (completion-preview-minimum-symbol-length 2)
  :bind (:map completion-preview-active-mode-map
              ("M-n" . completion-preview-next-candidate)
              ("M-p" . completion-preview-prev-candidate)
              ("M-f" . completion-preview-insert-word))
  :init (global-completion-preview-mode))

(use-package editorconfig
  :ensure nil
  :config (editorconfig-mode 1))

(global-visual-wrap-prefix-mode 1)

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom (flymake-show-diagnostics-at-end-of-line 'short))

;; ============================================================
;; COMPLETION & NAVIGATION
;; ============================================================
(use-package vertico
  :init (vertico-mode 1))

(use-package orderless
  :config (setq completion-styles '(orderless basic)))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-count 12)
  (corfu-cycle t)
  (corfu-preselect 'valid)
  (corfu-quit-no-match 'separator)
  (corfu-popupinfo-delay '(0.5 . 0.3))
  :bind (:map corfu-map ("SPC" . corfu-insert-separator))
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

(setq text-mode-ispell-word-completion nil)

(use-package which-key
  :ensure nil
  :init (which-key-mode 1))

(use-package project
  :ensure nil
  :custom
  (project-mode-line t)
  (project-file-history-behavior 'relativize)
  (project-vc-extra-root-markers '(".project" "Makefile" "package.json"))
  ;; project-prefix-map is autoloaded, so this works before project.el
  ;; loads.  (C-x p is the same map.)
  :init (keymap-global-set "C-c p" project-prefix-map))

(use-package magit
  :defer t)

(use-package diff-hl
  :custom (vc-git-diff-switches '("--histogram"))
  :config
  (global-diff-hl-mode)
  (diff-hl-flydiff-mode)
  (diff-hl-show-hunk-mouse-mode)
  (add-hook 'dired-mode-hook #'diff-hl-dired-mode)
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

;; ============================================================
;; TREE-SITTER & LSP
;; ============================================================
;; Grammars are cloned with git and built with clang on first use
;; (you'll be prompted before each one).
(use-package treesit-auto
  :custom (treesit-auto-install 'prompt)
  :config
  (setq treesit-auto-langs
        '(python c cpp c-sharp java javascript typescript tsx
          json bash css html yaml toml dockerfile cmake rust lua markdown))
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(setq treesit-font-lock-level 4)

;; C and C++ start a language server automatically: clangd ships with
;; the Command Line Tools.
(use-package eglot
  :ensure nil
  :hook ((c-ts-mode   . eglot-ensure)
         (c++-ts-mode . eglot-ensure)))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c++-ts-mode)
                 . ("clangd" "--clang-tidy" "--header-insertion=never"))))

;; Debugger -- dape (Debug Adapter Protocol client).
;; Talks to lldb-dap, which ships with the Command Line Tools 16+
;; (find with `xcrun -f lldb-dap`).
;;
;; Workflow: F5 to compile, then M-x dape RET, pick "lldb-dap" from the
;; prompt, and edit the :program path to your binary.  Step with n/s/c
;; in the source buffer; locals/stack panes update on the right.
(use-package dape
  :defer t
  :commands dape
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-cwd-fn #'project-root-or-default))

(defun project-root-or-default ()
  "Return current project root, or `default-directory' if outside a project."
  (if-let* ((proj (project-current))) (project-root proj) default-directory))

;; C compile helper + interactive F5
(defun my/c-compile-run ()
  "Compile current C file and run it interactively."
  (interactive)
  (compile compile-command t))

;; File names are shell-quoted so spaces or shell characters in them
;; can't break (or inject into) the command.
(add-hook 'c-ts-mode-hook
          (lambda ()
            (when buffer-file-name
              (let* ((src (file-name-nondirectory buffer-file-name))
                     (exe (shell-quote-argument (file-name-sans-extension src))))
                (setq-local compile-command
                            (format "gcc -Wall -Wextra -g -fsanitize=address -o %s %s && ./%s"
                                    exe (shell-quote-argument src) exe))))
            (local-set-key (kbd "<f5>") #'my/c-compile-run)))

;; Compilation behavior
;; compile.el auto-saves modified file buffers before running
;; (compilation-ask-about-save nil => no prompt).
;; `save-some-buffers-root' works out the project when you run compile
;; and only saves buffers under that root, so unrelated modified files
;; in other projects aren't silently written.
(setq compilation-ask-about-save nil
      compilation-save-buffers-predicate 'save-some-buffers-root
      compilation-scroll-output 'first-error)

;; ============================================================
;; MINIBUFFER, SEARCH, NAVIGATION TOOLS
;; ============================================================
(use-package embark
  :bind (("C-." . embark-act)))

(use-package embark-consult
  :after (embark consult))

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("M-s l" . consult-line)))

(use-package avy
  :bind (("C-:" . avy-goto-char-timer)))

(use-package vundo
  :bind (("C-x u" . vundo)))

(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)))

;; Casual transient menus (consolidated into a single 'casual' package).
;; Pinned to NonGNU ELPA. Both archives serve the same upstream commit,
;; but MELPA's date-stamp versions numerically dominate NonGNU's semver,
;; so without :pin package.el would route the install through MELPA.
(use-package casual
  :pin "nongnu"
  :bind ((:map dired-mode-map           ("C-o" . casual-dired-tmenu))
         (:map calc-mode-map            ("C-o" . casual-calc-tmenu))
         (:map isearch-mode-map         ("C-o" . casual-isearch-tmenu))
         (:map ibuffer-mode-map         ("C-o" . casual-ibuffer-tmenu))
         (:map Info-mode-map            ("C-o" . casual-info-tmenu))
         (:map bookmark-bmenu-mode-map  ("C-o" . casual-bookmarks-tmenu))))

;; Dirvish: modern dired overlay with previews and git signs.
;; NonGNU ELPA.  Takes over C-x d / dired commands.
;;
;; Dirvish ships its optional features under an `extensions/' subdirectory
;; that package.el does NOT add to `load-path' automatically, so the
;; extension minor-modes (dirvish-peek, dirvish-side, dirvish-subtree, etc.)
;; are unreachable without help.  We fix that in :init before :config runs.
(use-package dirvish
  :init
  (let* ((main (locate-library "dirvish"))
         (ext  (and main (expand-file-name
                          "extensions"
                          (file-name-directory main)))))
    (when (and ext (file-directory-p ext))
      (add-to-list 'load-path ext)))
  (dirvish-override-dired-mode)
  :custom
  (dirvish-quick-access-entries
   '(("h" "~/"         "Home")
     ("e" "~/.emacs.d/" "Emacs config")
     ("d" "~/Downloads/" "Downloads")))
  (dirvish-attributes '(file-size vc-state git-msg))
  (dirvish-mode-line-format
   '(:left (sort symlink) :right (omit yank index)))
  :config
  ;; Pull in the extensions we actually use.  Safe: errors here only
  ;; disable the optional feature, not dirvish itself.
  (require 'dirvish-peek    nil t)
  (require 'dirvish-side    nil t)
  (require 'dirvish-subtree nil t)
  (when (fboundp 'dirvish-peek-mode)        (dirvish-peek-mode 1))
  (when (fboundp 'dirvish-side-follow-mode) (dirvish-side-follow-mode 1))
  :bind (:map dirvish-mode-map
              ("a"   . dirvish-quick-access)
              ("TAB" . dirvish-subtree-toggle)
              ("M-f" . dirvish-history-go-forward)
              ("M-b" . dirvish-history-go-backward)
              ("M-t" . dirvish-layout-toggle)))

;; ============================================================
;; QUALITY-OF-LIFE
;; ============================================================
(electric-pair-mode 1)
(global-auto-revert-mode 1)
(setq confirm-kill-emacs 'y-or-n-p)
(winner-mode 1)

(global-set-key (kbd "C-c d") 'duplicate-line)
(setq use-short-answers t)

;; Line numbers in code buffers (Tsoding-style relative).
;; Current line shows its absolute line number; surrounding lines show
;; the distance from point.  Lets you jump with M-<n> C-n / C-p.
;; The disable-hooks for markdown/org further down keep these
;; modes uncluttered.
(setq display-line-numbers-type 'relative)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'conf-mode-hook #'display-line-numbers-mode)

;; tmr -- simple timers with a friendly notation, e.g. "10" (10 min),
;; "2h" (2 hours), "10:30" (until 10:30).  M-x tmr to start one,
;; M-x tmr-with-description to label it, M-x tmr-tabulated-view to list.
(use-package tmr
  :commands (tmr tmr-with-description tmr-tabulated-view))

;; ============================================================
;; MARKDOWN
;; ============================================================
(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode)
  :hook (markdown-mode . visual-line-mode)
  :custom
  (markdown-fontify-code-blocks-natively t)
  (markdown-header-scaling t)
  (markdown-hide-markup t))

(add-hook 'markdown-mode-hook
          (lambda () (display-line-numbers-mode -1)))

;; ============================================================
;; ORG-MODE
;; ============================================================
(use-package org
  :ensure nil
  :config
  (setq org-directory "~/org"
        org-agenda-files (list org-directory)
        org-startup-indented t
        org-startup-folded 'content
        org-hide-emphasis-markers t
        org-return-follows-link t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-log-done 'time
        org-startup-with-inline-images t
        org-image-actual-width '(300)
        org-pretty-entities t
        ;; Require {} for sub/superscripts so plain underscores in filenames
        ;; (e.g. "my_file") don't render as subscripts.  Use H_{2}O
        ;; (not H_2O) to get H₂O.  Also affects exporters.
        org-use-sub-superscripts '{}
        org-agenda-use-time-grid nil)
  ;; Always ask before running a code block, even in files under ~/org,
  ;; since a file saved there from elsewhere can contain code.
  (setq org-confirm-babel-evaluate t)
  ;; Make sure the org directory exists so the agenda doesn't error.
  (make-directory org-directory t)
  ;; Only languages that run with the Command Line Tools (python3, clang)
  ;; and the system shell.
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t)
     (C . t)
     (shell . t))))

(add-hook 'org-mode-hook
          (lambda () (display-line-numbers-mode -1)))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-hide-stars t
        org-modern-table t
        org-modern-priority nil
        org-modern-timestamp nil))

(use-package org-appear
  :hook (org-mode . org-appear-mode))

(global-set-key (kbd "C-c c") #'org-capture)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c l") #'org-store-link)

(setq org-capture-templates
      '(("n" "Quick Note" entry
         (file+headline "~/org/inbox.org" "Notes")
         "* %?\n %U\n")
        ("t" "TODO" entry
         (file+headline "~/org/inbox.org" "Tasks")
         "* TODO %?\n DEADLINE: %^t\n %U\n")))

;; ============================================================
;; SQL (editing only)
;; ============================================================
;; Smarter SQL indentation (GNU ELPA) — with proper 4-space offset
(use-package sql-indent
  :hook (sql-mode . sqlind-minor-mode)
  :config
  (setq sqlind-basic-offset 4)

  ;; Custom rules that EXTEND the defaults
  (defvar my-sql-indent-rules
    `((select-statement          0)
      (insert-statement          0)
      (update-statement          0)
      (delete-statement          0)
      (create-statement          0)
      (create-table-statement    0)
      (block                     4)
      (begin-block               4)
      (case-statement            4)
      (case-expression           4)
      (when-clause               4)
      (else-clause               4)
      (in-list                   4)
      (in-list-column            4)
      ;; Keep all the default rules intact
      ,@sqlind-default-indentation-offsets-alist))

  ;; Apply our custom rules to every SQL buffer
  (add-hook 'sqlind-minor-mode-hook
            (lambda ()
              (setq sqlind-indentation-offsets-alist my-sql-indent-rules))))

;; Force spaces (not tab characters) and align tab-width with
;; sqlind-basic-offset (4) so the file looks the same in other editors.
(add-hook 'sql-mode-hook
          (lambda ()
            (setq-local indent-tabs-mode nil
                        tab-width 4)))

(provide 'init)
;;; init.el ends here
