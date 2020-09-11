;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


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
(setq projectile-project-search-path '("~/Workspace/nubank")
      projectile-enable-caching nil)

;; Reload buffers when modified on disk
(setq global-auto-revert-mode t)

;; Avy all windows
(setq avy-all-windows t)

;; Change local leader to ','
(setq doom-localleader-key ",")

;; Lispyville config
;; (add-hook 'emacs-lisp-mode-hook #'lispyville-mode)
(add-hook 'lisp-mode-hook #'lispyville-mode)

(with-eval-after-load 'lispyville
  (lispyville-set-key-theme
   '(operators
     c-w
     (escape insert)
     (prettify insert)
     (additional-movement normal visual motion))))

;; which-key
(setq which-key-idle-delay 0.4)

;; treemacs
(setq treemacs-follow-mode t)

;; company
(setq company-selection-wrap-around t
      company-minimum-prefix-length 3
      company-idle-delay 0.4)

;; windows rules
(set-popup-rule! "^\\*cider-repl" :side 'right :width 0.5)
(set-popup-rule! "*cider-test-report*" :side 'right :width 0.5)
(set-popup-rule! "\\*midje-test-report\\*" :side 'right :width 0.5)

(use-package! cider
  :after clojure-mode
  :config
  (setq cider-ns-refresh-show-log-buffer t
        cider-show-error-buffer t;'only-in-repl
        cider-prompt-for-symbol nil)
  (set-lookup-handlers! 'cider-mode nil))

(use-package! clj-refactor
  :after clojure-mode
  :config
  (set-lookup-handlers! 'clj-refactor-mode nil)
  (setq cljr-warn-on-eval nil
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

(use-package! clojure-mode
  :config
  (setq clojure-indent-style 'align-arguments
        clojure-thread-all-but-last t
        clojure-align-forms-automatically t
        yas-minor-mode 1))

;; nu scripts
;; (let ((nudev-emacs-path "~/Workspace/nubank/nudev/ides/emacs/"))
;;   (when (file-directory-p nudev-emacs-path)
;;     (add-to-list 'load-path nudev-emacs-path)
;;     (require 'nu)))

(defun nutap ()
  (interactive)
  (insert-before-markers "#nu/tapd "))

(defun nutap-clean ()
  (interactive)
  (goto-char 1)
    (while (search-forward "#nu/tapd " nil nil)
      (replace-match "")))

(load! "+bindings")
