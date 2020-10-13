;;; ~/.doom.d/+bindings.el -*- lexical-binding: t; -*-

;; general mappings
(map!
                                        ; remove default workspace shortcuts
 :n "C-t" #'better-jumper-jump-backward
 :n "C-S-t" nil
                                        ; move betweeen windows faster in normal mode
 :m "C-h" #'evil-window-left
 :m "C-j" #'evil-window-down
 :m "C-k" #'evil-window-up
 :m "C-l" #'evil-window-right
                                        ; move windows faster in normal mode
 :m "C-S-h" #'+evil/window-move-left
 :m "C-S-j" #'+evil/window-move-down
 :m "C-S-k" #'+evil/window-move-up
 :m "C-S-l" #'+evil/window-move-right
                                        ; move centaur tabs
 :m "gT" #'centaur-tabs-backward
 :m "gt" #'centaur-tabs-forward
 :m "s-{" #'centaur-tabs-backward       ; idea-like move centaur tabs
 :m "s-}" #'centaur-tabs-forward
                                        ; lispy
 :n "gc" #'lispyville-comment-or-uncomment
                                        ; misc
 :n "-" #'dired-jump
 :n "s-t" #'magit-pull-from-upstream 
 :n "C-c +" #'evil-numbers/inc-at-pt
 :n "C-c -" #'evil-numbers/dec-at-pt
 :ne "C-;" #'avy-goto-char-2
 :nv "C-SPC" #'+fold/toggle)

;; clojure specific mappings
(map! :after clojure-mode
      :map clojure-mode-map
      :localleader

      :desc "Insert '#nu/tapd' before word"
      "d" #'nutap

      :desc "Ident buffer/region"
      "=" #'clojure-align

      :desc "Clean all '#nu/tapd' occurences in current buffer"
      "D" #'nutap-clean)

(map! :after lsp-mode
      :map lsp-ui-peek-mode-map
      "h" #'lsp-ui-peek--select-prev-file
      "j" #'lsp-ui-peek--select-next
      "k" #'lsp-ui-peek--select-prev
      "l" #'lsp-ui-peek--select-next-file)

(map! :after lsp-mode
      :map lsp-ui-mode-map
      :n "gd" #'lsp-ui-peek-find-definitions
      :n "s-b" #'lsp-ui-peek-find-definitions ; idea-like
      :n "gr" #'lsp-ui-peek-find-references
      :n "H"  #'lsp-ui-peek-jump-backward
      :n "L"  #'lsp-ui-peek-jump-forward)
