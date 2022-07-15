;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!
(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setq exec-path (append exec-path '("/usr/local/bin")))

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "André Fonseca"
      user-mail-address "1077309+andreAmorimF@users.noreply.github.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))
;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/.org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(setq projectile-project-search-path '("~/Workspace/nubank" "~/Workspace/others/cardano")
      projectile-enable-caching nil)

;; Reload buffers when modified on disk
(setq global-auto-revert-mode t)

;; Increase the amount of data which Emacs reads from the process
(setq read-process-output-max (* 1024 1024)) ;; 1mb

;; Avy all windows
(setq avy-all-windows t)

;; Change  local leader to ','
(setq doom-localleader-key ",")

;;  ranger
(setq ranger-preview-file t
      ranger-show-hidden t)

;; which-key
(setq which-key-idle-delay 0.4)

;; treemacs
(setq treemacs-follow-mode t)

;; evil-matchit
(setq global-evil-matchit-mode 1)

;; company
(setq company-selection-wrap-around t
      company-tooltip-align-annotations t
      company-show-numbers t
      company-idle-delay 0.5)

(add-to-list 'company-backends #'company-tabnine)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Aggressive indent
;; (use-package! aggressive-indent
;;   :hook ((common-lisp-mode . aggressive-indent-mode)
;;          (emacs-lisp-mode . aggressive-indent-mode)
;;          (clojure-mode . aggressive-indent-mode))
;;   :config
;;   (setq aggressive-indent-sit-for-time 0.2)
;;   (add-to-list
;;    'aggressive-indent-dont-indent-if
;;    '(and (stringp buffer-file-name)
;;          (string-match "\\.edn\\'" buffer-file-name))))

;; lsp related config
(setq lsp-ignore-dirs '("[/\\\\][^/\\\\]*\\.\\(json\\|pyc\\|class\\)$"
                        "[/\\\\]\\.clj-kondo\\'"
                        "[/\\\\]\\.github\\'"
                        "[/\\\\]\\.lsp\\'"
                        "[/\\\\]target\\"))

(use-package! lsp-mode
  :commands lsp
  :hook ((clojure-mode . lsp)
         (dart-mode    . lsp)
         (java-mode    . lsp)
         (python-mode  . lsp)
         (ruby-mode    . lsp)
         (scala-mode   . lsp))
  :config
  (setq lsp-headerline-breadcrumb-enable nil
        lsp-lens-enable t
        lsp-semantic-tokens-enable t
        lsp-lens-place-position 'end-of-line
        lsp-signature-auto-activate nil
        lsp-completion-sort-initial-results t
        lsp-completion-no-cache t
        lsp-completion-use-last-result nil
        lsp-file-watch-ignored-directories (append lsp-file-watch-ignored-directories lsp-ignore-dirs))
  (add-hook 'lsp-after-apply-edits-hook (lambda (&rest _) (save-buffer))))

(use-package! lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-include-signature nil
        lsp-ui-doc-position 'top
        lsp-ui-doc-header t
        lsp-ui-doc-enable t
        lsp-ui-doc-include-signature t
        lsp-ui-doc-use-childframe t
        lsp-ui-sideline-show-hover nil
        lsp-ui-sideline-ignore-duplicate t
        lsp-ui-sideline-show-code-actions nil
        lsp-ui-sideline-show-symbol nil
        lsp-completion-provider :company-mode
        lsp-completion-show-detail t
        lsp-completion-show-kind t
        lsp-ui-doc-border (doom-color 'fg)
        lsp-ui-peek-fontify 'always))

(use-package! lsp-treemacs
  :config
  (setq lsp-treemacs-error-list-current-project-only t))

;; clojure related plugins configuration
(use-package! cider
  :after clojure-mode
  :config
  (setq cider-ns-refresh-show-log-buffer t
        cider-show-error-buffer 'only-in-repl
        cider-eldoc-display-for-symbol-at-point nil ; use lsp
        cider-prompt-for-symbol nil)
  (set-lookup-handlers! 'cider-mode nil)
  (add-hook 'cider-mode-hook (lambda () (remove-hook 'completion-at-point-functions #'cider-complete-at-point))) ; use lsp
  )

(use-package! clj-refactor
  :after clojure-mode
  :config
  (set-lookup-handlers! 'clj-refactor-mode nil)
  (setq cljr-warn-on-eval nil
        cljr-auto-sort-ns t
        cljr-eagerly-build-asts-on-startup nil
        cljr-add-ns-to-blank-clj-files nil
        cljr-magic-require-namespaces
        '(("s"   . "schema.core")
          ("th"  . "common-core.test-helpers")
          ("gen" . "common-test.generators")
          ("d-pro" . "common-datomic.protocols.datomic")
          ("ex" . "common-core.exceptions")
          ("dth" . "common-datomic.test-helpers")
          ("t-money" . "common-core.types.money")
          ("t-time" . "common-core.types.time")
          ("d" . "datomic.api")
          ("m" . "matcher-combinators.matchers")
          ("pp" . "clojure.pprint"))))

(use-package! lispyville
  :hook ((common-lisp-mode . lispyville-mode)
         (emacs-lisp-mode . lispyville-mode)
         (scheme-mode . lispyville-mode)
         (cider-repl-mode . lispyville-mode)
         (clojure-mode . lispyville-mode))
  :config
  (lispyville-set-key-theme
   '(operators
     c-w
     (escape insert)
     (prettify insert)
     (additional-movement normal visual motion))))

(use-package! clojure-mode
  :config
  (setq clojure-indent-style 'align-arguments
        clojure-thread-all-but-last t
        clojure-align-forms-automatically t
        comment-start ";"
        yas-minor-mode 1)

  (defun nutap ()
    "Adds '#nu/tapd' before cursor"
    (interactive)
    (insert-before-markers " #nu/tapd "))

  (defun nutap-clean ()
    "Remove all occurences of '#nu/tapd' in current buffer"
    (interactive)
    (goto-char 1)
    (while (search-forward " #nu/tapd " nil nil)
      (replace-match ""))))

;; nu scripts
(let ((nudev-emacs-path "~/Workspace/nubank/nudev/ides/emacs/"))
  (when (file-directory-p nudev-emacs-path)
    (add-to-list 'load-path nudev-emacs-path)
    (require 'nu nil t)))

(use-package isa
  :load-path "~/Workspace/nubank/isa.el"
  :config
  ;; if you use vim keys
  (map! :leader
	:desc "isa" "N i" #'isa)
  ;; if you use emacs keys
  (define-key global-map (kbd "C-c i") #'isa))

;; Other windows rules
(after! magit
  (set-popup-rule! "^.*magit" :slot -1 :side 'right :width 0.4 :select t)
  (set-popup-rule! "^.*magit.*popup.*" :actions '(display-buffer-below-selected))
  (set-popup-rule! "^.*magit-revision" :slot 0 :side 'right :width 0.4 :select t)
  (set-popup-rule! "^.*magit-diff" :slot 0 :side 'right :width 0.5 :height 0.6))
(after! cider
  (set-popup-rule! "^\\*cider-repl" :side 'right :width 0.5 :select t)
  (set-popup-rule! "*cider-test-report*" '(display-buffer-below-selected))
  (set-popup-rule! "\\*midje-test-report\\*" :side 'right :width 0.5))

;; Key bindings definitions
(load! "+bindings")
